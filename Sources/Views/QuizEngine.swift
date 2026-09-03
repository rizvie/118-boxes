import Foundation
import Observation

enum QuizMode: String, CaseIterable, Identifiable {
    case symbolToName   // "Cu" -> Copper
    case pictureToName  // sample art -> Copper
    case nameToSymbol   // Copper -> "Cu"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .symbolToName:  return "What's this symbol?"
        case .pictureToName: return "What is this stuff?"
        case .nameToSymbol:  return "Find the symbol"
        }
    }

    var blurb: String {
        switch self {
        case .symbolToName:  return "See the letters, pick the name"
        case .pictureToName: return "See the sample, pick the name"
        case .nameToSymbol:  return "See the name, pick the letters"
        }
    }

    var icon: String {
        switch self {
        case .symbolToName:  return "textformat.abc"
        case .pictureToName: return "sparkles"
        case .nameToSymbol:  return "magnifyingglass"
        }
    }
}

struct Question: Identifiable {
    let id = UUID()
    let answer: ChemElement
    let options: [ChemElement]
}

@Observable
final class QuizEngine {
    static let questionsPerRound = 10

    let mode: QuizMode
    private(set) var questions: [Question] = []
    var index = 0
    var chosen: ChemElement?
    private(set) var score = 0
    private(set) var wrongThisRound: [ChemElement] = []

    init(mode: QuizMode, progress: [Int: (correct: Int, seen: Bool)]) {
        self.mode = mode
        self.questions = Self.buildRound(mode: mode, progress: progress)
    }

    var current: Question { questions[min(index, questions.count - 1)] }
    var isAnswered: Bool { chosen != nil }
    var isLastQuestion: Bool { index >= questions.count - 1 }

    var stars: Int {
        switch score {
        case 9...: return 3
        case 7...8: return 2
        case 5...6: return 1
        default: return 0
        }
    }

    /// Returns true when the tap was right.
    @discardableResult
    func answer(_ element: ChemElement) -> Bool {
        guard chosen == nil else { return false }
        chosen = element
        let right = element.z == current.answer.z
        if right {
            score += 1
        } else {
            wrongThisRound.append(current.answer)
        }
        return right
    }

    func next() {
        chosen = nil
        index += 1
    }

    // MARK: - Round building

    /// Picks ten elements. Everything on the table can come up, but anything he
    /// hasn't met yet, or hasn't nailed yet, comes up more often, and the first
    /// few rows get a nudge because that's where the familiar ones live.
    private static func buildRound(mode: QuizMode,
                                   progress: [Int: (correct: Int, seen: Bool)]) -> [Question] {
        var pool = Elements.all
        var picked: [ChemElement] = []

        func weight(_ e: ChemElement) -> Double {
            let p = progress[e.z]
            var w: Double
            if p == nil || p?.seen == false {
                w = 1.5
            } else if (p?.correct ?? 0) >= 3 {
                w = 0.25
            } else {
                w = 1.0
            }
            if e.z <= 36 { w *= 1.6 }
            return w
        }

        while picked.count < questionsPerRound, !pool.isEmpty {
            let total = pool.reduce(0.0) { $0 + weight($1) }
            var roll = Double.random(in: 0..<total)
            var chosenIndex = pool.count - 1
            for (i, e) in pool.enumerated() {
                roll -= weight(e)
                if roll <= 0 { chosenIndex = i; break }
            }
            picked.append(pool.remove(at: chosenIndex))
        }

        return picked.map { answer in
            Question(answer: answer, options: options(for: answer, mode: mode))
        }
    }

    /// Three wrong answers. One from the same family so there's something to
    /// learn, the rest from anywhere, because four metalloids in a row is a
    /// miserable question for a six-year-old. In the picture round the wrong
    /// answers have to *look* different, or it's a coin toss.
    private static func options(for answer: ChemElement, mode: QuizMode) -> [ChemElement] {
        var wrong: [ChemElement] = []

        func acceptable(_ e: ChemElement) -> Bool {
            guard e.z != answer.z, !wrong.contains(e) else { return false }
            if mode == .pictureToName { return e.form != answer.form }
            return true
        }

        let family = Elements.all.filter { $0.category == answer.category && acceptable($0) }
        wrong += family.shuffled().prefix(1)

        let rest = Elements.all.filter { acceptable($0) }
        wrong += rest.shuffled().prefix(3 - wrong.count)

        if wrong.count < 3 {
            let anything = Elements.all.filter { $0.z != answer.z && !wrong.contains($0) }
            wrong += anything.shuffled().prefix(3 - wrong.count)
        }

        return (wrong.prefix(3) + [answer]).shuffled()
    }
}
