import SwiftUI

/// Shown once, on first launch.
///
/// Without it a six-year-old lands on three unexplained buttons. Deliberately
/// short: at this age nobody reads a paragraph, so it is four lines and a big
/// button. The tiles are the same four elements as the app icon, so the thing
/// he tapped on the home screen is the thing he sees first.
struct IntroView: View {
    var onStart: () -> Void

    private let tiles: [(String, Color)] = [
        ("H",  Color(hex: 0x4FD8FF)),
        ("He", Color(hex: 0xA78BFA)),
        ("Li", Color(hex: 0xFFC93C)),
        ("Be", Color(hex: 0xFF6B6B)),
    ]

    private let rounds = [
        ("textformat.abc", "See the letters, pick the name"),
        ("sparkles", "See the stuff, pick the name"),
        ("magnifyingglass", "See the name, pick the letters"),
    ]

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 26) {

                HStack(spacing: 10) {
                    ForEach(tiles, id: \.0) { symbol, colour in
                        Text(symbol)
                            .font(Theme.rounded(26, .heavy))
                            .foregroundStyle(Theme.boxLine)
                            .frame(width: 66, height: 66)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(colour)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .strokeBorder(Theme.boxLine, lineWidth: 3)
                                    )
                            )
                            .accessibilityHidden(true)
                    }
                }

                VStack(spacing: 8) {
                    Text("Everything is made of 118 things.")
                        .font(Theme.rounded(28, .heavy))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Theme.textHi)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Let's learn them.")
                        .font(Theme.rounded(19, .semibold))
                        .foregroundStyle(Theme.textLo)
                }

                VStack(alignment: .leading, spacing: 14) {
                    ForEach(rounds, id: \.1) { icon, line in
                        HStack(spacing: 14) {
                            Image(systemName: icon)
                                .font(.system(size: 19, weight: .bold))
                                .foregroundStyle(Theme.accent)
                                .frame(width: 42, height: 42)
                                .background(Circle().fill(Theme.accent.opacity(0.16)))
                            Text(line)
                                .font(Theme.rounded(17, .semibold))
                                .foregroundStyle(Theme.textHi)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 0)
                        }
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Theme.boxLine).offset(y: 5)
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Theme.panel)
                            .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .strokeBorder(Theme.boxLine, lineWidth: 3))
                    }
                )
                .padding(.bottom, 5)

                        Text("Names are read out loud, so you can hear the hard ones.")
                            .font(Theme.rounded(14, .medium))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Theme.textLo)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 20)
                    .readableColumn()
                }
                .scrollBounceBehavior(.basedOnSize)

                Button {
                    Haptics.tap()
                    onStart()
                } label: {
                    Text("Let's go")
                        .font(Theme.rounded(22, .heavy))
                        .foregroundStyle(Theme.panel)
                        .frame(maxWidth: .infinity)
                        .frame(height: 62)
                        .background(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(Theme.accent)
                                .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .strokeBorder(Theme.boxLine, lineWidth: 3))
                        )
                        .background(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(Theme.boxLine).offset(y: 5)
                        )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 13)
                .readableColumn()
            }
        }
    }
}
