import AppKit
import CoreGraphics
import SwiftUI

final class NotchWindowController: NSWindowController, @unchecked Sendable {
    private let state = NotchState()
    private var localScrollMonitor: Any?
    private var globalScrollMonitor: Any?
    // NOTE: no global mouseMoved monitor — requires Accessibility permission.
    // Hover is handled via NSTrackingArea on the tracking overlay view.

    private let volumeMonitor     = VolumeMonitor()
    private let nowPlayingMonitor = NowPlayingMonitor()
    private let batteryMonitor    = BatteryMonitor()
    private let calendarManager   = CalendarManager()

    private weak var trackingOverlay: NotchTrackingView?
    private var hoverExitWorkItem: DispatchWorkItem?

    init(settings: SettingsManager) {
        let panel = NotchPanel()
        super.init(window: panel)
        state.attach(settings: settings)

        // Hosting view (SwiftUI root)
        let hostingView = NSHostingView(rootView: NotchRootView(state: state))
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        panel.contentView = hostingView
        panel.backgroundColor = .clear

        if let cv = panel.contentView {
            NSLayoutConstraint.activate([
                hostingView.leadingAnchor.constraint(equalTo: cv.leadingAnchor),
                hostingView.trailingAnchor.constraint(equalTo: cv.trailingAnchor),
                hostingView.topAnchor.constraint(equalTo: cv.topAnchor),
                hostingView.bottomAnchor.constraint(equalTo: cv.bottomAnchor),
            ])
        }

        // Transparent tracking overlay — sits on top, captures hover + scroll
        // without needing Accessibility permission
        let tracker = NotchTrackingView()
        tracker.translatesAutoresizingMaskIntoConstraints = false
        tracker.onEnter = { [weak self] in
            guard let self else { return }
            self.hoverExitWorkItem?.cancel()
            self.hoverExitWorkItem = nil
            self.state.setHover(true)
        }
        tracker.onExit = { [weak self] in
            guard let self else { return }
            let work = DispatchWorkItem { [weak self] in self?.state.setHover(false) }
            self.hoverExitWorkItem = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.20, execute: work)
        }
        tracker.onScroll = { [weak self] event in
            guard let self else { return }
            let phase = event.phase
            let momentumPhase = event.momentumPhase
            DispatchQueue.main.async {
                self.state.registerScroll(
                    deltaY: event.scrollingDeltaY,
                    isPrecise: event.hasPreciseScrollingDeltas,
                    phase: phase,
                    momentumPhase: momentumPhase
                )
            }
        }
        panel.contentView?.addSubview(tracker)
        if let cv = panel.contentView {
            NSLayoutConstraint.activate([
                tracker.leadingAnchor.constraint(equalTo: cv.leadingAnchor),
                tracker.trailingAnchor.constraint(equalTo: cv.trailingAnchor),
                tracker.topAnchor.constraint(equalTo: cv.topAnchor),
                tracker.bottomAnchor.constraint(equalTo: cv.bottomAnchor),
            ])
        }
        trackingOverlay = tracker

        state.recalculate(using: currentScreen())
        applyWindowFrame(animated: false)

