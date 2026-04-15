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

                        // Tappable timer label
                        Text(timerLabel)
                            .font(ND.Font.mono())
                            .foregroundStyle(ND.Color.green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(ND.Color.green.opacity(timerPressed ? 0.2 : 0.1))
                            )
                            .scaleEffect(timerPressed ? 0.94 : 1.0)
                            .animation(ND.Motion.micro, value: timerPressed)
                            .onTapGesture {
                                withAnimation(ND.Motion.micro) { timerPressed = true }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                                    withAnimation(ND.Motion.micro) { timerPressed = false }
                                }
                                onTimerTap()
                            }
                    }
                    .padding(.horizontal, ND.Space.lg)

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
            .offset(x: swipeOffset * 0.9)
            .frame(minWidth: 280, maxWidth: 360, alignment: .top)
            .contentShape(AsymmetricRoundedRect(topRadius: 0, bottomRadius: ND.Radius.card))
    }
}
