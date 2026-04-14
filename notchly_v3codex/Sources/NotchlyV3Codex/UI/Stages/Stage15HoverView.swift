import SwiftUI

struct Stage15HoverView: View {
    let dimensions: NotchDimensions
    let message: String
    let nowPlaying: NowPlayingInfo?
    let bluetoothDevice: BTDeviceInfo?

    var body: some View {
        AsymmetricRoundedRect(topRadius: 0, bottomRadius: 18)
            .fill(Color.black.opacity(0.98))
            .overlay {
                VStack(spacing: 4) {
                    if let np = nowPlaying {
                        HStack(spacing: 6) {
                            Image(systemName: "music.note")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(Color.green.opacity(0.8))
                            Text(np.displayLine)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.white.opacity(0.9))
                                .lineLimit(1)
                        }
                    } else {
                        Text("Now")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.45))
                        Text(message)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.94))
                            .lineLimit(1)
                    }

                    if let device = bluetoothDevice, let pct = device.batteryPercent {
                        HStack(spacing: 4) {
                            Image(systemName: batteryIcon(pct))
                                .font(.system(size: 10))
                                .foregroundStyle(batteryColor(pct))
                            Text("\(device.name.components(separatedBy: " ").first ?? "") \(pct)%")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, dimensions.notchHeight)
                .padding(.bottom, 8)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
            .frame(width: 340, height: nowPlaying != nil || bluetoothDevice?.batteryPercent != nil ? 80 : 70, alignment: .top)
            .contentShape(AsymmetricRoundedRect(topRadius: 0, bottomRadius: 18))
    }

    private func batteryIcon(_ pct: Int) -> String {
        switch pct {
        case 0..<15: return "battery.0percent"
        case 15..<40: return "battery.25percent"
        case 40..<65: return "battery.50percent"
        case 65..<90: return "battery.75percent"
        default: return "battery.100percent"
        }
    }

    private func batteryColor(_ pct: Int) -> Color {
        pct < 20 ? .red : pct < 40 ? .orange : .green.opacity(0.8)
    }
}
