/**
 * Vocablet AI Proxy — Cloudflare Worker
 *
 * POST /   body: { "term": "serendipity" }
 * Returns: { "kkPhonetic": "...", "ipaPhonetic": "...", "partOfSpeech": "...", ... }
 */

const ALLOWED_METHODS = ["POST", "OPTIONS"];

export default {
  async fetch(request, env) {
    const corsHeaders = {
      "Access-Control-Allow-Origin":  "*",
      "Access-Control-Allow-Methods": "POST, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type, X-App-Secret",
    };

    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: corsHeaders });
    }
    if (!ALLOWED_METHODS.includes(request.method)) {
      return jsonError("Method not allowed", 405, corsHeaders);
    }

    if (env.APP_SECRET) {
      const incoming = request.headers.get("X-App-Secret") ?? "";
      if (incoming !== env.APP_SECRET) {
        return jsonError("Unauthorised", 401, corsHeaders);
      }
    }

    let body;
    try { body = await request.json(); }
    catch { return jsonError("Invalid JSON body", 400, corsHeaders); }

    const term = (body.term ?? "").trim();
    if (!term) return jsonError("Missing 'term' field", 400, corsHeaders);

    const systemPrompt =
      "You are a precise dictionary assistant. " +
      "Always respond with ONLY a valid JSON object and nothing else — no markdown, no explanation.";

    const userPrompt = `For the English word or phrase "${term}", analyze its common meanings grouped by part of speech, and return this JSON:
{
  "kkPhonetic": "KK phonetic notation used in Taiwan, e.g. /ˋwɔtɚ/ or /ˌsɛrənˋdɪpɪtɪ/",
  "ipaPhonetic": "IPA (International Phonetic Alphabet) notation, e.g. /ˈwɔːtər/ or /ˌserənˈdɪpɪti/",
  "meanings": [
    {
      "partOfSpeech": "one of: noun / verb / adjective / adverb / pronoun / preposition / conjunction / interjection / phrase / idiom",
      "chineseTranslation": "concise Traditional Chinese translation for this specific part-of-speech meaning only",
      "englishDefinition": "clear and natural English definition for this specific part-of-speech meaning only",
      "exampleSentence": "one natural example sentence using the word in this part-of-speech meaning",
      "exampleTranslation": "Traditional Chinese translation of the example sentence"
    }
  ]
}
Important: include ONE separate entry per distinct common part of speech for this word — e.g. "address" is commonly both a noun (地址) and a verb (稱呼/處理), so return two separate entries, not one combined entry. Do not mix multiple parts of speech into a single entry's fields. If the word only has one common part of speech, return a single-element array.`;

    let anthropicResp;
    try {
      anthropicResp = await fetch("https://api.anthropic.com/v1/messages", {
        method: "POST",
        headers: {
          "Content-Type":      "application/json",
          "x-api-key":         env.ANTHROPIC_API_KEY,
          "anthropic-version": "2023-06-01",
        },
        body: JSON.stringify({
          model:      "claude-haiku-4-5-20251001",
          max_tokens: 600,
          system:     systemPrompt,
          messages:   [{ role: "user", content: userPrompt }],
        }),
      });
    } catch (e) {
      return jsonError("Failed to reach Anthropic: " + e.message, 502, corsHeaders);
    }

    if (!anthropicResp.ok) {
      return jsonError("Anthropic error HTTP " + anthropicResp.status, 502, corsHeaders);
    }

    const envelope = await anthropicResp.json();
    const text     = envelope?.content?.[0]?.text ?? "";
    const jsonText = extractJSON(text);

    return new Response(jsonText, {
      status:  200,
      headers: { "Content-Type": "application/json", ...corsHeaders },
    });
  },
};

function jsonError(message, status, corsHeaders) {
  return new Response(JSON.stringify({ error: message }), {
    status,
    headers: { "Content-Type": "application/json", ...corsHeaders },
  });
}

function extractJSON(text) {
  const s = text.trim();
  const start = s.indexOf("{");
  const end   = s.lastIndexOf("}");
  if (start !== -1 && end !== -1) return s.slice(start, end + 1);
  return s;
}
