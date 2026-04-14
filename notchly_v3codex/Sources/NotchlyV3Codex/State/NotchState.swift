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
    @Published var currentMessage = "Nothing due right now"
    @Published var secondaryMessage = "Free window before class prep."
    @Published var currentTimerLabel = "24m left"
    @Published var continuityMessage: String?
    @Published var isHovered = false
    @Published var swipeOffset: CGFloat = 0
    @Published var timerPaused = false

    // Live data
    @Published var volumeLevel: Float = 0.5
    @Published var volumeMuted: Bool = false
    @Published var nowPlaying: NowPlayingInfo? = nil
    @Published var bluetoothDevice: BTDeviceInfo? = nil
    @Published var calendarEvents: [CalEvent] = []

    private var autoCollapseTimer: Timer?
    private var continuityTimer: Timer?
    private var scrollResetTimer: Timer?
    private var volumeCollapseTimer: Timer?
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

    // MARK: - Volume
    func handleVolumeChange(volume: Float, muted: Bool) {
        volumeLevel = volume
        volumeMuted = muted
        // Only pop the volume stage if we're idle or already on volume
        guard currentStage == .s0Idle || currentStage == .s1Volume else { return }
        setStage(.s1Volume)
        volumeCollapseTimer?.invalidate()
        volumeCollapseTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { [weak self] _ in
            guard let self, self.currentStage == .s1Volume else { return }
            self.setStage(.s0Idle)
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

    func size(for stage: NotchStage) -> CGSize {
        let settings = settings ?? .shared

        switch stage {
        case .s0Idle:
            return CGSize(width: settings.collapsedWidth, height: settings.collapsedHeight)
        case .s1Notification:
            return CGSize(width: settings.widgetWidth, height: showsInlineButtons ? max(settings.widgetHeight + 59, 96) : max(settings.widgetHeight + 21, 58))
        case .s1Timer:
            return CGSize(width: min(max(settings.widgetWidth, 280), 360), height: showsInlineButtons ? max(settings.widgetHeight + 63, 98) : max(settings.widgetHeight + 25, 60))
        case .s1Volume:
            return CGSize(width: 220, height: max(dimensions.notchHeight + 30, 60))
        case .s15Hover:
            return CGSize(width: 340, height: 70)
        case .s2Card:
            return CGSize(width: 380, height: 168)
        case .s3Dashboard:
            return CGSize(width: settings.expandedWidth, height: max(settings.expandedHeight + 110, 320))
        case .s4Chat:
            return CGSize(width: settings.expandedWidth, height: max(settings.expandedHeight + 70, 260))
        }
    }

    func horizontalOffset(for stage: NotchStage) -> CGFloat {
        let settings = settings ?? .shared
        switch stage {
        case .s1Notification, .s1Timer, .s2Card, .s1Volume:
            return settings.compactOffsetX
        case .s0Idle:
            return settings.compactOffsetX - 16
        case .s15Hover:
            return settings.expandedOffsetX - 24
        case .s3Dashboard, .s4Chat:
            return settings.expandedOffsetX - 36
        }
    }

    // MARK: - Calendar helpers
    var currentCalEvent: CalEvent? {
        calendarEvents.first { $0.isNow }
    }

    var nextCalEvent: CalEvent? {
        calendarEvents.first { $0.isUpcoming }
    }

    var missedCalCount: Int {
        let now = Date()
        return calendarEvents.filter { $0.endDate < now }.count
    }

    // MARK: - Actions
    var leftAction: NotchAction? {
        switch currentStage {
        case .s1Notification: return .init(id: "skip_breakfast", title: "Skip")
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
        case .s1Notification: return .init(id: "had_breakfast", title: "Had It")
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

    func applySwipeOffset(_ value: CGFloat) {
        swipeOffset = value
    }

    func commitSwipeIfNeeded(predictedEnd: CGFloat) {
        let threshold: CGFloat = 40
        defer { swipeOffset = 0 }

        if predictedEnd >= threshold, let action = rightAction {
            perform(action)
        } else if predictedEnd <= -threshold, let action = leftAction {
            perform(action)
        }
    }

    func perform(_ action: NotchAction) {
        continuityMessage = "\(action.title) confirmed"
        continuityTimer?.invalidate()
        continuityTimer = Timer.scheduledTimer(withTimeInterval: 4, repeats: false) { [weak self] _ in
            self?.continuityMessage = nil
        }

        switch action.id {
        case "had_breakfast":
            currentMessage = "Breakfast logged"
            secondaryMessage = "Nice. Next up: class prep."
            setStage(.s0Idle)
        case "skip_breakfast":
            currentMessage = "Breakfast skipped"
            secondaryMessage = "I'll stop pushing this for now."
            setStage(.s0Idle)
        case "done_task":
            currentMessage = "Task complete"
            secondaryMessage = "Loading the next focus block."
            currentTimerLabel = "18m left"
            setStage(.s0Idle)
        case "take_break":
            currentMessage = "Break started"
            secondaryMessage = "I'll bring you back in 5 minutes."
            setStage(.s0Idle)
        case "later":
            currentMessage = "Rescheduled"
            secondaryMessage = "Moved into your next free slot."
            setStage(.s0Idle)
        case "going":
            currentMessage = "On your way"
            secondaryMessage = "I'll hold the next task."
            setStage(.s0Idle)
        case "done_card":
            currentMessage = "Handled"
            secondaryMessage = "Queue updated."
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

    func registerScroll(deltaY rawDeltaY: CGFloat, isPrecise: Bool) {
        let scaledDelta = isPrecise ? rawDeltaY : rawDeltaY * 8.0
        scrollAccumulator += scaledDelta

        scrollResetTimer?.invalidate()
        scrollResetTimer = Timer.scheduledTimer(withTimeInterval: 0.18, repeats: false) { [weak self] _ in
            self?.scrollAccumulator = 0
        }

        if scrollAccumulator <= -24 {
            setStage(.s0Idle)
            scrollAccumulator = 0
            return
        }

        switch scrollAccumulator {
        case ..<20: break
        case 20..<56:
            if currentStage != .s15Hover { setStage(.s15Hover) }
        case 56..<126:
            if currentStage != .s2Card { setStage(.s2Card) }
        default:
            if currentStage != .s3Dashboard { setStage(.s3Dashboard) }
        }
    }

    func toggleTimerPause() {
        timerPaused.toggle()
        currentTimerLabel = timerPaused ? "Paused" : "24m left"
        continuityMessage = timerPaused ? "Timer paused" : "Timer resumed"
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

        if let left = screen.auxiliaryTopLeftArea,
           let right = screen.auxiliaryTopRightArea {
            let minX = left.maxX
            let maxX = right.minX
            let computedWidth = max(0, maxX - minX)
            if computedWidth > 0 {
                dimensions.notchMinX = minX
                dimensions.notchMaxX = maxX
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
        let width = screen.frame.width
        switch width {
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
    }
}
