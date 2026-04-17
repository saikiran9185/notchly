#!/usr/bin/env python3
"""
Notchly Brain — personal assistant daemon
Uses rule-based logic + optional Cloud AI (OpenRouter/Groq).
Works fully offline. AI layer is bonus when API key is valid.

Run: python3 brain_loop.py
"""

import json, os, time, subprocess, hashlib, sys
from datetime import datetime, timedelta
from pathlib import Path

try:
    import requests
    HAS_REQUESTS = True
except ImportError:
    HAS_REQUESTS = False

# ── Config ──────────────────────────────────────────────────────────────────
BASE           = Path.home() / "Documents/notchly/v2"
OPENROUTER_KEY = ""          # paste your key here — brain works without it too
GROQ_KEY       = ""          # alternative: groq.com free tier (very fast)
POLL_SECONDS   = 600         # 10 minutes

# AI enrichment: set to True once you have a working key
AI_ENABLED     = False

# ── Apple native helpers ────────────────────────────────────────────────────

def calendar_events_today() -> list[dict]:
    """Returns list of {title, hour, minute} for today's events."""
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
        raw = r.stdout.strip()
        if not raw or "unavailable" in raw:
            return []
        events = []
        for part in raw.split("~"):
            pieces = part.strip().split("|")
            if len(pieces) == 3:
                try:
                    events.append({
                        "title":  pieces[0].strip(),
                        "hour":   int(pieces[1]),
                        "minute": int(pieces[2]),
                    })
                except ValueError:
                    continue
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


def active_app() -> str:
    script = 'tell application "System Events" to return name of first process whose frontmost is true'
    try:
        r = subprocess.run(["osascript", "-e", script],
                           capture_output=True, text=True, timeout=3)
        return r.stdout.strip()
    except Exception:
        return ""


def screenpipe_context() -> str:
    if not HAS_REQUESTS:
        return ""
    try:
        since = (datetime.utcnow() - timedelta(minutes=3)).strftime("%Y-%m-%dT%H:%M:%SZ")
        r = requests.get("http://localhost:3030/search",
                         params={"content_type": "ocr", "limit": 5, "start_time": since},
                         timeout=3)
        items = r.json().get("data", [])
        chunks = []
        for item in items:
            txt = item.get("content", {}).get("text", "").strip()
            app = item.get("content", {}).get("app_name", "")
            if txt and len(txt) > 15:
                chunks.append(f"[{app}] {txt[:100]}")
        return " | ".join(chunks[:3])
    except Exception:
        return ""


# ── Music mood ──────────────────────────────────────────────────────────────

MOOD_PLAYLISTS = {
    "focus":    ["Focus", "Deep Work", "Lo-Fi", "Concentration"],
    "relax":    ["Chill", "Calm", "Acoustic", "Easy Listening"],
    "energy":   ["Workout", "Hype", "Upbeat"],
    "creative": ["Inspiration", "Ambient", "Creative"],
}

def set_music_mood(mood: str):
    candidates = MOOD_PLAYLISTS.get(mood.lower(), [])
    for name in candidates:
        script = f'tell application "Music" to try\nplay playlist "{name}"\nreturn "ok"\nend try\nreturn "no"'
        try:
            r = subprocess.run(["osascript", "-e", script],
                               capture_output=True, text=True, timeout=4)
            if "ok" in r.stdout:
                print(f"  🎵 Mood '{mood}' → '{name}'")
                return True
        except Exception:
            pass
    return False


# ── Data helpers ────────────────────────────────────────────────────────────

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


# ── Alert dedup ─────────────────────────────────────────────────────────────

_fired_at: dict[str, datetime] = {}

def can_fire(aid: str, cooldown_minutes: int = 30) -> bool:
    last = _fired_at.get(aid)
    if last and (datetime.now() - last).seconds < cooldown_minutes * 60:
        return False
    return True


def push_alert(alerts_list: list, aid: str, type_: str,
               title: str, message: str, priority: int = 2,
               left: str = "Skip", right: str = "Got it") -> bool:
    """Add alert to list and mark fired. Returns True if added."""
    if not can_fire(aid):
        return False
    existing_ids = {a["id"] for a in alerts_list}
    if aid in existing_ids:
        return False
    alerts_list.append({
        "id":           aid,
        "type":         type_,
        "title":        title,
        "message":      message,
        "priority":     priority,
        "action_left":  left,
        "action_right": right,
        "created_at":   datetime.now().isoformat(),
    })
    _fired_at[aid] = datetime.now()
    print(f"  🔔 Alert: [{type_}] {title}")
    return True


