import SwiftUI

struct Stage4ChatView: View {
    let dimensions: NotchDimensions
    @State private var draft = ""
    @State private var messages: [ChatMessage] = []
    @State private var isLoading = false

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

                    // Message list
                    if !messages.isEmpty {
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(alignment: .leading, spacing: ND.Space.sm) {
                                ForEach(messages) { msg in
                                    HStack {
                                        if msg.isUser { Spacer(minLength: 40) }
                                        Text(msg.text)
                                            .font(ND.Font.caption())
                                            .foregroundStyle(msg.isUser ? ND.Color.primary : ND.Color.secondary)
                                            .padding(.horizontal, ND.Space.md)
                                            .padding(.vertical, ND.Space.sm)
                                            .background(
                                                RoundedRectangle(cornerRadius: ND.Radius.chip, style: .continuous)
                                                    .fill(msg.isUser ? ND.Color.surface : ND.Color.surface.opacity(0.5))
                                            )
                                        if !msg.isUser { Spacer(minLength: 40) }
                                    }
                                }
                            }
                            .padding(.horizontal, ND.Space.lg)
                            .padding(.vertical, ND.Space.sm)
                        }
                        .frame(maxHeight: 140)
                    } else {
                        Text("What should I focus on next?")
                            .font(ND.Font.caption())
                            .foregroundStyle(ND.Color.tertiary)
                            .padding(.horizontal, ND.Space.lg)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Spacer()

                    // Input row
                    HStack(spacing: ND.Space.sm) {
                        TextField("Type anything…", text: $draft)
                            .textFieldStyle(.plain)
                            .font(ND.Font.body())
                            .foregroundStyle(ND.Color.primary)
                            .onSubmit { sendMessage() }

                        if !draft.isEmpty {
                            Button(action: sendMessage) {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(ND.Color.green)
                            }
                            .buttonStyle(.plain)
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
            }
            .overlay {
                AsymmetricRoundedRect(topRadius: 0, bottomRadius: ND.Radius.large)
                    .stroke(ND.Color.stroke, lineWidth: 0.5)
            }
            .frame(width: 520, alignment: .top)
            .frame(maxHeight: 380, alignment: .top)
            .contentShape(AsymmetricRoundedRect(topRadius: 0, bottomRadius: ND.Radius.large))
    }

    private func sendMessage() {
        guard !draft.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let userMsg = draft
        messages.append(ChatMessage(text: userMsg, isUser: true))
        draft = ""
        // Stub response — wire to Openclaw / Claude API later
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            isLoading = false
            messages.append(ChatMessage(text: "Got it. I'll help you focus on that.", isUser: false))
        }
    }
}
