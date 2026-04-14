import SwiftUI

struct Stage0View: View {
    let dimensions: NotchDimensions
    var hasPendingAlert: Bool = false
    var hasActiveTask: Bool = false
    var isPlaying: Bool = false

    var dotColor: SwiftUI.Color {
        if hasPendingAlert { return ND.Color.orange }
        if hasActiveTask   { return ND.Color.green }
        if isPlaying       { return ND.Color.blue }
        return ND.Color.muted
    }

    var shouldPulse: Bool {
        hasPendingAlert || hasActiveTask || isPlaying
    }

    var body: some View {
        let settings = SettingsManager.shared
        let radius = CGFloat(settings.cornerRadius)

        AsymmetricRoundedRect(topRadius: 0, bottomRadius: radius)
            .fill(SwiftUI.Color.black)
            .frame(width: settings.collapsedWidth, height: settings.collapsedHeight)
            .overlay(alignment: .bottom) {
                NStatusDot(color: dotColor, pulse: shouldPulse)
                    .padding(.bottom, 7)
                    .animation(ND.Motion.micro, value: dotColor)
            }
    }
}
