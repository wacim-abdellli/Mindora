# Spec 05 — Complete Popups, Notifications, Jargon Rewrites & Inline-String Migration Bible

> **Reads with:** [`00_research_and_rules.md`](../00_research_and_rules.md) and `specs/01..04`.
> **Mission ("Never miss any minimal detail"):** Every single popup/dialog/sheet/snackbar callsite (**all 187 callsites across 37 files**), every single clinical jargon/long getter in `lib/app/localization/app_strings.dart` (**all 83 getters**), every hardcoded inline UI string outside `app_strings.dart` (**all ~94 UI ternaries + English-only / missing-French bugs**), every OS permission prompt, every local notification, and every core shared widget in `lib/core/widgets/` is specified here.

---

## Part 1 — Master Catalog of All 187 Popup, Dialog, Sheet, Toast & SnackBar Callsites

### 1.1 Global Popup Architecture Rules
1. **Single-Item Reversible Deletions -> `MindUndoBanner` (6 seconds, NEVER a blocking `AlertDialog`):**
   - Deleting 1 mood entry, 1 saved talk, 1 toolbox discovery, 1 symptom log, or 1 memory item hides it immediately from the UI list, announces via `SemanticsService.announce`, and shows `MindUndoBanner` (`56dp` height, floating `16dp` above bottom nav, high-contrast `[Undo]` pill `48dp` target). Permanent storage deletion commits only when the 6s timer expires or screen disposes.
   - **Accessibility Rule:** Read `MediaQuery.accessibleNavigationOf(context)` — if screen reader / switch access is active, extend undo timeout from **6 seconds -> 15 seconds** automatically!
2. **Irreversible Multi-Item Purge / Security Changes -> Centered `AlertDialog` (`20dp` radius):**
   - Reserved **strictly** for: (a) `Erase All Data` (`settings_screen.dart:602,655`), (b) `Delete Profile / Clear All Notes` (`privacy_management_sheet.dart:49,105`), (c) `Clear All Imported Patient Records` (`clinician_shell_screen.dart:1519`), and (d) `Crisis Safety Pause` (`safety_interceptor.dart:33`, `barrierDismissible: false`).
   - **Outcome-Named Buttons Mandatory:** Never `[OK] / [Yes]`. Always `[Delete all data] / [Keep my data]`, `[Clear patient list] / [Cancel]`.
3. **Passive Save Confirmations -> `MindToast` (`2.5s`, floating top/bottom pill, non-blocking, zero action button):**
   - Unify all raw `ScaffoldMessenger.of(context).showSnackBar(...)` calls that have no action button into `MindToast.show(context, text)` using `tokens.ink` bg + `tokens.bg` crisp text (`>= 14sp w600`).

### 1.2 Complete Callsite-by-Callsite Conversion Table (`#001` – `#187`)

