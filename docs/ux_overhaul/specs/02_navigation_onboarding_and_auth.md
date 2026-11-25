# Spec 02 — App Shell, 5-Tab Navigation, 3-Tap Onboarding, Auth, Safety & Reminders

> **Reads with:** [`00_research_and_rules.md`](../00_research_and_rules.md), [`01_design_system_sunrise_and_mood_faces.md`](01_design_system_sunrise_and_mood_faces.md)
> **Files in scope (11 files):**
> - `lib/app/router/app_router.dart` (261 lines)
> - `lib/app/router/scaffold_with_nav_bar.dart` (313 lines)
> - `lib/app/localization/locale_controller.dart` (52 lines)
> - `lib/features/onboarding/presentation/onboarding_screen.dart` (1,339 lines)
> - `lib/features/auth/presentation/auth_screen.dart` (760 lines)
> - `lib/core/safety/support_button.dart` (314 lines)
> - `lib/core/safety/safety_interceptor.dart` (164 lines)
> - `lib/core/safety/crisis_keywords.dart` (195 lines — DO NOT weaken)
> - `lib/core/safety/safety_model.dart` (166 lines)
> - `lib/core/security/lock_overlay.dart` (209 lines)
> - `lib/core/notifications/gentle_reminder_service.dart` (169 lines)

---

## 1. Current-State Inventory & Problems Found

| File | Current UX / Copy | Why It Hurts Grandpa (68) or Gen Z (19) |
|---|---|---|
| `scaffold_with_nav_bar.dart` | Floating dark-style pill dock (`height: 66`), labels `Home`, `Track`, `AI Guide`, `Insights`, `Profile`; center tab uses abstract sparkle/brain icon | Older adults don't know the difference between `Home` and `Track`, or what `AI Guide` / `Insights` mean. Small labels (`10.5sp`) are hard to read. |
| `onboarding_screen.dart` (1,339 lines, 31 `Text` widgets, 4 steps) | Step 1: poetic quote *"Every thought leaves a trace."* + 23-word privacy paragraph + Comfort toggle + Sign In. Step 2: 6 focus cards + custom text input. Step 3: *"Comfort & safety check"* + 6 age bands + biological sex / support context + 23-word crisis note. Step 4: 5 mood tiles + 1–10 slider + *"Save & Enter App"*. | **8–12 taps and ~190 words before entering the app!** Feels like a hospital intake questionnaire on minute 1. |
| `auth_screen.dart` (760 lines) | Uses terms *"Sovereign Vault"*, *"Anonymous Vault"*, *"Codename"*, `MAXIMUM PRIVACY`, `CREATE ACCOUNT` (ALL CAPS) | "Vault" and "Codename" confuse non-technical older users who just want *"Keep on my phone"* vs *"Back up with email"*. |
| `lock_overlay.dart` | `SESSION LOCKED` (ALL CAPS), `Protected Session Content`, `UNLOCK` | Cold security-terminal tone; snackbar on cancel says *"Biometric verification failed"* (uses "failed" — blames user). |
| `gentle_reminder_service.dart:121-130` | Inline hardcoded ternaries outside `app_strings.dart`; says *"Your daily Mind Trace is waiting..."* | Jargon *"Mind Trace"* + violates `app_strings.dart` rule + no pre-permission explanation before OS dialog. |
| `safety_interceptor.dart:46` & `app_strings.dart:1170` | `crisisPauseBody` says *"Indicators reveal acute hyperarousal. Cognitive analysis becomes counter-productive..."* | **24 words of clinical jargon during a crisis!** Violates Rule 11 Safety Exception (crisis copy must be direct, warm, human, and unmistakable). |

---

## 2. Redesigned 5-Tab Bottom Navigation (`scaffold_with_nav_bar.dart`)

### 2.1 Clear Single-Job Tab Architecture
Keep all existing `GoRouter` route paths (`/home`, `/track`, `/companion`, `/insights`, `/profile`, plus legacy redirects `/mind-trace`, `/progress`, `/toolkit`, `/observatory`) intact so deep links and router tests never break, while renaming the visible tab labels to **1 everyday word + unmistakable icon**:

| Index | Route | Icon (Inactive / Active) | EN | FR | AR (Tunisian) | Single Job of This Tab |
|---|---|---|---|---|---|---|
| 0 | `/home` | `wb_sunny_outlined` / `wb_sunny_rounded` | **Today** | **Aujourd'hui** | **اليوم** | Answer *"How are you?"* in 2 taps + 1 calm action |
| 1 | `/track` | `calendar_today_outlined` / `calendar_month_rounded` | **My days** | **Mes jours** | **أيامي** | Calendar & timeline of past days (no duplicate check-in form) |
| 2 | `/companion` | `chat_bubble_outline_rounded` / `chat_bubble_rounded` | **Talk** | **Parler** | **احكي** | Untangle a worry by tapping chips or chatting |
| 3 | `/insights` | `auto_graph_rounded` / `insights_rounded` | **Patterns** | **Tendances** | **أنماطي** | 3 plain cards: your week, what helps, your mood colors |
| 4 | `/profile` | `person_outline_rounded` / `person_rounded` | **Me** | **Moi** | **أنا** | Text size, theme, reminders, doctor share, backup |

