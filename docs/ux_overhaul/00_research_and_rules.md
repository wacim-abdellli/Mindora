# 00. Research, Rules and Design Foundation (read this first)

This file is the shared rulebook for the whole UX overhaul. Every spec in `docs/ux_overhaul/specs/` and the master prompt in `docs/ux_overhaul/01_MASTER_AGENT_PROMPT.md` obey it.

## 1. What the product owner asked for (24 Nov 2026, own words condensed)

- The app has **far too much text**. People may not understand it.
- It must be **user friendly for two groups at once**: older people who do not know phones well, and Gen Z who know the internet well. Balance both.
- **Each part must do one job.** Example: Home = the quick questions and tracking. Track = history.
- Logging must **not feel like a hard task or cost energy**. It should be fun, something users want to open. Interactive, easy.
- **Live, bright colors. Not dark. Not a "dead UI".**
- Plan every part of the app: **copy, pop-ups, and the smallest details.** Nothing may be missed.

## 2. Personas (design for both, test with both)

| Persona | Who | Needs | Test setup |
|---|---|---|---|
| **Amel, 68** | Retired, uses WhatsApp and calls, reads Arabic (Tunisian dialect) and French | Big text, big buttons, words she knows, one thing at a time, nothing hidden behind gestures, never feels lost | 320 px wide, text scale 1.35x to 2.0x, Arabic right-to-left, TalkBack on |
| **Yassine, 19** | Student, lives in apps, short attention, likes motion and personality | Instant feedback, color, playful motion, shareable stuff, no lecture tone, no forms | 412x915, text 1.0x, English and French, haptics on |
| **Nour, 34** | Busy parent, anxious evenings, uses the app in 10 seconds at night | Fast log, calm, nothing guilt-making, easy relief tool | Dark/Night mode, one hand |
| **Dr. Amira** | Psychiatrist using the clinician workspace | Dense but clear, scannable, print-ready | Tablet 1180x820 and phone |

## 3. Research summary (what we learned and how it changes the app)

Sources: UX literature on mental health apps, WCAG 2.2, Material 3 Expressive, Flutter accessibility docs, UX writing guidance, Finch / Daylio / Stoic / Bearable teardown articles, Hick's law and dialog/sheet pattern guidance.

| Finding | Rule we adopt |
|---|---|
| People using mental health apps have low mental energy. Flashy or dense UI makes them quit. | Max **one primary decision per screen**. Calm layout. Progressive disclosure. |
| The best check-ins take **under 10 seconds** and a few taps. Daylio proved text-free logging works. | First check-in = **2 taps** (face, then strength). Everything else is optional and comes after saving. |
| Tags and notes must **never be mandatory**. Any data point is valid. | Save is always enabled after the first tap. "Skip" on every optional step. |
| Streaks cause guilt. Finch, Stoic and Bearable use care, patterns and totals instead. | **No streaks. No "you missed". No broken chains.** Use "days you showed up" totals, cozy rewards, neutral insights ("Wednesdays tend to feel heavier"). |
| Delight beats grades: customization, play, soft rewards. | A drawn character per mood, color flood, soft bloom on save, unlockable cozy touches. No leaderboards, no points. |
| Material 3 Expressive research (46 studies, 18,000 people): expressive color, shape and spring motion made key elements findable up to 4x faster and were liked across ages, not only by young people. Risk: too much emotion on serious tasks. | Be expressive on daily mood and rewards. Be **calm and plain** on crisis, privacy, delete, and clinical screens. |
| Pure black with pure white causes glare and eye strain. Warm deep tones are easier and feel safer. | Night mode uses deep indigo, never `#000000`. Text is warm off-white, never `#FFFFFF`. |
| Never rely on color alone. | Every color meaning also has a shape, icon, or word. |
| WCAG 2.2 AA target size is 24x24 px minimum. Material says 48x48 dp. Seniors need more space between targets. | Main actions **56 dp**, all other targets **48 dp minimum**, **12 dp** gap between neighbors. |
| Seniors: body 18 to 20 px, line height 1.5, no justified text, avoid blocks of ALL CAPS, support 200% text. | Body **16 sp default, 18 sp in Comfort mode**, line height 1.5, left (start) aligned, no ALL CAPS beyond one short label. Layouts must survive **200%** text. |
| Plain language at grade 6, 10 to 12 words per sentence, active voice, outcome-named buttons. | See section 7 (copy rules). |
| Dialog for irreversible, sheet for contextual, **undo snackbar for reversible**. | See section 8 (pattern chooser). |
| Crisis help must be 1 to 2 taps from anywhere. Notifications must never guilt. | Keep the existing global support button and hotlines. Notification copy is warm and optional. |
| RTL: use start/end geometry, mirror directional icons, Arabic text is longer. | No `left/right`, only `start/end`. Test Arabic at 320 px. |

