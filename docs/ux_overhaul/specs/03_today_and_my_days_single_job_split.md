# Spec 03 — Single-Job Split: `Today` (2-Tap Joyful Check-In) vs. `My days` (Visual Calendar & Progressive Details)

> **Reads with:** [`00_research_and_rules.md`](../00_research_and_rules.md), [`01_design_system_sunrise_and_mood_faces.md`](01_design_system_sunrise_and_mood_faces.md)
> **Files in scope (17 files):**
> - `lib/features/home/presentation/home_screen.dart` (1,034 lines)
> - `lib/features/home/presentation/widgets/home_daily_check_in_card.dart` (1,006 lines)
> - `lib/features/home/presentation/widgets/home_weekly_rhythm_card.dart` (217 lines)
> - `lib/features/home/presentation/widgets/home_post_visit_focus_card.dart` (215 lines)
> - `lib/features/home/presentation/widgets/home_active_case_card.dart` (145 lines)
> - `lib/features/home/presentation/widgets/home_organic_exercise_art.dart` (140 lines)
> - `lib/features/track/presentation/track_screen.dart` (2,347 lines!)
> - `lib/features/track/presentation/widgets/track_mood_picker.dart` (247 lines)
> - `lib/features/track/presentation/widgets/track_month_calendar.dart` (409 lines)
> - `lib/features/track/presentation/widgets/track_entry_detail_sheet.dart` (619 lines)
> - `lib/features/track/presentation/widgets/track_mood_utils.dart` (78 lines)
> - `lib/features/mind_trace/presentation/widgets/daily_mind_trace_stepper.dart` (1,810 lines)
> - `lib/features/mind_trace/presentation/widgets/thought_trace_detail_sheet.dart` (680 lines)
> - `lib/features/mind_trace/presentation/widgets/trace_investigation_sheet.dart` (458 lines)
> - **New widget:** `lib/features/track/presentation/widgets/progressive_details_sheet.dart` (1-question-per-card optional enrichment sheet)

---

## 1. Current-State Diagnosis (The #1 UX Problem in Mindora Today)

1. **Duplicate check-in forms confuse everyone:**
   - `HomeScreen` shows an orb, 5 mood cards, a 1–10 equalizer slider (`-/+`), a blank text field, 4 note spark pills, and a save button (**6 widgets / ~82 words on 1 card**).
   - `TrackScreen` Tab 0 (`Check-In Today`, 2,347 lines!) repeats the exact same job — orb, mood grid, nuanced chips, intensity slider, note box, sparks, expandable context tags, what-helped chips, and 3 more sliders (`Sleep`, `Energy`, `Stress & Anxiety`)!
   - Meanwhile, `TrackScreen`'s *actual* unique value — the **Month Calendar & Day History** — is hidden behind Tab 1 (`History & Calendar`)!
2. **1–10 numerical sliders feel like medical paperwork:** Asking a tired teenager or a 70-year-old man *"Rate your somatic arousal from 1 to 10"* forces micro-decisions (`Is this a 6 or a 7?`). Three human choices (**`A little` · `Medium` · `A lot`**) map cleanly to `3 / 6 / 9` under the hood (`MindTraceModel.moodIntensity` stays `int 1–10` so ZERO analytics or clinician packet schemas break!).

---

## 2. Redesigned `Today` Tab (`HomeScreen`) — ONE Job: "How Are You?" in 2 Taps

### 2.1 Strict Screen Budget
- **Words above the fold:** `<= 32 words` (down from ~85!).
- **Primary decisions on screen:** **1** (`Pick a face`, then `Pick strength` — auto-saves!).
- **Removed from `Today`:**
  - Blank `TextField` & note sparks bar -> moved into optional post-save `"Add a note or detail"` sheet!
  - `1–10` slider -> replaced by 3 big `56dp` strength pills (`A little`, `Medium`, `A lot`)!
  - `RECENT SESSIONS` list & `Start Investigation` catalyst card -> moved to `Talk` tab where saved talks belong!
  - `OrganicMoodOrb` 2D drag instructions (*"Glide on the orb to sculpt mood & intensity"*) -> retired from the default form; `MoodFace` characters are self-explanatory at a glance with zero instruction text!