| Audit IDs (`file:line`) | Current Trigger & Widget | New Target Pattern | Exact Plain Copy (EN / FR / Tunisian AR) |
| :--- | :--- | :--- | :--- |
| **`#001–004`** `lib/core/safety/safety_interceptor.dart:33,43,46,151` | Crisis keyword level 2 -> `AlertDialog` (`barrierDismissible: false`) + `ContextualSupportSheet` | **Keep non-dismissible `AlertDialog`** (`20dp` radius, Sunrise `#FFFFFF` / Twilight `#261E42`) | **Title:** `Pause — you matter` / `Pause — vous comptez` / `لحظة — سلامتك أهم حاجة`<br>**Body:** `You don't have to carry this alone. Free, private help is ready right now.`<br>**Buttons:** `[Call 80 10 50 50]` · `[Call 190 (SAMU)]` · `[Call 198]` · `[Open calm breathing]` · `[I am safe right now]` |
| **`#005–010`** `lib/core/safety/support_button.dart:20,75,106,135` | Tap `[Help]` -> `ContextualSupportSheet`; dialer/URL fallback `SnackBar` | **`MindSheet`** + **`MindToast`** (migrate inline L106/L135 to `app_strings.dart`) | Fallback toast: `Number copied: $phone` / `Numéro copié : $phone` / `تنسخ الرقم: $phone` |
| **`#011–012`** `lib/core/security/lock_overlay.dart:155` | Biometric failed `SnackBar` | **`MindToast`** + inline shake message above PIN pad | `Fingerprint didn't match — enter your PIN` / `Empreinte non reconnue — entrez votre code` / `البصمة ما قراتش — اكتب الرمز متاعك` |
| **`#013–018`** `lib/core/widgets/mind_sheet.dart:14–31`, `mind_toast.dart:18–19` | Base `MindSheet` & `MindToast` primitives | **Upgrade tokens:** `MindSheet` uses `tokens.surface`, `24dp` top corners, `40x5dp` grab handle + visible `48x48dp` `[X]` close button for seniors! | Close semantics: `Close` / `Fermer` / `سكّر` |
| **`#019–020`** `lib/features/auth/presentation/auth_screen.dart:113` | Cloud sync prompt `SnackBar` (hardcoded inline ternary!) | **`MindToast`** via `strings.signInRequiredToast` | `Sign in or continue privately on this phone` / `Connectez-vous ou continuez sur cet appareil` / `ادخل بحسابك ولا كمّل على تليفونك برك` |
| **`#021–025`** `lib/features/case_file/presentation/case_report_screen.dart:57,102,130` | Rename talk `AlertDialog` + crisis check + privacy lock warning `AlertDialog` | Rename -> **`MindSheet` (`RenameTalkSheet`)**; Privacy export block -> **`MindSheet`** with 1-tap `[Unlock for sharing]` or `[Keep private]` | **Title:** `This talk is marked Private` / `Cet échange est privé` / `الحوار هذا خاص ومحمّي`<br>**Buttons:** `[Keep private]` (primary) · `[Allow sharing]` |
| **`#026–027`** `lib/features/case_file/presentation/case_report_screen.dart:182` | Delete talk `AlertDialog` (*"irreversible somatic purge"*) | **CONVERT -> `MindUndoBanner` (6s)** after popping back to `Talk`! | `Talk removed` · `[Undo]` / `Échange supprimé` · `[Annuler]` / `تفسخ الحوار` · `[رجّع]` |
| **`#028–030`** `lib/features/case_file/presentation/clinical_export_preview_sheet.dart:40,103` | Export preview sheet + copied `SnackBar` | **`MindSheet`** + **`MindToast`** | `Summary copied` / `Résumé copié` / `تنسخ الملخص` |
| **`#031–033`** `lib/features/clinician/presentation/clinician_patient_detail_screen.dart:91,1473` | Copy EHR note `SnackBar` + detail sheet | **`MindToast`** + **`MindSheet`** | `Clinic note copied` / `Note clinique copiée` / `تنسخت ملاحظة العيادة` |
| **`#034–036`** `lib/features/clinician/presentation/clinician_shell_screen.dart:1506,1519` | Filter sheet + Clear imported patients `AlertDialog` | **Keep `AlertDialog`** (multi-record irreversible wipe!) | **Title:** `Remove imported patient records?`<br>**Buttons:** `[Remove records]` (danger) · `[Cancel]` |
| **`#037–046`** `clinical_brief_preview_sheet.dart:29,89,133`, `compose_post_visit_focus_sheet.dart:31,149,180` | A4 brief sheet, PDF/copy toasts, care plan composer & delivery toasts | **`MindSheet`** + **`MindToast`** | `Care plan ready to share` / `Plan de suivi prêt` / `برنامج المتابعة حاضر للمشاركة` |
| **`#047–059`** `import_care_focus_sheet.dart:18,79`, `import_patient_packet_sheet.dart:18,80`, `mind_qr_scanner_sheet.dart:31`, `pre_visit_brief_sheet.dart:24`, `share_with_psychiatrist_sheet.dart:48,224,256` | Doctor-patient QR/code handoff sheets + success toasts | **`MindSheet`** (QR always on crisp `#FFFFFF` card) + **Camera Pre-Permission card** inside `MindQrScannerSheet` + **`MindToast`** | `Doctor's plan added to Today` / `Plan du médecin ajouté` / `تزاد برنامج الطبيب لصفحة اليوم` |
| **`#060–063`** `lib/features/home/presentation/home_screen.dart:157,227,313` | Crisis pause + check-in saved `SnackBar` | Crisis -> **`SafetyInterceptor`**; Saved -> **In-card bloom + calm mirror** (only show gentle support banner when `safetyLevel == 1`, zero redundant toast clutter!) | Level-1 gentle bar: `Heavy moment? Tap Help anytime.` / `Moment lourd ? Aide est là.` / `لحظة صعيبة؟ زر مساعدة ديما بحذاك.` |
| **`#064–067`** `lib/features/insights/presentation/insights_screen.dart:79`, `mood_aura_poster_sheet.dart:271,349` | Info sheet + Mood Colors Poster sheet + poster shared `SnackBar` | **`MindSheet`** + **`MindToast`** | `Mood poster ready to save` / `Poster prêt à enregistrer` / `لوحة ألوانك حاضرة للحفظ` |
| **`#068–073`** `lib/features/investigation/presentation/ai_companion_hub_view.dart:44,115,174` | 3 `AlertDialog`s: New talk title (`'Enter title...'` hardcoded!), Rename talk, Delete talk | New talk -> **0 popups! Opens `Talk` immediately and auto-titles from 1st tap/message!** Rename -> **`MindSheet`**. Delete -> **`MindUndoBanner` (6s)**! | `Talk removed` · `[Undo]` / `Échange supprimé` · `[Annuler]` / `تفسخ الحوار` · `[رجّع]` |
| **`#074–081`** `ai_engine_config_sheet.dart:18,135,157`, `custom_ai_instructions_sheet.dart:18,90` | AI config & custom instructions sheets + `SnackBar`s (L90 is English-only bug!) | **`MindSheet`** + localized **`MindToast`** (`strings.customInstructionsSavedToast`) | `Listening preferences saved` / `Préférences d’écoute enregistrées` / `تخزّنت تفضيلات الاستماع` |
| **`#082–089`** `live_dialogue_view.dart:124,305,497,1250`, `mode_chooser_sheet.dart:85`, `journal_memory_sheet.dart:21` | Crisis check, Thinking-trap sheet, talk saved toast, thought saved toast (inline L1250!), mode chooser, memory sheet | **`MindSheet`** + localized **`MindToast`** (`strings.thoughtSavedToast`) | `Saved to your summary` / `Ajouté à votre résumé` / `تحفظت الفكرة في ملخصك` |
| **`#090–091`** `journey_activity_detail_screen.dart:84` | Reflection saved `SnackBar` | **`MindToast`** | `Note saved` / `Note enregistrée` / `تسجّلت ملاحظتك` |
| **`#092–103`** `daily_mind_trace_stepper.dart:144,215,237,330`, `thought_trace_detail_sheet.dart:31,134`, `trace_investigation_sheet.dart:24,75,107` | Custom emotion sheet, trace detail sheet, delete trace `AlertDialog` (L134!), trace reflection toast (inline L107!) | Delete trace -> **CONVERT -> `MindUndoBanner` (6s)**! Migrate L107 to `strings.reflectionSavedToast`. | `Check-in removed` · `[Undo]` / `Entrée supprimée` · `[Annuler]` / `تفسخت التسجيلة` · `[رجّع]` |
| **`#104–117`** `inner_observatory_screen.dart:589`, `add_discovery_sheet.dart:14,107`, `custom_perspective_sheet.dart:14,94`, `custom_symptom_sheet.dart:15`, `symptom_assessment_sheet.dart:28,114`, `symptom_library_view.dart:37` | Delete discovery `AlertDialog` (L589), delete symptom `AlertDialog` (L37), 4 creation sheets + inline `SnackBar`s (L114 missing FR!) | Both single-item deletes -> **CONVERT -> `MindUndoBanner` (6s)**! Fix L114 French translation via `strings.symptomLoggedToast`. | `Body note saved` / `Ressenti enregistré` / `تسجّلت الملاحظة الجسدية`<br>Delete undo: `Item removed` · `[Undo]` |
| **`#118–119`** `onboarding_screen.dart:188,219` | Crisis safety check on custom onboarding text | **Keep `SafetyInterceptor.showCrisisPauseDialog`** | Same as `#001` |
| **`#120–133`** `psychological_profile_view.dart:254`, `condition_status_bottom_sheet.dart:35`, 7 `edit_*_sheet.dart`, `privacy_management_sheet.dart:19,49,105` | Profile edit sheets + Clear All Notes `AlertDialog` (L49) + Reset Profile `AlertDialog` (L105) | Edit sheets -> **`MindSheet`**; Multi-field Clear Notes / Reset Profile -> **Keep `AlertDialog`** (migrate inline L78/94/137/153 to `app_strings.dart`!) | **Buttons:** `[Clear all notes]` / `[Keep notes]` and `[Reset profile]` / `[Keep profile]` |
| **`#134–166`** `clinical_sharing_history_sheet.dart:17,55`, `settings_screen.dart:98–2139` (33 callsites!) | Reminder failed toast, raw JSON Backup/Restore `AlertDialog`s (L144, L299), Edit Name `AlertDialog` (L439, L2139), PIN setup sheet (L464), 2-step Erase Data `AlertDialog`s (L602, L655), Privacy sheet (L771), AI info dialog (L1001), Biometric unavailable toast (L1475), Backup done toast (L1553) | 1. Backup/Restore `AlertDialog`s -> **`MindSheet` with File Share + Dry-Run Preview BEFORE restore!**<br>2. Edit Name & AI Info -> **`MindSheet`**.<br>3. 2-step Erase Everything -> **Keep 2-step `AlertDialog`** with outcome buttons! | Step 1: `[Continue to erase]` / `[Keep my data]`<br>Step 2: `[Delete everything forever]` (`#D92D4B`) / `[Cancel — keep my data]` |
| **`#167–172`** `contextual_support_sheet.dart:36`, `micro_action_card.dart:360`, `routine_anchor_card.dart:299`, `quick_calm_breathing_sheet.dart:18` | Calm sheets + saved-to-discoveries `SnackBar`s (inline L360, L299!) | **`MindSheet`** + **`MindToast`** via `strings.savedToHelpfulToast` | `Saved to What helps you` / `Ajouté à Ce qui vous aide` / `تزاد لـ شنوة يعاونك ترتاح` |
| **`#173–187`** `track_screen.dart:303,377,392,445,510,548`, `track_entry_detail_sheet.dart:41,60,452,488,519` | Custom feeling sheet, crisis pause, pick-a-mood toast, day detail sheet, **Delete entry `AlertDialog` (`track_entry_detail_sheet.dart:60`)** | Delete entry (`L60`) -> **CONVERT -> `MindUndoBanner` (6s)**! | `Check-in removed` · `[Undo]` / `Entrée supprimée` · `[Annuler]` / `تفسخت التسجيلة` · `[رجّع]` |

