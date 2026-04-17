#!/usr/bin/env python3
"""
Notchly Brain — personal AI assistant daemon
Primary AI  : Ollama local (gemma3:4b) — offline, fast on Apple Silicon
Fallback AI : Groq cloud (llama-3.3-70b) — free, ~200ms
Data sources: Apple Calendar + Screenpipe screen reading + Music.app/Spotify

Run : python3 brain_loop.py
Stop: Ctrl+C  (or kill from Notchly menu bar)
"""

import json, os, time, subprocess, hashlib
from datetime import datetime, timedelta
from pathlib import Path
from typing import Optional

try:
    import requests
    HAS_REQUESTS = True
except ImportError:
    HAS_REQUESTS = False
    print("⚠️  pip3 install requests")

# ── Config ───────────────────────────────────────────────────────────────────
BASE           = Path.home() / "Documents/notchly/v2"
SCREENPIPE     = "http://localhost:3030"
OLLAMA         = "http://localhost:11434"
OLLAMA_MODEL   = "gemma3:4b"          # 3.5 GB — best assistant model under 5 GB
GROQ_KEY       = ""                   # console.groq.com — free fallback
POLL_SECONDS   = 600                  # 10 minutes

# ── Apple helpers ────────────────────────────────────────────────────────────

def calendar_events_today() -> list[dict]:
    script = '''
set out to {}
set d to current date
set time of d to 0
set tomorrow to d + 86400
tell application "Calendar"
    repeat with c in calendars
        try
            set evts to (every event of c whose start date ≥ d and start date ≤ tomorrow)
            repeat with e in evts
                set st to start date of e
                set entry to (summary of e) & "|" & (hours of st) & "|" & (minutes of st)
                set end of out to entry
            end repeat
        end try
    end repeat
end tell
set AppleScript's text item delimiters to "~"
return out as text
'''
    try:
        r = subprocess.run(["osascript", "-e", script],
                           capture_output=True, text=True, timeout=8)
        events = []
        for part in r.stdout.strip().split("~"):
            pieces = part.strip().split("|")
            if len(pieces) == 3:
                try:
                    events.append({"title": pieces[0].strip(),
                                   "hour": int(pieces[1]), "minute": int(pieces[2])})
                except ValueError:
                    pass
        return events
    except Exception:
        return []


def now_playing() -> str:
    for app, script in [
        ("Music",   'tell application "Music" to if player state is playing then return name of current track & " by " & artist of current track'),
        ("Spotify", 'tell application "Spotify" to if player state is playing then return name of current track & " by " & artist of current track'),
    ]:
        try:
            r = subprocess.run(["osascript", "-e", script],
                               capture_output=True, text=True, timeout=3)
            t = r.stdout.strip()
            if t and "execution error" not in t and len(t) > 2:
                return t
        except Exception:
            pass
    return ""


def _local_since(minutes: int) -> str:
    """ISO8601 timestamp with local timezone offset (screenpipe uses local tz)."""
    import subprocess as _sp
    tz = _sp.run(["date", "+%z"], capture_output=True, text=True).stdout.strip()
    dt = datetime.now() - timedelta(minutes=minutes)
    return dt.strftime("%Y-%m-%dT%H:%M:%S") + tz[:3] + ":" + tz[3:]

def screenpipe_context() -> tuple[str, str]:
    """(dominant_app, screen_text_summary). Reads last 30 min of screen frames."""
    if not HAS_REQUESTS:
        return "", ""
    try:
        r = requests.get(f"{SCREENPIPE}/search",
                         params={"content_type": "ocr", "limit": 8,
                                 "start_time": _local_since(30)},
                         timeout=12)
        items = r.json().get("data", [])
        app_counts: dict[str, int] = {}
        chunks: list[str] = []
        for item in items:
            c   = item.get("content", {})
            txt = c.get("text", "").strip().replace("\n", " ")
            app = c.get("app_name", "")
            if app:
                app_counts[app] = app_counts.get(app, 0) + 1
            if txt and len(txt) > 20:
                entry = f"[{app}] {txt[:90]}" if app else txt[:90]
                if entry not in chunks:
                    chunks.append(entry)
        dominant = max(app_counts, key=app_counts.get) if app_counts else ""
        return dominant, " | ".join(chunks[:4])
    except Exception:
        return "", ""


