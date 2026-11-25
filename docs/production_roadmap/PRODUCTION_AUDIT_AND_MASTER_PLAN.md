# Mindora — Multi-Perspective Visual Audit & Commercial Production Master Plan

> Grounded in 14 live rendered screenshots across Patient (Amel 68yo AR RTL 320px + Yassine 19yo EN/FR Light & Dark) and Doctor (Dr. Salma Psychiatrist Roster + Patient Dossier Light & Dark).

## Summary of 5 Production Pillars

1. **Phase A — Clean Vercel Dark Mode (Zero Purple!) & P0 Visual Bug Fixes**
   - Replace `MindTokens.dark` purple indigo (`#1B1530` / `#261E42` / `#B7A2FF`) with clean Vercel Obsidian-Zinc (`bg: #09090B`, `surface: #111114`, `surface2: #18181C`, `ink: #FAFAFA`, `ink2: #A1A1AA`, `primary: #FAFAFA`, `onPrimary: #09090B`).
   - Remove purple primary (`#6A3DE8`) and lilac heavy mood (`#B79CFF`) from Light mode too (replace with crisp Carbon `#111114` or Deep Teal `#0D9488` primary + Cool Slate `#94A3B8` for `heavy`).
   - Fix all 6 visual bugs caught in screenshots:
     1. `TrackMonthCalendar` selected Day `24` invisible dark-on-dark text.
     2. `SettingsScreen` header showing `"Access Your Account"` when `preferredName` is empty + clinical copy (`Visual Environment`, `Clinical Language`).
     3. `ObservedStabilizersCard` displaying confusing `"avg mood 3.0/10"` inverted intensity label.
     4. `FlashCaseScreen` 57px horizontal overflow at `320px` AR RTL.
     5. `AuthScreen` ALL CAPS `"SIGN IN"` & clinical subtitle.
     6. `MoodFace` `heavy` eyebrows softened + Arabic comma `،` in `HomeScreen`.

2. **Phase B — Adaptive Multi-Question First-Time Onboarding & Decision Engine**
   - 6-step options-first onboarding (<45s, zero compulsory typing):
     1. Language (`العربية (تونس)`, `Français`, `English`) + Light/Dark + `Aa Normal / AA Larger text`
     2. Role Gate: **Patient / Individual** vs **Doctor / Psychiatrist** (routes Doctors straight to `/clinician`!)
     3. Age Group (`Under 18` safeguard, `18-24`, `25-44`, `45-64`, `65+` auto-recommends Larger Text)
     4. Main Goals (multi-select cards)
     5. Care Context (followed by doctor or self-care) + Main Focus Areas (sleep, energy, stress, overthinking, routine)
     6. First 2-Tap Mood Check-in + Personalized Ready Summary
   - `AppPersonalizationEngine` configures initial route, daily Home clinical questions, comfort mode, and next-step recommendations automatically.

3. **Phase C — Clinically High-Value Daily Home Check-In Pattern (`Today`)**
   - Stage 1 (<5s): 2-tap `MoodFace` + 3-step strength (`A little / Medium / A lot`).
   - Stage 2 (10s, right on Home, 1-tap pills, skip anytime, time-of-day adaptive):
     - **Morning (05:00–13:59):** Last Night's Sleep (`<5h / 5–6h / 7–8h / 9h+` + quality chip) + Morning Energy (`Drained / Low / Steady / High-Wired`).
     - **Afternoon / Evening (14:00–04:59):** Stress Load + Main Stressor chip + What Helped chip + optional neutral Routine / Care Plan check (only if user opted in).
   - Feeds directly into Patient Patterns AND Doctor 7-Day vs. Baseline Table, Diurnal Shift, Sleep-Mood correlation, and A4 Clinical Brief PDF.

4. **Phase D — Doctor Version Elevation & Commercial B2B SaaS Roadmap**
   - Surface existing `lib/features/clinician/` (`ClinicianShellScreen`, `ClinicianPatientDetailScreen`, `ClinicalBriefPdfService`, `ComposePostVisitFocusSheet`) directly from Onboarding & Auth.
   - Upgrade Doctor UI with Vercel Dark/Light, 7-day Sleep+Mood sparklines on roster cards, factual shift chips (never relapse prediction), structured SOAP-lite consultation notes, and verified tablet/desktop split-pane layout.
   - Commercial SaaS Tier 2 Roadmap: E2EE cloud sync (Firebase Blaze + spend caps), Gemini Paid Tier compliance gate (`AGENTS.md` Rule 1), clinic multi-seat licensing, audit trails, and INPDP/GDPR privacy posture.

5. **Phase E — Visual Re-Audit & Zero-Regression Gate**
   - Re-capture all 14+ Light, Vercel Dark, Amel 68yo AR RTL, and Doctor Portal screenshots, inspect visually, and verify `flutter analyze --no-pub` (`0 issues`) + full `flutter test` (`100% green`).
