import SwiftUI

struct Stage4ChatView: View {
    let dimensions: NotchDimensions
    @State private var draft = ""

    var body: some View {
        AsymmetricRoundedRect(topRadius: 0, bottomRadius: 32)
            .fill(Color.black)
            .overlay(
                AsymmetricRoundedRect(topRadius: 0, bottomRadius: 32)
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
            )
            .overlay {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Ask Notchly")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)

                    TextField("What should I do next?", text: $draft)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.white.opacity(0.08))
                        )

                    Text("Direct chat stage. Dashboard stays hidden here.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
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
            .frame(maxHeight: 360, alignment: .top)
            .contentShape(AsymmetricRoundedRect(topRadius: 0, bottomRadius: 32))
    }
}
