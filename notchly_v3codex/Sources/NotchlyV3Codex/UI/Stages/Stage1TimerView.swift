import SwiftUI

struct Stage1TimerView: View {
    let dimensions: NotchDimensions
    let title: String
    let timerLabel: String
    let leftAction: NotchAction?
    let rightAction: NotchAction?
    let showsButtons: Bool
    let swipeOffset: CGFloat
    let onTimerTap: () -> Void

    var body: some View {
        AsymmetricRoundedRect(topRadius: 0, bottomRadius: 18)
            .fill(Color.black.opacity(0.98))
            .overlay {
                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        Text(title)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)

                        Spacer(minLength: 8)

                        Text(timerLabel)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundStyle(Color.green.opacity(0.95))
                            .onTapGesture(perform: onTimerTap)
                    }
                    .padding(.horizontal, 16)

                    if showsButtons {
                        HStack(spacing: 10) {
                            if let leftAction {
                                actionChip(leftAction.title, emphasis: .neutral)
                            }
                            if let rightAction {
                                actionChip(rightAction.title, emphasis: .positive)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.bottom, 10)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else {
                        Spacer()
                            .frame(height: 10)
                    }
                }
                .padding(.top, dimensions.notchHeight + 12)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .overlay {
                AsymmetricRoundedRect(topRadius: 0, bottomRadius: 18)
                    .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
            }
            .offset(x: swipeOffset * 0.9)
            .frame(minWidth: 280, maxWidth: 360, alignment: .top)
            .contentShape(AsymmetricRoundedRect(topRadius: 0, bottomRadius: 18))
    }

    private func actionChip(_ label: String, emphasis: Emphasis) -> some View {
        Text(label)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(emphasis == .positive ? Color.green.opacity(0.95) : .white.opacity(0.9))
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.08))
            )
    }

    private enum Emphasis {
        case neutral
        case positive
    }
}
