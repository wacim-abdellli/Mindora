# Mindora — Pre-Launch Clinical, Privacy & Billing Readiness Checklist

> **Scope:** Operational gate before moving Mindora from offline/local development & clinical demonstrations to any real patient or clinic deployment. Aligned with `AGENTS.md` Directive 1 (Steps 10 & 14) and verified repository guardrails.

---

## 1. Mandatory Pre-User Billing & Data Gate (Steps 10 & 14)

- [ ] **Stay on Spark Free Tier during development:** Do **not** link billing or store real patient telemetry during development. Default AI transport uses the offline mock simulator (`MockInvestigatorService`, `DEV_MOCK_GEMINI_KEY`).
- [ ] **Never send real personal data on Gemini free tier:** The Gemini free tier permits Google to use submitted content to improve its products and allows human review. Only synthetic/fictional text may be used during free-tier testing.
- [ ] **Switch to Paid AI Tier BEFORE any real user:** Link Cloud Billing to a paid Gemini API tier with strict data-logging opt-out / zero-training terms prior to onboarding real users.
- [ ] **Configure Billing Budget Alerts & Spend Caps:** Set hard monthly spend caps and automated email/webhook alerts at 50%, 80%, and 100% of budget before enabling live traffic.
- [ ] **Deploy via Server-Side Proxy (`AI_PROXY_URL`):** Supply `--dart-define=AI_PROXY_URL=https://...` in release builds so API credentials are never embedded directly inside public Android/iOS client binaries.
- [ ] **Verify Current Official Pricing & Data Terms:** Re-verify official Google Gemini API & Firebase pricing and privacy/DPA terms immediately prior to production launch.

---

## 2. Spark vs. Blaze Infrastructure Boundaries

| Subsystem | Development Mode | Pre-Launch / Production Boundary |
| :--- | :--- | :--- |
| **Daily Check-In, Insights, Loop Map, Recovery Ledger** | 100% local on-device | Zero cloud database required (`SharedPreferences` + encrypted local store) |
| **In-Room Patient -> Psychiatrist Sync (`MF-CLINIC-V1:`)** | 100% offline / QR / copy | Zero server transmission; gzip + PBKDF2-SHA256 + AES-256-GCM + SHA-256 check |
| **Post-Visit Focus Plan (`MF-CAREPLAN-V1:`)** | 100% offline / QR / copy | Zero server transmission; verbal in-room passphrase only |
| **Printable A4 Brief PDF & Native Share Sheet** | Offline PDF 1.4 synthesis | Local temp/file write + OS share sheet (`SharePlus.instance.share`) |
| **Live AI Companion / Deconstruction** | Local `MockInvestigatorService` | Paid-tier backend proxy (`AI_PROXY_URL`), gated by explicit consent & `isPrivate` block |

---

## 3. Privacy, Consent & Regulatory Posture (Tunisia INPDP / EU GDPR)

- [ ] **Hard Vault Isolation (`isPrivate == true`):** Confirm private investigation cases are excluded across `ClinicianSyncService.buildPatientPacket`, `ClinicianSyncPacket.fromJson`, `ForensicLoopLink.synthesize(excludePrivateCases: true)`, `generateEhrClinicalNote`, and `ClinicalBriefPdfService`.
- [ ] **Granular Patient Consent Scope:** Verify `ClinicalConsentScope` independently gates mood metrics, sleep/energy/anxiety + context tags, symptom reports, shared cases, personal notes, psychological profile snapshot, and pre-visit agenda.
- [ ] **Observational Non-Diagnostic Language Audit:** Verify all UI copy, PDF briefs, and EHR exports stay strictly descriptive (`inspired by CBT`), with zero medical diagnoses, zero diet/weight advice, and zero predictions of relapse.
- [ ] **Local Key Rotation & Purge:** Test biometric app lock (`local_auth`), encrypted local backup restore, and one-tap vault purge flows.

---

## 4. App Store & Play Store Permission Disclosures

Match submission metadata directly to verified manifest declarations:

- **Camera (`android.permission.CAMERA` / `NSCameraUsageDescription`):** Used strictly on-device when scanning encrypted `MF-CLINIC-V1:` or `MF-CAREPLAN-V1:` in-room QR codes. Zero camera frames are stored on disk or uploaded.
- **Biometrics (`android.permission.USE_BIOMETRIC` / `NSFaceIDUsageDescription`):** Optional device biometric verification protecting local sanctuary reflections.
- **Notifications (`android.permission.POST_NOTIFICATIONS`):** Optional local daily check-in reminders scheduled on-device.

---

## 5. Offline Crisis Safety Net Verification

- [ ] Confirm offline regex keyword interception (`crisis_keywords.dart`, `safety_interceptor.dart`) triggers locally without network access across EN, FR, and Tunisian Arabic phrases.
- [ ] Confirm unblockable direct dial links remain intact:
  - **Tunisia Ligne Verte:** `80 10 50 50`
  - **SAMU Medical Emergency:** `190`
  - **Protection Civile:** `198`

---

## 6. 60-Second Two-Phone In-Room Clinic Demo Script

1. **Seconds 0–15 (Patient Preparation):** Open **Patient Sanctuary -> Home / Insights**, review **Observed Stabilizers** and **Observed Forensic Loop** (`4/4` non-diagnostic nodes), tap **2-Minute Visit Brief**, pick 1–2 topics + focus completion status, and tap **Continue to Share with Psychiatrist**.
2. **Seconds 15–30 (Encrypted QR Handoff):** Choose consent toggles, enter a 6+ character verbal room PIN, generate the compressed `MF-CLINIC-V1:...` code, and tap **Show In-Room QR**.
3. **Seconds 30–45 (Psychiatrist Review):** Switch workspace to **Psychiatrist Workspace** (Phone 2 or tablet split-pane), tap **Import Packet -> Scan In-Room QR** (or inspect pre-seeded `Nadia B.` dossier), enter the verbal PIN, and review **Since Last Visit** deltas + **Observed Forensic Loop** + **A4 Consultation Brief** preview / native PDF Share Sheet.
4. **Seconds 45–60 (Closing the Loop):** Tap **Post-Visit Focus**, pick 1–2 collaborative observation cues, enter a room PIN, display the `MF-CAREPLAN-V1:` QR, scan into **Patient Sanctuary**, and confirm the focus card updates live on Patient Home.
