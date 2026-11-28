# Mindora — Pre-Launch Clinical, Privacy & Billing Readiness Checklist

> **Scope:** Operational gate before moving Mindora from offline/local development & clinical demonstrations to any real patient or clinic deployment. Aligned with `AGENTS.md` Directive 1 (Steps 10 & 14) and verified repository guardrails.

---

## 1. Mandatory Pre-User Billing & Data Gate (Steps 10 & 14)

> **Verified Official Pricing & Data-Governance Terms (Reviewed Nov 2026 before Phase 7 launch gate):**
> - **Gemini API Free Tier vs. Paid Tier:** On the **Free Tier**, submitted prompts, inputs, and responses **are used by Google to improve its products and services**, and **human reviewers may read, annotate, and process API inputs/outputs**. Free tier usage is also restricted or unavailable for commercial customer-facing apps in the **EEA, Switzerland, and the UK**. On the **Paid Tier (Pay-as-you-go via linked Cloud Billing)**, Google **does not use** prompts or responses to train or improve models, limiting temporary logs strictly to abuse/safety compliance.
> - **Firebase Spark vs. Blaze Plan:** **Spark (`$0`)** blocks Cloud Functions deployments, Phone SMS OTP, and halts traffic at quota. **Blaze (`$0` base, pay-as-you-go)** includes Cloud Firestore free daily quotas (**50,000 reads / 20,000 writes / 20,000 deletes / 1 GiB storage / 10 GiB egress/mo**), Cloud Functions (**2M invocations/mo free**), and Auth Email/Anonymous (**50,000 MAUs free**; Phone SMS OTP billed after **10 SMS/day**).
> - **Critical Budget Alert Warning:** Google Cloud **Budgets & Alerts (`50%`, `80%`, `100%`) notify by email/PubSub but do NOT automatically shut off Blaze billing**; pair budget alerts with Google Cloud API quota limits and server-side rate-limiting in `firebase/functions/index.js` (`aiCompanionProxy`).

- [ ] **Stay on Spark Free Tier during development:** Do **not** link billing or store real patient telemetry during development. Default backend stays on `ClinicBackendMode.offlineSimulator` (`LocalClinicSimulatorRepository`) and mock AI (`MockInvestigatorService`, `DEV_MOCK_GEMINI_KEY`).
- [ ] **Never send real personal data on Gemini free tier:** Only synthetic/fictional test text may be used during free-tier developer testing.
- [ ] **Switch to Paid AI Tier BEFORE any real user:** Link Cloud Billing to a Paid Gemini API key in Cloud Secret Manager (`firebase functions:secrets:set GEMINI_PAID_API_KEY`) with zero-training / no-human-review commercial terms prior to onboarding real users.
- [ ] **Configure Billing Budget Alerts & Hard Quota/Spend Caps:** Set automated Google Cloud Budget alerts at **50%, 80%, and 100%** AND enforce per-UID rate limits / API quotas on `aiCompanionProxy`.
- [ ] **Deploy via Server-Side Proxy (`AI_PROXY_URL`) + Multi-Tenant Firebase (`firebase/`):** Deploy `firebase/firestore.rules`, `firebase/firestore.indexes.json`, and `firebase/functions/index.js` on Firebase Blaze with App Check enabled, and pass `--dart-define=CLINIC_BACKEND_MODE=firebase_production --dart-define=PAID_AI_BILLING_VERIFIED=true --dart-define=AI_PROXY_URL=https://...` in release builds. Never bundle raw API keys inside APK/IPA/Windows binaries.
- [ ] **Verify Official Terms Immediately Before Go-Live:** Re-confirm current Gemini API Paid-tier DPA & Firebase Blaze pricing tables prior to welcoming the first clinic cohort.

---

## 2. Spark vs. Blaze Infrastructure Boundaries

