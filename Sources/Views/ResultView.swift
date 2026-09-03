import SwiftUI

struct ResultView: View {
    let engine: QuizEngine
    let playAgain: () -> Void
    let goHome: () -> Void

    @State private var pop = false

    private var message: String {
        switch engine.score {
        case 10: return "Perfect! Every single one."
        case 8...9: return "Brilliant work."
        case 6...7: return "Good going. Nearly there."
        case 3...5: return "Getting better every time."
        default: return "Have another go. You'll get them."
        }
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            HStack(spacing: 10) {
                ForEach(0..<3, id: \.self) { i in
                    Image(systemName: i < engine.stars ? "star.fill" : "star")
                        .font(.system(size: 46))
                        .foregroundStyle(i < engine.stars ? Theme.star : Theme.panelHi)
                        .scaleEffect(pop ? 1 : 0.4)
                        .animation(.spring(duration: 0.5).delay(Double(i) * 0.14), value: pop)
                }
            }

            VStack(spacing: 6) {
                Text("\(engine.score) out of \(QuizEngine.questionsPerRound)")
                    .font(Theme.rounded(34, .heavy))
                    .foregroundStyle(Theme.textHi)
                Text(message)
                    .font(Theme.rounded(17, .medium))
                    .foregroundStyle(Theme.textLo)
            }

            if !engine.wrongThisRound.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Ones to remember")
                        .font(Theme.rounded(13, .heavy))
                        .tracking(1.2)
                        .foregroundStyle(Theme.textLo)
                    ForEach(engine.wrongThisRound) { e in
                        HStack(spacing: 12) {
                            ElementArt(element: e, animated: false)
                                .frame(width: 44, height: 44)
                            Text(e.symbol)
                                .font(Theme.rounded(20, .heavy))
                                .foregroundStyle(Theme.textHi)
                                .frame(width: 44, alignment: .leading)
                            Text(e.name)
                                .font(Theme.rounded(18, .semibold))
                                .foregroundStyle(Theme.textHi)
                            Spacer()
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Theme.panel)
                )
            }

            Spacer()

            VStack(spacing: 12) {
                Button {
                    Haptics.tap()
                    playAgain()
                } label: {
                    Text("Play again")
                        .font(Theme.rounded(21, .heavy))
                        .foregroundStyle(Theme.bg)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Theme.textHi))
                }
                Button {
                    Haptics.tap()
                    goHome()
                } label: {
                    Text("Home")
                        .font(Theme.rounded(19, .bold))
                        .foregroundStyle(Theme.textLo)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
        .onAppear { pop = true }
    }
}