def active_app_fallback() -> str:
    script = 'tell application "System Events" to return name of first process whose frontmost is true'
    try:
        r = subprocess.run(["osascript", "-e", script],
                           capture_output=True, text=True, timeout=3)
        return r.stdout.strip()
    except Exception:
        return ""


# ── Music control ─────────────────────────────────────────────────────────────

MOOD_PLAYLISTS = {
    "focus":    ["Focus", "Deep Work", "Lo-Fi", "Concentration"],
    "relax":    ["Chill", "Calm", "Acoustic"],
    "energy":   ["Workout", "Hype", "Upbeat"],
    "creative": ["Inspiration", "Ambient"],
}

def set_music_mood(mood: str) -> bool:
    for name in MOOD_PLAYLISTS.get(mood.lower(), []):
        script = (f'tell application "Music"\ntry\nplay playlist "{name}"\n'
                  f'return "ok"\nend try\nend tell\nreturn "no"')
        try:
            r = subprocess.run(["osascript", "-e", script],
                               capture_output=True, text=True, timeout=4)
            if "ok" in r.stdout:
                print(f"  🎵 Mood '{mood}' → '{name}'")
                return True
        except Exception:
            pass
    return False


# ── Data I/O ──────────────────────────────────────────────────────────────────

def read_json(path: Path, default):
    try:
        return json.loads(path.read_text())
    except Exception:
        return default


def atomic_write(path: Path, data):
    tmp = path.with_suffix(".tmp")
    tmp.write_text(json.dumps(data, indent=2, ensure_ascii=False))
    os.rename(tmp, path)


def stable_id(*parts) -> str:
    day = datetime.now().strftime("%Y-%m-%d")
    return hashlib.md5(f"{day}:{'|'.join(str(p) for p in parts)}".encode()).hexdigest()[:10]


# ── Alert helpers ─────────────────────────────────────────────────────────────

_fired_at: dict[str, datetime] = {}

def can_fire(aid: str, cooldown_min: int = 30) -> bool:
    last = _fired_at.get(aid)
    return not (last and (datetime.now() - last).seconds < cooldown_min * 60)


def push_alert(lst: list, aid: str, type_: str, title: str, message: str,
               priority: int = 2, left: str = "Skip", right: str = "Got it") -> bool:
    if not can_fire(aid):
        return False
    if any(a["id"] == aid for a in lst):
        return False
    lst.append({"id": aid, "type": type_, "title": title, "message": message,
                "priority": priority, "action_left": left, "action_right": right,
                "created_at": datetime.now().isoformat()})
    _fired_at[aid] = datetime.now()
    print(f"  🔔 [{type_}] {title}")
    return True


# ── Rule engine ───────────────────────────────────────────────────────────────

FOCUS_APPS    = {"Xcode","Visual Studio Code","Code","PyCharm","Sublime Text",
                 "Notion","Obsidian","Bear","Notes","Terminal","Warp","iTerm2"}
DISTRACT_APPS = {"YouTube","Safari","Chrome","Firefox","Twitter","Reddit",
                 "Discord","Messages","Mail","Slack","Instagram","TikTok"}

_last_app   = ""
_app_start  = datetime.now()
_warned     = False

