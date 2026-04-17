╔══════════════════════════════════════════════════════════════════════════════╗
║  NOTCHLY — COMPLETE ENGINEERING MASTER TODO                                ║
║  Micro to Macro · Every feature · Every fix · Every test                   ║
║  Audience: Senior macOS Engineer · Product Lead · QA                       ║
║  Updated: 2026-04-17                                                        ║
╚══════════════════════════════════════════════════════════════════════════════╝

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
STAGE MAP (7 stages, continuous progress model)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Stage  │ Name              │ Progress / Trigger      │ Visual Function
  ───────┼───────────────────┼─────────────────────────┼─────────────────────────────────
  S0     │ Idle Pill         │ 0.0                     │ Stealth. Blends with hardware notch
  S1A    │ Notification      │ 0.15 (proactive)        │ Alert: title + dot + hover buttons
  S1B    │ Timer             │ 0.15 (active task)      │ Live countdown + pause + hover buttons
  S1.5   │ Hover / Diagnosis │ 0.12–0.39 (cursor)      │ Read-only peek OR 3-option diagnosis
  S2A    │ NowCard           │ 0.40–0.69 (scroll/tap)  │ Full task card + action buttons
  S2B    │ Missed Panel      │ 0.40 dynamic            │ Scrollable missed alerts + inline reply
  S3     │ Dashboard         │ 0.70–0.99 (long scroll) │ Full day: timeline + tasks + score
  S4     │ Chat / System     │ 1.0 (hotkey only)       │ AI chat, context peek, action cards

  Navigation:
  • Gestural: S0 ↔ S1.5 ↔ S2 ↔ S3  (two-finger scroll depth)
  • Direct:   ⌘⇧Space → S4 always   │  ⌘Space toggles S0 ↔ S3
  • Proactive: Brain fires S1A automatically on important events

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CURRENT BUILD STATE (v3 codex, 2026-04-17)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Component                                    │ File                        │ Status
  ─────────────────────────────────────────────┼─────────────────────────────┼────────
  NSPanel layer 25, collectionBehavior correct │ NotchWindowController.swift │ ✅
  Notch geometry via auxiliaryTopLeftArea      │ NotchState.swift            │ ✅
  Stage system S0→S4 with transitions          │ NotchRootView.swift         │ ✅
  Phase-aware scroll accumulator               │ NotchState.swift            │ ✅
  Volume monitor (CoreAudio 0.25s poll)        │ VolumeMonitor.swift         │ ✅
  NowPlaying (Music + Spotify)                 │ NowPlayingMonitor.swift     │ ✅
  Bluetooth audio + battery (ioreg)            │ BatteryMonitor.swift        │ ✅
  Calendar events via EventKit                 │ CalendarManager.swift       │ ✅
  DataStore polling ~/notchly/v2/ at 15s       │ DataStore.swift             │ ✅
  S0 idle dot with pulse                       │ Stage0View.swift            │ ✅
  S1 notification + swipe offset               │ Stage1NotificationView      │ ✅
  S1 timer + progress                          │ Stage1TimerView             │ ✅
  S1 volume HUD                                │ Stage1VolumeView            │ ✅
  S1.5 hover card                              │ Stage15HoverView            │ ✅
  S2 card with left/center/right actions       │ Stage2CardView              │ ✅
  S3 dashboard (cal, music, BT, tasks)         │ Stage3DashboardView         │ ✅
  S4 chat UI                                   │ Stage4ChatView              │ ⚠️ stub
  Settings window                              │ SettingsView                │ ✅
  NSTrackingArea hover (no Accessibility)      │ NotchWindowController       │ ✅
  Continuity banner                            │ ContinuityBanner            │ ✅
  ND design token system                       │ NotchlyDesign.swift         │ ✅
  Swipe left/right gesture                     │ —                           │ ❌ missing
  ⌘⇧Space global hotkey                        │ —                           │ ❌ missing
  Real AI in S4                                │ —                           │ ❌ stub
  Timer label cycling (countdown→elapsed→%)    │ Stage1TimerView             │ ❌ static
  Self-learning W score algorithm              │ —                           │ ❌ missing
  EVR interruption guard                       │ —                           │ ❌ missing
  OpenClaw chat bridge                         │ —                           │ ❌ missing

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BLOCK 1 — WINDOW & NOTCH  (do first — everything depends on it)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[ ] Window sits exactly on notch — no gap, no overlap
[ ] notchH reads from screen.safeAreaInsets.top (not hardcoded 38)
[ ] notchW reads from auxiliaryTopLeftArea/TopRightArea (not hardcoded 162)
[ ] Window level = .statusBar (CGWindowLevel 25)
[ ] collectionBehavior: [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
[ ] No shadow, no border, transparent background, isOpaque=false
[ ] LSUIElement = true in Info.plist — no Dock icon
[ ] No NSStatusItem — no menu bar icon
[ ] acceptsFirstMouse = true on contentView so clicks don't activate app
[ ] canBecomeKey = false, canBecomeMain = false
[ ] Seam masker: 2pt black Rectangle above pill, width = pillW - topRadius×2, y = -1pt
[ ] Window repositions on NSApplication.didChangeScreenParametersNotification
[ ] recalculate(using:) called on every screen change
[ ] App does not appear in Cmd+Tab switcher
[ ] Entry animation: pill drops from y:-10 opacity:0 → y:0 opacity:1, spring(0.42,0.72)
[ ] BUILT-IN SCREEN PRIORITY: builtinScreen() must always win over external monitor
[ ] If external is primary (user's current X=3227 bug): force built-in for notch window
[ ] Test: CGDisplayIsBuiltin() returns correct value for M-series built-in

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BLOCK 2 — STAGE 0 (idle — truly invisible)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[ ] Width = exact notchW from hardware measurement
[ ] Height = exact notchH from safeAreaInsets.top
[ ] Fill = #000000 pure black (blends with physical hardware notch)
[ ] topRadius = 6pt, bottomRadius = 10pt
[ ] Content: single 3×3pt dot centered horizontally, vertically centered
[ ] Dot color — no missed alerts: rgba(255,255,255, 0.06) — barely visible
[ ] Dot color — has pending alerts: rgba(228,75,74, 0.20) — dim red
[ ] Dot color — has active task: rgba(29,158,117, 0.20) — dim green
[ ] Dot color — music playing: rgba(74,144,226, 0.20) — dim blue
[ ] Dot = INVISIBLE (no dot at all) during deep focus mode (same app >20min)
[ ] Dot fades in over 0.4s when transitioning into S0
[ ] S0 is truly stealth — blends with hardware notch, no visible pill border
[ ] Single tap → S15 Hover
[ ] Double-tap → S4 Chat (skip S1/S2/S3)
[ ] Two-finger scroll down (>12pt delta) → S15 Hover

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BLOCK 3 — STAGE 1A (notification bar)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

DIMENSIONS:
[ ] Width: content-fit, MIN 240pt MAX 400pt
[ ] Height default (no hover): notchH + 20pt
[ ] Height on hover (buttons visible): notchH + 44pt
[ ] topRadius = 8pt, bottomRadius = 14pt
[ ] Fill = #111111, border = rgba(255,255,255,0.06) 0.5pt, top edge = none

CONTENT ROW:
[ ] 5pt type dot · title 12pt medium · separator 1×10pt · sub 10.5pt
[ ] Dot color by type: green=task, amber=meal, blue=class, red=deadline, purple=ai
[ ] Title truncates lineLimit=1
[ ] Sub shows time remaining or context (e.g. "in 7m")
[ ] Wire alertType from PendingAlert.type to dot color map

AUTO-DISMISS:
[ ] Auto-collapses to S0 after 30 seconds if no interaction
[ ] 30s timer pauses when cursor enters hover zone
[ ] 30s timer resumes when cursor leaves hover zone
[ ] On dismiss by timeout: add to missedAlerts THEN collapse to S0
[ ] Collapse animation: spring(response:0.35, dampingFraction:0.82)
[ ] S1A NEVER persists forever — 30s is a hard limit

HOVER SEQUENCE (critical — must be exact):
[ ] Step 1: cursor enters → hint text appears FIRST (before bar grows)
[ ] Hint text: "← [leftActionLabel]  ·  [rightActionLabel] →"
[ ] Hint text color: left = rgba(255,255,255,0.18), right = rgba(29,158,117,0.45)
[ ] Hint text font: SF Pro 9.5pt regular
[ ] Step 2: bar grows taller, spring(response:0.35, dampingFraction:0.75)
[ ] Step 3: buttons SLIDE DOWN from inside bar (bar grows, buttons don't float)
[ ] Buttons fill full width minus 14pt padding each side
[ ] Button gap = 5pt between buttons
[ ] Button height = 25pt, cornerRadius = 7pt
[ ] Right button (primary): bg #4A90E2, text white, 10.5pt medium
[ ] Left button (secondary): bg rgba(255,255,255,0.07), border 0.5pt, 10.5pt medium
[ ] 3-button layout (meal/task with Later): full width, 5pt gaps, middle bg more faded
[ ] Cursor leaves hover zone: bar shrinks, buttons slide back in, hint fades

ACTIONS:
[ ] action_left / action_right from PendingAlert override defaults
[ ] If PendingAlert has no action fields, use category defaults (see Block 13)
[ ] Continuity banner appears below for 4s when any button tapped
[ ] Right button tap → perform rightAction → collapse to S0
[ ] Left button tap → perform leftAction → collapse to S0
[ ] Middle button (when present): click only, NOT swipeable, never swipe-triggered

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BLOCK 4 — STAGE 1B (active task timer)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

DIMENSIONS:
[ ] Width: content-fit MIN 280pt MAX 360pt
[ ] Height: notchH + 22pt (slightly taller than 1A)
[ ] Same radius and border as S1A

TIMER:
[ ] Color: SF Mono, #1D9E75 green
[ ] Format: >60min → "1h 18m" | ≤60min → "18:42" live MM:SS
[ ] Live countdown: updates every 1 second via Timer
[ ] Timer stored: private var countdownTimer: Timer?
[ ] Timer invalidated in deinit { countdownTimer?.invalidate() }
[ ] RunLoop.main.add(timer, forMode: .common) — smooth during scroll
[ ] LABEL CYCLES every 4s (auto, pauses on hover):
    1. Countdown: "24m left"
    2. Elapsed: "36m in"
    3. Percentage: "60% done"
[ ] Cycle requires: @State var cycleIndex = 0 + 4s Timer

PAUSE/RESUME:
[ ] TAP the timer label to pause/resume (not a button — the label itself)
[ ] NSClickGestureRecognizer with 8pt expanded hit area
[ ] Paused: timer color → gray, "⏸" shown inline after label
[ ] Resumed: color back to green, "⏸" disappears
[ ] Haptic on toggle: NSHapticFeedbackManager.defaultPerformer .generic

HOVER:
[ ] Hover: bar grows, "Done ✓" (right, green) and "Take break" (left) slide down
[ ] Cycle pauses when hover buttons visible
[ ] Timer tap still works while hover visible

TIME'S UP:
[ ] At 0:00: color → amber, shows "0:00", 30s timer stops
[ ] Auto-shows buttons for 10s: [+15 min] (left) · [Done ✓] (right)
[ ] S1B NEVER auto-dismisses — persists until user acts

PROGRESS ARC:
[ ] Arc overlaid on timer label, 3pt stroke
[ ] Arc fills clockwise proportional to timerProgress
[ ] Color: green (< 80%) → amber (80–95%) → red (>95%)
[ ] Need start_time in ScheduleTask to compute timerProgress correctly
[ ] timerProgress = elapsed / duration (NOT 1 - remaining/duration)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BLOCK 5 — STAGE 1.5 (hover peek — read only)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[ ] Trigger: cursor enters 400×75pt hover zone centered on notch
[ ] Width: ~340pt max 360pt
[ ] Height: notchH + 32pt
[ ] topRadius = 10pt, bottomRadius = 16pt
[ ] Row 1: 7pt dot · "[task] · [timeLeft] · [pct]% done" 12pt medium
[ ] Row 2: "next: [task] · [time]" 10pt + "MISSED·N" in red if missed > 0
[ ] Row 3: "scroll ↓ to act" 9.5pt textTertiary 0.6 opacity
[ ] Scroll hint chevron (chevron.down) animates with subtle bob, 2s repeat
[ ] NO buttons — completely read only, no interaction except mouse and scroll
[ ] Hover exit: immediate collapse, easeOut(0.2s) — no delay, no grace
[ ] Exit debounce: 200ms before firing setHover(false) — prevents flicker
[ ] Missed count: if pendingAlerts.count > 0, show orange badge "● N missed"
[ ] Tapping missed badge → goes to S2B (missed list), not S2A
[ ] Scroll ≥ 50pt from here → S2A NowCard
[ ] Scroll ≥ 120pt → S3 Dashboard

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BLOCK 6 — STAGE 2A (NowCard — action stage)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[ ] Trigger: click S15 OR scroll δy 50–120pt
[ ] Width: 380pt fixed
[ ] Height: notchH + 88pt
[ ] topRadius = 12pt, bottomRadius = 20pt
[ ] Header: type icon · task title 12.5pt medium · time remaining · app launch button
[ ] Subtitle: 10pt regular, project name or context
[ ] Progress bar: 2pt height, green/amber/red, full width of card
[ ] "next: [task] · [time] · P=[score]" below bar, 10pt textTertiary
[ ] 3 action buttons, full width, HStack spacing 5pt
[ ] Button heights 28pt, cornerRadius 7pt
[ ] Left = secondary style (gray bg, border)
[ ] Center = muted style (more faded bg) — click ONLY, never swipe
[ ] Right = primary style (#4A90E2 blue)
[ ] EXCEPTION: deadline escalated → right button bg = #E24B4A red
[ ] Mouse away: IMMEDIATE collapse to S0 — no delay, no grace period
[ ] Action taken → continuity banner → collapse to S0
[ ] App launch button: "Open [App]" if not running, "Switch to [App]" if running not front
[ ] App launch button hidden if app is already frontmost
[ ] App button position: top-right corner of card, 8pt from edges

BUTTON SETS (implement ALL — AI selects per notification type):
[ ] task:     [Not yet] · [Later] · [Done ✓]          — 3 buttons, Later=middle click only
[ ] meal:     [Skip] · [Done] · [Going now]             — 3 buttons, Done=middle click only
[ ] class:    [Skip] · [Later] · [On my way]            — 3 buttons, Later=middle click only
[ ] exercise: [Skip today] · [Later] · [Starting now]   — 3 buttons
[ ] deadline: [Move to 8pm] · [+30m] · [Start now]     — right=red
[ ] timer-up: [Not yet] · [Take break] · [Done ✓]      — 3 buttons
[ ] lazy:     [10 more min] · [Dismiss] · [Get back to it]
[ ] break-end:[5 more min] · [Tomorrow] · [Back now]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BLOCK 7 — STAGE 2B (missed notifications panel)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[ ] Trigger: cursor in hover zone AND missedAlerts.count > 0
[ ] 2A and 2B mutually exclusive — never both visible
[ ] 2B takes priority over 2A when missed alerts exist
[ ] Width: 360pt fixed
[ ] Height: notchH + 20pt header + (28pt × min(2,count)) + 8pt
[ ] Header: red dot · "MISSED·N" 10pt bold red uppercase · "see all ↓" · "✕ clear all"
[ ] Shows most recent 2 missed items (suffix 2, reversed chronological)
[ ] Each item row: 2.5pt accent bar · title 11pt · time-ago 10pt textTertiary
[ ] Accent bar colors: class=blue, task=green, break=purple, deadline=red, meal=amber
[ ] Tap item → that item expands inline, shows 3 quick-reply buttons
[ ] Only ONE item expanded at a time (others collapse)
[ ] Expanded height: 28pt → 58pt, spring(0.35, 0.75)
[ ] Quick-reply buttons per item: [Done ✓] [Still needed] [Skip]
[ ] "see all ↓" → opens S3 Dashboard
[ ] "✕" clear all → dismisses all missed, collapses to S0
[ ] Mouse away: IMMEDIATE collapse

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BLOCK 8 — STAGE 3 (full dashboard)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[ ] Trigger: scroll δy > 120pt OR ⌘Space OR "see all" tap from S2B
[ ] Width: 520pt fixed
[ ] Height: dynamic MIN 280pt MAX 400pt
[ ] topRadius = 16pt, bottomRadius = 24pt
[ ] Fill = #0c0c0c, border rgba(255,255,255,0.06) 0.5pt
[ ] Section cards: bg rgba(255,255,255,0.025), border rgba(255,255,255,0.04), radius 9pt

ROW 1 — Two columns:
[ ] LEFT: Today Timeline — max 6 events
[ ] Done events: muted/strikethrough. Current: highlighted + pulsing dot + " ▶" suffix
[ ] RIGHT: Tasks Left — max 5 tasks
[ ] Each task: circle tick button (14×14pt) · name · "P=8.4" SF Mono · mini progress bar
[ ] Circle tick: tap → checkmark + strikethrough animation → row fades out
[ ] Circle tick hover: border color → green
[ ] Mini progress bar: 48×3pt, green/amber/red

ROW 2 — Two columns:
[ ] LEFT: Now + Prep — current task + live timer + next task + upcoming class
[ ] RIGHT: Day Score — done count, left count, energy label, missed count (red if > 0)

FULL WIDTH:
[ ] Calendar section: current event (title + time left) OR next 2 upcoming events
[ ] Now Playing: song + artist + 48pt mini progress bar
[ ] Bluetooth: device name + battery bar (red if < 20%, amber if < 40%)
[ ] AI goal: purple card with workingMemory.todays_goal text
[ ] Footer: purple dot · "double-tap to chat" 9.5pt textTertiary

[ ] Double-tap anywhere in S3 → opens S4 chat (content swaps in same panel)
[ ] Mouse away: IMMEDIATE collapse to S0 (no grace)
[ ] Exception: if S4 open via S3 double-tap, follow S4 close rules
[ ] S3 does NOT auto-collapse on timer — only scroll-up or Esc collapses

TASK TICK IMPLEMENTATION:
[ ] Each task row: HStack with circle button + content
[ ] Circle button: .onTapGesture → DataStore.shared.markTaskDone(task.id)
[ ] After tap: @State var completedIDs: Set<String> — add id
[ ] Row: if completedIDs.contains(task.id) → strikethrough + fadeout animation
[ ] Animation: strikethrough draws across 0.3s, then opacity → 0, height → 0, 0.4s

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BLOCK 9 — STAGE 4 (chat — intentional path)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[ ] Trigger: ⌘⇧Space global hotkey OR double-click S0 notch
[ ] Width: 520pt fixed
[ ] Height: 80pt (empty) → grows with content → MAX 360pt
[ ] Scrolls internally when content > 360pt
[ ] topRadius = 16pt, bottomRadius = 24pt
[ ] Fill = #0d0d0d, border rgba(255,255,255,0.07)
[ ] Purple accent (#7F77DD) throughout — visually distinct from S1–S3

HEADER:
[ ] Purple 5pt dot · "Ask Notchly" 10.5pt textSecondary
[ ] Pin badge (visible only when pinned): purple bg + "pinned · action pending"
[ ] ⌘⇧Space hint: SF Mono purple, right side
[ ] ✕ button far right → close and clear chat

CONTEXT PEEK (zero API calls, client-side only):
[ ] Keywords that trigger: move, tomorrow, reschedule, when, free, deadline,
    today, later, morning, evening, after, before, time, schedule
[ ] Detection: string match on draft onChange — every keystroke
[ ] On keyword match: schedule strip slides in above input, height 0→60pt spring(0.35,0.80)
[ ] Strip content: 3 upcoming events in compact format
[ ] Strip fades when non-schedule content typed
[ ] Strip never triggers an API or file read — data already in memory

CONVERSATION:
[ ] User bubbles: right-aligned, rgba(74,144,226,0.15) tint bg, max-width 85%
[ ] AI bubbles: left-aligned, surface bg, max-width 90%
[ ] AI action cards embedded in AI bubble:
    - updated_queue_card: new task queue with P scores
    - timeline_card: updated schedule for today
    - single_task_card: confirms one task added or moved
    - question_card: follow-up with 2 inline reply buttons

INPUT BAR:
[ ] Purple dot · TextField "ask anything · add task · reschedule…" · return key hint
[ ] Send fires on Return key
[ ] Draft clears after send
[ ] Loading spinner next to header while AI responds

SESSION LOCK RULES:
[ ] PINNED when: action card unacknowledged OR AI is responding
[ ] Pinned: mouse away does NOT close — only Esc or ✕
[ ] Pin badge shows in header when pinned
[ ] IDLE (nothing sent, conversation complete): mouse away → 60s → clears → S0
[ ] Re-enter within 60s: chat text preserved
[ ] S3→S4 via double-tap: mouse away = IMMEDIATE close (no 60s grace)
[ ] Only hotkey/double-click S4 gets the 60s grace

AI BACKEND:
[ ] Primary: OpenClaw bridge (check openclaw_response.json, if < 5s old, use it)
[ ] Fallback: Claude API claude-sonnet-4-6
[ ] System prompt includes: active_task, pending_alerts[:3], calEvents[:4], workingMemory
[ ] Response max tokens: 300 (keep it concise for the small UI)
[ ] On response: parse for action card JSON, render if present

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BLOCK 10 — SWIPE GESTURE PHYSICS (the most important interaction)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ACTIVE STAGES: S1A, S1B, S2A, S2B (where buttons exist)
Outside these stages: horizontal scroll = default macOS (do not capture)

DETECTION:
[ ] abs(scrollingDeltaX) > abs(scrollingDeltaY) = horizontal gesture
[ ] Accumulate xDelta across .began → .changed phases
[ ] Commit threshold: abs(xDelta) ≥ 40pt AND velocity > 200pt/s
[ ] Add deltaX parameter to registerScroll() alongside deltaY
[ ] Route horizontally when |deltaX| > |deltaY| && |deltaX| > 4pt

BUTTON DIRECTION RULE (from screenshot — ALWAYS):
  Swipe right = rightmost button
  Swipe left  = leftmost button
  Middle button = click only — never swipe-triggered
  AI decides which action is on which side (see Block 13)

── STATE 0: ENTRANCE (card drops in) ─────────────────────────────────────────
[ ] Drop from y:-notchH opacity:0 → spring(0.42, 0.72) — feels physical
[ ] Affordance nudge fires ONCE PER INSTALL (UserDefaults "swipeNudgeSeen" flag)
[ ] Nudge: +10pt right → -10pt left → center, spring(0.28, 0.65)
[ ] Hint text visible: "← [leftLabel]  ·  [rightLabel] →" rgba(255,255,255,0.22)
[ ] Hint updates to match current AI-determined button placement

── STATE 1: PULL (|δx| 1–39pt) ───────────────────────────────────────────────
[ ] Card tracks finger at 90% friction (not 1:1)
[ ] RIGHT pull:
    · green wash rgba(29,158,117) builds 0→55% opacity proportional to ratio
    · right button scales 1.0→1.08×
    · left button fades to 20% opacity
[ ] LEFT pull:
    · warm gray wash rgba(80,80,80) builds 0→40% — NEVER red, never green
    · left button scales 1.0→1.08×
    · right button fades to 20% opacity
[ ] ratio = abs(xDelta) / 40.0 (0.0 → 1.0)
[ ] All lerps driven by ratio

── STATE 2: THRESHOLD (|δx| ≥ 40pt) ─────────────────────────────────────────
[ ] Color snaps to full opacity: easeInOut(0.12s)
[ ] Right: rgba(29,158,117, 0.55) full
[ ] Left:  rgba(80,80,80, 0.40) full — ALWAYS warm gray, NEVER red
[ ] Button text morphs: right → "✓ confirmed" | left → "→ skip"
[ ] Haptic: NSHapticFeedbackManager.defaultPerformer .levelChange

── STATE 3A: SNAP BACK (released before threshold) ───────────────────────────
[ ] Card → center, spring(0.32, 0.68)
[ ] Color opacity → 0, easeOut(0.20s)
[ ] Buttons scale → 1.0
[ ] 30s dismiss timer resets to full 30s

── STATE 3B: SUCK INTO NOTCH (released at/past threshold) ────────────────────
[ ] Action FIRES IMMEDIATELY (before animation completes)
[ ] Write to episodic log immediately
[ ] Card: translateY → -notchH + scaleX → 0.1 + opacity → 0, easeIn(0.22s)
[ ] Edge pulse: right=green rgba(29,158,117,0.60)→0 | left=gray rgba(80,80,80,0.40)→0
[ ] Edge pulse: easeOut(0.30s) — physical "absorbed by hardware" feel
[ ] Continuity banner appears below: spring(0.45, 0.72)
[ ] Left suck = warm gray pulse. Right suck = green pulse. NEVER red pulse.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BLOCK 11 — SCROLL DEPTH GESTURE (vertical, stage progression)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[ ] Capture global NSEvent monitor for .scrollWheel
[ ] ONLY process when cursor in hover zone (400×75pt centered on notch)
[ ] Reset accumulator on phase .began
[ ] Accumulate scrollingDeltaY on phase .changed
[ ] Ignore phase .ended, .cancelled → schedule 0.45s reset, do not process delta
[ ] Ignore momentumPhase != .none || .stationary (inertial scroll)
[ ] Trackpad (hasPreciseScrollingDeltas=true): delta as-is
[ ] Magic Mouse (false): delta × 8.0
[ ] Non-precise, no phase: 0.35s idle reset timer

THRESHOLDS (current, may tune):
[ ] δy 0–11pt:   dead zone — no change
[ ] δy 12–35pt:  → S15 Hover
[ ] δy 36–79pt:  → S2A NowCard
[ ] δy 80pt+:    → S3 Dashboard
[ ] δy ≤ -16pt:  → S0 Idle (collapse)

[ ] All snaps: spring(0.42, 0.68)
[ ] Collapse: spring(0.35, 0.80)
[ ] Release mid-scroll: snap to nearest stage threshold
[ ] Scroll up from any stage → collapse to S0

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BLOCK 12 — HOTKEYS & DOUBLE-CLICK
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[ ] ⌘⇧Space → openStage4() — works from ANY app, ALWAYS (highest priority)
[ ] ⌘Space   → toggle S3 Dashboard (open if any stage, close if S3)
[ ] ⌘D       → mark current task done (when S1B or S2A active)
[ ] ⌘S       → skip current task
[ ] ⌘L       → postpone task
[ ] ⌘E       → extend timer +15min (when S1B active)
[ ] Y key    → primary/right action (when S1A visible and cursor in zone)
[ ] Esc      → collapse any stage to S0

IMPLEMENTATION:
[ ] Use Carbon RegisterEventHotKey (NOT NSEvent — more reliable, no focus needed)
[ ] Request Accessibility: AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt:true])
[ ] If Accessibility denied: hotkeys silently fail, amber dot in S0 indicates "limited mode"
[ ] AXIsProcessTrusted() check on every launch — re-show prompt if denied

DOUBLE-CLICK:
[ ] Global NSEvent monitor for .leftMouseUp
[ ] Filter: cursorInNotchZone() AND event.clickCount == 2
[ ] When S0 active: → openStage4()
[ ] When S1A or S1B active: → primaryAction() — NOT S4 (Z-index rule)
[ ] When S3 active: → openStage4() (content swaps in place)
[ ] Notch hit area: notchW + 20pt wide, notchH + 10pt tall

Z-INDEX HIERARCHY (strict priority):
  S4 hotkey (⌘⇧Space) > S1A/S1B interaction > S4 double-click
  If S1A is showing: double-click fires S1A primary action (not S4)
  To reach S4 while S1A showing: MUST use ⌘⇧Space

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BLOCK 13 — BUTTON PLACEMENT (AI-determined, learned per person)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

DEFAULT PLACEMENT (Week 1, before learning):

  Type         │ Left (swipe left)  │ Middle (click only) │ Right (swipe right)
  ─────────────┼────────────────────┼─────────────────────┼───────────────────
  task         │ Not yet            │ Later               │ Done ✓
  meal         │ Skip               │ Done                │ Going now
  class        │ Skip               │ —                   │ On my way
  exercise     │ Skip today         │ Later               │ Starting now
  deadline     │ Move to 8pm        │ +30m                │ Start now (red)
  lazy nudge   │ 10 more min        │ Dismiss             │ Get back to it
  timer up     │ +15 min            │ —                   │ Done ✓
  break end    │ 5 more min         │ Tomorrow            │ Back now

RULE: Swipe right = rightmost button. Swipe left = leftmost button. Always.
NOTE: Middle button = click only, NEVER swipeable.

LEARNING LOOP:
[ ] Week 1: use default placement from table above
[ ] Track press_count[notif_type][action][context_bucket] after each tap
[ ] Week 2+: most pressed action in context → moves to RIGHT (swipe right)
[ ] Example: skip lunch 4 of 5 times → "Skip" moves to right → hint flips: "← going · skip →"
[ ] Month 1: context-conditional placement (breakfast Mon=skip right, Sat=going right)
[ ] ALWAYS: hint text "← [leftLabel] · [rightLabel] →" shows current placement
[ ] Hint text updates immediately when placement adapts
[ ] Never surprise the user — hint text is always accurate

IMPLEMENTATION:
[ ] ButtonPlacementEngine.swift: reads from semantic_profile.json
[ ] func rightAction(for type: String, context: ContextBucket) -> NotchAction
[ ] func leftAction(for type: String, context: ContextBucket) -> NotchAction
[ ] Updates ButtonPlacement in semantic_profile after each tap via LearningEngine

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BLOCK 14 — PRIORITY SCORING FORMULA
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  P = (U×0.35) + (I×0.25) + (E×0.20) + (C×0.15) + (D×0.05)

[ ] assert(0.35+0.25+0.20+0.15+0.05 == 1.0) at startup — fatal if wrong
[ ] Show as "P=8.4" in SF Mono 9.5pt textTertiary next to tasks in S3

U = Urgency (0–10):
[ ] U = 10 × exp(-0.15 × hoursUntilDue)
[ ] Overdue: U = 10
[ ] No deadline: U = 2
[ ] Due < 2h: U clamps to minimum 7.5

I = Importance (0–10):
[ ] priority 1 = 10, priority 2 = 7, priority 3 = 4, priority 4 = 1, unset = 3
[ ] Postpone penalty: I -= 0.5 × postponeCount (min 0)

E = Energy match (0–10):
[ ] E = 10 × min(1, currentEnergy / taskRequirement)
[ ] Energy curve by hour: 8–12 = 9, 12–14 = 6, 14–17 = 8, 17–20 = 7, else 4
[ ] Task energy requirements: deepWork=6.5, creative=6, admin=3, meal=1
[ ] Skip meal: reduce afternoon energy estimate by 0.5

C = Context (0–10):
[ ] Relevant app is frontmost: C = 10
[ ] Relevant app is running (not front): C = 9
[ ] Relevant app not running: C = 7
[ ] No app relevance (general task): C = 5
[ ] In class (USDI calendar event): C = 0 (suppress task entirely)

D = Momentum (0–10):
[ ] D = 10 × (1 - h/72) for h between 6 and 72 hours since creation
[ ] h < 6 or h > 72: D = 0

SKIP PENALTY (applied at end):
[ ] P_final = P × pow(0.8, skipCount)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BLOCK 15 — EVR INTERRUPTION GUARD
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  EVR = p_forgotten × p_action × (benefit - cost_missing) - COI

[ ] EVR runs BEFORE every notification fires — it is the gatekeeper
[ ] p_forgotten = 1 - 1/(1+exp(-0.1 × minutesSinceSeen))
[ ] p_action = loaded from SemanticProfile.W_value per type+context (default 0.60)
[ ] COI = base 2.0 × attentionMultiplier × timeMultiplier

Attention multipliers:
[ ] inClass (USDI event active): 4.0×
[ ] deepWork (same app >20min): 2.5×
[ ] idle > 10min: 0.5×
[ ] normal: 1.0×

Time multipliers:
[ ] interruptionGap < 30min since last notification: 1.8×
[ ] else: 1.0×

DECISION:
[ ] EVR > 0: fire notification (show S1A)
[ ] EVR ≤ 0: queue silently, retry in 5min (max 6 retries before giving up)
[ ] SAFETY OVERRIDE: if P_urgency > 8.0, fire REGARDLESS of EVR
[ ] EVR check runs in InterruptionGuard.swift before every DataStore alert push

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BLOCK 16 — SELF-LEARNING ALGORITHM (4 layers)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

LAYER 1 — W SCORE (EVR updater):
  W_new = W_old × 0.85 + signal × 0.15

[ ] primary tapped:    signal = 1.0  (right button, swipe right)
[ ] secondary tapped:  signal = 0.5  (left button, swipe left)
[ ] dismissed <2s:     signal = -0.3 (saw it, not relevant)
[ ] ignored 30s:       signal = -0.5 (didn't even look)
[ ] W clamped 0.0–1.0
[ ] W ≥ 0.60: show every time
[ ] W 0.30–0.59: show every other time
[ ] W < 0.30: suppress
[ ] W < 0.10: dead (user must re-enable via S4 chat: "restart breakfast reminders")
[ ] Urgency > 8: show regardless of W
[ ] Context key format: "{type}_{timeOfDay}_{dayType}" e.g. "meal_morning_weekday"
[ ] Store: ~/notchly/v2/memory/notification_weights.json

LAYER 2 — CONTEXTUAL BANDIT:
[ ] Context vector: hour_bucket(2h), day_of_week, has_class, deadline_today, energy_bucket, frontmost_category
[ ] Q(context, action) updated with α=0.15 after each response
[ ] Rewards: +1.0 primary, +0.4 secondary, -0.3 dismissed, -0.6 ignored
[ ] Policy determines both button placement and show/suppress decisions

LAYER 3 — CAP PENALTY (prevents over-learning early):
[ ] β = 0.2 + 0.8 × (1 - exp(-dataPoints/100))
[ ] Week 1: β ≈ 0.20 (very conservative, barely modifies)
[ ] Month 1: β ≈ 0.79 (mostly learned)
[ ] Month 3: β ≈ 0.99 (fully confident)
[ ] penalty = β × COI × interruptionsToday
[ ] P_adjusted = P_final - penalty
[ ] Urgency > 8: bypass CAP always

LAYER 4 — PROACTOR TIMING:
[ ] Track response_time_bucket[type][halfHourBucket] per interaction
[ ] After 14+ days: optimal_time = argmax(response_bucket[type])
[ ] new_fire_time = scheduled_time × 0.70 + optimal_time × 0.30
[ ] Gradually converges over 6–8 weeks

WEEKLY REBUILD (Sunday 23:00):
[ ] NSBackgroundActivityScheduler fires weekly
[ ] Read all episodic.jsonl entries from past 7 days
[ ] Compute: energy_by_hour, W_values, optimal_fire_times, button_placement
[ ] Write to semantic_profile.json atomically (Data.write options: .atomic)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BLOCK 17 — MEMORY SYSTEM
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EPISODIC LOG (most critical — APPEND ONLY):
[ ] File: ~/Documents/notchly/v2/memory/episodic.jsonl
[ ] Use FileHandle.seekToEndOfFile() + write() — NEVER read+rewrite
[ ] One JSON line per user action
[ ] Each line: { ts, action, notif_type, task_title, context, delay_s, W_before, W_after }
[ ] Write is atomic per line (FileHandle.write is atomic at kernel level)
[ ] Never clear or truncate — it is the ground truth of the user's behavior

SEMANTIC PROFILE (derived weekly):
[ ] File: ~/Documents/notchly/v2/memory/semantic_profile.json
[ ] Write: Data.write(to: url, options: .atomic)
[ ] Read at app launch to load all learned preferences
[ ] Contents: W_values, energy_by_hour, optimal_fire_times, button_placement

WORKING MEMORY (daily reset):
[ ] File: ~/Documents/notchly/v2/working_memory.json
[ ] Write: Data.write(to: url, options: .atomic)
[ ] Resets at midnight via NSTimer or NSBackgroundActivityScheduler
[ ] Contains: current_task, queue_snapshot, done_today, missed_count, idle_minutes, todays_goal

FILE CONTRACT:
[ ] ALL Swift file writes: Data.write(to: url, options: .atomic) — no exceptions
[ ] ALL Python file writes: write to .tmp then os.rename() — atomic swap
[ ] JSONL append: FileHandle only — never load-modify-save the whole file

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BLOCK 18 — DATA SOURCES & SERVICES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CALENDAR — ONE singleton:
[ ] CalendarManager.shared (or CalendarReader.shared) — one EKEventStore everywhere
[ ] Read calendars: primary + USDI B.Des + Hostel Mess + Google Tasks
[ ] requestFullAccessToEvents (macOS 14+) with #available fallback
[ ] Class detection: USDI calendar OR title contains: lecture/class/lab/studio/crit/seminar/workshop
[ ] Meal detection: Hostel Mess calendar events
[ ] Refresh every 5 minutes (not 60s — meals close in 15m windows)
[ ] Add tomorrow events to nextEvent logic if no more events today
[ ] On upcoming event < 10min: create PendingAlert, write to pending_alerts.json

DATASTORE — FSEvents (not 15s polling):
[ ] Replace Timer 15s poll with DispatchSource.makeFileSystemObjectSource
[ ] Watch: pending_alerts.json, schedule.json, working_memory.json
[ ] Latency: 0.1s max delivery
[ ] On change: read and process immediately
[ ] 15s poll kept as fallback if FSEvents fails to deliver

VOLUME MONITOR:
[ ] Move polling Timer to DispatchQueue.global(qos: .utility) — off main thread
[ ] OR replace with AudioObjectAddPropertyListener for event-driven updates
[ ] Volume HUD (S1Volume) must NOT hijack S1A/S1B — check currentStage before showing

NOW PLAYING:
[ ] Add com.apple.podcasts.notification.playerInfo observer
[ ] Current: Music + Spotify ✅

BLUETOOTH BATTERY:
[ ] Filter by device.addressString when parsing ioreg output (multiple devices)
[ ] OR replace subprocess with IOKit direct: IORegistryEntryCreateCFProperty(entry, "BatteryPercent")
[ ] Add Mac's own battery to S3: IOPMBatteryInfo read

IDLE DETECTION:
[ ] IOKit: HIDIdleTime from IOHIDSystem — returns nanoseconds
[ ] idleSeconds = HIDIdleTime / 1_000_000_000.0
[ ] Poll every 60s in ContextEngine
[ ] Idle > 1200s (20min): lazy state
[ ] Idle > 18000s (5h) + hour 5–11 AND NSWorkspace.didWakeNotification: morning briefing

APP FOCUS:
[ ] NSWorkspace.shared.notificationCenter for .didActivateApplicationNotification
[ ] Track: current bundleID + switch timestamp
[ ] Deep work = same bundleID frontmost > 20min with no app switches
[ ] Expose as ContextEngine.shared.isDeepWork: Bool

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BLOCK 19 — BDI COGNITIVE ENGINE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[ ] BDIAgent.shared processes ContextSnapshot every 60s
[ ] Runs on background queue, results dispatched to main

BELIEFS (derived from sensors):
[ ] user.isInClass — USDI calendar event active now
[ ] user.isDeepWork — same app frontmost > 20min
[ ] user.isIdle — IOKit idle > 20min
[ ] task.deadlineToday — any task hoursUntilDue < 24
[ ] app.isRelevant — task title keyword matches current frontmost bundle ID

INTENTIONS (what the BDI decides to do):
[ ] enterClassMode → suppress all notifications except urgency > 8
[ ] showAppButton → add contextual launch button to S2A card
[ ] escalateDeadline → override urgency when hoursUntilDue < 6
[ ] autoReschedule → task postponed 3× → move to tomorrow 10am
[ ] showTransitionNudge → class ending in 10min → prepare user
[ ] sendMotivation → idle > 20min during work window
[ ] diagnosisMode → same task rejected 3× → trigger S1.5 Diagnosis

APP KEYWORD → BUNDLE ID MAP:
[ ] blender       → org.blender.Blender
[ ] figma         → com.figma.Desktop
[ ] xcode         → com.apple.dt.Xcode
[ ] notion        → notion.id
[ ] terminal      → com.apple.Terminal
[ ] claude        → com.anthropic.claudefordesktop
[ ] premiere      → com.adobe.premierepro
[ ] after effects → com.adobe.aftereffects
[ ] photoshop     → com.adobe.photoshop
[ ] illustrator   → com.adobe.illustrator
[ ] vs code       → com.microsoft.VSCode
[ ] davinci       → com.blackmagicdesign.resolve
[ ] procreate     → com.savage.procreate
[ ] chrome        → com.google.Chrome

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BLOCK 20 — DYNAMIC SCHEDULER
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[ ] Runs after EVERY user action (Done, Skip, Later, Break)
[ ] Score all incomplete tasks with P formula
[ ] Filter C=0 tasks (class time — suppress entirely)
[ ] Sort descending by P_final
[ ] Find free blocks from calendar (gaps between events)
[ ] Match: high energy slots → deep work tasks, low energy → admin
[ ] Skip class slots entirely (no scheduling during class)
[ ] Apply 15min buffer after class ends
[ ] Apply 20min transit buffer before first task after any class
[ ] Apply 10min context-switch buffer between different task types
[ ] Tasks not fitting today → tomorrow (don't overflow silently)
[ ] Deadline today + won't fit → ESCALATE urgency override
[ ] AI proposes specific time — never asks "when?" — always decides
[ ] Postpone 3×: auto-move to tomorrow 10am, reset postponeCount = 0
[ ] Show continuity: "Moved [task] to tomorrow — postponed 3×"
[ ] ALWAYS show exactly one suggestion — never a list, never a menu
[ ] Free period < 25min: admin/review tasks only (not deep work)
[ ] Free period 25–60min: one task matching the duration
[ ] Free period > 60min: highest P_final task

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BLOCK 21 — BEHAVIOURAL SAFEGUARDS (5 rules — do not skip any)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. DIAGNOSIS MODE (task purgatory — rejected 3×):
[ ] Trigger: task.rejectionCount ≥ 3 (increments on Skip/Later)
[ ] Position: pill drops 40pt LOWER than normal
[ ] Background: warm gray rgba(60,58,55,0.95) — NOT the dark pill color
[ ] Buttons: VERTICAL STACK (breaks horizontal muscle memory — critical)
[ ] Options: [Too big → split] [Wrong time → reschedule] [Not needed → remove]
[ ] "Too big": show 1-line text field for "first small step" — user types it
[ ] "Wrong time": auto-reschedule to next energy≥8 time slot
[ ] "Not needed": confirmation then delete
[ ] Dismiss twice without choosing: move to tomorrow silently
[ ] Reset rejectionCount when task rescheduled to new time

2. GLASS BREAK (emergency override):
[ ] Option key held during wellness/burnout alert → button transforms red
[ ] Text: "Deadline Mode: Disable Sensors"
[ ] Activates: disables wellness + burnout + idle detection until midnight
[ ] Midnight timer resets glass break state
[ ] Invisible in normal use — only discoverable by holding Option

3. BURNOUT PILL (DIFFERENT from diagnosis mode — common mistake):
[ ] Position: drops 40pt lower (same position as diagnosis)
[ ] Colors: INVERTED — red background, light text (NOT warm gray)
[ ] Buttons: HORIZONTAL layout (normal, same as S1A)
[ ] This combo (red bg + horizontal) breaks muscle memory without gray cue
[ ] The two differences from diagnosis: RED background + HORIZONTAL buttons

4. MORNING GATE (prevents 3am false wake):
[ ] Briefing fires ONLY when ALL THREE true simultaneously:
    1. NSWorkspace.didWakeNotification received
    2. systemIdleSeconds() > 18000 (5 hours inactive)
    3. currentHour >= 5 AND currentHour < 11
[ ] 3am laptop open → stays completely silent — morning gate fails condition 3

5. POSTPONE 3× AUTO-RESCHEDULE:
[ ] task.postponeCount ≥ 3 → move to tomorrow 10am automatically
[ ] No confirmation prompt — just does it
[ ] Continuity banner: "Moved [task] to tomorrow — postponed 3×"
[ ] Reset postponeCount = 0 after move
[ ] postponeCount is separate from rejectionCount

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BLOCK 22 — CONTINUITY BANNER
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[ ] Appears after ANY button tap in S1A, S1B, S2A, S2B, or S4
[ ] Position: y = notchH + 6pt (just below pill bottom edge)
[ ] Content: 4pt green dot · confirmation text 11pt rgba(255,255,255,0.60)
[ ] Background: #0f0f0f, cornerRadius 8pt
[ ] Appear: from y=-(notchH+10) opacity=0 → spring(0.45, 0.72)
[ ] Auto-dismiss: after 4.0 seconds → easeOut(0.3s)
[ ] Only ONE banner at a time (new action replaces in-progress banner)

MESSAGES (exact text):
[ ] task done:     "[task title] done · [next task] loading"
[ ] skip:          "Skipped · [next task] loading"
[ ] later:         "Moved later · [next task] loading"
[ ] meal confirmed:"Noted · mess closes in [X]m"
[ ] skip meal:     "Skipping lunch · energy adjusted"
[ ] break started: "Break started · resumes in [X]m"
[ ] rescheduled:   "Moved [task] to [time]"
[ ] extended:      "+15m added · [timeLeft] remaining"
[ ] postpone 3×:   "Moved to tomorrow — postponed 3×"
[ ] paused:        "Paused ⏸"
[ ] resumed:       "Resumed ▶"

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BLOCK 23 — FULL DAY SCENARIOS (context-aware behavior)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

WAKE DETECTION (06:00–09:30):
[ ] didWakeNotification + idle > 5h + hour 5–11 = morning briefing
[ ] Show: exercise prompt OR deadline warning (deadline takes priority)
[ ] Exercise prompt: only if no class before 09:00
[ ] "Good morning [name]" on first open — time-aware greeting
[ ] Breakfast warning 15min before mess closes

CLASS MODE (during USDI calendar event):
[ ] All task alerts suppressed (except urgency > 8)
[ ] Pill shows: subject + "· class ·" + time remaining — STATIC, no pulsing
[ ] Mess closing < 5min: shows as sub-text below class title (not as alert)
[ ] One-tap idea capture: tap notch → text field → saves to Notion
[ ] Class ending in 10min: "Next: [first free-period task]" prep nudge

FREE PERIOD (gap between classes):
[ ] Gap < 25min: admin tasks only (not deep work)
[ ] Gap 25–60min: one task matching duration (P score + duration filter)
[ ] Gap > 60min: highest P_final task regardless of type
[ ] ALWAYS one suggestion — never a list, never "what do you want to do?"
[ ] Show time context: "35m free before [next class]"

HOSTEL TRANSIT:
[ ] 15min buffer after class ends before any task suggestion
[ ] First task starts 20min after class end (transit time)
[ ] Never mark task "late" before transit buffer expires

DISTRACTION:
[ ] Social/YouTube app frontmost > 20min during work window + deadline today → stakes nudge
[ ] Message: always about the stakes, NEVER "you've been on YouTube"
[ ] Example: "Curry & Beans logo due Friday — haven't started today"
[ ] Max 2 distraction nudges per evening, then 30min silence window

NAP MODE:
[ ] Declared via S4: "taking a nap" → set idle suppress timer
[ ] Undeclared: idle > 40min during day → "Resting or stuck?"
[ ] Nap declared: pill goes dark (dot hidden), energy estimate adjusts

DAY CLOSEOUT (last task done OR 23:00):
[ ] Summary banner: done count + missed count
[ ] Tomorrow queue: score and set top 5 tasks silently
[ ] Sleep warning: if class before 09:00 tomorrow

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BLOCK 24 — OPENCLAW INTEGRATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

FILE PROTOCOL (all in ~/Documents/notchly/v2/):
[ ] schedule.json          — OpenClaw writes, DataStore reads
[ ] pending_alerts.json    — OpenClaw writes, DataStore reads via FSEvents
[ ] working_memory.json    — OpenClaw writes, DataStore reads
[ ] cache/notion_cache.json — OpenClaw writes, DataStore reads
[ ] chat_request.json      — Notchly writes (on S4 send), OpenClaw reads
[ ] openclaw_response.json — OpenClaw writes, Notchly polls

CHAT REQUEST SCHEMA:
  { "id": "uuid", "message": "...", "context": { active_task, events, memory }, "timestamp": "..." }

OPENCLAW RESPONSE SCHEMA:
  { "request_id": "uuid", "message": "...", "action": { "type": "reschedule_task|add_task|dismiss_alert|set_goal|none", "payload": {} }, "timestamp": "..." }

[ ] S4 sendMessage() writes chat_request.json (Data.write options: .atomic)
[ ] Poll openclaw_response.json for 5s after sending
[ ] If response.request_id matches AND timestamp < 30s old: use OpenClaw response
[ ] If no match in 5s: fall back to Claude API (claude-sonnet-4-6)
[ ] response.action → if not "none": execute immediately via DataStore, don't wait for poll
[ ] Indicator in S4 header: "OpenClaw" or "Claude" label (dim, 9pt)
[ ] Without OpenClaw: app works fully — Claude API is the default brain

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BLOCK 25 — PYTHON BRAIN DAEMON
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[ ] brain_loop.py: runs every 90s via launchd KeepAlive
[ ] Reads working_memory.json + semantic_profile.json
[ ] Writes pending_alerts.json atomically (tmp → os.rename)
[ ] scorer.py: mirrors exact Swift P formula, same weights, asserts sum==1.0 at import
[ ] notion_sync.py: reads Notion Tasks DB every 5min, writes notion_cache.json atomically
[ ] gcal_sync.py: reads all 4 Google Calendars every 5min, writes gcal_cache.json atomically
[ ] scheduler.py: proposes specific times — never asks "when?"
[ ] ALL Python writes: write to .tmp then os.rename() — atomic swap, never partial reads

LaunchAgents (both needed):
[ ] ~/Library/LaunchAgents/com.notchly.app.plist     — starts Swift app
[ ] ~/Library/LaunchAgents/com.notchly.brain.plist   — starts Python daemon
[ ] Both: RunAtLoad=true, KeepAlive=true
[ ] Logs: ~/Documents/notchly/logs/app.log, brain.log, brain_err.log

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BLOCK 26 — DESIGN TOKENS (implement once in NotchlyDesign.swift, use everywhere)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

COLORS:
  background:    #0d0d0d
  surface:       #111111
  borderNormal:  rgba(255,255,255,0.07)
  textPrimary:   rgba(255,255,255,0.90)
  textSecondary: rgba(255,255,255,0.45)
  textTertiary:  rgba(255,255,255,0.22)
  green:         #1D9E75
  amber:         #BA7517
  red:           #E24B4A
  blue:          #4A90E2
  purple:        #7F77DD
  coral:         #D85A30
  swipeRight:    rgba(29,158,117, 0→0.55)  ← never exceeds 55% opacity
  swipeLeft:     rgba(80,80,80,   0→0.40)  ← NEVER red, never green

TYPOGRAPHY (all SF Pro — NOT SF Rounded):
  notifTitle:    12pt medium
  timer:         12pt medium SF Mono #1D9E75
  hintText:      9.5pt regular rgba(255,255,255,0.22)
  buttonLabel:   10.5pt medium
  taskTitle:     12.5pt medium
  sectionLabel:  9pt semibold uppercase tracking 0.08em
  priorityScore: 9.5pt regular SF Mono textTertiary
  continuityText:11pt regular rgba(255,255,255,0.60)
  chatInput:     11.5pt regular
  missedLabel:   10pt bold red uppercase tracking 0.06em

CORNER RADII (AsymmetricRoundedRect — topRadius / bottomRadius):
  S0:    top=6   bottom=10
  S1:    top=8   bottom=14
  S1.5:  top=10  bottom=16
  S2:    top=12  bottom=20
  S3:    top=16  bottom=24
  S4:    top=16  bottom=24

SPRINGS (named constants in ND.Motion):
  pillSpring:       spring(response:0.42, dampingFraction:0.68)
  expandSpring:     spring(response:0.50, dampingFraction:0.88)
  hoverExpand:      spring(response:0.35, dampingFraction:0.75)
  snapBack:         spring(response:0.32, dampingFraction:0.68)
  nudgeSpring:      spring(response:0.28, dampingFraction:0.65)
  suckIntoNotch:    easeIn(0.22s) + scaleX(0.1) + translateY(-notchH)
  continuitySpring: spring(response:0.45, dampingFraction:0.72)
  thresholdSnap:    easeInOut(0.12s)
  pulseOut:         easeOut(0.30s)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BLOCK 27 — CODE RULES (never break any of these)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[ ] Every Timer: private var name: Timer? + deinit { name?.invalidate() }
[ ] JSONL append: FileHandle O_APPEND only — NEVER load+rewrite
[ ] All Swift file writes: Data.write(to: url, options: .atomic)
[ ] ONE EKEventStore: CalendarManager.shared — never create a second one
[ ] No file > 400 lines — split into subcomponents
[ ] Zero force unwraps (!) — always guard let or if let
[ ] NSScreen.screens never in SwiftUI body — cache in NotchDimensions
[ ] App Sandbox = false in entitlements (system APIs require this)
[ ] git commit after every working feature, meaningful message
[ ] P formula weights assert sum == 1.0 at startup (fatalError if wrong)
[ ] All DispatchAsync to main when updating @Published vars
[ ] No magic numbers — use ND.* tokens or named constants

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BLOCK 28 — PERMISSIONS & FIRST LAUNCH
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

INFO.PLIST:
[ ] LSUIElement = true (no Dock icon, no menu bar)
[ ] NSCalendarsUsageDescription = "Notchly reads your calendar to schedule tasks."
[ ] NSAppleEventsUsageDescription set

ENTITLEMENTS:
[ ] com.apple.security.app-sandbox = false (required — see Block 27)

FIRST LAUNCH FLOW:
[ ] Check UserDefaults "notchly_setup_complete" — skip if already done
[ ] Step 1: Request calendar — show granted/denied result
[ ] Step 2: Request Accessibility — open System Settings, poll AXIsProcessTrusted every 2s
[ ] Step 3: "Start" — begin normal operation
[ ] After permissions: start ContextEngine, load calendar, show first suggestion
[ ] Create directories: ~/Documents/notchly/v2/memory/, logs/, cache/

PERMISSION SUMMARY:
  Calendar    → EKEventStore.requestFullAccessToEvents  → show events, create alerts
  Accessibility → AXIsProcessTrustedWithOptions         → global hotkeys via CGEventTap
  (no permission needed) NSTrackingArea                 → hover detection
  (no permission needed) CoreAudio                      → volume
  (no permission needed) IOBluetooth                    → BT device list

[ ] If Accessibility denied: dim amber dot in S0, hotkeys silently fail, show note in S4
[ ] Launch at Login: SMAppService.mainApp.register() (macOS 13+) in Settings

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BLOCK 29 — DATA SCHEMA (source of truth)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ScheduleTask (add missing fields):
  id: String, title: String, duration_minutes: Int
  start_time: String?     ← MISSING — needed for elapsed calculation
  due: String?, status: String, project: String?
  priority: Int, rejection_count: Int = 0   ← MISSING — for Diagnosis Mode
  postpone_count: Int = 0  ← MISSING — for 3× auto-reschedule
  app_hint: String?        ← MISSING — bundle ID for app-specific buttons
  requires_diagnosis: Bool = false  ← MISSING

minutesLeft fix:
  minutesLeft = duration_minutes - minutesElapsed
  minutesElapsed = (Date() - startTime) / 60  (requires start_time)

PendingAlert (use existing action_left/action_right):
[ ] Wire to NotchState.leftAction/rightAction: if pendingAlerts.first?.action_left != nil, use it
[ ] priority field: if priority == 1 bypass EVR guard, show immediately

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BLOCK 30 — KNOWN BUGS (fix in order)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  #  │ Sev  │ Description                                   │ File                    │ Fix
  ───┼──────┼───────────────────────────────────────────────┼─────────────────────────┼────────────────────────────────
  1  │ HIGH │ Window on external monitor (X=3227) not notch  │ NotchWindowController   │ builtinScreen() must win always
  2  │ HIGH │ minutesLeft returns duration not remaining      │ DataStore.swift         │ Add start_time, compute elapsed
  3  │ HIGH │ No swipe left/right on notifications            │ NotchRootView           │ Route deltaX in registerScroll
  4  │ HIGH │ ⌘⇧Space hotkey not implemented                  │ NotchWindowController   │ Carbon RegisterEventHotKey
  5  │ HIGH │ S4 chat is a stub (no AI)                       │ Stage4ChatView          │ Wire Claude API + OpenClaw
  6  │ MED  │ action_left/right ignored in NotchState         │ NotchState.swift        │ Use from pendingAlerts.first
  7  │ MED  │ "Done" doesn't load next task                   │ NotchState.swift        │ Call applySchedule after done
  8  │ MED  │ Hover exit fires immediately (edge flicker)     │ NotchWindowController   │ 200ms debounce setHover(false)
  9  │ MED  │ Timer label is static (not cycling)             │ Stage1TimerView         │ 4s cycleIndex state + Timer
  10 │ MED  │ No progress arc in timer view                   │ Stage1TimerView         │ Arc overlay driven by timerProgress
  11 │ MED  │ S2B missed panel not implemented                │ —                       │ New Stage2BMissedView
  12 │ MED  │ S3 task circle buttons no tap handler           │ Stage3DashboardView     │ .onTapGesture → markTaskDone
  13 │ LOW  │ No "Quit Notchly" in context menu               │ NotchRootView           │ Add NSApp.terminate(nil)
  14 │ LOW  │ Calendar only refreshes every 60s (too slow)    │ CalendarManager         │ Change to 5min + meal-close alerts
  15 │ LOW  │ BT battery ioreg picks wrong device             │ BatteryMonitor          │ Filter by device.addressString

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BLOCK 31 — COMPLETE TESTING CHECKLIST
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

WINDOW & POSITIONING:
[ ] S0 centered on physical notch (14" M3 Pro)
[ ] S0 centered on physical notch (16" M3 Max)
[ ] Non-notch Mac (Air M2): window top-center, no crash
[ ] External monitor connected: window on BUILT-IN screen only
[ ] Screen arrangement changed while running: repositions < 0.5s
[ ] Display sleep/wake: window repositions correctly
[ ] Mission Control / Exposé: window stays on top
[ ] Full-screen app on built-in: Notchly still visible above it
[ ] No Dock icon, no menu bar icon
[ ] Not in Cmd+Tab switcher

STAGE 0:
[ ] Dot dims correctly (alert=orange, task=green, music=blue, clear=gray 0.06)
[ ] Dot invisible in deep focus mode (same app >20min)
[ ] Dot fades in 0.4s when collapsing to S0
[ ] S0 truly blends with hardware notch (no visible pill border)

STAGE 1A — NOTIFICATION:
[ ] Alert appears within 0.1s of pending_alerts.json change (FSEvents)
[ ] Correct icon/dot color per alert type
[ ] Auto-collapse exactly 30s from appearance (no interaction)
[ ] Hover: hint text appears BEFORE bar grows
[ ] Hover: bar grows with buttons sliding from inside (not floating)
[ ] Button labels match action_left/action_right from JSON
[ ] Right button tap → action fires → continuity banner → S0
[ ] Left button tap → action fires → continuity banner → S0
[ ] Cursor leaves → bar shrinks, buttons slide back in
[ ] Missed on timeout → added to missedAlerts array
[ ] Volume HUD does NOT appear while S1A active

STAGE 1B — TIMER:
[ ] Active task appears when schedule.json has status:"active"
[ ] Timer counts down live (every 1 second)
[ ] Timer format: "1h 18m" for >60min, "18:42" for ≤60min
[ ] Label cycles: countdown → elapsed → percent (every 4s)
[ ] Cycle pauses when hovered
[ ] Tap timer label → pauses (gray + ⏸)
[ ] Tap again → resumes (green)
[ ] Haptic on pause/resume
[ ] Progress arc fills correctly based on elapsed/duration
[ ] S1B never auto-dismisses
[ ] At 0:00: amber color, shows buttons for 10s
[ ] Hover: Done/Break buttons appear (same slide mechanic)

STAGE 1.5 — HOVER:
[ ] Appears on cursor enter hover zone (400×75pt)
[ ] Shows active task + next task correctly
[ ] Missed badge visible when pendingAlerts > 0
[ ] NO buttons — completely read only
[ ] Exits immediately on cursor leave (after 200ms debounce)
[ ] Scroll ≥ 50pt → S2A
[ ] Scroll ≥ 120pt → S3

SWIPE GESTURES:
[ ] Right swipe 40pt+: green wash + suck into notch + right action fires
[ ] Left swipe 40pt+: warm gray wash + suck into notch + left action fires
[ ] Swipe < 40pt: spring back, 30s timer resets
[ ] Green wash maximum 55% opacity — never exceeds
[ ] Left wash is WARM GRAY rgba(80,80,80) — never red
[ ] Button scales 1.08× in swipe direction
[ ] Opposite button fades to 20%
[ ] Haptic at threshold
[ ] Suck-back animation: easeIn(0.22s)
[ ] Edge pulse fades: easeOut(0.30s)
[ ] Affordance nudge fires only ONCE (UserDefaults flag set after)
[ ] Hint text matches actual current button placement

STAGE 2A — NOWCARD:
[ ] Opens on single tap of S15 OR scroll 50pt
[ ] Mouse away: IMMEDIATE collapse to S0 (no delay)
[ ] All 8 button set types render correctly (task/meal/class/exercise/deadline/lazy/timer-up/break-end)
[ ] Deadline type: right button is red (#E24B4A)
[ ] App launch button: "Open [App]" if not running, "Switch to [App]" if running
[ ] App launch button hidden when app is already frontmost
[ ] Middle button: click only — swipe never triggers it

STAGE 2B — MISSED:
[ ] Shows instead of S2A when missedAlerts > 0
[ ] Shows last 2 missed items, reversed
[ ] Tap item → inline expand with 3 buttons
[ ] Only 1 item expanded at a time
[ ] "see all" → S3 Dashboard
[ ] "✕" → clear all + S0
[ ] Mouse away: immediate collapse

STAGE 3 — DASHBOARD:
[ ] Task circle tick → marks done → strikethrough animation → row fades
[ ] Calendar section shows current event OR next 2 events
[ ] Now Playing: correct song + artist + progress bar
[ ] Bluetooth battery bar colors (red < 20%, amber < 40%)
[ ] AI goal card shows workingMemory.todays_goal
[ ] Double-tap → S4 chat swaps in
[ ] Mouse away: immediate collapse

STAGE 4 — CHAT:
[ ] ⌘⇧Space opens from any app (not just Notchly)
[ ] Double-tap S0 opens S4
[ ] Context peek appears on schedule keywords (no API call)
[ ] AI responds within 5s (OpenClaw) or 8s (Claude API fallback)
[ ] Active session pins: mouse away does NOT close
[ ] Idle 60s → closes and clears
[ ] Re-enter within 60s → chat preserved
[ ] S3→S4 via double-tap: mouse away = IMMEDIATE close
[ ] ✕ button closes and clears

SCROLL (phase-aware):
[ ] Mid-gesture hold for 1s does NOT drop accumulator
[ ] Momentum scroll (post finger lift) does NOT trigger stage changes
[ ] Phase .ended → 0.45s reset timer, not immediate
[ ] Scroll up from S3 → S0

LEARNING & ALGORITHMS:
[ ] After 5 ignores of same type: notification suppressed (W < 0.30)
[ ] After 5 primary taps: W > 0.60, shows every time
[ ] W scores survive app restart (file persisted)
[ ] Most pressed action moves to right after week 2
[ ] Weekly rebuild fires Sunday 23:00
[ ] P formula weights assert == 1.0 at startup (fatalError if not)
[ ] EVR runs before every notification — high attention multiplier suppresses

SAFEGUARDS:
[ ] Diagnosis Mode: drops 40pt + gray bg + VERTICAL buttons
[ ] Burnout Pill: drops 40pt + RED bg + HORIZONTAL buttons (not gray)
[ ] Morning gate: all 3 conditions required (3am open = silence)
[ ] Postpone 3× → tomorrow 10am, continuity shows, count resets
[ ] Glass Break: Option key transforms button red, disables sensors till midnight

SYSTEM:
[ ] Calendar permission requested on first launch
[ ] Accessibility permission requested on first launch
[ ] App starts on login (launchd plist)
[ ] App restarts if it crashes (KeepAlive=true)
[ ] Zero force unwraps in build (grep "!" to verify)
[ ] Every Timer has stored var + deinit invalidate

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BUILD COMMANDS & TEST DATA
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Build
cd ~/Documents/notchly/notchly_v3codex
swift build -c release

# Install
pkill -x NotchlyV2; sleep 1
cp .build/release/notchly_v3codex /Applications/NotchlyV2.app/Contents/MacOS/NotchlyV2
codesign --force --deep --sign - /Applications/NotchlyV2.app
open /Applications/NotchlyV2.app

# Inject test notification (appears within 0.1s with FSEvents, 15s with timer poll)
cat > ~/Documents/notchly/v2/pending_alerts.json << 'EOF'
[{"id":"t1","type":"meal","title":"Lunch — Kadi Pakouri","message":"Mess closes in 7m","created_at":"2026-04-17T13:00:00Z","priority":1,"action_left":"Skip","action_right":"Going now"}]
EOF

# Inject active task
cat > ~/Documents/notchly/v2/schedule.json << 'EOF'
[{"id":"task-1","title":"Curry & Beans Logo","duration_minutes":90,"start_time":"2026-04-17T11:00:00Z","due":"2026-04-18T17:00:00Z","status":"active","project":"Client Work","priority":1,"rejection_count":0,"postpone_count":0}]
EOF

# Clear all
echo '[]' > ~/Documents/notchly/v2/pending_alerts.json && echo '[]' > ~/Documents/notchly/v2/schedule.json

# Check window bounds
swift - << 'EOF'
import CoreGraphics, Foundation
let wins = CGWindowListCopyWindowInfo([.optionAll], kCGNullWindowID) as? [[String:Any]] ?? []
for w in wins { if (w["kCGWindowOwnerName"] as? String) == "NotchlyV2" { print(w["kCGWindowBounds"] as Any, "layer:", w["kCGWindowLayer"] as Any) } }
EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
20-DAY BUILD ORDER (start here if you don't know what to do)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  DAY  │ Goal                                        │ Blocks
  ─────┼─────────────────────────────────────────────┼────────
   1   │ Fix window: built-in screen, correct pos     │ 1, 2
   2   │ S1A full hover + buttons + auto-dismiss      │ 3
   3   │ S1B timer cycle + pause + arc                │ 4
   4   │ Scroll depth S0→S1.5→S2→S3                  │ 11
   5   │ Swipe physics all 4 states                   │ 10
   6   │ Hotkeys ⌘⇧Space etc + double-click           │ 12
   7   │ S2A NowCard all 8 button sets                │ 6, 13
   8   │ S2B missed inline expand                     │ 7
   9   │ S3 task ticks + calendar + BT                │ 8
  10   │ S4 chat + context peek + session lock + AI   │ 9
  11   │ Priority scorer + EVR guard                  │ 14, 15
  12   │ Learning algorithm 4 layers + W scores       │ 16
  13   │ Memory system: episodic log + semantic profile│ 17
  14   │ Data sources: FSEvents, idle, app focus       │ 18
  15   │ BDI engine + dynamic scheduler               │ 19, 20
  16   │ All 5 safeguards                             │ 21
  17   │ Full day scenarios: class, meals, transit     │ 23
  18   │ Python brain daemon + launchd                │ 25
  19   │ Onboarding + permissions + launch at login    │ 28
  20   │ Final tests — every checkbox green            │ 31
