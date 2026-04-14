import Foundation

extension Notification.Name {
    static let notchSettingsDidChange = Notification.Name("NotchSettingsDidChange")
    static let notchOpenSettings = Notification.Name("NotchOpenSettings")
}

final class SettingsManager: ObservableObject {
    nonisolated(unsafe) static let shared = SettingsManager()

    @Published var collapsedWidth: Double {
        didSet { persist("collapsedWidth", collapsedWidth) }
    }
    @Published var collapsedHeight: Double {
        didSet { persist("collapsedHeight", collapsedHeight) }
    }
    @Published var expandedWidth: Double {
        didSet { persist("expandedWidth", expandedWidth) }
    }
    @Published var expandedHeight: Double {
        didSet { persist("expandedHeight", expandedHeight) }
    }
    @Published var widgetWidth: Double {
        didSet { persist("widgetWidth", widgetWidth) }
    }
    @Published var widgetHeight: Double {
        didSet { persist("widgetHeight", widgetHeight) }
    }
    @Published var cornerRadius: Double {
        didSet { persist("cornerRadius", cornerRadius) }
    }
    @Published var compactOffsetX: Double {
        didSet { persist("compactOffsetX", compactOffsetX) }
    }
    @Published var expandedOffsetX: Double {
        didSet { persist("expandedOffsetX", expandedOffsetX) }
    }

    private let defaults: UserDefaults

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        collapsedWidth = defaults.object(forKey: "collapsedWidth") as? Double ?? 180
        collapsedHeight = defaults.object(forKey: "collapsedHeight") as? Double ?? 32
        expandedWidth = defaults.object(forKey: "expandedWidth") as? Double ?? 510
        expandedHeight = defaults.object(forKey: "expandedHeight") as? Double ?? 250
        widgetWidth = defaults.object(forKey: "widgetWidth") as? Double ?? 350
        widgetHeight = defaults.object(forKey: "widgetHeight") as? Double ?? 37
        cornerRadius = defaults.object(forKey: "cornerRadius") as? Double ?? 15
        compactOffsetX = defaults.object(forKey: "compactOffsetX") as? Double ?? -70
        expandedOffsetX = defaults.object(forKey: "expandedOffsetX") as? Double ?? -28
    }

    func resetToDefaults() {
        collapsedWidth = 180
        collapsedHeight = 32
        expandedWidth = 510
        expandedHeight = 250
        widgetWidth = 350
        widgetHeight = 37
        cornerRadius = 15
        compactOffsetX = -70
        expandedOffsetX = -28
    }

    private func persist(_ key: String, _ value: Double) {
        defaults.set(value, forKey: key)
        NotificationCenter.default.post(name: .notchSettingsDidChange, object: self)
    }
}
