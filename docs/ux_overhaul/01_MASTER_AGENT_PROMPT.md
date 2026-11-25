# Mindora — Master Autonomous Agent Prompt & Complete UX/UI Overhaul Execution Plan

> **Purpose:** Copy-paste the prompt inside **Section 1** directly into your implementation agent (Claude Code, Antigravity, Cursor, or Codex), or instruct that agent:
> `"Read docs/ux_overhaul/01_MASTER_AGENT_PROMPT.md and execute Phases 9 through 13 end-to-end."`
>
> Every single screen, widget, popup (`187 callsites`), jargon string (`83 rewrites`), inline hardcoded string (`~94 ternaries`), local notification, permission flow, accessibility rule, and test contract (`68 test files`) across all **200 Dart files** in `lib/` has been pre-audited and specified in `docs/ux_overhaul/`.

---

## Architecture & Spec Map (`docs/ux_overhaul/`)

| Document | Exact Coverage |
| :--- | :--- |
| [`00_research_and_rules.md`](00_research_and_rules.md) | Dual-generation personas (**Amel 68** low mobile literacy & **Yassine 19** Gen Z), WCAG 2.2 / Material 3 Expressive / Hick's Law research, Sunrise & Twilight contrast math, 6 living `MoodFace` specs, Grade-6 trilingual copy rules, popup decision matrix. |
| [`specs/01_design_system_sunrise_and_mood_faces.md`](specs/01_design_system_sunrise_and_mood_faces.md) | Full `MindTokens` Sunrise (`#FFF8F0` default light) & Twilight (`#1B1530` optional night) hex/alpha table, `ThemeMode.light` fresh-install default, vector `MoodFace` `CustomPainter` + spring/blink/bloom (`reduceMotion`-safe), `56dp` violet `MindButton`, `MindUndoBanner`, `>= 12sp` floor, token test updates. |
| [`specs/02_navigation_onboarding_and_auth.md`](specs/02_navigation_onboarding_and_auth.md) | 5-tab single-job dock (`Today`, `My days`, `Talk`, `Patterns`, `Me`), `<25s` 3-step onboarding (`<45 words`, live `Normal / Larger text` preview, first 2-tap check-in), `LocaleController`, `AuthScreen`, `LockOverlay`, human Grade-4 `SafetyInterceptor` crisis modal, `GentleReminderService` pre-permission sheet. |
| [`specs/03_today_and_my_days_single_job_split.md`](specs/03_today_and_my_days_single_job_split.md) | Single-Job Split: `Today` (`HomeScreen`: 2-tap `MoodFace` + `A little / Medium / A lot` auto-save in `<5s`, `<= 32 words` above fold, mood color flood, reward bloom) vs. `My days` (`TrackScreen`: deletes duplicate check-in form tab, opens directly to colored `MoodFace` Month Calendar + Day Timeline, `ProgressiveDetailsSheet` 1-question-per-card optional sleep/energy/tags/note). |
| [`specs/04_talk_toolbox_patterns_me_and_clinician.md`](specs/04_talk_toolbox_patterns_me_and_clinician.md) | `Talk` (collapse 4 bars -> 1 `56dp` AppBar, 4 starter cards, reply chips, plain `Fact / Guess / Worry story` + 6 thinking traps, `Talk summary`), `Relief & Toolbox` (`22sp` breathing cues, 5-4-3-2-1 tap counter, fix missing FR bug), `Patterns` (`<= 38w` 3-card top fold + `"See more details"` drawer + Sunrise/Twilight Mood Colors Poster), `Me` (5 calm cards + Dry-Run Backup Restore), and `Psychiatrist Workspace`. |
| [`specs/05_complete_popups_notifications_and_microcopy_bible.md`](specs/05_complete_popups_notifications_and_microcopy_bible.md) | Complete table of **all 187 popup/dialog/sheet/snackbar callsites**, **all 83 jargon & >16-word `app_strings.dart` rewrites** (EN / FR / Tunisian AR), **all ~94 inline hardcoded UI strings** to migrate into `app_strings.dart`, 4 zero-guilt notification templates, OS pre-permission sheets, and all `lib/core/widgets/**` rules. |

