import SwiftUI

struct Stage1TimerView: View {
    let dimensions: NotchDimensions
    let title: String
    let timerLabel: String
    let progress: CGFloat      // 0.0 – 1.0
    let leftAction: NotchAction?
    let rightAction: NotchAction?
    let showsButtons: Bool
    let swipeOffset: CGFloat
    let onTimerTap: () -> Void

    var body: some View {
        AsymmetricRoundedRect(topRadius: 0, bottomRadius: ND.Radius.card)
            .fill(SwiftUI.Color.black.opacity(0.98))
            .overlay {
                VStack(spacing: ND.Space.sm) {
                    // Title + timer label
                    HStack(spacing: ND.Space.md) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(title)
                                .font(ND.Font.body())
                                .foregroundStyle(ND.Color.primary)
                                .lineLimit(1)
                        }

                        Spacer(minLength: ND.Space.sm)

                        Text(timerLabel)
                            .font(ND.Font.mono())
                            .foregroundStyle(ND.Color.green)
                            .onTapGesture(perform: onTimerTap)
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
                                        colors: [ND.Color.green.opacity(0.7), ND.Color.green],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(4, geo.size.width * progress))
                                .animation(ND.Motion.fast, value: progress)
                        }
                    }
                    .frame(height: 3)
                    .padding(.horizontal, ND.Space.lg)

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
