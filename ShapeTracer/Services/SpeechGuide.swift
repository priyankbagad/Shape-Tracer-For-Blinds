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
        let u = AVSpeechUtterance(string: text)
        u.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
        u.voice = AVSpeechSynthesisVoice(language: "en-US")
        synth.speak(u)
    }
}
