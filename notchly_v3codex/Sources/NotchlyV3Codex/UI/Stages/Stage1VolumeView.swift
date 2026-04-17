import SwiftUI

struct Stage1VolumeView: View {
    let dimensions: NotchDimensions
    let volume: Float
    let muted:  Bool

    var body: some View {
        AsymmetricRoundedRect(topRadius: 0, bottomRadius: ND.Radius.card)
            .fill(SwiftUI.Color.black.opacity(0.96))
            .overlay {
                AsymmetricRoundedRect(topRadius: 0, bottomRadius: ND.Radius.card)
                    .fill(.ultraThinMaterial.opacity(0.12))
                    .environment(\.colorScheme, .dark)
            }
            .overlay {
                HStack(spacing: ND.Space.md) {
                    Image(systemName: iconName)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(muted ? ND.Color.red : ND.Color.primary)
                        .frame(width: 20)
                        .animation(ND.Motion.micro, value: muted)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(ND.Color.surface)
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: volumeColors,
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(0, geo.size.width * CGFloat(muted ? 0 : volume)))
                                .animation(ND.Motion.fast, value: volume)
                                .animation(ND.Motion.fast, value: muted)
                        }
                    }
                    .frame(height: 4)

                    Text(muted ? "Muted" : "\(Int(volume * 100))%")
                        .font(ND.Font.mono(11))
                        .foregroundStyle(ND.Color.tertiary)
                        .frame(width: 36, alignment: .trailing)
                        .animation(ND.Motion.micro, value: muted)
                }
                .padding(.horizontal, ND.Space.lg)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .padding(.top, dimensions.notchHeight)
                .padding(.bottom, ND.Space.sm)
            }
            .overlay {
                AsymmetricRoundedRect(topRadius: 0, bottomRadius: ND.Radius.card)
                    .stroke(ND.Color.stroke, lineWidth: 0.5)
            }
            .frame(width: 240, height: max(dimensions.notchHeight + 30, 60))
            .contentShape(AsymmetricRoundedRect(topRadius: 0, bottomRadius: ND.Radius.card))
    }

    private var iconName: String {
        if muted || volume == 0 { return "speaker.slash.fill" }
        if volume < 0.33 { return "speaker.wave.1.fill" }
        if volume < 0.66 { return "speaker.wave.2.fill" }
        return "speaker.wave.3.fill"
    }

    private var volumeColors: [SwiftUI.Color] {
        if muted { return [ND.Color.red.opacity(0.4), ND.Color.red] }
        if volume > 0.8 { return [ND.Color.green.opacity(0.6), ND.Color.orange] }
        return [ND.Color.green.opacity(0.7), ND.Color.green]
    }
}
