// Services/Spoken.swift
import AVFoundation

final class Speaker {
    static let shared = Speaker()

    enum Priority { case low, medium, high }

    private let synth = AVSpeechSynthesizer()
    private let voice = AVSpeechSynthesisVoice(language: "en-US")
    private let rate: Float = AVSpeechUtteranceDefaultSpeechRate * 0.9

    private var lastUtter: String = ""
    private var lastTime: TimeInterval = 0
    private let cooldownLow: TimeInterval = 1.0
    private let cooldownMed: TimeInterval = 0.6

    /// Debounced, duplicate-safe speech. High priority interrupts immediately.
    func say(_ text: String, priority: Priority) {
        let now = CFAbsoluteTimeGetCurrent()

        if text == lastUtter && (now - lastTime < 0.8) { return } // drop dupes

        switch priority {
        case .low:
            if synth.isSpeaking || (now - lastTime < cooldownLow) { return }
        case .medium:
            if now - lastTime < cooldownMed { return }
        case .high:
            if synth.isSpeaking { synth.stopSpeaking(at: .immediate) }
        }

        let u = AVSpeechUtterance(string: text)
        u.voice = voice
        u.rate = rate
        synth.speak(u)

        lastUtter = text
        lastTime = now
    }

    func stopAll() {
        if synth.isSpeaking { synth.stopSpeaking(at: .immediate) }
    }
}
