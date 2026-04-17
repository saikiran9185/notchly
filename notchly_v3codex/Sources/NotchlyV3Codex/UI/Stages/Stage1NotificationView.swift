import SwiftUI

struct Stage1NotificationView: View {
    let dimensions: NotchDimensions
    let message:     String
    let leftAction:  NotchAction?
    let rightAction: NotchAction?
    let showsButtons: Bool
    let swipeOffset:  CGFloat
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
        case "calendar": return ND.Color.blue
        case "reminder": return ND.Color.orange
        case "ai":       return ND.Color.purple
        default:         return ND.Color.secondary
        }
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
                VStack(spacing: 0) {
                    // Icon + message
                    HStack(spacing: ND.Space.sm) {
                        ZStack {
                            Circle()
                                .fill(typeColor.opacity(0.15))
                                .frame(width: 26, height: 26)
                            Image(systemName: typeIcon)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(typeColor)
                        }

                        Text(message)
                            .font(ND.Font.body())
                            .foregroundStyle(ND.Color.primary)
                            .lineLimit(1)

                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, ND.Space.lg)
                    .padding(.top, dimensions.notchHeight + ND.Space.md)

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
                        .padding(.top, ND.Space.sm)
                        .padding(.bottom, ND.Space.md)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else {
                        Spacer().frame(height: ND.Space.md)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .animation(ND.Motion.fast, value: showsButtons)
            }
            .overlay {
                AsymmetricRoundedRect(topRadius: 0, bottomRadius: ND.Radius.card)
                    .stroke(ND.Color.stroke, lineWidth: 0.5)
            }
            .overlay {
                // Swipe color wash — green right, warm gray left (never red)
                AsymmetricRoundedRect(topRadius: 0, bottomRadius: ND.Radius.card)
                    .fill(swipeWashColor)
                    .allowsHitTesting(false)
            }
            .offset(x: swipeOffset * 0.9)
            .frame(minWidth: 260, maxWidth: 420, alignment: .top)
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
}
