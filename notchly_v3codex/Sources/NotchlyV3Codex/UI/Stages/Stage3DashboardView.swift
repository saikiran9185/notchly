import SwiftUI

struct Stage3DashboardView: View {
    let dimensions:    NotchDimensions
    let currentEvent:  CalEvent?
    let nextEvent:     CalEvent?
    let missedCount:   Int
    let nowPlaying:    NowPlayingInfo?
    let bluetoothDevice: BTDeviceInfo?
    let activeTask:    ScheduleTask?
    let pendingTasks:  [ScheduleTask]
    let notionTasks:   [NotionTask]
    let memory:        WorkingMemory

    @State private var completedTaskIDs: Set<String> = []

    var body: some View {
        AsymmetricRoundedRect(topRadius: 0, bottomRadius: ND.Radius.large)
            .fill(SwiftUI.Color.black)
            .overlay {
                AsymmetricRoundedRect(topRadius: 0, bottomRadius: ND.Radius.large)
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
            }
            .overlay {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: ND.Space.lg) {

                        // MARK: — Header
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Today")
                                    .font(ND.Font.heading(18))
                                    .foregroundStyle(ND.Color.primary)
                                Text(todayString)
                                    .font(ND.Font.caption())
                                    .foregroundStyle(ND.Color.tertiary)
                            }
                            Spacer()
                            if let device = bluetoothDevice { btChip(device) }
                        }

                        // MARK: — Calendar
                        VStack(alignment: .leading, spacing: 0) {
                            calRow(
                                label: "Now",
                                value: currentEvent?.smartLabel ?? "Free",
                                accent: currentEvent != nil ? ND.Color.green : ND.Color.tertiary,
                                icon: "circle.fill",
                                active: currentEvent != nil
                            )
                            divider()
                            calRow(
                                label: "Next",
                                value: nextEvent?.smartLabel ?? "Nothing scheduled",
                                accent: nextEventAccent,
                                icon: "arrow.right",
                                active: false
                            )
                            if missedCount > 0 {
                                divider()
                                calRow(
                                    label: "Missed",
                                    value: "\(missedCount) event\(missedCount > 1 ? "s" : "") passed",
                                    accent: ND.Color.red,
                                    icon: "exclamationmark.circle.fill",
                                    active: false
                                )
                            }
                        }
                        .padding(ND.Space.md)
                        .background(
                            RoundedRectangle(cornerRadius: ND.Radius.chip, style: .continuous)
                                .fill(ND.Color.surface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: ND.Radius.chip, style: .continuous)
                                .stroke(ND.Color.stroke, lineWidth: 0.5)
                        )