## 4. Hard project rules (from `AGENTS.md`; do not break)

1. **Zero emojis in the UI** (widgets, buttons, sheets, badges, notifications). Use drawn vector characters and icons.
2. **Trilingual**: every user-facing string comes from `app_strings.dart` through `appStringsProvider` (EN, FR, authentic Tunisian Arabic). No inline `isArabic ? ... : ...` in screens (there are about 83 today; remove them).
3. **Safety**: never disable or bypass `crisis_keywords.dart` or `safety_interceptor.dart`. Hotlines stay intact and callable: Ligne Verte `80 10 50 50`, SAMU `190`, Protection Civile `198`.
4. **Forbidden content**: diet, calorie or weight advice. Predicting relapse. Calling anything "CBT treatment" or "therapy" (say "inspired by CBT"). Copying text from other apps or books.
5. **Free tier and mock AI** during development (`MockInvestigatorService`). Remind the owner about billing and data terms at the pre-launch steps (see `docs/PRODUCTION_LAUNCH_CHECKLIST.md`).
6. **Persistence**: active investigations stay hydrated across navigation and restart. Any model change is serialized in `toJson` / `fromJson`.
7. **Privacy**: `CaseModel.isPrivate == true` stays out of every shareable surface.
8. **Options-first**: choices before blank text boxes. A text box is never the only way forward.
9. **Zero regressions**: `flutter analyze --no-pub` and `flutter test` both pass before every commit.
10. **Palette rule update (decision of 24 Nov 2026)**: `AGENTS.md` rule 6 (pure black "Vercel" palette, 8 to 10 px radii) is **replaced** by this document's section 5. The first milestone of the master prompt edits `AGENTS.md` accordingly. If the owner objects, they say so before that milestone starts.

## 5. Visual system: "Sunrise" (default) and "Twilight" (optional night)

Default for new users is **Sunrise light**. The app does **not** follow the phone's dark setting by default. Night mode is a user choice.

### 5.1 Color tokens (contrast checked with the WCAG formula)

| Token | Sunrise (light) | Twilight (night) | Use |
|---|---|---|---|
| `bg` | `#FFF8F0` warm cream | `#1B1530` deep indigo | Page background |
| `surface` | `#FFFFFF` | `#261E42` | Cards, sheets |
| `surface2` | `#FFF0E3` peach tint | `#322857` | Wells, inputs, tracks |
| `ink` | `#2B2140` deep plum | `#F5F0FF` warm off-white | Main text |
| `ink2` | `#5A4B73` | `#CFC4EB` | Secondary text |
| `ink3` | `#6B5C85` | `#B7AAD9` | Hints, captions |
| `primary` | `#6A3DE8` violet (white text) | `#B7A2FF` lilac (dark text `#1B1530`) | Main buttons, selected state |
| `primaryDeep` | `#5B2FD0` | `#9C86FF` | Pressed state |
| `safety` | `#B3263E` | `#FF8A98` | Crisis and delete only |
| Mood: Calm | `#2EC4B6` teal | same | Calm face and tint |
| Mood: Happy / Good | `#FFC93C` sun yellow | same | Good face and tint |
| Mood: Anxious | `#5AA9FF` sky | same | Anxious |
| Mood: Frustrated | `#FF7A59` coral | same | Frustrated |
| Mood: Heavy | `#B79CFF` lilac | same | Heavy |
| Mood: Restless | `#FFB85C` apricot | same | Restless |

Measured contrast (must stay true in tests): ink on bg 14.3, ink on surface 15.1, ink2 on bg 7.4, ink3 on bg 5.7, white on primary 6.1 (7.6 for `primaryDeep`), ink on every mood fill 5.9 to 9.8, safety on bg 6.1, Night ink on bg 15.7, Night ink2 on surface 9.5, Night ink3 on surface 7.3, Night dark-ink on primary 8.0.
**Do not** put white text on Night `#7C5CFF` (4.35, fails).