---

## Section 1 — Copy-Paste Autonomous Agent Master Prompt

````markdown
# ROLE & MISSION: MINDORA COMPLETE CROSS-GENERATIONAL UX/UI OVERHAUL (PHASES 9–13)

You are a Principal Flutter Product Designer, Accessibility Architect, and Staff Engineer working in `d:\Projects\mind_forensics` (Windows, PowerShell).

Your mission is to execute a complete, zero-regression, zero-omission **UX, Visual Design, Interaction, Popup, and Plain-Language Microcopy Overhaul** of **Mindora** across **5 sequential phases (16 atomic milestones: M9.1 -> M13.3)**, automatically advancing from one milestone to the next ONLY after auditing your own work and passing `flutter analyze --no-pub` + `flutter test` with zero issues.

---

## 1. WHY WE ARE DOING THIS (THE PRODUCT NORTH STAR)

Mindora currently suffers from four critical UX failures that you MUST eliminate completely:
1. **Text & Clinical Jargon Overload:** Screens have up to 56 `Text` widgets (`insights_screen.dart`), 55 `Text` widgets (`settings_screen.dart`), clinical/police jargon (*Investigator, Observatory, Vagal Box Pacing, Somatic Arousal, Activating Catalyst, Cognitive Distortions, Personal Baseline, Observed Stabilizers, Forensic Loop*), 83 jargon/long getters in `app_strings.dart`, and ~94 hardcoded inline `isArabic`/`isFrench`/English strings scattered outside `app_strings.dart`.
2. **Dark "Death UI" Default:** `ThemeMode.system` boots dark-mode phones into `#000000` pure pitch black, and Light mode (`#F5F6FA`) looks like cold hospital grey-blue with tiny monochrome icons. Tracking feels like medical homework instead of a warm, alive, joyful 5-second ritual.
3. **Duplicate Jobs Across Tabs:** Both `Home` AND `Track` Tab 0 render competing daily check-in forms with 1–10 sliders and blank text boxes, hiding the Month Calendar behind a sub-tab.
4. **Two Generations Must Both Love This App Simultaneously:**
   - **Persona A — Amel / Hedi (Age 68–75, low smartphone literacy, presbyopia, reads Tunisian Arabic or French):** Needs instant visual clarity, `>= 56dp` primary buttons (`>= 48dp` everywhere else, `12dp` gap), `16sp` default / `18.5sp` Larger Text (`12.0sp` hard floor, sentence case, `1.5` line height), zero hidden swipe-only actions, 1 question per card, forgiving 6-second `[Undo]` banners, and layouts that NEVER clip or overflow at `320px` width + `200%` text scale + Arabic RTL.
   - **Persona B — Yassine / Lina (Age 18–24, Gen Z, high digital fluency, hates forms & streak guilt):** Needs a **sub-5-second 2-tap check-in**, warm alive **`Sunrise` colors**, expressive **drawn vector `MoodFace` characters** (squish on press, blink, breathe, soft background color flood, radial save bloom — **ZERO Unicode emojis**), a shareable **Mood Colors Poster**, and zero day-streak shame.

---

## 2. MANDATORY READING BEFORE WRITING ANY CODE

Before starting Milestone `M9.1`, read these specification files in full:
1. `AGENTS.md`
2. `docs/ux_overhaul/00_research_and_rules.md`
3. `docs/ux_overhaul/specs/01_design_system_sunrise_and_mood_faces.md`
4. `docs/ux_overhaul/specs/02_navigation_onboarding_and_auth.md`
5. `docs/ux_overhaul/specs/03_today_and_my_days_single_job_split.md`
6. `docs/ux_overhaul/specs/04_talk_toolbox_patterns_me_and_clinician.md`
7. `docs/ux_overhaul/specs/05_complete_popups_notifications_and_microcopy_bible.md`

Treat `docs/ux_overhaul/**` as your binding engineering contract. Do NOT invent alternate colors, skip files, leave inline strings behind, or improvise jargon copy.

---

## 3. NON-NEGOTIABLE GUARDRAILS (ENFORCE ON EVERY MILESTONE)

