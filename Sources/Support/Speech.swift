import AVFoundation

/// Reads element names out loud. He's six: hearing "Magnesium" while seeing it
/// written is most of the point.
@MainActor
final class Speaker {
    static let shared = Speaker()
    private let synth = AVSpeechSynthesizer()

    var enabled = true

    /// Empty means "use the default Australian voice". Storing the identifier
    /// rather than a language code means picking a specific voice sticks even
    /// when a region has several installed.
    static let voiceDefaultsKey = "voiceIdentifier"

    private init() {}

    /// Voices actually installed on this device, English only.
    ///
    /// Deliberately not every language on the device. A six-year-old who sets
    /// element names to Finnish has no way of reading his way back out, and the
    /// point of the feature is accent, not translation.
    ///
    /// Enhanced and Premium voices only appear here once they have been
    /// downloaded in iOS Settings -> Accessibility -> Spoken Content -> Voices,
    /// so on a fresh device this list is short. SettingsView says so.
    static func englishVoices() -> [AVSpeechSynthesisVoice] {
        AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix("en") }
            .sorted {
                // Australian first, it's the default and the one he hears at home.
                if ($0.language == "en-AU") != ($1.language == "en-AU") {
                    return $0.language == "en-AU"
                }
                if $0.language != $1.language { return $0.language < $1.language }
                return $0.name < $1.name
            }
    }

    /// "Karen — Australian" or "Daniel — British (Enhanced)".
    static func label(for voice: AVSpeechSynthesisVoice) -> String {
        let region = Locale.current.localizedString(forIdentifier: voice.language)
            ?? voice.language
        var text = "\(voice.name) — \(region)"
        switch voice.quality {
        case .enhanced: text += " (Enhanced)"
        case .premium:  text += " (Premium)"
        default: break
        }
        return text
    }

    /// The chosen voice, or the Australian default. Falls back cleanly if the
    /// stored voice has since been deleted in iOS Settings.
    private func currentVoice() -> AVSpeechSynthesisVoice? {
        let stored = UserDefaults.standard.string(forKey: Self.voiceDefaultsKey) ?? ""
        if !stored.isEmpty, let v = AVSpeechSynthesisVoice(identifier: stored) {
            return v
        }
        return AVSpeechSynthesisVoice(language: "en-AU")
            ?? AVSpeechSynthesisVoice(language: "en-GB")
    }

    func say(_ text: String) {
        guard enabled else { return }
        speak(text)
    }

    /// Used by Settings to demo a voice. Ignores `enabled`, because you are
    /// changing the setting and expect to hear the result.
    func preview(_ text: String) {
        speak(text)
    }

    private func speak(_ text: String) {
        synth.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = currentVoice()
        utterance.rate = 0.42
        utterance.pitchMultiplier = 1.05
        synth.speak(utterance)
    }

    func stop() { synth.stopSpeaking(at: .immediate) }
}