def rules_engine(events: list, schedule: list, app: str,
                 screen: str, music: str) -> dict:
    global _last_app, _app_start, _warned
    now    = datetime.now()
    alerts: list[dict] = []

    if app and app != _last_app:
        _last_app  = app
        _app_start = now
        _warned    = False

    # Calendar: upcoming event within 10 min
    next_event = None
    for e in events:
        ev_dt     = now.replace(hour=e["hour"], minute=e["minute"], second=0, microsecond=0)
        delta_min = int((ev_dt - now).total_seconds() / 60)
        if 0 < delta_min <= 10:
            next_event = e
            push_alert(alerts, stable_id("evt_soon", e["title"]),
                       "calendar", f"{e['title']} in {delta_min}m",
                       "Wrap up and get ready", 1, "Later", "On it")
        elif delta_min == 0:
            push_alert(alerts, stable_id("evt_now", e["title"]),
                       "calendar", f"{e['title']} now", "Time to join", 1, "Skip", "Joining")

    # Distraction nudge after 20 min
    if app in DISTRACT_APPS:
        in_min = int((now - _app_start).total_seconds() / 60)
        if in_min >= 20 and not _warned:
            _warned = True
            active = next((t for t in schedule if t.get("status") == "active"), None)
            hint   = f"Back to '{active['title']}'" if active else "Get back to work"
            push_alert(alerts, stable_id("distract", app),
                       "nudge", f"{in_min}min in {app}", hint, 2, "5 more min", "Back to work")

    if app in FOCUS_APPS:
        _warned = False

    # Music mood by time of day (only if nothing playing)
    hour = now.hour
    mood = None
    if not music:
        if   9  <= hour < 13: mood = "focus"
        elif 13 <= hour < 15: mood = "relax"
        elif 15 <= hour < 19: mood = "focus"
        elif 19 <= hour:      mood = "relax"

    # Goal + context
    active  = next((t for t in schedule if t.get("status") == "active"), None)
    pending = [t["title"] for t in schedule if t.get("status") == "pending"]

    if   next_event:   goal = f"Prep for {next_event['title']}"
    elif active:       goal = f"Finish {active['title']}"
    elif pending:      goal = f"Start {pending[0]}"
    else:              goal = "You're free — rest or plan next"

    ctx_parts = [f"Using {app}"] if app else []
    if active:  ctx_parts.append(f"Task: {active['title']}")
    if music:   ctx_parts.append(f"Playing: {music[:30]}")
    context = " · ".join(ctx_parts) or "Idle"

    return {"goal": goal, "context": context,
            "alerts": alerts[:1], "music_mood": mood}


# ── AI enrichment ─────────────────────────────────────────────────────────────

AI_SYSTEM = """\
You are Notchly Brain, a macOS personal assistant running in the menu bar notch.
Read the user context and return a single JSON object. No markdown. No explanation.

Example output:
{"todays_goal":"Ship Notchly v1 today","working_memory":"Deep coding session in Xcode","alerts":[],"music_mood":"focus"}

Rules:
- todays_goal: short action phrase, max 6 words, starts with a verb
- working_memory: what the user appears to be doing right now, max 15 words
- alerts: empty array [] unless something urgent (event in <10min, been stuck >30min)
- music_mood: one of "focus", "relax", "energy", "creative", or null

If there is an urgent alert, use this format inside the alerts array:
{"id":"evt_abc123","type":"calendar","title":"Stand-up in 5min","message":"Wrap up and join","priority":1,"action_left":"Later","action_right":"Joining"}

Return ONLY the JSON object. Nothing else.\
"""

def ollama_available() -> bool:
    try:
        r = requests.get(f"{OLLAMA}/api/tags", timeout=2)
        models = [m["name"] for m in r.json().get("models", [])]
        return any(OLLAMA_MODEL.split(":")[0] in m for m in models)
    except Exception:
        return False


def call_ai(prompt: str) -> Optional[dict]:
    """Try Ollama local first, then Groq cloud. Returns parsed dict or None."""
    if not HAS_REQUESTS:
        return None

    # 1. Ollama local (gemma3:4b) — offline, Apple Silicon MPS
    if ollama_available():
        try:
            r = requests.post(f"{OLLAMA}/v1/chat/completions",
                              json={"model": OLLAMA_MODEL,
                                    "messages": [{"role": "system", "content": AI_SYSTEM},
                                                 {"role": "user",   "content": prompt}],
                                    "max_tokens": 280, "temperature": 0.25,
                                    "stream": False},
                              timeout=25)
            raw = r.json()["choices"][0]["message"]["content"].strip()
            if raw.startswith("```"):
                raw = raw.split("```")[1]
                if raw.startswith("json"): raw = raw[4:]
            result = json.loads(raw.strip())
            print(f"  ✨ Gemma3 (local)")
            return result
        except Exception as e:
            print(f"  ℹ️  Ollama failed: {e}")

    # 2. Groq cloud fallback (free, llama-3.3-70b)
    if GROQ_KEY:
        try:
            r = requests.post("https://api.groq.com/openai/v1/chat/completions",
                              headers={"Authorization": f"Bearer {GROQ_KEY}",
                                       "Content-Type": "application/json"},
                              json={"model": "llama-3.3-70b-versatile",
                                    "messages": [{"role": "system", "content": AI_SYSTEM},
                                                 {"role": "user",   "content": prompt}],
                                    "max_tokens": 280, "temperature": 0.2},
                              timeout=12)
            raw = r.json()["choices"][0]["message"]["content"].strip()
            result = json.loads(raw.strip())
            print("  ✨ Groq (cloud)")
            return result
        except Exception as e:
            print(f"  ℹ️  Groq failed: {e}")

    return None


