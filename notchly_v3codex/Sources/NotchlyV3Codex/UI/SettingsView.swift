import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: SettingsManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                section("Notch Size") {
                    slider("Collapsed Width", value: $settings.collapsedWidth, range: 140...260, unit: "px")
                    slider("Collapsed Height", value: $settings.collapsedHeight, range: 28...44, unit: "px")
                }

                section("Expanded") {
                    slider("Expanded Width", value: $settings.expandedWidth, range: 420...620, unit: "px")
                    slider("Expanded Height", value: $settings.expandedHeight, range: 220...420, unit: "px")
                }

                section("Widget / Stage 1") {
                    slider("Widget Width", value: $settings.widgetWidth, range: 260...420, unit: "px")
                    slider("Widget Height", value: $settings.widgetHeight, range: 34...80, unit: "px")
                }

                section("Shape") {
                    slider("Corner Radius", value: $settings.cornerRadius, range: 10...28, unit: "px")
                }

                section("Position") {
                    slider("Compact Offset X", value: $settings.compactOffsetX, range: -140...40, unit: "px")
                    slider("Expanded Offset X", value: $settings.expandedOffsetX, range: -140...40, unit: "px")
                }

                Button("Reset to Defaults") {
                    settings.resetToDefaults()
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .padding(.top, 4)
            }
            .padding(20)
        }
        .frame(minWidth: 430, minHeight: 520)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.system(size: 20, weight: .semibold))
            content()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black.opacity(0.06))
        )
    }

    private func slider(_ title: String, value: Binding<Double>, range: ClosedRange<Double>, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                Spacer()
                Text("\(Int(value.wrappedValue))\(unit)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            Slider(value: value, in: range, step: 1)
        }
    }
}
