# Spec 01 — Design System Overhaul: "Sunrise" Default, "Twilight" Night & Living `MoodFace` Characters

> **Reads with:** [`00_research_and_rules.md`](../00_research_and_rules.md)
> **Files in scope (26 files):**
> - `AGENTS.md` (Rule 6 update)
> - `lib/app/theme/mind_tokens.dart` (627 lines)
> - `lib/app/theme/lab_theme.dart` (295 lines)
> - `lib/app/theme/lab_colors.dart` (94 lines)
> - `lib/app/theme/theme_controller.dart` (75 lines)
> - `lib/app/theme/display_comfort_controller.dart` (42 lines)
> - `lib/main.dart` (175 lines)
> - `lib/core/widgets/ambient_scaffold.dart` (75 lines)
> - `lib/core/widgets/mind_button.dart` (164 lines)
> - `lib/core/widgets/mind_card.dart` (94 lines)
> - `lib/core/widgets/mind_chip.dart` (89 lines)
> - `lib/core/widgets/mind_pill.dart` (99 lines)
> - `lib/core/widgets/mind_segmented.dart` (117 lines)
> - `lib/core/widgets/mind_sheet.dart` (85 lines)
> - `lib/core/widgets/mind_switch.dart` (88 lines)
> - `lib/core/widgets/mind_toast.dart` (43 lines)
> - `lib/core/widgets/mind_pressable.dart` (90 lines)
> - `lib/core/widgets/mood_emblem.dart` (224 lines)
> - `lib/core/widgets/organic_mood_orb.dart` (659 lines)
> - **New widget:** `lib/core/widgets/mood_face.dart` (expressive drawn vector character — zero emojis)
> - **New widget:** `lib/core/widgets/mind_undo_banner.dart` (6-second reversible action toast with 48dp `Undo`)

---

## 1. Current-State Diagnosis (Why Current UI Feels Cold / "Dead")

1. **Default theme traps users in pitch black:** `theme_controller.dart:11` sets `initialThemeModeProvider = ThemeMode.system`. Any phone in dark mode boots into `#000000` pure pitch black (`MindTokens.darkBg`) with `#FFFFFF` stark white buttons — causing optical halation for older eyes and a cold developer-console feel ("Vercel Dark") rather than a warm human sanctuary.
2. **Even Light mode ("Dawn") feels grey and clinical:** `MindTokens.lightBg` is `#F5F6FA` (cool hospital grey-blue) and primary buttons use `#172033` (dark navy-black), making primary actions look heavy and serious rather than inviting.
3. **Mood icons are tiny abstract symbols inside circles:** `MoodEmblem` draws small `20px` geometric icons (`water_drop`, `bolt`, `cloud`) inside desaturated circles. Neither a 68-year-old grandfather nor a 19-year-old Gen Z user feels emotional warmth from a tiny grey-blue outline icon.
4. **Typography floor is too small for older eyes:** Several labels across `case_report_screen.dart`, `settings_screen.dart`, `insights_screen.dart`, and `daily_mind_trace_stepper.dart` use `fontSize: 9`, `9.5`, `10`, `10.5`, and `11` coupled with `ALL CAPS` (`letterSpacing: 0.8–1.1`). Research shows presbyopic eyes struggle severely below `13–14sp` and read `ALL CAPS` slower because word ascender/descender shapes disappear.

---

## 2. Token Specification: `Sunrise` (Default Light) & `Twilight` (Optional Night)

### 2.1 Default Theme Policy (`lib/app/theme/theme_controller.dart`)
- Change fresh-install default from `ThemeMode.system` to **`ThemeMode.light` (`Sunrise`)** when no saved key `'mf_theme_mode_v1'` exists in `SharedPreferences`.
- Keep user choice persistent: `Sunrise` (`ThemeMode.light`), `Night` (`ThemeMode.dark`), `Match phone` (`ThemeMode.system`).
- Update `AGENTS.md` Directive 6 before modifying `mind_tokens.dart` so documentation and code remain 100% aligned.

### 2.2 Complete `MindTokens` Color Matrix (WCAG 2.2 Contrast Verified)

Every pair below was mathematically verified via relative luminance formula `(L1 + 0.05) / (L2 + 0.05)`:

