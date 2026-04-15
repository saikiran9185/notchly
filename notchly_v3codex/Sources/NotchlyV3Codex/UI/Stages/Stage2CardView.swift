import SwiftUI

struct Stage2CardView: View {
    let dimensions:   NotchDimensions
    let title:        String
    let subtitle:     String
    let leftAction:   NotchAction?
    let centerAction: NotchAction?
    let rightAction:  NotchAction?
    let swipeOffset:  CGFloat
    var icon:         String = "calendar"
    var iconColor:    SwiftUI.Color = ND.Color.blue

    var body: some View {
        AsymmetricRoundedRect(topRadius: 0, bottomRadius: ND.Radius.expanded)
            .fill(SwiftUI.Color.black.opacity(0.97))
            .overlay {
                AsymmetricRoundedRect(topRadius: 0, bottomRadius: ND.Radius.expanded)
                    .fill(.ultraThinMaterial.opacity(0.12))
                    .environment(\.colorScheme, .dark)
            }
            .overlay {
                VStack(alignment: .leading, spacing: ND.Space.lg) {
                    // Header: icon + text
                    HStack(spacing: ND.Space.md) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(iconColor.opacity(0.18))
                                .frame(width: 36, height: 36)
                            Image(systemName: icon)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(iconColor)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text(title)
                                .font(ND.Font.body(14))
                                .foregroundStyle(ND.Color.primary)
                                .lineLimit(1)
                            if !subtitle.isEmpty {
                                Text(subtitle)
                                    .font(ND.Font.caption())
                                    .foregroundStyle(ND.Color.secondary)
                                    .lineLimit(1)
                            }
                        }

                        Spacer()
                    }

                    // Divider
                    Rectangle()
                        .fill(ND.Color.stroke)
                        .frame(height: 0.5)

                    // Actions
                    HStack(spacing: ND.Space.sm) {
                        if let left = leftAction {
                            NChip(label: left.title, accent: ND.Color.secondary)
                        }
                        Spacer()
                        if let center = centerAction {
                            NChip(label: center.title, accent: ND.Color.blue)
                        }
                        if let right = rightAction {
                            NChip(label: right.title, accent: ND.Color.green)
                        }
                    }

                    // Scroll hint
                    HStack(spacing: 4) {
                        Spacer()
                        Text("Scroll to expand")
                            .font(ND.Font.label())
                            .foregroundStyle(ND.Color.tertiary)
                            .tracking(0.5)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundStyle(ND.Color.tertiary)
                        Spacer()
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
