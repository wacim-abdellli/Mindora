# Spec 04 — `Talk`, `Toolbox & Relief`, `Patterns`, `Me`, and `Doctor / Psychiatrist Workspace`

> **Reads with:** [`00_research_and_rules.md`](../00_research_and_rules.md), [`01_design_system_sunrise_and_mood_faces.md`](01_design_system_sunrise_and_mood_faces.md), [`02_navigation_onboarding_and_auth.md`](02_navigation_onboarding_and_auth.md), [`03_today_and_my_days_single_job_split.md`](03_today_and_my_days_single_job_split.md)
> **Scope:** Complete screen-by-screen UX, wireframe, progressive-disclosure, interaction, accessibility, trilingual Grade-6 copy deck, and test-migration specification for all remaining modules in Mindora (**60 files across 5 domains**).

---

## Section A — `Talk` Tab (Calm AI Companion & Step-by-Step Untangling)

### A.1 Files in Scope
- `lib/features/investigation/presentation/flash_case_screen.dart` (760 lines)
- `lib/features/investigation/presentation/widgets/live_dialogue_view.dart` (1,540 lines)
- `lib/features/investigation/presentation/ai_companion_hub_view.dart` (364 lines)
- `lib/features/investigation/presentation/widgets/companion_context_bridge_card.dart`
- `lib/features/investigation/presentation/widgets/vagal_breathing_visualizer.dart`
- `lib/features/investigation/presentation/widgets/mode_chooser_sheet.dart`
- `lib/features/investigation/presentation/widgets/ai_engine_config_sheet.dart`
- `lib/features/investigation/presentation/widgets/custom_ai_instructions_sheet.dart`
- `lib/features/investigation/presentation/widgets/voice_dictation_button.dart`
- `lib/features/journal/presentation/widgets/journal_memory_sheet.dart`
- `lib/features/case_file/presentation/case_report_screen.dart` (817 lines)
- `lib/features/case_file/presentation/clinical_export_preview_sheet.dart`
- `lib/features/case_file/presentation/widgets/clarity_anchor_card.dart`
- `lib/features/tools/presentation/widgets/reframe_drill_card.dart`
- `lib/features/tools/presentation/widgets/quick_calm_breathing_sheet.dart`
- `lib/features/investigation/controllers/investigation_providers.dart`
- `lib/features/investigation/data/mock_investigator_service.dart`

### A.2 Current-State Friction Diagnosis
1. **Four stacked chrome bars eat 38% of the screen before chat even starts:**
   - Top AppBar (`AI HUB` hardcoded English string at `flash_case_screen.dart:150`, mode chip, AI provider status pill, settings gear, `[Help]` button), plus a mode banner, plus clinical disclaimer strip, plus a busy composer bar (`+ Distortion`, `Fact / Guess / Story` pills, mic, text input, send). On a `320px` phone or `1.3x–2.0x` text scale, barely **1.5 chat bubbles** fit!
2. **Interrogation / forensic police vocabulary:**
   - Words like *Investigator*, *Case*, *Activating Catalyst*, *Neural & Somatic State*, *Somatic Arousal Intensity*, *Empirical Reality*, *Cognitive Distortions*, and *Clinical Triage* intimidate older adults and feel cold to Gen Z.
3. **Blank-page paralysis vs. Options-First rule (`AGENTS.md` Rule 11):**
   - Users shouldn't face an intimidating blank input box first. Starting a talk must present **4 warm, 1-tap starter cards** above a gentle optional composer.

### A.3 Redesigned `Talk` Layout & Wireframe (`412px` & `320px`)

#### 1. Collapse 4 Chrome Bars -> 1 Calm Top Bar (`56dp`)
```text
+--------------------------------------+
|  Talk          [Saved (3)] [...] [!] |  <- 1 clean row!
+--------------------------------------+
|  Private on your phone · Inspired by |  <- Dismissible 1-line trust pill (12.5sp)
|  CBT, not medical advice        [x]  |     Auto-collapses after 1st message!
+--------------------------------------+
|                                      |
|  (Companion avatar — warm violet)    |
|  "Take your time. What is on your    |  <- 16sp (18.5sp Comfort), max 18 words!
|   mind right now?"                   |
|                                      |
|  Tap one to start, or type below:    |  <- Options-First starter grid!
|  +----------------+ +---------------+|
|  | Overthinking   | | Heavy feeling ||  <- 56dp warm Sunrise cards (2x2 grid;
|  | something      | | I can't name  ||     1-col stack at 320px / Large text)
|  +----------------+ +---------------+|
|  | Tension with   | | Just need to  ||
|  | someone        | | vent safely   ||
|  +----------------+ +---------------+|
|                                      |
+--------------------------------------+
|  [Mic] [ Write or pick above... ] [>]|  <- 56dp composer bar; tools tucked cleanly!
+--------------------------------------+
```