### 2.2 Ergonomics & Visual Spec
- **Height:** `minHeight: 72dp` (plus `SafeArea` bottom inset), each tab hit box `>= 56dp` tall and `>= 60dp` wide.
- **Labels:** Always visible under every icon (never icon-only!), `12.5sp` `w700` active / `12sp` `w600` inactive. At `textScaler >= 1.4x`, label uses `maxLines: 1, overflow: TextOverflow.ellipsis` and dock grows cleanly to `80dp`.
- **Active indicator:** Soft pill (`tokens.primary.withValues(alpha: 0.14)`) behind icon + `tokens.primary` icon & label color + subtle `180ms` spring bounce on selection.

---

## 3. Redesigned 3-Tap First Run (`onboarding_screen.dart` — Sub-25 Seconds)

Cut onboarding from 4 text-heavy pages (~190 words) to **3 joyful, ultra-clear cards (< 45 words total across all 3 steps!)**:

### Wireframe — Step 1 of 3: Language & Text Size (`412px` & `320px`)
```text
+--------------------------------------+
|  [EN]  [Français]  [العربية]         |  <- 48dp language pills (live switch)
|                                      |
|         ( Warm Sunrise Sun /         |
|           Smiling Calm Blob )        |  <- 96dp friendly animated character
|                                      |
|       Welcome to Mindora             |  <- 26sp bold (4 words)
|   Check in with yourself in          |  <- 16sp ink2 (10 words)
|   seconds. Private on your phone.    |
|                                      |
|  TEXT SIZE                           |
|  +---------------+ +---------------+ |
|  |  Aa  Normal   | |  AA  Larger   | |  <- 60dp big 2-card choice!
|  +---------------+ +---------------+ |     (toggles DisplayComfortController)
|                                      |
|  [         Let's start  ->         ] |  <- 56dp Primary Violet pill button
|       I already have a backup        |  <- 48dp text button -> /auth
+--------------------------------------+
```

### Wireframe — Step 2 of 3: Quick Safety & Age Check (1 Tap + `Skip`)
*(Preserves minor safeguard & `PsychologicalProfileModel.ageRange` contract in `onboarding_adaptive_flow_test.dart` without interrogation!)*
```text
+--------------------------------------+
|  <- Back          2 of 3       Skip  |  <- 48dp Back & Skip
|                                      |
|  Which age group fits you?           |  <- 22sp bold (5 words)
|  Helps us keep safety info right.    |  <- 15sp ink2 (6 words)
|                                      |
|  [ Under 18 ]        [ 18 – 24 ]     |  <- 56dp 2-col pills
|  [ 25 – 44  ]        [ 45 – 64 ]     |     (If "Under 18" tapped: calm
|  [   65+    ]                        |      amber card appears w/ 80 10 50 50
|                                      |      + "Talk to a trusted adult")
|  [            Next  ->             ] |  <- 56dp Primary Violet button
+--------------------------------------+
```
*(Note: Goals & biological sex & support-context essays are REMOVED from first-run onboarding! Users can optionally set them anytime in `Me -> About me`.)*

### Wireframe — Step 3 of 3: Your First 2-Tap Mood Check-In!
```text
+--------------------------------------+
|  <- Back          3 of 3       Skip  |
|                                      |
|  How are you feeling right now?      |  <- 24sp bold (6 words)
|                                      |
|   (Good)      (Calm)     (Worried)   |  <- 80dp animated MoodFace characters
|                                      |     with 14sp label underneath
|  (Annoyed)     (Low)     (Restless)  |
|                                      |
|  --- slides in smoothly on tap: ---  |
|  How strong is it?                   |
|  [ A little ] [ Medium ] [  A lot  ] |  <- 52dp 3-choice pills (maps to 3, 6, 8)
|                                      |
|  [      Save & open Mindora        ] |  <- 56dp Primary Violet button
+--------------------------------------+
```
- **Tap count for a brand-new user:** Tap `Let's start` (1) -> Tap `Skip` or Age (2) -> Tap `Calm` face + `Save & open Mindora` (3–4 taps total, **0 typing**, **< 20 seconds**, lands on `Today` already warm-tinted in Teal with their first check-in saved!).

---

## 4. Plain-Language Auth, Lock, Safety & Notifications

### 4.1 `AuthScreen` (`lib/features/auth/presentation/auth_screen.dart`)
- Rename confusing crypto jargon into warm, plain choices:
  - Card 1 (Recommended for most people): **"Keep everything on this phone"** (*"No email or password needed. Private to you."*) -> Button: **`Continue on this phone`** (calls `createAnonymousVault()`).
  - Card 2 (Optional account / sign-in): **"Use email & password"** (*"Sign in or create an account on this device."*) -> Tabs: **`Sign in`** | **`New account`**.
