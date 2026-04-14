import AppKit
import CoreGraphics
import SwiftUI

final class NotchWindowController: NSWindowController {
    private let state = NotchState()
    private var localScrollMonitor: Any?
    private var globalScrollMonitor: Any?

    private let volumeMonitor = VolumeMonitor()
    private let nowPlayingMonitor = NowPlayingMonitor()
    private let batteryMonitor = BatteryMonitor()
    private let calendarManager = CalendarManager()

    init(settings: SettingsManager) {
        let panel = NotchPanel()
        super.init(window: panel)
        state.attach(settings: settings)

        let hostingView = NSHostingView(rootView: NotchRootView(state: state))
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        panel.contentView = hostingView
        panel.backgroundColor = .clear

        if let contentView = panel.contentView {
            NSLayoutConstraint.activate([
                hostingView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                hostingView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                hostingView.topAnchor.constraint(equalTo: contentView.topAnchor),
                hostingView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
            ])
        }

        state.recalculate(using: currentScreen())
        applyWindowFrame(animated: false)
        startMonitors()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    private func startMonitors() {
        // Volume
        volumeMonitor.onVolumeChange = { [weak self] volume, muted in
            DispatchQueue.main.async {
                self?.state.handleVolumeChange(volume: volume, muted: muted)
            }
        }
        volumeMonitor.start()

        // Now Playing
        nowPlayingMonitor.onUpdate = { [weak self] info in
            self?.state.nowPlaying = info
        }
        nowPlayingMonitor.start()

        // Bluetooth Battery
        batteryMonitor.onUpdate = { [weak self] info in
            self?.state.bluetoothDevice = info
        }
        batteryMonitor.start()

        // Calendar
        calendarManager.onUpdate = { [weak self] events in
            self?.state.calendarEvents = events
        }
        calendarManager.start()
    }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        applyWindowFrame(animated: false)
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        installEventMonitors()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleStageChange),
            name: NotchState.stageDidChangeNotification,
            object: state
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleScreenChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSettingsChange),
            name: .notchSettingsDidChange,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func handleStageChange() { applyWindowFrame(animated: true) }
    @objc private func handleScreenChange() {
        state.recalculate(using: currentScreen())
        applyWindowFrame(animated: true)
    }
    @objc private func handleSettingsChange() {
        state.recalculate(using: currentScreen())
        applyWindowFrame(animated: true)
    }

    private func installEventMonitors() {
        localScrollMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
            self?.handleScrollEvent(event)
            return event
        }
        globalScrollMonitor = NSEvent.addGlobalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
            self?.handleScrollEvent(event)
        }
    }

    private func handleScrollEvent(_ event: NSEvent) {
        guard cursorIsInHoverZone() else { return }
        state.registerScroll(deltaY: event.scrollingDeltaY, isPrecise: event.hasPreciseScrollingDeltas)
    }

    private func cursorIsInHoverZone() -> Bool {
        guard let panel = window else { return false }
        let frame = panel.frame
        let hoverWidth = max(frame.width, 400)
        let hoverHeight = max(frame.height, 80)
        let rect = NSRect(
            x: frame.midX - (hoverWidth / 2.0),
            y: state.dimensions.screenMaxY - hoverHeight,
            width: hoverWidth,
            height: hoverHeight
        )
        return rect.contains(NSEvent.mouseLocation)
    }

    private func currentScreen() -> NSScreen? {
        builtinScreen() ?? NSScreen.main ?? NSScreen.screens.first
    }

    private func builtinScreen() -> NSScreen? {
        NSScreen.screens.first { screen in
            guard let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else { return false }
            let displayID = CGDirectDisplayID(number.uint32Value)
            return CGDisplayIsBuiltin(displayID) != 0
        }
    }

    private func applyWindowFrame(animated: Bool) {
        guard let panel = window as? NSPanel else { return }
        let stage = state.currentStage
        let size = state.size(for: stage)
        let x = state.dimensions.screenMidX - (size.width / 2.0) + state.horizontalOffset(for: stage)
        let y = state.dimensions.screenMaxY - size.height
        let frame = NSRect(x: x, y: y, width: size.width, height: size.height)
        panel.setContentSize(size)
        if animated {
            panel.animator().setFrame(frame, display: true)
        } else {
            panel.setFrame(frame, display: true)
        }
    }
}

private final class NotchPanel: NSPanel {
    init() {
        super.init(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isReleasedWhenClosed = false
        isOpaque = false
        hasShadow = false
        level = .statusBar
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        backgroundColor = .clear
        ignoresMouseEvents = false
        hidesOnDeactivate = false
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        acceptsMouseMovedEvents = true
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