### 2.2 Wireframe — State A: Not Checked In Yet (`412px` & `320px`)
```text
+--------------------------------------+
|  Mindora                      [Help] |  <- Warm Sunrise cream (#FFF8F0), Help shield
|  Good morning, Amel                  |  <- 20sp w700 ink
|                                      |
|  +----------------------------------+|
|  |  How are you right now?          ||  <- 24sp w800 ink (5 words)
|  |                                  ||
|  |   ( Good )  ( Calm )  (Worried)  ||  <- 3x2 (or 2x3 at 320px / Large text)
|  |     Good      Calm     Worried   ||     80dp animated MoodFace characters!
|  |                                  ||     12dp spacing between tiles.
|  |  (Annoyed)  ( Low  )  (Restless) ||
|  |   Annoyed     Low      Restless  ||
|  |                                  ||
|  |  -- After tapping a face: -------||  <- Card softly floods with mood color!
|  |  How strong?                     ||  <- 15sp w700
|  |  [ A little ] [ Medium ] [A lot] ||  <- 3 x 56dp pill buttons.
|  |                                  ||     TAPPING ONE SAVES IMMEDIATELY!
|  +----------------------------------+|
|                                      |
|  +----------------------------------+|
|  |  This week            4 days     ||  <- 7 colored MoodFace mini-dots (28dp)
|  |   o   o   *   *   o   *   *      ||     No "/7" quota, no streak guilt!
|  |   M   T   W   T   F   S   S      ||
|  +----------------------------------+|
|                                      |
|  +----------------------------------+|
|  |  ( ~ )  Take a 1-minute breather ||  <- Single calm quick-relief card (56dp)
|  +----------------------------------+|
+--------------------------------------+
```
- **Responsive `320px` / `200%` Text Rule:** `LayoutBuilder` switches the 6 `MoodFace` tiles from `3 columns x 2 rows` (when `width >= 350 && textScale <= 1.25`) to **`2 columns x 3 rows`** automatically so labels NEVER truncate or collide! And the 3 strength pills (`A little`, `Medium`, `A lot`) switch from a `Row` to a vertical `Column` of full-width `52dp` buttons when `width < 340 || textScale > 1.3`.

### 2.3 Wireframe — State B: Moment Just Saved (Reward Bloom + Optional Enrichment)
- Immediately upon tapping `A little` (`3`), `Medium` (`6`), or `A lot` (`9`):
  1. Light haptic + soft `650ms` radial color bloom ring around the chosen `MoodFace` (instant if `reduceMotion`).
  2. Saves `MindTraceModel` immediately via `mindTraceControllerProvider.notifier.recordCheckIn(..., generateAi: false)` — **if the user closes the app right now, their check-in is 100% saved!**
  3. Card transitions smoothly into the warm **Logged Today Card**:
```text
+--------------------------------------+
|  +----------------------------------+|  <- Soft teal/yellow/sky mood-tinted card
|  |  (Calm)   You feel Calm today    ||  <- 56dp MoodFace + 18sp w700 title
|  |           A little · 09:40       ||  <- Plain strength word, not "(3/10)"!
|  |                                  ||
|  |  "4 calm mornings this month —   ||  <- 1-line CheckInMicroMirror (<=12 words)
|  |   your rhythm is steady."        ||
|  |                                  ||
|  |  [ + Add sleep, tags or a note ] ||  <- 52dp Soft pill -> opens ProgressiveDetailsSheet
|  |                                  ||
|  |  [ Breathe ]    [ Talk it out ]  ||  <- Two 52dp calm next-step buttons
|  |                                  ||
|  |  Change   ·   + Log new moment   ||  <- 48dp subtle links at bottom
|  +----------------------------------+|
|                                      |
|  (If Doctor's Plan active:)          |
|  +----------------------------------+|
|  |  Plan from Dr. Amira       1/2   ||  <- HomePostVisitFocusCard (plain copy)
|  |  [ ] Pause screens before 21:00  ||
|  +----------------------------------+|
+--------------------------------------+
```

---

## 3. Progressive "Add Details" Sheet (`progressive_details_sheet.dart`)

