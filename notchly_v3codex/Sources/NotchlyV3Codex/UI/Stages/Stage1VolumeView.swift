import SwiftUI

struct Stage1VolumeView: View {
    let dimensions: NotchDimensions
    let volume: Float
    let muted: Bool

    var body: some View {
        AsymmetricRoundedRect(topRadius: 0, bottomRadius: 18)
            .fill(Color.black.opacity(0.98))
            .overlay {
                HStack(spacing: 10) {
                    Image(systemName: iconName)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                        .frame(width: 18)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.12))
                            Capsule()
                                .fill(Color.white.opacity(0.85))
                                .frame(width: geo.size.width * CGFloat(muted ? 0 : volume))
                                .animation(.easeOut(duration: 0.15), value: volume)
                        }
                    }
                    .frame(height: 4)
                }
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .padding(.top, dimensions.notchHeight)
                .padding(.bottom, 8)
            }
            .overlay {
                AsymmetricRoundedRect(topRadius: 0, bottomRadius: 18)
                    .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
            }
            .frame(width: 220)
            .contentShape(AsymmetricRoundedRect(topRadius: 0, bottomRadius: 18))
    }

    private var iconName: String {
        if muted || volume == 0 { return "speaker.slash.fill" }
        if volume < 0.33 { return "speaker.wave.1.fill" }
        if volume < 0.66 { return "speaker.wave.2.fill" }
        return "speaker.wave.3.fill"
    }
}