1. **`AGENTS.md` Directive 6 Alignment First:**
   - In `M9.1`, update `AGENTS.md` Directive 6 FIRST to replace the retired `#000000` Vercel Dark palette rule with the approved **`Sunrise` Warm Daylight Default (`#FFF8F0` ground, `#FFFFFF` card, `#FFF0E3` surface2, `#2B2140` warm plum ink `14.3:1`, `#6A3DE8` alive violet primary `6.09:1`, `16–20dp` card radius)** and **`Twilight` Deep Indigo Night Mode (`#1B1530` ground, `#261E42` card, `#F7F3FF` ink `15.7:1`, `#B7A2FF` soft lavender primary `8.04:1` — NEVER `#000000`)**.
2. **Strictly Forbidden (`AGENTS.md` Rules 1, 4, 5, 8, 9):**
   - **NO EMOJIS IN UI** (`MoodFace` custom vector painter & outline/duotone icons ONLY — zero Unicode emojis in widgets, buttons, sheets, badges, or `app_strings.dart`).
   - **NO clinical overreach:** Never use *"therapy"* or *"CBT treatment"* (always *"inspired by CBT"*); never predict relapse; never add diet/calorie/weight advice.
   - **Spark / MockAI Cost Rule:** Keep `MockInvestigatorService` (offline free test mode) as the default AI engine; develop strictly on free Firebase Spark with billing unlinked; preserve/remind of the paid Gemini tier requirement before real user rollout (Steps 10 & 14).
   - **Safety & Crisis Gate Intact:** Never weaken or bypass `CrisisKeywords.evaluateText` or `SafetyInterceptor.showCrisisPauseDialog`. Keep Tunisian emergency numbers **`80 10 50 50`** (Ligne Verte), **`190`** (SAMU), and **`198`** (Protection Civile) 1-tap callable at all times.
   - **Backward-Compatible Persistence & Clinical Schemas:**
     - `MindTraceModel.moodIntensity` MUST remain `int` `1–10` in JSON/storage (`A little -> 3`, `Medium -> 6`, `A lot -> 9`; when displaying existing 1–10 values: `1..4 -> A little`, `5..7 -> Medium`, `8..10 -> A lot`).
     - `CaseModel.toJson()/fromJson()`, `PsychologicalProfileModel`, `UnifiedBackupService`, `MF-CLINIC-V1:`, `MF-CAREPLAN-V1:`, and `isPrivate` case exclusion MUST remain 100% backward-compatible.
3. **Hard Quantitative UX Budgets:**
   - **Check-in speed:** `Today` check-in completes & persists in **2 taps (`< 5 seconds`)** with **0 required typing**.
   - **Word budgets:** Headlines `<= 9 words`; body/helper `<= 14 words`; buttons `1–3 words` (outcome-named); `Today` above-fold `<= 32 words`; `Patterns` above-fold `<= 38 words`; Onboarding total across all 3 steps `<= 45 words`.
   - **Touch & Type floors:** Primary CTAs `>= 56dp` height; all other interactive targets `>= 48dp x 48dp` with `>= 8–12dp` spacing; body `16sp` (`18.5sp` Larger Text); **hard floor `12.0sp`** (zero `9sp`, `10sp`, `11sp` anywhere); sentence case (ban `ALL CAPS` blocks); `MediaQuery.disableAnimationsOf(context)` honored on every animation.
   - **Trilingual Parity (`EN` / `FR` / Tunisian `AR`):** 100% of user-facing strings live in `lib/app/localization/app_strings.dart` via `ref.watch(appStringsProvider)`. Zero hardcoded English or inline `isArabic ? ... : ...` UI strings in widgets/services.
4. **Self-Audit & Verification Protocol After EVERY Milestone:**
   - In Windows PowerShell, run:
     ```powershell
     flutter analyze --no-pub; if ($?) { flutter test }
     ```
   - Perform a structured **Self-Audit Check** before moving to the next milestone:
     1. *Did I hit every file and requirement in the spec for this milestone?*
     2. *Could a 70-year-old user at `320px` + `2.0x` Arabic RTL tap every button without reading fine print or hitting overflow?*
     3. *Would a 19-year-old Gen Z user find this screen bright, alive, fast, and guilt-free?*
     4. *Are `flutter analyze --no-pub` (`0 issues`) and `flutter test` (`100% passing`) green?*
   - Commit each completed phase/milestone cleanly with descriptive commit messages, then **auto-advance immediately** to the next milestone until `M13.3` is complete.