Rules: backgrounds may use soft gradients of 2 mood tints (max 12% opacity over `bg`) for life. Primary buttons are **violet, not navy or black**. A mood's color floods the check-in background after the user picks it. Comfort mode (existing) still adds +15% text and stronger borders on top of either theme.

### 5.2 Shape, space, type, motion

| Token | Value |
|---|---|
| Radius | Cards 24, buttons 20 (pill for primary), chips 16, sheets 28 top, mood tiles 28 |
| Spacing scale | 4, 8, 12, 16, 20, 24, 32, 40. Screen padding 20. Gap between tappable neighbors at least 12 |
| Min target | 48 dp. Main actions 56 dp. Mood faces at least 72 dp (96 dp on Home) |
| Type | Font Inter (Latin) and Noto Sans Arabic. Display 28/34 bold, Title 22/28 semibold, Body 16/24, Body large (Comfort) 18/27, Label 14/20 medium, Caption 12/18. **Minimum size anywhere: 12 sp. Nothing below 11.5.** |
| Case | Sentence case. ALL CAPS only for one short tiny label, never in Arabic |
| Elevation | Soft colored shadows (tinted by the card mood, 8% to 14%) in Sunrise. Borders 1 px `line` in Twilight |
| Motion tokens | Tap feedback 120 ms scale 0.97 (spring). Card enter 280 ms ease-out-cubic. Sheet 320 ms. Mood color flood 450 ms. Reward bloom 700 ms max. Reduced motion: every duration 0, no loops, no parallax, keep color and text change |
| Haptics | Selection tick on every choice. Light impact on save. Never heavy impact except crisis |
| Sound | None |

## 6. Mood faces (replace small icon tiles; no emojis)

Five core moods, drawn as vector characters (blob with eyes and mouth), each with an idle animation and a tap animation:

| Mood | Plain label EN / FR / AR (Tunisian) | Face idea | Idle | On tap |
|---|---|---|---|---|
| Calm | Calm / Calme / مرتاح | soft smile, closed eyes | slow breathing scale 1.0 to 1.04 | sigh squish, teal floods bg |
| Anxious | Worried / Inquiet / قلقان | wide eyes, small wavy mouth | tiny shiver | wobble, sky floods |
| Frustrated | Annoyed / Agacé / متنرفز | brows down, flat mouth | slow pulse | quick shake, coral floods |
| Heavy | Low / Abattu / ثقيل | droopy eyes, flat mouth | slow sink | settle down, lilac floods |
| Restless | Restless / Agité / مش مرتاح | eyes darting, mouth zigzag | gentle bounce | spin, apricot floods |

Add a sixth, **Good** (happy, yellow), if the product owner approves (many users want a clearly positive option). It is listed as an open decision in the master prompt.

## 7. Copy rules

1. Grade 6 reading level. 10 to 12 words per sentence, **9 words or fewer** for headlines, **14 words or fewer** per card body, **3 words or fewer** per button where possible.
2. Active voice. Talk to "you". Warm, calm, never clinical, never bossy, never slangy (older users must understand).
3. Buttons name the outcome: "Save", "Delete this entry", "Keep it". Never "Yes / No / OK / Submit".
4. Errors say what happened and how to fix it. Never "failed", "invalid", or codes.
5. Empty states: what is missing + why it helps + one next step.
6. Confirm dialogs: question title, one sentence of consequence, two outcome buttons, safe option first.
7. No jargon. Use the glossary below on every patient-facing surface.
8. One idea per sentence. No semicolons. No double negatives.
9. Numbers: use digits. Dates short and local.
10. Arabic uses Tunisian dialect where natural, plain Arabic otherwise. French uses "vous" and short sentences. Provide all three for every string.

### Glossary (patient-facing; clinician screens may keep clinical words but still plain)