Replaces both `TrackScreen`'s long collapsible slider wall AND the old 5-step `DailyMindTraceStepper` essay form!
- **Rule:** **1 question per card**, giant tap buttons (`56dp`), progress dots `1 of 4`, **`Skip`** (`48dp`) top-end on every card, **`Done`** saves at any step:
  - **Card 1 — Nuance feelings (optional):** *"Any closer word for it?"* -> 6 big `48dp` pills for the chosen mood (from `AffectTaxonomy`) -> `Next` / `Skip`.
  - **Card 2 — Sleep & Energy (optional, zero sliders!):**
    - *"How did you sleep?"* -> 4 big `52dp` tiles: `Under 6h` (`5.5`) · `About 7h` (`7.0`) · `About 8h` (`8.0`) · `9h+` (`9.0`).
    - *"How is your energy?"* -> 3 big `52dp` tiles: `Low` (`3`) · `Okay` (`6`) · `Full` (`8`).
  - **Card 3 — What was part of today? (optional):**
    - 6 friendly icon+word tiles (`Good sleep`, `Moved my body`, `Time with people`, `Busy / work`, `Late screens`, `Quiet rest`) + *"What helped?"* (`Walk`, `Breathing`, `Quiet time`, `Talked`, `Rest`).
  - **Card 4 — Quick note (optional):**
    - 4 1-tap `QuickNoteSparksBar` chips + optional 2-line `TextField` (*"Anything you want to remember? (optional)"*, crisis-scanned via `CrisisKeywords.evaluateText` before saving!) -> **`Save details`** (`56dp` violet button).

---

## 4. Redesigned `My days` Tab (`TrackScreen`) — ONE Job: Visual History & Calendar

### 4.1 Remove the Duplicate Check-In Tab!
- Delete the top `Check-In Today | History & Calendar` segmented switcher on `TrackScreen`.
- `TrackScreen` (`My days`) opens **directly** to your visual month & day timeline!
- Top AppBar: **`My days`** (`22sp` bold) + **`+ Add moment`** pill button (`48dp`, opens a compact 2-tap `MoodFace` + strength sheet -> optional `ProgressiveDetailsSheet`) + `[Help]` shield.

### 4.2 Wireframe — `My days` (`412px` & `320px`)
```text
+--------------------------------------+
|  My days          [+ Moment]  [Help] |
|                                      |
|  +----------------------------------+|
|  |   <     November 2026      >     ||  <- 48dp arrows, 17sp w700 month
|  |   M   T   W   T   F   S   S      ||
|  |       1   2   3  (o) (o)  6      ||  <- Logged days show warm colored
|  |  (o)  8  (o) (o) 11  12  (o)     ||     MoodFace dots (44x44dp tap area!)
|  |  ...                             ||     Unlogged days are soft plain numbers
|  +----------------------------------+|     (NEVER red X's or "missed" marks!)
|                                      |
|  Tuesday, 24 Nov            Clear x  |  <- Filter pill when a date is tapped
|  +----------------------------------+|
|  |  (Calm)   Calm · A little  09:40 ||  <- Tap opens TrackEntryDetailSheet
|  |           Slept ~8h · Walk       ||     Swipe or tap trash -> IMMEDIATE
|  |           "Peaceful morning"     ||     delete + 6s MindUndoBanner!
|  +----------------------------------+|
|  +----------------------------------+|
|  |  (Worried) Worried · A lot 20:15 ||
|  |           Busy / work            ||
|  +----------------------------------+|
+--------------------------------------+
```
- **Empty State (0 entries yet):**
  - Friendly `72dp` sleeping sun-cloud illustration + Headline: **`Your days will show up here`** + Body (11 words): **`Each check-in adds a colored dot so you can spot patterns.`** + `56dp` button: **`Check in for today`** (navigates to `Today` tab).
- **Reversible Delete Upgrade (`TrackEntryDetailSheet` & `ThoughtTraceDetailSheet`):**
  - Replace the scary `AlertDialog("Delete Trace Entry?")` with **instant optimistic removal + `showMindUndoBanner("Entry removed", undoLabel: "Undo", onUndo: restoreTrace)`**! Faster for Gen Z, forgiving if Grandpa taps delete by mistake!

---

## 5. Copy Deck — Key Strings for `Today` & `My days`