---

## Part 2 — Complete Jargon & Long-String Rewrite Bible (`lib/app/localization/app_strings.dart`)

Every single getter flagged by our automated audit (**60 jargon getters + 24 >16-word getters**) MUST be updated in `app_strings.dart` to these exact plain, human, Grade-6 strings (`<= 14 words` for UI copy; `<= 22 words` max for mandatory legal/safety notices):

### 2.1 Patient-Facing Jargon & Long Getters (`app_strings.dart`)

| Getter (`Line`) | Old Problem | New English | New Français | New العربية (Tunisian-friendly) |
| :--- | :--- | :--- | :--- | :--- |
| `needExploreDesc` (`L107`) | *"Inner Observatory"* | `Check body signs and helpful notes` | `Noter vos signes physiques et repères` | `سجّل أعراض البدن والأفكار اللي تعاونك` |
| `personalBaselineTitle` (`L273`) | *"Personal Baseline"* | `Your usual rhythm` | `Votre rythme habituel` | `إيقاعك المعتاد` |
| `baselineNeedsMoreData` (`L279`) | *"observation days... baseline"* | `Check in for 3 days to see your usual rhythm` | `3 jours suffisent pour voir votre rythme` | `سجّل 3 أيام باش تكتشف إيقاعك المعتاد` |
| `calibratingBaseline` (`L370`) | *"Calibrating baseline"* | `Learning your rhythm` | `Découverte de votre rythme` | `نتعرّفوا على إيقاعك` |
| `dailyInsightBody` (`L510`, 22w) | *"somatic... prefrontal regulation"* | `Your body often tenses before thoughts race. Naming the feeling helps you slow down.` | `Le corps se tend souvent avant les pensées. Nommer l’émotion aide à ralentir.` | `بدنك يتوتر قبل ما مخك يسرّح. كي تسمّي إحساسك ترجعلك الراحة.` |
| `reframe3Title` (`L656`) | *"Somatic Safety Anchor"* | `My body is safe right now` | `Mon corps est en sécurité ici` | `بدني في أمان توا` |
| `reframe3Body` (`L659`, 18w) | *"nervous system false alarm"* | `This is a stress alarm, not real danger. I am safe right here.` | `C’est une alarme de stress, pas un vrai danger. Je suis en sécurité.` | `هذا إنذار توتر موش خطر حقيقي. أنا في أمان هوني.` |
| `breathingTitle` (`L677`) | *"Vagal Box Pacing"* | `Slow breathing (4-4-4-4)` | `Respiration calme (4-4-4-4)` | `تنفّس هادي (4-4-4-4)` |
| `dataTransparencyTitle` (`L811`) | *"DATA PRIVACY PROTOCOL"* | `Your privacy promise` | `Votre confidentialité` | `حماية خصوصيتك` |
| `privacyPrinciplesBody` (`L819`, 43w) | 43-word legalese wall | `• Saved privately on your phone.\n• Never sold or shared.\n• Private talks never go to doctors.` | `• Gardé en privé sur ce téléphone.\n• Jamais vendu ni partagé.\n• Vos échanges privés restent à vous.` | `• محفوظ في تليفونك بخصوصية.\n• ما يتباعش وما يتشاركش.\n• الحوارات الخاصة تبقى عندك وحدك.` |
| `stageIncident` (`L831`) | *"Activating Catalyst"* | `What happened` | `Ce qui s’est passé` | `شنوة اللي صار` |
| `stageEvidence` (`L834`) | *"Neural & Somatic State"* | `Feeling & first thought` | `Ressenti et pensée` | `الإحساس وأول فكرة` |
| `incidentHelpText` (`L861`) | *"Select a catalyst"* | `Pick what set this off, or add a short note:` | `Choisissez ce qui a déclenché cela :` | `اختار شنوة اللي قلّقك، ولا زيد كلمتين:` |
| `describeSituationWarning` (`L871`) | *"enter a catalyst"* | `Pick a topic above to continue.` | `Choisissez un sujet pour continuer.` | `اختار موضوع من الفوق باش تكمّل.` |
| `proceedToEvidenceBtn` (`L876`) | *"SOMATIC & NEURAL STATE"* | `Next: How it felt` | `Suivant : Votre ressenti` | `التالي: كيفاش حسّيت` |
| `mapChainTitle` (`L882`) | *"Map Somatic & Cognitive..."* | `How did it feel in the moment?` | `Comment l’avez-vous vécu ?` | `كيفاش حسّيتها في اللحظة هاذيكة؟` |
| `triggerLabel` (`L892`) | *"Identified Catalyst"* | `What set it off` | `Ce qui l’a déclenché` | `السبب اللّي حرّك الموقف` |
| `emotionLabel` (`L895`) | *"Primary Somatic State"* | `Main feeling` | `Émotion principale` | `الشعور الأساسي` |
| `emotionalIntensityTitle` (`L900`) | *"SOMATIC AROUSAL INTENSITY"* | `How strong is it?` | `Quelle intensité ?` | `قدّاش قوّتو؟` |
| `findingsSub` (`L978`) | *"empirical reality... distortions"* | `Separating hard facts from worry stories:` | `Séparer les faits réels des scénarios d’inquiétude :` | `نفرّقوا بين الواقع الملموس وسيناريوهات القلق:` |
| `fallbackFindingsSummary` (`L983`, 42w) | *"Empirical Reality... Distortion"* | `• Fact: No clear sign anyone meant harm.\n• Trap: Jumping ahead before knowing.\n• Kinder view: Give it breathing room.` | `• Fait : Aucun signe d’intention négative.\n• Piège : Anticiper le pire trop vite.\n• Recul : Laissez retomber la pression.` | `• الواقع: ما فمّاش دليل على نية خايبة.\n• الفخ: مخك سبق الأحداث.\n• نظرة أهدى: خوذ نفس وخلّي الوقت يوضّح.` |
| `deleteCaseWarning` (`L1064`) | *"somatic... permanently purged"* | `Talk removed` *(used with Undo; if fallback dialog: `Remove this talk from your phone?`)* | `Supprimer cet échange de ce téléphone ?` | `تحب تفسخ الحوار هذا من تليفونك؟` |
| `incidentNarrativeHeader` (`L1074`) | *"1. ACTIVATING CATALYST"* | `1. What happened` | `1. Ce qui s’est passé` | `1. شنوة اللي صار` |
| `observableChainHeader` (`L1080`) | *"2. SOMATIC & NEURAL"* | `2. How it felt & first thought` | `2. Ressenti et première pensée` | `2. الإحساس وأول فكرة` |
| `emotionTag` (`L1104`) | *"SOMATIC STATE: X (8/10)"* | `Feeling: $emotion ($intensity/10)` | `Ressenti : $emotion ($intensity/10)` | `الشعور: $emotion ($intensity/10)` |
| `triggerTitle` (`L1109`) | *"Catalyst"* | `What happened` | `Déclencheur` | `شنوة اللي صار` |
| `emotionHiddenPrivacy` (`L1126`) | *"Somatic state hidden"* | `Feeling hidden (private)` | `Ressenti masqué (privé)` | `الشعور مخفي (خاص)` |
| `supportModalBody` (`L1160`, 26w) | 26-word paragraph | `Going through a hard moment? Free, caring people are ready to listen.` | `Un moment difficile ? Des professionnels gratuits sont là pour vous écouter.` | `تتعدّى بلحظة صعيبة؟ فمّا شكون يسمعك ويعاونك مجاناً وبسرية.` |
| `crisisPauseBody` (`L1170`, 24w) | *"acute hyperarousal"* | `You don't have to carry this alone. Free, private help is ready right now.` | `Ne restez pas seul(e). Une écoute gratuite et confidentielle est disponible maintenant.` | `مانكش وحدك. فمّا مساعدة مجانية وسرية حاضرة تسمعك توا.` |
| `onboardingWelcomeBody` (`L1212`, 18w) | 18w formal copy | `Check in with two taps and see what helps you feel good.` | `Notez votre humeur en deux gestes et voyez ce qui vous fait du bien.` | `سجّل إحساسك في لمستين واكتشف شنوة اللي يريّحك.` |
| `onboardingPrivacyPromise` (`L1217`, 23w) | 23w formal copy | `Private on your phone. Inspired by CBT — not medical therapy.` | `Privé sur votre téléphone. Inspiré des TCC — pas une thérapie médicale.` | `محفوظ في تليفونك بخصوصية. مستوحى من CBT وموش علاج طبي.` |
| `onboardingCrisisSafetyNote` (`L1282`, 23w) | 23w formal copy | `Need urgent help? Tap Help anytime for 80 10 50 50, 190, or 198.` | `Urgence ? Touchez Aide à tout moment (80 10 50 50, 190, 198).` | `تستحق مساعدة عاجلة؟ انزل على مساعدة في أي وقت (80 10 50 50، 190، 198).` |
| `onboardingFirstCheckInSubtitle` (`L1292`) | *"today's baseline"* | `Tap a face and how strong it feels — done in 5 seconds.` | `Touchez un visage et son intensité — fini en 5 secondes.` | `اختار وجه وقدّاش قوّتو — في 5 ثواني برك.` |
| `caseIsPrivateCannotExport` (`L1323`, 18w) | *"privacy shield"* | `This talk is marked Private and is never shared unless you unlock it.` | `Cet échange est privé et n’est jamais partagé sans votre accord.` | `الحوار هذا خاص وما يتشاركش أبداً إلا كان تفتحو بنفسك.` |
| `clinicalDisclaimerNotice` (`L1383`, 18w) | *"Exploratory hypotheses"* | `Inspired by CBT reflection — not a medical diagnosis or therapy.` | `Inspiré des outils TCC — ni diagnostic médical ni thérapie.` | `مستوحى من تمارين CBT — موش تشخيص طبي وموش علاج.` |
| `clinicalSharingHistoryDesc` (`L1395`, 17w) | 17w copy | `Every summary you chose to share (nothing is ever sent automatically).` | `Chaque résumé partagé par vous (aucun envoi automatique).` | `كل ملخص اخترت تشاركو بنفسك (ما يتبعث شي وحدو أبداً).` |
| `welcomeDialoguePrompt` (`L1486`, 24w) | 24w copy | `Take your time. What is on your mind right now?` | `Prenez votre temps. Qu’avez-vous sur le cœur ?` | `خوذ راحتك. شنوة اللّي شاغلك توا؟` |
| `cognitiveDistortionSheetTitle` (`L1544`) | *"COGNITIVE DISTORTIONS"* | `Common thinking traps` | `Pièges de pensée fréquents` | `فخاخ التفكير الشائعة` |
| `tagDistortionBtn` (`L1567`) | *"+ Distortion"* | `+ Tag thought` | `+ Repérer` | `+ فرز الفكرة` |
| `thoughtTraceQuote` (`L1599`, 20w) | Poetic archive quote | `Every small check-in helps you see your days more clearly.` | `Chaque petit point vous aide à mieux comprendre vos journées.` | `كل تسجيلة صغيرة تعاونك تفهم أيامك بوضوح أكثر.` |
| `profileIntroQuote` (`L1631`, 19w) | 19w quote | `Share only what helps Mindora support you.` | `Partagez uniquement ce qui nous aide à vous accompagner.` | `شارك كان اللّي تحبو يعاونك في التطبيق.` |
| `profileSecondaryQuote` (`L1636`, 17w) | 17w quote | `Everything is optional and stays on your phone.` | `Tout est facultatif et reste sur votre téléphone.` | `كل شي اختياري ويبقى في تليفونك.` |
| `shareWithAiDesc` (`L1758`, 18w) | 18w copy | `Lets Talk tailor replies to your goals while staying on your phone.` | `Adapte l’écoute à vos objectifs tout en restant local.` | `يخلّي الحوار يمشي مع أهدافك ويبقى كل شي في تليفونك.` |
| `nonJudgmentalNotice` (`L1835`, 21w) | *"self-attunement"* | `Go at your own pace. Skip or revisit any step anytime.` | `Avancez à votre rythme. Passez ou revenez quand vous voulez.` | `امشي على راحتك. تنجّم تعدّي ولا ترجع لأي خطوة وقت ما تحب.` |
| `onboardingBasicInfoSubtitle` (`L1959`, 18w) | *"physiological context"* | `Helps us keep language comfortable for your age. Skip anything.` | `Aide à adapter le ton à votre âge. Tout se passe si besoin.` | `يعاونّا نختاروا أسلوب مريح لعمرك. تنجّم تعدّي أي سؤال.` |
| `biologicalSexHelperNote` (`L1971`) | *"somatic observation"* | `Optional — used only for energy and sleep tips.` | `Facultatif — utilisé uniquement pour le sommeil et l’énergie.` | `اختياري — يعاون برك في نصائح النوم والطاقة.` |
| `minorSupportNotice` (`L1976`, 29w) | 29w notice | `Mindora is for reflection, not medical care. If you feel unsafe, talk to a trusted adult or call 190.` | `Mindora n’est pas un soin médical. En cas de détresse, parlez à un adulte de confiance ou au 190.` | `التطبيق للتأمل موش للعلاج الطبي. كان حسّيت بضيق كبير كلّم شخص راشد تثق فيه ولا 190.` |
| `symptomsSelectionSubtitle` (`L2070`) | *"Observatory domains"* | `Pick any body or mood signs you want to keep an eye on.` | `Choisissez les signes que vous souhaitez suivre.` | `اختار الأعراض أو المشاعر اللّي تحب تتابعها.` |
| `emotionalVarietyTitle` (`L2611`) | *"EMOTIONAL GRANULARITY"* | `Feelings you named` | `Émotions nommées` | `المشاعر اللّي سمّيتها` |
| `energyAndSleepTitle` (`L2629`) | *"SOMATIC & SLEEP INSIGHTS"* | `Sleep & energy` | `Sommeil et énergie` | `النوم والطاقة` |
| `calendarNoBreaksNote` (`L2646`, 17w) | 17w copy | `Every colored dot is a day you checked in — no streaks to lose.` | `Chaque point coloré compte — aucune série à perdre.` | `كل نقطة ملونة هي نهار سجّلت فيه — بلاش عدّاد يضغط عليك.` |
| `sharePacketTitle` (`L3153`) | *"dossier"* | `Share summary with my doctor` | `Partager un résumé au médecin` | `مشاركة ملخص مع طبيبي` |
| `steadyWithBaseline` (`L3404`) | *"baseline"* | `Close to your usual` | `Proche de votre habitude` | `قريب من عادتك` |
| `fullProgressTrendsSub` (`L3420`) | *"somatic index"* | `Your feelings, sleep, energy, and milestones` | `Vos émotions, sommeil, énergie et étapes` | `مشاعرك، نومك، طاقتك والمحطات المهمة` |
| `baselineSleepComparisonTitle` (`L3431`) | *"Sleep vs baseline"* | `Sleep vs. your usual` | `Sommeil vs habitude` | `النوم مقارنة بعادتك` |
| `baselineMoodComparisonTitle` (`L3434`) | *"Mood intensity vs baseline"* | `Feeling strength vs. your usual` | `Intensité vs habitude` | `قوة الشعور مقارنة بعادتك` |
| `formatBaselineDelta` (`L3441`) | *"baseline"* | Replace `(baseline: X)` -> `(usual: $baseStr)` / `(habitude : $baseStr)` / `(عادتك: $baseStr)` | Same | Same |
| `aiEngineSheetSubtitle` (`L3531`, 21w) | 21w technical copy | `Default: free offline test mode on your phone. Live AI is optional.` | `Par défaut : mode test local gratuit. L’IA en direct est facultative.` | `الوضع العادي: تجريبي مجاني على تليفونك. الربط المباشر اختياري.` |
| `privateCasesExcludedBanner` (`L3861`) | *"dossier"* | `$count private talk(s) left out — private talks are never shared.` | `$count échange(s) privé(s) exclu(s) — jamais partagés.` | `$count حوار(ات) خاصة مستبعدة — الحوارات الخاصة ما تتشاركش أبداً.` |
| `observedStabilizersTitle` (`L4478`) | *"OBSERVED STABILIZERS"* | `What helps you feel better` | `Ce qui vous fait du bien` | `شنوة يعاونك ترتاح` |
| `forensicLoopMapTitle` (`L4636`) | *"OBSERVED FORENSIC LOOP"* | `How a tough moment unfolds` | `Comment un moment difficile s’enchaîne` | `كيفاش تتسلسل اللحظة الصعيبة` |
| `forensicLoopMapSub` (`L4640`) | *"diurnal affect... stabilizers"* | `How events, feelings, thoughts, and helpful habits connect.` | `Lien entre situation, émotion, pensée et ce qui apaise.` | `العلاقة بين الموقف، الإحساس، الفكرة وشنوة اللّي يهدّيك.` |
| `forensicLoopNodeStabilizer` (`L4658`) | *"Observed stabilizer"* | `What helped` | `Ce qui a aidé` | `شنوة عاونك` |
| `milestoneStabilizerSub` (`L4939`) | *"Observed stabilizer"* | `Found what helps` | `Repère apaisant trouvé` | `لقيت حاجة تريّحك` |
| `companionBridgeFocusPrompt` (`L5082`, 19w) | 19w copy | `Let's look at my doctor's step: "$goalTitle". What's one easy start today?` | `Voyons l’étape « $goalTitle ». Quel petit pas faire aujourd’hui ?` | `خلّينا نشوفوا خطوة الطبيب: "$goalTitle". شنوة أبسط بداية اليوم؟` |
| `reliefLoggedConfirm` (`L5130`) | *"Observed Stabilizers"* | `Saved to What helps you` | `Ajouté à Ce qui vous fait du bien` | `تزاد لـ شنوة يعاونك ترتاح` |

