import SwiftUI

struct ElementDetailView: View {
    let element: ChemElement
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            VStack(spacing: 18) {
                Capsule()
                    .fill(Theme.panelHi)
                    .frame(width: 42, height: 5)
                    .padding(.top, 10)

                ElementArt(element: element)
                    .frame(height: 190)

                VStack(spacing: 6) {
                    Text(element.symbol)
                        .font(Theme.rounded(56, .heavy))
                        .foregroundStyle(Theme.textHi)
                    Text(element.name)
                        .font(Theme.rounded(28, .bold))
                        .foregroundStyle(Theme.textHi)
                    Text(element.category.rawValue.uppercased())
                        .font(Theme.rounded(12, .heavy))
                        .tracking(1.4)
                        .foregroundStyle(element.category.colour)
                }

                HStack(spacing: 10) {
                    pill("Number", "\(element.z)")
                    pill("State", element.phase.label)
                    pill("Row", "\(element.row <= 7 ? element.row : 6)")
                }

                Text(element.fact)
                    .font(Theme.rounded(17, .medium))
                    .foregroundStyle(Theme.textHi)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Theme.panel))

                Spacer()

                Button {
                    Haptics.tap()
                    Speaker.shared.say(element.name)
                } label: {
                    Label("Say it", systemImage: "speaker.wave.2.fill")
                        .font(Theme.rounded(19, .heavy))
                        .foregroundStyle(Theme.bg)
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .background(RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Theme.textHi))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 18)
        }
        .presentationDetents([.large])
        .onAppear { Speaker.shared.say(element.name) }
        .onDisappear { Speaker.shared.stop() }
    }

    private func pill(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(label.uppercased())
                .font(Theme.rounded(10, .heavy))
                .tracking(1.1)
                .foregroundStyle(Theme.textLo)
            Text(value)
                .font(Theme.rounded(17, .bold))
                .foregroundStyle(Theme.textHi)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.panel))
    }
}
