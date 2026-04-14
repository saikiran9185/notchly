import SwiftUI

struct Stage3DashboardView: View {
    let dimensions: NotchDimensions
    let currentEvent: CalEvent?
    let nextEvent: CalEvent?
    let missedCount: Int
    let nowPlaying: NowPlayingInfo?
    let bluetoothDevice: BTDeviceInfo?

    var body: some View {
        AsymmetricRoundedRect(topRadius: 0, bottomRadius: 32)
            .fill(Color.black)
            .overlay(
                AsymmetricRoundedRect(topRadius: 0, bottomRadius: 32)
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
            )
            .overlay {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("Today")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                        Spacer()
                        if let device = bluetoothDevice {
                            batteryChip(device)
                        }
                    }

                    dashboardRow(
                        title: "Current",
                        value: currentEvent?.smartLabel ?? "Free"
                    )
                    dashboardRow(
                        title: "Next",
                        value: nextEvent?.smartLabel ?? "Nothing scheduled"
                    )
                    if missedCount > 0 {
                        dashboardRow(
                            title: "Missed",
                            value: "\(missedCount) event\(missedCount > 1 ? "s" : "") passed"
                        )
                    }
                    if let np = nowPlaying {
                        Divider().overlay(Color.white.opacity(0.08))
                        dashboardRow(title: "Playing", value: np.displayLine)
                    }
                }
                .padding(.top, dimensions.notchHeight + 12)
                .padding(.horizontal, 16)
                .padding(.bottom, 18)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .overlay {
                AsymmetricRoundedRect(topRadius: 0, bottomRadius: 32)
                    .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
            }
            .frame(width: 520, alignment: .top)
            .frame(maxHeight: 400, alignment: .top)
            .contentShape(AsymmetricRoundedRect(topRadius: 0, bottomRadius: 32))
    }

    private func dashboardRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white.opacity(0.4))
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))
                .lineLimit(1)
        }
    }

    private func batteryChip(_ device: BTDeviceInfo) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "airpodspro")
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.5))
            if let pct = device.batteryPercent {
                Text("\(pct)%")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
            } else {
                Text(device.name.components(separatedBy: " ").first ?? device.name)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule().fill(Color.white.opacity(0.08))
        )
    }
}
