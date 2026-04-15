import SwiftUI

struct Stage15HoverView: View {
    let dimensions:     NotchDimensions
    let message:        String
    let nowPlaying:     NowPlayingInfo?
    let bluetoothDevice: BTDeviceInfo?
    let activeTask:     ScheduleTask?

    var body: some View {
        AsymmetricRoundedRect(topRadius: 0, bottomRadius: ND.Radius.card)
            .fill(SwiftUI.Color.black.opacity(0.96))
            .overlay {
                AsymmetricRoundedRect(topRadius: 0, bottomRadius: ND.Radius.card)
                    .fill(.ultraThinMaterial.opacity(0.12))
                    .environment(\.colorScheme, .dark)
            }
            .overlay {
                HStack(spacing: ND.Space.sm) {
                    // Left: context
                    Group {
                        if let np = nowPlaying {
                            HStack(spacing: 6) {
                                // Music icon with subtle pulse
                                Image(systemName: "music.note")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(ND.Color.green)
                                Text(np.displayLine)
                                    .font(ND.Font.caption())
                                    .foregroundStyle(ND.Color.primary)
                                    .lineLimit(1)
                            }
                        } else if let task = activeTask {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(ND.Color.green)
                                    .frame(width: 5, height: 5)
                                Text(task.title)
                                    .font(ND.Font.caption())
                                    .foregroundStyle(ND.Color.primary)
                                    .lineLimit(1)
                            }
                        } else {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("NOW")
                                    .font(ND.Font.label())
                                    .foregroundStyle(ND.Color.tertiary)
                                    .tracking(0.8)
                                Text(message)
                                    .font(ND.Font.caption())
                                    .foregroundStyle(ND.Color.primary)
                                    .lineLimit(1)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Right: BT battery
                    if let device = bluetoothDevice {
                        HStack(spacing: 4) {
                            if let pct = device.batteryPercent {
                                Image(systemName: batteryIcon(pct))
                                    .font(.system(size: 10))
                                    .foregroundStyle(batteryColor(pct))
                                Text("\(pct)%")
                                    .font(ND.Font.caption())
                                    .foregroundStyle(ND.Color.secondary)
                            } else {
                                Image(systemName: "airpodspro")
                                    .font(.system(size: 10))
                                    .foregroundStyle(ND.Color.tertiary)
                            }
                        }
                        .padding(.horizontal, ND.Space.sm)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(ND.Color.surface))
                    }

                    // Scroll hint arrow
                    Image(systemName: "chevron.down")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(ND.Color.tertiary)
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
            .frame(width: 340, height: 70, alignment: .top)
            .contentShape(AsymmetricRoundedRect(topRadius: 0, bottomRadius: ND.Radius.card))
    }

    private func batteryIcon(_ pct: Int) -> String {
        switch pct {
        case 0..<15: return "battery.0percent"
        case 15..<40: return "battery.25percent"
        case 40..<65: return "battery.50percent"
        case 65..<90: return "battery.75percent"
        default:      return "battery.100percent"
        }
    }

    private func batteryColor(_ pct: Int) -> SwiftUI.Color {
        pct < 20 ? ND.Color.red : pct < 40 ? ND.Color.orange : ND.Color.green
    }
}
