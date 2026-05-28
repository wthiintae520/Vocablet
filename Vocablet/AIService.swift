import Foundation

// MARK: - Result

struct WordAutoFillResult {
    var phonetic: String = ""
    var partOfSpeech: String = ""
    var chineseTranslation: String = ""
    var englishDefinition: String = ""
    var exampleSentence: String = ""
    var exampleTranslation: String = ""
}

// MARK: - Errors

enum AIServiceError: LocalizedError {
    case missingAPIKey
    case httpError(Int)
    case parseError(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "請先在「設定 → AI 設定」填入 Anthropic API Key"
        case .httpError(let code):
            return "API 錯誤（HTTP \(code)），請確認 API Key 是否正確"
        case .parseError(let detail):
            return "無法解析 AI 回應：\(detail)"
        }
    }
}

// MARK: - Service

final class AIService {
    static let shared = AIService()

    func fillWordDetails(for term: String, apiKey: String) async throws -> WordAutoFillResult {
        let key = apiKey.trimmingCharacters(in: .whitespaces)
        guard !key.isEmpty else { throw AIServiceError.missingAPIKey }

        let url = URL(string: "https://api.anthropic.com/v1/messages")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json",  forHTTPHeaderField: "Content-Type")
        req.setValue(key,                 forHTTPHeaderField: "x-api-key")
        req.setValue("2023-06-01",        forHTTPHeaderField: "anthropic-version")

        let systemPrompt = """
        You are a precise dictionary assistant. \
        Always respond with ONLY a valid JSON object and nothing else — no markdown, no explanation.
        """

        let userPrompt = """
        For the English word or phrase "\(term)", return this JSON:
        {
          "phonetic": "IPA notation, e.g. /ˌserənˈdɪpɪti/",
          "partOfSpeech": "one of: noun / verb / adjective / adverb / pronoun / preposition / conjunction / interjection / phrase / idiom",
          "chineseTranslation": "concise Traditional Chinese translation, e.g. 意外的好運、緣分",
          "englishDefinition": "clear and natural English definition",
          "exampleSentence": "one natural example sentence using the word",
          "exampleTranslation": "Traditional Chinese translation of the example sentence"
        }
        """

        let body: [String: Any] = [
            "model": "claude-3-5-haiku-20241022",
            "max_tokens": 512,
            "system": systemPrompt,
            "messages": [["role": "user", "content": userPrompt]]
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw AIServiceError.httpError(http.statusCode)
        }

        // Unwrap Anthropic envelope
        guard
            let envelope = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let content  = envelope["content"] as? [[String: Any]],
            let text     = content.first?["text"] as? String
        else { throw AIServiceError.parseError("envelope") }

        // Parse inner JSON (Claude may occasionally wrap in ```)
        let jsonText = extractJSON(from: text)
        guard
            let textData = jsonText.data(using: .utf8),
            let dict     = try? JSONSerialization.jsonObject(with: textData) as? [String: String]
        else { throw AIServiceError.parseError(text.prefix(120).description) }

        return WordAutoFillResult(
            phonetic:           dict["phonetic"]           ?? "",
            partOfSpeech:       dict["partOfSpeech"]       ?? "",
            chineseTranslation: dict["chineseTranslation"] ?? "",
            englishDefinition:  dict["englishDefinition"]  ?? "",
            exampleSentence:    dict["exampleSentence"]    ?? "",
            exampleTranslation: dict["exampleTranslation"] ?? ""
        )
    }

    // Strip markdown code fences if Claude wraps the JSON
    private func extractJSON(from text: String) -> String {
        let stripped = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let start = stripped.firstIndex(of: "{"), let end = stripped.lastIndex(of: "}") {
            return String(stripped[start...end])
        }
        return stripped
    }
}
