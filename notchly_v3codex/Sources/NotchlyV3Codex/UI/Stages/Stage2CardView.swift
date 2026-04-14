import SwiftUI

struct Stage2CardView: View {
    let dimensions: NotchDimensions
    let title: String
    let subtitle: String
    let leftAction: NotchAction?
    let centerAction: NotchAction?
    let rightAction: NotchAction?
    let swipeOffset: CGFloat

    var body: some View {
        AsymmetricRoundedRect(topRadius: 0, bottomRadius: 24)
            .fill(Color.black.opacity(0.98))
            .overlay {
                VStack(alignment: .leading, spacing: 12) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)

                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.68))

                    HStack(spacing: 10) {
                        if let leftAction {
                            actionChip(leftAction.title)
                        }
                        if let centerAction {
                            actionChip(centerAction.title)
                        }
                        if let rightAction {
                            actionChip(rightAction.title)
                        }
                    }
                }
                .padding(.top, dimensions.notchHeight + 12)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .offset(x: swipeOffset * 0.9)
            .frame(width: 380, alignment: .top)
            .contentShape(AsymmetricRoundedRect(topRadius: 0, bottomRadius: 24))
    }

    private func actionChip(_ label: String) -> some View {
        Text(label)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.white.opacity(0.92))
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.08))
            )
    }
}
