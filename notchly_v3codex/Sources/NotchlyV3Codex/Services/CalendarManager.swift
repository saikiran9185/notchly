import EventKit
import Foundation

struct CalEvent: Identifiable, Equatable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date

    var isNow: Bool {
        let now = Date()
        return startDate <= now && endDate >= now
    }

    var isUpcoming: Bool { startDate > Date() }

    var timeString: String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: startDate)
    }

    var minutesUntil: Int {
        Int(startDate.timeIntervalSinceNow / 60)
    }

    var smartLabel: String {
        if isNow {
            let left = Int(endDate.timeIntervalSinceNow / 60)
            return "\(title) · \(left)m left"
        }
        let mins = minutesUntil
        if mins < 60 { return "\(title) in \(mins)m" }
        return "\(title) at \(timeString)"
    }
}

final class CalendarManager: NSObject, @unchecked Sendable {
    var onUpdate: (([CalEvent]) -> Void)?
    private(set) var todayEvents: [CalEvent] = []
    private let store = EKEventStore()
    private var timer: Timer?
    private var authorized = false

    func start() {
        requestAccess()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func requestAccess() {
        if #available(macOS 14.0, *) {
            store.requestFullAccessToEvents { [weak self] granted, _ in
                guard granted else { return }
                DispatchQueue.main.async {
                    self?.authorized = true
                    self?.fetchToday()
                    self?.scheduleRefresh()
                }
            }
        } else {
            store.requestAccess(to: .event) { [weak self] granted, _ in
                guard granted else { return }
                DispatchQueue.main.async {
                    self?.authorized = true
                    self?.fetchToday()
                    self?.scheduleRefresh()
                }
            }
        }
    }

    private func scheduleRefresh() {
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.fetchToday()
        }
    }

    func fetchToday() {
        guard authorized else { return }
        let now = Date()
        let cal = Calendar.current
        let start = cal.startOfDay(for: now)
        let end = cal.date(byAdding: .day, value: 1, to: start)!

        let pred = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        let raw = store.events(matching: pred)
            .filter { !$0.isAllDay }
            .sorted { $0.startDate < $1.startDate }

        let events = raw.map { e in
            CalEvent(
                id: e.eventIdentifier ?? UUID().uuidString,
                title: e.title ?? "Event",
                startDate: e.startDate,
                endDate: e.endDate
            )
        }
        todayEvents = events
        onUpdate?(events)
    }

    var currentEvent: CalEvent? {
        todayEvents.first { $0.isNow }
    }

    var nextEvent: CalEvent? {
        todayEvents.first { $0.isUpcoming }
    }

    var missedCount: Int {
        let now = Date()
        return todayEvents.filter { $0.endDate < now }.count
    }
}