#### 2. Header & Overflow Consolidation Rules
- **AppBar Title:** `Talk` / `حوار` / `Parler` (`20sp w800`). Delete hardcoded `'AI HUB'` (`flash_case_screen.dart:150`) and `'6 MODES'` (`ai_companion_hub_view.dart:299`).
- **`[Saved (N)]` Pill (`48dp` target):** Opens `AiCompanionHubView` (saved conversations list + search + `+ New talk` button).
  - Deleting a saved talk **NO LONGER pops a scary `AlertDialog` ("irreversible somatic purge")** — instead, hides the row immediately and shows a **6-second `MindUndoBanner`** (*"Talk removed · [Undo]"*)!
  - Private Lock toggle (`Lock` icon on each talk card): 1-tap toggle with `MindToast` (*"Marked private — never shared with doctors"*).
- **`[...]` (`More` `MindSheet`, `48dp` target):** Houses secondary controls out of the user's face:
  1. **How should I listen?** (`ModeChooserSheet` — 4 plain modes instead of 6 overlapping clinical labels; map legacy 6 enum values cleanly under the hood):
     - `Just listen` (*Warm, no advice*)
     - `Untangle a thought` (*Step-by-step, inspired by CBT*)
     - `Calm down fast` (*Short grounding steps*)
     - `Plan one small step` (*Practical next action*)
  2. **How to talk to me** (`CustomAiInstructionsSheet` — fixes English-only SnackBar bug at `custom_ai_instructions_sheet.dart:96`!).
  3. **What Mindora remembers** (`JournalMemorySheet` — clear toggle + 1-tap delete per memory with `MindUndoBanner`).
  4. **AI connection (Advanced)** (`AiEngineConfigSheet` — defaults to `Offline Test Mode (Private & Free)` per `AGENTS.md` Rule 1, with plain badge *"Test mode — stays on your phone"*).
  5. **Save summary card** -> opens `CaseReportScreen`.
- **`[!]` (`SupportButton`, `48dp` target):** Always visible top-end (`Semantics(label: strings.needSupportNow)`).

#### 3. Progressive Chat Tools (Zero Clutter While Typing)
- **Suggested Reply Chips (`Options-First`):** After every AI message, render **3 tappable reply pills (`48dp` min height)** right above the composer (e.g., *"Tell me another way to see this"*, *"Help me calm my body first"*, *"That feels lighter now — pause here"*). Tapping a pill fills or sends immediately (user configurable; default: sends on tap with visible bubble, zero typing needed for Amel 68yo!).
- **Thought Helper Drawer (`+ Tag thought` chip, `48dp`, shown only after >= 1 user message):**
  - Replaces the cramped inline `Fact / Hypothesis / Story` + `+ Distortion` strip!
  - Tapping `+ Tag thought` opens a clean 2-section `MindSheet`:
    - **Is this a...** -> 3 big `52dp` cards:
      - **`Fact`** (*Something a camera could see*)
      - **`Guess`** (*Possible, not sure yet*)
      - **`Worry story`** (*My mind jumping ahead*)
    - **Common thinking traps** (replaces *"COGNITIVE DISTORTIONS"*):
      1. `Jumping to the worst` (*Catastrophizing*)
      2. `Guessing their thoughts` (*Mind reading*)
      3. `All good or all bad` (*All-or-nothing*)
      4. `Feeling = fact` (*Emotional reasoning*)
      5. `Only seeing the bad` (*Mental filter*)
      6. `Always / never` (*Overgeneralizing*)
- **Voice Dictation (`VoiceDictationButton`):** `48dp × 48dp` circle, clear pulsing Sunrise coral ring while listening, pre-permission `MindSheet` before first microphone OS prompt (*"Speak instead of typing — your voice is turned into text and never recorded."*).
- **Safety Gate:** Every user message, starter prompt, and custom instruction continues to pass synchronously through `SafetyInterceptor` / `CrisisKeywords.evaluateText` **before** calling `AiService`.

