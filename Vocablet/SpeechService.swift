import AVFoundation

@MainActor
final class SpeechService: ObservableObject {
    static let shared = SpeechService()
    private let synthesizer = AVSpeechSynthesizer()
    @Published var isSpeaking = false

    /// 讀取發音腔調（en-US 或 en-GB），預設美式
    var currentLanguage: String {
        UserDefaults.standard.string(forKey: "pronunciationAccent") ?? "en-US"
    }

    /// 使用當前設定語言朗讀
    func speak(_ text: String) {
        performSpeak(text, language: currentLanguage)
    }

    /// 指定語言朗讀（覆蓋設定）
    func speak(_ text: String, language: String) {
        performSpeak(text, language: language)
    }

    private func performSpeak(_ text: String, language: String) {
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