| Token Field | Sunrise (`MindTokens.light`) | Twilight (`MindTokens.dark`) | Verified Contrast & Role |
|---|---|---|---|
| `bg` | `0xFFFFF8F0` (Warm Cream) | `0xFF1B1530` (Deep Indigo) | Ground canvas — zero `#000000` |
| `surface` | `0xFFFFFFFF` (Pure Warm Card) | `0xFF261E42` (Elevated Plum-Indigo) | Cards, modals, bottom sheets |
| `surface2` | `0xFFFFF0E3` (Soft Peach Well) | `0xFF322857` (Soft Violet Well) | Input fills, pill wells, tracks |
| `line` | `rgba(43, 33, 64, 0.10)` | `rgba(245, 240, 255, 0.12)` | 1px subtle card & divider border |
| `lineStrong` | `rgba(43, 33, 64, 0.20)` | `rgba(245, 240, 255, 0.24)` | Active outlines, stepper borders |
| `ink` | `0xFF2B2140` (Deep Plum) | `0xFFF5F0FF` (Warm Off-White) | **14.3:1** Light / **13.9:1** Night (AAA) |
| `ink2` | `0xFF5A4B73` (Muted Plum) | `0xFFCFC4EB` (Soft Lavender) | **7.4:1** Light / **9.5:1** Night (AAA) |
| `ink3` | `0xFF6B5C85` (Warm Slate) | `0xFFB7AAD9` (Muted Lilac) | **5.7:1** Light / **7.3:1** Night (AA+) |
| `primary` *(new field)* | `0xFF6A3DE8` (Alive Violet) | `0xFFB7A2FF` (Luminous Lilac) | Primary CTA fill (**6.1:1** w/ `#FFFFFF` in Light; **8.0:1** w/ `#1B1530` in Night) |
| `onPrimary` *(new field)* | `0xFFFFFFFF` | `0xFF1B1530` | Primary CTA text & icon |
| `primaryDeep` *(new field)* | `0xFF5B2FD0` | `0xFF9C86FF` | Pressed / active primary state |
| `safety` | `0xFFB3263E` (Warm Crimson) | `0xFFFF8A98` (Soft Rose-Coral) | **6.1:1** Light / **6.9:1** Night — Crisis & destructive actions ONLY |
| `safetySoft` | `0xFFFDE8EC` | `0xFF3D1D2B` | Crisis banner / destructive tint |
| `navGlass` | `rgba(255, 248, 240, 0.90)` | `rgba(38, 30, 66, 0.90)` | Frosted floating bottom dock |
| `focusRing` | `0xFF6A3DE8` | `0xFFFFD166` | 2px keyboard / TalkBack focus ring |

### 2.3 Six Expressive Mood Palettes (`AppMood` + `MindTokens.moodColor`)

Add **`AppMood.good`** (`'good'`) alongside existing 5 core moods so users have a joyful, sunny option when having a good day (backward-compatible: all existing `'calm'`, `'anxious'`, `'frustrated'`, `'heavy'`, `'restless'` keys continue working unchanged!):

| Mood Key | Character Fill | Text/Stroke on Fill | Soft Background Flood (`14%` Light / `16%` Night) | Plain Label (EN / FR / AR) |
|---|---|---|---|---|
| `good` *(new)* | `0xFFFFC93C` (Sun Yellow) | `0xFF2B2140` (**9.8:1**) | Warm golden sunlight glow | Good / Bien / لباس وفرحان |
| `calm` | `0xFF2EC4B6` (Alive Teal) | `0xFF2B2140` (**6.9:1**) | Fresh seafoam breeze glow | Calm / Calme / مرتاح وهادي |
| `anxious` | `0xFF5AA9FF` (Clear Sky) | `0xFF2B2140` (**6.1:1**) | Soft sky mist glow | Worried / Inquiet / قلقان |
| `frustrated` | `0xFFFF7A59` (Warm Coral) | `0xFF2B2140` (**5.9:1**) | Warm sunset coral glow | Annoyed / Agacé / متنرفز |
| `heavy` | `0xFFB79CFF` (Soft Lilac) | `0xFF2B2140` (**6.6:1**) | Gentle lavender twilight glow | Low / Abattu / ثقيل وتاعب |
| `restless` | `0xFFFFB85C` (Warm Apricot) | `0xFF2B2140` (**7.8:1**) | Warm amber glow | Restless / Agité / مش ركح |

