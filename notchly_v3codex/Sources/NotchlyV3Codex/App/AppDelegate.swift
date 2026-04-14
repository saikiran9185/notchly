import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var windowController: NotchWindowController?
    private var settingsWindowController: SettingsWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        DirectorySetup.ensureSupportDirectories()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(openSettingsWindow),
            name: .notchOpenSettings,
            object: nil
        )

        let controller = NotchWindowController(settings: SettingsManager.shared)
        controller.showWindow(nil)
        controller.window?.orderFrontRegardless()
        windowController = controller
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    @objc
    private func openSettingsWindow() {
        let controller = settingsWindowController ?? SettingsWindowController(settings: SettingsManager.shared)
        settingsWindowController = controller
        controller.showWindow(nil)
        controller.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