# ── Smart rules engine ──────────────────────────────────────────────────────

FOCUS_APPS   = {"Xcode", "Visual Studio Code", "Code", "PyCharm", "Sublime Text",
                "Notion", "Obsidian", "Bear", "Notes", "Terminal", "iTerm2"}
DISTRACT_APPS = {"YouTube", "Safari", "Chrome", "Firefox", "Twitter", "Reddit",
                 "Discord", "Messages", "Mail", "Slack"}

_last_app = ""
_app_start = datetime.now()
_distract_warned = False


def rules_engine(events: list[dict], schedule: list[dict],
                 app: str, screen: str, music: str) -> dict:
    """
    Pure logic brain. Returns {goal, context, alerts, music_mood}.
    No API calls needed.
    """
    global _last_app, _app_start, _distract_warned
    now = datetime.now()
    alerts: list[dict] = []

    # ── Track app switches ──
    if app and app != _last_app:
        _last_app  = app
        _app_start = now
        _distract_warned = False

    # ── Calendar: upcoming event alerts ──
    next_event = None
    for e in events:
        event_dt = now.replace(hour=e["hour"], minute=e["minute"], second=0, microsecond=0)
        delta_min = int((event_dt - now).total_seconds() / 60)
        if 0 < delta_min <= 10:
            next_event = e
            aid = stable_id("event_soon", e["title"])
            push_alert(alerts, aid, "calendar",
                       f"{e['title']} in {delta_min}m",
                       "Wrap up and get ready",
                       priority=1, left="Later", right="On it")
        elif delta_min == 0:
            aid = stable_id("event_now", e["title"])
            push_alert(alerts, aid, "calendar",
                       f"{e['title']} starting now",
                       "Time to join",
                       priority=1, left="Skip", right="Joining")

    # ── Distraction nudge: if in distract app > 20 min ──
    if app in DISTRACT_APPS:
        in_app_min = int((now - _app_start).total_seconds() / 60)
        if in_app_min >= 20 and not _distract_warned:
            _distract_warned = True
            active_task = next((t for t in schedule if t.get("status") == "active"), None)
            task_hint = f"Back to '{active_task['title']}'" if active_task else "Get back to work"
            aid = stable_id("distract", app)
            push_alert(alerts, aid, "nudge",
                       f"{in_app_min}min in {app}",
                       task_hint,
                       priority=2, left="5 more min", right="Back to work")

    # ── Focus streak praise (silent memory update, no alert) ──
    if app in FOCUS_APPS:
        in_app_min = int((now - _app_start).total_seconds() / 60)
        _distract_warned = False  # reset distraction flag

    # ── Music mood suggestion ──
    hour = now.hour
    mood_suggestion = None
    if not music:  # only suggest if nothing playing
        if 9 <= hour < 13:
            mood_suggestion = "focus"
        elif 13 <= hour < 15:
            mood_suggestion = "relax"
        elif 15 <= hour < 19:
            mood_suggestion = "focus"
        elif 19 <= hour:
            mood_suggestion = "relax"

    # ── Goal + context ──
    active_task = next((t for t in schedule if t.get("status") == "active"), None)
    pending = [t["title"] for t in schedule if t.get("status") == "pending"]

    if next_event and next_event in [e for e in events]:
        goal = f"Prep for {next_event['title']}"
    elif active_task:
        goal = f"Finish {active_task['title']}"
    elif pending:
        goal = f"Start {pending[0]}"
    else:
        goal = "Great, you're free"

    ctx_parts = []
    if app:         ctx_parts.append(f"Using {app}")
    if active_task: ctx_parts.append(f"Task: {active_task['title']}")
    if music:       ctx_parts.append(f"Playing: {music[:30]}")
    context_str = " · ".join(ctx_parts) or "Idle"

    return {
        "goal":       goal,
        "context":    context_str,
        "alerts":     alerts[:1],   # max 1 per cycle
        "music_mood": mood_suggestion,
    }


# ── Optional AI enrichment ──────────────────────────────────────────────────

AI_SYSTEM = """You are Notchly Brain. Given context, return ONE JSON object (no markdown):
{"todays_goal":"≤8 words","working_memory":"≤20 words","alerts":[],"music_mood":null}
Alert schema: {"id":"short_id","type":"calendar|nudge|ai","title":"≤6 words","message":"≤12 words","priority":2,"action_left":"Skip","action_right":"Got it"}
Fire at most 1 alert. Only if truly urgent."""

