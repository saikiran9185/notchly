import SwiftUI

struct Stage1NotificationView: View {
    let dimensions: NotchDimensions
    let message: String
    let leftAction: NotchAction?
    let rightAction: NotchAction?
    let showsButtons: Bool
    let swipeOffset: CGFloat
    var alertType: String = "nudge"

    var typeIcon: String {
        switch alertType {
        case "calendar":  return "calendar"
        case "reminder":  return "bell.fill"
        case "notion":    return "doc.text.fill"
        case "ai":        return "sparkles"
        default:          return "bell.badge.fill"
        }
    }

    var typeColor: SwiftUI.Color {
        switch alertType {
        case "calendar":  return ND.Color.blue
        case "reminder":  return ND.Color.orange
        case "ai":        return ND.Color.purple
        default:          return ND.Color.secondary
        }
    }

    var body: some View {
        AsymmetricRoundedRect(topRadius: 0, bottomRadius: ND.Radius.card)
            .fill(SwiftUI.Color.black.opacity(0.98))
            .overlay {
                VStack(spacing: ND.Space.sm) {
                    // Icon + message row
                    HStack(spacing: ND.Space.sm) {
                        Image(systemName: typeIcon)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(typeColor)
                            .frame(width: 18)

                        Text(message)
                            .font(ND.Font.body())
                            .foregroundStyle(ND.Color.primary)
                            .lineLimit(1)
                    }
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
            .frame(minWidth: 240, maxWidth: 400, alignment: .top)
            .contentShape(AsymmetricRoundedRect(topRadius: 0, bottomRadius: ND.Radius.card))
    }
}