| Key | EN | FR | AR (Tunisian) |
|---|---|---|---|
| `navToday` | `Today` | `Aujourd’hui` | `اليوم` |
| `navMyDays` | `My days` | `Mes jours` | `أيامي` |
| `todayHeroQuestion` | `How are you right now?` | `Comment vous sentez-vous là ?` | `كيفاش حالك توّا؟` |
| `moodGood` | `Good` | `Bien` | `لباس وفرحان` |
| `moodCalmPlain` | `Calm` | `Calme` | `مرتاح` |
| `moodAnxiousPlain` | `Worried` | `Inquiet` | `قلقان` |
| `moodFrustratedPlain` | `Annoyed` | `Agacé` | `متنرفز` |
| `moodHeavyPlain` | `Low` | `Abattu` | `ثقيل وتاعب` |
| `moodRestlessPlain` | `Restless` | `Agité` | `مش ركح` |
| `strengthQuestion` | `How strong?` | `Quelle force ?` | `قدّاش قوي؟` |
| `strengthLittle` | `A little` | `Un peu` | `شويّة` |
| `strengthMedium` | `Medium` | `Moyen` | `وسط` |
| `strengthLot` | `A lot` | `Beaucoup` | `برشا` |
| `addDetailsOptionalBtn` | `Add sleep, tags or a note` | `Ajouter sommeil, tags ou note` | `زيد النوم أو ملاحظة` |
| `breatheOneMinCard` | `Take a 1-minute breather` | `Respirer 1 minute au calme` | `خذ نفس هادي لدقيقة` |
| `weekDaysNotedBadge` | `$count days noted` | `$count jours notés` | `$count أيّام مسجّلة` |
| `myDaysEmptyTitle` | `Your days will show up here` | `Vos journées apparaîtront ici` | `أيّامك باش تبان هوني` |
| `myDaysEmptyBody` | `Each check-in adds a color dot so you can see your rhythm.` | `Chaque point du jour ajoute une couleur pour suivre votre rythme.` | `كلّ تسجيل يزيد نقطة ملوّنة باش تشوف إيقاعك بوضوح.` |
| `entryRemovedUndoMsg` | `Entry removed.` | `Entrée supprimée.` | `تفسخ التسجيل.` |
| `undoActionBtn` | `Undo` | `Annuler` | `رجّع` |

---

## 6. Tests Affected & Migration Map

| Test File | Existing Assertion | Required Update |
|---|---|---|
| `test/home_dribbble_redesign_test.dart` | Expects `INTENSITY`, `Log Daily Check-in`, `RECENT SESSIONS`, inline `TextField` on Home | Update to 2-tap `MoodFace` -> `A little / Medium / A lot` auto-save, `ProgressiveDetailsSheet` note entry, and 1-minute breather card |
| `test/home_extracted_components_test.dart` | Expects `OrganicMoodOrb`, inline `TextField`, `5/10` | Update to `MoodFace` geometry invariance, 3-level strength pills, and logged summary card (`Breathe` & `Talk it out`) |
| `test/tactile_orb_and_sparks_test.dart` | Tests `QuickNoteSparksBar` directly on Home & Track Tab 0 | Keep `OrganicMoodOrb` unit/widget test standalone; test `QuickNoteSparksBar` inside `ProgressiveDetailsSheet` |
| `test/elder_friendly_steppers_and_mirror_test.dart` | Tests `TrackScreen` Tab 0 sliders & `CheckInMicroMirror` | Keep `CheckInMicroMirror` tests; update sleep/energy preset test to `ProgressiveDetailsSheet` |
| `test/track_and_insights_ui_test.dart` | Expects 2 `MindSegmented` tabs (`Check-In Today`, `History & Calendar`) and delete `AlertDialog` | Update to single-purpose `My days` calendar + timeline, `+ Moment` sheet, and `MindUndoBanner` reversible delete |
| `test/affect_and_multimoment_test.dart` & `test/daily_context_tags_test.dart` | Logs multi-moment & context tags via `TrackScreen` Tab 0 | Update UI driver steps to `+ Moment` / `ProgressiveDetailsSheet` while keeping all domain/provider/baseline assertions 100% identical |