---

## 4. SEQUENCED EXECUTION PLAN (5 PHASES · 16 ATOMIC MILESTONES)

### PHASE 9 — Alive `Sunrise` & `Twilight` Design System, `MoodFace` Characters & Plain Copy Foundation
*(Reference: `Spec 01` & `Spec 05 Parts 2–4`)*

- **Milestone `M9.1` — `Sunrise` Default Light & `Twilight` Deep Indigo Token Overhaul:**
  - Update `AGENTS.md` Directive 6 first.
  - Update `lib/app/theme/mind_tokens.dart`, `lib/app/theme/lab_theme.dart`, `lib/app/theme/lab_colors.dart`, `lib/app/theme/theme_controller.dart` (fresh-install default -> `ThemeMode.light`!), `lib/app/theme/display_comfort_controller.dart`, `lib/main.dart`, and `lib/core/widgets/ambient_scaffold.dart` to the exact WCAG-verified `Sunrise` and `Twilight` palettes in `Spec 01 §2.2` (Note: never put `#FFFFFF` text on `#7C5CFF` `4.35:1`; use `#6A3DE8` `6.09:1` in Sunrise and `#1B1530` ink on `#B7A2FF` `8.04:1` in Twilight!).
  - Enforce the `12.0sp` minimum typography floor and sentence-case styles in `lab_theme.dart`.
  - Update hex/theme assertions in `test/theme_tokens_contrast_test.dart`, `test/comfort_mode_and_phase7_vqa_test.dart`, and `test/contact_sheet_generator_test.dart` (asserting WCAG `>= 4.5:1` text and `>= 3.0:1` UI contrast across every Sunrise & Twilight pair).
- **Milestone `M9.2` — Living Vector `MoodFace`, `MindUndoBanner` & Core Widget Primitives:**
  - Create `lib/core/widgets/mood_face.dart`: custom drawn vector `MoodFace` character (`Good / Happy`, `Calm`, `Worried / Anxious`, `Annoyed / Angry`, `Low / Sad`, `Restless / Stressed` — zero emojis!) with gentle idle blink/breathing, press squish spring, selection bounce, `Semantics`, and full `MediaQuery.disableAnimationsOf(context)` static rendering.
  - Create `lib/core/widgets/mind_undo_banner.dart`: floating `56dp` reversible-delete banner (`6s` default timeout, `15s` when `MediaQuery.accessibleNavigationOf(context)` is true, `48dp` `[Undo]` pill, `SemanticsService.announce`).
  - Upgrade `mind_button.dart` (`56dp` primary violet CTA), `mind_card.dart` (`16–20dp` radius, warm elevation), `mind_chip.dart` & `mind_pill.dart` (`48dp` min touch height), `mind_segmented.dart` (`48dp`), `mind_sheet.dart` (`24dp` top radius + visible `48x48dp` `[X]` close button), `mind_switch.dart`, `mind_toast.dart` (`2.5s` clean pill), `mind_pressable.dart`, `mood_emblem.dart` (delegate to `MoodFace` or warm vector tint), `mind_intensity_picker.dart` (3-button `A little / Medium / A lot` default), `label_badge.dart` & `mind_badge.dart` (`>= 12sp`), `mind_qr_code.dart` (always `#FFFFFF` quiet zone), `quick_note_sparks_bar.dart` (`48dp`), `smooth_spline_chart.dart` (screen-reader `Semantics`), `botanical_emblem.dart`, `bouncing_widget.dart`, `fingerprint_thread_signature.dart`, and `icon_blob.dart`.
  - Add widget unit tests for `MoodFace` (all 6 moods, tap semantics, `disableAnimations: true`) and `MindUndoBanner` (undo callback vs timer commit).
