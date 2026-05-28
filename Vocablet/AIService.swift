import Foundation

// MARK: - Configuration

/// The URL of your deployed Cloudflare Worker proxy.
/// Replace YOUR-SUBDOMAIN with your actual Cloudflare subdomain after deploying.
private let AI_PROXY_URL = "https://vocablet-ai.wthiintae520.workers.dev"

/// Optional shared secret — must match the APP_SECRET Workers Secret you set via wrangler.
/// Leave empty ("") if you did not configure APP_SECRET on the Worker.
private let APP_PROXY_SECRET = ""

// MARK: - Result

struct WordAutoFillResult {
    var kkPhonetic: String = ""
    var ipaPhonetic: String = ""
    var partOfSpeech: String = ""
    var chineseTranslation: String = ""
    var englishDefinition: String = ""
    var exampleSentence: String = ""
    var exampleTranslation: String = ""
}

// MARK: - Errors

enum AIServiceError: LocalizedError {
    case proxyNotConfigured
    case httpError(Int)
    case parseError(String)
    case networkError(String)

    var errorDescription: String? {
        switch self {
        case .proxyNotConfigured:
            return "AI 服務尚未設定，請聯絡開發者。"
        case .httpError(let code):
            return "AI 服務錯誤（HTTP \(code)），請稍後再試。"
        case .parseError(let detail):
            return "無法解析 AI 回應：\(detail)"
        case .networkError(let msg):
            return "網路錯誤：\(msg)"
        }
    }
}

// MARK: - Service

final class AIService {
    static let shared = AIService()

    func fillWordDetails(for term: String) async throws -> WordAutoFillResult {
        guard !AI_PROXY_URL.contains("YOUR-SUBDOMAIN"),
              let url = URL(string: AI_PROXY_URL) else {
            throw AIServiceError.proxyNotConfigured
        }

        var req = URLRequest(url: url)
        req.httpMethod  = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !APP_PROXY_SECRET.isEmpty {
            req.setValue(APP_PROXY_SECRET, forHTTPHeaderField: "X-App-Secret")
        }
        req.httpBody = try JSONSerialization.data(withJSONObject: ["term": term])

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: req)
        } catch {
            throw AIServiceError.networkError(error.localizedDescription)
        }

        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw AIServiceError.httpError(http.statusCode)
        }

        guard let dict = try? JSONSerialization.jsonObject(with: data) as? [String: String] else {
            let preview = String(data: data, encoding: .utf8)?.prefix(120).description ?? ""
            throw AIServiceError.parseError(preview)
        }

        return WordAutoFillResult(
            kkPhonetic:         dict["kkPhonetic"]         ?? "",
            ipaPhonetic:        dict["ipaPhonetic"]        ?? "",
            partOfSpeech:       dict["partOfSpeech"]       ?? "",
            chineseTranslation: dict["chineseTranslation"] ?? "",
            englishDefinition:  dict["englishDefinition"]  ?? "",
            exampleSentence:    dict["exampleSentence"]    ?? "",
            exampleTranslation: dict["exampleTranslation"] ?? ""
        )
    }
}
