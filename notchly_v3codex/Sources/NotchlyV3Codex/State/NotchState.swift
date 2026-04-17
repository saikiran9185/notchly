import AppKit
import Foundation

struct NotchDimensions {
    var notchWidth: CGFloat = 162
    var notchHeight: CGFloat = 38
    var screenMidX: CGFloat = 0
    var screenMaxY: CGFloat = 0
    var compactStageOffset: CGFloat = -70
    var expandedStageOffset: CGFloat = -28
    var notchMinX: CGFloat = 0
    var notchMaxX: CGFloat = 0
}

struct NotchAction: Identifiable, Equatable {
    let id: String
    let title: String
}

final class NotchState: ObservableObject {
    static let stageDidChangeNotification = Notification.Name("NotchState.stageDidChange")

    @Published private(set) var currentStage: NotchStage = .s0Idle {
        didSet {
            NotificationCenter.default.post(name: Self.stageDidChangeNotification, object: self)
        }
    }

    @Published private(set) var dimensions = NotchDimensions()

    // Notification / timer content
    @Published var currentMessage = "Nothing due right now"
    @Published var secondaryMessage = "Free window before class prep."
    @Published var currentTimerLabel = "24m left"
    @Published var timerProgress: CGFloat = 0.65
    @Published var currentAlertType = "nudge"
    @Published var continuityMessage: String?
    @Published var isHovered = false
    @Published var swipeOffset: CGFloat = 0
    @Published var timerPaused = false

    // Live services data
    @Published var volumeLevel: Float = 0.5
    @Published var volumeMuted: Bool = false
    @Published var nowPlaying: NowPlayingInfo? = nil
    @Published var bluetoothDevice: BTDeviceInfo? = nil
    @Published var calendarEvents: [CalEvent] = []

    // V2 DataStore data
    @Published var activeTask: ScheduleTask? = nil
    @Published var pendingTasks: [ScheduleTask] = []
    @Published var notionTasks: [NotionTask] = []
    @Published var workingMemory: WorkingMemory = WorkingMemory()
    @Published var pendingAlerts: [PendingAlert] = []

    private var autoCollapseTimer: Timer?
    private var continuityTimer: Timer?
    private var scrollResetTimer: Timer?
    private var volumeCollapseTimer: Timer?
    private var taskTickTimer: Timer?
    private var scrollAccumulator: CGFloat = 0
    private weak var settings: SettingsManager?

    func attach(settings: SettingsManager) {
        self.settings = settings
    }

    func recalculate(using screen: NSScreen?) {
        guard let screen else { return }
        let topInset = screen.safeAreaInsets.top
        dimensions.notchHeight = topInset > 0 ? topInset : 38
        calibrateNotchGeometry(using: screen)
        dimensions.screenMaxY = screen.frame.maxY
    }

    // MARK: - Volume
    func handleVolumeChange(volume: Float, muted: Bool) {
        volumeLevel = volume
        volumeMuted = muted
        guard currentStage == .s0Idle || currentStage == .s1Volume else { return }
        setStage(.s1Volume)
        volumeCollapseTimer?.invalidate()
        volumeCollapseTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { [weak self] _ in
            guard let self, self.currentStage == .s1Volume else { return }
            self.setStage(.s0Idle)
        }
    }

    // MARK: - DataStore integration
    func applySchedule(_ tasks: [ScheduleTask]) {
        activeTask = tasks.first { $0.status == "active" }
        pendingTasks = tasks.filter { $0.status == "pending" }

        if let task = activeTask {
            refreshTaskDisplay(task)
            startTaskTick()
            if currentStage == .s0Idle { setStage(.s1Timer) }
        } else {
            stopTaskTick()
        }
    }

    private func refreshTaskDisplay(_ task: ScheduleTask) {
        currentMessage = task.title
        currentTimerLabel = task.timerLabel
        let done = task.duration_minutes - task.minutesLeft
        timerProgress = CGFloat(min(1.0, max(0, Double(done) / Double(max(1, task.duration_minutes)))))
    }

