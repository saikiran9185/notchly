# Notchly — Master Engineering Specification & TODO
**Version:** V3 Codex  
**Status:** Active Development  
**Audience:** Senior macOS Engineer, Product Lead, QA  
**Last Updated:** 2026-04-17

---

## 0. WHAT THIS APP IS

Notchly is a native macOS assistant that lives permanently in the MacBook Pro notch. It is not a menu bar app, not a status bar icon, not a floating widget. It is a dark panel that grows downward from the physical camera cutout, shows contextual information, and collapses back to near-invisible when not needed.

**Core principle:** The app speaks first. You respond with one gesture. Then it's gone.

---

## 1. CURRENT BUILD STATE

### 1.1 What is Built and Working
| Component | File | Status |
|-----------|------|--------|
| NSPanel at .statusBar level (layer 25) | NotchWindowController.swift | ✅ Working |
| Notch geometry calibration (auxiliaryTopLeftArea) | NotchState.swift | ✅ Working |
| Stage system (S0→S4) with animated transitions | NotchRootView.swift | ✅ Working |
| Scroll accumulator with phase tracking | NotchState.swift | ✅ Working |
| Volume monitor (CoreAudio polling at 0.25s) | VolumeMonitor.swift | ✅ Working |
| Now Playing (Music + Spotify via DistributedNotificationCenter) | NowPlayingMonitor.swift | ✅ Working |
| Bluetooth audio device + battery (ioreg) | BatteryMonitor.swift | ✅ Working |
| Calendar events via EventKit | CalendarManager.swift | ✅ Working |
| DataStore polling ~/Documents/notchly/v2/ at 15s | DataStore.swift | ✅ Working |
| Stage 0 — idle pill with pulsing dot | Stage0View.swift | ✅ Working |
| Stage 1 — notification with swipe offset | Stage1NotificationView.swift | ✅ Working |
| Stage 1 — timer with progress | Stage1TimerView.swift | ✅ Working |
| Stage 1 — volume HUD | Stage1VolumeView.swift | ✅ Working |
| Stage 1.5 — hover card | Stage15HoverView.swift | ✅ Working |
| Stage 2 — card with left/right/center actions | Stage2CardView.swift | ✅ Working |
| Stage 3 — dashboard (calendar, music, BT, tasks) | Stage3DashboardView.swift | ✅ Working |
| Stage 4 — chat UI (stub, no AI backend) | Stage4ChatView.swift | ⚠️ UI only |
| Settings window | SettingsView.swift | ✅ Working |
| NSTrackingArea hover (no Accessibility needed) | NotchWindowController.swift | ✅ Working |
| Continuity banner (action confirmation) | ContinuityBanner.swift | ✅ Working |
| AsymmetricRoundedRect (notch-flush shape) | AsymmetricRoundedRect.swift | ✅ Working |
| ND design token system (colors, fonts, spacing) | NotchlyDesign.swift | ✅ Working |

