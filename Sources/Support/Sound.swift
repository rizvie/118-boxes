import AVFoundation
import SwiftUI

/// Synthesises short tones at runtime, so nothing has to be bundled. Ambient
/// category means it mixes with other audio and respects the mute switch.
@MainActor
final class SoundEngine {
    static let shared = SoundEngine()

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let sampleRate = 44_100.0
    private var started = false

    var enabled = true

    private init() {
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode,
                       format: AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1))
    }

    private func startIfNeeded() {
        guard !started else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            try engine.start()
            player.play()
            started = true
        } catch {
            started = false
        }
    }

    private func tone(_ frequency: Double, duration: Double, volume: Float = 0.5, delay: Double = 0) {
        guard enabled else { return }
        startIfNeeded()
        guard started else { return }

        let lead = AVAudioFrameCount(delay * sampleRate)
        let body = AVAudioFrameCount(duration * sampleRate)
        let frames = lead + body
        guard frames > 0,
              let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames),
              let data = buffer.floatChannelData else { return }
        buffer.frameLength = frames

        let attack = 0.006 * sampleRate
        for i in 0..<Int(frames) {
            if i < Int(lead) { data[0][i] = 0; continue }
            let n = i - Int(lead)
            let t = Double(n) / sampleRate
            let env = Double(n) < attack ? Double(n) / attack : exp(-3.2 * t / duration)
            data[0][i] = Float(sin(2 * .pi * frequency * t) * env) * volume
        }
        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
    }

    func tap()   { tone(660, duration: 0.05, volume: 0.3) }
    func right() {
        tone(784, duration: 0.09, volume: 0.5)
        tone(1046, duration: 0.16, volume: 0.5, delay: 0.08)
    }
    func wrong() { tone(196, duration: 0.22, volume: 0.45) }
    func finish() {
        tone(523, duration: 0.10, volume: 0.5)
        tone(659, duration: 0.10, volume: 0.5, delay: 0.10)
        tone(784, duration: 0.10, volume: 0.5, delay: 0.20)
        tone(1046, duration: 0.30, volume: 0.55, delay: 0.30)
    }
}