#### 4. `CaseReportScreen` -> Renamed **"Talk Summary"** (`case_report_screen.dart`)
- Replace forensic dossier headers with warm, human cards (`Sunrise` `#FFFFFF` surface + `#FFF0E3` highlight card):
  1. **`What happened`** (replaces `1. ACTIVATING CATALYST`)
  2. **`How it felt & first thought`** (replaces `2. SOMATIC & NEURAL RESPONSE` and `SOMATIC STATE: ANXIOUS (8/10)` -> shows `MoodFace` + `Worried · A lot`)
  3. **`Another way to see it`** (replaces `CLINICAL TRIAGE / COGNITIVE DISTORTIONS`)
  4. **`Keep this calm reminder`** (`ClarityAnchorCard` — warm `#FFF0E3` / `#312754` keepsake card with 1-tap `Pin to Today` or `Share summary`).
- **Step-by-Step Guided Mode (`FlashCaseScreen` stepper fallback):** Keep the 3-step structured flow accessible via *"Prefer step-by-step cards instead of chat?"* using plain stage titles: `Step 1: What happened?` -> `Step 2: Body & thought` (`A little / Medium / A lot`) -> `Step 3: Clearer view`.

### A.4 Copy Deck — `Talk` Tab (EN / FR / Tunisian AR)

| Getter / Key | English (Grade <= 6) | Français | العربية (تونسية واضحة) |
| :--- | :--- | :--- | :--- |
| `navTalk` | `Talk` | `Parler` | `حوار` |
| `talkSavedPill` | `Saved ($count)` | `Gardés ($count)` | `محفوظة ($count)` |
| `talkTrustStrip` | `Private on your phone · Inspired by CBT, not therapy` | `Privé sur ce téléphone · Inspiré des TCC, pas une thérapie` | `محفوظ في تليفونك · مستوحى من CBT وموش علاج طبي` |
| `welcomeDialoguePrompt` | `Take your time. What is on your mind right now?` | `Prenez votre temps. Qu’avez-vous sur le cœur ?` | `خوذ راحتك. شنوة اللّي شاغلك توا؟` |
| `talkStarterOverthinking` | `Overthinking something` | `Je rumine quelque chose` | `نخمّم برشا في حاجة` |
| `talkStarterHeavy` | `Heavy feeling I can't name` | `Un poids difficile à nommer` | `حاسس بضيق وما عرفتش نسمّيه` |
| `talkStarterPeople` | `Tension with someone` | `Tension avec quelqu’un` | `توتر مع شخص` |
| `talkStarterVent` | `Just need to let it out` | `Juste besoin de vider mon sac` | `نحب نفرّغ قلبي برك` |
| `tagDistortionBtn` | `+ Tag thought` | `+ Repérer` | `+ فرز الفكرة` |
| `cognitiveDistortionSheetTitle` | `Common thinking traps` | `Pièges de pensée fréquents` | `فخاخ التفكير الشائعة` |
| `thoughtTypeFact` | `Fact — something anyone could see` | `Fait — observable de l’extérieur` | `حقيقة — حاجة أي واحد يشوفها` |
| `thoughtTypeGuess` | `Guess — possible, not sure yet` | `Supposition — pas encore sûr` | `تخمين — ممكن أما موش أكيد` |
| `thoughtTypeStory` | `Worry story — my mind jumping ahead` | `Scénario — mon esprit anticipe` | `سيناريو قلق — مخي سبق الأحداث` |
| `caseReportTitle` | `Talk summary` | `Résumé d’échange` | `ملخص الحوار` |
| `incidentNarrativeHeader` | `What happened` | `Ce qui s’est passé` | `شنوة اللي صار` |
| `observableChainHeader` | `How it felt & first thought` | `Ressenti et première pensée` | `الإحساس وأول فكرة` |
| `findingsSub` | `Another way to look at it` | `Une autre façon de voir les choses` | `زاوية أخرى تشوف بيها الموقف` |
| `talkDeletedUndo` | `Talk removed` | `Échange supprimé` | `تفسخ الحوار` |
| `customInstructionsSavedToast` | `Listening preferences saved` | `Préférences d’écoute enregistrées` | `تخزّنت تفضيلات الاستماع` |