### 2.2 Clinician-Only Getters (`L3984–L4265`)
*(Scoped strictly to `ClinicianShellScreen` / `ClinicianPatientDetailScreen` — clean sentence case, zero ALL-CAPS shouting, plain clinical clarity):*
- `kpiBaselineShifts` (`L3984`) -> `Notable shifts` / `Écarts notables` / `تغيّرات ملحوظة`
- `filterDemoCohort` (`L4001`) -> `Sample patients` / `Patients démo` / `ملفات تجريبية`
- `baselineSteadyBadge` (`L4017`) -> `Near usual` / `Stable` / `مستقر`
- `noPatientsEmptyTitle` (`L4021`) -> `No patient summaries yet` / `Aucun résumé patient` / `ما فمّاش ملفات مرضى بعد`
- `noPatientsEmptySub` (`L4025`) -> `Scan a patient code or turn on sample patients.` / `Scannez un code patient ou activez les cas démo.` / `امسح رمز المريض أو فعّل الملفات التجريبية.`
- `cohortObservationsTitle` (`L4031`) -> `Recent shifts across patients` / `Évolutions récentes des patients` / `التغيّرات الأخيرة عند المرضى`
- `cohortAvgMetricsTitle` (`L4043`) -> `7-day averages` / `Moyennes sur 7 jours` / `معدلات آخر 7 أيام`
- `clinicalBoundaryNote` (`L4098`) -> `Supports clinical review — not automated diagnosis. Shows patient-shared data only.` / `Aide à la revue clinique sans diagnostic auto.` / `أداة مساعدة للمعاينة وموش تشخيص آلي.`
- `importSuccessSnackbar` (`L4128`) -> `Patient summary unlocked and added.` / `Résumé patient déchiffré et ajouté.` / `تفتح ملخص المريض وتزاد بأمان.`
- `copyEhrSummaryBtn` (`L4158`) -> `Copy clinic note` / `Copier note clinique` / `نسخ ملاحظة العيادة`
- `recentVsBaselineTitle` (`L4172`) -> `Last 7 days vs. usual` / `7 derniers jours vs habitude` / `آخر 7 أيام مقارنة بالمعتاد`
- `baselineColumnLabel` (`L4184`) -> `Usual` / `Habitude` / `المعتاد`
- `patientNotFoundTitle` (`L4265`) -> `Patient summary not found` / `Résumé patient introuvable` / `ملف المريض موش موجود`