def ai_enrich(context: dict, base_result: dict) -> dict:
    """Optional AI pass over the rule-based result. Falls back to base if fails."""
    if not HAS_REQUESTS or not (OPENROUTER_KEY or GROQ_KEY):
        return base_result
    prompt = f"""Time:{context['time']} | App:{context['app']} | Events:{context['events_str']}
Active task:{context['active_task']} | Screen:{context['screen'][:200]}
Rule suggestion — goal:"{base_result['goal']}" context:"{base_result['context']}"
Improve or confirm these. Return JSON only."""
    headers = {"Content-Type": "application/json", "X-Title": "Notchly"}
    body = {"messages": [{"role":"system","content":AI_SYSTEM},{"role":"user","content":prompt}],
            "max_tokens": 250, "temperature": 0.2}
    try:
        if OPENROUTER_KEY:
            headers["Authorization"] = f"Bearer {OPENROUTER_KEY}"
            url, body["model"] = "https://openrouter.ai/api/v1/chat/completions", "anthropic/claude-3-haiku-20240307"
        elif GROQ_KEY:
            headers["Authorization"] = f"Bearer {GROQ_KEY}"
            url, body["model"] = "https://api.groq.com/openai/v1/chat/completions", "llama-3.1-8b-instant"
        r = requests.post(url, headers=headers, json=body, timeout=10)
        raw = r.json()["choices"][0]["message"]["content"].strip()
        if raw.startswith("```"):
            raw = raw.split("```")[1]
            if raw.startswith("json"): raw = raw[4:]
        parsed = json.loads(raw.strip())
        base_result["goal"]    = parsed.get("todays_goal", base_result["goal"])
        base_result["context"] = parsed.get("working_memory", base_result["context"])
        if parsed.get("alerts"):
            base_result["alerts"] = parsed["alerts"][:1]
        if parsed.get("music_mood"):
            base_result["music_mood"] = parsed["music_mood"]
        print("  ✨ AI enriched")
    except Exception as e:
        print(f"  ℹ️  AI skipped: {e}")
    return base_result


# ── Main tick ───────────────────────────────────────────────────────────────

def tick():
    now     = datetime.now()
    events  = calendar_events_today()
    app     = active_app()
    screen  = screenpipe_context()
    music   = now_playing()
    schedule = read_json(BASE / "schedule.json", [])

    events_str = ", ".join(f"{e['title']} @{e['hour']:02d}:{e['minute']:02d}" for e in events) or "none"
    active_task = next((t for t in schedule if t.get("status") == "active"), None)

    print(f"[{now.strftime('%H:%M')}] app={app or '?'} | events={len(events)} | music={'yes' if music else 'no'}")

    result = rules_engine(events, schedule, app, screen, music)

    if AI_ENABLED:
        ctx = {"time": now.strftime("%H:%M"), "app": app, "screen": screen,
               "events_str": events_str, "active_task": active_task["title"] if active_task else "none"}
        result = ai_enrich(ctx, result)

    # Write memory
    mem = read_json(BASE / "working_memory.json", {})
    mem["todays_goal"]   = result["goal"]
    mem["context"]       = result["context"]
    mem["last_updated"]  = now.isoformat()
    atomic_write(BASE / "working_memory.json", mem)
    print(f"  🎯 {result['goal']}")

    # Music
    if result.get("music_mood") and not music:
        set_music_mood(result["music_mood"])

    # Alerts
    if result["alerts"]:
        existing = read_json(BASE / "pending_alerts.json", [])
        existing_ids = {a["id"] for a in existing}
        for a in result["alerts"]:
            if a["id"] not in existing_ids:
                existing.append(a)
        atomic_write(BASE / "pending_alerts.json", existing)


# ── Entry point ─────────────────────────────────────────────────────────────

def main():
    BASE.mkdir(parents=True, exist_ok=True)
    (BASE / "cache").mkdir(exist_ok=True)

    print("=" * 48)
    print("🧠 Notchly Brain")
    print(f"   Poll : every {POLL_SECONDS // 60} min")
    print(f"   AI   : {'enabled' if AI_ENABLED else 'rule-based (fast)'}")
    print(f"   Data : {BASE}")
    print("=" * 48)
    if not HAS_REQUESTS:
        print("⚠️  pip3 install requests  (needed for Screenpipe + AI)")
    print()

    while True:
        try:
            tick()
        except Exception as e:
            print(f"  ❌ {e}")
        print(f"  💤 Next tick in {POLL_SECONDS//60} min\n")
        time.sleep(POLL_SECONDS)


if __name__ == "__main__":
    main()
