import AVFoundation

@MainActor
final class SpeechService: ObservableObject {
    static let shared = SpeechService()
    private let synthesizer = AVSpeechSynthesizer()
    @Published var isSpeaking = false

    func speak(_ text: String, language: String = "en-US") {
        if synthesizer.isSpeaking { synthesizer.stopSpeaking(at: .immediate) }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = 0.45
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        synthesizer.speak(utterance)
        isSpeaking = true
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(text.count) * 0.1 + 0.5) {
            self.isSpeaking = false
        }
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
    }
}