    private func startTaskTick() {
        taskTickTimer?.invalidate()
        taskTickTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            guard let self, let task = self.activeTask, !self.timerPaused else { return }
            self.refreshTaskDisplay(task)
        }
    }

    private func stopTaskTick() {
        taskTickTimer?.invalidate()
        taskTickTimer = nil
    }

    func applyAlerts(_ alerts: [PendingAlert]) {
        pendingAlerts = alerts
        if let alert = alerts.first, currentStage == .s0Idle {
            currentMessage = alert.title.isEmpty ? alert.message : alert.title
            currentAlertType = alert.type
            setStage(.s1Notification)
        }
    }

    // MARK: - Reset
    func reset() {
        autoCollapseTimer?.invalidate()
        continuityTimer?.invalidate()
        volumeCollapseTimer?.invalidate()
        scrollAccumulator = 0
        continuityMessage = nil
        setStage(.s0Idle)
    }

    // MARK: - Card context
    var cardIcon: String {
        if activeTask != nil { return "checklist" }
        switch currentAlertType {
        case "calendar": return "calendar"
        case "reminder": return "bell.fill"
        case "notion":   return "doc.text.fill"
        case "ai":       return "sparkles"
        default:         return "bell.badge.fill"
        }
    }

    var cardIconColorName: String {
        if activeTask != nil { return "green" }
        switch currentAlertType {
        case "calendar": return "blue"
        case "ai":       return "purple"
        default:         return "orange"
        }
    }

    // MARK: - Stage management
    func cycleDemoStage() {
        let stages = NotchStage.allCases
        guard let index = stages.firstIndex(of: currentStage) else { return }
        setStage(stages[(index + 1) % stages.count])
    }

    func setStage(_ stage: NotchStage) {
        autoCollapseTimer?.invalidate()
        currentStage = stage
        swipeOffset = 0
        if stage == .s1Notification || stage == .s1Timer {
            scheduleAutoCollapse()
        }
    }

    func size(for stage: NotchStage) -> CGSize {
        let settings = settings ?? .shared
        switch stage {
        case .s0Idle:
            return CGSize(width: settings.collapsedWidth, height: settings.collapsedHeight)
        case .s1Notification:
            return CGSize(width: settings.widgetWidth, height: showsInlineButtons ? max(settings.widgetHeight + 59, 96) : max(settings.widgetHeight + 21, 58))
        case .s1Timer:
            return CGSize(width: min(max(settings.widgetWidth, 280), 360), height: showsInlineButtons ? max(settings.widgetHeight + 70, 108) : max(settings.widgetHeight + 32, 68))
        case .s1Volume:
            return CGSize(width: 220, height: max(dimensions.notchHeight + 30, 60))
        case .s15Hover:
            return CGSize(width: 340, height: 70)
        case .s2Card:
            return CGSize(width: 380, height: 180)
        case .s3Dashboard:
            return CGSize(width: settings.expandedWidth, height: max(settings.expandedHeight + 110, 340))
        case .s4Chat:
            return CGSize(width: settings.expandedWidth, height: max(settings.expandedHeight + 100, 320))
        }
    }

    func horizontalOffset(for stage: NotchStage) -> CGFloat {
        let settings = settings ?? .shared
        switch stage {
        case .s0Idle, .s1Notification, .s1Timer, .s2Card, .s1Volume:
            return settings.compactOffsetX
        case .s15Hover, .s3Dashboard, .s4Chat:
            return settings.expandedOffsetX
        }
    }

    // MARK: - Calendar
    var currentCalEvent: CalEvent? { calendarEvents.first { $0.isNow } }
    var nextCalEvent: CalEvent? { calendarEvents.first { $0.isUpcoming } }
    var missedCalCount: Int { calendarEvents.filter { $0.endDate < Date() }.count }

    // MARK: - Idle state hints
    var hasPendingAlert: Bool { !pendingAlerts.isEmpty }
    var hasActiveTask: Bool { activeTask != nil }
    var isPlayingMusic: Bool { nowPlaying?.isPlaying == true }

    // MARK: - Actions
    var leftAction: NotchAction? {
        switch currentStage {
        case .s1Notification:
            // Use dynamic label from alert schema if present
            let label = pendingAlerts.first?.action_left ?? "Skip"
            return .init(id: "dismiss", title: label)
        case .s1Timer: return .init(id: "take_break", title: "Break")
        case .s2Card: return .init(id: "later", title: "Later")
        default: return nil
        }
    }

    var centerAction: NotchAction? {
        switch currentStage {
        case .s2Card: return .init(id: "going", title: "Going")
        default: return nil
        }
    }

    var rightAction: NotchAction? {
        switch currentStage {
        case .s1Notification:
            let label = pendingAlerts.first?.action_right ?? "Got it"
            return .init(id: "done_alert", title: label)
        case .s1Timer: return .init(id: "done_task", title: "Done")
        case .s2Card: return .init(id: "done_card", title: "Done")
        default: return nil
        }
    }

    var showsInlineButtons: Bool {
        switch currentStage {
        case .s1Notification, .s1Timer: return isHovered
        case .s2Card: return true
        default: return false
        }
    }

    func handlePrimaryTap() {
        switch currentStage {
        case .s0Idle: setStage(.s15Hover)
        case .s1Notification, .s1Timer: setStage(.s2Card)
        case .s1Volume: setStage(.s0Idle)
        case .s15Hover: setStage(.s2Card)
        case .s2Card: setStage(.s3Dashboard)
        case .s3Dashboard: setStage(.s0Idle)
        case .s4Chat: break
        }
    }

    func applySwipeOffset(_ value: CGFloat) { swipeOffset = value }

    func commitSwipeIfNeeded(predictedEnd: CGFloat) {
        let threshold: CGFloat = 40
        defer { swipeOffset = 0 }
        if predictedEnd >= threshold, let action = rightAction { perform(action) }
        else if predictedEnd <= -threshold, let action = leftAction { perform(action) }
    }

    func perform(_ action: NotchAction) {
        continuityMessage = "\(action.title) ✓"
        continuityTimer?.invalidate()
        continuityTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { [weak self] _ in
            self?.continuityMessage = nil
        }

        switch action.id {
        case "done_alert":
            if let alert = pendingAlerts.first {
                DataStore.shared.dismissAlert(alert.id)
            }
            setStage(.s0Idle)
        case "dismiss":
            setStage(.s0Idle)
        case "done_task":
            if let task = activeTask {
                DataStore.shared.markTaskDone(task.id)
            }
            currentMessage = "Task complete"
            currentTimerLabel = "Done"
            timerProgress = 1.0
            // Load next pending task immediately before collapsing
            let remaining = pendingTasks
            if let next = remaining.first {
                currentMessage = next.title
                currentTimerLabel = next.timerLabel
                timerProgress = 0
                continuityMessage = "\(activeTask?.title ?? "Task") done · \(next.title) loading"
            }
            setStage(.s0Idle)
        case "take_break":
            currentMessage = "Break started"
            setStage(.s0Idle)
        case "later":
            currentMessage = "Rescheduled"
            setStage(.s0Idle)
        case "going":
            currentMessage = "On your way"
            setStage(.s0Idle)
        case "done_card":
            currentMessage = "Handled"
            setStage(.s0Idle)
        default:
            setStage(.s0Idle)
        }
    }

    func setHover(_ hovering: Bool) {
        guard isHovered != hovering else { return }
        isHovered = hovering
        switch currentStage {
        case .s1Notification, .s1Timer:
            if hovering { autoCollapseTimer?.invalidate() }
        default: break
        }
    }

    func registerScroll(deltaY rawDeltaY: CGFloat, isPrecise: Bool, phase: NSEvent.Phase = [], momentumPhase: NSEvent.Phase = []) {
        // Ignore inertial (momentum) scroll after finger lift — only act on real gesture
        guard momentumPhase.isEmpty || momentumPhase == .stationary else { return }

        // Gesture ended: schedule a short reset so a new swipe starts fresh
        if phase == .ended || phase == .cancelled {
            scrollResetTimer?.invalidate()
            scrollResetTimer = Timer.scheduledTimer(withTimeInterval: 0.45, repeats: false) { [weak self] _ in
                self?.scrollAccumulator = 0
            }
            return  // Don't act on the final zero-delta ended event
        }

        let scaledDelta = isPrecise ? rawDeltaY : rawDeltaY * 8.0
        scrollAccumulator += scaledDelta

        // For mouse-wheel (no phase), use a short idle timer
        if !isPrecise || phase.isEmpty {
            scrollResetTimer?.invalidate()
            scrollResetTimer = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: false) { [weak self] _ in
                self?.scrollAccumulator = 0
            }
        }

        // Collapse on scroll-down
        if scrollAccumulator <= -16 { setStage(.s0Idle); scrollAccumulator = 0; return }

        // Expand stages — lower thresholds for snappier trackpad feel
        switch scrollAccumulator {
        case ..<12:   break
        case 12..<36: if currentStage != .s15Hover    { setStage(.s15Hover)    }
        case 36..<80: if currentStage != .s2Card      { setStage(.s2Card)      }
        default:      if currentStage != .s3Dashboard { setStage(.s3Dashboard) }
        }
    }

    func toggleTimerPause() {
        timerPaused.toggle()
        currentTimerLabel = timerPaused ? "Paused" : (activeTask?.timerLabel ?? "24m left")
        continuityMessage = timerPaused ? "Paused" : "Resumed"
        continuityTimer?.invalidate()
        continuityTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { [weak self] _ in
            self?.continuityMessage = nil
        }
    }

    private func scheduleAutoCollapse() {
        autoCollapseTimer?.invalidate()
        autoCollapseTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: false) { [weak self] _ in
            guard let self, !self.isHovered else { return }
            self.setStage(.s0Idle)
        }
    }

    private func calibrateNotchGeometry(using screen: NSScreen) {
        let frame = screen.frame
        let fallbackWidth = inferredNotchWidth(for: screen)
        if let left = screen.auxiliaryTopLeftArea, let right = screen.auxiliaryTopRightArea {
            let minX = left.maxX; let maxX = right.minX
            let computedWidth = max(0, maxX - minX)
            if computedWidth > 0 {
                dimensions.notchMinX = minX; dimensions.notchMaxX = maxX
                dimensions.notchWidth = computedWidth
                dimensions.screenMidX = minX + (computedWidth / 2.0)
                return
            }
        }
        dimensions.notchWidth = fallbackWidth
        dimensions.screenMidX = frame.midX
        dimensions.notchMinX = dimensions.screenMidX - (fallbackWidth / 2.0)
        dimensions.notchMaxX = dimensions.screenMidX + (fallbackWidth / 2.0)
    }

    private func inferredNotchWidth(for screen: NSScreen) -> CGFloat {
        switch screen.frame.width {
        case ..<1600: return 150
        case 1600..<2600: return 162
        default: return 184
        }
    }

    deinit {
        autoCollapseTimer?.invalidate()
        continuityTimer?.invalidate()
        scrollResetTimer?.invalidate()
        volumeCollapseTimer?.invalidate()
        taskTickTimer?.invalidate()
    }
}
