import SwiftUI
import SwiftData

struct QuizView: View {
    let mode: QuizMode
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var stats: [ElementStat]
    @AppStorage("showPictureHint") private var showPictureHint = true

    @State private var engine: QuizEngine?
    @State private var finished = false
    @State private var shake = false

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            if let engine {
                if finished {
                    ResultView(engine: engine,
                               playAgain: { start() },
                               goHome: { dismiss() })
                        .transition(.opacity.combined(with: .scale(scale: 0.94)))
                } else {
                    round(engine)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear { if engine == nil { start() } }
        .onDisappear { Speaker.shared.stop() }
    }

    // MARK: - Round

    private func round(_ engine: QuizEngine) -> some View {
        VStack(spacing: 18) {
            header(engine)

            prompt(engine)
                .frame(maxHeight: .infinity)

            answers(engine)

            if engine.isAnswered {
                factBar(engine)
            }
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 12)
    }

    private func header(_ engine: QuizEngine) -> some View {
        HStack(spacing: 14) {
            Button {
                Haptics.tap()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(Theme.rounded(18, .heavy))
                    .foregroundStyle(Theme.textLo)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Theme.panel))
            }

            HStack(spacing: 5) {
                ForEach(0..<QuizEngine.questionsPerRound, id: \.self) { i in
                    Capsule()
                        .fill(i < engine.index ? Theme.accent
                              : (i == engine.index ? Theme.textHi : Theme.panelHi))
                        .frame(height: 8)
                }
            }

            HStack(spacing: 4) {
                Image(systemName: "star.fill").foregroundStyle(Theme.star)
                Text("\(engine.score)")
                    .font(Theme.rounded(20, .heavy))
                    .foregroundStyle(Theme.textHi)
                    .contentTransition(.numericText())
            }
            .frame(width: 56)
        }
        .padding(.top, 6)
    }

    @ViewBuilder
    private func prompt(_ engine: QuizEngine) -> some View {
        let e = engine.current.answer
        // In the picture round the sample is the question. Elsewhere it's a
        // clue underneath, and it always appears once he's answered.
        let showClue = engine.mode != .pictureToName
            && (showPictureHint || engine.isAnswered)

        VStack(spacing: 10) {
            Text(engine.mode.title)
                .font(Theme.rounded(17, .semibold))
                .foregroundStyle(Theme.textLo)

            Card(tint: Theme.panel) {
                VStack(spacing: 14) {
                    switch engine.mode {
                    case .symbolToName:
                        symbolTile(e)
                    case .nameToSymbol:
                        Text(e.name)
                            .font(Theme.rounded(38, .heavy))
                            .foregroundStyle(Theme.textHi)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                            .padding(.horizontal, 12)
                    case .pictureToName:
                        ElementArt(element: e)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }

                    if showClue {
                        VStack(spacing: 2) {
                            ElementArt(element: e)
                                .frame(width: 150, height: 110)
                            Text(e.phase.label.uppercased())
                                .font(Theme.rounded(10, .heavy))
                                .tracking(1.3)
                                .foregroundStyle(Theme.textLo)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.vertical, 18)
            }
            .offset(x: shake ? -10 : 0)
        }
    }

    private func symbolTile(_ e: ChemElement) -> some View {
        VStack(spacing: 2) {
            Text("\(e.z)")
                .font(Theme.rounded(15, .bold))
                .foregroundStyle(Theme.textLo)
            Text(e.symbol)
                .font(Theme.rounded(72, .heavy))
                .foregroundStyle(Theme.textHi)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
        }
        .frame(width: 150, height: 130)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(e.category.colour.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(e.category.colour.opacity(0.6), lineWidth: 2)
                )
        )
    }

    private func answers(_ engine: QuizEngine) -> some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)], spacing: 12) {
            ForEach(engine.current.options) { option in
                AnswerButton(
                    label: engine.mode == .nameToSymbol ? option.symbol : option.name,
                    state: state(for: option, in: engine)
                ) {
                    tap(option, engine)
                }
                .disabled(engine.isAnswered)
            }
        }
    }

    private func factBar(_ engine: QuizEngine) -> some View {
        let e = engine.current.answer
        return VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(Theme.star)
                Text(e.fact)
                    .font(Theme.rounded(15, .medium))
                    .foregroundStyle(Theme.textHi)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Theme.panelHi)
            )

            Button {
                advance(engine)
            } label: {
                Text(engine.isLastQuestion ? "See my score" : "Next")
                    .font(Theme.rounded(20, .heavy))
                    .foregroundStyle(Theme.bg)
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Theme.textHi)
                    )
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Behaviour

    private func state(for option: ChemElement, in engine: QuizEngine) -> AnswerState {
        guard let chosen = engine.chosen else { return .idle }
        if option.z == engine.current.answer.z { return .right }
        if option.z == chosen.z { return .wrong }
        return .dimmed
    }

    private func tap(_ option: ChemElement, _ engine: QuizEngine) {
        guard !engine.isAnswered else { return }
        let right = engine.answer(option)
        record(engine.current.answer, right: right)

        withAnimation(.spring(duration: 0.3)) { }
        if right {
            Haptics.right()
        } else {
            Haptics.wrong()
            withAnimation(.default.repeatCount(3).speed(6)) { shake = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { shake = false }
        }
        Speaker.shared.say(engine.current.answer.name)
    }

    private func advance(_ engine: QuizEngine) {
        Haptics.tap()
        Speaker.shared.stop()
        if engine.isLastQuestion {
            Haptics.finish()
            withAnimation(.spring) { finished = true }
        } else {
            withAnimation(.easeInOut(duration: 0.2)) { engine.next() }
        }
    }

    private func start() {
        var progress: [Int: (correct: Int, seen: Bool)] = [:]
        for s in stats { progress[s.z] = (s.correct, s.seen) }
        engine = QuizEngine(mode: mode, progress: progress)
        withAnimation { finished = false }
    }

    private func record(_ element: ChemElement, right: Bool) {
        let z = element.z
        let stat = stats.first { $0.z == z } ?? {
            let fresh = ElementStat(z: z)
            context.insert(fresh)
            return fresh
        }()
        if right { stat.correct += 1 } else { stat.wrong += 1 }
        stat.lastSeen = .now
        try? context.save()
    }
}

// MARK: - Answer button

enum AnswerState { case idle, right, wrong, dimmed }

struct AnswerButton: View {
    let label: String
    let state: AnswerState
    let action: () -> Void

    private var fill: Color {
        switch state {
        case .idle:   return Theme.panel
        case .right:  return Theme.right.opacity(0.85)
        case .wrong:  return Theme.wrong.opacity(0.85)
        case .dimmed: return Theme.panel.opacity(0.4)
        }
    }

    private var textColour: Color {
        switch state {
        case .idle:   return Theme.textHi
        case .right, .wrong: return .white
        case .dimmed: return Theme.textLo.opacity(0.6)
        }
    }

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(Theme.rounded(21, .bold))
                .foregroundStyle(textColour)
                .minimumScaleFactor(0.55)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
                .frame(maxWidth: .infinity)
                .frame(height: 76)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(fill)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .strokeBorder(Theme.line, lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
        .scaleEffect(state == .right ? 1.04 : 1)
        .animation(.spring(duration: 0.3), value: state)
    }
}
