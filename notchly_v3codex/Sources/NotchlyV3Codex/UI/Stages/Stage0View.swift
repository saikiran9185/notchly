import SwiftUI

struct Stage0View: View {
    let dimensions: NotchDimensions
    var hasPendingAlert: Bool = false
    var hasActiveTask:   Bool = false
    var isPlaying:       Bool = false

    @State private var dotScale: CGFloat = 1.0

    var dotColor: SwiftUI.Color {
        if hasPendingAlert { return ND.Color.orange }
        if hasActiveTask   { return ND.Color.green  }
        if isPlaying       { return ND.Color.blue   }
        return ND.Color.muted
    }

    var shouldPulse: Bool { hasPendingAlert || hasActiveTask || isPlaying }

    var body: some View {
        let settings = SettingsManager.shared
        let radius   = CGFloat(settings.cornerRadius)

        AsymmetricRoundedRect(topRadius: 0, bottomRadius: radius)
            .fill(SwiftUI.Color.black)
            .frame(width: settings.collapsedWidth, height: settings.collapsedHeight)
            .overlay(alignment: .bottom) {
                // Status dot with smooth pulse
                Circle()
                    .fill(dotColor)
                    .frame(width: 4, height: 4)
                    .scaleEffect(dotScale)
                    .opacity(shouldPulse ? 1 : 0.35)
                    .padding(.bottom, 7)
                    .animation(ND.Motion.micro, value: dotColor)
                    .animation(ND.Motion.micro, value: shouldPulse)
                    .onAppear { animateDot() }
                    .onChange(of: shouldPulse) { _ in animateDot() }
            }
    }

    private func animateDot() {
        guard shouldPulse else { dotScale = 1.0; return }
        withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
            dotScale = 1.6
        }
    }
}