---

## Part 3 — Complete Inline-String Elimination Table (Move All to `app_strings.dart`)

An automated lint test (`test/ux_copy_and_word_budget_lint_test.dart`) will scan `lib/features/**` and `lib/core/**` to guarantee **zero hardcoded English-only strings and zero inline `isArabic ? '...' : (isFrench ? '...' : '...')` UI text ternaries remain outside `app_strings.dart`** (except data catalog models like `DefaultSymptomLibrary` / `DailyContextTags` that intentionally store trilingual `{en, fr, ar}` tuples).

Migrate every single file below into typed `AppStrings` getters/methods:

1. **Bug Fixes (Broken Language Parity Today!):**
   - `lib/features/investigation/presentation/widgets/custom_ai_instructions_sheet.dart:90–91` -> Hardcoded English `'AI Companion instructions updated successfully'` -> `strings.customInstructionsSavedToast`.
   - `lib/features/investigation/presentation/flash_case_screen.dart:150` -> Hardcoded `'AI HUB'` -> remove button label or use `strings.talkSavedPill(count)`.
   - `lib/features/investigation/presentation/ai_companion_hub_view.dart:63,299` -> Hardcoded `'Enter title...'` & `'6 MODES'` -> remove modal / use `strings.listeningStylesCount`.
   - `lib/features/observatory/presentation/widgets/symptom_assessment_sheet.dart:114` -> Missing `isFrench` branch! -> `strings.symptomLoggedToast`.
