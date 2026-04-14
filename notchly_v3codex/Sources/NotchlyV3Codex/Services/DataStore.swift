import Foundation

// MARK: - V2 Data Schema (mirrors ~/Documents/notchly/v2/ JSON files)

struct ScheduleTask: Codable, Identifiable, Equatable {
    let id: String
    var title: String
    var duration_minutes: Int
    var due: String?
    var status: String // "active" | "done" | "pending" | "break"
    var project: String?
    var priority: Int?

    var minutesLeft: Int {
        // If due is a timestamp, compute remaining. Otherwise use duration.
        duration_minutes
    }

    var timerLabel: String {
        let m = minutesLeft
        if m <= 0 { return "Done" }
        if m >= 60 {
            let h = m / 60; let rem = m % 60
            return rem > 0 ? "\(h)h \(rem)m left" : "\(h)h left"
        }
        return "\(m)m left"
    }
}

struct PendingAlert: Codable, Identifiable, Equatable {
    let id: String
    var type: String      // "calendar" | "nudge" | "reminder" | "notion" | "ai"
    var title: String
    var message: String
    var created_at: String
    var priority: Int     // 1=high, 2=normal, 3=low
    var action_left: String?
    var action_right: String?
}

struct WorkingMemory: Codable, Equatable {
    var current_task: String?
    var context: String?
    var last_updated: String?
    var focus_mode: Bool?
    var todays_goal: String?
}

struct NotionTask: Codable, Identifiable, Equatable {
    let id: String
    var title: String
    var status: String    // "To Do" | "In Progress" | "Done"
    var project: String?
    var due: String?
    var priority: String? // "High" | "Medium" | "Low"

    var isDone: Bool { status.lowercased() == "done" }
    var isInProgress: Bool { status.lowercased().contains("progress") }
}

// MARK: - DataStore

final class DataStore: NSObject, @unchecked Sendable {
    static let shared = DataStore()

    private let base = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Documents/notchly/v2")

    // Published data
    private(set) var schedule: [ScheduleTask] = []
    private(set) var alerts: [PendingAlert] = []
    private(set) var memory: WorkingMemory = WorkingMemory()
    private(set) var notionTasks: [NotionTask] = []

    var onScheduleUpdate: (([ScheduleTask]) -> Void)?
    var onAlertsUpdate: (([PendingAlert]) -> Void)?
    var onMemoryUpdate: ((WorkingMemory) -> Void)?
    var onNotionUpdate: (([NotionTask]) -> Void)?

    private var timer: Timer?

    private override init() {
        super.init()
        ensureDirectories()
    }

    func start() {
        load()
        timer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
            self?.load()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func ensureDirectories() {
        let dirs = [base, base.appendingPathComponent("cache"), base.appendingPathComponent("memory")]
        dirs.forEach { try? FileManager.default.createDirectory(at: $0, withIntermediateDirectories: true) }
    }

    private func load() {
        loadSchedule()
        loadAlerts()
        loadMemory()
        loadNotion()
    }

    // MARK: Schedule
    private func loadSchedule() {
        let url = base.appendingPathComponent("schedule.json")
        guard let data = try? Data(contentsOf: url),
              let tasks = try? JSONDecoder().decode([ScheduleTask].self, from: data) else { return }
        DispatchQueue.main.async { [weak self] in
            self?.schedule = tasks
            self?.onScheduleUpdate?(tasks)
        }
    }

    func saveSchedule() {
        let url = base.appendingPathComponent("schedule.json")
        guard let data = try? JSONEncoder().encode(schedule) else { return }
        try? data.write(to: url)
    }

    func markTaskDone(_ id: String) {
        if let i = schedule.firstIndex(where: { $0.id == id }) {
            schedule[i].status = "done"
            saveSchedule()
            onScheduleUpdate?(schedule)
        }
    }

    func addTask(_ task: ScheduleTask) {
        schedule.append(task)
        saveSchedule()
        onScheduleUpdate?(schedule)
    }

    // MARK: Alerts
    private func loadAlerts() {
        let url = base.appendingPathComponent("pending_alerts.json")
        guard let data = try? Data(contentsOf: url),
              let items = try? JSONDecoder().decode([PendingAlert].self, from: data) else { return }
        DispatchQueue.main.async { [weak self] in
            self?.alerts = items.sorted { $0.priority < $1.priority }
            self?.onAlertsUpdate?(items)
        }
    }

    func dismissAlert(_ id: String) {
        alerts.removeAll { $0.id == id }
        let url = base.appendingPathComponent("pending_alerts.json")
        guard let data = try? JSONEncoder().encode(alerts) else { return }
        try? data.write(to: url)
        onAlertsUpdate?(alerts)
    }

    func addAlert(_ alert: PendingAlert) {
        alerts.append(alert)
        let url = base.appendingPathComponent("pending_alerts.json")
        guard let data = try? JSONEncoder().encode(alerts) else { return }
        try? data.write(to: url)
        onAlertsUpdate?(alerts)
    }

    // MARK: Memory
    private func loadMemory() {
        let url = base.appendingPathComponent("working_memory.json")
        guard let data = try? Data(contentsOf: url),
              let mem = try? JSONDecoder().decode(WorkingMemory.self, from: data) else { return }
        DispatchQueue.main.async { [weak self] in
            self?.memory = mem
            self?.onMemoryUpdate?(mem)
        }
    }

    func updateMemory(_ mem: WorkingMemory) {
        memory = mem
        let url = base.appendingPathComponent("working_memory.json")
        guard let data = try? JSONEncoder().encode(mem) else { return }
        try? data.write(to: url)
    }

    // MARK: Notion Cache
    private func loadNotion() {
        let url = base.appendingPathComponent("cache/notion_cache.json")
        guard let data = try? Data(contentsOf: url),
              let tasks = try? JSONDecoder().decode([NotionTask].self, from: data) else { return }
        DispatchQueue.main.async { [weak self] in
            self?.notionTasks = tasks
            self?.onNotionUpdate?(tasks)
        }
    }

    // Computed helpers
    var activeTask: ScheduleTask? {
        schedule.first { $0.status == "active" }
    }

    var pendingTasks: [ScheduleTask] {
        schedule.filter { $0.status == "pending" }
    }

    var nextAlert: PendingAlert? {
        alerts.first
    }

    var inProgressNotionTasks: [NotionTask] {
        notionTasks.filter { $0.isInProgress }
    }

    var todoNotionTasks: [NotionTask] {
        notionTasks.filter { !$0.isDone && !$0.isInProgress }
    }
}
