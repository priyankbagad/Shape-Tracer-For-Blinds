import Foundation
import AVFoundation
import UIKit

final class FeedbackManager {
    static let shared = FeedbackManager()

    private var engine: AVAudioEngine?
    private var source: AVAudioSourceNode?
    private let sampleRate = 44100.0
    private var theta: Double = 0
    private var frequency: Double = 440
    private var playing = false

    private init() {}

    func prepareAudio() {
        guard engine == nil else { return }
        let engine = AVAudioEngine()
        let src = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self = self else { return noErr }
            let abl = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let incr = 2.0 * .pi * self.frequency / self.sampleRate
            for f in 0..<Int(frameCount) {
                let sampleVal = Float32(sin(self.theta)) * 0.18
                self.theta += incr
                if self.theta > 2.0 * .pi { self.theta -= 2.0 * .pi }
                for buf in abl {
                    let p = UnsafeMutableBufferPointer<Float32>(buf)
                    p[f] = sampleVal
                }
            }
            return noErr
        }
        engine.attach(src)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)
        engine.connect(src, to: engine.mainMixerNode, format: format)
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        try? engine.start()
        self.engine = engine; self.source = src; self.playing = true
    }

    func updateContinuousTone(distance: CGFloat, band: CGFloat) {
        guard playing else { prepareAudio(); return }
        let norm = min(max(distance / (band * 2), 0), 1) // 0..1
        let delta: Double = 140
        self.frequency = 440.0 + (1 - Double(norm)) * delta - delta * 0.5
    }

    func lightTick() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func vertexDing() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        let old = frequency
        frequency = 660
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { self.frequency = old }
    }

    func finishSuccess() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    func stopAll() {
        engine?.stop(); engine = nil; source = nil; playing = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