---

## Section B — `Relief & Toolbox` (Instant Calm, Grounding & Body Notes)

### B.1 Files in Scope
- `lib/core/safety/support_button.dart`
- `lib/features/support/presentation/contextual_support_sheet.dart`
- `lib/features/support/presentation/widgets/breathing_exercise_card.dart`
- `lib/features/support/presentation/widgets/grounding_exercise_card.dart`
- `lib/features/support/presentation/widgets/micro_action_card.dart`
- `lib/features/support/presentation/widgets/perspective_exploration_card.dart`
- `lib/features/support/presentation/widgets/routine_anchor_card.dart`
- `lib/features/support/presentation/widgets/relief_micro_check_card.dart`
- `lib/features/observatory/presentation/inner_observatory_screen.dart` (777 lines)
- `lib/features/observatory/presentation/widgets/add_discovery_sheet.dart`
- `lib/features/observatory/presentation/widgets/custom_perspective_sheet.dart`
- `lib/features/observatory/presentation/widgets/custom_symptom_sheet.dart`
- `lib/features/observatory/presentation/widgets/symptom_assessment_sheet.dart`
- `lib/features/observatory/presentation/widgets/symptom_library_view.dart`
- `lib/features/journey/presentation/journey_activity_detail_screen.dart`
- `lib/features/mind_trace/presentation/widgets/trace_entry_detail_sheet.dart`

### B.2 Current-State Friction Diagnosis
1. **Jargon exercise titles:** *Vagal Box Pacing (4-4-4-4)*, *Somatic Safety Anchor*, *Inner Observatory*, *Routine Anchor*, *Micro-Action*. An older user in distress has zero idea what "Vagal" means!
2. **Hardcoded inline language strings & missing French bug:**
   - `symptom_assessment_sheet.dart:114` has an `isArabic ? ... : ...` ternary that **completely forgets French (`isFrench`)**, showing English inside French mode!
   - `breathing_exercise_card.dart`, `grounding_exercise_card.dart`, `micro_action_card.dart`, `routine_anchor_card.dart`, `add_discovery_sheet.dart`, `custom_perspective_sheet.dart`, and `symptom_library_view.dart` contain dozens of inline `isArabic`/`isFrench` ternaries outside `app_strings.dart`.

### B.3 Redesigned `Calm & Help` Sheet (`ContextualSupportSheet` + `SupportButton`)
Tapping **`[Help]`** in any top bar or **`Take a 1-minute breather`** on `Today` opens a clear, high-contrast sheet divided into **2 unmistakable zones**:
1. **Top Zone — Quick Calm Tools (1 tap to start, `Stop anytime` `48dp` button always visible):**
   - **`Slow breathing · 1 min`** (`BreathingExerciseCard` — expanding Sunrise teal `#2AD5A5` soft circle, **`22sp w800`** phase cue: `Breathe in... 4` / `Hold... 4` / `Breathe out... 4`, zero small text; Static progress ring + numeric countdown when `reduceMotion == true`).
   - **`Look around you · 5-4-3-2-1`** (`GroundingExerciseCard` — 1 sense per step with big `+1` tap circles instead of a wall of text: *Tap 5 things you can see* -> *4 things you can touch* -> *3 sounds* -> *2 smells* -> *1 calm breath*).
   - **`One tiny step`** (`MicroActionCard` — 3 gentle tap cards: *Drink a glass of water*, *Unclench your shoulders*, *Step near a window*).
   - **`Did that help?` (`ReliefMicroCheckCard`):** Shown after completing an exercise -> 3 big buttons (`Yes, lighter` · `A little` · `Not right now`). Tapping `Yes, lighter` saves to *"What helps you"* (`ObservedStabilizers`) with toast *"Saved to What helps you"*.
2. **Bottom Zone — Emergency Human Support (Direct, Unambiguous per `AGENTS.md` Rule 8 & 11):**
   - Warm rose-bordered card (`#FFF1F4` light / `#3A1F2D` night) with **1-tap `56dp` call buttons**:
     - **`Call 80 10 50 50 — Free support line (Tunisia)`**
     - **`Call 190 — Medical emergency (SAMU)`**
     - **`Call 198 — Civil protection`**