### 2.4 `withComfortBoost(bool enabled)` Update
- In Sunrise (`Brightness.light`): `line` -> `rgba(43, 33, 64, 0.20)`, `lineStrong` -> `rgba(43, 33, 64, 0.34)`, `ink2` -> `0xFF3F3159` (**10.1:1**), `ink3` -> `0xFF4F406B` (**8.0:1**).
- In Twilight (`Brightness.dark`): `line` -> `rgba(245, 240, 255, 0.24)`, `lineStrong` -> `rgba(245, 240, 255, 0.38)`, `ink2` -> `0xFFE4DCFA` (**11.8:1**), `ink3` -> `0xFFD2C7F0` (**9.8:1**).
- Root text scaling in `main.dart`:
  - Expand upper clamp from `1.35` to **`2.0`** on scrolled screens, OR keep safe app-wide comfort boost `1.18x` default when Comfort Mode is ON while supporting OS `TextScaler` up to **`1.6x–2.0x`** via flexible heights (never fixed `height: 44` or `height: 50` on text containers — always `constraints: BoxConstraints(minHeight: 56)`!).

---

## 3. Typography & Readability Scale (`lib/app/theme/lab_theme.dart`)

| Role | Default Size / Line-Height | Weight | Comfort Mode (+15%) | Strict Rules |
|---|---|---|---|---|
| `displayTitle` | `26sp` / `1.25` | `w800` | `30sp` | Screen hero question ("How are you right now?"). Max 7 words. |
| `sectionTitle` | `19sp` / `1.30` | `w700` | `22sp` | Card group titles. Sentence case ONLY (never ALL CAPS). |
| `cardTitle` | `16.5sp` / `1.35` | `w700` | `19sp` | Primary card title. |
| `body` | `16sp` / `1.50` | `w400` | `18.5sp` | Standard reading text. Left/start aligned, never justified. |
| `buttonLabel` | `16sp` / `1.25` | `w700` | `18sp` | Primary & secondary buttons (`minHeight: 56dp`). |
| `chipLabel` | `14sp` / `1.30` | `w600` | `16sp` | Pills, reply chips, mood labels (`minHeight: 48dp`). |
| `caption` | `12.5sp` / `1.40` | `w500` | `14.5sp` | Timestamps, helper hints. **Hard floor: nothing in `lib/` < `12.0sp`!** |

---

## 4. New Component Specifications

### 4.1 `MoodFace` Widget (`lib/core/widgets/mood_face.dart`) — ZERO EMOJIS
Replaces abstract `20px` icons on mood pickers, check-in summaries, calendar day dots, and onboarding!
- **Geometry (`CustomPainter`):**
  - Soft organic squircle-blob (`size`: `80dp` in 2x3 Home grid, `44dp` in summary headers, `28dp` in calendar day cells) filled with radial gradient of the mood's vivid fill (`#FFC93C`, `#2EC4B6`, `#5AA9FF`, `#FF7A59`, `#B79CFF`, `#FFB85C`), subtle specular top-start highlight (`rgba(255,255,255,0.38)`), and `2.5px` stroke in `#2B2140` when selected.
  - **Drawn Facial Expressions (`#2B2140` round-cap strokes, `strokeWidth = size * 0.055`):**
    1. `good`: happy curved-up arc eyes (`^ ^`) + warm open smile arc + soft rosy cheek dots (`rgba(255, 122, 89, 0.35)`).
    2. `calm`: peaceful closed-lid downward gentle arcs + serene small smile arc.
    3. `anxious`: wide round eyes with tiny raised inner brows + gentle wavy mouth line.
    4. `frustrated`: angled-inward determined brows + firm straight/slightly downturned mouth.
    5. `heavy`: sleepy half-lidded eyes + soft low curve mouth.
    6. `restless`: asymmetric alert eyes (one slightly higher) + lively zigzag/ripple mouth.
- **Physics & Motion:**
  - **Idle (when `reduceMotion == false`):** gentle 3.2s breathing scale (`1.00 <-> 1.035`) + natural 140ms eye blink every ~4.5s.
  - **On Tap (`MindPressable` + spring):** `180ms` jelly squish (`scaleX: 1.08, scaleY: 0.92 -> 1.0`) + `HapticFeedback.selectionClick()` + triggers parent `AnimatedContainer` background mood flood (`420ms` `Curves.easeOutCubic`).
  - **Reduced Motion (`MediaQuery.disableAnimationsOf(context) == true`):** zero idle ticker (`TickerMode` / controller stopped), instant selection ring + instant background tint.
