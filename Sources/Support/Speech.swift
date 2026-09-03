import AVFoundation

/// Reads element names out loud. He's six: hearing "Magnesium" while seeing it
/// written is most of the point.
@MainActor
final class Speaker {
    static let shared = Speaker()
    private let synth = AVSpeechSynthesizer()

    var enabled = true

    private init() {}

    func say(_ text: String) {
        guard enabled else { return }
        synth.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-AU")
            ?? AVSpeechSynthesisVoice(language: "en-GB")
        utterance.rate = 0.42
        utterance.pitchMultiplier = 1.05
        synth.speak(utterance)
    }

    func stop() { synth.stopSpeaking(at: .immediate) }
}