- Plain validation messages (zero *"Invalid"* / *"Failed"*):
  - Bad email -> *"Please check your email address (example: name@mail.com)."*
  - Short password -> *"Use at least 8 characters so your account stays safe."*
  - Wrong password -> *"That email or password didn't match. Please try again."*

### 4.2 `LockOverlay` (`lib/core/security/lock_overlay.dart`)
- Replace `SESSION LOCKED` / `Protected Session Content` with:
  - Friendly lock illustration (`Icons.lock_person_rounded` in `tokens.primary` soft circle)
  - Headline: **`Welcome back`** (`FR: Bon retour` / `AR: مرحبا بيك من جديد`)
  - Subtitle: **`Unlock to see your private space.`** (`FR: Déverrouillez votre espace privé.` / `AR: حلّ القفل باش تدخل لمساحتك الخاصة.`)
  - Primary `56dp` button: **`Unlock`** (`FR: Déverrouiller` / `AR: حلّ القفل`)
  - Retry toast (if dismissed): **`Touch Unlock whenever you're ready.`** (replaces *"Biometric verification failed"*).

### 4.3 `SupportButton` & `SafetyInterceptor` (Crisis Clarity — Rule 8 & Rule 11)
- **Global `SupportButton` (top-end of every main tab):**
  - Keep `>= 48x48dp` shield button in `tokens.safety` with `safetySoft` tint so it is unmistakable on every screen.
- **`SafetyInterceptor.showCrisisPauseDialog`:**
  - Replace the 24-word clinical paragraph (*"hyperarousal... cognitive analysis becomes counter-productive"*) with **direct, warm, Grade-4 human care**:
    - **Title:** `You don't have to carry this alone` (`FR: Vous n'êtes pas seul(e)` / `AR: ماكش وحدك في اللحظة هاذي`)
    - **Body (14 words):** `It sounds like things feel very heavy right now. Free, confidential help is here 24/7.` (`FR: Ce moment semble très lourd. Une écoute gratuite et confidentielle est là 24h/24.` / `AR: واضح اللي اللحظة هاذي صعيبة برشا. فمّا شكون يسمعك ويعاونك مجاناً وبسرّية.`)
    - **Primary `56dp` button (`tokens.safety`):** `Call free helpline (80 10 50 50)` + `See all emergency numbers` (`190` SAMU, `198` Protection Civile — 100% preserved & callable!).
    - **Secondary `48dp` button:** `I'm safe right now — close`

### 4.4 `GentleReminderService` + Pre-Permission Sheet
- Move hardcoded notification title/body (`gentle_reminder_service.dart:121-130`) into `app_strings.dart`:
  - `reminderNotifTitle`: EN `"How are you today?"` | FR `"Comment allez-vous aujourd'hui ?"` | AR `"كيفاش حالك اليوم؟"`
  - `reminderNotifBody`: EN `"Take 5 seconds to check in whenever you feel ready."` | FR `"Prenez 5 secondes pour faire le point, sans pression."` | AR `"خذ 5 ثواني وسجّل شعورك وقت ما تحب، بلاش ضغط."`
- When toggling Reminders ON in `Me`, show a **1-card Pre-Permission Bottom Sheet** *before* calling `requestPermission()`:
  - Headline: `"Get a gentle check-in nudge?"`
  - Body: `"Never guilt-tripping. You choose daily, every two days, or weekly."`
  - Buttons: **`Allow reminders`** (`56dp` primary) and **`Not now`** (`48dp` text button).

---

## 5. Tests Affected & Migration Map

| Test File | Existing Assertion | Required Update |
|---|---|---|
| `test/widget_test.dart` | `find.text('Home')`, `find.text('Track')`, `find.text('AI Guide')`, `find.text('Insights')`, `find.text('Profile')` | Update expected dock labels to `Today`, `My days`, `Talk`, `Patterns`, `Me` |
| `test/technical_polish_test.dart:35,57` | `find.text('Home')`, `find.text('الرئيسية')` | Update to `Today` and `اليوم` |
| `test/onboarding_adaptive_flow_test.dart` | Tests 4 steps + Step 2 focus cards + `Every thought leaves a trace.` | Update to test the 3-step sub-25s onboarding (`Welcome to Mindora`, `Normal`/`Larger` text size card, Age & `Under 18` safeguard, 2-tap `MoodFace` first check-in, and `Skip` flow) |
| `test/auth_test.dart:295` | `AuthScreen renders tabs, anonymous vault card, and input fields` | Update UI text finders (`Continue on this phone`, `Sign in`, `New account`) while keeping all 14 crypto/PBKDF2 unit tests untouched |
| `test/biometric_security_test.dart:115` | `find.text('SESSION LOCKED')`, `find.text('UNLOCK')` | Update to `Welcome back` and `Unlock` |
| `test/contextual_support_test.dart` | Verifies `80 10 50 50`, `190`, `198` & `SupportButton` | Keep all 3 hotline numbers verbatim so safety tests pass 100% |