| Subsystem | Development Mode | Pre-Launch / Production Boundary |
| :--- | :--- | :--- |
| **Daily Check-In, Insights, Loop Map, Recovery Ledger** | 100% local on-device | Zero cloud database required (`SharedPreferences` + encrypted local store) unless synced via clinic tenant |
| **Clinic Provisioning, Auth & Auto-Sync (`ClinicAuthRepository` / `ClinicSyncRepository`)** | `LocalClinicSimulatorRepository` (PBKDF2 PINs, single-use hashed QR tokens, AES-GCM vault, multi-tenant `doctorId` firewall, `isPrivate` exclusion) | Swap to Firebase Auth + Cloud Functions + Firestore (Blaze plan) with strict `clinicId`/`doctorId` tenant rules and zero server-side visibility of `isPrivate == true` entries |
| **In-Room Patient -> Psychiatrist Handoff (`MF-CLINIC-V1:`)** | 100% offline / QR / copy | Zero server transmission; gzip + PBKDF2-SHA256 + AES-256-GCM + SHA-256 check |
| **Post-Visit Focus Plan (`MF-CAREPLAN-V1:` & Clinic Inbox Push)** | Auto-pushed into Clinic Inbox + optional offline QR | Delivered automatically upon Patient sync (`pullInboxUpdates`) without manual code copy/paste |
| **Printable A4 Brief PDF & Native Share Sheet** | Offline PDF 1.4 synthesis | Local temp/file write + OS share sheet (`SharePlus.instance.share`) |
| **Live AI Companion / Deconstruction** | Local `MockInvestigatorService` | Paid-tier backend proxy (`AI_PROXY_URL`), gated by explicit consent & `isPrivate` block |

---

## 3. Privacy, Consent & Regulatory Posture (Tunisia INPDP / EU GDPR)

- [ ] **Hard Vault Isolation (`isPrivate == true`):** Confirm private check-ins and Talk sessions are excluded across `ClinicianSyncService.buildPatientPacket`, `LocalClinicSimulatorRepository.syncPatientSnapshot`, `ClinicianSyncPacket.fromJson`, `ForensicLoopLink.synthesize(excludePrivateCases: true)`, `generateEhrClinicalNote`, and `ClinicalBriefPdfService`.
- [ ] **Doctor Admin Multi-Tenant Isolation:** Confirm Doctor A cannot query, reset PINs for, pause, or read dossiers belonging to Doctor B (`ClinicAuthErrorCode.unauthorizedDoctor`), and signed-out patients wipe cached session tokens (`mf_signed_out` + `mf_last_checkin_cache_v1`).
- [ ] **Patient App Minimalism Gate:** Verify Patient UI contains zero manual JSON backup buttons, zero AI API/proxy settings (`AiEngineConfigSheet`), zero public self-signup/anonymous bypasses, and zero clinician workspace toggles.
- [ ] **Observational Non-Diagnostic Language Audit:** Verify all UI copy, PDF briefs, and EHR exports stay strictly descriptive (`inspired by CBT`), with zero medical diagnoses, zero diet/weight advice, and zero predictions of relapse.
- [ ] **Local Key Rotation & Purge:** Test biometric app lock (`local_auth`), PIN rotation (`changePatientPin` + Doctor `resetPatientAccess`), and double-confirmed local wipe flows.

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

## 6. Clinic v2 End-to-End Demo Script (Doctor Admin + Patient Auto-Sync)

1. **Seconds 0–15 (Doctor Provisions Account):** Launch **Mindora Doctor Edition** (`lib/main_clinician.dart`) -> tap **+ Add patient** -> enter Name, Phone/Username, Age group (e.g., `65+` auto-enables Larger Text & Daylight clarity), and Care Tracks -> tap **Create account & QR** to display the single-use `MF-INVITE-V1:` QR and one-time 6-digit PIN.
2. **Seconds 15–30 (Patient Scans & Enters Sanctuary):** On **Mindora Patient Edition** (`lib/main.dart`), tap **Scan doctor's QR** (or enter PIN) -> review the one-time connected doctor & safety banner (`Not a 24/7 emergency monitor`) -> tap **Start my day**.
3. **Seconds 30–45 (Effortless Daily Tracking + `Keep just for me`):** Tap a MoodFace mood chip -> log Sleep/Energy or a quiet Talk -> optionally toggle **Keep just for me** on any private Track entry or Talk session so it stays strictly on the patient's phone while everything else auto-syncs quietly (`Synced`).
4. **Seconds 45–60 (Doctor Dossier Review & Automatic Care Plan Push):** Open the patient's dossier in Doctor Edition (`Reset PIN & QR`, `Pause / Resume access`, `Edit focus areas`) -> compose a Between-Session Focus Plan and tap **Send to patient** so it arrives automatically on Patient Home.