- **Accessibility:**
  - Wrapped in `Semantics(button: true, selected: isSelected, label: moodLabel)` with minimum `72x72dp` hit area on pickers (`48x48dp` everywhere else).

### 4.2 Upgraded `MindButton` (`lib/core/widgets/mind_button.dart`)
- **Primary (`MindButtonVariant.primary`):**
  - Fill: `tokens.primary` (`#6A3DE8` Sunrise / `#B7A2FF` Twilight) — **alive violet, never black/navy!**
  - Text & Icon: `tokens.onPrimary`, `16sp` `w700`.
  - Height: `constraints: const BoxConstraints(minHeight: 56)` (grows vertically if text wraps at `200%` scale — NEVER clips!).
  - Shape: `BorderRadius.circular(20)` with subtle colored elevation shadow (`tokens.primary.withValues(alpha: 0.24)`, `blurRadius: 14`, `offset: Offset(0, 5)` in Sunrise).
- **Soft (`MindButtonVariant.soft`):** `tokens.surface2` fill, `1px tokens.lineStrong`, `minHeight: 52`.
- **Destructive (`MindButtonVariant.danger`):** `tokens.safety` fill, white/dark high-contrast text, used ONLY inside destructive confirmation dialogs.

### 4.3 `MindUndoBanner` (`lib/core/widgets/mind_undo_banner.dart`)
Standard helper `showMindUndoBanner(BuildContext context, {required String message, required String undoLabel, required VoidCallback onUndo})`:
- Floating pill `SnackBar`, `duration: const Duration(seconds: 6)`, `tokens.ink` surface with `tokens.bg` `14.5sp` text and a high-contrast `48dp` tap-target pill button (`tokens.primary` / `#FFD166`) for **`Undo`**.
- Used for: deleting a mood entry, deleting a saved discovery/note, dismissing an insight, clearing a tag, archiving a talk.

---

## 5. Automated Guardrail Tests to Add in Phase 9

1. **Update `test/theme_tokens_contrast_test.dart`:**
   - Replace old Dawn/Vercel hex assertions (`#000000`, `#0A0A0A`, `#F5F6FA`, `#172033`) with the exact Sunrise & Twilight token values in Section 2.2.
   - Keep & expand WCAG contrast assertions: assert `>= 4.5:1` for `ink`, `ink2`, `ink3` on `bg`, `surface`, `surface2`, `onPrimary` on `primary`, and `#2B2140` on all 6 mood fills!
   - Update default `ThemeMode` expectation from `ThemeMode.system` to `ThemeMode.light`.
2. **Update `test/comfort_mode_and_phase7_vqa_test.dart`, `test/step2_primitives_test.dart`, `test/step_4_design_hygiene_test.dart`:**
   - Update ground hex check in `comfort_mode_and_phase7_vqa_test.dart:200` from `#000000`/`#F5F6FA` to `#1B1530`/`#FFF8F0`.
   - Update `AmbientScaffold` test (`step2_primitives_test.dart`) so gentle ambient mood tint renders in BOTH Sunrise (`14%` radial warm wash) and Twilight (`10%` soft indigo-mood glow).
3. **Create `test/ux_copy_and_word_budget_lint_test.dart` (NEW PERMANENT GATE):**
   - Scans `lib/` `.dart` files (excluding `app_strings.dart`, clinician EHR/PDF export templates, and comments) and **FAILS** if:
     - Any UI file contains `strings.isArabic ?` or `isAr ?` returning a `String` literal (only numeric `letterSpacing` / `TextDirection` / font-family switches allowed!).
     - Any patient-facing `app_strings.dart` getter contains banned jargon (`Vagal`, `Somatic`, `Epistemic`, `Catalyst`, `Recovery Ledger`, `Observed Stabilizers`, `Forensic Loop`, `Distortion`, `Granularity`, `Attunement`, `Observatory`, `Investigator`).
     - Any `fontSize:` in `lib/` is `< 11.5`.
     - Any UI file contains Unicode emoji characters.
