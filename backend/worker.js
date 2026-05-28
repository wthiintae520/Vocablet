/**
 * Vocablet AI Proxy — Cloudflare Worker
 *
 * Proxies word-lookup requests from the iOS app to Anthropic.
 * The ANTHROPIC_API_KEY is stored as a Workers Secret (never in the app).
 *
 * Endpoint: POST /
 * Body:     { "term": "serendipity" }
 * Returns:  { "phonetic": "...", "partOfSpeech": "...", ... }
 *
 * Deploy:
 *   1. cd backend
 *   2. npx wrangler secret put ANTHROPIC_API_KEY   ← paste your key
 *   3. npx wrangler deploy
 */

const ALLOWED_METHODS = ["POST", "OPTIONS"];

// ── Optional: simple shared secret to block unauthorised callers ──────────
// Set via:  npx wrangler secret put APP_SECRET
// Then set the same value in iOS AIService.swift → APP_PROXY_SECRET constant.
// Leave APP_SECRET unset in Workers to disable the check entirely.
// ─────────────────────────────────────────────────────────────────────────

export default {
  async fetch(request, env) {
    // ── CORS pre-flight ──────────────────────────────────────────────────
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

    // ── Optional shared-secret check ─────────────────────────────────────
    if (env.APP_SECRET) {
      const incoming = request.headers.get("X-App-Secret") ?? "";
      if (incoming !== env.APP_SECRET) {
        return jsonError("Unauthorised", 401, corsHeaders);
      }
    }

    // ── Parse body ───────────────────────────────────────────────────────
    let body;
    try { body = await request.json(); }
    catch { return jsonError("Invalid JSON body", 400, corsHeaders); }

    const term = (body.term ?? "").trim();
    if (!term) return jsonError("Missing 'term' field", 400, corsHeaders);

    // ── Call Anthropic ───────────────────────────────────────────────────
    const systemPrompt =
      "You are a precise dictionary assistant. " +
      "Always respond with ONLY a valid JSON object and nothing else — no markdown, no explanation.";

    const userPrompt = `For the English word or phrase "${term}", return this JSON:
{
  "phonetic": "IPA notation, e.g. /ˌserənˈdɪpɪti/",
  "partOfSpeech": "one of: noun / verb / adjective / adverb / pronoun / preposition / conjunction / interjection / phrase / idiom",
  "chineseTranslation": "concise Traditional Chinese translation, e.g. 意外的好運、緣分",
  "englishDefinition": "clear and natural English definition",
  "exampleSentence": "one natural example sentence using the word",
  "exampleTranslation": "Traditional Chinese translation of the example sentence"
}`;

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
          model:      "claude-3-5-haiku-20241022",
          max_tokens: 512,
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

    // ── Unwrap Anthropic envelope → forward inner JSON to app ────────────
    const envelope = await anthropicResp.json();
    const text     = envelope?.content?.[0]?.text ?? "";
    const jsonText = extractJSON(text);

    return new Response(jsonText, {
      status:  200,
      headers: { "Content-Type": "application/json", ...corsHeaders },
    });
  },
};

// ── Helpers ───────────────────────────────────────────────────────────────

function jsonError(message, status, corsHeaders) {
  return new Response(JSON.stringify({ error: message }), {
    status,
    headers: { "Content-Type": "application/json", ...corsHeaders },
  });
}

/** Strip markdown code fences if Claude accidentally wraps the JSON. */
function extractJSON(text) {
  const s = text.trim();
  const start = s.indexOf("{");
  const end   = s.lastIndexOf("}");
  if (start !== -1 && end !== -1) return s.slice(start, end + 1);
  return s;
}
