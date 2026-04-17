import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
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
        menu.addItem(withTitle: "Open Settings",  action: #selector(openSettingsWindow), keyEquivalent: ",")
        menu.addItem(withTitle: "Reset to Idle",  action: #selector(resetToIdle),        keyEquivalent: "")
        menu.addItem(.separator())
        let spItem = NSMenuItem(title: screenpipeRunning() ? "Stop Screenpipe" : "Start Screenpipe",
                                action: #selector(toggleScreenpipe), keyEquivalent: "")
        spItem.tag = 42
        menu.addItem(spItem)
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Notchly", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        statusItem?.menu = menu
        statusItem?.menu?.delegate = self
    }

    @objc private func resetToIdle() {
        windowController?.handleHotkeyToggle()
    }

    @objc private func toggleScreenpipe() {
        if screenpipeRunning() {
            Process.launchedProcess(launchPath: "/bin/sh",
                arguments: ["-c", "pkill -f 'screenpipe record'"])
        } else {
            let p = Process()
            p.launchPath = "/bin/sh"
            p.arguments  = ["-c",
                "\(screenpipePath()) record --disable-audio >> ~/Documents/notchly/brain/screenpipe.log 2>&1 &"]
            try? p.run()
        }
    }

    private func screenpipeRunning() -> Bool {
        let t = Process()
        t.launchPath = "/bin/sh"
        t.arguments  = ["-c", "pgrep -f 'screenpipe record' > /dev/null 2>&1"]
        try? t.run(); t.waitUntilExit()
        return t.terminationStatus == 0
    }

    private func screenpipePath() -> String {
        let candidates = [
            "\(NSHomeDirectory())/.local/bin/screenpipe",
            "/usr/local/bin/screenpipe",
            "/opt/homebrew/bin/screenpipe"
        ]
        return candidates.first { FileManager.default.fileExists(atPath: $0) }
            ?? "screenpipe"
    }

    // Update "Start/Stop Screenpipe" label each time the menu opens
    func menuWillOpen(_ menu: NSMenu) {
        if let item = menu.item(withTag: 42) {
            item.title = screenpipeRunning() ? "Stop Screenpipe ●" : "Start Screenpipe"
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
