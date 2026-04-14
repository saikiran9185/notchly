import SwiftUI

struct Stage0View: View {
    let dimensions: NotchDimensions

    var body: some View {
        let settings = SettingsManager.shared
        let radius = CGFloat(settings.cornerRadius)

        AsymmetricRoundedRect(topRadius: 0, bottomRadius: radius)
            .fill(Color.black)
            .frame(width: settings.collapsedWidth, height: settings.collapsedHeight)
            .overlay(alignment: .bottom) {
                Circle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 5, height: 5)
                    .padding(.bottom, 7)
            }
    }
}