def ai_enrich(ctx: dict, base: dict) -> dict:
    prompt = (
        f"Time:{ctx['time']} | App:{ctx['app']} | Events:{ctx['events_str']}\n"
        f"Active task:{ctx['active_task']} | Screen:{ctx['screen'][:300]}\n"
        f"Rules suggest — goal:\"{base['goal']}\" context:\"{base['context']}\"\n"
        "Improve or confirm. Return JSON only."
    )
    result = call_ai(prompt)
    if not result:
        return base
    base["goal"]    = result.get("todays_goal",    base["goal"])
    base["context"] = result.get("working_memory", base["context"])
    if result.get("alerts"):     base["alerts"]     = result["alerts"][:1]
    if result.get("music_mood"): base["music_mood"] = result["music_mood"]
    return base


# ── Main tick ─────────────────────────────────────────────────────────────────

def tick():
    now      = datetime.now()
    events   = calendar_events_today()
    music    = now_playing()
    schedule = read_json(BASE / "schedule.json", [])

    sp_app, sp_screen = screenpipe_context()
    app = sp_app or active_app_fallback()

    events_str  = ", ".join(f"{e['title']} @{e['hour']:02d}:{e['minute']:02d}"
                             for e in events) or "none"
    active_task = next((t for t in schedule if t.get("status") == "active"), None)

    print(f"[{now.strftime('%H:%M')}] app={app or '?'} | "
          f"events={len(events)} | screen={'✓' if sp_screen else '✗'} | "
          f"music={'✓' if music else '✗'}")

    result = rules_engine(events, schedule, app, sp_screen, music)

    # AI enrichment if Ollama is ready or Groq key set
    if ollama_available() or GROQ_KEY:
        ctx = {"time": now.strftime("%H:%M"), "app": app, "screen": sp_screen,
               "events_str": events_str,
               "active_task": active_task["title"] if active_task else "none"}
        result = ai_enrich(ctx, result)

    # Write memory
    mem = read_json(BASE / "working_memory.json", {})
    mem["todays_goal"]  = result["goal"]
    mem["context"]      = result["context"]
    mem["last_updated"] = now.isoformat()
    atomic_write(BASE / "working_memory.json", mem)
    print(f"  🎯 {result['goal']}")

    # Music
    if result.get("music_mood") and not music:
        set_music_mood(result["music_mood"])

    # Alerts
    if result["alerts"]:
        existing     = read_json(BASE / "pending_alerts.json", [])
        existing_ids = {a["id"] for a in existing}
        for a in result["alerts"]:
            if a["id"] not in existing_ids:
                existing.append(a)
        atomic_write(BASE / "pending_alerts.json", existing)


# ── Entry ─────────────────────────────────────────────────────────────────────

def main():
    BASE.mkdir(parents=True, exist_ok=True)
    (BASE / "cache").mkdir(exist_ok=True)

    ollama_ready = ollama_available()
    print("=" * 50)
    print("🧠 Notchly Brain")
    print(f"   Local AI : {'gemma3:4b ✓' if ollama_ready else 'gemma3:4b (still downloading...)'}")
    print(f"   Cloud AI : {'Groq ✓' if GROQ_KEY else 'not set (optional)'}")
    print(f"   Screenpipe: {'✓' if HAS_REQUESTS else '✗'}")
    print(f"   Poll     : every {POLL_SECONDS // 60} min")
    print("=" * 50)

    while True:
        try:
            tick()
        except Exception as e:
            print(f"  ❌ {e}")
        print(f"  💤 next in {POLL_SECONDS // 60}min\n")
        time.sleep(POLL_SECONDS)


if __name__ == "__main__":
    main()
