import AppKit
import SwiftUI

final class SettingsWindowController: NSWindowController {
    init(settings: SettingsManager) {
        let view = SettingsView(settings: settings)
        let host = NSHostingController(rootView: view)

        let window = NSWindow(contentViewController: host)
        window.title = "Notchly Calibration"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.setContentSize(NSSize(width: 430, height: 520))
        window.isReleasedWhenClosed = false
        window.center()

        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }
}