- **Milestone `M9.3` — Complete Jargon & Long-String Overhaul in `app_strings.dart` + Copy Lint Gate:**
  - Apply **all 83 jargon & long-string rewrites** from `Spec 05 Part 2` in `lib/app/localization/app_strings.dart`, plus add all new plain-language getters needed across Specs `02–05` in **English (`en`), French (`fr`), and natural Tunisian-friendly Arabic (`ar`)**.
  - Create `test/ux_copy_and_word_budget_lint_test.dart` asserting: (a) zero Unicode emojis in `app_strings.dart` and `lib/**`, (b) zero banned patient-facing jargon words (*somatic, vagal, catalyst, distortion, granularity, attunement, forensic, observatory, dossier, empirical*), and (c) EN/FR/AR non-empty parity across every `AppStrings` getter.

---

### PHASE 10 — Single-Job Navigation, `<25s` Onboarding, Auth, Lock & Human Crisis Care
*(Reference: `Spec 02` & `Spec 05 Parts 1, 4`)*

- **Milestone `M10.1` — 5-Tab Single-Job Bottom Dock & Router Polish:**
  - Update `lib/app/router/scaffold_with_nav_bar.dart`, `lib/app/router/app_router.dart`, and `lib/app/localization/locale_controller.dart`:
    - 5 clear tabs (`68dp` height, always-visible `12.5sp w700` labels, warm violet pill indicator, zero red badges): **`Today`** · **`My days`** · **`Talk`** · **`Patterns`** · **`Me`**.
- **Milestone `M10.2` — Sub-25-Second 3-Step Onboarding (`<= 45 Words` Total):**
  - Overhaul `lib/features/onboarding/presentation/onboarding_screen.dart`:
    - **Step 1 (`Welcome`):** Language pills (`العربية` / `Français` / `English`) + live **`Normal text` / `Larger text`** preview cards (`DisplayComfortController`) + 1-line privacy & `"inspired by CBT"` trust promise -> `Start`.
    - **Step 2 (`About You`, `Skip` top-end):** 4 big `52dp` age-group tiles (`Under 18` shows warm minor safety card, `18–24`, `25–54`, `55+` auto-suggests `Larger text` if not chosen!) + optional name field (`Skip` anytime).
    - **Step 3 (`First 2-Tap Check-In`):** *"How are you right now?"* -> 6 living `MoodFace` tiles + `A little / Medium / A lot` -> saves real first `MindTraceModel` with bloom animation and lands on a warm, populated `Today` screen!
  - Update `test/onboarding_and_disclaimer_test.dart` and `test/minor_safeguards_and_age_tone_test.dart`.
- **Milestone `M10.3` — Plain-Language `AuthScreen`, `LockOverlay`, `SafetyInterceptor` & Gentle Reminders:**
  - Overhaul `lib/features/auth/presentation/auth_screen.dart` (make **`Continue privately on this phone`** the unmistakable hero path; collapse email/cloud sync cleanly; migrate inline `L113` SnackBar).
  - Polish `lib/core/security/lock_overlay.dart` (`64dp` keypad buttons, `48dp` biometric button, gentle inline error + `MindToast`).
  - Upgrade `lib/core/safety/safety_interceptor.dart` & `lib/core/safety/support_button.dart` to Grade-4 human warmth (`Pause — you matter`, `56dp` 1-tap call buttons for **`80 10 50 50`**, **`190`**, **`198`** + **`Open calm breathing`** + **`I am safe right now`**).
  - Upgrade `lib/core/notifications/gentle_reminder_service.dart` with the 4 rotating zero-guilt EN/FR/AR messages and pre-permission `MindSheet`.
  - Verify `test/safety_interceptor_test.dart`, `test/auth_screen_test.dart`, and `test/app_lock_test.dart` pass 100%.

---

### PHASE 11 — The Core Single-Job Split: `Today` (2-Tap Check-In) vs. `My days` (Calendar & History Only)
*(Reference: `Spec 03`)*