### 1.2 What is Stubbed / Incomplete
| Feature | Status | Priority |
|---------|--------|----------|
| Stage 4 chat — real AI backend (Claude/OpenClaw) | Stub only | P0 |
| Swipe left/right gesture on notifications | Not implemented | P0 |
| Global hotkey ⌘⇧Space for Stage 4 | Not implemented | P0 |
| Scroll-to-stage gesture (two-finger trackpad) | Phase-aware but no scroll→stage from global monitor | P1 |
| Auto-collapse Stage 1 after 30s | Implemented (30s timer) | ✅ |
| Idle detection (Mac lid open after 5h) | Not implemented | P1 |
| Context detection (frontmost app awareness) | Not implemented | P1 |
| Self-learning algorithm (W score per notification type) | Not implemented | P1 |
| OpenClaw plugin bridge (reads ~/Documents/notchly/v2/) | DataStore exists, no OpenClaw writer | P1 |
| macOS launchd auto-start plist | Not implemented | P2 |
| Week summary (visible W score trend) | Not implemented | P2 |
| Haptic feedback on swipe commit | Not implemented | P2 |
| Timer tap-to-pause (Stage 1 Timer) | UI exists, wired in NotchState | ✅ |
| Dynamic button placement (most-pressed goes right) | Not implemented | P2 |
| Stage 2B — missed notifications list with inline reply | Not implemented | P2 |
| Context peek in Stage 4 (schedule strip on schedule keywords) | Not implemented | P3 |
| App-aware action buttons (Blender → "Open Blender") | Not implemented | P3 |
| Rejection count + Stage 1.5 Diagnosis Mode | Not implemented | P3 |
| Snooze / postpone that actually writes back to DataStore | Partial (marks done, doesn't reschedule) | P1 |

---

## 2. STAGE BEHAVIOR SPEC

Every stage must match this spec exactly. Width/height in points (2× for Retina pixels).

### S0 — Idle (Default)
**Dimensions:** 180 × 32 pt  
**Position:** Centered on notch, top of screen, flush with camera cutout  
**Appearance:** Pure black `AsymmetricRoundedRect(topRadius:0, bottomRadius:15)`. Single 4pt dot centered at bottom, 7pt padding from edge.

**Dot states:**
- `hasPendingAlert` → orange dot, pulsing (scale 1.0→1.6, 1.1s easeInOut repeat)  
- `hasActiveTask` → green dot, pulsing  
- `isPlayingMusic` → blue dot, pulsing  
- All clear → muted gray dot, static (opacity 0.35)  

**Behavior:**
- No text, no labels. Purely visual.
- Double-tap → jump directly to S4 Chat (skips S1/S2/S3)
- Single tap → S15 Hover
- Scroll down (two-finger trackpad, >12pt delta) → S15 Hover
- If external monitor is primary: window must track built-in screen notch only

**TODO:**
- [ ] Confirm dot is visible against physical notch on all MacBook Pro models (14", 16")
- [ ] Test dot pulse on M3 Pro (notch height = 38pt vs M1 = 38pt; check inset values)
- [ ] Double-tap to S4 currently requires exact double-tap timing — tune `count: 2` threshold or use `TapGesture` sequence

---

### S1 — Notification
**Dimensions:** 350 × (widgetHeight+21) pt, min 58pt height  
**Auto-collapse:** 30 seconds after appearing, collapses to S0 silently  
**Hover pause:** If cursor enters notch zone, cancel auto-collapse timer  

**Appearance:** Single line message with icon badge on left. Alert type drives icon and badge color:
- `nudge` → clock.fill, amber  
- `calendar` → calendar, blue  
- `reminder` → bell.fill, orange  
- `notion` → checkmark.square, purple  
- `ai` → sparkles, teal  

**On hover — buttons appear:**
- Slide down from inside the bar (not a popup, the bar itself grows taller)
- Full width of notification bar, split two equal buttons
- Left button = `leftAction` (e.g. "Skip")  
- Right button = `rightAction` (e.g. "Got it")
- Hint text: `← skip · got it →` shown in tertiary color when first hovering

**Swipe gesture (two-finger horizontal, cursor in notch zone):**
- Swipe right (>30pt delta) → fires right action (primary/most-pressed)
- Swipe left (>30pt delta) → fires left action (dismiss/skip)
- Below 30pt → spring back
- Visual: bar slides in swipe direction with `swipeOffset`, max ±80pt before snap
- On commit: notification "sucks back" into notch (scale to 0, opacity to 0, 0.22s ease-in)
- Right swipe: green wash during drag. Left swipe: warm gray wash (not red)

**TODO:**
- [ ] **P0** Implement two-finger horizontal swipe gesture on notch zone — currently only vertical scroll is handled
- [ ] **P0** Implement swipe spring-back when delta < 30pt
- [ ] **P0** Implement color wash (green/gray) proportional to swipe delta
- [ ] **P0** Implement "suck back" commit animation
- [ ] **P0** Show hint text `← skip · got it →` on first hover (once per session, not every hover)
- [ ] **P1** `action_left` / `action_right` fields in `PendingAlert` schema — use these to override default button labels dynamically
- [ ] **P1** Notification type drives icon — wire `alertType` to icon map in `Stage1NotificationView`
- [ ] **P1** Priority field drives display order — P1 alerts interrupt even during active task (bypass idle check)
- [ ] **P2** Continuity banner shows confirmed action for 2.5s after swipe commit

---

### S1 — Timer (Active Task)
**Dimensions:** 280–360 × (widgetHeight+32) pt  
**Behavior:** Shows active task title, timer label, arc progress ring

**Timer display cycles every 4s (auto, pauses on hover):**
1. Countdown: "24m left"
2. Elapsed: "36m in"  
3. Percentage: "60% done"

**Tap the timer number/label → pause/resume**
- Paused state: timer label → "Paused ⏸", dot color → gray
- Resumed: restore countdown, dot color → green

**Hover → buttons appear (same slide mechanic as S1 Notification):**
- Left: "Break" — starts a break task, collapses to S0
- Right: "Done" — marks task done in DataStore, loads next task

**Swipe right → "Done", swipe left → "Break"**

**TODO:**
- [ ] **P0** Arc progress ring — currently using `timerProgress` float but no arc drawn in view, only in `Stage1TimerView`. Verify arc renders correctly
- [ ] **P0** Timer cycle (countdown→elapsed→percent) — currently static label. Implement rotation `@State var cycleIndex` with 4s `Timer`
- [ ] **P0** Swipe gestures on timer stage (same as Notification)
- [ ] **P1** When `timerPaused == true`, dot should go gray/static — wire to `Stage0View` dot state
- [ ] **P1** "Done" action should find next pending task and preload it into `currentMessage` before collapsing — feels instant
- [ ] **P2** "Break" should create a `ScheduleTask(status: "break")` in DataStore with a 10m duration by default

---

### S1 — Volume HUD
**Dimensions:** 220 × (notchHeight+30) pt, min 60pt  
**Trigger:** System volume change detected by `VolumeMonitor` (polling every 0.25s, threshold >1%)  
**Auto-collapse:** 2.5s after last volume change  
**No hover buttons — this is read-only**

**Appearance:**
- Icon left: speaker SF symbol (1→2→3 waves by level, slash if muted)
- Bar center: 4pt tall capsule, gradient fills proportionally
  - Normal: green→green (opacity 0.7→1.0)
  - Loud (>80%): green→orange
  - Muted: red (opacity 0.4→1.0) at 0 width
- Label right: "47%" in SF Mono 11pt, or "Muted"

**TODO:**
- [ ] **P1** Volume HUD should not interrupt S1 Notification/Timer — if a notification is showing, volume change updates silently (icon in corner?) rather than hijacking the stage
- [ ] **P1** Test mute toggle detection — `muteVal` from CoreAudio fires on ⌥ + volume key mute?
- [ ] **P2** Tap anywhere on volume HUD → go to S0 (currently wired via `handlePrimaryTap`)

---

### S15 — Hover
**Dimensions:** 340 × 70 pt  
**Trigger:** Cursor enters notch tracking zone (NSTrackingArea, .activeAlways)  
**Exit:** Cursor leaves zone → collapse to S0 after 200ms debounce  

**Content — context-aware, shows most relevant of:**
1. Active task: "⬤ Task title · 24m left" + next task preview
2. Current calendar event: event title + time remaining
3. Now playing: song · artist (scrolling marquee if too long)
4. Bluetooth: device name + battery bar
5. Missed count badge: "● 3 missed" in orange if pendingAlerts > 0

**Scroll hint:**  
Small `chevron.down` icon at bottom center, 0.4 opacity, indicates scroll-to-expand

**TODO:**
- [ ] **P0** Hover exit debounce — currently `setHover(false)` fires immediately on exit, causing flicker if cursor brushes edge. Add 200ms delay before collapse
- [ ] **P1** Context priority order — implement ranked display: active task > current event > now playing > BT > free
- [ ] **P1** Missed count badge — if `pendingAlerts.count > 0`, show orange dot + count in top-right of hover card. Tapping this goes to S2B (missed list)
- [ ] **P2** Marquee scroll for long song titles (>28 chars)
- [ ] **P2** Scroll hint chevron should animate (subtle bob, 2s repeat)

---

### S2 — Card
**Dimensions:** 380 × 180 pt  
**Trigger:** Single tap on S15 Hover, or dragging to medium depth  

**Content:**
- Large icon/badge (36×36, RoundedRectangle)
- Title (task name or alert title) — SF Pro Medium 15pt
- Subtitle (project name, event location, or secondary message) — SF Pro 12pt tertiary
- Action buttons: Left / Center / Right (center only for calendar RSVP)
- "Scroll to expand" hint at bottom

**Action button behavior:**
- Swipe right → right action
- Swipe left → left action
- Center only reachable by click (never swipe)

**TODO:**
- [ ] **P1** S2B mode — when user taps "3 missed" from S15, show scrollable list of missed alerts. Each item is a row with title + inline quick-reply buttons that expand on row-tap
- [ ] **P1** Swipe gesture at this stage mirrors S1 swipe
- [ ] **P2** App-specific icon — if task has a project name matching a known app (Blender, Figma, Xcode), show that app's icon in the badge slot
- [ ] **P2** Calendar RSVP flow — if alert type is `calendar`, show Going/Later/Decline as three buttons

---

### S3 — Dashboard
**Dimensions:** 510 × (expandedHeight+110) pt, min 340pt  
**Trigger:** Long scroll, or S2 → tap  
**Content columns:** Today's schedule left, live data right  

**Left column — Schedule:**
- Header: "Today" + date (e.g. "Thu 17")
- Active task row: green dot + title + timer arc + "●" Done circle button (tap = mark done instantly)
- Pending tasks: up to 3 rows, each with "●" circle button to tick off
- "See all" link if more than 3 pending
- Notion tasks section (In Progress first, then To Do, up to 3)

**Right column — Live:**
- Calendar: current event (title + time remaining) or next event (title + "in Xm")
- Now Playing: song + artist + mini progress bar
- Bluetooth: device + battery colored bar (red < 20%)
- AI goal: purple card with `workingMemory.todays_goal`

**Footer:** "Double-tap anywhere to ask Notchly"

**TODO:**
- [ ] **P1** Task circle buttons — currently no tap handler on individual task rows in S3. Add `.onTapGesture` to each task row that calls `DataStore.shared.markTaskDone(task.id)` and animates row away
- [ ] **P1** Notion "In Progress" row — show inline progress indicator (not just a label)
- [ ] **P1** S3 should not auto-collapse — only collapses on scroll-up or explicit escape
- [ ] **P2** "See all" tasks → does not navigate anywhere currently. Should expand S3 height or open system app
- [ ] **P2** Calendar section should show next 2 events if none is current (not just one)
- [ ] **P2** Missed events count — if `missedCalCount > 0` show "⚠️ N missed today" in red below calendar section
- [ ] **P3** Mini now-playing progress bar — needs actual track position/duration (MediaRemote private API or polling approach)
- [ ] **P3** Add "Reschedule" button to each pending task row

---

### S4 — Chat
**Dimensions:** 510 × 320 pt  
**Trigger:** Double-tap from S0, OR ⌘⇧Space from any app  
**Session lock:** Stays open if conversation active or action card unacknowledged  
**Auto-close:** 60s idle (no input, no pending response), or cursor leaves for 60s  
**Close:** Esc, or cursor away for 60s with no active session  

**Content:**
- Header: sparkles icon + "Ask Notchly" + loading spinner when thinking
- Message list: user bubbles (right-aligned, surface bg) + AI bubbles (left-aligned)
- Input bar: TextField + send button (appears when draft not empty)
- Placeholder hint: "What should I focus on next?"

**Context peek (when schedule keyword detected):**
- User types "tomorrow", "move", "reschedule", "when", "free" → faded schedule strip appears above input showing next 3 events
- Strip fades in/out based on keyword presence, no AI call needed

**AI backend (current state: stub):**
- Currently returns hardcoded "Got it. I'll help you focus on that."
- Needs: Claude API integration OR OpenClaw bridge

**TODO:**
- [ ] **P0** Wire ⌘⇧Space global hotkey — use `CGEventTap` or `Carbon.RegisterEventHotKey`. Must work without Accessibility permission via `CGEventTapCreate` at `kCGHIDEventTap` level
- [ ] **P0** 60-second idle auto-close — add `idleTimer` that resets on every keystroke/message. Active session (unread AI response) pins window
- [ ] **P0** Real AI backend — Claude API (`claude-sonnet-4-6`) with system prompt including current task, pending alerts, calendar events, working memory
- [ ] **P1** Context peek — keyword detection on `draft.onChange`, show/hide `CalEventStripView` (compact 3-event list above input)
- [ ] **P1** OpenClaw bridge — if `~/Documents/notchly/v2/openclaw_response.json` exists and modified < 30s, prefer it over Claude API
- [ ] **P2** Action cards — AI response can embed structured JSON to create/modify tasks. Render as a card inside the chat bubble with a "Confirm" button
- [ ] **P2** Chat history — persist last 10 messages to `~/Documents/notchly/v2/chat_history.json`
- [ ] **P3** Animate card expansion when OpenClaw response is long

---

## 3. GESTURE SYSTEM

All gestures require cursor to be inside the notch hover zone (600 × 120 pt, centered on notch).

### 3.1 Two-Finger Vertical Scroll (Trackpad)
| Delta | Action |
|-------|--------|
| 0 to +11 | No stage change |
| +12 to +35 | → S15 Hover |
| +36 to +79 | → S2 Card |
| +80 and above | → S3 Dashboard |
| −16 and below | → S0 Idle (collapse) |

**Phase rules (currently implemented):**
- `.ended` / `.cancelled` → schedule 0.45s reset timer, do not process delta
- `momentumPhase` not empty → ignore (inertia scroll)
- Mouse wheel (no phase) → 0.35s idle reset timer

**TODO:**
- [ ] **P1** Test scroll-to-stage feel. Current thresholds (12/36/80/-16) may need tuning on different trackpad speeds. Consider `sensitivity` setting in SettingsManager
- [ ] **P1** On external monitor setup: global scroll monitor uses `cursorIsInHoverZone()` which checks `screenMidX` — verify this uses built-in screen midX, not external
- [ ] **P2** Magic Mouse: horizontal swipe via `scrollingDeltaX` — should trigger swipe left/right action at any active-button stage

### 3.2 Two-Finger Horizontal Swipe (Trackpad) — NOT YET IMPLEMENTED
**Target stages:** S1 Notification, S1 Timer, S2 Card  
**Threshold:** 30pt committed, <30pt spring-back  
**Implementation approach:** Monitor `scrollingDeltaX` in `registerScroll`. If `abs(deltaX) > abs(deltaY)` treat as horizontal swipe, route to `applySwipeOffset`/`commitSwipeIfNeeded`.

**TODO:**
- [ ] **P0** Add `deltaX` parameter to `registerScroll`
- [ ] **P0** When `abs(deltaX) > abs(deltaY) && abs(deltaX) > 4`: route to `applySwipeOffset(deltaX)` instead of vertical stage logic
- [ ] **P0** `commitSwipeIfNeeded` already exists — confirm threshold 40pt → change to 30pt
- [ ] **P0** Add color wash to `Stage1NotificationView` — overlay with green/gray `.blendMode(.overlay)` at opacity proportional to `abs(swipeOffset)/80`
- [ ] **P0** Add "suck-back" animation: `withAnimation(.easeIn(duration: 0.22)) { swipeOffset = stage.width * sign }`

### 3.3 Single Tap
| Stage | Result |
|-------|--------|
| S0 | → S15 Hover |
| S1 Notification | → S2 Card |
| S1 Timer | → S2 Card |
| S1 Volume | → S0 |
| S15 Hover | → S2 Card |
| S2 Card | → S3 Dashboard |
| S3 Dashboard | → S0 |
| S4 Chat | no-op (handled by text field) |

**TODO:**
- [ ] **P1** Tap on missed count badge in S15 → should go to S2B (missed list mode), not S2 Card

### 3.4 Double-Tap
| Stage | Result |
|-------|--------|
| Any | → S4 Chat |

**Note:** If S1 is active, double-tap goes to S4, overriding S1. Use ⌘⇧Space to reach S4 without disturbing S1.

**TODO:**
- [ ] **P1** Double-tap on an active S1 alert currently works but loses the alert. Should the alert persist in S4 as context?

### 3.5 Swipe Left/Right (on buttons)
Already described per stage above. Summary:
- Requires `leftAction` or `rightAction` to be non-nil
- `commitSwipeIfNeeded(predictedEnd:)` dispatches to `perform(_ action:)`
- 30pt threshold (currently 40pt — change to 30)

### 3.6 Context Menu (Right-Click)
- "Open Settings" → `NotificationCenter.post(.notchOpenSettings)`
- "Reset to Idle" → `state.reset()`
- "Cycle Demo Stage" → `state.cycleDemoStage()`

**TODO:**
- [ ] **P2** Add "Dismiss Alert" to context menu when S1 Notification is active
- [ ] **P2** Add "Quit Notchly" to context menu (currently requires Activity Monitor)

---

## 4. WINDOW & POSITIONING

### 4.1 NSPanel Configuration
```
styleMask:          [.borderless, .nonactivatingPanel]
level:              .statusBar  (CGWindowLevel 25)
collectionBehavior: [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
isOpaque:           false
hasShadow:          false
backgroundColor:    .clear
hidesOnDeactivate:  false
canBecomeKey:       false
canBecomeMain:      false
```

### 4.2 Frame Calculation
```
x = screenMidX - (width / 2) + horizontalOffset
y = screenMaxY - height
```

**Built-in screen detection:** `CGDisplayIsBuiltin()` — always prefer built-in over external. If no built-in (desktop Mac), use `NSScreen.main`.

**Notch geometry:** `auxiliaryTopLeftArea.maxX` to `auxiliaryTopRightArea.minX` — exact notch bounds. Falls back to inferred width by screen width (1600pt→162, else→150/184).

**TODO:**
- [ ] **P1** When external monitor is primary (user's current setup: X=3227), the window is appearing on external monitor. Fix: `currentScreen()` should always return built-in first, then main, then first. Verify `builtinScreen()` is returning correct result
- [ ] **P1** Screen arrangement change (`NSApplication.didChangeScreenParametersNotification`) — verify `recalculate(using:)` fires and `applyWindowFrame` re-positions correctly
- [ ] **P2** Stage transitions: `applyWindowFrame(animated: true)` uses 0.28s `easeInEaseOut` for frame. SwiftUI uses `ND.Motion.expand` for content. These should be synchronized (same duration)
- [ ] **P2** When window width changes (S0 180pt → S3 510pt), the `x` recalculates cleanly — verify no positional jump on transition

### 4.3 macOS Version Compatibility
- Minimum target: macOS 13.0 (Ventura) — notch hardware is M1 Pro and later
- `safeAreaInsets.top` → notch height. On non-notch Macs this returns 0, fallback to 38pt
- `requestFullAccessToEvents` requires macOS 14.0+ — `#available` check exists ✅
- `auxiliaryTopLeftArea` / `auxiliaryTopRightArea` — macOS 12.0+ ✅

**TODO:**
- [ ] **P1** Test on macOS 13.0 (Ventura) — `auxiliaryTopLeftArea` API availability?
- [ ] **P1** Test on non-notch MacBook (Air M1) — S0 should fall back gracefully to 180×38 centered on screen top

---

## 5. DATA LAYER

### 5.1 File System Contract
All data lives at `~/Documents/notchly/v2/`:

| File | Schema | Writer | Reader | Poll |
|------|--------|--------|--------|------|
| `schedule.json` | `[ScheduleTask]` | OpenClaw Python / DataStore | DataStore | 15s |
| `pending_alerts.json` | `[PendingAlert]` | OpenClaw Python / DataStore | DataStore | 15s |
| `working_memory.json` | `WorkingMemory` | OpenClaw Python | DataStore | 15s |
| `cache/notion_cache.json` | `[NotionTask]` | OpenClaw Python | DataStore | 15s |
| `chat_history.json` | `[ChatMessage]` | Stage4ChatView | Stage4ChatView | on load |
| `openclaw_response.json` | `OpenClawResponse` | OpenClaw Python | Stage4ChatView | on demand |

### 5.2 ScheduleTask Schema
```json
{
  "id": "uuid",
  "title": "Curry & Beans logo",
  "duration_minutes": 90,
  "due": "2026-04-18T17:00:00Z",
  "status": "active|pending|done|break",
  "project": "Client Work",
  "priority": 1
}
```

**TODO:**
- [ ] **P1** Add `rejection_count: Int` field — increments on "Skip"/"Later" actions. At 3, trigger Diagnosis Mode (S1.5)
- [ ] **P1** Add `start_time: String?` — actual start timestamp for elapsed calculation
- [ ] **P1** `minutesLeft` currently returns `duration_minutes` (wrong). Fix: `minutesLeft = duration_minutes - minutesElapsed`. Need `start_time` to compute elapsed
- [ ] **P2** Add `app_hint: String?` — e.g. "com.blenderfoundation.blender". Stage 2 uses this for app-specific button

### 5.3 PendingAlert Schema
```json
{
  "id": "uuid",
  "type": "nudge|calendar|reminder|notion|ai",
  "title": "Sequential Narratives in 10m",
  "message": "Lecture starts at 2:30 PM, Block A room 204",
  "created_at": "2026-04-17T14:20:00Z",
  "priority": 1,
  "action_left": "Skip",
  "action_right": "On my way"
}
```

**TODO:**
- [ ] **P1** `action_left` / `action_right` are defined in schema but not used in `NotchState.leftAction` / `rightAction`. Fix: if `action_left` is set on current alert, return that label instead of hardcoded "Skip"
- [ ] **P1** `priority` field: P1 alerts (priority=1) should bypass idle check — show even if active task is running

### 5.4 DataStore — Known Issues
- [ ] **P1** `loadAlerts()` parses `priority` but `PendingAlert` has `priority: Int` — confirm schema matches (currently `priority` default not set in JSON samples)
- [ ] **P1** `markTaskDone` saves but doesn't notify next pending task. After marking done, `applySchedule` should re-fire to pick up next active task
- [ ] **P1** `dismissAlert` writes synchronously on main thread — move to background queue, write atomically (write to temp file, rename)
- [ ] **P2** `DataStore.start()` fires `load()` immediately, then every 15s. If file changes between polls (OpenClaw writes), notification is delayed up to 15s. Consider `DispatchSource.makeFileSystemObjectSource` for instant file-change detection

---

## 6. SERVICES

### 6.1 VolumeMonitor
- Polls at 0.25s via `Timer` on main thread ← should be on background queue, dispatch result to main
- Uses `kAudioObjectPropertyElementMain` (correct for macOS 12+)
- Detects: volume scalar + mute toggle

**TODO:**
- [ ] **P1** Move polling timer to `DispatchQueue.global(qos: .utility)` — CoreAudio calls are not main-thread only but polling on main adds latency budget pressure
- [ ] **P2** `kAudioHardwarePropertyDefaultOutputDevice` PropertyListener instead of polling — event-driven, zero overhead

### 6.2 NowPlayingMonitor
- Listens to `com.apple.Music.playerInfo` and `com.spotify.client.PlaybackStateChanged`
- Missing: Apple Podcasts, YouTube in browser (no distributed notification), system audio

**TODO:**
- [ ] **P2** Add `com.apple.podcasts.notification.playerInfo` observer
- [ ] **P3** MediaRemote.framework private API for universal "now playing" — covers browser media, Reeder, all MPNowPlayingInfoCenter clients

### 6.3 BatteryMonitor
- Uses IOBluetooth + ioreg subprocess for battery
- Polls every 30s

**TODO:**
- [ ] **P1** `ioreg -r -k BatteryPercent` — this reads ALL devices. If multiple BT devices connected, may pick wrong one. Fix: filter by device address
- [ ] **P2** Replace subprocess with `IOKit` direct read: `IORegistryEntryCreateCFProperty(entry, "BatteryPercent", ...)` — no process spawn
- [ ] **P2** Mac's own battery (not BT) is not shown anywhere. Add `IOPMBatteryInfo` read for Mac battery in Stage 3

### 6.4 CalendarManager
- `EKEventStore` with full access (macOS 14+)
- Fetches today's events, refreshes every 60s
- Filters `isAllDay` events

**TODO:**
- [ ] **P1** Add tomorrow's events to `nextEvent` logic — if no more events today after current time, peek at tomorrow
- [ ] **P1** Calendar source filtering — user may want to exclude personal calendars. Add `CalendarManager.excludedCalendarIDs: Set<String>` in SettingsManager
- [ ] **P2** Event notifications — when next event is <10 min away, create a `PendingAlert` and write to DataStore. This closes the loop: calendar feeds alerts, DataStore polls alerts, S1 shows them

---

## 7. OPENCLAW INTEGRATION

OpenClaw is the optional power layer. Without it, Notchly works standalone using DataStore files. With it, the files are written by OpenClaw's Python brain.

### 7.1 Bridge Protocol
OpenClaw writes to `~/Documents/notchly/v2/` using the file contract above. Notchly reads. One-way data flow.

For chat (S4 → OpenClaw):
1. User sends message in Stage4ChatView
2. Notchly writes request to `~/Documents/notchly/v2/chat_request.json`
3. OpenClaw detects file change via FSEvents, processes, writes `openclaw_response.json`
4. Notchly polls response file for 30s; if no response, falls back to Claude API

### 7.2 chat_request.json Schema
```json
{
  "id": "uuid",
  "message": "Move the Curry & Beans task to tomorrow",
  "context": {
    "active_task": "ScheduleTask object",
    "current_events": "[CalEvent array]",
    "working_memory": "WorkingMemory object"
  },
  "timestamp": "2026-04-17T14:35:00Z"
}
```

### 7.3 openclaw_response.json Schema
```json
{
  "request_id": "uuid",
  "message": "Done. Curry & Beans moved to tomorrow at 3 PM.",
  "action": {
    "type": "reschedule_task|add_task|dismiss_alert|set_goal|none",
    "payload": {}
  },
  "timestamp": "2026-04-17T14:35:02Z"
}
```

**TODO:**
- [ ] **P0** Write `chat_request.json` in `Stage4ChatView.sendMessage()`
- [ ] **P0** Poll `openclaw_response.json` — check `request_id` matches, check `timestamp` < 30s old
- [ ] **P0** If no OpenClaw response in 5s, fall back to Claude API
- [ ] **P1** `action` field — if type is `reschedule_task`, call `DataStore.shared.markTaskDone` / `addTask` to immediately update local state. Don't wait for next poll
- [ ] **P2** Indicator in S4 header: "OpenClaw" vs "Claude" badge — shows which brain is responding

---

## 8. SELF-LEARNING ALGORITHM

### 8.1 W Score (Notification Weight)

Each notification type+context gets a confidence score `W ∈ [0, 1]`.

**Update rule (Exponential Moving Average):**
```
W_new = W_old × 0.85 + signal × 0.15
```
Where:
- `signal = 1.0` for primary action tap (right button / swipe right)
- `signal = 0.4` for secondary action (left button / swipe left)  
- `signal = 0.0` for ignored (notification auto-collapsed with no interaction)
- `signal = -0.2` for dismissed immediately (<2s after appearing)

**Suppression threshold:** W < 0.2 → don't show this notification type in this context  
**Recovery:** W recovers naturally as signal improves

**Stored at:** `~/Documents/notchly/v2/memory/notification_weights.json`
```json
{
  "breakfast_morning_weekday": 0.73,
  "nudge_evening_freelance": 0.45,
  "calendar_alert_anytime": 0.91
}
```

**Context key format:** `{type}_{timeOfDay}_{dayType}`  
Where `timeOfDay` = morning/afternoon/evening/night, `dayType` = weekday/weekend

**TODO:**
- [ ] **P1** Create `LearningEngine.swift` — single class that reads/writes weights and provides `shouldShow(type:context:) -> Bool`
- [ ] **P1** Wire `perform(_ action:)` in `NotchState` to call `LearningEngine.shared.record(action:type:context:)`
- [ ] **P1** Wire auto-collapse (30s timer fires with no interaction) → `LearningEngine.shared.record(.ignored, ...)`
- [ ] **P1** Wire `DataStore.loadAlerts()` to filter through `LearningEngine.shouldShow()` before setting `pendingAlerts`
- [ ] **P2** Weekly summary — compute per-type trend from raw log. Write to `memory/weekly_summary.json`. Show in S3 Dashboard as "Your week" card
- [ ] **P3** Dynamic button placement — if right action has signal > 0.7, it stays right. If left action accumulates more taps than right, swap placement. Store per-type button assignment

### 8.2 Rejection Count (Task Purgatory)
If user taps "Skip" or "Later" on same task 3 times:
- Flag task with `requires_diagnosis: true`
- On next show: Stage 1 expands to Diagnosis Mode (taller, warm gray, three buttons stacked vertically: "Split it / Wrong time / Not needed")
- Diagnosis buttons write back a `diagnosis_action` to DataStore

**TODO:**
- [ ] **P3** Implement `rejection_count` field in `ScheduleTask`
- [ ] **P3** In `perform("take_break")` and `perform("later")`: increment `rejection_count`. If == 3: set `requires_diagnosis = true`, save
- [ ] **P3** In `Stage1TimerView`: if `activeTask?.requires_diagnosis == true`, show Diagnosis Mode layout

---

## 9. SYSTEM INTEGRATION

### 9.1 Launch at Login (launchd)
```xml
<!-- ~/Library/LaunchAgents/com.notchly.app.plist -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>com.notchly.app</string>
  <key>ProgramArguments</key>
  <array><string>/Applications/NotchlyV2.app/Contents/MacOS/NotchlyV2</string></array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
</dict>
</plist>
```

**TODO:**
- [ ] **P2** Add "Launch at Login" toggle to Settings UI — writes/removes plist via `launchctl`
- [ ] **P2** On first launch: prompt user to enable launch at login
- [ ] **P2** Use `SMAppService.mainApp.register()` (macOS 13+ preferred) instead of manual plist

### 9.2 Permissions Required
| Permission | API | Purpose | When Asked |
|------------|-----|---------|------------|
| Calendar | `EKEventStore.requestFullAccessToEvents` | Show today's events | First launch |
| Accessibility | `AXIsProcessTrusted()` | Global hotkey via CGEventTap | First launch |
| (none) | NSTrackingArea | Hover detection | No permission needed |
| (none) | CoreAudio | Volume | No permission needed |
| (none) | IOBluetooth | BT device list | No permission needed |

**TODO:**
- [ ] **P1** First-launch permission flow — show an onboarding card in S2 asking for Calendar, then Accessibility. Currently permissions are silently skipped if denied
- [ ] **P2** `AXIsProcessTrusted()` check on launch — if not trusted, show amber dot in S0 indicating "limited mode" (no global hotkey)
- [ ] **P2** `AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt: true])` — trigger system prompt for Accessibility

### 9.3 App Sandbox
**Must remain disabled.** Sandbox would block:
- FSEvents on `~/Documents/notchly/v2/`
- `IOBluetoothDevice.pairedDevices()`
- `CGEventTap` for global hotkey

### 9.4 No Dock Icon, No Menu Bar
- `LSUIElement = true` in Info.plist → no Dock icon ✅
- No `NSStatusItem` created → no menu bar icon ✅
- The only way to quit: context menu "Quit" (to be added) or Activity Monitor

---

## 10. DESIGN TOKENS

All UI values are defined in `NotchlyDesign.swift` as `ND.*`. Do not hardcode any visual values outside this file.

### 10.1 Colors (all `.dark` colorScheme)
| Token | Value | Usage |
|-------|-------|-------|
| `ND.Color.primary` | white | Titles, primary text |
| `ND.Color.secondary` | white 0.6 | Subtitles, labels |
| `ND.Color.tertiary` | white 0.35 | Hints, timestamps |
| `ND.Color.muted` | white 0.15 | Disabled, placeholders |
| `ND.Color.surface` | white 0.06 | Card backgrounds |
| `ND.Color.stroke` | white 0.08 | Borders, dividers |
| `ND.Color.green` | `#34C759` | Done, active, success |
| `ND.Color.orange` | `#FF9500` | Warnings, alerts, loud volume |
| `ND.Color.red` | `#FF3B30` | Error, muted, urgent |
| `ND.Color.blue` | `#007AFF` | Calendar, music |
| `ND.Color.purple` | `#AF52DE` | AI, Notchly brand |

### 10.2 Typography
| Token | Size | Weight | Usage |
|-------|------|--------|-------|
| `ND.Font.heading()` | 13pt | semibold | Stage headers |
| `ND.Font.body()` | 12pt | regular | Main content |
| `ND.Font.caption()` | 11pt | regular | Subtitles, hints |
| `ND.Font.micro()` | 10pt | regular | Timestamps, labels |
| `ND.Font.mono(11)` | 11pt | monospaced | Timer labels, percentages |

### 10.3 Spacing
| Token | Value |
|-------|-------|
| `ND.Space.sm` | 6pt |
| `ND.Space.md` | 10pt |
| `ND.Space.lg` | 16pt |

### 10.4 Motion
| Token | Animation |
|-------|-----------|
| `ND.Motion.micro` | spring(response:0.2, dampingFraction:0.8) |
| `ND.Motion.fast` | spring(response:0.28, dampingFraction:0.82) |
| `ND.Motion.expand` | spring(response:0.38, dampingFraction:0.78) |
| `ND.Motion.spring` | spring(response:0.45, dampingFraction:0.72) |

**TODO:**
- [ ] **P2** Swipe commit animation needs a new token: `ND.Motion.suckBack` — `.easeIn(duration: 0.22)` for the collapse-into-notch on swipe confirm

---

## 11. TESTING CHECKLIST

This is the Definition of Done. All items must pass before shipping.

### 11.1 Window & Positioning
- [ ] S0 appears centered on physical notch camera cutout (not menu bar center) on 14" MacBook Pro M3
- [ ] S0 appears centered on physical notch on 16" MacBook Pro M3 Max
- [ ] On non-notch Mac (Air M2), window appears at top-center of screen without crashing
- [ ] External monitor connected: window appears on built-in screen notch, NOT on external
- [ ] Screen arrangement changed while app running: window re-positions within 0.5s
- [ ] Display goes to sleep and wakes: window re-positions correctly
- [ ] Mission Control / Exposé: window stays on top (collectionBehavior correctly set)
- [ ] Full-screen app on built-in screen: window still visible above it
- [ ] App installed at `/Applications/NotchlyV2.app`, codesigned, launches via launchd

### 11.2 Stage Transitions
- [ ] S0 → S15: single tap, immediate (< 50ms)
- [ ] S15 → S2: single tap on hover card
- [ ] S2 → S3: single tap on card
- [ ] S3 → S0: single tap on dashboard
- [ ] Any → S4: double-tap from S0 or ⌘⇧Space from any app
- [ ] S1 auto-collapse: notification appears, 30s later collapses without interaction
- [ ] S1 hover pause: cursor enters, auto-collapse pauses; cursor exits, 30s restarts
- [ ] Scroll up from S0 (12pt): snaps to S15
- [ ] Scroll up from S0 (50pt): snaps to S2 (skips S15)
- [ ] Scroll up from S0 (100pt): snaps to S3
- [ ] Scroll down from S3: collapses to S0
- [ ] Scroll mid-gesture does NOT drop (phase-aware test): start trackpad scroll, hold fingers mid-gesture for 1s, continue — should not reset accumulator

### 11.3 Notifications (S1)
- [ ] Alert appears when `pending_alerts.json` is written with a valid PendingAlert
- [ ] Alert appears within 15s of file write (poll cycle)
- [ ] Alert shows correct icon for each type (nudge/calendar/reminder/notion/ai)
- [ ] Alert auto-collapses at 30s
- [ ] Hover reveals buttons below (slide animation, full width)
- [ ] Right button tap → action fires → continuity banner shows → S0
- [ ] Left button tap → action fires → S0
- [ ] Swipe right past 30pt → commits right action
- [ ] Swipe left past 30pt → commits left action
- [ ] Swipe < 30pt → springs back
- [ ] Green wash visible during right swipe
- [ ] Gray wash visible during left swipe
- [ ] Suck-back animation on commit

### 11.4 Timer (S1)
- [ ] Active task shows when `schedule.json` has a task with `status: "active"`
- [ ] Timer label cycles: countdown → elapsed → percent (every 4s)
- [ ] Tap timer number → pauses (label shows "Paused ⏸")
- [ ] Tap again → resumes
- [ ] Progress arc fills proportionally to task elapsed time
- [ ] "Done" button marks task in DataStore and loads next pending task
- [ ] "Break" button creates break task
- [ ] Hover shows Done/Break buttons below timer

### 11.5 Volume HUD (S1)
- [ ] Volume HUD appears within 0.5s of system volume change
- [ ] Gradient: normal=green, loud(>80%)=green→orange, muted=red
- [ ] Mute toggle shows "Muted" label and red bar
- [ ] HUD auto-collapses 2.5s after last change
- [ ] Volume HUD does NOT appear if S1 Notification is active

### 11.6 Chat (S4)
- [ ] ⌘⇧Space opens S4 from any app
- [ ] Double-tap on S0 opens S4
- [ ] Message sends on Return key
- [ ] AI responds (Claude API or OpenClaw)
- [ ] Idle 60s with no input → S4 closes
- [ ] Cursor leaves notch for 60s → S4 closes
- [ ] Active session (AI generating) → cursor leave does NOT close S4
- [ ] Schedule keyword ("tomorrow") → context strip appears above input

### 11.7 Dashboard (S3)
- [ ] All calendar events show for today
- [ ] Current event highlighted (title + time left)
- [ ] Active task shows with timer
- [ ] Pending tasks show (up to 3) with circle tap buttons
- [ ] Circle button tap → marks task done → row animates out
- [ ] Now playing shows current song
- [ ] BT battery shows colored bar (red if < 20%)
- [ ] `todays_goal` from working_memory.json appears in AI goal card

### 11.8 Learning Algorithm
- [ ] After 3 ignores of same alert type, alert stops showing in that context
- [ ] After 5 primary-action taps, W > 0.7
- [ ] After 5 ignores, W < 0.2
- [ ] W scores survive app restart (persisted to file)
- [ ] Weekly summary shows trend for each notification type

### 11.9 OpenClaw Integration
- [ ] Message in S4 writes `chat_request.json`
- [ ] OpenClaw response appears in S4 within 5s
- [ ] If no OpenClaw: Claude API responds within 3s
- [ ] Reschedule action in response updates DataStore immediately

---

## 12. KNOWN BUGS (Current Build)

| # | Severity | Description | File | Fix |
|---|----------|-------------|------|-----|
| 1 | HIGH | Window appears on external monitor instead of built-in notch | NotchWindowController.swift | Verify `builtinScreen()` returns correct device |
| 2 | HIGH | `minutesLeft` returns `duration_minutes` instead of actual remaining | DataStore.swift | Need `start_time` field in ScheduleTask |
| 3 | HIGH | No swipe left/right gesture for notifications | NotchRootView.swift | Implement `scrollingDeltaX` routing |
| 4 | HIGH | ⌘⇧Space global hotkey not implemented | NotchWindowController.swift | Add `CGEventTap` or `Carbon.RegisterEventHotKey` |
| 5 | HIGH | Stage 4 chat has no real AI — hardcoded stub | Stage4ChatView.swift | Wire Claude API |
| 6 | MED | `action_left`/`action_right` fields ignored | NotchState.swift | Use from `pendingAlerts.first` if set |
| 7 | MED | Task "Done" doesn't automatically load next task | NotchState.swift | After `markTaskDone`, call `applySchedule` with remaining |
| 8 | MED | Hover exit fires immediately (flicker on edge) | NotchWindowController.swift | Add 200ms debounce to `setHover(false)` |
| 9 | MED | Timer label is static (not cycling countdown→elapsed→%) | Stage1TimerView.swift | Add cycle state machine |
| 10 | LOW | No progress arc in timer view | Stage1TimerView.swift | Add arc overlay using `timerProgress` |
| 11 | LOW | `PendingAlert.priority` not used for sort order in DataStore | DataStore.swift | Already sorted in `loadAlerts()` — verify it works |
| 12 | LOW | No "Quit" in context menu | NotchRootView.swift | Add `Button("Quit Notchly") { NSApp.terminate(nil) }` |

---

## 13. BUILD & DEPLOY

### 13.1 Build Commands
```bash
# Development build
cd ~/Documents/notchly/notchly_v3codex
swift build

# Release build
swift build -c release

# Install
pkill -x NotchlyV2
cp .build/release/notchly_v3codex /Applications/NotchlyV2.app/Contents/MacOS/NotchlyV2
codesign --force --deep --sign - /Applications/NotchlyV2.app
open /Applications/NotchlyV2.app
```

### 13.2 Test Data Injection
```bash
# Inject a test notification (appears within 15s)
cat > ~/Documents/notchly/v2/pending_alerts.json << 'EOF'
[{"id":"test-1","type":"nudge","title":"Time to focus","message":"You have 2 hours free","created_at":"2026-04-17T10:00:00Z","priority":1,"action_left":"Skip","action_right":"Got it"}]
EOF

# Inject active task
cat > ~/Documents/notchly/v2/schedule.json << 'EOF'
[{"id":"task-1","title":"Curry & Beans Logo","duration_minutes":90,"due":"2026-04-18T17:00:00Z","status":"active","project":"Client Work","priority":1}]
EOF

# Clear all
echo '[]' > ~/Documents/notchly/v2/pending_alerts.json
echo '[]' > ~/Documents/notchly/v2/schedule.json
```

### 13.3 Git Workflow
```bash
# Feature branch
git checkout -b feature/swipe-gestures

# Commit
git add -A && git commit -m "feat: two-finger swipe on notifications"

# Push
git push origin feature/swipe-gestures
```

**Remote:** `https://github.com/saikiran9185/notchly.git`

---

## 14. PRIORITY QUEUE (What to Build Next)

### Sprint 1 — Core Interactions (P0)
1. **Swipe left/right gesture** on S1 notifications and S1 timer
2. **⌘⇧Space global hotkey** to open S4 Chat
3. **Real AI backend** in Stage 4 (Claude API claude-sonnet-4-6)

### Sprint 2 — Data Correctness (P1)
4. **Fix external monitor positioning** — built-in screen always wins
5. **Fix `minutesLeft`** — add `start_time` to ScheduleTask, compute elapsed
6. **Timer label cycling** — countdown → elapsed → percent every 4s
7. **`action_left`/`action_right` dynamic labels** from PendingAlert schema
8. **After "Done": load next task** without collapse delay
9. **Hover exit debounce** 200ms

### Sprint 3 — Smart Features (P1)
10. **LearningEngine.swift** — W score algorithm, suppress suppressed alerts
11. **OpenClaw chat bridge** — write request, poll response
12. **CalendarManager → PendingAlert** — create alerts for upcoming events < 10m
13. **S2B missed notifications list** — scrollable with inline reply

### Sprint 4 — Polish (P2)
14. **Swipe color wash + suck-back animation**
15. **Context peek in S4** (schedule strip on keyword)
16. **S3 task circle buttons** — tap to complete
17. **Mac own battery** in S3 Dashboard
18. **Launch at Login** toggle in Settings
19. **"Quit Notchly"** in context menu

### Sprint 5 — Advanced (P3)
20. **Diagnosis Mode** (rejection count Stage 1.5)
21. **App-specific action buttons** (Blender, Figma, Xcode detection)
22. **Weekly summary card** in S3
23. **Dynamic button placement** (most-pressed action goes right)
24. **MediaRemote** for universal now-playing
25. **Bluetooth battery via IOKit** (no subprocess)
