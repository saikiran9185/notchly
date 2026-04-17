import Foundation

// MARK: - V2 Data Schema

struct ScheduleTask: Codable, Identifiable, Equatable {
    let id: String
    var title: String
    var duration_minutes: Int
    var due: String?
    var started_at: String?    // ISO8601 — set when task becomes "active"
    var status: String         // "active" | "done" | "pending" | "break"
    var project: String?
    var priority: Int?

    var minutesLeft: Int {
        guard status == "active", let s = started_at,
              let start = ISO8601DateFormatter().date(from: s) else {
            return duration_minutes
        }
        let elapsed = Int(-start.timeIntervalSinceNow / 60)
        return max(0, duration_minutes - elapsed)
    }

    var timerLabel: String {
        let m = minutesLeft
        if m <= 0 { return "Done" }
        if m >= 60 { let h = m / 60; let r = m % 60; return r > 0 ? "\(h)h \(r)m left" : "\(h)h left" }
        return "\(m)m left"
    }
}

struct PendingAlert: Codable, Identifiable, Equatable {
    let id: String
    var type: String
    var title: String
    var message: String
    var created_at: String
    var priority: Int
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
    var status: String
    var project: String?
    var due: String?
    var priority: String?

    var isDone: Bool { status.lowercased() == "done" }
    var isInProgress: Bool { status.lowercased().contains("progress") }
}

// MARK: - DataStore

final class DataStore: NSObject, @unchecked Sendable {
    static let shared = DataStore()

    private let base = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Documents/notchly/v2")

    private(set) var schedule: [ScheduleTask] = []
    private(set) var alerts:   [PendingAlert] = []
    private(set) var memory:   WorkingMemory  = WorkingMemory()
    private(set) var notionTasks: [NotionTask] = []

    var onScheduleUpdate: (([ScheduleTask]) -> Void)?
    var onAlertsUpdate:   (([PendingAlert]) -> Void)?
    var onMemoryUpdate:   ((WorkingMemory)  -> Void)?
    var onNotionUpdate:   (([NotionTask])   -> Void)?

    private var timer: Timer?
    private var dirWatchSources: [DispatchSourceFileSystemObject] = []
    private var reloadWorkItem: DispatchWorkItem?

    private override init() {
        super.init()
        ensureDirectories()
    }

    func start() {
        load()
        // Immediate FSEvents watcher — fires within ~150ms of any file change
        startFileWatchers()
        // Fallback poll every 8s for cases FSEvents misses
        timer = Timer.scheduledTimer(withTimeInterval: 8, repeats: true) { [weak self] _ in
            self?.load()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        dirWatchSources.forEach { $0.cancel() }
        dirWatchSources.removeAll()
    }

    // MARK: - File system watchers (kqueue via DispatchSource)

    private func startFileWatchers() {
        let watchPaths = [base.path, base.appendingPathComponent("cache").path]
        for path in watchPaths {
            let fd = Darwin.open(path, O_EVTONLY)
            guard fd >= 0 else { continue }
            let src = DispatchSource.makeFileSystemObjectSource(
                fileDescriptor: fd,
                eventMask: [.write, .rename],
                queue: .global(qos: .utility)
            )
            src.setEventHandler { [weak self] in self?.scheduleReload() }
            src.setCancelHandler { Darwin.close(fd) }
            src.resume()
            dirWatchSources.append(src)
        }
    }

    private func scheduleReload() {
        reloadWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.load() }
        reloadWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: work)
    }

    // MARK: - Load

    private func load() {
        loadSchedule()
        loadAlerts()
        loadMemory()
        loadNotion()
    }

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
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.onScheduleUpdate?(self.schedule)
            }
        }
    }

    func markTaskActive(_ id: String) {
        let now = ISO8601DateFormatter().string(from: Date())
        for i in schedule.indices {
            if schedule[i].id == id {
                schedule[i].status = "active"
                schedule[i].started_at = now
            } else if schedule[i].status == "active" {
                schedule[i].status = "pending"
            }
        }
        saveSchedule()
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.onScheduleUpdate?(self.schedule)
        }
    }

    func addTask(_ task: ScheduleTask) {
        schedule.append(task)
        saveSchedule()
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.onScheduleUpdate?(self.schedule)
        }
    }

    // MARK: - Alerts

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

    // MARK: - Memory

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

    // MARK: - Notion

    private func loadNotion() {
        let url = base.appendingPathComponent("cache/notion_cache.json")
        guard let data = try? Data(contentsOf: url),
              let tasks = try? JSONDecoder().decode([NotionTask].self, from: data) else { return }
        DispatchQueue.main.async { [weak self] in
            self?.notionTasks = tasks
            self?.onNotionUpdate?(tasks)
        }
    }

    // MARK: - Computed

    var activeTask: ScheduleTask?   { schedule.first { $0.status == "active" } }
    var pendingTasks: [ScheduleTask] { schedule.filter { $0.status == "pending" } }
    var nextAlert: PendingAlert?    { alerts.first }

    // MARK: - Bootstrap sample data

    private func ensureDirectories() {
        let dirs = [base, base.appendingPathComponent("cache"), base.appendingPathComponent("memory")]
        dirs.forEach { try? FileManager.default.createDirectory(at: $0, withIntermediateDirectories: true) }
        createSampleDataIfNeeded()
    }

    private func createSampleDataIfNeeded() {
        let fm = FileManager.default

        let scheduleURL = base.appendingPathComponent("schedule.json")
        let scheduleEmpty = (try? Data(contentsOf: scheduleURL)).map { $0.count <= 4 } ?? true
        if !fm.fileExists(atPath: scheduleURL.path) || scheduleEmpty {
            let ts = ISO8601DateFormatter().string(from: Date())
            let sample = """
            [
              {"id":"demo1","title":"Build Notchly UI","duration_minutes":45,"status":"active","project":"Notchly","priority":1,"started_at":"\(ts)"},
              {"id":"demo2","title":"Review design tokens","duration_minutes":30,"status":"pending","project":"Notchly"},
              {"id":"demo3","title":"Test all gestures","duration_minutes":20,"status":"pending"}
            ]
            """
            try? sample.data(using: .utf8)?.write(to: scheduleURL)
        }

        let alertsURL = base.appendingPathComponent("pending_alerts.json")
        if !fm.fileExists(atPath: alertsURL.path) {
            try? "[]".data(using: .utf8)?.write(to: alertsURL)
        }

        let memURL = base.appendingPathComponent("working_memory.json")
        let memEmpty = (try? Data(contentsOf: memURL)).map { $0.count <= 4 } ?? true
        if !fm.fileExists(atPath: memURL.path) || memEmpty {
            let sample = """
            {"current_task":"Building Notchly","todays_goal":"Ship the notch assistant","focus_mode":true}
            """
            try? sample.data(using: .utf8)?.write(to: memURL)
        }

        let notionURL = base.appendingPathComponent("cache/notion_cache.json")
        if !fm.fileExists(atPath: notionURL.path) {
            try? "[]".data(using: .utf8)?.write(to: notionURL)
        }
    }
}
