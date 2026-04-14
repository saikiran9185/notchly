import Foundation

enum DirectorySetup {
    static func ensureSupportDirectories() {
        let fm = FileManager.default
        let base = supportDirectory()
        let directories = [
            base,
            base.appendingPathComponent("logs", isDirectory: true),
            base.appendingPathComponent("memory", isDirectory: true),
            base.appendingPathComponent("cache", isDirectory: true)
        ]

        for url in directories {
            try? fm.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }

    static func supportDirectory() -> URL {
        let root = FileManager.default.homeDirectoryForCurrentUser
        return root
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Application Support", isDirectory: true)
            .appendingPathComponent("notchly_v3codex", isDirectory: true)
    }
}
