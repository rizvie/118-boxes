import Foundation
import SwiftData

/// One row per element the child has been asked about.
@Model
final class ElementStat {
    @Attribute(.unique) var z: Int
    var correct: Int
    var wrong: Int
    var lastSeen: Date

    init(z: Int, correct: Int = 0, wrong: Int = 0, lastSeen: Date = .now) {
        self.z = z
        self.correct = correct
        self.wrong = wrong
        self.lastSeen = lastSeen
    }

    /// Three right answers and it counts as learned.
    var isLearned: Bool { correct >= 3 }

    var seen: Bool { correct + wrong > 0 }
}
