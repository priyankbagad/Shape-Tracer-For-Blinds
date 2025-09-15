// Services/SpeechGuide.swift
import Foundation
import AVFoundation
import UIKit

@MainActor
final class SpeechGuide: ObservableObject {
    static let shared = SpeechGuide()

    private let synth = AVSpeechSynthesizer()
    private var timer: Timer?

    func startGuidance(script: String, interval: TimeInterval = 6.0) {
        stopGuidance()

        // Ensure audio is heard even if the phone is on silent
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)

        speak(script)
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.speak(script) }
        }
    }

    func stopGuidance() {
        timer?.invalidate()
        timer = nil
        if synth.isSpeaking { synth.stopSpeaking(at: .immediate) }
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func speak(_ text: String) {
        guard !synth.isSpeaking else { return }
        let utt = AVSpeechUtterance(string: text)
        utt.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
        utt.voice = AVSpeechSynthesisVoice(language: "en-US")
        synth.speak(utt)
    }
}