| Old word | New word EN | FR | AR (Tunisian) |
|---|---|---|---|
| Home | Today | Aujourd'hui | اليوم |
| Track | My days | Mes jours | أيامي |
| Companion / Investigator / AI Guide | Talk | Parler | احكي |
| Insights | My patterns | Mes tendances | أنماطي |
| Profile / Settings | Me | Moi | أنا |
| Observatory | Toolbox | Boîte à outils | الأدوات |
| Check-in | Check-in (or "How are you?") | Point du jour | كيفاش حالك |
| Intensity | How strong? (A little / Medium / A lot) | Quelle force ? (Un peu / Moyen / Beaucoup) | قدّاش قوي؟ (شوية / وسط / برشا) |
| Observed Stabilizers / Recovery Ledger | What helps me | Ce qui m'aide | اللي يعاوني |
| Forensic Loop Map | How it unfolds | Comment ça se déroule | كيفاش يتسلسل |
| Fact / Assumption / Interpretation | Fact / Guess / Story | Fait / Supposition / Histoire | حقيقة / ظنّ / حكاية |
| Cognitive distortion | Thinking trap | Piège de pensée | فخّ التفكير |
| Vagal Box Pacing | Box breathing | Respiration carrée | تنفّس مربّع |
| 5-4-3-2-1 Sensory Grounding | Look around you | Regardez autour de vous | شوف حواليك |
| Case / Session / Deconstruction | Saved talk | Échange enregistré | حديث محفوظ |
| Baseline | Your usual | Votre habitude | عادتك |
| Clarity Anchor | Calm reminder card | Carte de calme | بطاقة التهدئة |
| Care focus / Post-visit focus plan | Plan from your doctor | Plan de votre médecin | خطّة طبيبك |
| Psychological profile | About me | À propos de moi | عليّ |
| Mood Aura | My mood colors | Mes couleurs | ألواني |

## 8. Pattern chooser for pop-ups (every pop-up in the app must be assigned one)

| Situation | Pattern | Rules |
|---|---|---|
| Reversible and frequent (delete an entry, remove a tag, clear a draft) | **Do it now + Undo snackbar**, 6 s | Text: what happened. Action: "Undo". Announced to screen readers. |
| Irreversible or high stakes (delete all data, sign out of vault, reset) | **Dialog** | Title is a question. Consequence in one sentence. Safe button first and neutral. Destructive button names the outcome and uses `safety` color. Never pre-focused. Extreme risk only: type a word to confirm. |
| Choosing among 3 to 6 options, forms, sharing, details | **Bottom sheet** | Drag handle, close button 48 dp, primary action at the bottom within thumb reach. |
| Short confirmation of a good action ("Saved") | **Toast pill** (not a dialog) | 2.5 s, icon + 3 words, no action needed. |
| Permission asks (camera, biometrics, notifications) | **Pre-permission sheet** before the OS prompt | One sentence of why, one benefit, buttons "Allow" and "Not now". |
| Crisis | **Crisis sheet** (existing) | Direct, clear, no playful motion, hotline buttons 56 dp. |
| Blocking error (offline, storage full) | **Inline banner** at the top of the screen, retry button | Never a dialog unless the user cannot continue. |

## 9. Anti-patterns to remove everywhere

Streak or "missed" language. Blank text box as the only path. Sliders as the main input for 1 to 10 scores. Icon-only buttons without labels or tooltips. Nested tabs inside tabs. Text smaller than 12 sp. ALL CAPS paragraphs. Dialogs for success. Same job offered on two screens. Technical words in patient copy. Pure black backgrounds. White text on mid-tone fills under 4.5:1.

## 10. Spec template (every domain spec in `specs/` follows these 11 sections)

1. Scope and files (path and line count)
2. Current-state inventory: every screen state, every visible string (key or inline), every dialog, sheet, snackbar, toast, tooltip, semantics label, empty, loading and error state, every haptic. Table: Element, Current copy, Problem
3. Counts: taps, decisions and words above the fold today, and targets
4. Redesign per screen: ASCII wireframe at 412 px, 320 px and 200% text. Component specs (size, token, radius, states: default, pressed, selected, disabled, error, loading, empty). Motion and haptics
5. Flows: step by step, tap counts, Skip, Back, Undo, error recovery
6. **Copy deck**: every string with key name, EN, FR, AR, word count and which rule it follows
7. Accessibility: semantics labels, focus order, 200% text, RTL, color independence
8. Safety and rules compliance
9. Tests: new tests, existing tests that will break (file and test name), acceptance checklist
10. Implementation task list: ordered, with file paths, size (S, M, L) and dependencies
11. Risks and open questions