### B.4 `InnerObservatoryScreen` -> Renamed **"Toolbox & Body Check"**
Accessible from `Me -> Toolbox & body notes` or `ContextualSupportSheet -> More tools`:
- **3 Clean Tabs (`MindSegmented`, `48dp` height):**
  1. **`Body & signs`** (`SymptomLibraryView` + `SymptomAssessmentSheet`):
     - Fix missing French translation at `symptom_assessment_sheet.dart:114` and move all inline strings to `app_strings.dart`.
     - Replace `1–10` severity slider in `SymptomAssessmentSheet` with **`Mild` (`3`) · `Moderate` (`6`) · `Strong` (`9`)** `56dp` buttons + optional tap chips (*Morning*, *Afternoon*, *Night*).
  2. **`Helpful thoughts`** (`PerspectiveExplorationCard` + `CustomPerspectiveSheet`):
     - Card deck of short `<= 14-word` grounding reminders user can star or add in 1 sentence.
  3. **`Aha moments`** (`AddDiscoverySheet`):
     - Simple list of things the user noticed about themselves; deleting any item uses **6-second `MindUndoBanner`** instead of a blocking confirmation modal.

---

## Section C — `Patterns` Tab (`InsightsScreen` Progressive Disclosure & Mood Colors Poster)

### C.1 Files in Scope
- `lib/features/insights/presentation/insights_screen.dart` (1,813 lines, **56 `Text` widgets** — #1 text-density hotspot in the app!)
- `lib/features/insights/presentation/widgets/observed_stabilizers_card.dart`
- `lib/features/insights/presentation/widgets/forensic_loop_map_card.dart`
- `lib/features/insights/presentation/widgets/discovery_milestones_card.dart`
- `lib/features/insights/presentation/widgets/mood_aura_poster_sheet.dart`
- `lib/features/progress/data/progress_analytics_service.dart`
- `lib/features/progress/domain/progress_analytics_model.dart`
- `lib/core/widgets/smooth_spline_chart.dart`

### C.2 Current-State Friction Diagnosis
- Currently stacks **9 dense analytical cards** vertically (*Personal Baseline*, *Emotional Granularity*, *Somatic & Sleep Insights*, *Observed Stabilizers*, *Observed Forensic Loop*, *Discovery Milestones*, *Mood Aura Poster*, *30-Day Deltas*, *Sparklines*) with **56 `Text` widgets** and clinical phrases like *"Descriptive link across daily context, diurnal affect, observed thought chains, and stabilizers."*
- Both Amel (68) and Yassine (19) bounce off walls of text; Yassine wants visual payoff & shareable art, while Amel wants **1 clear sentence** telling her how her week went!

### C.3 Redesigned `Patterns` Layout (`<= 38 Words` Above the Fold!)

```text
+--------------------------------------+
|  Patterns                     [Help] |
+--------------------------------------+
|  +----------------------------------+|
|  |  Your week                       ||  <- Card 1: 1-line human summary + faces!
|  |  "Mostly calm mornings, tired    ||     18sp w700 ink (<= 12 words)
|  |   on late-screen nights."        ||
|  |                                  ||
|  |  (Calm) (Good) (Calm) (Low) ...  ||  <- 7 colored MoodFace badges
|  +----------------------------------+|
|                                      |
|  +----------------------------------+|
|  |  What helps you feel better      ||  <- Card 2: Plain top 3 helpful habits
|  |  [ Morning walk ] [ Slow breath ]||     (replaces "OBSERVED STABILIZERS")
|  |  [ 8h sleep ]                    ||
|  +----------------------------------+|
|                                      |
|  +----------------------------------+|
|  |  ( * )  Your Mood Colors Poster  ||  <- Card 3: Vivid Sunrise/Twilight
|  |  Turn this month into art   [->] ||     generative poster preview! (Gen Z hook)
|  +----------------------------------+|
|                                      |
|  [ v  See more details (3 cards)   ] |  <- 52dp progressive disclosure button!
+--------------------------------------+
```

#### Inside `[ v  See more details ]` (Collapsed by default, remembers user preference):
1. **`How a tough moment unfolds`** (`ForensicLoopMapCard` — replaces *"OBSERVED FORENSIC LOOP"*):
   - 4 connected rounded pills with plain labels: `What happened` -> `Feeling` -> `First thought` -> `What helped`.
2. **`Sleep & energy`** (`energyAndSleepTitle` — replaces *"SOMATIC & SLEEP INSIGHTS"*):
   - Simple visual bar comparing good-sleep days (`7h+`) vs. short-sleep days, zero decimals (`"You feel calmer after 7+ hours of sleep"`).
3. **`Your usual rhythm`** (replaces *"PERSONAL BASELINE"* / *"GRANULARITY"*):
   - Plain comparison: `This week` vs `Your usual`, plus `Milestones noticed` (`DiscoveryMilestonesCard` — celebrating gentle moments like *"First calm breather"*, *"3 moods named"*, **never** day-streak pressure!).

#### Progressive Empty States (`0`, `1–2`, `3+` Days Logged)
- **`0 days`:** Friendly `MoodFace(calm)` illustration + *"Check in for 3 days to see your first pattern."* + **`Check in now`** (`56dp` button -> switches to `Today` tab).
- **`1–2 days`:** Visual `3-dot` progress pill (`1 of 3` or `2 of 3`) + *"Almost ready — 1 more day unlocks your weekly pattern!"* (Your *Mood Colors Poster* is already unlocked from Day 1 so Gen Z gets instant visual delight!).
- **`MoodAuraPosterSheet` Upgrade:** Add theme switcher right inside the poster sheet (**`Sunrise Warm` `#FFF8F0`** | **`Twilight Indigo` `#1B1530`**) so users can save/share bright pastel-vivid art OR glowing night-sky art, with zero personal notes or private data ever rendered on the image!

---

## Section D — `Me` Tab (`SettingsScreen`, `PsychologicalProfile`, Privacy & Backup)

### D.1 Files in Scope
- `lib/features/settings/presentation/settings_screen.dart` (2,196 lines, **55 `Text` widgets**, **37 popup callsites**!)
- `lib/features/settings/presentation/clinical_sharing_history_sheet.dart`
- `lib/features/profile/presentation/psychological_profile_screen.dart`
- `lib/features/profile/presentation/psychological_profile_view.dart`
- `lib/features/profile/presentation/widgets/condition_status_bottom_sheet.dart`
- `lib/features/profile/presentation/widgets/edit_about_me_sheet.dart`
- `lib/features/profile/presentation/widgets/edit_basic_info_sheet.dart`
- `lib/features/profile/presentation/widgets/edit_communication_sheet.dart`
- `lib/features/profile/presentation/widgets/edit_conditions_sheet.dart`
- `lib/features/profile/presentation/widgets/edit_experiences_sheet.dart`
- `lib/features/profile/presentation/widgets/edit_goals_sheet.dart`
- `lib/features/profile/presentation/widgets/edit_personal_context_sheet.dart`
- `lib/features/profile/presentation/widgets/edit_preferences_sheet.dart`
- `lib/features/profile/presentation/widgets/edit_symptoms_sheet.dart`
- `lib/features/profile/presentation/widgets/edit_triggers_sheet.dart`
- `lib/features/profile/presentation/widgets/edit_values_sheet.dart`
- `lib/features/profile/presentation/widgets/privacy_management_sheet.dart`
- `lib/features/backup/data/unified_backup_service.dart`

### D.2 Current-State Friction Diagnosis
1. `SettingsScreen` is a 2,196-line scroll of 14+ technical sections, raw JSON clipboard backup dialogs, developer-sounding AI provider keys, clinician workspace switches, PIN settings, reminders, language, theme, comfort mode, and erase buttons all competing at the same visual weight!
2. Raw JSON clipboard paste dialogs for Backup/Restore terrify non-technical users.

### D.3 Redesigned `Me` Tab — 5 Calm Grouped Cards (`56dp` Rows)

```text
+--------------------------------------+
|  Me                           [Help] |
+--------------------------------------+
|  1. LOOK & READING                   |
|  +----------------------------------+|
|  | Colors   [Sunrise] [Night] [Auto]||  <- Segmented 48dp; Sunrise = default!
|  | Text size   [Normal] [Larger Aa] ||  <- Instant live preview!
|  | Language    [EN] [FR] [العربية]   ||
|  +----------------------------------+|
|                                      |
|  2. ABOUT ME & REMINDERS             |
|  +----------------------------------+|
|  | My story & goals             [>] ||  <- Opens PsychologicalProfileScreen
|  | Toolbox & body notes         [>] ||  <- Opens InnerObservatoryScreen
|  | Daily gentle reminder     [Toggle]|| <- Pre-permission sheet on 1st enable
|  +----------------------------------+|
|                                      |
|  3. DOCTOR VISIT (OPTIONAL)          |
|  +----------------------------------+|
|  | 2-minute visit summary       [>] ||  <- Opens PreVisitBriefSheet
|  | Share code with my doctor    [>] ||  <- Opens ShareWithPsychiatristSheet
|  | Add plan from my doctor      [>] ||  <- Opens ImportCareFocusSheet
|  +----------------------------------+|
|                                      |
|  4. PRIVACY, LOCK & BACKUP           |
|  +----------------------------------+|
|  | App PIN / fingerprint lock [Tog] ||
|  | Save backup file             [>] ||  <- OS share sheet (.mindora / .json) + passphrase
|  | Restore from backup          [>] ||  <- File picker + Dry-run preview BEFORE overwrite!
|  | Privacy & erase data         [>] ||  <- Opens Privacy & Erase sheet
|  +----------------------------------+|
|                                      |
|  5. [ v  For clinicians & advanced ] |  <- Collapsed accordion!
|     - Switch to Psychiatrist Workspace
|     - AI connection (Offline test mode / Gemini / Groq)
|     - Sharing history log
|     - Account / Sign out
+--------------------------------------+
```

#### Key `Me` Sub-Flow Simplifications:
- **`PsychologicalProfileScreen` ("My Story & Goals"):**
  - Keep all 7 optional `edit_*_sheet.dart` bottom sheets **100% chip-first** (`48dp` chips + optional *"Add your own"* pill), delete both 19-word intro quotes (`profileIntroQuote`, `profileSecondaryQuote`) and replace with 1 warm 10-word subtitle: *"Share only what helps Mindora support you. Everything stays private."*
  - Move every hardcoded inline string in `condition_status_bottom_sheet.dart`, `edit_experiences_sheet.dart`, and `privacy_management_sheet.dart` into `app_strings.dart`.
- **Backup & Restore Safety (`UnifiedBackupService` UI in `SettingsScreen`):**
  - Keep clipboard fallback under *"Copy text code instead"* for desktop/test environments, **primary button uses file save/share** with plain instructions (*"Save a locked copy of your Mindora history"*).
  - Before restoring, ALWAYS show a plain **Dry-Run Preview `MindSheet`** (*"Found 18 check-ins and 4 talks from Nov 2026. Add to your phone?"* -> **`Restore backup`** / **`Cancel`**).
- **Destructive `Erase Everything` (`AGENTS.md` + `accidental-data-loss-prevention`):**
  - Remains a 2-step explicit `AlertDialog` with outcome-named buttons (**`Delete all my data`** in `#D92D4B` danger fill vs **`Keep my data`** default focus).

---

## Section E — `Doctor Visit` & `Psychiatrist Workspace`

### E.1 Files in Scope
- **Patient-side handoff sheets (4 files):**
  - `lib/features/clinician/presentation/widgets/pre_visit_brief_sheet.dart`
  - `lib/features/clinician/presentation/widgets/share_with_psychiatrist_sheet.dart`
  - `lib/features/clinician/presentation/widgets/import_care_focus_sheet.dart`
  - `lib/features/clinician/presentation/widgets/mind_qr_scanner_sheet.dart`
- **Clinician-side workspace (5 files):**
  - `lib/features/clinician/presentation/clinician_shell_screen.dart` (1,682 lines)
  - `lib/features/clinician/presentation/clinician_patient_detail_screen.dart` (1,611 lines)
  - `lib/features/clinician/presentation/widgets/clinical_brief_preview_sheet.dart`
  - `lib/features/clinician/presentation/widgets/compose_post_visit_focus_sheet.dart`
  - `lib/features/clinician/presentation/widgets/import_patient_packet_sheet.dart`

### E.2 Patient-Facing Doctor Handoff Rules (Grade-6 Plain Language)
1. **`PreVisitBriefSheet` ("2-Minute Visit Summary"):**
   - Top banner in soft teal (`#E4FAF3`): *"Private talks are automatically left out."* (`privateCasesExcludedBanner` shortened to `<= 10 words`!).
   - Plain checkboxes (`52dp` rows): `Include mood summary`, `Include sleep & energy`, `Include what helped`, `Include non-private talk summaries`.
2. **`ShareWithPsychiatristSheet` ("Share with My Doctor"):**
   - Generates encrypted `MF-CLINIC-V1:` QR / code (contract **MUST remain unchanged** for `clinician_portal_and_handoff_test.dart`!).
   - Display a giant QR on crisp `#FFFFFF` card (even in `Twilight` Night mode so phone cameras scan reliably!) + large `22sp` monospace 1-time passphrase box with 1-tap `Copy code`.
3. **`MindQrScannerSheet` Camera Pre-Permission:**
   - Before requesting OS camera access, show a friendly 1-card prompt if permission not yet granted: *"Allow camera to scan your doctor's QR code — you can also paste the text code below."* (`Scan with camera` / `Paste text code`).

### E.3 Clinician Workspace Rules (High-Clarity Professional Sunrise / Twilight)
Dr. Amira needs rapid 30-second clinical triage without eye strain:
- **Preserve Existing Structural & Test Contracts 100%:**
  - Keep `MindSegmented` controls on `ClinicianShellScreen` and `ClinicianPatientDetailScreen` (`test/clinician_portal_and_handoff_test.dart` asserts exact `MindSegmented` widget presence and tab switching!).
  - Keep `MF-CLINIC-V1:` import decryption, `MF-CAREPLAN-V1:` post-visit care focus generation (`ComposePostVisitFocusSheet`), `ClinicalBriefPreviewSheet` A4 print/PDF layout, EHR summary copy, and strict `isPrivate` exclusion untouched!
- **Visual & Readability Upgrades:**
  - Automatically inherit `Sunrise` (`#FFF8F0` / `#FFFFFF` crisp clinical paper feel!) and `Twilight` (`#1B1530` / `#261E42`) tokens via `MindTokens.of(context)` — zero hardcoded `#000000` or `#0A0A0A`!
  - Migrate inline strings in `clinician_shell_screen.dart:128-137` and `clinical_export_preview_sheet.dart:303` into `app_strings.dart`.
  - Enforce `>= 12sp` typography floor on all table headers and badges (`baselineSteadyBadge`, `baselineColumnLabel`).

---

## Section F — Test Migration Map for Spec 04

| Test File | What Changes / Must Be Preserved |
| :--- | :--- |
| `test/clinician_portal_and_handoff_test.dart` | **Preserve 100%:** `MindSegmented` counts, `MF-CLINIC-V1:` / `MF-CAREPLAN-V1:` packet roundtrips, `isPrivate` case stripping, demo cohort toggle. Update any string assertions only if matching renamed `app_strings.dart` getters. |
| `test/phase5_stabilizers_loop_and_brief_test.dart` | Keep `ObservedStabilizersCard` & `ForensicLoopMapCard` widget types intact! Note: in `InsightsScreen`, `ObservedStabilizersCard` stays above the fold ("What helps you feel better"), while `ForensicLoopMapCard` lives inside the expandable `"See more details"` section — update widget test to tap `"See more details"` (or pass `initiallyExpanded: true` in unit harness) when asserting `ForensicLoopMapCard` inside `InsightsScreen`. |
| `test/phase6_relief_loop_and_care_bridge_test.dart` | Preserve `ReliefMicroCheckCard` -> stabilizer recording & `HomePostVisitFocusCard` -> `Talk` companion prompt handoff. |
| `test/phase7_delight_and_comfort_test.dart` | Update `MoodAuraPosterSheet` / `DiscoveryMilestonesCard` assertions if copy strings changed; verify both `Sunrise` and `Twilight` poster styles render cleanly. |
| `test/scenarios_verification_test.dart`, `test/step_3_1_*`, `test/step_3_2_*`, `test/step_3_3_*` | Domain/service/privacy tests — keep `CaseModel`, `PsychologicalProfileModel`, `UnifiedBackupService`, and `ProgressAnalyticsModel` public APIs 100% backward-compatible so all pass with zero regressions! |
| **New Test:** `test/talk_and_patterns_progressive_ux_test.dart` | Asserts: (1) `Talk` initial screen has `<= 4` starter cards + single `56dp` AppBar + zero overflow at `320x640` `2.0x` AR RTL; (2) deleting a saved talk shows `MindUndoBanner` and restores on `Undo`; (3) `Patterns` top fold has `<= 38 words` and expands `"See more details"` cleanly; (4) `Me` renders 5 grouped cards with `Advanced` collapsed by default. |
