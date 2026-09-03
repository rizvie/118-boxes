import UIKit

@MainActor
enum Haptics {
    static func tap() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        SoundEngine.shared.tap()
    }
    static func right() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        SoundEngine.shared.right()
    }
    static func wrong() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        SoundEngine.shared.wrong()
    }
    static func finish() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        SoundEngine.shared.finish()
    }
}