        // windowDidLoad is NOT called when window is set via init(window:) —
        // wire all observers and monitors directly here.
        setupNotificationObservers()
        installScrollMonitors()
        startMonitors()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    // MARK: - Setup

    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleStageChange),
            name: NotchState.stageDidChangeNotification, object: state)
        NotificationCenter.default.addObserver(self, selector: #selector(handleScreenChange),
            name: NSApplication.didChangeScreenParametersNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleSettingsChange),
            name: .notchSettingsDidChange, object: nil)
    }

    private func installScrollMonitors() {
        // Local: events that land in our window
        localScrollMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
            self?.handleScrollEvent(event)
            return event
        }
        // Global: events anywhere on screen while cursor is in hover zone
        globalScrollMonitor = NSEvent.addGlobalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
            self?.handleScrollEvent(event)
        }
    }

    private func startMonitors() {
        volumeMonitor.onVolumeChange = { [weak self] vol, muted in
            DispatchQueue.main.async { self?.state.handleVolumeChange(volume: vol, muted: muted) }
        }
        volumeMonitor.start()

        nowPlayingMonitor.onUpdate = { [weak self] info in self?.state.nowPlaying = info }
        nowPlayingMonitor.start()

        batteryMonitor.onUpdate = { [weak self] info in self?.state.bluetoothDevice = info }
        batteryMonitor.start()

        calendarManager.onUpdate = { [weak self] events in self?.state.calendarEvents = events }
        calendarManager.start()

        DataStore.shared.onScheduleUpdate = { [weak self] tasks  in self?.state.applySchedule(tasks) }
        DataStore.shared.onAlertsUpdate   = { [weak self] alerts in self?.state.applyAlerts(alerts) }
        DataStore.shared.onMemoryUpdate   = { [weak self] mem    in self?.state.workingMemory = mem }
        DataStore.shared.onNotionUpdate   = { [weak self] tasks  in self?.state.notionTasks = tasks }
        DataStore.shared.start()
    }

    // MARK: - Window lifecycle

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        applyWindowFrame(animated: false)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        // Event monitors released automatically on dealloc
    }

    // MARK: - Notification handlers

    // MARK: - Hotkey

    func handleHotkeyToggle() {
        let stage = state.currentStage
        withAnimation(ND.Motion.expand) {
            if stage == .s0Idle || stage == .s15Hover {
                state.setStage(.s3Dashboard)
            } else {
                state.setStage(.s0Idle)
            }
        }
    }

    @objc private func handleStageChange()    { applyWindowFrame(animated: true) }
    @objc private func handleScreenChange()   { state.recalculate(using: currentScreen()); applyWindowFrame(animated: true) }
    @objc private func handleSettingsChange() { state.recalculate(using: currentScreen()); applyWindowFrame(animated: true) }

    // MARK: - Scroll (global fallback for events outside the window)

    private func handleScrollEvent(_ event: NSEvent) {
        guard cursorIsInHoverZone() else { return }
        let phase = event.phase
        let momentumPhase = event.momentumPhase
        DispatchQueue.main.async { [weak self] in
            self?.state.registerScroll(
                deltaY: event.scrollingDeltaY,
                isPrecise: event.hasPreciseScrollingDeltas,
                phase: phase,
                momentumPhase: momentumPhase
            )
        }
    }

    private func cursorIsInHoverZone() -> Bool {
        let mouse     = NSEvent.mouseLocation
        let midX      = state.dimensions.screenMidX
        let screenTop = state.dimensions.screenMaxY
        let zoneW: CGFloat = 600
        let zoneH: CGFloat = 120
        return NSRect(x: midX - zoneW / 2, y: screenTop - zoneH,
                      width: zoneW, height: zoneH).contains(mouse)
    }

    // MARK: - Screen helpers

    private func currentScreen() -> NSScreen? {
        builtinScreen() ?? NSScreen.main ?? NSScreen.screens.first
    }

    private func builtinScreen() -> NSScreen? {
        // Primary: the notch display always has auxiliaryTopLeftArea
        if let s = NSScreen.screens.first(where: {
            $0.auxiliaryTopLeftArea != nil && $0.auxiliaryTopRightArea != nil
        }) { return s }
        // Fallback: IOKit built-in flag
        return NSScreen.screens.first { screen in
            guard let n = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else { return false }
            return CGDisplayIsBuiltin(CGDirectDisplayID(n.uint32Value)) != 0
        }
    }

    // MARK: - Frame

    private func applyWindowFrame(animated: Bool) {
        guard let panel = window as? NSPanel else { return }
        let stage = state.currentStage
        let size  = state.size(for: stage)
        let x     = state.dimensions.screenMidX - (size.width / 2.0) + state.horizontalOffset(for: stage)
        let y     = state.dimensions.screenMaxY - size.height
        let frame = NSRect(x: x, y: y, width: size.width, height: size.height)
        panel.setContentSize(size)
        if animated {
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.28
                ctx.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                panel.animator().setFrame(frame, display: true)
            }
        } else {
            panel.setFrame(frame, display: true)
        }
    }
}

// MARK: - Tracking overlay view (hover + scroll, no Accessibility needed)

final class NotchTrackingView: NSView {
    var onEnter:  (() -> Void)?
    var onExit:   (() -> Void)?
    var onScroll: ((NSEvent) -> Void)?

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach { removeTrackingArea($0) }
        addTrackingArea(NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        ))
    }

    override func mouseEntered(with event: NSEvent) { onEnter?() }
    override func mouseExited(with event: NSEvent)  { onExit?()  }
    override func scrollWheel(with event: NSEvent)  { onScroll?(event) }

    // Pass all other events through so SwiftUI taps/gestures still work
    override func hitTest(_ point: NSPoint) -> NSView? {
        // Return nil so clicks fall through to the hosting view beneath
        nil
    }
}

// MARK: - NotchPanel

private final class NotchPanel: NSPanel {
    init() {
        super.init(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isReleasedWhenClosed       = false
        isOpaque                   = false
        hasShadow                  = false
        level                      = .statusBar
        collectionBehavior         = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        backgroundColor            = .clear
        ignoresMouseEvents         = false
        hidesOnDeactivate          = false
        titleVisibility            = .hidden
        titlebarAppearsTransparent = true
        acceptsMouseMovedEvents    = true
    }

    override var canBecomeKey:  Bool { false }
    override var canBecomeMain: Bool { false }
}
