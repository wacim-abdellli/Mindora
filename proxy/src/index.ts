import { initializeApp } from "firebase-admin/app";
import { getAppCheck } from "firebase-admin/app-check";
import { onRequest } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";

initializeApp();

// Stored in Google Secret Manager — never embedded in client APKs.
const geminiPaidApiKey = defineSecret("GEMINI_PAID_API_KEY");
const groqZdrApiKey = defineSecret("GROQ_ZDR_API_KEY");

const DEFAULT_GEMINI_MODEL = process.env.GEMINI_MODEL || "gemini-2.5-flash";
const DEFAULT_GROQ_MODEL = process.env.GROQ_MODEL || "llama-3.3-70b-versatile";

/**
 * Hardened App-Check-verified AI proxy for Mindora.
 *
 * Deployment checklist (AGENTS.md Steps 10 & 14):
 * 1. Upgrade Firebase to Blaze ONLY when onboarding real users.
 * 2. Ensure Cloud Billing links a Paid Gemini Tier (zero model training) & enable ZDR in Groq Console.
 * 3. Configure budget alerts (50%, 80%, 100%) and hard daily spend caps.
 * 4. Build Flutter release APK with: --dart-define=AI_PROXY_URL=https://<region>-<project>.cloudfunctions.net/companionTurn
 */
export const companionTurn = onRequest(
  {
    region: "europe-west1",
    cors: false,
    secrets: [geminiPaidApiKey, groqZdrApiKey],
    maxInstances: 20,
    timeoutSeconds: 15,
  },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).json({ error: "Method not allowed" });
      return;
    }

    // Enforce Firebase App Check token in production deployments
    const appCheckToken = req.header("X-Firebase-AppCheck");
    if (process.env.REQUIRE_APP_CHECK !== "false") {
      if (!appCheckToken) {
        res.status(401).json({ error: "Missing App Check token" });
        return;
      }
      try {
        await getAppCheck().verifyToken(appCheckToken);
      } catch {
        res.status(401).json({ error: "Invalid App Check token" });
        return;
      }
    }

    const body = req.body as Record<string, unknown> | undefined;
    if (!body || typeof body !== "object") {
      res.status(400).json({ error: "Invalid JSON payload" });
      return;
    }

    // Basic payload size ceiling (~64 KB) to prevent runaway token spend
    if (Buffer.byteLength(JSON.stringify(body), "utf8") > 65536) {
      res.status(413).json({ error: "Payload too large" });
      return;
    }

    const preferredProvider =
      typeof body.provider === "string" ? body.provider : "gemini";

    // Route Gemini payloads when requested or default
    if (preferredProvider === "gemini" && geminiPaidApiKey.value()) {
      const model =
        typeof body.model === "string" && body.model.trim()
          ? body.model.trim()
          : DEFAULT_GEMINI_MODEL;
      const upstreamUrl = `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(
        model
      )}:generateContent`;

      const { provider: _p, model: _m, ...geminiPayload } = body;
      const upstream = await fetch(upstreamUrl, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-goog-api-key": geminiPaidApiKey.value(),
        },
        body: JSON.stringify(geminiPayload),
      });

      if (upstream.ok) {
        const json = await upstream.json();
        res.status(200).json(json);
        return;
      }
    }

    // Automatic ZDR Groq fallback / direct Groq route
    if (groqZdrApiKey.value()) {
      const groqPayload =
        preferredProvider === "groq"
          ? body
          : {
              model: DEFAULT_GROQ_MODEL,
              response_format: { type: "json_object" },
              temperature: 0.65,
              messages: [
                {
                  role: "system",
                  content:
                    "Return valid JSON: {reply, chosen_posture, suggested_replies, offer_calm_exercise, silent_thought_type, silent_distortion_theme, save_worthy_summary}. Zero emojis.",
                },
                {
                  role: "user",
                  content: "Respond warmly and concisely to the latest reflection.",
                },
              ],
            };

      const upstream = await fetch(
        "https://api.groq.com/openai/v1/chat/completions",
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${groqZdrApiKey.value()}`,
          },
          body: JSON.stringify(groqPayload),
        }
      );

      const text = await upstream.text();
      res.status(upstream.status).type("application/json").send(text);
      return;
    }

    res.status(503).json({ error: "No live AI provider configured on proxy" });
  }
);
