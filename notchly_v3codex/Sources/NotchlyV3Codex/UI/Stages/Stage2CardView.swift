import SwiftUI

struct Stage2CardView: View {
    let dimensions: NotchDimensions
    let title: String
    let subtitle: String
    let leftAction: NotchAction?
    let centerAction: NotchAction?
    let rightAction: NotchAction?
    let swipeOffset: CGFloat
    var icon: String = "calendar"
    var iconColor: SwiftUI.Color = ND.Color.blue

    var body: some View {
        AsymmetricRoundedRect(topRadius: 0, bottomRadius: ND.Radius.expanded)
            .fill(SwiftUI.Color.black.opacity(0.98))
            .overlay {
                VStack(alignment: .leading, spacing: ND.Space.md) {
                    // Header
                    HStack(spacing: ND.Space.sm) {
                        Image(systemName: icon)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(iconColor)
                            .frame(width: 22, height: 22)
                            .background(Circle().fill(iconColor.opacity(0.12)))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(title)
                                .font(ND.Font.body(14))
                                .foregroundStyle(ND.Color.primary)
                                .lineLimit(1)
                            Text(subtitle)
                                .font(ND.Font.caption())
                                .foregroundStyle(ND.Color.secondary)
                                .lineLimit(1)
                        }
                    }

                    // Actions
                    HStack(spacing: ND.Space.sm) {
                        if let left = leftAction {
                            NChip(label: left.title, accent: ND.Color.secondary)
                        }
                        if let center = centerAction {
                            NChip(label: center.title, accent: ND.Color.blue)
                        }
                        if let right = rightAction {
                            NChip(label: right.title, accent: ND.Color.green)
                        }
                    }
                }
                .padding(.top, dimensions.notchHeight + ND.Space.md)
                .padding(.horizontal, ND.Space.lg)
                .padding(.bottom, ND.Space.lg)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .overlay {
                AsymmetricRoundedRect(topRadius: 0, bottomRadius: ND.Radius.expanded)
                    .stroke(ND.Color.stroke, lineWidth: 0.5)
            }
            .offset(x: swipeOffset * 0.9)
            .frame(width: 380, alignment: .top)
            .contentShape(AsymmetricRoundedRect(topRadius: 0, bottomRadius: ND.Radius.expanded))
    }
}
