import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var windowController: NotchWindowController?
    private var settingsWindowController: SettingsWindowController?
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        DirectorySetup.ensureSupportDirectories()
        setupMenuBarIcon()

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

        // Shift+Space global hotkey — no Accessibility permission required
        HotkeyManager.shared.onTrigger = { [weak self] in
            self?.windowController?.handleHotkeyToggle()
        }
        HotkeyManager.shared.register()
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

    // MARK: - Menu bar icon

    private func setupMenuBarIcon() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        guard let btn = statusItem?.button else { return }
        btn.image = NSImage(systemSymbolName: "circle.fill", accessibilityDescription: "Notchly")
        btn.image?.isTemplate = true

        let menu = NSMenu()
        menu.addItem(withTitle: "Notchly", action: nil, keyEquivalent: "").isEnabled = false
        menu.addItem(.separator())
        menu.addItem(withTitle: "Open Settings", action: #selector(openSettingsWindow), keyEquivalent: ",")
        menu.addItem(withTitle: "Reset to Idle", action: #selector(resetToIdle), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Notchly", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        statusItem?.menu = menu
    }

    @objc private func resetToIdle() {
        windowController?.handleHotkeyToggle()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