2. **Safety & Auth (`2 files`):**
   - `lib/core/safety/support_button.dart:106,135,297` -> `strings.dialerCopiedToast(phone)`, `strings.linkCopiedToast(url)`, `strings.infoBadge`.
   - `lib/features/auth/presentation/auth_screen.dart:113–114` -> `strings.signInRequiredToast`.
3. **Home & Track (`3 files`):**
   - `lib/features/home/presentation/home_screen.dart:346` -> `strings.defaultFriendName`.
   - `lib/features/home/presentation/widgets/home_daily_check_in_card.dart:97` -> `strings.viewLabel`.
   - `lib/features/track/presentation/track_screen.dart:510` -> `strings.momentSavedGentleSupport`.
4. **Talk, Case File & Journey (`6 files`):**
   - `lib/features/case_file/data/clinical_export_service.dart:193,237,252,294,297,302,336,339,342,360,365` -> move export section headers to `AppStrings` methods (using plain labels: `Recurring feelings`, `What set it off`, `First thought`, `What supports it`).
   - `lib/features/case_file/presentation/case_report_screen.dart:556,580,596,599` -> `strings.summaryHighlightsHeader`, `strings.talkTranscriptHeader`, `strings.youSpeakerLabel`, `strings.companionSpeakerLabel`.
   - `lib/features/case_file/presentation/clinical_export_preview_sheet.dart:303` -> `strings.exportPreviewLabel`.
   - `lib/features/investigation/presentation/flash_case_screen.dart:235,238` -> `strings.activeTalkTab`, `strings.savedTalksTab`.
   - `lib/features/investigation/presentation/widgets/ai_engine_config_sheet.dart:363` -> `strings.toggleKeyVisibilityTooltip`.
   - `lib/features/investigation/presentation/widgets/live_dialogue_view.dart:265–300,360,747,1251` -> plain thinking-trap names (`strings.trapMindReadingTitle`, `strings.trapCatastrophizingTitle`, `strings.trapAllOrNothingTitle`, `strings.trapEmotionalReasoningTitle`, `strings.trapMentalFilterTitle`, `strings.trapOvergeneralizingTitle`), `strings.clearBtn`, `strings.listeningPrefsLabel`, `strings.thoughtSavedToast`.
   - `lib/features/journey/presentation/journey_activity_detail_screen.dart:243` -> `strings.whyThisHelpsHeader` (replaces `'CLINICAL PURPOSE'` -> `'Why this helps'` / `'Pourquoi cela aide'` / `'كيفاش يعاونك التمرين هذا'`).
