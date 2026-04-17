import SwiftUI

struct Stage4ChatView: View {
    let dimensions:   NotchDimensions
    let activeTask:   ScheduleTask?
    let pendingTasks: [ScheduleTask]
    let currentEvent: CalEvent?
    let nextEvent:    CalEvent?
    let memory:       WorkingMemory

    @State private var draft    = ""
    @State private var messages: [ChatMessage] = []
    @State private var isLoading = false
    @State private var errorText: String? = nil

    struct ChatMessage: Identifiable {
        let id = UUID()
        let text: String
        let isUser: Bool
    }

    var body: some View {
        AsymmetricRoundedRect(topRadius: 0, bottomRadius: ND.Radius.large)
            .fill(SwiftUI.Color.black)
            .overlay(
                AsymmetricRoundedRect(topRadius: 0, bottomRadius: ND.Radius.large)
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
            )
            .overlay {
                VStack(spacing: 0) {
                    // Header
                    HStack(spacing: ND.Space.sm) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(ND.Color.purple)
                        Text("Ask Notchly")
                            .font(ND.Font.heading())
                            .foregroundStyle(ND.Color.primary)
                        Spacer()
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.6)
                                .tint(ND.Color.secondary)
                        }
                    }
                    .padding(.top, dimensions.notchHeight + ND.Space.md)
                    .padding(.horizontal, ND.Space.lg)
                    .padding(.bottom, ND.Space.sm)

                    // Context chip row
                    if let task = activeTask {
                        HStack(spacing: ND.Space.xs) {
                            Circle().fill(ND.Color.green).frame(width: 5, height: 5)
                            Text(task.title)
                                .font(ND.Font.label())
                                .foregroundStyle(ND.Color.green)
                                .lineLimit(1)
                            Spacer()
                        }
                        .padding(.horizontal, ND.Space.lg)
                        .padding(.bottom, ND.Space.sm)
                    }

                    // Message list
                    if messages.isEmpty {
                        VStack(alignment: .leading, spacing: ND.Space.sm) {
                            suggestionChip("What should I focus on next?")
                            suggestionChip("Give me a quick summary of my day")
                            if let e = nextEvent {
                                suggestionChip("Prep for \(e.title)")
                            }
                        }
                        .padding(.horizontal, ND.Space.lg)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        ScrollViewReader { proxy in
                            ScrollView(.vertical, showsIndicators: false) {
                                VStack(alignment: .leading, spacing: ND.Space.sm) {
                                    ForEach(messages) { msg in
                                        HStack(alignment: .top) {
                                            if msg.isUser { Spacer(minLength: 40) }
                                            Text(msg.text)
                                                .font(ND.Font.caption())
                                                .foregroundStyle(msg.isUser ? ND.Color.primary : ND.Color.secondary)
                                                .multilineTextAlignment(msg.isUser ? .trailing : .leading)
                                                .padding(.horizontal, ND.Space.md)
                                                .padding(.vertical, ND.Space.sm)
                                                .background(
                                                    RoundedRectangle(cornerRadius: ND.Radius.chip, style: .continuous)
                                                        .fill(msg.isUser ? ND.Color.surface : ND.Color.surface.opacity(0.5))
                                                )
                                                .id(msg.id)
                                            if !msg.isUser { Spacer(minLength: 40) }
                                        }
                                    }
                                }
                                .padding(.horizontal, ND.Space.lg)
                                .padding(.vertical, ND.Space.sm)
                            }
                            .frame(maxHeight: 160)
                            .onChange(of: messages.count) { _ in
                                if let last = messages.last {
                                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                                }
                            }
                        }
                    }

                    if let err = errorText {
                        Text(err)
                            .font(ND.Font.label())
                            .foregroundStyle(ND.Color.red)
                            .padding(.horizontal, ND.Space.lg)
                            .padding(.top, ND.Space.xs)
                    }

                    Spacer()

                    // Input row
                    HStack(spacing: ND.Space.sm) {
                        TextField("Ask anything…", text: $draft)
                            .textFieldStyle(.plain)
                            .font(ND.Font.body())
                            .foregroundStyle(ND.Color.primary)
                            .onSubmit { sendMessage() }

                        if !draft.isEmpty {
                            Button(action: sendMessage) {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(isLoading ? ND.Color.muted : ND.Color.purple)
                            }
                            .buttonStyle(.plain)
                            .disabled(isLoading)
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, ND.Space.md)
                    .padding(.vertical, ND.Space.sm)
                    .background(
                        RoundedRectangle(cornerRadius: ND.Radius.chip, style: .continuous)
                            .fill(ND.Color.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: ND.Radius.chip, style: .continuous)
                                    .stroke(ND.Color.stroke, lineWidth: 0.5)
                            )
                    )
                    .padding(.horizontal, ND.Space.lg)
                    .padding(.bottom, ND.Space.lg)
                }
                .animation(ND.Motion.fast, value: draft)
                .animation(ND.Motion.fast, value: messages.count)
            }
            .overlay {
                AsymmetricRoundedRect(topRadius: 0, bottomRadius: ND.Radius.large)
                    .stroke(ND.Color.stroke, lineWidth: 0.5)
            }
            .frame(width: 520, alignment: .top)
            .frame(maxHeight: 380, alignment: .top)
            .contentShape(AsymmetricRoundedRect(topRadius: 0, bottomRadius: ND.Radius.large))
    }

    // MARK: - Suggestion chip

    private func suggestionChip(_ text: String) -> some View {
        Text(text)
            .font(ND.Font.caption())
            .foregroundStyle(ND.Color.secondary)
            .padding(.horizontal, ND.Space.md)
            .padding(.vertical, ND.Space.xs)
            .background(
                Capsule().fill(ND.Color.surface)
                    .overlay(Capsule().stroke(ND.Color.stroke, lineWidth: 0.5))
            )
            .onTapGesture {
                draft = text
                sendMessage()
            }
    }

    // MARK: - Send

    private func sendMessage() {
        let text = draft.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty, !isLoading else { return }
        messages.append(ChatMessage(text: text, isUser: true))
        draft = ""
        errorText = nil
        isLoading = true

        let history = messages.dropLast().map {
            ChatService.Message(role: $0.isUser ? "user" : "assistant", content: $0.text)
        }

        ChatService.send(
            userMessage: text,
            history: Array(history),
            systemPrompt: buildSystemPrompt()
        ) { result in
            isLoading = false
            switch result {
            case .success(let reply):
                messages.append(ChatMessage(text: reply, isUser: false))
            case .failure:
                errorText = "Couldn't reach AI — check your connection."
            }
        }
    }

    // MARK: - Context

    private func buildSystemPrompt() -> String {
        var parts: [String] = [
            "You are Notchly, a concise AI assistant living in the macOS notch.",
            "Respond in 1-3 short sentences. Be direct and actionable. Never pad."
        ]

        if let task = activeTask {
            parts.append("User is currently working on: \"\(task.title)\" (\(task.timerLabel) remaining).")
        }

        if !pendingTasks.isEmpty {
            let titles = pendingTasks.prefix(3).map { "\"\($0.title)\"" }.joined(separator: ", ")
            parts.append("Upcoming tasks: \(titles).")
        }

        if let now = currentEvent {
            parts.append("Current calendar event: \(now.smartLabel).")
        }

        if let next = nextEvent {
            parts.append("Next calendar event: \(next.smartLabel).")
        }

        if let goal = memory.todays_goal {
            parts.append("Today's goal: \(goal).")
        }

        return parts.joined(separator: " ")
    }
}
