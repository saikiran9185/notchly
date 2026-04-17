import SwiftUI

struct Stage1TimerView: View {
    let dimensions: NotchDimensions
    let title:       String
    let timerLabel:  String
    let progress:    CGFloat        // 0.0 – 1.0
    let leftAction:  NotchAction?
    let rightAction: NotchAction?
    let showsButtons: Bool
    let swipeOffset:  CGFloat
    let onTimerTap:  () -> Void

    @State private var timerPressed = false
    @State private var cycleIndex = 0
    @State private var cycleTimer: Timer?

    // Derived cycle labels from timerLabel (format: "24m left")
    private var cycleTitles: [String] {
        let base = timerLabel
        // Parse minutes from "24m left" or "1h 12m left"
        let elapsed = elapsedLabel(from: base)
        let pct = percentLabel(from: progress)
        return [base, elapsed, pct]
    }

    private var displayLabel: String {
        guard !showsButtons else { return timerLabel }
        return cycleTitles[cycleIndex % cycleTitles.count]
    }

    var body: some View {
        AsymmetricRoundedRect(topRadius: 0, bottomRadius: ND.Radius.card)
            .fill(SwiftUI.Color.black.opacity(0.96))
            .overlay {
                AsymmetricRoundedRect(topRadius: 0, bottomRadius: ND.Radius.card)
                    .fill(.ultraThinMaterial.opacity(0.15))
                    .environment(\.colorScheme, .dark)
            }
            .overlay {
                VStack(spacing: ND.Space.sm) {
                    // Title + timer
                    HStack(spacing: ND.Space.md) {
                        // Green active dot
                        Circle()
                            .fill(ND.Color.green)
                            .frame(width: 6, height: 6)

                        Text(title)
                            .font(ND.Font.body())
                            .foregroundStyle(ND.Color.primary)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        // Tappable timer label (cycles countdown→elapsed→percent)
                        Text(displayLabel)
                            .font(ND.Font.mono())
                            .foregroundStyle(ND.Color.green)
                            .contentTransition(.numericText())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(ND.Color.green.opacity(timerPressed ? 0.2 : 0.1))
                            )
                            .scaleEffect(timerPressed ? 0.94 : 1.0)
                            .animation(ND.Motion.micro, value: timerPressed)
                            .animation(ND.Motion.fast, value: cycleIndex)
                            .onTapGesture {
                                withAnimation(ND.Motion.micro) { timerPressed = true }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                                    withAnimation(ND.Motion.micro) { timerPressed = false }
                                }
                                onTimerTap()
                            }
                    }
                    .padding(.horizontal, ND.Space.lg)
                    .onAppear { startCycle() }
                    .onDisappear { stopCycle() }
                    .onChange(of: showsButtons) { _, hovering in
                        hovering ? stopCycle() : startCycle()
                    }

                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(ND.Color.surface)
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [ND.Color.green.opacity(0.6), ND.Color.green],
                                        startPoint: .leading, endPoint: .trailing
                                    )
                                )
                                .frame(width: max(6, geo.size.width * progress))
                                .animation(ND.Motion.fast, value: progress)
                        }
                    }
                    .frame(height: 3)
                    .padding(.horizontal, ND.Space.lg)

                    // Action buttons
                    if showsButtons {
                        HStack(spacing: ND.Space.sm) {
                            if let left = leftAction {
                                NChip(label: left.title, accent: ND.Color.secondary)
                            }
                            if let right = rightAction {
                                NChip(label: right.title, accent: ND.Color.green)
                            }
                        }
                        .padding(.horizontal, ND.Space.md)
                        .padding(.bottom, ND.Space.md)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else {
                        Spacer().frame(height: ND.Space.md)
                    }
                }
                .padding(.top, dimensions.notchHeight + ND.Space.md)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .animation(ND.Motion.fast, value: showsButtons)
            }
            .overlay {
                AsymmetricRoundedRect(topRadius: 0, bottomRadius: ND.Radius.card)
                    .stroke(ND.Color.stroke, lineWidth: 0.5)
            }
            .overlay {
                // Swipe color wash — green for right, warm gray for left
                AsymmetricRoundedRect(topRadius: 0, bottomRadius: ND.Radius.card)
                    .fill(swipeWashColor)
                    .allowsHitTesting(false)
            }
            .offset(x: swipeOffset * 0.9)
            .frame(minWidth: 280, maxWidth: 360, alignment: .top)
            .contentShape(AsymmetricRoundedRect(topRadius: 0, bottomRadius: ND.Radius.card))
    }

    private var swipeWashColor: SwiftUI.Color {
        let ratio = min(abs(swipeOffset) / 40.0, 1.0)
        if swipeOffset > 0 {
            return SwiftUI.Color(red: 0.11, green: 0.62, blue: 0.46).opacity(ratio * 0.55)
        } else {
            return SwiftUI.Color(red: 0.31, green: 0.31, blue: 0.31).opacity(ratio * 0.40)
        }
    }

    // MARK: — Cycle logic

    private func startCycle() {
        stopCycle()
        cycleTimer = Timer.scheduledTimer(withTimeInterval: 4, repeats: true) { _ in
            withAnimation(ND.Motion.fast) { cycleIndex += 1 }
        }
    }

    private func stopCycle() {
        cycleTimer?.invalidate()
        cycleTimer = nil
    }

    private func elapsedLabel(from label: String) -> String {
        let mins = parseMinutes(from: label)
        guard mins > 0, progress > 0 else { return label }
        let elapsed = Int(Double(mins) * Double(progress))
        if elapsed >= 60 { return "\(elapsed / 60)h \(elapsed % 60)m in" }
        return "\(elapsed)m in"
    }

    private func percentLabel(from p: CGFloat) -> String {
        "\(Int(p * 100))% done"
    }

    private func parseMinutes(from label: String) -> Int {
        var total = 0
        for comp in label.components(separatedBy: " ") {
            if comp.hasSuffix("h"), let h = Int(comp.dropLast()) { total += h * 60 }
            if comp.hasSuffix("m"), let m = Int(comp.dropLast()) { total += m }
        }
        return total
    }
}