5. **Mind Trace & Observatory (`8 files`):**
   - `lib/features/mind_trace/presentation/widgets/daily_mind_trace_stepper.dart:263–1720` -> move remaining labels to `app_strings.dart` (or delegate directly to `ProgressiveDetailsSheet`).
   - `lib/features/mind_trace/presentation/widgets/thought_trace_detail_sheet.dart:120,131,295,377,421,474,546,574` -> `strings.editBtn`, `strings.deleteBtn`, `strings.exploredBadge`, `strings.whatHappenedAndHelpedHeader`, `strings.sleepAndEnergyHeader`, `strings.clearerViewHeader` (replaces `'SOCRATIC DECONSTRUCTION FINDINGS'`), `strings.companionNoteHeader`, `strings.myNoteHeader`.
   - `lib/features/mind_trace/presentation/widgets/trace_investigation_sheet.dart:107` -> `strings.reflectionSavedToast`.
   - `lib/features/observatory/presentation/inner_observatory_screen.dart:592` -> replaced by `MindUndoBanner` (`strings.itemRemovedUndo`).
   - `lib/features/observatory/presentation/widgets/add_discovery_sheet.dart:107,203,283` -> `strings.discoverySavedToast`, `strings.topicHeader`, `strings.mainTakeawayHeader`.
   - `lib/features/observatory/presentation/widgets/custom_perspective_sheet.dart:94` -> `strings.helpfulThoughtSavedToast`.
   - `lib/features/observatory/presentation/widgets/custom_symptom_sheet.dart:133` -> `strings.symptomGroupLabel`.
   - `lib/features/observatory/presentation/widgets/symptom_assessment_sheet.dart:114,371–450,655` -> `strings.symptomLoggedToast`, `strings.backBtn`, + symptom option getters.
   - `lib/features/observatory/presentation/widgets/symptom_library_view.dart:37,127,370` -> `MindUndoBanner` + `strings.bodySignsTab`, `strings.allFilterChip`.