- **Milestone `M11.1` — `Today` (`HomeScreen`) Sub-5-Second 2-Tap Check-In:**
  - Redesign `lib/features/home/presentation/home_screen.dart`, `home_daily_check_in_card.dart`, `home_weekly_rhythm_card.dart`, `home_post_visit_focus_card.dart`, `home_active_case_card.dart`, and `home_organic_exercise_art.dart`:
    - Remove inline blank `TextField`, note sparks bar, 1–10 slider, and `RECENT SESSIONS` clutter from `Today` (`<= 32 words` above the fold!).
    - Render the 6 animated `MoodFace` tiles (`3x2` grid; auto-adapts to `2x3` at `<350px` or `textScale > 1.25`).
    - Tapping a `MoodFace` softly tints the card with its mood wash and reveals **`How strong?`** -> **`[ A little ]` (`3`) · `[ Medium ]` (`6`) · `[ A lot ]` (`9`)** (`56dp` pills; vertical stack at `<340px` or `textScale > 1.3`).
    - Tapping strength **auto-saves immediately** with haptic + radial bloom (`reduceMotion`-safe) and transitions to the **Logged Today Card** (`MoodFace`, 1-line `CheckInMicroMirror`, `+ Add sleep, tags or a note` button, `Breathe` / `Talk it out` buttons, `Change` / `+ Log new moment`).
    - Keep `HomeWeeklyRhythmCard` (7 colored `MoodFace` dots, zero `/7` quota or streak shame), 1 `Take a 1-minute breather` card, and `HomePostVisitFocusCard` (when a doctor's plan is active).
- **Milestone `M11.2` — `ProgressiveDetailsSheet` (1 Question Per Card, Zero Sliders):**
  - Create `lib/features/track/presentation/widgets/progressive_details_sheet.dart`:
    - 4 optional swipe/tap cards with `Skip` (`48dp`) on every card and `Done` anytime:
      1. Closer feeling word (`AffectTaxonomy` `48dp` pills)
      2. Sleep (`Under 6h / About 7h / About 8h / 9h+`) & Energy (`Low / Okay / Full`) `52dp` tiles
      3. Today's context & What helped (`48dp` icon+word tiles)
      4. Quick note (`QuickNoteSparksBar` + optional 2-line `TextField` gated by `CrisisKeywords.evaluateText`).
- **Milestone `M11.3` — `My days` (`TrackScreen`) Visual Calendar & Timeline Overhaul:**
  - Refactor `lib/features/track/presentation/track_screen.dart` (down from 2,347 lines!), `track_month_calendar.dart`, `track_mood_picker.dart`, `track_mood_utils.dart`, `track_entry_detail_sheet.dart`, `daily_mind_trace_stepper.dart`, `thought_trace_detail_sheet.dart`, `trace_entry_detail_sheet.dart`, and `trace_investigation_sheet.dart`:
    - **Delete the duplicate `"Check-In Today"` tab from `TrackScreen`!** `My days` opens **directly** into the vivid colored **`MoodFace` Month Calendar + Selected Day Timeline**.
    - Tapping any past/today calendar cell shows that day's entries below (or `+ Add check-in for this day`).
    - Convert single-entry delete `AlertDialog`s in `track_entry_detail_sheet.dart:60` and `thought_trace_detail_sheet.dart:134` to **`MindUndoBanner` (6s)**.
    - Migrate all remaining inline strings (`track_screen.dart:510`, `daily_mind_trace_stepper.dart`, `thought_trace_detail_sheet.dart`, `trace_investigation_sheet.dart`) to `app_strings.dart`.
  - Add `test/today_and_my_days_single_job_test.dart` verifying 2-tap auto-save, calendar-first `My days`, `ProgressiveDetailsSheet` skip flow, `MindUndoBanner` restore, and zero overflow at `320x640` `2.0x` AR RTL.

---

### PHASE 12 — Calm `Talk`, Plain `Relief & Toolbox`, and Progressive `Patterns`
*(Reference: `Spec 04 Sections A–C` & `Spec 05 Parts 1, 3`)*

- **Milestone `M12.1` — `Talk` Tab De-Clutter & Plain CBT Companion:**
  - Overhaul `flash_case_screen.dart`, `live_dialogue_view.dart`, `ai_companion_hub_view.dart`, `companion_context_bridge_card.dart`, `vagal_breathing_visualizer.dart`, `mode_chooser_sheet.dart`, `ai_engine_config_sheet.dart`, `custom_ai_instructions_sheet.dart`, `voice_dictation_button.dart`, `journal_memory_sheet.dart`, `case_report_screen.dart`, `clinical_export_preview_sheet.dart`, `clinical_export_service.dart`, `clarity_anchor_card.dart`, `reframe_drill_card.dart`, `quick_calm_breathing_sheet.dart`, and `mock_investigator_service.dart`:
    - Collapse 4 top bars into **1 clean `56dp` AppBar**: `Talk`, `[Saved (N)]`, `[...]` (`More` `MindSheet`), and `[Help]`.
    - Empty/new talk state shows **4 warm `56dp` starter cards** (`Overthinking something`, `Heavy feeling I can't name`, `Tension with someone`, `Just need to let it out`) + 3 tappable suggested reply chips after AI turns.
    - Move `Fact / Guess / Worry story` + 6 plain **Common thinking traps** into `+ Tag thought` `MindSheet`.
    - Eliminate the `"New talk title"` `AlertDialog` (`ai_companion_hub_view.dart:44` — start immediately & auto-title!), convert single-talk delete `AlertDialog`s (`ai_companion_hub_view.dart:174`, `case_report_screen.dart:182`) to **`MindUndoBanner` (6s)**, fix the English-only SnackBar bug (`custom_ai_instructions_sheet.dart:90`), and add microphone pre-permission `MindSheet` to `VoiceDictationButton`.
- **Milestone `M12.2` — `Relief & Toolbox` Plain-Word Calm Exercises & Bug Fixes:**
  - Overhaul `contextual_support_sheet.dart`, `breathing_exercise_card.dart`, `grounding_exercise_card.dart`, `micro_action_card.dart`, `perspective_exploration_card.dart`, `routine_anchor_card.dart`, `relief_micro_check_card.dart`, `inner_observatory_screen.dart`, `add_discovery_sheet.dart`, `custom_perspective_sheet.dart`, `custom_symptom_sheet.dart`, `symptom_assessment_sheet.dart`, `symptom_library_view.dart`, and `journey_activity_detail_screen.dart`:
    - Plain exercise titles (`Slow breathing · 1 min` with `22sp` cues, `Look around you · 5-4-3-2-1` interactive tap counter, `One tiny step`).
    - Fix missing French translation bug in `symptom_assessment_sheet.dart:114`, replace 1–10 symptom slider with `Mild / Moderate / Strong` `56dp` buttons, convert discovery/symptom delete `AlertDialog`s (`inner_observatory_screen.dart:589`, `symptom_library_view.dart:37`) to **`MindUndoBanner` (6s)**, and migrate all inline strings to `app_strings.dart`.
- **Milestone `M12.3` — `Patterns` Progressive Disclosure & Dual-Theme `MoodAuraPosterSheet`:**
  - Overhaul `insights_screen.dart`, `observed_stabilizers_card.dart`, `forensic_loop_map_card.dart`, `discovery_milestones_card.dart`, `mood_aura_poster_sheet.dart`, `progress_analytics_service.dart`, `progress_analytics_model.dart`, and `pattern_awareness_service.dart`:
    - Top fold (`<= 38 words`!): **Card 1 (`Your week` 1-line human summary + 7 `MoodFace`s)**, **Card 2 (`What helps you feel better` top 3 chips)**, **Card 3 (`Your Mood Colors Poster` vivid preview CTA)** + **`[ See more details ]`** `52dp` expandable button housing `How a tough moment unfolds` (`ForensicLoopMapCard`), `Sleep & energy`, and `Your usual rhythm` + `Milestones`.
    - Add **`Sunrise Warm` / `Twilight Indigo`** style toggle inside `MoodAuraPosterSheet`.
    - Update `test/phase5_stabilizers_loop_and_brief_test.dart`, `test/phase6_relief_loop_and_care_bridge_test.dart`, `test/phase7_delight_and_comfort_test.dart`, and add `test/talk_and_patterns_progressive_ux_test.dart`.

---

### PHASE 13 — Calm 5-Card `Me`, Doctor Handoff Polish & Final Dual-Persona Visual QA Gate
*(Reference: `Spec 04 Sections D–E` & `Spec 05`)*

- **Milestone `M13.1` — `Me` Tab 5-Card Reorganization & Safe File Backup/Restore:**
  - Refactor `settings_screen.dart`, `clinical_sharing_history_sheet.dart`, `psychological_profile_screen.dart`, `psychological_profile_view.dart`, `condition_status_bottom_sheet.dart`, all `edit_*_sheet.dart` files, and `privacy_management_sheet.dart`:
    - Organize `Me` into **5 calm cards**: (1) *Look & Reading* (`Sunrise / Night / Auto`, `Normal / Larger text`, `EN / FR / العربية`), (2) *About Me & Reminders*, (3) *Doctor Visit*, (4) *Privacy, Lock & Backup*, and (5) collapsed *For clinicians & advanced* accordion.
    - Replace raw JSON clipboard backup/restore `AlertDialog`s (`settings_screen.dart:144,299`) with clean **`MindSheet` flows featuring File Share/Pick + mandatory Dry-Run Preview (`"Found X check-ins and Y talks. Restore?"`)** before overwriting, while keeping text-code fallback and 2-step `Erase Everything` confirmation (`[Delete everything forever]` vs `[Cancel — keep my data]`).
    - Migrate every inline string in `settings_screen.dart`, `condition_status_bottom_sheet.dart`, `edit_experiences_sheet.dart`, and `privacy_management_sheet.dart` into `app_strings.dart`.
- **Milestone `M13.2` — `Doctor Visit` & `Psychiatrist Workspace` Sunrise/Twilight Upgrade:**
  - Polish `pre_visit_brief_sheet.dart`, `share_with_psychiatrist_sheet.dart`, `import_care_focus_sheet.dart`, `mind_qr_scanner_sheet.dart` (add camera pre-permission prompt + paste-code fallback), `clinician_shell_screen.dart`, `clinician_patient_detail_screen.dart`, `clinical_brief_preview_sheet.dart`, `compose_post_visit_focus_sheet.dart`, and `import_patient_packet_sheet.dart`.
  - Keep `MindSegmented`, `MF-CLINIC-V1:`, `MF-CAREPLAN-V1:`, and `isPrivate` stripping 100% intact; verify `test/clinician_portal_and_handoff_test.dart` passes completely.
- **Milestone `M13.3` — Final Zero-Omission Repo Sweep & Dual-Persona Visual QA Suite:**
  - Expand `test/ux_copy_and_word_budget_lint_test.dart` to scan **all `lib/**.dart` files** and assert:
    1. **0 hardcoded inline UI `isArabic` / `isFrench` string ternaries** remain outside `lib/app/localization/app_strings.dart` (allowlisting only `letterSpacing` / `TextDirection` layout helpers and data catalog models).
    2. **0 font sizes `< 12.0`** remain anywhere in `lib/features/**` or `lib/core/widgets/**`.
    3. **0 `#000000` (`Colors.black` background)** surfaces remain in `lib/**` (excluding shadow alpha overlays).
  - Create `test/ux_dual_persona_vqa_golden_test.dart` (modeled on `test/contact_sheet_generator_test.dart`) that renders and verifies **zero layout/RenderFlex overflows and `>= 48dp` interactive targets** across `Onboarding`, `Today`, `My days`, `Talk`, `Calm & Help`, `Patterns`, `Me`, and `Clinician Shell` under BOTH:
    - **Amel (68yo Senior Stress Matrix):** `320x640` viewport, `TextScaler.linear(2.0)` + `Larger text` Comfort Mode, Arabic (`ar`, RTL), `Sunrise` Light.
    - **Yassine (19yo Gen Z Matrix):** `412x915` viewport, `1.0x` scale, English (`en`) & French (`fr`), both `Sunrise` Light and `Twilight` Night.
  - Run final full gate:
    ```powershell
    flutter analyze --no-pub; if ($?) { flutter test }
    ```
  - Only conclude when `flutter analyze --no-pub` reports **0 issues** and **every single test in `test/` passes**.
````
