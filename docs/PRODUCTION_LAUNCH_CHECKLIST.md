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