6. **Profile, Progress, Settings, Support & Clinician (`10 files`):**
   - `lib/features/profile/presentation/widgets/condition_status_bottom_sheet.dart:140,310` -> `strings.removeFromProfileBtn`, `strings.updateProfileBtn`, `strings.addToProfileBtn`.
   - `lib/features/profile/presentation/widgets/edit_experiences_sheet.dart:90` -> `strings.doneBtn`.
   - `lib/features/profile/presentation/widgets/privacy_management_sheet.dart:78,94,137,153` -> `strings.keepNotesBtn`, `strings.clearAllNotesBtn`, `strings.keepProfileBtn`, `strings.resetProfileBtn`.
   - `lib/features/progress/data/progress_analytics_service.dart:208,269–472` & `lib/features/progress/domain/progress_analytics_model.dart:31–83` & `lib/features/insights/data/pattern_awareness_service.dart:27,459` -> move milestone titles, plain correlation notes, and time-window pills (`7 days`, `30 days`, `90 days`, `All time` in sentence case!) into `AppStrings`.
   - `lib/features/settings/presentation/settings_screen.dart:98,182,196,275,354,398,1352,1369,1553` -> move backup passphrase labels, reminder frequency chips (`Every day`, `Every 2 days`), and status toasts into `AppStrings`.
   - `lib/features/support/presentation/contextual_support_sheet.dart:144` -> `strings.calmToolsHeader`.
   - `lib/features/support/presentation/widgets/breathing_exercise_card.dart:95–108` -> `strings.breatheInCue` (`Breathe in...`), `strings.holdCue` (`Hold gently...`), `strings.breatheOutCue` (`Breathe out slowly...`), `strings.restCue` (`Rest...`).
   - `lib/features/support/presentation/widgets/micro_action_card.dart:326,360` & `routine_anchor_card.dart:299` -> `strings.doneBtn`, `strings.savedToHelpfulToast`.
   - `lib/features/clinician/presentation/clinician_shell_screen.dart:128–137` -> `strings.formatRelativeTimeAgo(Duration)`.

---

## Part 4 — Notifications, Permissions & Shared Core Widgets (`lib/core/widgets/**`)

### 4.1 Gentle Local Notifications (`lib/core/notifications/gentle_reminder_service.dart`)
- **Zero Streak Guilt Rule:** Never say *"Don't break your streak!"* or *"You forgot to log today!"*
- **4 Rotating Warm Messages (EN / FR / Tunisian AR, `<= 10 words`):**
  1. `How are you feeling right now? Two taps if you'd like.` / `Comment allez-vous ce soir ? Deux gestes suffisent.` / `شنوةحالك توا؟ في لمستين برك كان تحب.`
  2. `Take one slow breath — Mindora is here whenever you want.` / `Prenez une grande respiration — Mindora est là.` / `خوذ نفس هادي — Mindora بحذاك وقت ما تحب.`
  3. `Want to save a quick color for today?` / `Envie de noter la couleur de votre journée ?` / `تحب تسجّل لون نهارك اليوم؟`
  4. `Pause for 5 seconds and check in with yourself.` / `Cinq secondes de pause pour écouter comment ça va.` / `وقفة 5 ثواني تطمّن بيها على روحك.`
- **Default Time:** `20:00` local time (quiet hours respected; 1-tap time picker in `Me -> Daily gentle reminder`).

### 4.2 Core Shared Widgets Token & Accessibility Checklist (`lib/core/widgets/**`)
Every shared widget in `lib/core/widgets/` MUST comply with Sunrise/Twilight tokens, `>= 48dp` touch targets, `>= 12sp` text floor, and `reduceMotion`:
- `botanical_emblem.dart`, `fingerprint_thread_signature.dart`, `icon_blob.dart`: Tint strokes/fills using `tokens.primary`, `tokens.accentWarm`, and `tokens.moodCalm` (retire cold grey/monochrome strokes); freeze continuous rotation/wave loops when `MediaQuery.disableAnimationsOf(context)` is `true`.
- `bouncing_widget.dart`: Use gentle spring scale (`0.96 -> 1.0`, `180ms`), ensure `HitTestBehavior.opaque` and `ConstrainedBox(constraints: BoxConstraints(minWidth: 48, minHeight: 48))`, skip scale animation when `disableAnimations` is `true`.
- `label_badge.dart` & `mind_badge.dart`: Raise minimum font size from `9.5–10.5sp` -> **`12.0sp` (`13.5sp` in Larger Text mode)**, sentence case (ban `.toUpperCase()`), `6dp` vertical / `10dp` horizontal padding.
- `mind_intensity_picker.dart`: Default mode becomes the **3-pill `MindStrengthPicker` (`A little`=`3`, `Medium`=`6`, `A lot`=`9`, `56dp` height)**; keep optional numeric 1–10 mode behind a constructor flag if needed by legacy tests.
- `mind_qr_code.dart`: Always render QR matrix on a `#FFFFFF` quiet-zone container (`16dp` white padding) with `#1B1530` dark modules even in `Twilight` Night mode so physical camera scanners never fail on inverted QR codes!
- `quick_note_sparks_bar.dart`: Upgrade chip height to `48dp`, `14sp w600` (`16sp` Larger Text), Sunrise `#FFF0E3` warm pill background (`#312754` in Night mode).
- `smooth_spline_chart.dart`: Stroke curve with `tokens.primary` (`3.0dp` width) + soft gradient fill (`tokens.primarySoft`), add `Semantics(label: ...)` summary string for TalkBack/VoiceOver so blind/senior screen-reader users hear `"7-day mood trend: mostly Calm"`.