                        // MARK: — Active Task
                        if let task = activeTask {
                            VStack(alignment: .leading, spacing: ND.Space.sm) {
                                HStack {
                                    HStack(spacing: 5) {
                                        Circle().fill(ND.Color.green).frame(width: 5, height: 5)
                                        NLabel(text: "Focus")
                                    }
                                    Spacer()
                                    Text(task.timerLabel)
                                        .font(ND.Font.mono(11))
                                        .foregroundStyle(ND.Color.green)
                                }
                                Text(task.title)
                                    .font(ND.Font.body())
                                    .foregroundStyle(ND.Color.primary)
                                if let project = task.project {
                                    Text(project)
                                        .font(ND.Font.caption())
                                        .foregroundStyle(ND.Color.tertiary)
                                }
                            }
                            .padding(ND.Space.md)
                            .background(
                                RoundedRectangle(cornerRadius: ND.Radius.chip, style: .continuous)
                                    .fill(ND.Color.green.opacity(0.07))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: ND.Radius.chip, style: .continuous)
                                            .stroke(ND.Color.green.opacity(0.18), lineWidth: 0.5)
                                    )
                            )
                        }

                        // MARK: — Pending Tasks
                        if !pendingTasks.isEmpty {
                            VStack(alignment: .leading, spacing: ND.Space.sm) {
                                NLabel(text: "Up Next")
                                ForEach(pendingTasks.prefix(3)) { task in
                                    let done = completedTaskIDs.contains(task.id)
                                    HStack(spacing: ND.Space.sm) {
                                        // Tappable circle tick button
                                        ZStack {
                                            Circle()
                                                .stroke(done ? ND.Color.green : ND.Color.muted, lineWidth: 1)
                                                .frame(width: 14, height: 14)
                                            if done {
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 8, weight: .bold))
                                                    .foregroundStyle(ND.Color.green)
                                            }
                                        }
                                        .onTapGesture {
                                            withAnimation(ND.Motion.fast) {
                                                completedTaskIDs.insert(task.id)
                                            }
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                                DataStore.shared.markTaskDone(task.id)
                                            }
                                        }

                                        Text(task.title)
                                            .font(ND.Font.caption())
                                            .foregroundStyle(done ? ND.Color.tertiary : ND.Color.secondary)
                                            .strikethrough(done, color: ND.Color.tertiary)
                                            .lineLimit(1)
                                            .animation(ND.Motion.fast, value: done)
                                        Spacer()
                                        if let p = task.priority, p == 1, !done {
                                            Image(systemName: "exclamationmark")
                                                .font(.system(size: 9, weight: .bold))
                                                .foregroundStyle(ND.Color.orange)
                                        }
                                    }
                                    .opacity(done ? 0.45 : 1.0)
                                    .animation(ND.Motion.fast, value: done)
                                }
                            }
                        }

                        // MARK: — Notion Tasks
                        let openNotion = notionTasks.filter { !$0.isDone }
                        if !openNotion.isEmpty {
                            VStack(alignment: .leading, spacing: ND.Space.sm) {
                                NLabel(text: "Notion")
                                ForEach(openNotion.prefix(4)) { task in notionRow(task) }
                            }
                        }

                        // MARK: — Now Playing
                        if let np = nowPlaying {
                            HStack(spacing: ND.Space.sm) {
                                Image(systemName: "music.note")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(ND.Color.green)
                                Text(np.displayLine)
                                    .font(ND.Font.caption())
                                    .foregroundStyle(ND.Color.secondary)
                                    .lineLimit(1)
                                Spacer()
                            }
                            .padding(.horizontal, ND.Space.md)
                            .padding(.vertical, ND.Space.sm)
                            .background(
                                Capsule().fill(ND.Color.surface)
                                    .overlay(Capsule().stroke(ND.Color.stroke, lineWidth: 0.5))
                            )
                        }

                        // MARK: — AI Goal
                        if let goal = memory.todays_goal {
                            HStack(spacing: ND.Space.sm) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 10))
                                    .foregroundStyle(ND.Color.purple)
                                Text(goal)
                                    .font(ND.Font.caption())
                                    .foregroundStyle(ND.Color.secondary)
                                    .lineLimit(2)
                            }
                            .padding(ND.Space.md)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: ND.Radius.chip, style: .continuous)
                                    .fill(ND.Color.purple.opacity(0.07))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: ND.Radius.chip, style: .continuous)
                                            .stroke(ND.Color.purple.opacity(0.15), lineWidth: 0.5)
                                    )
                            )
                        }

                        // Double-tap hint
                        HStack {
                            Spacer()
                            Text("Double-tap to ask Notchly")
                                .font(ND.Font.label())
                                .foregroundStyle(ND.Color.tertiary)
                                .tracking(0.3)
                            Spacer()
                        }
                    }
                    .padding(.top, dimensions.notchHeight + ND.Space.md)
                    .padding(.horizontal, ND.Space.lg)
                    .padding(.bottom, ND.Space.xl)
                }
            }
            .overlay {
                AsymmetricRoundedRect(topRadius: 0, bottomRadius: ND.Radius.large)
                    .stroke(ND.Color.stroke, lineWidth: 0.5)
            }
            .frame(width: 520, alignment: .top)
            .frame(maxHeight: 420, alignment: .top)
            .contentShape(AsymmetricRoundedRect(topRadius: 0, bottomRadius: ND.Radius.large))
    }

    // MARK: — Helpers

    private var todayString: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, d MMM"
        return f.string(from: Date())
    }

    private var nextEventAccent: SwiftUI.Color {
        guard let e = nextEvent else { return ND.Color.tertiary }
        return e.minutesUntil < 10 ? ND.Color.orange : ND.Color.secondary
    }

    private func divider() -> some View {
        Rectangle()
            .fill(ND.Color.stroke)
            .frame(height: 0.5)
            .padding(.vertical, ND.Space.sm)
    }

    private func calRow(label: String, value: String, accent: SwiftUI.Color, icon: String, active: Bool) -> some View {
        HStack(spacing: ND.Space.sm) {
            Image(systemName: icon)
                .font(.system(size: 7, weight: .bold))
                .foregroundStyle(accent)
                .frame(width: 12)
            VStack(alignment: .leading, spacing: 2) {
                NLabel(text: label)
                Text(value)
                    .font(ND.Font.body())
                    .foregroundStyle(active ? ND.Color.primary : ND.Color.primary.opacity(0.75))
                    .lineLimit(1)
            }
        }
    }

    private func notionRow(_ task: NotionTask) -> some View {
        HStack(spacing: ND.Space.sm) {
            Circle()
                .fill(task.isInProgress ? ND.Color.orange : ND.Color.muted)
                .frame(width: 5, height: 5)
            Text(task.title)
                .font(ND.Font.caption())
                .foregroundStyle(task.isInProgress ? ND.Color.primary : ND.Color.secondary)
                .lineLimit(1)
            Spacer()
            if let p = task.priority, p == "High" {
                Image(systemName: "exclamationmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(ND.Color.red)
            }
        }
    }

    private func btChip(_ device: BTDeviceInfo) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "airpodspro")
                .font(.system(size: 10))
                .foregroundStyle(ND.Color.tertiary)
            if let pct = device.batteryPercent {
                Text("\(pct)%")
                    .font(ND.Font.caption())
                    .foregroundStyle(pct < 20 ? ND.Color.red : ND.Color.secondary)
            }
        }
        .padding(.horizontal, ND.Space.sm)
        .padding(.vertical, 4)
        .background(Capsule().fill(ND.Color.surface).overlay(Capsule().stroke(ND.Color.stroke, lineWidth: 0.5)))
    }
}
