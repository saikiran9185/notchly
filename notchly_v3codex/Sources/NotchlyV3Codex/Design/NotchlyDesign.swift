import SwiftUI

// MARK: - Notchly Design System
// Tokens aligned with macOS Human Interface Guidelines + Dynamic Island language

enum ND {

    // MARK: Colors
    enum Color {
        static let surface     = SwiftUI.Color.white.opacity(0.06)
        static let surfaceHi   = SwiftUI.Color.white.opacity(0.10)
        static let stroke      = SwiftUI.Color.white.opacity(0.08)
        static let strokeHi    = SwiftUI.Color.white.opacity(0.14)
        static let primary     = SwiftUI.Color.white.opacity(0.94)
        static let secondary   = SwiftUI.Color.white.opacity(0.55)
        static let tertiary    = SwiftUI.Color.white.opacity(0.35)
        static let muted       = SwiftUI.Color.white.opacity(0.20)

        // Semantic accents (Apple system palette)
        static let green   = SwiftUI.Color(red: 0.188, green: 0.820, blue: 0.345) // #30D158
        static let orange  = SwiftUI.Color(red: 1.0,   green: 0.624, blue: 0.039) // #FF9F0A
        static let red     = SwiftUI.Color(red: 1.0,   green: 0.271, blue: 0.227) // #FF453A
        static let blue    = SwiftUI.Color(red: 0.039, green: 0.518, blue: 1.0)   // #0A84FF
        static let purple  = SwiftUI.Color(red: 0.749, green: 0.353, blue: 1.0)   // #BF5AFF
    }

    // MARK: Typography
    enum Font {
        static func heading(_ size: CGFloat = 15) -> SwiftUI.Font {
            .system(size: size, weight: .semibold, design: .default)
        }
        static func body(_ size: CGFloat = 13) -> SwiftUI.Font {
            .system(size: size, weight: .medium, design: .default)
        }
        static func caption(_ size: CGFloat = 11) -> SwiftUI.Font {
            .system(size: size, weight: .medium, design: .default)
        }
        static func label(_ size: CGFloat = 10) -> SwiftUI.Font {
            .system(size: size, weight: .bold, design: .default)
        }
        static func mono(_ size: CGFloat = 12) -> SwiftUI.Font {
            .system(size: size, weight: .medium, design: .monospaced)
        }
    }

    // MARK: Spacing
    enum Space {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
    }

    // MARK: Animation
    enum Motion {
        static let micro  = Animation.easeOut(duration: 0.15)
        static let fast   = Animation.easeOut(duration: 0.22)
        static let spring = Animation.spring(response: 0.35, dampingFraction: 0.78)
        static let expand = Animation.spring(response: 0.42, dampingFraction: 0.80)
    }

    // MARK: Shapes
    enum Radius {
        static let chip:     CGFloat = 8
        static let card:     CGFloat = 18
        static let expanded: CGFloat = 26
        static let large:    CGFloat = 32
    }
}

// MARK: - Reusable Components

struct NLabel: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(ND.Font.label())
            .foregroundStyle(ND.Color.tertiary)
            .tracking(0.5)
    }
}

struct NChip: View {
    let label: String
    var accent: SwiftUI.Color = ND.Color.primary
    var action: (() -> Void)? = nil

    var body: some View {
        Text(label)
            .font(ND.Font.caption())
            .foregroundStyle(accent.opacity(0.9))
            .padding(.vertical, ND.Space.sm)
            .padding(.horizontal, ND.Space.md)
            .background(Capsule().fill(accent.opacity(0.12)))
            .contentShape(Capsule())
            .onTapGesture { action?() }
    }
}

struct NEventRow: View {
    let label: String
    let value: String
    var accent: SwiftUI.Color = ND.Color.secondary

    var body: some View {
        VStack(alignment: .leading, spacing: ND.Space.xs) {
            NLabel(text: label)
            Text(value)
                .font(ND.Font.body())
                .foregroundStyle(ND.Color.primary)
                .lineLimit(1)
        }
    }
}

struct NStatusDot: View {
    var color: SwiftUI.Color = ND.Color.muted
    var pulse: Bool = false
    @State private var animating = false

    var body: some View {
        ZStack {
            if pulse {
                Circle()
                    .fill(color.opacity(0.3))
                    .frame(width: 10, height: 10)
                    .scaleEffect(animating ? 1.8 : 1.0)
                    .opacity(animating ? 0 : 1)
                    .animation(
                        .easeOut(duration: 1.2).repeatForever(autoreverses: false),
                        value: animating
                    )
            }
            Circle()
                .fill(color)
                .frame(width: 5, height: 5)
        }
        .onAppear { if pulse { animating = true } }
    }
}
