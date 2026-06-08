import Foundation

// MARK: - Configuration

/// The URL of your deployed Cloudflare Worker proxy.
/// Replace YOUR-SUBDOMAIN with your actual Cloudflare subdomain after deploying.
private let AI_PROXY_URL = "https://vocablet-ai.wthiintae520.workers.dev"

/// Optional shared secret — must match the APP_SECRET Workers Secret you set via wrangler.
/// Leave empty ("") if you did not configure APP_SECRET on the Worker.
private let APP_PROXY_SECRET = ""

// MARK: - Result

/// One distinct part-of-speech meaning of a word (e.g. "address" → noun meaning, verb meaning)
struct WordMeaning {
    var partOfSpeech: String = ""
    var chineseTranslation: String = ""
    var englishDefinition: String = ""
    var exampleSentence: String = ""
    var exampleTranslation: String = ""
}

struct WordAutoFillResult {
    var kkPhonetic: String = ""
    var ipaPhonetic: String = ""
    /// One entry per distinct part-of-speech meaning (e.g. noun meaning, verb meaning, ...)
    var meanings: [WordMeaning] = []
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

        guard let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            let preview = String(data: data, encoding: .utf8)?.prefix(120).description ?? ""
            throw AIServiceError.parseError(preview)
        }

        let kkPhonetic  = dict["kkPhonetic"]  as? String ?? ""
        let ipaPhonetic = dict["ipaPhonetic"] as? String ?? ""

        var meanings: [WordMeaning] = []
        if let arr = dict["meanings"] as? [[String: Any]] {
            meanings = arr.map { m in
                WordMeaning(
                    partOfSpeech:       m["partOfSpeech"]       as? String ?? "",
                    chineseTranslation: m["chineseTranslation"] as? String ?? "",
                    englishDefinition:  m["englishDefinition"]  as? String ?? "",
                    exampleSentence:    m["exampleSentence"]    as? String ?? "",
                    exampleTranslation: m["exampleTranslation"] as? String ?? ""
                )
            }
        }

        // Backward compatibility with the older flat single-meaning response shape
        if meanings.isEmpty {
            let pos  = dict["partOfSpeech"]       as? String ?? ""
            let cn   = dict["chineseTranslation"] as? String ?? ""
            let def  = dict["englishDefinition"]  as? String ?? ""
            let ex   = dict["exampleSentence"]    as? String ?? ""
            let exTr = dict["exampleTranslation"] as? String ?? ""
            if !pos.isEmpty || !cn.isEmpty || !def.isEmpty {
                meanings = [WordMeaning(partOfSpeech: pos, chineseTranslation: cn,
                                        englishDefinition: def, exampleSentence: ex,
                                        exampleTranslation: exTr)]
            }
        }

        return WordAutoFillResult(kkPhonetic: kkPhonetic, ipaPhonetic: ipaPhonetic, meanings: meanings)
    }
}
