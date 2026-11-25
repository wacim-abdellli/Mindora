# Mindora App Check AI Proxy

Lightweight backend gateway keeping **all paid API keys out of client APKs** (`AGENTS.md` Directive 1 / Launch Gate Steps 10 & 14).

## Architecture
- **Primary:** Google Gemini Paid Tier (`gemini-2.5-flash` / configurable server model, commercial no-training terms + `europe-west1` deployment option) with constrained JSON schema.
- **Fallback:** GroqCloud (`llama-3.3-70b-versatile`) with **Zero Data Retention (ZDR)** enabled in Groq Console Data Controls.
- **Security:** Verifies `X-Firebase-AppCheck` header before forwarding and enforces a 64 KB payload cap per turn. Never logs user reflection text.

## Before Deploying to Real Users
1. Stay on Firebase **Spark** (mock local engine) during offline development & demos.
2. When ready for pilot users, upgrade Firebase project to **Blaze**, verify current Google Gemini & Groq pricing/DPA terms, and set **Cloud Billing budget alerts (`50%`, `80%`, `100%`) + spend caps**.
3. Store secrets via Firebase Secret Manager:
   ```powershell
   firebase functions:secrets:set GEMINI_PAID_API_KEY
   firebase functions:secrets:set GROQ_ZDR_API_KEY
   npm --prefix proxy run build
   firebase deploy --only functions:companionTurn
   ```
4. Pass the proxy endpoint to release Flutter builds without bundling raw API keys:
   ```powershell
   flutter build apk --release --dart-define=AI_PROXY_URL=https://europe-west1-<project-id>.cloudfunctions.net/companionTurn
   ```
