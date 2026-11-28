import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/clinic_sync/domain/clinic_account_models.dart';
import '../../features/clinician/data/clinician_sync_service.dart';
import '../../features/investigation/domain/label_type.dart';
import '../../features/journey/domain/journey_phase.dart';
import '../../features/profile/domain/condition_type.dart';
import '../../features/profile/domain/diagnostic_status.dart';
import 'locale_controller.dart';

/// Central type-safe medical & cognitive neuropsychological dictionary for Mindora.
///
/// Supports English ('en'), Français médical ('fr'), and authentic Tunisian Arabic ('ar').
class AppStrings {
  final String languageCode;

  const AppStrings(this.languageCode);

  bool get isArabic => languageCode == 'ar';
  bool get isFrench => languageCode == 'fr';

  // Navigation (5 Standard Destinations: Home, Track, AI Guide, Insights, Profile)
  String get navHome => isArabic ? 'الرئيسية' : (isFrench ? 'Accueil' : 'Home');
  String get navObservatory =>
      isArabic ? 'الأدوات' : (isFrench ? 'Outils' : 'Tools');
  String get navInnerObservatory => isArabic
      ? 'أدوات العناية'
      : (isFrench ? 'Outils Bien-être' : 'Self-Care Tools');
  String get navAiGuide =>
      isArabic ? 'المتابعة' : (isFrench ? 'Suivi' : 'Care Consult');
  String get navInvestigator =>
      isArabic ? 'استشارة طبية' : (isFrench ? 'Consultation' : 'Clinical Consult');
  String get navProfile =>
      isArabic ? 'ملفي' : (isFrench ? 'Profil' : 'Profile');

  // Contextual Support
  String get contextualSupportTitle => isArabic
      ? 'أدوات التهدئة والدعم'
      : (isFrench ? 'Outils d’apaisement' : 'Calm & grounding tools');
  String get whatWouldHelpPrompt => isArabic
      ? 'شنوة يعاونك توا؟'
      : (isFrench
            ? 'De quoi avez-vous besoin maintenant ?'
            : 'What would help right now?');
  String get whatWouldHelpSubtitle => isArabic
      ? 'اختر نقطة انطلاق هادية ومباشرة، من غير أي استبيان أو ضغط'
      : (isFrench
            ? 'Choisissez une aide simple et directe, sans aucun questionnaire ni pression'
            : 'Choose a calm, immediate starting point with zero pressure or lengthy forms');
  String get homeSupportCardTitle => isArabic
      ? 'تحتاج مساعدة أو تهدئة توا؟'
      : (isFrench
            ? 'Besoin d’aide ou d’apaisement ?'
            : 'Need support right now?');
  String get homeSupportCardSub => isArabic
      ? 'اختر نقطة انطلاق هادية ومباشرة حسب حاجتك'
      : (isFrench
            ? 'Choisissez un point de départ doux et direct selon votre besoin'
            : 'Choose a gentle starting point based on what you need.');
  String get needPracticalSupportNow => isArabic
      ? 'نحتاج دعم عملي توا'
      : (isFrench
            ? 'Besoin d’aide concrète maintenant'
            : 'I need something practical right now');
  String get needSettleTitle => isArabic
      ? 'نحب نهدّي روحي'
      : (isFrench ? 'J’ai besoin de m’apaiser' : 'I need to settle myself');
  String get needSettleDesc => isArabic
      ? 'تنفس مهدئ أو تثبيت حسي في المكان'
      : (isFrench
            ? 'Respiration guidée ou ancrage sensoriel'
            : 'Paced breathing or sensory grounding');
  String get needThoughtsTitle => isArabic
      ? 'أفكاري مشابكة ونحس روحي واحل'
      : (isFrench
            ? 'Je suis coincé dans mes pensées'
            : 'I’m stuck in my thoughts');
  String get needThoughtsDesc => isArabic
      ? 'فصل الواقع عن التخمينات والتأويلات'
      : (isFrench
            ? 'Démêler les faits des suppositions'
            : 'Untangle facts from assumptions and interpretations');
  String get needActionTitle => isArabic
      ? 'مانيش قادر نبدى في حتى شي'
      : (isFrench
            ? 'Je n’arrive pas à démarrer'
            : 'I can’t get myself started');
  String get needActionDesc => isArabic
      ? 'خطوة ميكرو-بسيطة تدوم دقيقتين فقط'
      : (isFrench
            ? 'Un tout petit pas gérable de deux minutes'
            : 'A manageable two-minute action to overcome inertia');
  String get needRoutineTitle => isArabic
      ? 'نحب نعاون روحي في الروتين اليومي'
      : (isFrench
            ? 'J’ai besoin d’aide avec ma routine'
            : 'I need help with my routine');
  String get needRoutineDesc => isArabic
      ? 'إرساء نقطة توازن وحدة في يومك'
      : (isFrench
            ? 'Poser un point d’ancrage simple dans votre journée'
            : 'Establish one gentle anchor point in your day');
  String get needExploreTitle => isArabic
      ? 'نحب نستكشف حاجة أخرى'
      : (isFrench
            ? 'Je souhaite explorer autre chose'
            : 'I want to explore something else');
  String get needExploreDesc => isArabic
      ? 'سجّل أعراض البدن والأفكار اللي تعاونك'
      : (isFrench
            ? 'Noter vos signes physiques et repères'
            : 'Check body signs and helpful notes');
  String get needCrisisHelp => isArabic
      ? 'طوارئ: مساعدة عاجلة وخطوط استماع'
      : (isFrench
            ? 'Besoin d’aide immédiate : Urgences'
            : 'Need help now: Emergency crisis lines');
  String get emergencyCallDirect => isArabic
      ? 'خطوط المساعدة النفسية والطوارئ الرسمية'
      : (isFrench
            ? 'Lignes d’écoute et services d’urgence officiels'
            : 'Official crisis and emergency helplines');

  // Sensory Grounding (5-4-3-2-1)
  String get sensoryGroundingTitle => isArabic
      ? 'التثبيت الحسي 5-4-3-2-1'
      : (isFrench
            ? 'Ancrage sensoriel 5-4-3-2-1'
            : '5-4-3-2-1 Sensory Grounding');
  String get sensoryGroundingDesc => isArabic
      ? 'إعادة توجيه الانتباه نحو الحواس والمكان الحاضر'
      : (isFrench
            ? 'Réorienter doucement votre attention sur votre environnement'
            : 'Gently reconnect with your immediate physical environment');
  String get groundingSee => isArabic
      ? '5 حاجات تراهم دايرين بيك'
      : (isFrench ? '5 choses que vous voyez' : '5 things you see around you');
  String get groundingTouch => isArabic
      ? '4 حاجات تنجم تمسهم توا'
      : (isFrench
            ? '4 choses que vous pouvez toucher'
            : '4 things you can physically touch');
  String get groundingHear => isArabic
      ? '3 أصوات تسمع فيهم في اللحظة'
      : (isFrench ? '3 sons que vous entendez' : '3 sounds you hear right now');
  String get groundingSmell => isArabic
      ? '2 روائح تشم فيهم أو تتفكرهم'
      : (isFrench
            ? '2 odeurs que vous percevez ou imaginez'
            : '2 scents you notice or recall');
  String get groundingTaste => isArabic
      ? 'إحساس واحد ملموس في فمك أو نفس نقي'
      : (isFrench
            ? '1 sensation physique ou goût de l’air'
            : '1 physical sensation or taste of fresh air');

  // Self-Care Tools Hub (formerly Inner Observatory)
  String get observatoryTitle => isArabic
      ? 'أدوات العناية'
      : (isFrench ? 'Outils Bien-être' : 'Self-Care Tools');
  String get observatorySubtitle => isArabic
      ? 'أدوات بسيطة وهادئة لتهدئة البال وفهم الأفكار'
      : (isFrench
            ? 'Outils simples pour apaiser le mental et prendre du recul'
            : 'Simple, practical tools to calm your mind and gain clarity');
  String get sectionSymptomExploration => isArabic
      ? 'الجسم والأعراض'
      : (isFrench ? 'Corps & Ressenti' : 'Body & Mind');
  String get sectionPerspectiveExploration => isArabic
      ? 'تغيير زاوية النظر'
      : (isFrench ? 'Recadrer' : 'Reframe Thought');
  String get sectionExperimentsStrategies => isArabic
      ? 'خطوات عملية'
      : (isFrench ? 'Actions Simples' : 'Coping Steps');
  String get sectionPersonalDiscoveries =>
      isArabic ? 'خلاصاتي' : (isFrench ? 'Notes Sauvées' : 'Saved Notes');

  // Quick Feature Hub on Home (1-Tap Reachability)
  String get quickAccessHeader =>
      isArabic ? 'الوصول السريع' : (isFrench ? 'ACCÈS RAPIDE' : 'ALL FEATURES');
  String get quickAiSubtitle => isArabic
      ? 'حوار واعي وهادئ'
      : (isFrench ? 'Échange apaisé' : 'Guided reflection');
  String get quickToolsTitle => isArabic
      ? 'أدوات التهدئة'
      : (isFrench ? 'Outils calmes' : 'Self-Care Tools');
  String get quickToolsSubtitle => isArabic
      ? 'تنفس، أفكار وخطوات'
      : (isFrench ? 'Respiration & recul' : 'Breathing & coping');
  String get quickCalendarTitle => isArabic
      ? 'التقويم والسجل'
      : (isFrench ? 'Calendrier' : 'Calendar & Log');
  String get quickCalendarSubtitle => isArabic
      ? 'تتبع الأيام والأشهر'
      : (isFrench ? 'Vue mensuelle' : 'History & streaks');
  String get quickInsightsTitle => isArabic
      ? 'التحليلات والتقرير'
      : (isFrench ? 'Tendances' : 'Insights & Export');
  String get quickInsightsSubtitle => isArabic
      ? 'أنماطك وملخصك'
      : (isFrench ? 'Bilan & courbes' : 'Mood trends');

  // Common Actions & Navigation
  String get backBtn => isArabic ? 'رجوع' : (isFrench ? 'Retour' : 'Back');

  // Backward compatibility tab aliases
  String get navJournal =>
      isArabic ? 'السجل' : (isFrench ? 'Journal' : 'Journal');
  String get navToolkit =>
      isArabic ? 'صندوق الأدوات' : (isFrench ? 'Boîte à outils' : 'Toolkit');
  String get navTrack => isArabic ? 'تتبّع' : (isFrench ? 'Observer' : 'Track');
  String get navCompanion =>
      isArabic ? 'الرفيق الذكي' : (isFrench ? 'Compagnon IA' : 'AI Companion');
  String get navInsights =>
      isArabic ? 'التحليلات' : (isFrench ? 'Analyses' : 'Insights');
  String get navCases => navJournal;
  String get navTools => navToolkit;
  String get navSettings => navProfile;
  String get newInvestigation => isArabic
      ? 'استكشاف فكري جديد'
      : (isFrench ? 'Nouvelle Réflexion' : 'New Thought Exploration');

  // Memory Log
  String get memoryVaultTitle => isArabic
      ? 'سجل الذاكرة'
      : (isFrench ? 'Journal de mémoire' : 'Memory Log');
  String get memoryVaultDesc => isArabic
      ? 'عرض ومراجعة المعلومات التي يتذكرها المساعد الذكي عنك'
      : (isFrench
            ? 'Consulter et gérer les éléments mémorisés par le compagnon IA'
            : 'Review and manage what the AI companion remembers');

  // Track & Self-Observation Hub
  String get trackHubTitle => isArabic
      ? 'مساحة الملاحظة والتتبّع'
      : (isFrench
            ? 'Espace d’auto-observation'
            : 'Self-Observation & Tracking');
  String get trackHubSubtitle => isArabic
      ? 'سجل حالتك الشعورية، النوم، الطاقة، وأفكارك بكل سهولة'
      : (isFrench
            ? 'Observez vos émotions, sommeil, énergie et pensées sans friction'
            : 'Track mood, sleep, energy, thoughts, and symptoms with ease');
  String get quickCheckInTab =>
      isArabic ? 'تسجيل سريع' : (isFrench ? 'Bilan rapide' : 'Quick Check-in');
  String get fullObservationTab => isArabic
      ? 'ملاحظة مفصلة'
      : (isFrench ? 'Observation complète' : 'Detailed Trace');
  String get traceHistoryTab =>
      isArabic ? 'السجل الزمني' : (isFrench ? 'Historique' : 'Trace History');
  String get historyTab => traceHistoryTab;
  String get journalTab => traceHistoryTab;
  String get sleepTrackingLabel => isArabic
      ? 'ساعات النوم'
      : (isFrench ? 'Heures de sommeil' : 'Sleep Duration');
  String get energyTrackingLabel => isArabic
      ? 'مستوى الطاقة'
      : (isFrench ? 'Niveau d’énergie' : 'Energy Level');
  String get anxietyTrackingLabel => isArabic
      ? 'مستوى التوتر والقلق'
      : (isFrench ? 'Niveau d’anxiété / tension' : 'Stress & Anxiety');
  String get trackingTriggersLabel => isArabic
      ? 'المحفزات والظروف المحيطة'
      : (isFrench ? 'Facteurs déclencheurs' : 'Triggers & Context');
  String get medicationLabel =>
      isArabic ? 'الأدوية الموصوفة' : (isFrench ? 'Médication' : 'Medication');
  String get medicationTakenPrompt => isArabic
      ? 'هل تناولت علاجك اليوم؟'
      : (isFrench
            ? 'Traitements pris aujourd’hui ?'
            : 'Prescribed medication taken today?');

  // Baseline & Pattern Awareness
  String get personalBaselineTitle => isArabic
      ? 'إيقاعك المعتاد'
      : (isFrench
            ? 'Votre rythme habituel'
            : 'Your usual rhythm');
  String get patternAwarenessTitle => isArabic
      ? 'ملاحظات الأنماط والتغيرات'
      : (isFrench ? 'Observations des schémas' : 'Pattern Awareness');
  String get baselineNeedsMoreData => isArabic
      ? 'سجّل 3 أيام باش تكتشف إيقاعك المعتاد'
      : (isFrench
            ? '3 jours suffisent pour voir votre rythme'
            : 'Check in for 3 days to see your usual rhythm');
  String get weeklySummaryTitle => isArabic
      ? 'الملخص الأسبوعي للمختص'
      : (isFrench ? 'Synthèse hebdomadaire' : 'Weekly Summary for Therapist');
  String get exportSummaryButton => isArabic
      ? 'تصدير التقرير للمختص'
      : (isFrench ? 'Exporter la synthèse' : 'Export Therapist Report');
  String get recognizeChangePrompt => isArabic
      ? 'هل تلاحظ هذا التغير في روتينك أو حالتك الجسدية؟'
      : (isFrench
            ? 'Reconnaissez-vous ce changement dans votre quotidien ?'
            : 'Do you recognize this change in your routine or physical state?');
  String get reviewSupportPlan => isArabic
      ? 'مراجعة خطة الدعم الشخصية'
      : (isFrench
            ? 'Consulter le plan de soutien'
            : 'Review Personal Support Plan');

  // Daily Check-in & Notes (Step 6)
  String get dailyCheckInTitle => isArabic
      ? 'التقييم اليومي'
      : (isFrench ? 'Bilan quotidien' : 'Daily Check-in');
  String get todaysNoteLabel => isArabic
      ? 'ملاحظة اليوم (اختياري)'
      : (isFrench ? 'Note du jour (facultatif)' : "Today's note (optional)");
  String get todaysNoteHint => isArabic
      ? 'شنوة صار اليوم؟ دوّن باختصار...'
      : (isFrench
            ? 'Que s’est-il passé aujourd’hui ?'
            : 'What happened today? Briefly note...');
  String get lastMoodLabel =>
      isArabic ? 'آخر حالة مسجلة' : (isFrench ? 'Dernier état' : 'Last Mood');
  String get saveCheckInButton => isArabic
      ? 'تسجيل التقييم اليومي'
      : (isFrench ? 'Enregistrer le bilan' : 'Log Daily Check-in');
  String get checkInSavedSnackbar => isArabic
      ? 'تم تسجيل التقييم وملاحظة اليوم بنجاح'
      : (isFrench
            ? 'Bilan et note enregistrés'
            : 'Daily check-in and note saved');
  String get toolkitPlaceholderV1 => isArabic
      ? 'صندوق الأدوات (نموذج v1)'
      : (isFrench ? 'Boîte à outils (v1 Réservé)' : 'Toolkit (v1 Placeholder)');
  String get toolkitV2Notice => isArabic
      ? 'تمارين الاسترخاء واليقظة الذهنية، وسجل النوم، ومخطط الأنشطة ستتوفر بالكامل في الإصدار الثاني v2.'
      : (isFrench
            ? 'Exercices de relaxation, journal de sommeil et planification comportementale arriveront en v2.'
            : 'Short mindfulness exercises, sleep hygiene diary, and behavioral activity planner arrive in v2.');

  // Greetings & Home
  String get greetingMorning =>
      isArabic ? 'صباح الخير' : (isFrench ? 'Bonjour' : 'Good morning');
  String get greetingAfternoon => isArabic
      ? 'مساء الخير'
      : (isFrench ? 'Bon après-midi' : 'Good afternoon');
  String get greetingEvening =>
      isArabic ? 'مساء النور' : (isFrench ? 'Bonsoir' : 'Good evening');
  String dearUserGreeting(String name) =>
      isArabic ? 'عزيزي $name،' : (isFrench ? 'Cher(e) $name,' : 'Dear $name,');
  String get timeSwitcherMonth =>
      isArabic ? 'شهر' : (isFrench ? 'Mois' : 'Month');
  String get timeSwitcherWeek =>
      isArabic ? 'أسبوع' : (isFrench ? 'Semaine' : 'Week');
  String get timeSwitcherDay => isArabic ? 'يوم' : (isFrench ? 'Jour' : 'Day');
  String get exercisesForYou => isArabic
      ? 'تمارين مقترحة لك'
      : (isFrench ? 'Exercices pour vous' : 'Exercises for you');
  String get relieveStress => isArabic
      ? 'تخفيف التوتر'
      : (isFrench ? 'Soulager le stress' : 'Relieve stress');
  String get breathingPractice => isArabic
      ? 'تمرين التنفس المبهمي'
      : (isFrench ? 'Pratique respiratoire' : 'Breathing practice');
  String get duration5Min =>
      isArabic ? '5 دقائق' : (isFrench ? '5 min' : '5 min');
  String get lastWeekLabel =>
      isArabic ? 'الأسبوع الماضي' : (isFrench ? 'Semaine passée' : 'Last week');
  String get moodStable =>
      isArabic ? 'مزاج مستقر' : (isFrench ? 'Humeur stable' : 'Mood stable');
  String get moodUnstable => isArabic
      ? 'تذبذب مزاجي'
      : (isFrench ? 'Humeur fluctuante' : 'Mood unstable');
  String get avgStressLevel => isArabic
      ? 'متوسط مستوى التوتر'
      : (isFrench ? 'Niveau de stress moyen' : 'Average stress level');
  String get inAWeek =>
      isArabic ? 'خلال أسبوع' : (isFrench ? 'en une semaine' : 'in a week');
  String get calibratingBaseline => isArabic
      ? 'نتعرّفوا على إيقاعك'
      : (isFrench
            ? 'Découverte de votre rythme'
            : 'Learning your rhythm');
  String get needsTwoEntries => isArabic
      ? 'يتطلب تسجيلين على الأقل'
      : (isFrench ? 'Nécessite 2 entrées' : 'Needs 2+ entries');
  String get noEntriesThisWeek => isArabic
      ? 'لا توجد تسجيلات'
      : (isFrench ? 'Aucune entrée' : 'No entries yet');
  String get updateCheckInButton => isArabic
      ? 'تحديث تقييم اليوم'
      : (isFrench ? 'Mettre à jour' : 'Update Check-in');
  String get todayCheckInRecorded => isArabic
      ? 'تم توثيق تقييم اليوم'
      : (isFrench
            ? 'Entrée du jour enregistrée'
            : 'Today\'s check-in recorded');
  String get loggedTodayEyebrow => isArabic
      ? 'مسجّل اليوم'
      : (isFrench ? 'NOTÉ AUJOURD’HUI' : 'LOGGED TODAY');
  String get aGentleNextStepHeader => isArabic
      ? 'خطوة هادية جاية'
      : (isFrench ? 'UN PETIT PAS SUIVANT' : 'A GENTLE NEXT STEP');
  String get actionBreatheLabel =>
      isArabic ? 'تنفّس' : (isFrench ? 'Respirer' : 'Breathe');
  String get actionTalkAboutItLabel =>
      isArabic ? 'احكي فيه' : (isFrench ? 'En parler' : 'Talk about it');
  String get thisWeekTitle =>
      isArabic ? 'الجمعة هاذي' : (isFrench ? 'Cette semaine' : 'This week');
  String observedDaysCount(int count) => isArabic
      ? '$count/7 أيام'
      : (isFrench ? '$count/7 observés' : '$count/7 observed');
  String get thisWeekSupportiveCaption => isArabic
      ? 'كلّ تسجيل هو نهار وقفت فيه مع روحك.'
      : (isFrench
            ? 'Chaque suivi est un jour où vous avez pris soin de vous.'
            : 'Every check-in is a day you showed up for yourself.');
  String talkAboutMoodPrompt(String moodLabel, int intensity, String? note) {
    final trimmed = note?.trim() ?? '';
    if (isArabic) {
      return trimmed.isNotEmpty
          ? 'سجّلت اليوم شعور "$moodLabel" بشدة $intensity/10: $trimmed'
          : 'سجّلت اليوم شعور "$moodLabel" بشدة $intensity/10 ونحب نفهمو شوية معاك.';
    }
    if (isFrench) {
      return trimmed.isNotEmpty
          ? 'Je viens de noter "$moodLabel" ($intensity/10) : $trimmed'
          : 'Je me sens "$moodLabel" ($intensity/10) aujourd’hui et j’aimerais explorer ce qui se passe.';
    }
    return trimmed.isNotEmpty
        ? 'Today I logged "$moodLabel" ($intensity/10): $trimmed'
        : 'Right now I feel "$moodLabel" ($intensity/10) and would like to talk through what is coming up.';
  }

  String get homeQuestion => isArabic
      ? 'كيفاش تحسّ روحك في اللحظة هاذي؟'
      : (isFrench
            ? 'Comment va votre esprit en ce moment ?'
            : 'How is your mind right now?');

  // Dashboard Sections
  String get activeCaseSection => isArabic
      ? 'الجلسة النشطة'
      : (isFrench ? 'SESSION EN COURS' : 'ACTIVE SESSION');
  String get mindsetPulseSection => isArabic
      ? 'مؤشر الاستثارة العصبية'
      : (isFrench ? 'ÉTAT DU SYSTÈME NERVEUX' : 'NEURAL AROUSAL PULSE');
  String get recentCasesSection => isArabic
      ? 'سجل الجلسات المعرفية'
      : (isFrench ? 'SESSIONS RÉCENTES' : 'RECENT SESSIONS');
  String get viewAll =>
      isArabic ? 'عرض الأرشيف' : (isFrench ? 'Voir tout' : 'View All');
  String get startInvestigation => isArabic
      ? 'بدء استكشاف فكري'
      : (isFrench ? 'Explorer une Pensée' : 'Explore a Thought');
  String get startInvestigationSub => isArabic
      ? 'استكشاف هادئ للأفكار التلقائية والتشنج الجسدي في دقائق معدودة'
      : (isFrench
            ? 'Prenez du recul sur vos pensées automatiques et sensations corporelles'
            : 'Gently examine automatic thoughts and physical tension in a few calm minutes');
  String get resumeInvestigation => isArabic
      ? 'مواصلة الجلسة'
      : (isFrench ? 'Reprendre la session' : 'Resume Session');
  String get noCasesOnFile => isArabic
      ? 'مازال ما فماش جلسات — اختار موضوع والا ابدأ جلسة جديدة الفوق.'
      : (isFrench
            ? 'Aucune session pour le moment — commencez une réflexion ci-dessus.'
            : 'No sessions yet — pick a topic or start a reflection above.');
  String stageNumberLabel(int step) => isArabic
      ? 'الخطوة $step من 6'
      : (isFrench ? 'Étape $step/6' : 'Step $step/6');
  String get inProgressLabel =>
      isArabic ? 'قيد المتابعة' : (isFrench ? 'En cours' : 'In progress');
  String get quickTriageLabel => isArabic
      ? 'فرز سريع 60 ثانية'
      : (isFrench ? 'Tri rapide 60 s' : '60s quick check');
  String get groundedAnchorTag => isArabic
      ? 'خطوة التثبيت'
      : (isFrench ? 'Point d’ancrage' : 'Grounded view');

  // Moods & States (Plain 1-Word Human Affect Labeling — Zero Clinical Jargon)
  String get moodCalm => isArabic ? 'هادئ' : (isFrench ? 'Calme' : 'Calm');
  String get moodAnxious =>
      isArabic ? 'قلق' : (isFrench ? 'Anxieux' : 'Anxious');
  String get moodFrustrated =>
      isArabic ? 'متضايق' : (isFrench ? 'Frustré' : 'Frustrated');
  String get moodHeavy => isArabic ? 'ثقيل' : (isFrench ? 'Lourd' : 'Heavy');
  String get moodRestless =>
      isArabic ? 'متشتّت' : (isFrench ? 'Agité' : 'Restless');
  String get moodIntensityLabel =>
      isArabic ? 'شدة الشعور' : (isFrench ? 'Intensité' : 'Intensity');

  String intensityLevelWord(int level) {
    if (level <= 2) {
      return isArabic ? 'خفيف' : (isFrench ? 'Douce' : 'Light');
    }
    if (level <= 4) {
      return isArabic ? 'بسيط' : (isFrench ? 'Légère' : 'Mild');
    }
    if (level <= 6) {
      return isArabic ? 'متوسّط' : (isFrench ? 'Modérée' : 'Moderate');
    }
    if (level <= 8) {
      return isArabic ? 'قوي' : (isFrench ? 'Forte' : 'Strong');
    }
    return isArabic ? 'قوي برشا' : (isFrench ? 'Intense' : 'Overwhelming');
  }

  String get intensityDecreaseLabel => isArabic
      ? 'نقص الشدة'
      : (isFrench ? 'Diminuer l’intensité' : 'Decrease intensity');

  String get intensityIncreaseLabel => isArabic
      ? 'زيد الشدة'
      : (isFrench ? 'Augmenter l’intensité' : 'Increase intensity');

  // Daily Cognitive Insight
  String get dailyInsightTitle => isArabic
      ? 'ملاحظة علم الأعصاب الإدراكي'
      : (isFrench ? 'Éclairage Neuro-Cognitif' : 'Neuro-Cognitive Insight');
  String get dailyInsightBody => isArabic
      ? 'بدنك يتوتر قبل ما مخك يسرّح. كي تسمّي إحساسك ترجعلك الراحة.'
      : (isFrench
            ? 'Le corps se tend souvent avant les pensées. Nommer l’émotion aide à ralentir.'
            : 'Your body often tenses before thoughts race. Naming the feeling helps you slow down.');

  // Clinical Epistemic Labels
  String get labelFact => isArabic
      ? 'حقيقة مثبتة'
      : (isFrench ? 'Fait Objectif' : 'Objective Fact');
  String get labelAssumption => isArabic
      ? 'فرضية غير مؤكدة'
      : (isFrench ? 'Hypothèse' : 'Unverified Assumption');
  String get labelInterpretation => isArabic
      ? 'تأويل ذاتي'
      : (isFrench ? 'Interprétation' : 'Subjective Interpretation');

  String localizedLabelName(LabelType label) {
    switch (label) {
      case LabelType.fact:
        return labelFact;
      case LabelType.assumption:
        return labelAssumption;
      case LabelType.interpretation:
        return labelInterpretation;
    }
  }

  // Interactive Catalysts (1-Tap Concise Triggers — Zero Clipping)
  String get catalystUnanswered => isArabic
      ? 'رسالة بلا رد'
      : (isFrench ? 'Message sans réponse' : 'Unanswered text');
  String get catalystCritique => isArabic
      ? 'ملاحظة في العمل'
      : (isFrench ? 'Remarque au travail' : 'Work feedback');
  String get catalystComparison => isArabic
      ? 'مقارنة اجتماعية'
      : (isFrench ? 'Comparaison sociale' : 'Social Comparison');
  String get catalystImposter => isArabic
      ? 'شك في الكفاءة'
      : (isFrench ? 'Doute de soi' : 'Imposter Doubt');
  String get catalystConflict => isArabic
      ? 'توتر في العلاقة'
      : (isFrench ? 'Tension relationnelle' : 'Interpersonal Friction');
  String get catalystExclusion => isArabic
      ? 'إحساس بالإقصاء'
      : (isFrench ? 'Sentiment d’exclusion' : 'Excluded / Left Out');
  String get catalystOverload => isArabic
      ? 'ضغط وتشتّت ذهني'
      : (isFrench ? 'Trop en tête' : 'Mental overload');
  String get catalystUncertainty => isArabic
      ? 'مستقبل غامض'
      : (isFrench ? 'Incertitude future' : 'Ambiguous Future');

  // Somatic Sensations (Body State Radar)
  String get somaticChest => isArabic
      ? 'ضيق بالصدر'
      : (isFrench ? 'Oppression thoracique' : 'Chest Constriction');
  String get somaticThroat => isArabic
      ? 'غصة بالحلق'
      : (isFrench ? 'Nœud à la gorge' : 'Throat Tightness');
  String get somaticStomach => isArabic
      ? 'تشنج بالمعدة'
      : (isFrench ? 'Nœud à l’estomac' : 'Gastric Knot');
  String get somaticHeart => isArabic
      ? 'تسارع نبضات القلب'
      : (isFrench ? 'Palpitations' : 'Racing Heartbeat');
  String get somaticJaw => isArabic
      ? 'ضغط الفك والرقبة'
      : (isFrench ? 'Mâchoire crispée' : 'Clenched Jaw / Neck');
  String get somaticHeavy => isArabic
      ? 'ثقل وإرهاق عام'
      : (isFrench ? 'Lourdeur léthargique' : 'Heavy Fatigue');

  // Cognitive Distortions
  String get distortionMindReading => isArabic
      ? 'قراءة الأفكار (Mind Reading)'
      : (isFrench ? 'Lecture de pensée' : 'Mind Reading');
  String get distortionCatastrophizing => isArabic
      ? 'التضخيم الكارثي (Catastrophizing)'
      : (isFrench ? 'Scénario catastrophe' : 'Catastrophizing');
  String get distortionAllOrNothing => isArabic
      ? 'الكل أو لا شيء (All-or-Nothing)'
      : (isFrench ? 'Pensée dichotomique' : 'All-or-Nothing');
  String get distortionPersonalization => isArabic
      ? 'الشخصنة (Personalization)'
      : (isFrench ? 'Personnalisation excessive' : 'Personalization');

  // Fast Socratic Micro-Toggles
  String get socraticCameraCheck => isArabic
      ? '1. إمكانية الإثبات المادي:'
      : (isFrench
            ? '1. Vérifiabilité empirique :'
            : '1. Empirical Verifiability:');
  String get socraticCameraTrue => isArabic
      ? 'ملموس بالكاميرا'
      : (isFrench ? 'Observable / Prouvé' : 'Verifiable Reality');
  String get socraticCameraFalse => isArabic
      ? 'سيناريو ذهني داخلي'
      : (isFrench ? 'Projection interne' : 'Internal Narrative');
  String get socraticTimeHorizon => isArabic
      ? '2. الأثر الزمني بعد 6 أشهر:'
      : (isFrench ? '2. Impact à 6 mois :' : '2. 6-Month Time Horizon:');
  String get socraticTimeLow => isArabic
      ? 'دون أي أثر حقيقي'
      : (isFrench ? 'Bruit éphémère (nul)' : 'Zero Long-Term Impact');
  String get socraticTimeHigh => isArabic
      ? 'أثر دائم وملموس'
      : (isFrench ? 'Impact durable' : 'Permanent Impact');
  String get socraticProbability => isArabic
      ? '3. الاحتمال الإحصائي للسيناريو الأسوأ:'
      : (isFrench
            ? '3. Probabilité réelle du pire :'
            : '3. Catastrophe Probability:');
  String get socraticProbLow => isArabic
      ? 'احتمال ضئيل (<15%)'
      : (isFrench ? 'Très faible (<15%)' : 'Highly Unlikely (<15%)');
  String get socraticProbHigh => isArabic
      ? 'شبه مؤكد (>80%)'
      : (isFrench ? 'Quasi certain (>80%)' : 'High Likelihood (>80%)');

  // 1-Tap Adaptive Reframes
  String get adoptReframeBtn => isArabic
      ? 'اعتماد هذا التوجيه الذهني'
      : (isFrench ? 'Adopter ce recadrage' : 'ADOPT THIS REFRAME');
  String get reframeAdoptedSnackbar => isArabic
      ? 'تم تثبيت إعادة التوجيه المعرفي بنجاح.'
      : (isFrench
            ? 'Recadrage adaptatif ancré avec succès.'
            : 'Adaptive reframe successfully anchored.');
  String get reframe1Title => isArabic
      ? 'تفكيك الشخصنة (De-personalization)'
      : (isFrench ? 'Désattribution personnelle' : 'De-Personalization Anchor');
  String get reframe1Body => isArabic
      ? 'سلوك الطرف الآخر يعكس ظروفه، ضغطه، أو طاقته اللحظية، ولا يحدد قيمتي أو كفاءتي.'
      : (isFrench
            ? 'Le comportement d’autrui reflète ses propres contraintes et sa charge mentale, non ma valeur intrinsèque.'
            : 'Their reaction reflects their internal bandwidth and circumstances, not my intrinsic worth or competence.');
  String get reframe2Title => isArabic
      ? 'تعليق الحكم حتى ثبوت الدليل (Cognitive Pause)'
      : (isFrench ? 'Suspension du jugement' : 'Empirical Data Hold');
  String get reframe2Body => isArabic
      ? 'أنا أتفاعل مع فراغ في البيانات. سأتوقف عن نسج السيناريوهات حتى تتوفر حقائق واضحة.'
      : (isFrench
            ? 'Je réagis à un vide informationnel. Je suspends toute alarme tant que les données réelles manquent.'
            : 'I am reacting to a data void. I choose to withhold panic until verifiable facts emerge.');
  String get reframe3Title => isArabic
      ? 'بدني في أمان توا'
      : (isFrench
            ? 'Mon corps est en sécurité ici'
            : 'My body is safe right now');
  String get reframe3Body => isArabic
      ? 'هذا إنذار توتر موش خطر حقيقي. أنا في أمان هوني.'
      : (isFrench
            ? 'C’est une alarme de stress, pas un vrai danger. Je suis en sécurité.'
            : 'This is a stress alarm, not real danger. I am safe right here.');

  // Tools
  String get toolsTitle => isArabic
      ? 'مخبر التنظيم العصبي'
      : (isFrench ? 'Lab de Régulation Neuro' : 'Neuro Regulation Lab');
  String get labelMasterTitle => isArabic
      ? 'تمرين الفرز المعرفي'
      : (isFrench ? 'Triage Cognitif Rapide' : 'Cognitive Triage Drill');
  String get labelMasterDesc => isArabic
      ? 'تدريب سريع لفصل الإشارات الواقعية عن التشويش الذهني'
      : (isFrench
            ? 'Entraînement réflexe pour séparer faits et biais'
            : 'Rapid reflex drill to separate empirical facts from cognitive noise');
  String get breathingTitle => isArabic
      ? 'تنفّس هادي (4-4-4-4)'
      : (isFrench
            ? 'Respiration calme (4-4-4-4)'
            : 'Slow breathing (4-4-4-4)');
  String get breathingDesc => isArabic
      ? 'تثبيط فوري لنشاط الجهاز العصبي الودي في 3 دقائق'
      : (isFrench
            ? 'Désactivation immédiate de l’hyperarousal sympathique'
            : 'Immediate downregulation of sympathetic hyperarousal');
  String get breatheIn => isArabic
      ? 'شهيق عميق...'
      : (isFrench ? 'Inspiration...' : 'Inhale deeply...');
  String get breatheHold =>
      isArabic ? 'حبس النفس...' : (isFrench ? 'Rétention...' : 'Hold...');
  String get breatheOut => isArabic
      ? 'زفير بطيء...'
      : (isFrench ? 'Expiration...' : 'Exhale slowly...');
  String get breatheRest =>
      isArabic ? 'استقرار...' : (isFrench ? 'Pause...' : 'Rest...');
  String get tunisianHotlinesTitle => isArabic
      ? 'خطوط الدعم النفسي والطوارئ في تونس'
      : (isFrench
            ? 'Lignes de Crise & Urgences (Tunisie)'
            : 'Clinical Crisis & Emergency Hub');
  String get tunisianHotlinesDesc => isArabic
      ? 'دعم طبي ونفسي مجاني وسري 24/7'
      : (isFrench
            ? 'Assistance médicale et psychiatrique confidentielle'
            : 'Free confidential psychiatric & emergency support');
  String drillCounter(int current, int total) => isArabic
      ? 'تمرين $current/$total'
      : (isFrench ? 'EXERCICE $current/$total' : 'DRILL $current/$total');
  String get nextDrill =>
      isArabic ? 'التمرين الموالي' : (isFrench ? 'SUIVANT' : 'NEXT DRILL');
  String get startPacer => isArabic
      ? 'تفعيل إيقاع التنظيم (4-4-4-4)'
      : (isFrench ? 'ACTIVER LE RYTHMEUR' : 'ACTIVATE PACER (4-4-4-4)');
  String get stopPacer => isArabic
      ? 'إيقاف الإيقاع'
      : (isFrench ? 'ARRÊTER LE RYTHMEUR' : 'STOP PACER');
  String get pacerSub => isArabic
      ? '4 ثواني شهيق • 4 حبس • 4 زفير • 4 استقرار'
      : (isFrench
            ? '4s Inspiration • 4s Rétention • 4s Expiration • 4s Pause'
            : '4s Inhale • 4s Hold • 4s Exhale • 4s Rest');

  // Settings
  String get settingsTitle => isArabic
      ? 'الإعدادات'
      : (isFrench ? 'Paramètres' : 'Settings');
  String get themeModeTitle => isArabic
      ? 'المظهر والألوان'
      : (isFrench ? 'Thème' : 'Theme');
  String get themeDaylight =>
      isArabic ? 'نهاري' : (isFrench ? 'Clair' : 'Daylight');
  String get themeNight =>
      isArabic ? 'داكن' : (isFrench ? 'Sombre' : 'Dark');
  String get themeSystem =>
      isArabic ? 'النظام' : (isFrench ? 'Système' : 'System');
  String get languageTitle => isArabic
      ? 'اللغة'
      : (isFrench ? 'Langue' : 'Language');
  String get aiHistoryTitle => isArabic
      ? 'سياق الأنماط المعرفية التراكمية'
      : (isFrench
            ? 'Mémoire des schémas cognitifs'
            : 'Cognitive Pattern Memory');
  String get aiHistoryDesc => isArabic
      ? 'تضمين الجلسات السابقة لرصد الأنماط المتكررة بدقة'
      : (isFrench
            ? 'Croiser les sessions pour détecter les schémas récurrents'
            : 'Cross-reference sessions to identify recurring cognitive schemas');
  String get biometricLockTitle => isArabic
      ? 'قفل الأمان بالبصمة'
      : (isFrench ? 'Verrouillage biométrique' : 'Biometric lock');
  String get biometricLockDesc => isArabic
      ? 'التثبّت بالبصمة أو رمز الهاتف لحماية خصوصيتك'
      : (isFrench
            ? 'Empreinte ou code requis pour protéger vos notes'
            : 'Require fingerprint or passcode to protect your private space');
  String get biometricVaultLockedTitle => isArabic
      ? 'الجلسة مقفلة'
      : (isFrench ? 'Espace verrouillé' : 'Session locked');
  String get biometricVaultLockedDesc => isArabic
      ? 'تثبّت بالبصمة أو رمز التليفون باش تكمل لخصوصياتك.'
      : (isFrench
            ? 'Confirmez avec votre empreinte ou code pour retrouver vos notes.'
            : 'Verify with biometrics or device passcode to keep your notes private.');
  String get unlockWithBiometricsBtn =>
      isArabic ? 'فتح القفل' : (isFrench ? 'Déverrouiller' : 'Unlock');
  String get biometricFailedSnackbar => isArabic
      ? 'فشلت المصادقة البيومترية'
      : (isFrench
            ? 'Échec de l’authentification'
            : 'Biometric authentication failed');
  String get biometricNotAvailableSnackbar => isArabic
      ? 'البصمة غير متوفرة في هذا الجهاز'
      : (isFrench
            ? 'Biométrie non disponible'
            : 'Biometrics not available on this device');
  // Cloud Sync (Firebase Spark Plan - Step 11)
  String get cloudSyncTitle => isArabic
      ? 'النسخ الاحتياطي والمزامنة'
      : (isFrench
            ? 'Sauvegarde & Synchronisation'
            : 'Backup & Synchronization');
  String get cloudSyncDesc => isArabic
      ? 'نسخ احتياطي محلي سيادي متوافق مع قيود الخصوصية والتكلفة (\$0.00)'
      : (isFrench
            ? 'Sauvegarde locale souveraine sans facturation (\$0.00)'
            : 'Local sovereign backup on device with zero billing linked (\$0.00)');
  String get exportVaultBtn => isArabic
      ? 'تصدير نسخة احتياطية (JSON)'
      : (isFrench
            ? 'Exporter la sauvegarde (JSON)'
            : 'Export Full Backup (JSON)');
  String get exportVaultSuccess => isArabic
      ? 'تم نسخ النسخة الاحتياطية إلى الحافظة'
      : (isFrench
            ? 'Sauvegarde complète copiée'
            : 'Full backup copied to clipboard');
  String get sparkPlanBadge => isArabic
      ? 'خطة SPARK المجانية (\$0.00)'
      : (isFrench ? 'FORFAIT SPARK (\$0.00)' : 'SPARK FREE TIER (\$0.00)');

  String get wipeDataTitle => isArabic
      ? 'مسح السجلات نهائياً'
      : (isFrench ? 'Purger toutes les données' : 'Purge All Records');
  String get wipeDataDesc => isArabic
      ? 'حذف كافة الجلسات والتحليلات المعرفية المحفوظة على هذا الجهاز'
      : (isFrench
            ? 'Suppression irréversible de l’historique des sessions'
            : 'Irreversibly delete all cognitive history from this device');
  String get dataTransparencyTitle => isArabic
      ? 'حماية خصوصيتك'
      : (isFrench
            ? 'Votre confidentialité'
            : 'Your privacy promise');
  String get privacyPrinciplesTitle => isArabic
      ? 'المعايير السريرية للخصوصية'
      : (isFrench
            ? 'Normes de Confidentialité Médicale'
            : 'Clinical Privacy Standards');
  String get privacyPrinciplesBody => isArabic
      ? '• محفوظ في تليفونك بخصوصية.\n• ما يتباعش وما يتشاركش.\n• الحوارات الخاصة تبقى عندك وحدك.'
      : (isFrench
            ? '• Gardé en privé sur ce téléphone.\n• Jamais vendu ni partagé.\n• Vos échanges privés restent à vous.'
            : '• Saved privately on your phone.\n• Never sold or shared.\n• Private talks never go to doctors.');
  String get allDataWipedSnackbar => isArabic
      ? 'تم مسح كافة السجلات المعرفية بنجاح.'
      : (isFrench
            ? 'Toutes les données ont été purgées avec succès.'
            : 'All clinical session records permanently cleared.');

  // Deconstruction Workflow (Clinical Stages)
  String get stageIncident => isArabic
      ? 'شنوة اللي صار'
      : (isFrench
            ? 'Ce qui s’est passé'
            : 'What happened');
  String get stageEvidence => isArabic
      ? 'الإحساس وأول فكرة'
      : (isFrench
            ? 'Ressenti et pensée'
            : 'Feeling & first thought');
  String get stageHypotheses => isArabic
      ? 'النماذج التفسيرية'
      : (isFrench ? 'Modèles Alternatifs' : 'Cognitive Models');
  String get stageCrossExam => isArabic
      ? 'اختبار الواقع السقراطي'
      : (isFrench ? 'Test de Réalité' : 'Socratic Reality Test');
  String get stageFindings => isArabic
      ? 'ملخص الأنماط'
      : (isFrench ? 'Synthèse des Schémas' : 'Pattern Reflection');
  String get stageVerdict => isArabic
      ? 'إعادة التوجيه المتزنة'
      : (isFrench ? 'Recadrage Adaptatif' : 'Adaptive Reframe');

  String stepBadgeText(int step, String stageTitle) => isArabic
      ? 'الخطوة $step من 6 · $stageTitle'
      : (isFrench
            ? 'Étape $step sur 6 · $stageTitle'
            : 'Step $step of 6 · $stageTitle');

  String get whatHappenedQuestion => isArabic
      ? 'شنوة المحفز اللي أثار التوتر؟'
      : (isFrench
            ? 'Quel est le stimulus déclencheur ?'
            : 'What is the activating stimulus?');
  String get incidentHelpText => isArabic
      ? 'اختار شنوة اللي قلّقك، ولا زيد كلمتين:'
      : (isFrench
            ? 'Choisissez ce qui a déclenché cela :'
            : 'Pick what set this off, or add a short note:');
  String get incidentHint => isArabic
      ? 'أو اكتب باختصار: مثلاً شفت الإيميل وحسيت بضغط مفاجئ...'
      : (isFrench
            ? 'Ou notez brièvement le contexte...'
            : 'Or enter optional custom trigger context...');
  String get describeSituationWarning => isArabic
      ? 'اختار موضوع من الفوق باش تكمّل.'
      : (isFrench
            ? 'Choisissez un sujet pour continuer.'
            : 'Pick a topic above to continue.');
  String get proceedToEvidenceBtn => isArabic
      ? 'التالي: كيفاش حسّيت'
      : (isFrench
            ? 'Suivant : Votre ressenti'
            : 'Next: How it felt');

  String get mapChainTitle => isArabic
      ? 'كيفاش حسّيتها في اللحظة هاذيكة؟'
      : (isFrench
            ? 'Comment l’avez-vous vécu ?'
            : 'How did it feel in the moment?');
  String get mapChainSub => isArabic
      ? 'حدد أين استقر التوتر في جسدك وصنف الفكرة التلقائية السريعة:'
      : (isFrench
            ? 'Localisez la tension corporelle et qualifiez la pensée automatique :'
            : 'Locate where the body feels it and classify the automatic thought:');
  String get triggerLabel => isArabic
      ? 'السبب اللّي حرّك الموقف'
      : (isFrench
            ? 'Ce qui l’a déclenché'
            : 'What set it off');
  String get emotionLabel => isArabic
      ? 'الشعور الأساسي'
      : (isFrench
            ? 'Émotion principale'
            : 'Main feeling');
  String get emotionalIntensityTitle => isArabic
      ? 'قدّاش قوّتو؟'
      : (isFrench
            ? 'Quelle intensité ?'
            : 'How strong is it?');
  String get behaviorLabel => isArabic
      ? 'دافع السلوك اللحظي (هروب، تجنب، هجوم)'
      : (isFrench
            ? 'Impulsion d’action (fuite, évitement, repli)'
            : 'Action Impulse (withdraw, avoid, confront)');
  String get classifyThoughtLabel => isArabic
      ? 'تصنيف الفكرة التلقائية'
      : (isFrench
            ? 'CLASSIFICATION ÉPISTÉMIQUE'
            : 'CLASSIFY THE AUTOMATIC THOUGHT');
  String get examinePerspectivesBtn => isArabic
      ? 'توليد النماذج التفسيرية البديلة'
      : (isFrench
            ? 'Générer les modèles alternatifs'
            : 'GENERATE ALTERNATIVE MODELS');

  String get warmInvestigatorTitle => isArabic
      ? 'النماذج الإدراكية البديلة'
      : (isFrench
            ? 'Modèles Cognitifs Alternatifs'
            : 'Alternative Neuro-Cognitive Models');
  String get hypothesesSub => isArabic
      ? 'مسارات عصبية بديلة لتفكيك النظرة الضيقة وتخفيف نشاط مركز الخوف بالمخ.'
      : (isFrench
            ? 'Perspectives cliniques alternatives pour désamorcer l’hypervigilance de l’amygdale.'
            : 'Alternative prefrontal cognitive pathways to disarm limbic hypervigilance.');
  String get queryInvestigatorBtn => isArabic
      ? 'توليد مسارات تفسيرية إضافية'
      : (isFrench
            ? 'Générer d’autres hypothèses'
            : 'Generate Additional Models');
  String get whyItFitsPrefix => isArabic
      ? 'عوامل التوافق:'
      : (isFrench ? 'Facteurs concordants :' : 'Congruent evidence:');
  String get whatDoesNotFitPrefix => isArabic
      ? 'مؤشرات التناقض:'
      : (isFrench ? 'Facteurs divergents :' : 'Contradictory evidence:');
  String get testAssumptionsBtn => isArabic
      ? 'إجراء اختبار الواقع السقراطي'
      : (isFrench
            ? 'Tester la réalité socratique'
            : 'RUN SOCRATIC REALITY TEST');

  String get crossExamTitle => isArabic
      ? 'اختبار الواقع السقراطي السريع'
      : (isFrench ? 'Test de Réalité Socratique' : 'Socratic Reality Testing');
  String get crossExamSub => isArabic
      ? 'أجب بنقرة سريعة على الأسئلة الثلاثة لفصل الواقع الحسي عن تهويل المخ:'
      : (isFrench
            ? 'Répondez rapidement aux 3 curseurs pour isoler les faits des distorsions :'
            : 'Quickly toggle the 3 reality checks to separate empirical reality from mental projection:');
  String get crossExamQuestion1 => isArabic
      ? '“هل يمكن لكاميرا فيديو محايدة إثبات هذه الفكرة بنسبة 100%؟”'
      : (isFrench
            ? '« Une caméra externe neutre pourrait-elle prouver cette pensée à 100% ? »'
            : '“Could a neutral video camera prove this thought 100% true?”');
  String get crossExamQuestion2 => isArabic
      ? '“هل سيكون لهذا الموقف أي أثر فعلي على حياتك بعد 6 أشهر؟”'
      : (isFrench
            ? '« Cet événement aura-t-il un impact tangible dans 6 mois ? »'
            : '“Will this event hold any real impact 6 months from now?”');
  String get crossExamQuestion3 => isArabic
      ? '“ما هو الاحتمال الرياضي لحدوث السيناريو الكارثي الذي تخشاه؟”'
      : (isFrench
            ? '« Quelle est la probabilité statistique réelle du pire scénario ? »'
            : '“What is the statistical likelihood of your catastrophic fear?”');
  String get synthesizeFindingsBtn => isArabic
      ? 'استعراض أنماط التفكير'
      : (isFrench
            ? 'Explorer les schémas cognitifs'
            : 'SUMMARIZE THINKING PATTERNS');

  String get findingsTitle => isArabic
      ? 'أنماط التفكير والملاحظة'
      : (isFrench ? 'Schémas de Pensée' : 'Thinking Pattern Reflection');
  String get findingsSub => isArabic
      ? 'نفرّقوا بين الواقع الملموس وسيناريوهات القلق:'
      : (isFrench
            ? 'Séparer les faits réels des scénarios d’inquiétude :'
            : 'Separating hard facts from worry stories:');
  String get fallbackFindingsSummary => isArabic
      ? '• الواقع: ما فمّاش دليل على نية خايبة.\n• الفخ: مخك سبق الأحداث.\n• نظرة أهدى: خوذ نفس وخلّي الوقت يوضّح.'
      : (isFrench
            ? '• Fait : Aucun signe d’intention négative.\n• Piège : Anticiper le pire trop vite.\n• Recul : Laissez retomber la pression.'
            : '• Fact: No clear sign anyone meant harm.\n• Trap: Jumping ahead before knowing.\n• Kinder view: Give it breathing room.');
  String get recordVerdictBtn => isArabic
      ? 'الانتقال إلى إعادة التوجيه المتزنة'
      : (isFrench
            ? 'Passer au recadrage adaptatif'
            : 'CONTINUE TO ADAPTIVE REFRAME');

  String get verdictTitle => isArabic
      ? 'إعادة التوجيه المتزنة (Adaptive Reframe)'
      : (isFrench
            ? 'Recadrage Adaptatif & Ancrage'
            : 'Adaptive Reframe & Grounded Anchor');
  String get verdictSub => isArabic
      ? 'اختر الركيزة المعرفية الأنسب لك واعتمدها بنقرة واحدة لتهدئة الدائرة العصبية:'
      : (isFrench
            ? 'Sélectionnez le recadrage clinique le plus aidant et ancrez-le en 1 tap :'
            : 'Select the most empowering clinical reframe and anchor it in 1 tap:');
  String get conclusionHint => isArabic
      ? 'أو اكتب تعديلك الخاص باختصار شديد...'
      : (isFrench
            ? 'Ou notez votre propre recadrage...'
            : 'Or enter custom personal reframe...');
  String get fileAndArchiveBtn => isArabic
      ? 'تثبيت وحفظ الجلسة في الأرشيف'
      : (isFrench
            ? 'Ancrer & archiver la session'
            : 'ANCHOR & ARCHIVE SESSION');
  String get caseArchivedSuccess => isArabic
      ? 'تم تثبيت الجلسة المعرفية وحفظها بنجاح.'
      : (isFrench
            ? 'Session cognitive ancrée avec succès.'
            : 'Cognitive session successfully anchored.');
  String get writeConclusionWarning => isArabic
      ? 'الرجاء اختيار أو كتابة إعادة التوجيه قبل الحفظ.'
      : (isFrench
            ? 'Veuillez sélectionner un recadrage avant d’archiver.'
            : 'Please select or enter an adaptive reframe before filing.');
  String get previousStepBtn => isArabic
      ? 'الخطوة السابقة'
      : (isFrench ? 'Étape précédente' : 'Previous step');

  /// Formats an internal session identifier into sentence-case display format.
  String formatSessionNumber(String rawNumber) {
    final digitsMatch = RegExp(r'\d+').firstMatch(rawNumber);
    final num = digitsMatch != null
        ? int.tryParse(digitsMatch.group(0) ?? '')
        : null;
    final formatted = num != null ? num.toString().padLeft(2, '0') : '01';
    if (isArabic) {
      return 'جلسة $formatted';
    }
    return 'Session $formatted';
  }

  // Case Report View
  String get caseReportTitle => isArabic
      ? 'ملخص الحوار'
      : (isFrench
            ? 'Résumé d’échange'
            : 'Talk summary');
  String get caseNotFound => isArabic
      ? 'الجلسة غير موجودة.'
      : (isFrench ? 'Session introuvable.' : 'Session record not found.');
  String get editVerdictTitle => isArabic
      ? 'تعديل خلاصة التوازن'
      : (isFrench ? 'Modifier votre mise au point' : 'Edit takeaway');
  String get yourUpdatedTakeaway => isArabic
      ? 'صيغتك المعدلة...'
      : (isFrench ? 'Votre recadrage révisé...' : 'Your updated takeaway...');
  String get saveVerdictBtn =>
      isArabic ? 'حفظ التعديل' : (isFrench ? 'Enregistrer' : 'Save takeaway');
  String get deleteCaseFileTitle => isArabic
      ? 'حذف سجل الحوار'
      : (isFrench ? 'Supprimer cet échange' : 'Delete talk record');
  String get deleteCase => isArabic
      ? 'حذف الجلسة'
      : (isFrench ? 'Supprimer la session' : 'Delete session');
  String get deleteCaseWarning => isArabic
      ? 'تحب تفسخ الحوار هذا من تليفونك؟'
      : (isFrench
            ? 'Supprimer cet échange de ce téléphone ?'
            : 'Remove this talk from your phone?');
  String get deletePermanentlyBtn => isArabic
      ? 'حذف نهائي'
      : (isFrench ? 'Supprimer définitivement' : 'Delete permanently');
  String get cancelBtn =>
      isArabic ? 'إلغاء' : (isFrench ? 'Annuler' : 'Cancel');
  String get incidentNarrativeHeader => isArabic
      ? '1. شنوة اللي صار'
      : (isFrench
            ? '1. Ce qui s’est passé'
            : '1. What happened');
  String get noNarrativeRecorded => isArabic
      ? 'لم يتم تسجيل محفز.'
      : (isFrench ? 'Aucun déclencheur noté.' : 'No situation recorded.');
  String get observableChainHeader => isArabic
      ? '2. الإحساس وأول فكرة'
      : (isFrench
            ? '2. Ressenti et première pensée'
            : '2. How it felt & first thought');
  String get hypothesesExaminedHeader => isArabic
      ? '3. زوايا نظر بديلة'
      : (isFrench
            ? '3. Pistes envisagées'
            : '3. Other ways to see it');
  String get groundedVerdictHeader => isArabic
      ? '4. خطوة التثبيت المعتمدة'
      : (isFrench
            ? '4. Point d’appui retenu'
            : '4. Grounded takeaway');
  String get finalTakeawayUserHeader => isArabic
      ? 'الفكرة المريحة المعتمدة'
      : (isFrench ? 'Point d’appui retenu' : 'Chosen takeaway');
  String get editBtn => isArabic ? 'تعديل' : (isFrench ? 'Modifier' : 'Edit');
  String get noConclusionYet => isArabic
      ? 'لم يُعتمد توجيه بعد.'
      : (isFrench
            ? 'Aucun recadrage ancré pour le moment.'
            : 'No reframe anchored yet.');
  String emotionTag(String emotion, int intensity) => isArabic
      ? 'الشعور: $emotion ($intensity/10)'
      : (isFrench
            ? 'Ressenti : $emotion ($intensity/10)'
            : 'Feeling: $emotion ($intensity/10)');
  String get triggerTitle => isArabic
      ? 'شنوة اللي صار'
      : (isFrench
            ? 'Déclencheur'
            : 'What happened');
  String get thoughtTitle => isArabic
      ? 'الفكرة التلقائية'
      : (isFrench ? 'Pensée automatique' : 'Automatic Thought');
  String get behaviorTitle =>
      isArabic ? 'دافع السلوك' : (isFrench ? 'Impulsion' : 'Action Impulse');

  // Journal / Vault
  String get noCasesRecordedTitle => isArabic
      ? 'لا توجد جلسات مسجلة'
      : (isFrench ? 'AUCUNE SESSION ENREGISTRÉE' : 'NO SESSIONS RECORDED');
  String get noCasesRecordedDesc => isArabic
      ? 'عندما تشعر بأي استثارة أو فكرة مقلقة، ابدأ جلسة تفكير هادئة لإعادة التوازن.'
      : (isFrench
            ? 'Dès qu’une tension ou pensée automatique surgit, initiez une session de réflexion.'
            : 'Whenever tension or automatic anxiety arises, launch a gentle reflection session.');
  String get emotionHiddenPrivacy => isArabic
      ? 'الشعور مخفي (خاص)'
      : (isFrench
            ? 'Ressenti masqué (privé)'
            : 'Feeling hidden (private)');
  String feltEmotionSub(String emotion, int intensity) => isArabic
      ? 'الاستجابة: $emotion • الشدة: $intensity/10'
      : (isFrench
            ? 'État : $emotion • Intensité $intensity/10'
            : 'State: $emotion • Arousal $intensity/10');
  String get showPreviewsTooltip =>
      isArabic ? 'إظهار المعاينة' : (isFrench ? 'Afficher' : 'Show previews');
  String get hidePreviewsTooltip => isArabic
      ? 'إخفاء المعاينة (خصوصية)'
      : (isFrench ? 'Masquer (Confidentialité)' : 'Hide previews (Privacy)');

  // Safety & Crisis Dialog / Bottom Sheet
  String get needSupportBtn => isArabic
      ? 'دعم نفسي وطوارئ'
      : (isFrench ? 'Lignes d’urgence' : 'Crisis Support');
  String get supportTitle =>
      isArabic ? 'مساعدة' : (isFrench ? 'Aide' : 'Support');
  String get callBtn =>
      isArabic ? 'اتصال مباشر' : (isFrench ? 'Appeler' : 'CALL');
  String get supportModalTitle => isArabic
      ? 'Aide & Urgences • الدعم والمساعدة السريرية'
      : (isFrench
            ? 'Lignes Cliniques & Urgences'
            : 'Clinical Support & Emergency');
  String get supportModalSub => isArabic
      ? 'أرقام النجدة والمساندة النفسية الرسمية في تونس'
      : (isFrench
            ? 'Numéros d’urgence officiels en Tunisie'
            : 'Official emergency hotlines in Tunisia');
  String get supportModalBody => isArabic
      ? 'تتعدّى بلحظة صعيبة؟ فمّا شكون يسمعك ويعاونك مجاناً وبسرية.'
      : (isFrench
            ? 'Un moment difficile ? Des professionnels gratuits sont là pour vous écouter.'
            : 'Going through a hard moment? Free, caring people are ready to listen.');
  String get crisisPauseTitle => isArabic
      ? 'وقفة هادئة لتنظيم الجهاز العصبي'
      : (isFrench
            ? 'Pause de Régulation Immédiate'
            : 'Gentle Neuro-Regulation Pause');
  String get crisisPauseBody => isArabic
      ? 'مانكش وحدك. فمّا مساعدة مجانية وسرية حاضرة تسمعك توا.'
      : (isFrench
            ? 'Ne restez pas seul(e). Une écoute gratuite et confidentielle est disponible maintenant.'
            : 'You do not have to carry this alone. Free, private help is ready right now.');
  String get greenLineTitle => isArabic
      ? 'الرقم الأخضر للمساعدة النفسية (تونس)'
      : (isFrench
            ? 'Numéro Vert d’Aide Psychologique (Tunisie)'
            : 'National Mental Health Green Line (Tunisia)');
  String get greenLineSubtitle => isArabic
      ? '80 10 50 50 • مجاني 24/7'
      : (isFrench ? '80 10 50 50 • Gratuit 24/7' : '80 10 50 50 • Free 24/7');
  String get returnToCaseBtn => isArabic
      ? 'الرجوع للجلسة'
      : (isFrench ? 'Revenir à la session' : 'Return to Session');
  String get viewSupportResourcesBtn => isArabic
      ? 'أرقام النجدة والمساعدة'
      : (isFrench ? 'Voir les ressources d’urgence' : 'View Crisis Resources');

  // Onboarding (4-Step Fast Flow)
  String get onboardingSkip =>
      isArabic ? 'تخطي' : (isFrench ? 'Passer' : 'Skip');
  String get onboardingEnterLab => isArabic
      ? 'دخول المساحة'
      : (isFrench ? 'Entrer dans l’espace' : 'Enter Space');
  String get onboardingNext =>
      isArabic ? 'الموالي' : (isFrench ? 'Suivant' : 'Continue');
  String get onboardingGetStarted =>
      isArabic ? 'ابدأ الآن' : (isFrench ? 'Commencer' : 'Get Started');
  String get onboardingContinue =>
      isArabic ? 'متابعة' : (isFrench ? 'Continuer' : 'Continue');
  String onboardingStepOf(int step, int total) => isArabic
      ? 'الخطوة $step من $total'
      : (isFrench ? 'Étape $step sur $total' : 'Step $step of $total');

  // Step 1: Welcome & Privacy
  String get onboardingWelcomeHeadline => isArabic
      ? 'كل فكرة تترك أثراً.'
      : (isFrench
            ? 'Chaque pensée laisse une trace.'
            : 'Every thought leaves a trace.');
  String get onboardingWelcomeBody => isArabic
      ? 'سجّل إحساسك في لمستين واكتشف شنوة اللي يريّحك.'
      : (isFrench
            ? 'Notez votre humeur en deux gestes et voyez ce qui vous fait du bien.'
            : 'Check in with two taps and see what helps you feel good.');
  String get onboardingPrivacyPromise => isArabic
      ? 'محفوظ بخصوصية في تليفونك · خطوات مستوحاة من علم النفس لصفاء بالك.'
      : (isFrench
            ? 'Privé sur votre téléphone · Outils doux pour votre clarté au quotidien.'
            : 'Private on your phone · Calm psychology tools for daily clarity.');

  // Step 2: Focus (1–3 Options)
  String get onboardingFocusTitle => isArabic
      ? 'شنوّة أكثر حاجة تحب تركّز عليها؟'
      : (isFrench
            ? 'Sur quoi souhaitez-vous porter votre attention ?'
            : 'What would help most right now?');
  String get onboardingFocusSubtitle => isArabic
      ? 'اختار من خيار لـ 3 (اختياري). باش نرتبولك المساحة حسب حاجتك.'
      : (isFrench
            ? 'Choisissez 1 à 3 axes (facultatif) pour adapter vos repères dès l’accueil.'
            : 'Pick 1 to 3 focus areas (optional) so your home space starts tailored to you.');
  String get focusGoalStress => isArabic
      ? 'تهدئة التوتر والقلق'
      : (isFrench ? 'Apaiser le stress et l’anxiété' : 'Ease stress & anxiety');
  String get focusGoalMood => isArabic
      ? 'فهم تقلبات المزاج'
      : (isFrench
            ? 'Comprendre les variations d’humeur'
            : 'Understand mood patterns');
  String get focusGoalOverthinking => isArabic
      ? 'فك تشابك كثرة التفكير'
      : (isFrench ? 'Démêler la rumination mentale' : 'Untangle overthinking');
  String get focusGoalSleepEnergy => isArabic
      ? 'توازن النوم والطاقة'
      : (isFrench ? 'Équilibrer sommeil et énergie' : 'Sleep & energy rhythm');
  String get focusGoalSpecialist => isArabic
      ? 'تنظيم الملاحظات مع مختص'
      : (isFrench
            ? 'Préparer le suivi avec un spécialiste'
            : 'Reflect alongside a specialist');
  String get addCustomGoalToggle => isArabic
      ? 'أو أضف هدفاً خاصاً (اختياري)'
      : (isFrench
            ? 'Ou ajouter un objectif personnel (facultatif)'
            : 'Or add your own focus (optional)');
  String get customGoalHint => isArabic
      ? 'مثال: لاحظت إني نتقلق الصباح...'
      : (isFrench
            ? 'Ex : mieux repérer mes déclencheurs...'
            : 'e.g. notice morning tension...');

  // Step 3: Comfort & Safety Check
  String get onboardingComfortTitle => isArabic
      ? 'إطار الراحة والأمان'
      : (isFrench ? 'Confort & repères de sécurité' : 'Comfort & safety check');
  String get onboardingComfortSubtitle => isArabic
      ? 'اختياري بالكامل — يساعدنا على ضبط الإيقاع وتوفير خطوط الدعم بوضوح.'
      : (isFrench
            ? 'Entièrement facultatif — aide à ajuster le rythme et garder l’aide à portée.'
            : 'Completely optional — helps calibrate pacing and keep support resources clear.');
  String get supportOptionSpecialist => isArabic
      ? 'نتابع مع مختص حالياً'
      : (isFrench ? 'Suivi par un spécialiste' : 'Seeing a specialist');
  String get supportOptionSelfGuided => isArabic
      ? 'نستكشف وحدي'
      : (isFrench ? 'Exploration autonome' : 'Exploring on my own');
  String get supportOptionPreferNotToSay => isArabic
      ? 'أفضل عدم التحديد'
      : (isFrench ? 'Préfère ne pas préciser' : 'Prefer not to say');
  String get onboardingCrisisSafetyNote => isArabic
      ? 'تستحق مساعدة عاجلة؟ انزل على مساعدة في أي وقت (80 10 50 50، 190، 198).'
      : (isFrench
            ? 'Urgence ? Touchez Aide à tout moment (80 10 50 50, 190, 198).'
            : 'Need urgent help? Tap Help anytime for 80 10 50 50, 190, or 198.');
  String get openCrisisResourcesLabel => isArabic
      ? 'عرض أرقام الطوارئ'
      : (isFrench ? 'Voir les numéros d’aide' : 'View emergency numbers');

  // Step 4: First Check-In & Zero-Blank-Screen Handoff
  String get onboardingFirstCheckInSubtitle => isArabic
      ? 'اختار وجه وقدّاش قوّتو — في 5 ثواني برك.'
      : (isFrench
            ? 'Touchez un visage et son intensité — fini en 5 secondes.'
            : 'Tap a face and how strong it feels — done in 5 seconds.');
  String get saveAndEnterAppBtn => isArabic
      ? 'حفظ والدخول للتطبيق'
      : (isFrench ? 'Enregistrer & entrer' : 'Save & Enter App');
  String get skipAndEnterAppBtn => isArabic
      ? 'تخطي التسجيل والدخول'
      : (isFrench ? 'Passer et entrer' : 'Skip & Enter App');

  // Clinical Session Brief & Privacy Shield (Section 12 - Step 12)
  String get casePrivateBadge => isArabic
      ? 'سري: خاص — غير قابل للمشاركة'
      : (isFrench
            ? 'CONFIDENTIEL : PRIVÉ — NON PARTAGEABLE'
            : 'CONFIDENTIAL: PRIVATE — NEVER SHAREABLE');
  String get caseShareableBadge => isArabic
      ? 'قابل للتضمين في الملخص السريري'
      : (isFrench
            ? 'PARTAGEABLE DANS LE BILAN DE SESSION'
            : 'SHAREABLE IN SESSION BRIEF');
  String get togglePrivacyTooltip => isArabic
      ? 'تعديل درع السرية'
      : (isFrench ? 'Basculer la confidentialité' : 'Toggle Privacy Shield');
  String get privacyShieldTitle => isArabic
      ? 'درع السرية والخصوصية'
      : (isFrench
            ? 'Bouclier de Confidentialité'
            : 'Privacy & Confidentiality Shield');
  String get caseIsPrivateCannotExport => isArabic
      ? 'الحوار هذا خاص وما يتشاركش أبداً إلا كان تفتحو بنفسك.'
      : (isFrench
            ? 'Cet échange est privé et n’est jamais partagé sans votre accord.'
            : 'This talk is marked Private and is never shared unless you unlock it.');

  String get exportSessionBriefTitle => isArabic
      ? 'ملخص الجلسة السريري'
      : (isFrench ? 'Bilan de Session Clinique' : 'Clinical Session Brief');
  String get sessionBriefExportHeader => isArabic
      ? 'تصدير ملخص الجلسات للمعالج'
      : (isFrench
            ? 'Exporter le Bilan de Session'
            : 'Export Clinical Session Brief');
  String get sessionBriefSubtitle => isArabic
      ? 'ملخص معرفي منظم بمبادرة شخصية لمناقشته مع طبيبك أو أخصائيك النفسي'
      : (isFrench
            ? 'Synthèse cognitive structurée pour votre praticien'
            : 'Structured patient-initiated cognitive summary for clinician collaboration');
  String get exportSelectionMode => isArabic
      ? 'تحديد الجلسات'
      : (isFrench ? 'Sélectionner des sessions' : 'Select Sessions');
  String get selectSessionsToExport => isArabic
      ? 'اختر الجلسات لتضمينها في الملخص'
      : (isFrench
            ? 'Choisissez les sessions à inclure'
            : 'Select sessions to include in brief');
  String sessionsSelectedCount(int count) => isArabic
      ? (count == 1 ? 'جلسة واحدة مختارة' : '$count جلسات مختارة')
      : (isFrench
            ? '$count session(s) sélectionnée(s)'
            : '$count session(s) selected');
  String get previewBriefBtn => isArabic
      ? 'معاينة الملخص السريري'
      : (isFrench ? 'APERÇU DU BILAN' : 'PREVIEW CLINICAL BRIEF');
  String get copySessionBriefBtn => isArabic
      ? 'نسخ الملخص السريري للحافظة'
      : (isFrench ? 'COPIER LE BILAN' : 'COPY CLINICAL BRIEF');
  String get sessionBriefCopiedSuccess => isArabic
      ? 'تم نسخ الملخص السريري إلى الحافظة بنجاح'
      : (isFrench
            ? 'Bilan clinique copié dans le presse-papiers'
            : 'Clinical session brief copied to clipboard');
  String get recipientOrNoteLabel => isArabic
      ? 'اسم المعالج / ملاحظة الجلسة (اختياري)'
      : (isFrench
            ? 'Praticien / Note de séance (optionnel)'
            : 'Clinician / Session Note (optional)');
  String get recipientOrNoteHint => isArabic
      ? 'مثال: د. بن عمار - متابعة الجلسة'
      : (isFrench
            ? 'Ex: Dr. Ben Ammar - Suivi'
            : 'e.g., Dr. Ben Ammar - Session follow-up');
  String privateCasesExcludedNote(int count) => isArabic
      ? (count == 1
            ? 'تم استبعاد جلسة واحدة موسومة كخاصة وسرية'
            : 'تم استبعاد $count جلسات موسومة كخاصة وسرية')
      : (isFrench
            ? '$count session(s) confidentielle(s) exclue(s)'
            : '$count private shielded session(s) excluded');
  String get clinicalDisclaimerNotice => isArabic
      ? 'مستوحى من تمارين CBT — موش تشخيص طبي وموش علاج.'
      : (isFrench
            ? 'Inspiré des outils TCC — ni diagnostic médical ni thérapie.'
            : 'Inspired by CBT reflection — not a medical diagnosis or therapy.');

  // Clinical Sharing History (Principle 5)
  String get clinicalSharingHistoryTitle => isArabic
      ? 'سجل التصدير والمشاركات السريرية'
      : (isFrench
            ? 'Historique des Partages Cliniques'
            : 'Clinical Sharing History');
  String get clinicalSharingHistoryDesc => isArabic
      ? 'كل ملخص اخترت تشاركو بنفسك (ما يتبعث شي وحدو أبداً).'
      : (isFrench
            ? 'Chaque résumé partagé par vous (aucun envoi automatique).'
            : 'Every summary you chose to share (nothing is ever sent automatically).');
  String get noSharingHistoryYet => isArabic
      ? 'لم يتم تصدير أي ملخص جلسة حتى الآن.'
      : (isFrench
            ? 'Aucun bilan partagé pour l’instant.'
            : 'No clinical briefs have been exported yet.');
  String get clearSharingHistoryBtn => isArabic
      ? 'مسح سجل المشاركات'
      : (isFrench ? 'Purger l’historique' : 'Clear Sharing History');
  String get sharingHistoryCleared => isArabic
      ? 'تم مسح سجل المشاركات بنجاح'
      : (isFrench
            ? 'Historique des partages purgé'
            : 'Clinical sharing history cleared');
  String get closeBtn => isArabic ? 'إغلاق' : (isFrench ? 'Fermer' : 'Close');

  // AI Companion Engine Settings (Direct Free Gemini API Key)
  String get aiEngineSectionTitle => isArabic
      ? 'محرك الذكاء الاصطناعي (GEMINI)'
      : (isFrench ? 'MOTEUR D’IA (GEMINI)' : 'AI COMPANION ENGINE');
  String get aiEngineSectionDesc => isArabic
      ? 'اربط مفتاح Gemini المجاني للتحليل السريري المباشر أو اعتمد المحاكي الداخلي (\$0.00)'
      : (isFrench
            ? 'Connectez votre clé Gemini gratuite pour l’analyse directe ou utilisez le simulateur local (\$0.00)'
            : 'Connect your free Gemini API key for live analysis or use the local simulator (\$0.00)');
  String get liveGeminiActiveBadge => isArabic
      ? 'GEMINI FLASH مباشر'
      : (isFrench ? 'GEMINI FLASH ACTIF' : 'LIVE GEMINI FLASH');
  String get offlineMockActiveBadge =>
      isArabic ? 'محاكي محلي' : (isFrench ? 'MOCK LOCAL' : 'OFFLINE MOCK');
  String get geminiApiKeyLabel => isArabic
      ? 'مفتاح Gemini API (Google AI Studio)'
      : (isFrench
            ? 'Clé API Gemini (Google AI Studio)'
            : 'Gemini API Key (Google AI Studio)');
  String get geminiApiKeyHint => isArabic
      ? 'الصق المفتاح AIzaSy... أو AQ...'
      : (isFrench ? 'Collez votre clé API...' : 'Paste your API key');
  String get getFreeKeyLink => isArabic
      ? 'احصل على مفتاح مجاني 100% بدون بطاقة بنكية من aistudio.google.com (1,500 استعلام يومياً مجاناً)'
      : (isFrench
            ? 'Obtenez une clé gratuite sans carte sur aistudio.google.com (1 500 requêtes/jour gratuites)'
            : 'Get a 100% free developer key without credit card at aistudio.google.com (1,500 free queries/day)');
  String get testConnectionBtn => isArabic
      ? 'فحص الاتصال'
      : (isFrench ? 'TESTER LA CONNEXION' : 'TEST CONNECTION');
  String get saveKeyBtn =>
      isArabic ? 'حفظ وتفعيل' : (isFrench ? 'ENREGISTRER' : 'SAVE & ACTIVATE');
  String get clearKeyBtn => isArabic
      ? 'مسح المفتاح (الرجوع للمحاكي)'
      : (isFrench ? 'Purger la clé' : 'Clear Key');
  String get connectionSuccessToast => isArabic
      ? 'تم الاتصال بنجاح بـ Gemini Flash'
      : (isFrench
            ? 'Connexion réussie à Gemini Flash'
            : 'Connected to Gemini Flash successfully');
  String get connectionFailedToast => isArabic
      ? 'فشل الاتصال: تأكد من صحة المفتاح والإنترنت'
      : (isFrench
            ? 'Échec de connexion : vérifiez la clé et le réseau'
            : 'Connection failed: verify your key and internet');
  String get keySavedToast => isArabic
      ? 'تم تفعيل محرك Gemini المباشر بنجاح'
      : (isFrench
            ? 'Moteur Gemini direct activé avec succès'
            : 'Gemini live engine activated successfully');
  String get keyClearedToast => isArabic
      ? 'تم مسح المفتاح والعودة للمحاكي المحلي (\$0.00)'
      : (isFrench
            ? 'Clé purgée, retour au simulateur local (\$0.00)'
            : 'Key cleared, reverted to local mock (\$0.00)');

  // Direct Live Conversation with The Warm Investigator
  String get dialogueModeTitle => isArabic
      ? 'حوار مباشر'
      : (isFrench ? 'Dialogue Direct' : 'Live Dialogue');
  String get labModeTitle => isArabic
      ? 'المختبر السريري'
      : (isFrench ? 'Labo Clinique' : 'Clinical Lab');
  String get investigatorTyping => isArabic
      ? 'الأخصائي يراجع كلامك...'
      : (isFrench
            ? 'Analyse clinique en cours...'
            : 'Care Specialist is reviewing...');
  String get typeMessageHint => isArabic
      ? 'احكي عن حالتك بكلامك البسيط...'
      : (isFrench
            ? 'Décrivez ce que vous ressentez...'
            : 'Describe how you are feeling...');
  String get welcomeDialoguePrompt => isArabic
      ? 'خوذ راحتك. شنوة اللّي شاغلك توا؟'
      : (isFrench
            ? 'Prenez votre temps. Qu’avez-vous sur le cœur ?'
            : 'Take your time. What is on your mind right now?');
  String get quickPillAssumption => isArabic
      ? 'نحسها مجرد فرضية موش حقيقة'
      : (isFrench
            ? 'C’est une supposition, pas un fait'
            : 'It feels like an assumption');
  String get quickPillNoProof => isArabic
      ? 'ما عندي حتى دليل ملموس'
      : (isFrench
            ? 'Je n’ai pas de preuve concrète'
            : 'I have no concrete proof');
  String get quickPillAlternative => isArabic
      ? 'كيفاش نجم نغزر للموضوع بطريقة أخرى؟'
      : (isFrench
            ? 'Quelle serait une autre explication ?'
            : 'What is an alternative explanation?');
  String get quickPillSomatic => isArabic
      ? 'حاسس بتوتر وضغط في بدني'
      : (isFrench
            ? 'Je ressens une tension physique'
            : 'I feel tension in my body');
  String get newSessionBtn =>
      isArabic ? 'جلسة جديدة' : (isFrench ? 'Nouvelle Session' : 'New Session');
  String get convertToCaseBtn => isArabic
      ? 'حفظ الجلسة'
      : (isFrench ? 'Enregistrer la session' : 'Save Session');
  String get caseSavedFromChat => isArabic
      ? 'تم حفظ الحوار في السجل'
      : (isFrench
            ? 'Session archivée dans le Journal'
            : 'Session saved to Journal');
  String get tagStatementFact =>
      isArabic ? 'حقيقة [F]' : (isFrench ? 'Fait [F]' : 'Fact [F]');
  String get tagStatementAssumption => isArabic
      ? 'فرضية [A]'
      : (isFrench ? 'Supposition [A]' : 'Assumption [A]');
  String get tagStatementInterpretation => isArabic
      ? 'تأويل [I]'
      : (isFrench ? 'Interprétation [I]' : 'Interpretation [I]');

  // Cognitive Distortions & Forensic Synthesis
  String get synthesizeCaseBtn => isArabic
      ? 'استخلاص الملف'
      : (isFrench ? 'SYNTHÉTISER' : 'SYNTHESIZE BRIEF');
  String get synthesizingCase => isArabic
      ? 'جاري استخلاص النتائج المعرفية...'
      : (isFrench
            ? 'Synthèse cognitive en cours...'
            : 'Synthesizing cognitive findings...');
  String get caseSynthesizedSuccess => isArabic
      ? 'تم توثيق واستخلاص الجلسة في السجل بنجاح'
      : (isFrench
            ? 'Session synthétisée et enregistrée dans le Journal'
            : 'Session brief synthesized and filed to Journal');
  String get cognitiveDistortionSheetTitle => isArabic
      ? 'فخاخ التفكير الشائعة'
      : (isFrench
            ? 'Pièges de pensée fréquents'
            : 'Common thinking traps');
  String get cognitiveDistortionSheetDesc => isArabic
      ? 'حدد التشويه الفكري الأكثر مطابقة لفكرتك لمساعدتك على تفكيكها بهدوء'
      : (isFrench
            ? 'Identifiez le piège de pensée correspondant pour prendre du recul'
            : 'Identify the automatic thinking trap to re-anchor in reality');
  String get distortionEmotionalReasoning => isArabic
      ? 'الاستدلال الشعوري (الشعور بالشيء يجعله حقيقة)'
      : (isFrench
            ? 'Raisonnement émotionnel (je le ressens donc c’est vrai)'
            : 'Emotional Reasoning (feeling = reality)');
  String get distortionMentalFilter => isArabic
      ? 'التصفية الذهنية (التركيز على السلبي وتجاهل الإيجابي)'
      : (isFrench
            ? 'Filtre mental (focalisation négative)'
            : 'Mental Filter (discounting the positives)');
  String get distortionOvergeneralization => isArabic
      ? 'التعميم المفرط (موقف سلبي واحد يتحول إلى قاعدة دائمة)'
      : (isFrench
            ? 'Généralisation excessive (règle absolue)'
            : 'Overgeneralization (single event = permanent pattern)');
  String get tagDistortionBtn => isArabic
      ? '+ فرز الفكرة'
      : (isFrench
            ? '+ Repérer'
            : '+ Tag thought');
  String get quickPillWhatFacts => isArabic
      ? 'شنوة اللي صار بالحق في الواقع؟'
      : (isFrench
            ? 'Quels sont les faits observables ?'
            : 'What are the raw facts?');
  String get quickPillFriendPerspective => isArabic
      ? 'شنوة كنت ننصح صديق لو كان في بلاصتي؟'
      : (isFrench
            ? 'Que dirais-je à un ami proche ?'
            : 'What would I tell a friend?');
  String get quickPillControl => isArabic
      ? 'شنوة اللي في نطاق تحكمي توا؟'
      : (isFrench
            ? 'Que puis-je contrôler maintenant ?'
            : 'What is in my control right now?');

  // =========================================================================
  // 3. The Thought Trace & Daily Mind Trace
  // =========================================================================
  String get dailyMindTraceTitle => isArabic
      ? 'أثر اليوم'
      : (isFrench ? 'Trace Quotidienne' : 'Daily Mind Trace');
  String get dailyMindTraceQuote => isArabic
      ? '«كل نهار يخلي أثر فينا. كيفاش تحب ترسم وتوثق أثر يومك الليلة؟»'
      : (isFrench
            ? '« Chaque jour laisse une trace. À quoi ressemble la vôtre aujourd’hui ? »'
            : '“Every day leaves a trace. What does yours look like today?”');
  String get thoughtTraceTitle => isArabic
      ? 'أثر الأفكار'
      : (isFrench ? 'L’Empreinte des Pensées' : 'The Thought Trace');
  String get thoughtTraceQuote => isArabic
      ? 'كل تسجيلة صغيرة تعاونك تفهم أيامك بوضوح أكثر.'
      : (isFrench
            ? 'Chaque petit point vous aide à mieux comprendre vos journées.'
            : 'Every small check-in helps you see your days more clearly.');
  String get thoughtTraceTab =>
      isArabic ? 'أثر الأفكار' : (isFrench ? 'Empreinte' : 'The Thought Trace');
  String get constellationTab => thoughtTraceTab;
  String get patternsTab => isArabic
      ? 'استكشاف الأنماط'
      : (isFrench ? 'Exploration des Schémas' : 'Pattern Exploration');
  String get checkInTab =>
      isArabic ? 'تسجيل الأثر' : (isFrench ? 'Bilan' : 'Check-in');
  String get recordTraceBtn => isArabic
      ? 'تسجيل أثر اليوم في السجل'
      : (isFrench
            ? 'Enregistrer dans l’archive'
            : 'Save daily check-in');
  String get traceSavedSnackbar => isArabic
      ? 'تم تسجيل أثر الفكرة وحفظه في أرشيفك الشخصي بنجاح'
      : (isFrench
            ? 'Empreinte de pensée enregistrée dans votre archive personnelle'
            : 'Daily thought trace recorded in your personal archive');

  // =========================================================================
  // 1. Personalized Mental Health Profile
  // =========================================================================
  // 1. Personalized Mental Health Profile (Session 03)
  // =========================================================================
  String get myPsychologicalProfileTitle => isArabic
      ? 'ملفي النفسي'
      : (isFrench ? 'Mon Profil Psychologique' : 'My Psychological Profile');
  String get profileIntroQuote => isArabic
      ? 'شارك كان اللّي تحبو يعاونك في التطبيق.'
      : (isFrench
            ? 'Partagez uniquement ce qui nous aide à vous accompagner.'
            : 'Share only what helps Mindora support you.');
  String get profileSecondaryQuote => isArabic
      ? 'كل شي اختياري ويبقى في تليفونك.'
      : (isFrench
            ? 'Tout est facultatif et reste sur votre téléphone.'
            : 'Everything is optional and stays on your phone.');
  String get sectionAboutMe =>
      isArabic ? 'عني' : (isFrench ? 'À propos de moi' : 'About Me');
  String get sectionAboutMeDesc => isArabic
      ? 'الاسم المفضل، الفئة العمرية، اللغة المفضلة، ومقدمة شخصية.'
      : (isFrench
            ? 'Nom préféré, tranche d’âge, langue et présentation personnelle.'
            : 'Preferred name, age range, language, and personal introduction.');
  String get sectionExperiences => isArabic
      ? 'التجارب النفسية'
      : (isFrench ? 'Expériences psychologiques' : 'Psychological Experiences');
  String get sectionExperiencesDesc => isArabic
      ? 'التجارب والحالات المعاشة ومستوى التشخيص أو الاستكشاف.'
      : (isFrench
            ? 'Vécus, schémas ou particularités et leur statut d’évaluation.'
            : 'Conditions, patterns, and neurodivergent traits relevant to you.');
  String get sectionSymptoms => isArabic
      ? 'الأعراض والصعوبات'
      : (isFrench ? 'Symptômes et difficultés' : 'Symptoms and Difficulties');
  String get sectionSymptomsDesc => isArabic
      ? 'التحديات الانفعالية، الفكرية، السلوكية والجسدية الحالية.'
      : (isFrench
            ? 'Défis émotionnels, cognitifs, comportementaux et somatiques.'
            : 'Current emotional, cognitive, and behavioral challenges.');
  String get sectionGoals => isArabic
      ? 'الأهداف الشخصية'
      : (isFrench ? 'Objectifs personnels' : 'Personal Goals');
  String get sectionGoalsDesc => isArabic
      ? 'ما ترغب في استكشافه أو تطويره من خلال Mindora.'
      : (isFrench
            ? 'Ce que vous souhaitez comprendre ou renforcer grâce à l’application.'
            : 'What you would like to explore or improve through Mindora.');
  String get sectionContext => isArabic
      ? 'سياقي الشخصي'
      : (isFrench ? 'Contexte personnel' : 'Personal Context');
  String get sectionContextDesc => isArabic
      ? 'ما ترغب أن يدركه التطبيق عن تاريخك وتحدياتك وما يساعدك.'
      : (isFrench
            ? 'Ce que vous aimeriez que Mindora comprenne de votre parcours.'
            : 'What you would like Mindora to understand about you.');
  String get sectionCommunication => isArabic
      ? 'تفضيلات التواصل'
      : (isFrench
            ? 'Préférences de communication'
            : 'Communication Preferences');
  String get sectionCommunicationDesc => isArabic
      ? 'نبرة المساعد، طول الردود، وتفضيلات التعامل أثناء التوتر.'
      : (isFrench
            ? 'Ton du compagnon, longueur des réponses et préférences en cas de détresse.'
            : 'AI tone, response length, and preferences when feeling distressed.');
  String get sectionPrivacy => isArabic
      ? 'الخصوصية وتخصيص الذكاء الاصطناعي'
      : (isFrench ? 'Confidentialité et IA' : 'Privacy and AI Personalization');
  String get sectionPrivacyDesc => isArabic
      ? 'التحكم الدقيق في مشاركة السياق، حذف البيانات، وخصوصية الحساب.'
      : (isFrench
            ? 'Contrôle granulaire du contexte IA et gestion des données locales.'
            : 'Granular control over AI context, data removal, and account privacy.');
  String get profileNotCompletedBadge => isArabic
      ? 'غير مكتمل بعد'
      : (isFrench ? 'À compléter' : 'Not yet completed');
  String get profileCompletedBadge =>
      isArabic ? 'مكتمل' : (isFrench ? 'Complété' : 'Completed');
  String get profileSubtitle => isArabic
      ? 'مساحة شخصية وسرية لتوثيق تجاربك وتخصيص مرافقتك النفسية وفق احتياجاتك.'
      : (isFrench
            ? 'Espace confidentiel pour consigner votre vécu et personnaliser votre accompagnement.'
            : 'A confidential space to document your lived experiences and personalize your companion.');
  String get conditionsSectionTitle => isArabic
      ? 'التجارب والحالات النفسية'
      : (isFrench ? 'Conditions & Expériences' : 'Conditions & Experiences');
  String get conditionsSectionSubtitle => isArabic
      ? 'اختر ما يعبر عن تجربتك الشخصية. الاختيار لا يعني بالضرورة وجود تشخيص طبي رسمي.'
      : (isFrench
            ? 'Sélectionnez ce qui résonne avec votre vécu. Ne constitue pas un diagnostic médical.'
            : 'Select what resonates with your experience. Selection does not assume a clinical diagnosis.');
  String get statusTitle => isArabic
      ? 'حالة التقييم السريري'
      : (isFrench ? 'Statut d’évaluation' : 'Evaluation Status');
  String get optionalDetailsTitle => isArabic
      ? 'سياق وتفاصيل إضافية (اختياري)'
      : (isFrench
            ? 'Contexte & détails (facultatif)'
            : 'Optional Context & Details');
  String get symptomsLabel => isArabic
      ? 'الأعراض والتجارب المعاشة'
      : (isFrench ? 'Symptômes et vécus' : 'Symptoms and lived experiences');
  String get durationLabel => isArabic
      ? 'المدة الزمنية لهذه التجارب'
      : (isFrench
            ? 'Durée de cette expérience'
            : 'How long you have experienced them');
  String get difficultiesLabel => isArabic
      ? 'الصعوبات الحالية الأكثر تأثيراً'
      : (isFrench ? 'Difficultés actuelles' : 'Current difficulties');
  String get triggersLabel => isArabic
      ? 'المحفزات الشخصية المعروفة'
      : (isFrench
            ? 'Déclencheurs personnels connus'
            : 'Personal triggers, if known');
  String get treatmentLabel => isArabic
      ? 'المتابعة أو العلاج المهني الحالي'
      : (isFrench
            ? 'Accompagnement ou traitement actuel'
            : 'Current treatment or professional support');
  String get goalsLabel => isArabic
      ? 'أهدافك الشخصية من الاستكشاف'
      : (isFrench ? 'Vos objectifs personnels' : 'Personal goals');
  String get notesForAiLabel => isArabic
      ? 'ما ترغب أن يدركه مرافقك الذكي'
      : (isFrench
            ? 'Ce que l’IA devrait comprendre de vous'
            : 'Things you want your AI companion to understand');
  String get shareWithAiToggle => isArabic
      ? 'مشاركة الملف مع المرافق الذكي'
      : (isFrench
            ? 'Partager avec le compagnon IA'
            : 'Share profile with AI companion');
  String get shareWithAiDesc => isArabic
      ? 'يخلّي الحوار يمشي مع أهدافك ويبقى كل شي في تليفونك.'
      : (isFrench
            ? 'Adapte l’écoute à vos objectifs tout en restant local.'
            : 'Lets Talk tailor replies to your goals while staying on your phone.');
  String get saveProfileBtn => isArabic
      ? 'حفظ الملف النفسي'
      : (isFrench ? 'Enregistrer le profil' : 'Save profile');
  String get profileSavedSnackbar => isArabic
      ? 'تم حفظ الملف النفسي وتحديث سياق المرافق بنجاح'
      : (isFrench
            ? 'Profil psychologique mis à jour avec succès'
            : 'Psychological profile saved and AI context updated');
  String get editConditionStatusTitle => isArabic
      ? 'تحديد حالة التقييم'
      : (isFrench ? 'Définir le statut' : 'Specify Evaluation Status');
  String get conditionNoteLabel => isArabic
      ? 'ملاحظة خاصة بهذه الحالة'
      : (isFrench
            ? 'Note personnelle pour cette condition'
            : 'Personal note for this condition');
  String get tabProfile =>
      isArabic ? 'ملفي النفسي' : (isFrench ? 'Mon Profil' : 'My Profile');
  String get tabSettings => isArabic
      ? 'الإعدادات والخصوصية'
      : (isFrench ? 'Paramètres & Confidentialité' : 'Settings & Privacy');

  // =========================================================================
  // 2. Personalized Psychological Journey & Progress
  // =========================================================================
  String get myJourneyTitle =>
      isArabic ? 'رحلتي النفسية' : (isFrench ? 'Mon Parcours' : 'My Journey');
  String get myJourneySubtitle => isArabic
      ? 'مسار مرن واستكشافي يتكيف معك، بدون تقييمات قسرية أو نسب تعافٍ زائفة.'
      : (isFrench
            ? 'Cadre d’exploration flexible et bienveillant, sans pourcentages de guérison arbitraires.'
            : 'A flexible, non-judgmental exploration framework without arbitrary recovery scores.');
  String get myProgressTab =>
      isArabic ? 'تقدمي ومحطاتي' : (isFrench ? 'Mes Progrès' : 'My Progress');
  String get currentPhaseLabel => isArabic
      ? 'المرحلة المستكشفة حالياً'
      : (isFrench ? 'Phase active' : 'Active Phase');
  String get activityCompletedBadge =>
      isArabic ? 'مكتمل' : (isFrench ? 'Complété' : 'Completed');
  String get activityInProgressBadge =>
      isArabic ? 'استكشاف' : (isFrench ? 'En cours' : 'Explore');
  String get startActivityBtn => isArabic
      ? 'بدء التمرين والتأمل'
      : (isFrench ? 'Explorer l’activité' : 'Explore Activity');
  String get guidedInstructionsTitle => isArabic
      ? 'إرشادات توجيهية خطوة بخطوة'
      : (isFrench ? 'Instructions pas-à-pas' : 'Guided Instructions');
  String get reflectionQuestionsTitle => isArabic
      ? 'أسئلة التأمل والاستبصار'
      : (isFrench ? 'Questions de réflexion' : 'Reflection Questions');
  String get personalNotesLabel => isArabic
      ? 'ملاحظاتي واستنتاجاتي الشخصية'
      : (isFrench
            ? 'Notes & réflexions personnelles'
            : 'Personal notes and reflections');
  String get markAsCompletedBtn => isArabic
      ? 'تعليم كمكتمل'
      : (isFrench ? 'Marquer comme complété' : 'Mark as Completed');
  String get saveReflectionBtn => isArabic
      ? 'حفظ التأمل والاستنتاجات'
      : (isFrench ? 'Enregistrer la réflexion' : 'Save reflection');
  String get reflectionSavedSnackbar => isArabic
      ? 'تم حفظ تأملاتك بنجاح'
      : (isFrench
            ? 'Réflexion enregistrée avec succès'
            : 'Reflection saved successfully');
  String get totalCompletedActivities => isArabic
      ? 'الأنشطة المكتملة'
      : (isFrench ? 'Activités complétées' : 'Completed Activities');
  String get totalReflectionsLogged => isArabic
      ? 'التأملات المدونة'
      : (isFrench ? 'Réflexions consignées' : 'Reflections Logged');
  String get nonJudgmentalNotice => isArabic
      ? 'امشي على راحتك. تنجّم تعدّي ولا ترجع لأي خطوة وقت ما تحب.'
      : (isFrench
            ? 'Avancez à votre rythme. Passez ou revenez quand vous voulez.'
            : 'Go at your own pace. Skip or revisit any step anytime.');
  String get toolkitLabTab =>
      isArabic ? 'مختبر الأدوات' : (isFrench ? 'Boîte à Outils' : 'Tools Lab');

  // =========================================================================
  // 3. Authentication & Account Onboarding
  // =========================================================================
  String get authTitle => isArabic
      ? 'الدخول إلى حسابك'
      : (isFrench ? 'Accès à votre compte' : 'Access Your Account');
  String get authSubtitle => isArabic
      ? 'سجّل حالتك اليومية، نومك وملخصات طبيبك بكل سرية على تليفونك.'
      : (isFrench
            ? 'Gardez votre humeur, votre sommeil et vos résumés médicaux en sécurité sur ce téléphone.'
            : 'Keep your daily mood, sleep & doctor summaries safe on this phone.');
  String get signInTab =>
      isArabic ? 'تسجيل الدخول' : (isFrench ? 'Connexion' : 'Sign In');
  String get signUpTab => isArabic
      ? 'إنشاء حساب'
      : (isFrench ? 'Créer un compte' : 'Create Account');
  String get emailFieldLabel => isArabic
      ? 'البريد الإلكتروني'
      : (isFrench ? 'Adresse email' : 'Email Address');
  String get emailFieldHint => 'name@example.com';
  String get passwordFieldLabel =>
      isArabic ? 'كلمة السر' : (isFrench ? 'Mot de passe' : 'Password');
  String get passwordFieldHint => isArabic
      ? '6 أحرف على الأقل'
      : (isFrench ? '6 caractères minimum' : 'At least 6 characters');
  String get codenameFieldLabel => isArabic
      ? 'الاسم المفضل (اختياري)'
      : (isFrench
            ? 'Prénom ou pseudo (facultatif)'
            : 'Preferred name (optional)');
  String get codenameFieldHint => isArabic
      ? 'مثال: أمال'
      : (isFrench ? 'ex : Yassine' : 'e.g. Yassine');
  String get localProfileOnlyNote => isArabic
      ? 'اختياري: يتخزّن على هذا التليفون فقط. صدّر نسخة احتياطية قبل تبديل الهاتف.'
      : (isFrench
            ? 'Optionnel : enregistré sur ce téléphone uniquement. Exportez une sauvegarde avant de changer d’appareil.'
            : 'Optional: saved on this phone only. Export a backup before switching devices.');
  String get createVaultBtn => isArabic
      ? 'إنشاء حساب'
      : (isFrench ? 'Créer un compte' : 'Create account');
  String get unlockVaultBtn =>
      isArabic ? 'تسجيل الدخول' : (isFrench ? 'Se connecter' : 'Sign in');
  String get anonymousOptionTitle => isArabic
      ? 'مساحة محلية خاصة'
      : (isFrench ? 'Espace local privé' : 'Private Local Space');
  String get anonymousOptionSubtitle => isArabic
      ? 'بدون بريد أو هاتف. تبقى كافة البيانات محفوظة محلياً على جهازك لخصوصية تامة.'
      : (isFrench
            ? 'Sans email ni identifiant requis. Toutes les données sont conservées localement sur votre appareil.'
            : 'No email or phone required. All data remains stored locally on your device with complete privacy.');
  String get startAnonymouslyBtn => isArabic
      ? 'متابعة بدون حساب'
      : (isFrench ? 'Continuer sans compte' : 'Continue without an account');
  String get alreadyHaveVaultPrompt => isArabic
      ? 'لديك حساب سابق؟'
      : (isFrench ? 'Vous avez déjà un compte ?' : 'Already have an account?');
  String get newInvestigatorPrompt =>
      isArabic ? 'مستخدم جديد؟' : (isFrench ? 'Nouveau ici ?' : 'New here?');
  String get startExplorationBtn => isArabic
      ? 'ابدأ الأسئلة السريعة'
      : (isFrench ? 'Configurer mon espace' : 'Set up my space');
  String get signInPromptBtn =>
      isArabic ? 'تسجيل الدخول' : (isFrench ? 'Se connecter' : 'Sign In');
  String get biometricUnlockBtn => isArabic
      ? 'فتح سريع بالبصمة'
      : (isFrench ? 'Déverrouillage biométrique' : 'Quick Biometric Unlock');
  String get linkEmailTitle => isArabic
      ? 'الربط بحساب سحابي'
      : (isFrench ? 'Associer un compte cloud' : 'Sync to Cloud Account');
  String get linkEmailSubtitle => isArabic
      ? 'اربط بريدك الإلكتروني لمزامنة مسارك النفسي بين أجهزتك بأمان دون فقدان أي ملاحظة.'
      : (isFrench
            ? 'Associez un email pour synchroniser votre parcours entre vos appareils sans rien perdre.'
            : 'Link an email and password to securely sync your journey across devices without losing data.');
  String get linkEmailBtn => isArabic
      ? 'ربط ومزامنة الحساب'
      : (isFrench ? 'ASSOCIER & SYNCHRONISER' : 'LINK & SYNC ACCOUNT');
  String get signOutBtn =>
      isArabic ? 'تسجيل الخروج' : (isFrench ? 'Se déconnecter' : 'Sign Out');
  String get deleteAccountBtn => isArabic
      ? 'حذف الحساب والبيانات'
      : (isFrench
            ? 'Supprimer le compte et les données'
            : 'Delete Account & Data');
  String get vaultStatusAnonymous => isArabic
      ? 'حساب محلي على الجهاز'
      : (isFrench
            ? 'Compte local (sur l’appareil)'
            : 'Local On-Device Account');
  String get vaultStatusCloud => isArabic
      ? 'حساب متزامن سحابياً'
      : (isFrench
            ? 'Compte synchronisé dans le cloud'
            : 'Cloud-Synced Account');
  String get onboardingVaultChoiceTitle => isArabic
      ? 'الحساب والخصوصية'
      : (isFrench ? 'Compte & Confidentialité' : 'Account & Privacy');
  String get onboardingVaultChoiceSubtitle => isArabic
      ? 'حدد كيفية حفظ بياناتك وتأمينها.'
      : (isFrench
            ? 'Choisissez comment sauvegarder et sécuriser vos données.'
            : 'Choose how your reflections and data are stored and protected.');
  String get anonymousChoiceBadge => isArabic
      ? 'أعلى درجات الخصوصية'
      : (isFrench ? 'CONFIDENTIALITÉ MAXIMALE' : 'MAXIMUM PRIVACY');
  String get cloudChoiceBadge => isArabic
      ? 'مزامنة متعددة الأجهزة'
      : (isFrench ? 'SYNCHRONISATION MULTI-APPAREILS' : 'MULTI-DEVICE SYNC');
  String get biometricEnableToggle => isArabic
      ? 'تأمين هذا الجهاز ببصمة الإصبع أو الوجه'
      : (isFrench
            ? 'Protéger l’accès par biométrie'
            : 'Secure device with Biometrics');

  // =========================================================================
  // Adaptive Personalized Onboarding
  // =========================================================================
  String get onboardingBasicInfoTitle => isArabic
      ? 'معلومات أولية'
      : (isFrench ? 'Informations de base' : 'Basic Information');
  String get onboardingBasicInfoSubtitle => isArabic
      ? 'يعاونّا نختاروا أسلوب مريح لعمرك. تنجّم تعدّي أي سؤال.'
      : (isFrench
            ? 'Aide à adapter le ton à votre âge. Tout se passe si besoin.'
            : 'Helps us keep language comfortable for your age. Skip anything.');
  String get ageRangeLabel =>
      isArabic ? 'الفئة العمرية' : (isFrench ? 'Tranche d’âge' : 'Age Range');
  String get biologicalSexLabel => isArabic
      ? 'السياق الجسدي / الجنس (اختياري)'
      : (isFrench
            ? 'Contexte physiologique / Sexe (facultatif)'
            : 'Physiological Context / Sex (Optional)');
  String get biologicalSexHelperNote => isArabic
      ? 'اختياري — يعاون برك في نصائح النوم والطاقة.'
      : (isFrench
            ? 'Facultatif — utilisé uniquement pour le sommeil et l’énergie.'
            : 'Optional — used only for energy and sleep tips.');
  String get minorSupportNotice => isArabic
      ? 'التطبيق للتأمل موش للعلاج الطبي. كان حسّيت بضيق كبير كلّم شخص راشد تثق فيه ولا 190.'
      : (isFrench
            ? 'Mindora n’est pas un soin médical. En cas de détresse, parlez à un adulte de confiance ou au 190.'
            : 'Mindora is for reflection, not medical care. If you feel unsafe, talk to a trusted adult or call 190.');

  String get onboardingBackgroundTitle => isArabic
      ? 'نقطة انطلاقك'
      : (isFrench ? 'Votre point de départ' : 'Your Starting Point');
  String get onboardingBackgroundSubtitle => isArabic
      ? 'أي من هذه الخيارات يصف وضعك الحالي بأفضل صورة؟ كل مسار هنا كامل ومحترم بالتساوي.'
      : (isFrench
            ? 'Quelle option décrit le mieux votre parcours ? Chaque chemin est complet et respecté.'
            : 'Which best describes your current journey? Every path is complete and respected equally.');

  String get bgDiagnosedTitle => isArabic
      ? 'تشخيص طبي رسمي'
      : (isFrench ? 'Diagnostic formel' : 'Diagnosed Condition');
  String get bgDiagnosedDesc => isArabic
      ? 'لدي تشخيص سريري رسمي واحد أو أكثر من قبل مختص مؤهل.'
      : (isFrench
            ? 'J’ai reçu un diagnostic médical formel d’un professionnel.'
            : 'I have received one or more formal clinical diagnoses from a professional.');

  String get bgSuspectedTitle => isArabic
      ? 'اشتباه أو استكشاف ذاتي'
      : (isFrench ? 'Suspicion / Exploration' : 'Suspected / Exploring');
  String get bgSuspectedDesc => isArabic
      ? 'أشتبه في وجود حالة معينة، لكن بدون تشخيص رسمي حتى الآن.'
      : (isFrench
            ? 'Je suspecte un trouble précis, sans diagnostic formel.'
            : 'I suspect I experience a condition, but have no formal diagnosis yet.');

  String get bgAssessingTitle => isArabic
      ? 'بصدد التقييم السريري حالياً'
      : (isFrench ? 'Évaluation en cours' : 'Currently Being Assessed');
  String get bgAssessingDesc => isArabic
      ? 'أخضع حالياً لجلسات تقييم نفسي أو سريري مع مختص.'
      : (isFrench
            ? 'Je suis actuellement suivi pour une évaluation clinique.'
            : 'I am actively undergoing psychological or psychiatric evaluation.');
  String get bgAssessedTitle => bgAssessingTitle;
  String get bgAssessedDesc => bgAssessingDesc;

  String get bgDifficultiesTitle => isArabic
      ? 'صعوبات وتحديات بدون تشخيص'
      : (isFrench
            ? 'Difficultés sans diagnostic'
            : 'Difficulties Without Diagnosis');
  String get bgDifficultiesDesc => isArabic
      ? 'أعاني من صعوبات وتحديات نفسية متكررة دون أي تسميات طبية.'
      : (isFrench
            ? 'Je vis des défis émotionnels ou mentaux récurrents sans étiquette.'
            : 'I experience recurring emotional or cognitive challenges without medical labels.');

  String get bgWellbeingTitle => isArabic
      ? 'تتبع العافية النفسية والروتين'
      : (isFrench ? 'Suivi du bien-être' : 'Wellbeing & Habit Tracking');
  String get bgWellbeingDesc => isArabic
      ? 'أرغب في متابعة توازني النفسي، فهم أفكاري، وبناء عادات هادئة.'
      : (isFrench
            ? 'Je cherche à observer mes pensées et renforcer mon équilibre quotidien.'
            : 'I am here for self-reflection, emotional clarity, and gentle habit awareness.');

  String get bgUnsureTitle => isArabic
      ? 'لست متأكداً بعد'
      : (isFrench ? 'Je ne sais pas encore' : 'Still Figuring It Out');
  String get bgUnsureDesc => isArabic
      ? 'لست متأكداً تماماً، وأريد مساحة آمنة ومريحة لملاحظة نفسي.'
      : (isFrench
            ? 'Pas tout à fait sûr(e), je cherche un espace serein d’exploration.'
            : 'I am not sure where I fit, but I want a safe space to observe myself.');

  String get conditionSearchHint => isArabic
      ? 'ابحث في الحالات والتجارب...'
      : (isFrench
            ? 'Rechercher une condition ou expérience...'
            : 'Search conditions or lived experiences...');
  String get statusDiagnosedTag =>
      isArabic ? 'تشخيص سريري مؤكد' : (isFrench ? 'Diagnostiqué' : 'Diagnosed');
  String get statusSuspectedTag => isArabic
      ? 'اشتباه / استكشاف'
      : (isFrench ? 'Suspecté / En exploration' : 'Suspected / Exploring');
  String get conditionNonDiagnosticNote => isArabic
      ? 'تحديد حالتك يساعد على فهم عالمك النفسي؛ ولا يعني أبداً وضع تشخيص سريري جديد.'
      : (isFrench
            ? 'Ce choix contextualise vos outils ; il ne constitue jamais un diagnostic médical.'
            : 'Selection contextualizes your reflection space; it never implies or confirms a diagnosis.');

  String get symptomsSelectionTitle => isArabic
      ? 'الأعراض والتحديات الحالية'
      : (isFrench
            ? 'Symptômes & Défis actuels'
            : 'Current Symptoms & Difficulties');
  String get symptomsSelectionSubtitle => isArabic
      ? 'اختار الأعراض أو المشاعر اللّي تحب تتابعها.'
      : (isFrench
            ? 'Choisissez les signes que vous souhaitez suivre.'
            : 'Pick any body or mood signs you want to keep an eye on.');

  String get supportSystemTitle => isArabic
      ? 'المرافقة المهنية الحالية (اختياري)'
      : (isFrench
            ? 'Accompagnement professionnel (Facultatif)'
            : 'Professional Support (Optional)');
  String get supportSystemSubtitle => isArabic
      ? 'هل تعمل حالياً مع مختص أو شبكة دعم؟ هذا يساعد في توجيه ميزات التصدير والتلخيص.'
      : (isFrench
            ? 'Bénéficiez-vous actuellement d’un suivi ? Cela aide à orienter les résumés pour votre thérapeute.'
            : 'Are you currently working with professional care? This helps guide summary and therapist features.');

  String get summaryPrioritiesTitle => isArabic
      ? 'مراجعة أولوياتك وملفك'
      : (isFrench ? 'Synthèse de vos priorités' : 'Review Your Priorities');
  String get summaryPrioritiesSubtitle => isArabic
      ? 'هذه خلاصتك الأولية. يمكنك تعديل أي قسم الآن أو لاحقاً في ملفك الشخصي.'
      : (isFrench
            ? 'Voici votre profil de départ. Vous pouvez modifier n’importe quel point maintenant ou plus tard.'
            : 'Confirm your starting profile. You can edit any section now or refine it later in Profile.');

  String get editSectionBtn =>
      isArabic ? 'تعديل' : (isFrench ? 'Modifier' : 'Edit');
  String get confirmAndStartBtn => isArabic
      ? 'تأكيد وبدء الاستخدام'
      : (isFrench ? 'CONFIRMER & COMMENCER' : 'CONFIRM & GET STARTED');
  String get returnToSummaryBtn => isArabic
      ? 'الرجوع للملخص'
      : (isFrench ? 'Retour à la synthèse' : 'Return to Summary');

  // Condition and Status Display Name Localizers
  String conditionName(ConditionType condition) {
    if (isArabic) {
      switch (condition) {
        case ConditionType.depression:
          return 'الاكتئاب';
        case ConditionType.bipolarI:
          return 'اضطراب ثنائي القطب النوع الأول';
        case ConditionType.bipolarII:
          return 'اضطراب ثنائي القطب النوع الثاني';
        case ConditionType.moodInstability:
          return 'تقلبات المزاج وعدم الاستقرار';
        case ConditionType.otherMood:
          return 'تجارب مزاجية أخرى';
        case ConditionType.generalizedAnxiety:
          return 'القلق العام (GAD)';
        case ConditionType.socialAnxiety:
          return 'القلق الاجتماعي';
        case ConditionType.panicAttacks:
          return 'نوبات الهلع (Panic Attacks)';
        case ConditionType.specificPhobias:
          return 'مخاوف ورهاب محدد';
        case ConditionType.otherAnxiety:
          return 'تجارب قلق أخرى';
        case ConditionType.ocd:
          return 'الوسواس القهري (OCD)';
        case ConditionType.intrusiveThoughts:
          return 'أفكار متطفلة وملحة';
        case ConditionType.repetitiveThoughts:
          return 'أفكار متكررة واجترار';
        case ConditionType.compulsiveBehaviors:
          return 'سلوكيات قهرية متكررة';
        case ConditionType.ptsd:
          return 'اضطراب ما بعد الصدمة (PTSD)';
        case ConditionType.complexPtsd:
          return 'اضطراب ما بعد الصدمة المعقد (C-PTSD)';
        case ConditionType.traumaDifficulties:
          return 'صعوبات ناتجة عن صدمات';
        case ConditionType.adhd:
          return 'تشتت الانتباه وفرط الحركة (ADHD)';
        case ConditionType.autism:
          return 'طيف التوحد';
        case ConditionType.attentionDifficulties:
          return 'صعوبات الانتباه والتركيز';
        case ConditionType.sensoryDifficulties:
          return 'حساسية وتحديات حسية';
        case ConditionType.psychosisSpectrum:
          return 'تجارب طيف الذهان';
        case ConditionType.schizophrenia:
          return 'الفصام (Schizophrenia)';
        case ConditionType.hallucinations:
          return 'تجارب حسية وهلوسات';
        case ConditionType.delusions:
          return 'معتقدات خاصة / ضلالات';
        case ConditionType.otherPerceptual:
          return 'تجارب إدراكية غير اعتيادية';
        case ConditionType.dissociativeDisorders:
          return 'الاضطرابات التفارقية';
        case ConditionType.dissociativeExperiences:
          return 'تجارب انفصال وتفارق';
        case ConditionType.eatingDisorders:
          return 'اضطرابات الأكل';
        case ConditionType.eatingDifficulties:
          return 'صعوبات تتعلق بالأكل';
        case ConditionType.personalityDisorders:
          return 'اضطرابات الشخصية';
        case ConditionType.personalityDifficulties:
          return 'صعوبات نمط الشخصية';
        case ConditionType.sleepDisorders:
          return 'اضطرابات النوم والأرق';
        case ConditionType.sleepDifficulties:
          return 'صعوبات النوم والاستيقاظ';
        case ConditionType.other:
          return 'حالة أخرى / غير مدرجة';
        case ConditionType.stillExploring:
          return 'ما زلت أستكشف صحتي النفسية';
        case ConditionType.preferNotToSpecify:
          return 'أفضل عدم التحديد';
      }
    } else if (isFrench) {
      switch (condition) {
        case ConditionType.depression:
          return 'Dépression';
        case ConditionType.bipolarI:
          return 'Trouble bipolaire I';
        case ConditionType.bipolarII:
          return 'Trouble bipolaire II';
        case ConditionType.moodInstability:
          return 'Instabilité de l’humeur';
        case ConditionType.otherMood:
          return 'Autres expériences de l’humeur';
        case ConditionType.generalizedAnxiety:
          return 'Anxiété généralisée (TAG)';
        case ConditionType.socialAnxiety:
          return 'Anxiété sociale';
        case ConditionType.panicAttacks:
          return 'Attaques de panique';
        case ConditionType.specificPhobias:
          return 'Phobies spécifiques';
        case ConditionType.otherAnxiety:
          return 'Autres expériences anxieuses';
        case ConditionType.ocd:
          return 'Trouble obsessionnel-compulsif (TOC)';
        case ConditionType.intrusiveThoughts:
          return 'Pensées intrusives';
        case ConditionType.repetitiveThoughts:
          return 'Pensées répétitives';
        case ConditionType.compulsiveBehaviors:
          return 'Comportements compulsifs';
        case ConditionType.ptsd:
          return 'Stress post-traumatique (TSPT)';
        case ConditionType.complexPtsd:
          return 'TSPT complexe';
        case ConditionType.traumaDifficulties:
          return 'Difficultés liées aux traumatismes';
        case ConditionType.adhd:
          return 'TDAH';
        case ConditionType.autism:
          return 'Spectre de l’autisme';
        case ConditionType.attentionDifficulties:
          return 'Difficultés d’attention';
        case ConditionType.sensoryDifficulties:
          return 'Sensibilités sensorielles';
        case ConditionType.psychosisSpectrum:
          return 'Expériences du spectre psychotique';
        case ConditionType.schizophrenia:
          return 'Schizophrénie';
        case ConditionType.hallucinations:
          return 'Expériences hallucinatoires';
        case ConditionType.delusions:
          return 'Idées délirantes / croyances inhabituelles';
        case ConditionType.otherPerceptual:
          return 'Autres perceptions inhabituelles';
        case ConditionType.dissociativeDisorders:
          return 'Troubles dissociatifs';
        case ConditionType.dissociativeExperiences:
          return 'Expériences dissociatives';
        case ConditionType.eatingDisorders:
          return 'Troubles du comportement alimentaire';
        case ConditionType.eatingDifficulties:
          return 'Difficultés alimentaires';
        case ConditionType.personalityDisorders:
          return 'Troubles de la personnalité';
        case ConditionType.personalityDifficulties:
          return 'Difficultés relationnelles/personnalité';
        case ConditionType.sleepDisorders:
          return 'Troubles du sommeil';
        case ConditionType.sleepDifficulties:
          return 'Difficultés de sommeil';
        case ConditionType.other:
          return 'Autre / Non listé';
        case ConditionType.stillExploring:
          return 'En cours d’exploration';
        case ConditionType.preferNotToSpecify:
          return 'Préfère ne pas préciser';
      }
    } else {
      return condition.defaultDisplayName();
    }
  }

  String statusName(DiagnosticStatus status) {
    if (isArabic) {
      switch (status) {
        case DiagnosticStatus.professionallyDiagnosed:
          return 'تشخيص طبي معتمد';
        case DiagnosticStatus.currentlyBeingEvaluated:
          return 'قيد التقييم السريري حالياً';
        case DiagnosticStatus.selfIdentifiedExploring:
          return 'استكشاف ذاتي / ملاحظة شخصية';
        case DiagnosticStatus.preferNotToSay:
          return 'أفضل عدم الذكر';
      }
    } else if (isFrench) {
      switch (status) {
        case DiagnosticStatus.professionallyDiagnosed:
          return 'Diagnostic professionnel';
        case DiagnosticStatus.currentlyBeingEvaluated:
          return 'En cours d’évaluation';
        case DiagnosticStatus.selfIdentifiedExploring:
          return 'Auto-identifié / En exploration';
        case DiagnosticStatus.preferNotToSay:
          return 'Préfère ne pas dire';
      }
    } else {
      return status.defaultDisplayName();
    }
  }

  String ageRangeDisplayName(String key) {
    switch (key) {
      case 'under_18':
      case '<18':
        return isArabic
            ? 'أقل من 18 سنة'
            : (isFrench ? 'Moins de 18 ans' : 'Under 18');
      case '18-24':
        return isArabic ? '18 - 24 سنة' : (isFrench ? '18-24 ans' : '18-24');
      case '25-34':
        return isArabic ? '25 - 34 سنة' : (isFrench ? '25-34 ans' : '25-34');
      case '35-44':
        return isArabic ? '35 - 44 سنة' : (isFrench ? '35-44 ans' : '35-44');
      case '25-44':
        return isArabic ? '25 - 44 سنة' : (isFrench ? '25-44 ans' : '25-44');
      case '45-54':
        return isArabic ? '45 - 54 سنة' : (isFrench ? '45-54 ans' : '45-54');
      case '55-64':
        return isArabic ? '55 - 64 سنة' : (isFrench ? '55-64 ans' : '55-64');
      case '45-64':
        return isArabic ? '45 - 64 سنة' : (isFrench ? '45-64 ans' : '45-64');
      case '65+':
        return isArabic ? '+65 سنة' : (isFrench ? '65 ans et plus' : '65+');
      case 'prefer_not_to_say':
      default:
        return isArabic
            ? 'أفضل عدم التحديد'
            : (isFrench ? 'Préfère ne pas préciser' : 'Prefer not to say');
    }
  }

  String biologicalSexDisplayName(String key) {
    switch (key) {
      case 'female':
        return isArabic ? 'أنثى' : (isFrench ? 'Femme' : 'Female');
      case 'male':
        return isArabic ? 'ذكر' : (isFrench ? 'Homme' : 'Male');
      case 'intersex':
        return isArabic
            ? 'ثنائي الجنس (Intersex)'
            : (isFrench ? 'Intersexe' : 'Intersex');
      case 'other':
        return isArabic ? 'آخر / مختلف' : (isFrench ? 'Autre' : 'Other');
      case 'prefer_not_to_say':
      default:
        return isArabic
            ? 'أفضل عدم التحديد'
            : (isFrench ? 'Préfère ne pas préciser' : 'Prefer not to say');
    }
  }

  String supportSystemOptionTitle(String key) {
    switch (key) {
      case 'therapist':
        return isArabic
            ? 'معالج نفسي أو أخصائي عيادي'
            : (isFrench
                  ? 'Psychothérapeute ou psychologue'
                  : 'Therapist or Psychologist');
      case 'psychiatrist':
        return isArabic
            ? 'طبيب نفسي (Psychiatrist)'
            : (isFrench ? 'Psychiatre' : 'Psychiatrist');
      case 'assessment':
        return isArabic
            ? 'قيد التقييم السريري حالياً'
            : (isFrench
                  ? 'Évaluation clinique en cours'
                  : 'Undergoing Clinical Evaluation');
      case 'primary_care':
        return isArabic
            ? 'طبيب عام أو رعاية أولية'
            : (isFrench ? 'Médecin généraliste' : 'Primary Care / GP');
      case 'coach':
        return isArabic
            ? 'مرشد نفسي أو موجّه (Coach)'
            : (isFrench ? 'Conseiller ou coach' : 'Counselor or Coach');
      case 'self_guided':
        return isArabic
            ? 'متابعة ذاتية مستقلة'
            : (isFrench ? 'Suivi autonome' : 'Self-guided (No current care)');
      case 'prefer_not_to_say':
      default:
        return isArabic
            ? 'أفضل عدم التحديد'
            : (isFrench ? 'Préfère ne pas préciser' : 'Prefer not to say');
    }
  }

  String backgroundDisplayName(String key) {
    switch (key) {
      case 'diagnosed':
        return bgDiagnosedTitle;
      case 'suspected':
        return bgSuspectedTitle;
      case 'being_assessed':
        return bgAssessedTitle;
      case 'difficulties_no_diagnosis':
        return bgDifficultiesTitle;
      case 'wellbeing_tracking':
        return bgWellbeingTitle;
      case 'unsure':
      default:
        return bgUnsureTitle;
    }
  }

  String phaseTitle(JourneyPhase phase) {
    if (isArabic) {
      switch (phase) {
        case JourneyPhase.phase1SelfDiscovery:
          return 'المرحلة 1: اكتشاف الذات';
        case JourneyPhase.phase2UnderstandingPatterns:
          return 'المرحلة 2: فهم الأنماط';
        case JourneyPhase.phase3PsychologicalAwareness:
          return 'المرحلة 3: الوعي النفسي';
        case JourneyPhase.phase4CopingAndDevelopment:
          return 'المرحلة 4: التكيف والتطور';
        case JourneyPhase.phase5PersonalGrowthAndMaintenance:
          return 'المرحلة 5: النمو والاستمرارية';
      }
    } else if (isFrench) {
      switch (phase) {
        case JourneyPhase.phase1SelfDiscovery:
          return 'Phase 1 : Découverte de soi';
        case JourneyPhase.phase2UnderstandingPatterns:
          return 'Phase 2 : Schémas & Liens';
        case JourneyPhase.phase3PsychologicalAwareness:
          return 'Phase 3 : Conscience psycho';
        case JourneyPhase.phase4CopingAndDevelopment:
          return 'Phase 4 : Stratégies d’adaptation';
        case JourneyPhase.phase5PersonalGrowthAndMaintenance:
          return 'Phase 5 : Croissance durable';
      }
    } else {
      return 'Phase ${phase.phaseNumber} — ${phase.defaultTitle()}';
    }
  }

  String phasePurpose(JourneyPhase phase) {
    if (isArabic) {
      switch (phase) {
        case JourneyPhase.phase1SelfDiscovery:
          return 'فهم عالمك الداخلي، والأفكار المتكررة، والتمييز الواضح بين الفكرة والشعور والتصرف.';
        case JourneyPhase.phase2UnderstandingPatterns:
          return 'إدراك الروابط بين المحفزات، والأنماط الفكرية التلقائية، والاستجابات السلوكية كالتجنب.';
        case JourneyPhase.phase3PsychologicalAwareness:
          return 'تعميق الوعي بالتجارب الخاصة، والتنظيم الانفعالي، والتشوهات المعرفية دون إصدار أحكام ذاتية.';
        case JourneyPhase.phase4CopingAndDevelopment:
          return 'تطبيق تمارين نفسية واستراتيجيات تكيف مثبتة، مثل تقنيات التأريض، وسجلات الأفكار، والروتين الصحي.';
        case JourneyPhase.phase5PersonalGrowthAndMaintenance:
          return 'ترسيخ ما اكتشفته، والتعامل برحمة ووعي مع الانتكاسات، وبناء عادات مستدامة طويلة المدى.';
      }
    } else if (isFrench) {
      switch (phase) {
        case JourneyPhase.phase1SelfDiscovery:
          return 'Comprendre votre monde intérieur et distinguer pensées, émotions et comportements.';
        case JourneyPhase.phase2UnderstandingPatterns:
          return 'Repérer les liens entre déclencheurs, pensées automatiques et stratégies d’évitement.';
        case JourneyPhase.phase3PsychologicalAwareness:
          return 'Approfondir la compréhension de vos vécus et distorsions sans jugement de soi.';
        case JourneyPhase.phase4CopingAndDevelopment:
          return 'Intégrer des exercices ancrés : ancrage 5-4-3-2-1, restructuration cognitive et routines.';
        case JourneyPhase.phase5PersonalGrowthAndMaintenance:
          return 'Consolider vos acquis, traverser les rechutes avec bienveillance et pérenniser vos habitudes.';
      }
    } else {
      return phase.defaultPurpose();
    }
  }

  // ===========================================================================
  // AI COMPANION (SESSION 05)
  // ===========================================================================
  String get aiCompanionTitle =>
      isArabic ? 'المرافق الذكي' : (isFrench ? 'Compagnon IA' : 'AI Companion');
  String get aiCompanionIntro => isArabic
      ? 'مساحة ذكية لاستكشاف ما يجري في داخلك.'
      : (isFrench
            ? 'Un espace intelligent pour explorer ce qui se passe en vous.'
            : 'An intelligent space to explore what is happening within you.');
  String get aiCompanionSupporting => isArabic
      ? 'تحدث بحرية، استكشف أفكارك، وافهم مشاعرك، واكتشف الروابط المحتملة في تجاربك.'
      : (isFrench
            ? 'Parlez librement, explorez vos pensées, comprenez vos émotions et découvrez les liens possibles dans vos expériences.'
            : 'Talk freely, explore your thoughts, understand your emotions, and discover possible connections in your experiences.');
  String get selectConversationMode => isArabic
      ? 'اختر نمط المحادثة'
      : (isFrench ? 'Mode de conversation' : 'Select Conversation Mode');
  String get newConversationBtn => isArabic
      ? 'محادثة جديدة'
      : (isFrench ? 'Nouvelle conversation' : 'New Conversation');
  String get resumeConversationBtn =>
      isArabic ? 'متابعة' : (isFrench ? 'Reprendre' : 'Resume');
  String get recentConversationsTitle => isArabic
      ? 'المحادثات السابقة'
      : (isFrench ? 'Échanges récents' : 'Recent talks');
  String get noRecentConversations => isArabic
      ? 'ما فمّاش محادثات محفوظة بعد — تنجم تبدأ وقت ما تحب.'
      : (isFrench
            ? 'Aucun échange enregistré pour le moment.'
            : 'No saved talks yet — begin whenever you feel ready.');
  String get suggestedStartersTitle => isArabic
      ? 'مقترحات للمحادثة'
      : (isFrench ? 'Idées de départ' : 'Suggested Starters');
  String get renameConversationTitle => isArabic
      ? 'إعادة تسمية المحادثة'
      : (isFrench ? 'Renommer la conversation' : 'Rename Conversation');
  String get deleteConversationTitle => isArabic
      ? 'حذف المحادثة'
      : (isFrench ? 'Supprimer la conversation' : 'Delete Conversation');
  String get deleteConversationConfirm => isArabic
      ? 'هل أنت متأكد من حذف هذه المحادثة؟ لا يمكن التراجع عن هذا الإجراء.'
      : (isFrench
            ? 'Êtes-vous sûr de vouloir supprimer cette conversation ? Cette action est irréversible.'
            : 'Are you sure you want to delete this conversation? This action cannot be undone.');
  String get clearAllConversationsBtn => isArabic
      ? 'مسح سجل المحادثات'
      : (isFrench ? 'Effacer tout l’historique' : 'Clear All History');
  String get clearAllConversationsConfirm => isArabic
      ? 'هل أنت متأكد من حذف جميع سجلات المحادثات نهائياً من هذا الجهاز؟'
      : (isFrench
            ? 'Supprimer définitivement tout l’historique des conversations ?'
            : 'Permanently delete all conversation records from this device?');
  String get offlineNoticeTitle => isArabic
      ? 'الوضع دون اتصال'
      : (isFrench ? 'Mode hors ligne' : 'Offline Mode');
  String get offlineNoticeBody => isArabic
      ? 'الردود الحية تتطلب اتصالاً بالإنترنت. محادثاتك وملاحظاتك محفوظة محلياً بأمان.'
      : (isFrench
            ? 'Les réponses en direct nécessitent une connexion Internet. Vos échanges restent enregistrés localement.'
            : 'Live AI responses require an active internet connection. Your conversations remain securely saved locally.');
  String get switchMode =>
      isArabic ? 'تغيير النمط' : (isFrench ? 'Changer de mode' : 'Switch Mode');
  String get inputPlaceholder => isArabic
      ? 'اكتب ما يدور في خاطرك...'
      : (isFrench
            ? 'Écrivez ce qui vous traverse l’esprit...'
            : 'What has been happening in your mind?');
  String get typingIndicator => isArabic
      ? 'المرافق يستمع ويتأمل...'
      : (isFrench
            ? 'Le compagnon réfléchit...'
            : 'AI Companion is reflecting...');
  String get backToAllConversations => isArabic
      ? 'جميع المحادثات'
      : (isFrench ? 'Toutes les conversations' : 'All Conversations');

  // ===========================================================================
  // MY PROGRESS (BUILD SESSION 06)
  // ===========================================================================
  String get progressTitle => isArabic
      ? 'مساري وتقدّمي'
      : (isFrench ? 'MON CHEMINEMENT' : 'MY PROGRESS');
  String get progressQuote => isArabic
      ? 'كل تدوينة تروي قصة. استكشف اللحظات والمشاعر والاستبصارات التي تشكّل مسارك.'
      : (isFrench
            ? 'Chaque entrée raconte une histoire. Explorez les moments, émotions et découvertes qui composent votre cheminement.'
            : 'Every entry tells a story. Explore the moments, emotions, and discoveries that make up your journey.');
  String get progressTabThoughtTrace => isArabic
      ? 'أثر الأفكار والنظرة العامة'
      : (isFrench
            ? 'EMPREINTE DES PENSÉES & APERÇU'
            : 'THOUGHT TRACE & OVERVIEW');
  String get progressTabConstellation => progressTabThoughtTrace;
  String get progressTabCalendar => isArabic
      ? 'التقويم والسجلات'
      : (isFrench ? 'CALENDRIER & ENTRÉES' : 'CALENDAR & ENTRIES');
  String get progressTabReflections => isArabic
      ? 'أرشيف التأملات'
      : (isFrench ? 'ARCHIVES DE RÉFLEXIONS' : 'REFLECTIONS ARCHIVE');
  String get progressTabMilestones => isArabic
      ? 'المحطات والمسار'
      : (isFrench ? 'JALONS & PARCOURS' : 'MILESTONES & JOURNEY');

  String get thoughtTraceWaitingTitle => isArabic
      ? 'سجل أثر الأفكار بانتظارك'
      : (isFrench
            ? 'L’EMPREINTE DES PENSÉES VOUS ATTEND'
            : 'THE THOUGHT TRACE IS WAITING');
  String get skyWaitingTitle => thoughtTraceWaitingTitle;
  String get thoughtTraceWaitingSub => isArabic
      ? 'كل فكرة تترك أثراً. سجّل تقرير اليوم لبدء سجلك الزمني والتأملي.'
      : (isFrench
            ? 'Chaque pensée laisse une trace. Enregistrez votre bilan aujourd’hui pour ouvrir votre chronologie réflexive.'
            : 'Every thought leaves a trace. Record today’s check-in to begin your reflective timeline archive.');
  String get skyWaitingSub => thoughtTraceWaitingSub;
  String get recordTodayTraceBtn => isArabic
      ? 'تسجيل أثر اليوم'
      : (isFrench
            ? 'Enregistrer l’empreinte du jour'
            : 'Record Today\'s Trace');
  String get tapTraceToInspect => isArabic
      ? 'المس أي تدوينة لمعاينة أثر الفكرة واستكشافها.'
      : (isFrench
            ? 'Touchez une entrée pour examiner la pensée.'
            : 'Tap any entry to explore the thought.');
  String get tapStarToInspect => tapTraceToInspect;
  String get selectedTraceLabel => isArabic
      ? 'أثر الفكرة المحدد'
      : (isFrench ? 'Empreinte sélectionnée' : 'Selected Thought Trace');
  String get selectedStarLabel => selectedTraceLabel;
  String get viewFullTraceBtn => isArabic
      ? 'عرض تفاصيل الأثر'
      : (isFrench ? 'Voir la trace complète' : 'View Full Trace');
  String get investigateThoughtBtn => isArabic
      ? 'استكشاف هذه الفكرة'
      : (isFrench ? 'Explorer cette pensée' : 'Explore This Thought');

  String get totalEntriesMetric => isArabic
      ? 'إجمالي التدوينات'
      : (isFrench ? 'Total entrées' : 'Total entries');
  String get uniqueDaysMetric => isArabic
      ? 'الأيام الملاحظة'
      : (isFrench ? 'Jours observés' : 'Days observed');
  String get emotionSelectionsMetric => isArabic
      ? 'المشاعر المحددة'
      : (isFrench ? 'Émotions citées' : 'Emotion tags');
  String get emotionalSpectrumTitle => isArabic
      ? 'توزيع المشاعر المعاشة'
      : (isFrench ? 'Spectre émotionnel' : 'Reported emotional spectrum');
  String get emotionalVarietyTitle => isArabic
      ? 'المشاعر اللّي سمّيتها'
      : (isFrench
            ? 'Émotions nommées'
            : 'Feelings you named');
  String distinctEmotionsCount(int count) => isArabic
      ? '$count مشاعر مختلفة تم تمييزها'
      : (isFrench
            ? '$count émotions distinctes nommées'
            : '$count distinct emotions recognized');
  String get intensityTimelineTitle => isArabic
      ? 'منحنى شدة المشاعر'
      : (isFrench ? 'INTENSITÉ DANS LE TEMPS' : 'MOOD INTENSITY TIMELINE');
  String get avgIntensityLabel => isArabic
      ? 'متوسط الشدة'
      : (isFrench ? 'Intensité moyenne' : 'Average Intensity');
  String intensityMinMax(int min, int max) => isArabic
      ? 'المدى: $min - $max / 10'
      : (isFrench ? 'Plage : $min - $max / 10' : 'Range: $min - $max / 10');

  String get energyAndSleepTitle => isArabic
      ? 'النوم والطاقة'
      : (isFrench
            ? 'Sommeil et énergie'
            : 'Sleep & energy');
  String get avgEnergyMetric =>
      isArabic ? 'متوسط الطاقة' : (isFrench ? 'ÉNERGIE MOY.' : 'AVG ENERGY');
  String get avgSleepMetric =>
      isArabic ? 'متوسط النوم' : (isFrench ? 'SOMMEIL MOY.' : 'AVG SLEEP');
  String get avgQualityMetric =>
      isArabic ? 'جودة النوم' : (isFrench ? 'QUALITÉ MOY.' : 'AVG QUALITY');
  String get empiricalDisclaimer => isArabic
      ? '* ملاحظات إحصائية مستندة إلى بياناتك المسجلة فقط، ولا تعني وجود علاقة سببية طبية حتمية.'
      : (isFrench
            ? '* Observations issues exclusivement de vos bilans enregistrés. N’implique aucune causalité médicale.'
            : '* Data observations from your self-reported logs only. Does not imply medical or psychological causality.');

  String get calendarNoBreaksNote => isArabic
      ? 'كل نقطة ملونة هي نهار سجّلت فيه — بلاش عدّاد يضغط عليك.'
      : (isFrench
            ? 'Chaque point coloré compte — aucune série à perdre.'
            : 'Every colored dot is a day you checked in — no streaks to lose.');
  String get deleteEntryBtn =>
      isArabic ? 'حذف' : (isFrench ? 'Supprimer' : 'Delete');
  String get editEntryBtn =>
      isArabic ? 'تعديل' : (isFrench ? 'Modifier' : 'Edit');
  String get deleteTraceConfirmTitle => isArabic
      ? 'حذف الأثر المسجل؟'
      : (isFrench ? 'Supprimer cette trace ?' : 'Delete Trace Entry?');
  String get deleteTraceConfirmBody => isArabic
      ? 'هل أنت متأكد من رغبتك في حذف هذا الأثر نهائياً من سجلاتك المحلية؟'
      : (isFrench
            ? 'Êtes-vous sûr de vouloir supprimer définitivement cette entrée ?'
            : 'Are you sure you want to permanently delete this daily trace entry?');

  String get searchReflectionsHint => isArabic
      ? 'ابحث في أفكارك وتأملاتك...'
      : (isFrench
            ? 'Rechercher dans vos réflexions...'
            : 'Search your thoughts and reflections...');
  String get filterAllSources => isArabic
      ? 'كافة المصادر'
      : (isFrench ? 'Toutes les sources' : 'All Sources');
  String get noReflectionsFound => isArabic
      ? 'لم يتم العثور على أي تأملات مطابقة للبحث.'
      : (isFrench
            ? 'Aucune réflexion ne correspond à votre recherche.'
            : 'No reflections found matching your query.');
  String get noReflectionsEmpty => isArabic
      ? 'أرشيفك بانتظار تدويناتك. اكتب خواطرك أثناء التقييم اليومي أو جلسات التأمل الفكري أو تمارين المسار.'
      : (isFrench
            ? 'Vos réflexions apparaîtront ici dès vos premiers bilans ou exercices.'
            : 'Your reflection archive is waiting. Write thoughts during daily check-ins, reflection sessions, or journey activities.');

  String get journeyProgressTitle => isArabic
      ? 'استكشاف مراحل المسار النفسي'
      : (isFrench
            ? 'EXPLORATION DU PARCOURS'
            : 'JOURNEY CURRICULUM EXPLORATION');
  String activitiesExplored(int completed, int total) => isArabic
      ? '$completed من $total أنشطة تم استكشافها'
      : (isFrench
            ? '$completed / $total activités explorées'
            : '$completed / $total Activities Explored');
  String get milestonesTitle => isArabic
      ? 'المحطات الكونية المستنيرة'
      : (isFrench ? 'JALONS CÉLESTES' : 'CELESTIAL MILESTONES');
  String get milestonesSub => isArabic
      ? 'محطات تحتفي بتراكم الاستبصار والفضول الذاتي دون ضغط أو سلاسل ملزمة.'
      : (isFrench
            ? 'Ces repères célèbrent votre exploration intérieure, sans pression de performance.'
            : 'Milestones honor cumulative self-discovery with zero streak pressure or judgment.');
  String get patternsWorthExploringTitle => isArabic
      ? 'أنماط جديرة بالاستكشاف'
      : (isFrench ? 'SCHÉMAS À EXPLORER' : 'PATTERNS WORTH EXPLORING');
  String get patternsSub => isArabic
      ? 'ملاحظات محلية مستخلصة من بياناتك لمساعدتك في التأمل والاستبصار دون أحكام.'
      : (isFrench
            ? 'Observations locales formulées à partir de vos saisies pour nourrir votre réflexion.'
            : 'Local observations formulated from your entries to assist self-reflection.');
  String get dismissInsight =>
      isArabic ? 'تجاهل' : (isFrench ? 'Masquer' : 'Dismiss');
  String get reopenTraceAction =>
      isArabic ? 'فتح الأثر' : (isFrench ? 'Ouvrir' : 'Open Entry');

  // Unified Soft UI & Decluttered Navigation Strings (EN / FR / AR Tunisian)
  String get mindAssistantTitle => isArabic
      ? 'المساعد الذهني'
      : (isFrench ? 'Assistant Mental' : 'Mind Assistant');
  String get mindAssistantSub => isArabic
      ? 'احكي على اللي في بالك أو اسأل بهدوء وبدون ضغط.'
      : (isFrench
            ? 'Parlez de ce que vous avez en tête ou explorez une question.'
            : 'Talk through what is on your mind, or ask anything.');
  String get quickGroundingTitle => isArabic
      ? 'استراحة تنفّس سريعة'
      : (isFrench ? 'Pause d’ancrage' : 'Quick Grounding');
  String get nextStepSettlePrompt => isArabic
      ? 'تحبّ تاخذ 60 ثانية تنفّس باش تهدى شوية؟'
      : (isFrench
            ? 'Voulez-vous prendre 60 secondes pour vous apaiser ?'
            : 'Would 60 seconds of breathing help settle things?');
  String get nextStepThoughtPrompt => isArabic
      ? 'تحبّ نفرقو بين الحقيقة والافتراض في اللي صار؟'
      : (isFrench
            ? 'Séparer les faits des hypothèses ?'
            : 'Separate facts from what your mind assumed?');
  String get nextStepAnchorPrompt => isArabic
      ? 'لحظة هادئة — تحبّ تحفظ مرساة لليوم؟'
      : (isFrench
            ? 'Un moment calme — enregistrer un repère ?'
            : 'A calm moment — want to save one anchor for today?');

  String get trackPageTitle =>
      isArabic ? 'تتبّع وملاحظة' : (isFrench ? 'Suivi & Observation' : 'Track');
  String get checkInTodayTab => isArabic
      ? 'تسجيل اليوم'
      : (isFrench ? 'Bilan du jour' : 'Check-In Today');
  String get historyAndCalendarTab => isArabic
      ? 'السجل والتقويم'
      : (isFrench ? 'Historique & Calendrier' : 'History & Calendar');
  String get fullCalendarTooltip => isArabic
      ? 'التقويم الكامل والتحليلات'
      : (isFrench
            ? 'Calendrier complet & Analyses'
            : 'Full Calendar & Analytics');
  String get fullTraceTab =>
      isArabic ? 'رصد معمّق' : (isFrench ? 'Trace complète' : 'Full Trace');
  String get howFeelingRightNow => isArabic
      ? 'كيفاش حاسس روحك توّا؟'
      : (isFrench
            ? 'Comment vous sentez-vous en ce moment ?'
            : 'How are you feeling right now?');
  String get todaysCoreState => isArabic
      ? 'الحالة الأساسية لليوم'
      : (isFrench ? 'ÉTAT PRINCIPAL DU JOUR' : "TODAY'S CORE STATE");
  String get intenseAnchorLabel =>
      isArabic ? 'شديد' : (isFrench ? 'Intense' : 'Intense');
  String get addNoteOptionalHint => isArabic
      ? 'زيد ملاحظة صغيرة (اختياري)...'
      : (isFrench
            ? 'Ajouter une note (optionnel)...'
            : 'Add a note (optional)...');
  String get addContextOptionalTitle => isArabic
      ? 'إضافة تفاصيل اختيارية'
      : (isFrench
            ? 'Ajouter du contexte (optionnel)'
            : 'Add context (optional)');
  String get addContextOptionalSub => isArabic
      ? 'المحفزات، النوم، والطاقة'
      : (isFrench
            ? 'Déclencheurs, sommeil et énergie'
            : 'Triggers, sleep, and energy');
  String get whatHelpedTodayLabel => isArabic
      ? 'شنوّة اللي ساعدك اليوم؟ (اختياري)'
      : (isFrench
            ? 'Qu’est-ce qui vous a aidé ? (optionnel)'
            : 'What helped today? (optional)');
  String get whatsInfluencingMood => isArabic
      ? 'شنوّة اللي مأثّر على مزاجك؟'
      : (isFrench
            ? 'Qu’est-ce qui influence votre humeur ?'
            : "What's influencing your mood?");
  String get triggersContextHeader => isArabic
      ? 'المحفّزات والسياق'
      : (isFrench ? 'DÉCLENCHEURS & CONTEXTE' : 'TRIGGERS & CONTEXT');
  String get saveCheckInAction => isArabic
      ? 'حفظ التسجيل'
      : (isFrench ? 'Enregistrer le bilan' : 'Save Check-In');
  String get updateTodaysEntryAction => isArabic
      ? 'تحديث تسجيل اليوم'
      : (isFrench ? 'Mettre à jour aujourd’hui' : "Update Today's Entry");
  String get preferStepByStepLabel => isArabic
      ? 'تحبّ تسجيل مفصّل خطوة بخطوة؟'
      : (isFrench
            ? 'Préférez-vous un bilan étape par étape ?'
            : 'Prefer step-by-step check-in?');
  String get saveEntryBtn => saveCheckInAction;
  String get deepenReflectionCta => preferStepByStepLabel;
  String get calendarTitle => isArabic
      ? 'تقويم الملاحظات'
      : (isFrench ? 'Calendrier d’observation' : 'Observation Calendar');
  String get timelineBuildsTitle => isArabic
      ? 'سجلك الزمني يتبنى مع كل ملاحظة تسجلها'
      : (isFrench
            ? 'Votre historique se construit au fil des bilans'
            : 'Your timeline builds as you log');
  String get logTodayBtn =>
      isArabic ? 'سجّل اليوم' : (isFrench ? 'Noter aujourd’hui' : 'Log Today');
  String get showAllEntriesBtn =>
      isArabic ? 'عرض الكل' : (isFrench ? 'Tout voir' : 'Show all');
  String filteredByDateLabel(String dateKey) => formatHumanDateKey(dateKey);
  String get noEntriesForDayNote => isArabic
      ? 'ما فماش تسجيل في النهار هذا.'
      : (isFrench
            ? 'Aucun bilan enregistré ce jour-là.'
            : 'No check-in logged on this day.');
  String get exploreWithAiGuideBtn => isArabic
      ? 'مواصلة في استشارة المتابعة'
      : (isFrench
            ? 'Approfondir en suivi clinique'
            : 'Discuss in Care Consult');
  String get editEntryTitle => isArabic
      ? 'تعديل التسجيل'
      : (isFrench ? 'Modifier le bilan' : 'Edit Check-In Entry');
  String get saveChangesBtn =>
      isArabic ? 'حفظ التعديلات' : (isFrench ? 'Enregistrer' : 'Save Changes');
  String get cancelActionLabel =>
      isArabic ? 'إلغاء' : (isFrench ? 'Annuler' : 'Cancel');
  String get calmScaleAnchor =>
      isArabic ? 'هادي 1' : (isFrench ? 'Calme 1' : 'Calm 1');
  String get overwhelmedScaleAnchor =>
      isArabic ? 'مضغوط 10' : (isFrench ? 'Débordé 10' : 'Overwhelmed 10');
  String get whatsOnYourMindHint => isArabic
      ? 'شنوّة اللي في بالك توّا؟ (اختياري)'
      : (isFrench
            ? 'Qu’avez-vous en tête ? (optionnel)'
            : 'What is on your mind? (optional)');
  String get pickHowYouFeelFirst => isArabic
      ? 'اختار شعورك قبل الحفظ.'
      : (isFrench
            ? 'Choisissez d’abord votre ressenti.'
            : 'Pick how you feel first.');
  String get savedBadgeLabel =>
      isArabic ? 'تم الحفظ' : (isFrench ? 'Enregistré' : 'Saved');
  String get timelineOverline =>
      isArabic ? 'السجل الزمني' : (isFrench ? 'CHRONOLOGIE' : 'TIMELINE');
  String get exploreMoodContextPrefix => isArabic
      ? 'استكشاف حالة مزاجية مسجّلة:'
      : (isFrench ? 'Explorer ce bilan d’humeur :' : 'Explore mood check-in:');

  String trackTriggerDisplay(String key) {
    switch (key) {
      case 'Work / Demands':
        return isArabic
            ? 'ضغط العمل'
            : (isFrench ? 'Travail / Charge' : 'Work / Demands');
      case 'Sleep Disruption':
        return isArabic
            ? 'اضطراب النوم'
            : (isFrench ? 'Sommeil perturbé' : 'Sleep Disruption');
      case 'Studies':
        return isArabic ? 'الدراسة' : (isFrench ? 'Études' : 'Studies');
      case 'Social':
        return isArabic ? 'علاقات اجتماعية' : (isFrench ? 'Social' : 'Social');
      case 'Health':
        return isArabic ? 'الصحة' : (isFrench ? 'Santé' : 'Health');
      case 'Overload':
        return isArabic ? 'إرهاق ذهني' : (isFrench ? 'Surcharge' : 'Overload');
      default:
        return key;
    }
  }

  String trackHelpedDisplay(String key) {
    switch (key) {
      case 'Walk':
        return isArabic ? 'مشي هادئ' : (isFrench ? 'Marche' : 'Walk');
      case 'Quiet time':
        return isArabic
            ? 'وقت هادئ'
            : (isFrench ? 'Moment calme' : 'Quiet time');
      case 'Breathing':
        return isArabic ? 'تنفّس' : (isFrench ? 'Respiration' : 'Breathing');
      case 'Talked':
        return isArabic ? 'فضفضة مع قريب' : (isFrench ? 'Échange' : 'Talked');
      case 'Rest':
        return isArabic ? 'راحة' : (isFrench ? 'Repos' : 'Rest');
      default:
        return key;
    }
  }

  List<String> get weekdayShortLabels {
    if (isArabic) return const ['ن', 'ث', 'ر', 'خ', 'ج', 'س', 'ح'];
    if (isFrench) return const ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    return const ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  }

  String monthName(int month) {
    const en = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    const fr = [
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre',
    ];
    const ar = [
      'جانفي',
      'فيفري',
      'مارس',
      'أفريل',
      'ماي',
      'جوان',
      'جويلية',
      'أوت',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    final idx = (month - 1).clamp(0, 11);
    if (isArabic) return ar[idx];
    if (isFrench) return fr[idx];
    return en[idx];
  }

  String shortMonthName(int month) {
    const en = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    const fr = [
      'JAN',
      'FÉV',
      'MAR',
      'AVR',
      'MAI',
      'JUIN',
      'JUIL',
      'AOÛ',
      'SEP',
      'OCT',
      'NOV',
      'DÉC',
    ];
    const ar = [
      'جانفي',
      'فيفري',
      'مارس',
      'أفريل',
      'ماي',
      'جوان',
      'جويلية',
      'أوت',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    final idx = (month - 1).clamp(0, 11);
    if (isArabic) return ar[idx];
    if (isFrench) return fr[idx];
    return en[idx];
  }

  String weekdayName(int weekday) {
    const en = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const fr = [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche',
    ];
    const ar = [
      'الإثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ];
    final idx = (weekday - 1).clamp(0, 6);
    if (isArabic) return ar[idx];
    if (isFrench) return fr[idx];
    return en[idx];
  }

  String weekdayInitial(int weekday) {
    const en = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    const fr = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    const ar = ['ن', 'ث', 'ر', 'خ', 'ج', 'س', 'ح'];
    final idx = (weekday - 1).clamp(0, 6);
    if (isArabic) return ar[idx];
    if (isFrench) return fr[idx];
    return en[idx];
  }

  String formattedDateOverline(DateTime dt) {
    final dayLabel = weekdayName(dt.weekday);
    final mLabel = monthName(dt.month);
    return '$dayLabel ${dt.day} $mLabel';
  }

  String get observatoryHeroSubtitle => isArabic
      ? 'نظرة هادئة وأعمق على أفكارك'
      : (isFrench
            ? 'Un regard calme et lucide sur votre esprit'
            : 'A deeper, calmer look into your mind');
  String get thoughtPatternsLabel => isArabic
      ? 'أنماط الأفكار'
      : (isFrench ? 'Schémas de pensée' : 'Thought Patterns');
  String get thoughtPatternsSub => isArabic
      ? 'فهم الأفكار المتكررة'
      : (isFrench
            ? 'Explorer les pensées récurrentes'
            : 'Explore recurring thoughts');
  String get emotionalLandscapeLabel => isArabic
      ? 'الخريطة الشعورية'
      : (isFrench ? 'Paysage émotionnel' : 'Emotional Landscape');
  String get emotionalLandscapeSub => isArabic
      ? 'تسمية وفهم المشاعر'
      : (isFrench ? 'Comprendre vos émotions' : 'Understand your emotions');
  String get behaviorInsightsLabel => isArabic
      ? 'محفّزات السلوك'
      : (isFrench ? 'Élan comportemental' : 'Behavioral Steps');
  String get behaviorInsightsSub => isArabic
      ? 'خطوات صغيرة بلا ضغط'
      : (isFrench ? 'Petits pas sans pression' : 'Low-pressure next actions');
  String get savedReframesTitle => isArabic
      ? 'زوايا نظر محفوظة'
      : (isFrench ? 'Repères conservés' : 'Saved Reframes');
  String get savedReframesEmpty => isArabic
      ? 'احفظ أي إعادة صياغة مريحة أثناء الحوار باش ترجعلها وقت الحاجة.'
      : (isFrench
            ? 'Enregistrez une reformulation utile pendant un échange pour la retrouver ici.'
            : 'Save a grounded takeaway from any dialogue to revisit during tough moments.');
  String get saveTakeawayAction =>
      isArabic ? 'حفظ الفكرة' : (isFrench ? 'Sauvegarder' : 'Save Takeaway');

  String get moodTrendsHeader => isArabic
      ? 'توجّهات المزاج'
      : (isFrench ? 'Tendances de l’humeur' : 'Mood Trends');
  String get yourPatternsHeader => isArabic
      ? 'أنماطك الملاحظة'
      : (isFrench ? 'Vos schémas' : 'Your Patterns');
  String get viewAllArrowLabel =>
      isArabic ? 'عرض الكل' : (isFrench ? 'Tout voir' : 'View all');
  String get patternsAndTrendsTab => isArabic
      ? 'الأنماط والمنحنيات'
      : (isFrench ? 'Schémas & Tendances' : 'Patterns & Trends');
  String get reflectionsAndMilestonesTab => isArabic
      ? 'التأملات والمحطات'
      : (isFrench ? 'Réflexions & Jalons' : 'Reflections & Milestones');
  String get triggerMoodCorrelationsTitle => isArabic
      ? 'روابط السياق والمزاج'
      : (isFrench ? 'Liens contexte & humeur' : 'Context & Mood Links');
  String get triggerMoodCorrelationsSub => isArabic
      ? 'مقارنة محلية بسيطة بين العوامل اللي سجلتها ومتوسط راحتك بدون أحكام.'
      : (isFrench
            ? 'Observations locales basées uniquement sur vos étiquettes enregistrées.'
            : 'Local comparisons from your own tagged logs, framed without judgment.');
  String get typicalSleepLabel => isArabic
      ? 'متوسط النوم'
      : (isFrench ? 'SOMMEIL TYPIQUE' : 'TYPICAL SLEEP');
  String get typicalEnergyLabel => isArabic
      ? 'متوسط الطاقة'
      : (isFrench ? 'ÉNERGIE TYPIQUE' : 'TYPICAL ENERGY');
  String get moodIntensityShortLabel =>
      isArabic ? 'شدة المزاج' : (isFrench ? 'INTENSITÉ' : 'INTENSITY');
  String get frequentEmotionsLabel => isArabic
      ? 'المشاعر المتكررة'
      : (isFrench ? 'ÉMOTIONS FRÉQUENTES' : 'FREQUENT EMOTIONS');
  String get suggestedTherapyLabel => isArabic
      ? 'مواضيع مقترحة للنقاش المهني'
      : (isFrench
            ? 'PISTES POUR VOTRE SPÉCIALISTE'
            : 'TOPICS FOR SPECIALIST DISCUSSION');

  String get memberRoleLabel => isArabic
      ? 'عضو مسار الوعي الذاتي'
      : (isFrench ? 'Membre Mindora' : 'Mindora Member');
  String get myAccountTitle => isArabic
      ? 'ملفي النفسي وحسابي'
      : (isFrench ? 'Mon Profil & Compte' : 'My Account & Context');
  String get myAccountSub => isArabic
      ? 'خلفية حياتك، أهدافك وتفضيلات المتابعة'
      : (isFrench
            ? 'Votre parcours, objectifs et préférences'
            : 'Your background, goals & doctor preferences');
  String get mindAssistantEngineTitle => isArabic
      ? 'محرّك المساعد الذهني'
      : (isFrench ? 'Moteur d’Assistant Mental' : 'Mind Assistant Engine');
  String get mindAssistantEngineSub => isArabic
      ? 'وضع الاختبار المحلي أو الاتصال السحابي'
      : (isFrench
            ? 'Mode test local et diagnostics Gemini'
            : 'Gemini live AI & safe test mode status');
  String get sharePacketTitle => isArabic
      ? 'مشاركة ملخص مع طبيبي'
      : (isFrench
            ? 'Partager un résumé au médecin'
            : 'Share summary with my doctor');
  String get sharePacketSub => isArabic
      ? 'اختر البيانات التي تشاركها بإرادتك'
      : (isFrench
            ? 'Choisissez exactement quoi inclure'
            : 'Choose what to include before exporting');

  // Accessibility tooltips (EN / FR / AR)
  String get clearSearchTooltip => isArabic
      ? 'مسح البحث'
      : (isFrench ? 'Effacer la recherche' : 'Clear search');
  String get previousMonthTooltip => isArabic
      ? 'الشهر السابق'
      : (isFrench ? 'Mois précédent' : 'Previous month');
  String get nextMonthTooltip =>
      isArabic ? 'الشهر التالي' : (isFrench ? 'Mois suivant' : 'Next month');
  String get toggleVisibilityTooltip => isArabic
      ? 'إظهار أو إخفاء'
      : (isFrench ? 'Afficher ou masquer' : 'Toggle visibility');
  String get addItemTooltip =>
      isArabic ? 'إضافة' : (isFrench ? 'Ajouter' : 'Add');
  String get viewDetailsTooltip => isArabic
      ? 'عرض التفاصيل'
      : (isFrench ? 'Voir les détails' : 'View details');

  // Step 7 — AI Guide Header Clarity, Mode Chooser & Welcome Starters
  String get engineBadgeOffline =>
      isArabic ? 'محلي' : (isFrench ? 'Local' : 'Local');
  String get engineBadgeGroq => 'Groq';
  String get engineBadgeGemini => 'Gemini';
  String get aiEngineTooltip => isArabic
      ? 'إعدادات محرّك الاستشارة'
      : (isFrench
            ? 'Réglages du moteur clinique'
            : 'Consultation engine settings');
  String get modesAndHistoryTooltip => isArabic
      ? 'الأساليب والجلسات السابقة'
      : (isFrench ? 'Modes & historique' : 'Modes & History');
  String get changeModeTooltip => isArabic
      ? 'تغيير الأسلوب'
      : (isFrench ? 'Changer de mode' : 'Switch mode');
  String get chooseModeSheetTitle => isArabic
      ? 'اختار أسلوب الحديث'
      : (isFrench
            ? 'Choisir un style d’échange'
            : 'Choose a conversation style');
  String get chooseModeSheetSub => isArabic
      ? 'تنجم تبدّل الأسلوب في أي وقت وحوارك يقعد محفوظ.'
      : (isFrench
            ? 'Changez de style à tout moment sans perdre votre fil.'
            : 'Switch anytime — your current conversation stays intact.');
  String get welcomeQuestionHeadline => isArabic
      ? 'شنوة اللي شاغل بالك توّا؟'
      : (isFrench ? 'Qu’avez-vous en tête ?' : "What's on your mind?");
  String get welcomePickOrTypeSub => isArabic
      ? 'اختار نقطة بداية من الأسفل أو اكتب سطر كي تحس روحك حاضر.'
      : (isFrench
            ? 'Choisissez un point de départ ou écrivez une ligne quand vous voulez.'
            : 'Pick a starting point below or type a line whenever you feel ready.');
  String get privacyLocalTag => isArabic
      ? 'محلي على جهازك'
      : (isFrench ? 'Local sur l’appareil' : 'Local On-Device');
  String get privacyCloudConsentedTag => isArabic
      ? 'سحابي مشفّر بموافقتك'
      : (isFrench ? 'Cloud chiffré autorisé' : 'Encrypted Cloud Consented');
  String get privacyPrivateSessionTag => isArabic
      ? 'جلسة خاصة (محلية فقط)'
      : (isFrench ? 'Session privée (Locale)' : 'Private Session (Local Only)');
  String get saveTakeawayReportBtn => isArabic
      ? 'حفظ تقرير الجلسة'
      : (isFrench ? 'Créer le bilan' : 'Save Takeaway Report');
  String get openSelfCareToolsShort => isArabic
      ? 'أدوات التهدئة'
      : (isFrench ? 'Outils bien-être' : 'Self-Care Tools');
  String get userSpeakerYou => isArabic ? 'أنت' : (isFrench ? 'Vous' : 'You');
  String get tagFactGuessStoryHint => isArabic
      ? '+ تصنيف (حقيقة / تخمين / تأويل)'
      : (isFrench ? '+ Fait / Hypothèse / Récit' : '+ Fact / Guess / Story');
  String get labelFactHuman =>
      isArabic ? 'حقيقة' : (isFrench ? 'Fait' : 'Fact');
  String get labelGuessHuman =>
      isArabic ? 'تخمين' : (isFrench ? 'Hypothèse' : 'Guess');
  String get labelStoryHuman =>
      isArabic ? 'تأويل' : (isFrench ? 'Récit' : 'Story');
  String get suggestedReplyFactsVsGuesses => isArabic
      ? 'نفرّق بين الحقيقة والتخمين'
      : (isFrench
            ? 'Distinguer faits et hypothèses'
            : 'Separate facts vs guesses');
  String get suggestedReplyGroundingFirst => isArabic
      ? 'نحتاج تثبيت وتنفّس قبل'
      : (isFrench ? 'Besoin d’ancrage d’abord' : 'I need grounding first');
  String get suggestedReplySaveTakeaway => isArabic
      ? 'نحفظ الخلاصة المهمة'
      : (isFrench ? 'Sauvegarder l’essentiel' : 'Save key takeaway');

  List<String> localizedStartersForMode(String modeName) {
    switch (modeName) {
      case 'understandEmotion':
        return isArabic
            ? const [
                'حاسس بثقل وضغط في صدري اليوم.',
                'نحب نفهم علاش حاسس بالطريقة هذي.',
                'مزاجي تبدّل فجأة وحاسس بعدم ارتياح.',
              ]
            : (isFrench
                  ? const [
                      'Je sens une lourdeur dans ma poitrine.',
                      'Je veux comprendre ce que je ressens.',
                      'Mon humeur a changé d’un coup aujourd’hui.',
                    ]
                  : const [
                      'I feel a heavy tightness in my chest today.',
                      'I want to understand why I feel this way.',
                      'My emotions shifted suddenly and feel unsettled.',
                    ]);
      case 'psychologicalAnalysis':
        return isArabic
            ? const [
                'نجمو نفهمو نمط متكرر في ردود فعلي؟',
                'لاحظت ديما نهرب مالضغط كي نتحاصر.',
                'عاوني نشوف العلاقة بين أفكاري ومزاجي.',
              ]
            : (isFrench
                  ? const [
                      'Explorer un schéma récurrent dans mes réactions ?',
                      'J’ai remarqué que j’évite souvent la pression.',
                      'Quel lien entre mes pensées et mon humeur ?',
                    ]
                  : const [
                      'Can we explore a recurring pattern in my reactions?',
                      'I noticed I pull away whenever things feel tense.',
                      'Help me see the link between my mood and thoughts.',
                    ]);
      case 'guidedReflection':
        return isArabic
            ? const [
                'عاوني نرتّب الأفكار اللي في بالي خطوة بخطوة.',
                'صار نقاش صعيب اليوم ونحب نفهمو.',
                'نحب نراجع كيفاش تفاعلت مع موقف مقلق.',
              ]
            : (isFrench
                  ? const [
                      'Aidez-moi à organiser mes pensées pas à pas.',
                      'Une discussion difficile m’a marqué aujourd’hui.',
                      'Je veux revoir ma réaction face à un imprévu.',
                    ]
                  : const [
                      'Help me organize what is happening step by step.',
                      'A difficult conversation weighed on me today.',
                      'I want to review how I reacted to a challenge.',
                    ]);
      case 'justTalk':
        return isArabic
            ? const [
                'نحتاج نحكي بهدوء من غير ما نحكم على روحي.',
                'اليوم كان طويل وتعبني برشا.',
                'في بالي برشا حاجات وما نعرفش منين نبدا.',
              ]
            : (isFrench
                  ? const [
                      'J’ai simplement besoin qu’on m’écoute sans juger.',
                      'La journée a été longue et épuisante.',
                      'Beaucoup de choses me pèsent sans savoir par où commencer.',
                    ]
                  : const [
                      'I need a calm space to talk without judgment.',
                      'Today felt long and exhausting.',
                      'I have a lot on my mind and do not know where to start.',
                    ]);
      case 'grounding':
        return isArabic
            ? const [
                'عاوني نعمل تثبيت حسي 5-4-3-2-1.',
                'حاسس بإرهاق ونحتاج نهبط التوتر شوية.',
                'عاوني ننظم تنفّسي توا.',
              ]
            : (isFrench
                  ? const [
                      'Guidez-moi pour un ancrage 5-4-3-2-1.',
                      'Je me sens débordé et j’ai besoin de ralentir.',
                      'Aidez-moi à calmer ma respiration.',
                    ]
                  : const [
                      'Guide me through a 5-4-3-2-1 sensory grounding.',
                      'I feel overwhelmed and need to slow down.',
                      'Help me settle my breathing right now.',
                    ]);
      case 'exploreThought':
      default:
        return isArabic
            ? const [
                'فمّا فكرة مش راضية تخرج من بالي.',
                'حاسس روحي غلطت غلطة كبيرة اليوم.',
                'عاوني نفرّق بين الحقيقة والافتراض لهنا.',
              ]
            : (isFrench
                  ? const [
                      'Une pensée tourne en boucle dans ma tête.',
                      'J’ai l’impression d’avoir fait une grosse erreur.',
                      'Aidez-moi à séparer les faits de mes suppositions.',
                    ]
                  : const [
                      'There is a thought I cannot stop replaying.',
                      'I keep doubting myself even when things go well.',
                      'Help me separate facts from what my mind guessed.',
                    ]);
    }
  }

  // Step 8: Self-Care Tools Drills, Insights Baseline & Chart, 4-Card Profile/Settings
  String get quickCalmTitle => isArabic
      ? 'تهدئة سريعة'
      : (isFrench ? 'Apaisement rapide' : 'Quick Calm');
  String get quickCalmSub => isArabic
      ? 'تنفّس مربّع 4-4-4-4 · تنجم توقّف وقت ما تحب'
      : (isFrench
            ? 'Respiration 4-4-4-4 · Arrêtez quand vous voulez'
            : '4-4-4-4 Box Breathing · Stop anytime');
  String get practiceLabelingTitle => isArabic
      ? 'تمرّن على التمييز: حقيقة أم تخمين أم قصة'
      : (isFrench
            ? 'Pratiquer : Fait, Supposition ou Récit'
            : 'Practice: Fact, Guess, or Story');
  String get practiceLabelingSub => isArabic
      ? 'اقرأ الجملة واختار التصنيف الأقرب — من غير أي ضغط.'
      : (isFrench
            ? 'Lisez chaque phrase et distinguez l’observable de l’interprétation.'
            : 'Tap the tag that matches each sentence — no score, just practice.');
  String get drillCorrectBanner => isArabic
      ? 'تمام — التمييز واضح وموزون.'
      : (isFrench
            ? 'Exact — belle distinction entre fait et interprétation.'
            : 'Spot on — balanced separation of observation and story.');
  String get drillHintPrefix =>
      isArabic ? 'نظرة أخرى:' : (isFrench ? 'Autre piste :' : 'Consider:');

  String get chartHighLabel =>
      isArabic ? 'مرتفع' : (isFrench ? 'Haut' : 'High');
  String get chartMidLabel => isArabic ? 'متوسط' : (isFrench ? 'Moyen' : 'Mid');
  String get chartLowLabel => isArabic ? 'منخفض' : (isFrench ? 'Bas' : 'Low');
  String get calibratingChartTitle => isArabic
      ? 'منحنى المزاج قيد المعايرة'
      : (isFrench
            ? 'Courbe d’humeur en calibration'
            : 'Mood rhythm calibrating');
  String get calibratingChartSub => isArabic
      ? 'سجّل يومين مختلفين على الأقل باش يظهر المنحنى الشخصي متاعك.'
      : (isFrench
            ? 'Enregistrez au moins 2 jours différents pour tracer votre courbe.'
            : 'Log at least 2 different days to render your mood curve.');
  String get steadyWithBaseline => isArabic
      ? 'قريب من عادتك'
      : (isFrench
            ? 'Proche de votre habitude'
            : 'Close to your usual');
  String get rollingNormalSubtitle => isArabic
      ? 'معدّلك المعتاد خلال آخر 30 يوماً من الملاحظة الذاتية:'
      : (isFrench
            ? 'Votre repère habituel sur les 30 derniers jours d’observation :'
            : 'Your rolling normal over the past 30 days of self-observation:');
  String get recordedSymptomsPrefix => isArabic
      ? 'الأعراض والمشاعر المسجّلة:'
      : (isFrench ? 'Observations physiques notées :' : 'Recorded Symptoms:');
  String get fullProgressTrendsTitle => isArabic
      ? 'التقدّم الكامل والاتجاهات الطويلة'
      : (isFrench
            ? 'Progrès complet et tendances longues'
            : 'Full Progress & Longitudinal Trends');
  String get fullProgressTrendsSub => isArabic
      ? 'مشاعرك، نومك، طاقتك والمحطات المهمة'
      : (isFrench
            ? 'Vos émotions, sommeil, énergie et étapes'
            : 'Your feelings, sleep, energy, and milestones');

  String get mostCommonThisWeekLabel => isArabic
      ? 'الشعور الأكثر تكراراً هذا الأسبوع'
      : (isFrench
            ? 'Ressenti le plus fréquent cette semaine'
            : 'Most common this week');
  String get baselineSleepComparisonTitle => isArabic
      ? 'النوم مقارنة بعادتك'
      : (isFrench
            ? 'Sommeil vs habitude'
            : 'Sleep vs. your usual');
  String get baselineMoodComparisonTitle => isArabic
      ? 'قوة الشعور مقارنة بعادتك'
      : (isFrench
            ? 'Intensité vs habitude'
            : 'Feeling strength vs. your usual');

  /// Formats a numeric delta relative to a personal baseline without noisy "0.0".
  String formatBaselineDelta({
    required double delta,
    required double baselineValue,
    required String unit,
    bool higherLabel = true,
  }) {
    final baseStr = '${baselineValue.toStringAsFixed(1)}$unit';
    if (delta.abs() < 0.1) {
      return '$steadyWithBaseline ($baseStr)';
    }
    final amountStr = '${delta.abs().toStringAsFixed(1)}$unit';
    if (isArabic) {
      final dir = delta > 0 ? 'أعلى بـ' : 'أقل بـ';
      return '$dir $amountStr (عادتك: $baseStr)';
    }
    if (isFrench) {
      final dir = delta > 0 ? 'plus haut de' : 'plus bas de';
      return '$dir $amountStr (habitude : $baseStr)';
    }
    final dir = delta > 0 ? 'up by' : 'down by';
    return '$dir $amountStr from baseline ($baseStr)';
  }

  // Step 8 Profile / Settings 4 grouped cards + double-confirm reset
  String get profileGroupYou => isArabic ? 'أنت' : (isFrench ? 'Vous' : 'You');
  String get profileGroupDisplay => isArabic
      ? 'العرض واللغة'
      : (isFrench ? 'Affichage & Langue' : 'Display & Language');
  String get profileGroupAiSecurity => isArabic
      ? 'المتابعة والأمان'
      : (isFrench ? 'Suivi clinique & Sécurité' : 'Care Consult & Security');
  String get profileGroupDataCrisis => isArabic
      ? 'البيانات والطوارئ'
      : (isFrench ? 'Données & Crise' : 'Data & Crisis');
  String get preferredNameLabel => isArabic
      ? 'الاسم المفضّل'
      : (isFrench ? 'Prénom / Nom affiché' : 'Preferred name');
  String get editPreferredNameHint => isArabic
      ? 'أدخل الاسم الذي تحب الظهور به...'
      : (isFrench
            ? 'Comment souhaitez-vous être appelé ?'
            : 'How should we address you?');
  String get notSetLabel =>
      isArabic ? 'غير محدد' : (isFrench ? 'Non défini' : 'Not set');
  String get accountStatusLabel =>
      isArabic ? 'حالة الحساب' : (isFrench ? 'Compte' : 'Account');
  String get localDeviceOnlyLabel => isArabic
      ? 'خاص على هذا الجهاز'
      : (isFrench ? 'Privé sur cet appareil' : 'Private on this device');
  String get backupNowBtn =>
      isArabic ? 'نسخ احتياطي الآن' : (isFrench ? 'Sauvegarder' : 'Backup Now');
  String get supportCrisisRowTitle => isArabic
      ? 'الدعم والمساعدة العاجلة'
      : (isFrench ? 'Aide & Lignes d’urgence' : 'Support & Crisis Helplines');
  String get resetConfirmStep1Title => isArabic
      ? 'بدء تصفير كل البيانات؟'
      : (isFrench
            ? 'Commencer la réinitialisation complète ?'
            : 'Start full local data reset?');
  String get resetConfirmStep1Body => isArabic
      ? 'باش تتأكّد في الخطوة الجاية قبل مسح أي يومية، أو جلسة، أو ملف من جهازك.'
      : (isFrench
            ? 'Une deuxième confirmation sera demandée avant d’effacer vos bilans, sessions et profil.'
            : 'You will confirm once more before erasing check-ins, sessions, and your local profile.');
  String get continueActionBtn =>
      isArabic ? 'مواصلة' : (isFrench ? 'Continuer' : 'Continue');
  String get resetConfirmStep2Title => isArabic
      ? 'تأكيد المسح النهائي؟'
      : (isFrench ? 'Confirmation finale ?' : 'Final confirmation?');
  String get resetConfirmStep2Body => isArabic
      ? 'كل التدوينات، المحادثات، الذكريات والملف الشخصي على هذا الجهاز باش يتمسحو نهائياً. ما فماش رجوع.'
      : (isFrench
            ? 'Toutes vos traces, échanges et données de profil seront supprimés de façon irréversible.'
            : 'All check-ins, talks, memories, and profile records on this device will be permanently removed.');
  String get confirmResetBtn => isArabic
      ? 'نعم، امسح كل شيء'
      : (isFrench ? 'Tout effacer' : 'Erase Everything');

  // Slice 3A: Clinical Engine Config & Non-Silent Runtime Notice
  String get aiEngineSheetTitle => isArabic
      ? 'إعدادات محرك الحوار'
      : (isFrench
            ? 'Paramètres du compagnon IA'
            : 'Companion engine settings');
  String get aiEngineLiveGroqBadge =>
      isArabic ? 'GROQ مباشر' : (isFrench ? 'GROQ EN DIRECT' : 'LIVE GROQ');
  String get aiEngineLiveGeminiBadge => isArabic
      ? 'GEMINI مباشر'
      : (isFrench ? 'GEMINI EN DIRECT' : 'LIVE GEMINI');
  String get aiEngineTestModeBadge => isArabic
      ? 'وضع التجربة (\$0.00)'
      : (isFrench ? 'MODE TEST (\$0.00)' : 'TEST MODE (\$0.00)');
  String get aiEngineSheetSubtitle => isArabic
      ? 'الوضع العادي: تجريبي مجاني على تليفونك. الربط المباشر اختياري.'
      : (isFrench
            ? 'Par défaut : mode test local gratuit. L’IA en direct est facultative.'
            : 'Default: free offline test mode on your phone. Live AI is optional.');
  String get aiEngineGroqOption => isArabic
      ? 'Groq (Llama مجاني)'
      : (isFrench ? 'Groq (Llama gratuit)' : 'Groq (Free Llama)');
  String get aiEngineGeminiOption => 'Google Gemini';
  String get aiEngineDevTestModeTitle => isArabic
      ? 'وضع التطوير والاختبار'
      : (isFrench ? 'Mode développement / test' : 'Development / Test Mode');
  String get aiEngineDevTestModeSubtitle => isArabic
      ? 'تشغيل الوضع المحلي المجاني بدون أي اتصال خارجي.'
      : (isFrench
            ? 'Force le mode local hors ligne sans frais ni appel réseau.'
            : 'Enforce offline mock mode for zero-cost and automated testing.');
  String get aiEngineGroqKeyLabel => isArabic
      ? 'مفتاح GROQ API (CONSOLE.GROQ.COM)'
      : (isFrench
            ? 'CLÉ API GROQ (CONSOLE.GROQ.COM)'
            : 'GROQ API KEY (CONSOLE.GROQ.COM)');
  String get aiEngineGeminiKeyLabel => isArabic
      ? 'مفتاح GOOGLE GEMINI API'
      : (isFrench ? 'CLÉ API GOOGLE GEMINI' : 'GOOGLE GEMINI API KEY');
  String get aiEngineProxyLabel => isArabic
      ? 'عنوان البروكسي الآمن (اختياري)'
      : (isFrench
            ? 'URL DU PROXY SÉCURISÉ (OPTIONNEL)'
            : 'SECURE PROXY URL (OPTIONAL)');
  String get aiEngineProxyHint => isArabic
      ? 'https://your-proxy.example.com/v1/chat/completions'
      : (isFrench
            ? 'https://votre-proxy.example.com/v1/chat/completions'
            : 'https://your-proxy.example.com/v1/chat/completions');
  String get aiEngineTestConnBtn => isArabic
      ? 'اختبار الاتصال'
      : (isFrench ? 'TESTER LA CONNEXION' : 'TEST CONNECTION');
  String get aiEngineSaveActivateBtn =>
      isArabic ? 'حفظ وتفعيل' : (isFrench ? 'ENREGISTRER' : 'SAVE & ACTIVATE');
  String get aiEngineRevertMockBtn => isArabic
      ? 'العودة إلى الوضع المحلي'
      : (isFrench
            ? 'Revenir au mode local hors ligne'
            : 'Revert to Offline Mock Mode');
  String get aiEngineEmptyKeyPrompt => isArabic
      ? 'أدخل مفتاح API أو عنوان بروكسي لاختبار الاتصال.'
      : (isFrench
            ? 'Saisissez une clé API ou une URL proxy pour tester.'
            : 'Please enter an API key or proxy URL to test connection.');
  String aiEngineSavedSnackbar(String providerLabel, bool hasLive) {
    if (hasLive) {
      if (isArabic) {
        return 'تم حفظ وتفعيل محرك $providerLabel.';
      }
      if (isFrench) {
        return 'Configuration $providerLabel enregistrée et activée.';
      }
      return '$providerLabel API configuration saved and activated.';
    }
    if (isArabic) return 'تم التحويل إلى الوضع المحلي المجاني.';
    if (isFrench) return 'Bascule vers le simulateur clinique hors ligne.';
    return 'Switched to offline clinical simulator.';
  }

  String get aiEngineClearedSnackbar => isArabic
      ? 'تم مسح المفتاح. الوضع المحلي مفعّل.'
      : (isFrench
            ? 'Clé API supprimée. Mode local activé.'
            : 'API key cleared. Offline mock mode active.');

  String get aiNoticeDailyLimit => isArabic
      ? 'وصلت للحد اليومي للمساعد الحي — مواصلة هادئة بالوضع المحلي.'
      : (isFrench
            ? 'Limite quotidienne atteinte — poursuite calme en mode local.'
            : 'Daily live reflection limit reached — continuing gently in offline mode.');
  String get aiNoticeOfflineFallback => isArabic
      ? 'تعذر الاتصال بالمساعد الحي — تم التحويل تلقائياً إلى الوضع المحلي.'
      : (isFrench
            ? 'IA en direct hors ligne — bascule douce vers le mode local.'
            : 'Live AI unavailable offline — switched gently to local mode.');
  String get aiNoticeApiErrorFallback => isArabic
      ? 'تعذر استجابة المزوّد الخارجي — يتم المتابعة بالوضع المحلي.'
      : (isFrench
            ? 'Le fournisseur externe n’a pas répondu — poursuite en mode local.'
            : 'Live AI provider returned an error — continuing calmly in local mode.');
  String get aiEngineSettingsAction =>
      isArabic ? 'الإعدادات' : (isFrench ? 'Réglages' : 'Engine');

  String get confirmAction =>
      isArabic ? 'تأكيد' : (isFrench ? 'Confirmer' : 'Confirm');
  String get dismissAction =>
      isArabic ? 'تجاهل' : (isFrench ? 'Ignorer' : 'Dismiss');

  String memoryObservationsSummary(int obsCount, int entryCount) {
    if (isArabic) {
      return '$obsCount ملاحظات • $entryCount تدوينات';
    }
    if (isFrench) {
      return '$obsCount observations • $entryCount entrées';
    }
    return '$obsCount observations • $entryCount source entries';
  }

  String localizeAuthError(String raw) {
    final cleaned = raw
        .replaceFirst(RegExp(r'^FormatException:\s*'), '')
        .trim();
    switch (cleaned) {
      case 'Please enter a valid email address.':
        return isArabic
            ? 'الرجاء إدخال بريد إلكتروني صحيح.'
            : (isFrench
                  ? 'Veuillez saisir une adresse e-mail valide.'
                  : cleaned);
      case 'Password must be at least 6 characters.':
        return isArabic
            ? 'كلمة المرور يجب أن تحتوي على 6 أحرف على الأقل.'
            : (isFrench
                  ? 'Le mot de passe doit contenir au moins 6 caractères.'
                  : cleaned);
      case 'An account with this email already exists.':
        return isArabic
            ? 'يوجد حساب مسجّل بهذا البريد الإلكتروني بالفعل.'
            : (isFrench
                  ? 'Un compte existe déjà avec cette adresse e-mail.'
                  : cleaned);
      case 'Invalid email or password.':
        return isArabic
            ? 'البريد الإلكتروني أو كلمة المرور غير صحيحة.'
            : (isFrench ? 'E-mail ou mot de passe incorrect.' : cleaned);
      case 'Account profile not found.':
        return isArabic
            ? 'لم يتم العثور على ملف الحساب.'
            : (isFrench ? 'Profil du compte introuvable.' : cleaned);
      default:
        if (cleaned.isNotEmpty) return cleaned;
        return isArabic
            ? 'تعذر إتمام العملية. يرجى المحاولة مجدداً.'
            : (isFrench
                  ? 'Impossible de finaliser l’opération. Veuillez réessayer.'
                  : 'Unable to complete the request. Please try again.');
    }
  }

  // ===========================================================================
  // PHASE 2: MULTI-AFFECT SPECTRUM & INTRA-DAY MOMENTS
  // ===========================================================================
  String get alsoFeelingOptionalLabel => isArabic
      ? 'شعور آخر مصاحب (اختياري)'
      : (isFrench ? 'RESSENTI NUANCÉ (OPTIONNEL)' : 'ALSO FEELING (OPTIONAL)');

  String get showMoreFeelingsBtn => isArabic
      ? '+ مشاعر أكثر'
      : (isFrench ? '+ Plus de nuances' : '+ More feelings');

  String get showFewerFeelingsBtn =>
      isArabic ? 'أقل' : (isFrench ? 'Réduire' : 'Less');

  String get addCustomFeelingBtn =>
      isArabic ? '+ مخصص' : (isFrench ? '+ Personnalisé' : '+ Custom');

  String get customFeelingSheetTitle => isArabic
      ? 'أضف شعوراً خاصاً بك'
      : (isFrench ? 'Ajouter un ressenti' : 'Add Custom Feeling');

  String get customFeelingHint => isArabic
      ? 'مثلاً: مضغوط، متأثر، مرتاح البال...'
      : (isFrench
            ? 'ex. Tiraillement, Pression, Apaisé...'
            : 'e.g., Torn, Pressured, Peaceful...');

  String get todaysMomentsHeader => isArabic
      ? 'لحظات اليوم'
      : (isFrench ? 'MOMENTS DU JOUR' : 'TODAY’S MOMENTS');

  String get newMomentChipLabel => isArabic
      ? '+ لحظة جديدة'
      : (isFrench ? '+ Nouveau moment' : '+ New moment');

  String get logNewMomentBtn => isArabic
      ? 'سجّل لحظة جديدة'
      : (isFrench ? 'Enregistrer ce moment' : 'Log New Moment');

  String get logMomentShortBtn =>
      isArabic ? 'لحظة جديدة' : (isFrench ? 'Moment' : 'Log moment');

  String momentsCountLabel(int count) {
    if (isArabic) return '$count لحظات';
    if (isFrench) return '$count moments';
    return '$count moments';
  }

  String momentsTodayTrail(int count, String shiftText) {
    if (isArabic) return '$count لحظات اليوم · $shiftText';
    if (isFrench) return '$count moments aujourd’hui · $shiftText';
    return '$count moments today · $shiftText';
  }

  String get affectSpectrumSectionTitle => isArabic
      ? 'طيف المشاعر والإيقاع اليومي'
      : (isFrench
            ? 'Spectre émotionnel & Rythme diurne'
            : 'Affect Spectrum & Diurnal Rhythm');

  String get recurringFeelingsLabel => isArabic
      ? 'المشاعر المصاحبة المتكررة'
      : (isFrench ? 'Nuances récurrentes' : 'Co-occurring feelings');

  String get diurnalRhythmLabel => isArabic
      ? 'تغيّر الحالة حسب الوقت'
      : (isFrench ? 'Rythme selon l’heure' : 'Time-of-day rhythm');

  String get intraDayShiftAvgLabel => isArabic
      ? 'متوسط التقلّب اليومي'
      : (isFrench ? 'Variation intra-journalière' : 'Avg intra-day swing');

  String get morningBucketLabel =>
      isArabic ? 'الصباح' : (isFrench ? 'Matin' : 'Morning');

  String get afternoonBucketLabel =>
      isArabic ? 'العشية' : (isFrench ? 'Après-midi' : 'Afternoon');

  String get eveningBucketLabel =>
      isArabic ? 'المساء' : (isFrench ? 'Soirée' : 'Evening');

  String get nightBucketLabel =>
      isArabic ? 'الليل' : (isFrench ? 'Nuit' : 'Night');

  // ---------------------------------------------------------------------------
  // Phase 3: Psychiatrist Workspace & Encrypted Care Handoff Protocol
  // ---------------------------------------------------------------------------

  String get psychiatristWorkspaceTitle => isArabic
      ? 'فضاء الطبيب النفسي'
      : (isFrench ? 'Espace Psychiatre' : 'Psychiatrist Workspace');

  String get psychiatristWorkspaceSub => isArabic
      ? 'مراجعة ملفات المرضى والاتجاهات وملاحظات الجلسات'
      : (isFrench
            ? 'Suivre les patients importés, tendances et notes cliniques'
            : 'Review imported patient timelines, shifts & clinical notes');

  String get shareWithPsychiatristTitle => isArabic
      ? 'مشاركة مع الطبيب النفسي'
      : (isFrench ? 'Partager avec mon psychiatre' : 'Share with Psychiatrist');

  String get shareWithPsychiatristSub => isArabic
      ? 'حزمة مشفّرة حسب اختيارك وجدول تحضير للجلسة'
      : (isFrench
            ? 'Paquet chiffré sur consentement & ordre du jour de visite'
            : 'Consent-scoped encrypted handoff & pre-visit agenda');

  String get clinicianPortalBtnLabel => isArabic
      ? 'بوابة الطبيب النفسي / المعالج'
      : (isFrench
            ? 'Portail Psychiatre / Clinicien'
            : 'Psychiatrist / Clinician Portal');

  String get switchToPatientWorkspaceBtn => isArabic
      ? 'العودة إلى فضاء المريض'
      : (isFrench
            ? 'Passer à l’espace patient'
            : 'Switch to Patient Workspace');

  String get patientViewChipLabel =>
      isArabic ? 'فضاء المريض' : (isFrench ? 'Vue Patient' : 'Patient View');

  String get careHandoffSubtitle => isArabic
      ? 'اختر المدة الزمنية ونوع المعطيات اللي تحب تشاركها بأمان مع طبيبك.'
      : (isFrench
            ? 'Choisissez la fenêtre et les données partagées en toute confidentialité.'
            : 'Choose your timeframe and exactly what enters the clinical handoff.');

  String get timeWindowLabel => isArabic
      ? 'الفترة الزمنية'
      : (isFrench ? 'FENÊTRE DE PARTAGE' : 'SHARE WINDOW');

  String daysWindowLabel(int days) {
    if (isArabic) return '$days يوم';
    if (isFrench) return '${days}j';
    return '${days}d';
  }

  String get whatToShareLabel => isArabic
      ? 'شنوّة تحب تشارك'
      : (isFrench ? 'PORTÉE DU CONSENTEMENT' : 'CONSENT SCOPE');

  String get scopeMoodMetricsLabel => isArabic
      ? 'المزاج العام والشدة والمشاعر الدقيقة'
      : (isFrench
            ? 'Humeur principale, intensité & nuances'
            : 'Core mood, intensity & nuanced feelings');

  String get scopeSleepEnergyAnxietyLabel => isArabic
      ? 'ساعات النوم والطاقة والتوتر اليومي'
      : (isFrench
            ? 'Sommeil, énergie & niveau de tension'
            : 'Sleep duration, energy & anxiety levels');

  String get scopePersonalNotesLabel => isArabic
      ? 'الملاحظات الشخصية والمحفزات اليومية'
      : (isFrench
            ? 'Notes personnelles & déclencheurs'
            : 'Personal daily notes, triggers & what helped');

  String get scopeSharedCasesLabel => isArabic
      ? 'الاستكشافات المعرفية غير الخاصة'
      : (isFrench
            ? 'Explorations cognitives non privées'
            : 'Non-private CBT-inspired explorations');

  String get scopeSymptomReportsLabel => isArabic
      ? 'سجل الأعراض الجسدية والنفسية'
      : (isFrench
            ? 'Rapports de symptômes observés'
            : 'Self-reported symptom logs');

  String get scopeProfileSnapshotLabel => isArabic
      ? 'ملخص الأهداف وتفضيلات التواصل'
      : (isFrench
            ? 'Objectifs & préférences de communication'
            : 'Goals & communication preferences');

  String get scopePreVisitAgendaLabel => isArabic
      ? 'نقاط التحضير لموعد الطبيب'
      : (isFrench
            ? 'Ordre du jour de pré-consultation'
            : 'Pre-visit consultation agenda');

  String privateCasesExcludedBanner(int count) {
    if (isArabic) {
      return count > 0
          ? '$count حوار(ات) خاصة مستبعدة — الحوارات الخاصة ما تتشاركش أبداً.'
          : 'الحوارات الخاصة مستبعدة تلقائياً وما تغادرش تليفونك.';
    }
    if (isFrench) {
      return count > 0
          ? '$count échange(s) privé(s) exclu(s) — jamais partagés.'
          : 'Les échanges privés sont toujours exclus automatiquement.';
    }
    return count > 0
        ? '$count private talk(s) left out — private talks are never shared.'
        : 'Private talks are always left out automatically.';
  }

  String get preVisitAgendaSectionTitle => isArabic
      ? 'تحضير موعد الاستشارة (اختياري)'
      : (isFrench
            ? 'PRÉPARER LA CONSULTATION (OPTIONNEL)'
            : 'PRE-VISIT AGENDA (OPTIONAL)');

  String get preVisitTopicsLabel => isArabic
      ? 'مواضيع تحب تحكي فيها'
      : (isFrench ? 'Sujets à aborder' : 'Topics for your visit');

  String get preVisitQuestionHint => isArabic
      ? 'سؤال تحب تسألو لطبيبك... (اختياري)'
      : (isFrench
            ? 'Une question pour votre psychiatre... (optionnel)'
            : 'One question for your psychiatrist... (optional)');

  String get preVisitHelpedHint => isArabic
      ? 'شنوّة عاونك ها الفترة؟ (اختياري)'
      : (isFrench
            ? 'Ce qui vous a aidé récemment... (optionnel)'
            : 'What has helped recently... (optional)');

  String get preVisitTopicSleep => isArabic
      ? 'تقلّبات النوم'
      : (isFrench ? 'Variations du sommeil' : 'Sleep shifts');

  String get preVisitTopicEveningDips => isArabic
      ? 'هبوط المزاج في المساء'
      : (isFrench ? 'Baisses en soirée' : 'Evening dips');

  String get preVisitTopicWorkStrain => isArabic
      ? 'ضغط الخدمة أو القراية'
      : (isFrench ? 'Charge pro / études' : 'Work or study strain');

  String get preVisitTopicTreatmentQuestions => isArabic
      ? 'أسئلة على الخطة أو الدواء'
      : (isFrench ? 'Questions de suivi' : 'Follow-up & medication questions');

  String get preVisitTopicThoughtLoops => isArabic
      ? 'دوائر الأفكار المتكررة'
      : (isFrench ? 'Ruminations récurrentes' : 'Recurring thought loops');

  String get preVisitTopicCopingReview => isArabic
      ? 'شنوّة نفعني مؤخراً'
      : (isFrench ? 'Stratégies utiles' : 'Review what helped');

  String get handoffPassphraseLabel => isArabic
      ? 'كلمة سر لفك التشفير (6 أحرف على الأقل)'
      : (isFrench
            ? 'Phrase secrète de transfert (min. 6 caractères)'
            : 'Handoff Passphrase (min. 6 chars)');

  String get handoffPassphraseHint => isArabic
      ? 'أدخل كلمة سر تتشاركها مع طبيبك'
      : (isFrench
            ? 'Ex. seance-tunis-24'
            : 'Enter a passphrase to share separately');

  String get handoffPassphraseMinError => isArabic
      ? 'كلمة السر يلزمها 6 أحرف على الأقل.'
      : (isFrench
            ? 'Veuillez saisir au moins 6 caractères.'
            : 'Please enter at least 6 characters.');

  String get generateSyncCodeBtn => isArabic
      ? 'إنشاء رمز مزامنة مشفّر'
      : (isFrench ? 'Générer un code chiffré' : 'Generate Encrypted Sync Code');

  String get copySyncCodeBtn => isArabic
      ? 'نسخ رمز المزامنة'
      : (isFrench ? 'Copier le code chiffré' : 'Copy Sync Code');

  String get syncCodeCopiedSnackbar => isArabic
      ? 'تم نسخ رمز المزامنة المشفّر.'
      : (isFrench ? 'Code chiffré copié.' : 'Encrypted sync code copied.');

  String get sendToLocalClinicianBtn => isArabic
      ? 'إرسال مباشرة لفضاء الطبيب على هذا الجهاز'
      : (isFrench
            ? 'Envoyer à l’espace psychiatre local'
            : 'Send to Psychiatrist Workspace on This Device');

  String get sentToLocalClinicianSnackbar => isArabic
      ? 'تم تحديث ملف المريض في فضاء الطبيب.'
      : (isFrench
            ? 'Paquet transmis à l’espace psychiatre.'
            : 'Delivered to Psychiatrist Workspace on this device.');

  String get openClinicianWorkspaceBtn => isArabic
      ? 'فتح الفضاء'
      : (isFrench ? 'Ouvrir l’espace' : 'Open Workspace');

  String get clinicianTabPatients =>
      isArabic ? 'المرضى' : (isFrench ? 'Patients' : 'Patients');

  String get clinicianTabOverview =>
      isArabic ? 'نظرة عامة' : (isFrench ? 'Cohorte' : 'Overview');

  String get clinicianTabPractice =>
      isArabic ? 'العيادة' : (isFrench ? 'Cabinet' : 'Practice');

  String get importPacketBtn =>
      isArabic ? '+ استيراد' : (isFrench ? '+ Importer' : '+ Import');

  String get kpiActivePatients =>
      isArabic ? 'المرضى' : (isFrench ? 'Patients' : 'Active Patients');

  String get kpiBaselineShifts => isArabic
      ? 'تغيّرات ملحوظة'
      : (isFrench
            ? 'Écarts notables'
            : 'Notable shifts');

  String get kpiSharedUpdates => isArabic
      ? 'تحديثات جديدة'
      : (isFrench ? 'Nouveaux partages' : 'Shared Updates');

  String get filterAll => isArabic ? 'الكل' : (isFrench ? 'Tous' : 'All');

  String get filterShiftsNoted => isArabic
      ? 'تغيّرات مرصودة'
      : (isFrench ? 'Écarts notables' : 'Shifts Noted');

  String get filterNewUpdates =>
      isArabic ? 'جديد' : (isFrench ? 'Non lus' : 'New Updates');

  String get filterDemoCohort => isArabic
      ? 'ملفات تجريبية'
      : (isFrench
            ? 'Patients démo'
            : 'Sample patients');

  String get demoDatasetBadge =>
      isArabic ? 'تجريبي' : (isFrench ? 'DÉMO' : 'DEMO');

  String shiftsCountBadge(int count) {
    if (isArabic) {
      return count == 1 ? 'تغيّر واحد' : '$count تغيّرات';
    }
    if (isFrench) {
      return count == 1 ? '1 écart' : '$count écarts';
    }
    return count == 1 ? '1 shift' : '$count shifts';
  }

  String get baselineSteadyBadge => isArabic
      ? 'مستقر'
      : (isFrench
            ? 'Stable'
            : 'Near usual');

  String get noPatientsEmptyTitle => isArabic
      ? 'ما فمّاش ملفات مرضى بعد'
      : (isFrench
            ? 'Aucun résumé patient'
            : 'No patient summaries yet');

  String get noPatientsEmptySub => isArabic
      ? 'امسح رمز المريض أو فعّل الملفات التجريبية.'
      : (isFrench
            ? 'Scannez un code patient ou activez les cas démo.'
            : 'Scan a patient code or turn on sample patients.');

  String get cohortObservationsTitle => isArabic
      ? 'التغيّرات الأخيرة عند المرضى'
      : (isFrench
            ? 'Évolutions récentes des patients'
            : 'Recent shifts across patients');

  String get cohortTopFeelingsTitle => isArabic
      ? 'المشاعر الدقيقة الأكثر تكراراً'
      : (isFrench
            ? 'NUANCES ÉMOTIONNELLES DOMINANTES'
            : 'RECURRING AFFECT SPECTRUM');

  String get cohortAvgMetricsTitle => isArabic
      ? 'معدلات آخر 7 أيام'
      : (isFrench
            ? 'Moyennes sur 7 jours'
            : '7-day averages');

  String get practiceProfileTitle => isArabic
      ? 'معلومات الممارس / العيادة'
      : (isFrench ? 'PROFIL DU PRATICIEN' : 'PRACTITIONER PROFILE');

  String get editPracticeProfileTitle => isArabic
      ? 'تعديل بيانات الطبيب'
      : (isFrench ? 'Modifier le profil clinicien' : 'Edit Clinician Profile');

  String get clinicianNameLabel => isArabic
      ? 'الاسم المهني'
      : (isFrench ? 'Nom du psychiatre' : 'Clinician Name');

  String get clinicianSpecialtyLabel =>
      isArabic ? 'الاختصاص' : (isFrench ? 'Spécialité' : 'Specialty');

  String get clinicNameLabel => isArabic
      ? 'العيادة أو المؤسسة'
      : (isFrench ? 'Cabinet / Service' : 'Clinic / Practice');

  String get demoCohortToggleTitle => isArabic
      ? 'عرض الحالات السريرية التجريبية'
      : (isFrench ? 'Jeu de données cliniques démo' : 'Demo Clinical Dataset');

  String get demoCohortToggleSub => isArabic
      ? 'ثلاثة ملفات افتراضية لتجربة فضاء الطبيب'
      : (isFrench
            ? 'Affiche 3 profils fictifs (Nadia, Karim, Lina) clairement marqués DÉMO'
            : 'Shows 3 clearly badged fictional patient timelines for clinical evaluation');

  String get clinicBiometricLockTitle => isArabic
      ? 'قفل العيادة بالبصمة'
      : (isFrench ? 'Verrouillage biométrique' : 'Biometric Vault Lock');

  String get biometricLockSub => isArabic
      ? 'تأمين المعطيات السريرية والملاحظات الخاصة'
      : (isFrench
            ? 'Protéger l’accès aux dossiers et notes privées'
            : 'Protect clinical timelines and private clinician notes');

  String get clearImportedPatientsBtn => isArabic
      ? 'مسح الملفات المستوردة'
      : (isFrench
            ? 'Effacer les dossiers importés'
            : 'Clear Imported Patients');

  String get clearImportedPatientsConfirm => isArabic
      ? 'سيتم حذف جميع حزم المرضى المستوردة وملاحظاتها على هذا الجهاز فقط.'
      : (isFrench
            ? 'Supprime tous les patients importés localement (hors dossiers démo).'
            : 'Removes all imported patient packets and associated local notes.');

  String get clinicalBoundaryNote => isArabic
      ? 'أداة مساعدة للمعاينة وموش تشخيص آلي. تعرض كان المعطيات الموافَق عليها.'
      : (isFrench
            ? 'Aide à la revue clinique sans diagnostic auto. Données partagées uniquement.'
            : 'Supports clinical review — not automated diagnosis. Shows patient-shared data only.');

  String get importPacketTitle => isArabic
      ? 'استيراد حزمة مريض مشفّرة'
      : (isFrench
            ? 'Importer un paquet patient chiffré'
            : 'Import Encrypted Patient Packet');

  String get importPacketSubtitle => isArabic
      ? 'ألصق الرمز المشفّر الذي أرسله المريض مع كلمة السر الخاصة بالجلسة.'
      : (isFrench
            ? 'Collez le code MF-CLINIC-V1 transmis par le patient ainsi que la phrase secrète.'
            : 'Paste the patient’s MF-CLINIC-V1 sync code and shared passphrase to decrypt locally.');

  String get syncCodeFieldLabel => isArabic
      ? 'رمز المزامنة (MF-CLINIC-V1:...)'
      : (isFrench ? 'Code de synchronisation' : 'Sync Code');

  String get syncCodeFieldHint => isArabic
      ? 'MF-CLINIC-V1:...'
      : (isFrench ? 'MF-CLINIC-V1:...' : 'MF-CLINIC-V1:...');

  String get decryptAndImportBtn => isArabic
      ? 'فك التشفير والاستيراد'
      : (isFrench ? 'Déchiffrer et importer' : 'Decrypt & Import');

  String get importSuccessSnackbar => isArabic
      ? 'تفتح ملخص المريض وتزاد بأمان.'
      : (isFrench
            ? 'Résumé patient déchiffré et ajouté.'
            : 'Patient summary unlocked and added.');

  String get importInvalidCodeError => isArabic
      ? 'صيغة الرمز غير صالحة أو ناقصة.'
      : (isFrench
            ? 'Format de code invalide ou corrompu.'
            : 'Invalid or malformed sync code format.');

  String get importWrongPassphraseError => isArabic
      ? 'تعذّر فك التشفير — تأكد من كلمة السر وصحة الرمز.'
      : (isFrench
            ? 'Échec du déchiffrement — vérifiez la phrase secrète.'
            : 'Decryption failed — check passphrase or packet integrity.');

  String get dossierTabOverview =>
      isArabic ? 'الملخص' : (isFrench ? 'Aperçu' : 'Overview');

  String get dossierTabTimeline =>
      isArabic ? 'التسلسل' : (isFrench ? 'Chronologie' : 'Timeline');

  String get dossierTabCases =>
      isArabic ? 'الحالات' : (isFrench ? 'Explorations' : 'Cases');

  String get dossierTabNotes =>
      isArabic ? 'ملاحظاتي' : (isFrench ? 'Notes' : 'Notes');

  String get copyEhrSummaryBtn => isArabic
      ? 'نسخ ملاحظة العيادة'
      : (isFrench
            ? 'Copier note clinique'
            : 'Copy clinic note');

  String get ehrCopiedSnackbar => isArabic
      ? 'تم نسخ الملخص السريري المنظم.'
      : (isFrench
            ? 'Résumé structuré copié dans le presse-papiers.'
            : 'Structured EHR consultation summary copied.');

  String get consentScopeBannerTitle => isArabic
      ? 'نطاق موافقة المريض'
      : (isFrench ? 'PORTÉE DU CONSENTEMENT PATIENT' : 'PATIENT CONSENT SCOPE');

  String get recentVsBaselineTitle => isArabic
      ? 'آخر 7 أيام مقارنة بالمعتاد'
      : (isFrench
            ? '7 derniers jours vs habitude'
            : 'Last 7 days vs. usual');

  String get metricColumnLabel =>
      isArabic ? 'المؤشر' : (isFrench ? 'Indicateur' : 'Metric');

  String get recent7dColumnLabel =>
      isArabic ? '7 أيام' : (isFrench ? '7j' : '7d');

  String get baselineColumnLabel => isArabic
      ? 'المعتاد'
      : (isFrench
            ? 'Habitude'
            : 'Usual');

  String get deltaColumnLabel =>
      isArabic ? 'الفرق' : (isFrench ? 'Écart' : 'Delta');

  String get notesNotSharedNotice => isArabic
      ? 'اختار المريض عدم مشاركة الملاحظات النصية في هذه الحزمة.'
      : (isFrench
            ? 'Le patient a choisi de ne pas partager ses notes personnelles.'
            : 'Personal free-text notes were excluded by patient consent.');

  String get casesNotSharedNotice => isArabic
      ? 'اختار المريض عدم مشاركة جلسات الاستكشاف في هذه الحزمة.'
      : (isFrench
            ? 'Explorations cognitives exclues par le consentement du patient.'
            : 'CBT-inspired explorations were excluded by patient consent.');

  String get privateCasesNeverSharedNote => isArabic
      ? 'الجلسات المصنفة خاصة لا تُدرج أبداً في هذا الفضاء.'
      : (isFrench
            ? 'Les sessions marquées privées restent strictement invisibles.'
            : 'Sessions marked Private on the patient device are never transmitted.');

  String get sharedCasesTitle => isArabic
      ? 'جلسات الاستكشاف المعرفي المشتركة'
      : (isFrench
            ? 'EXPLORATIONS COGNITIVES PARTAGÉES'
            : 'SHARED COGNITIVE EXPLORATIONS');

  String get sharedSymptomsTitle => isArabic
      ? 'سجل الأعراض المشارَك'
      : (isFrench ? 'RAPPORTS DE SYMPTÔMES PARTAGÉS' : 'SHARED SYMPTOM LOGS');

  String get clinicianNotesPrivateNotice => isArabic
      ? 'ملاحظات الطبيب مشفّرة ومحفوظة في فضاء العيادة فقط — لا ترسل تلقائياً للمريض.'
      : (isFrench
            ? 'Ces notes sont isolées et chiffrées localement dans votre espace clinicien.'
            : 'Encrypted locally inside the isolated clinician workspace — never pushed back automatically.');

  String get addClinicianNoteBtn => isArabic
      ? '+ إضافة ملاحظة سريرية'
      : (isFrench ? '+ Ajouter une note clinique' : '+ Add Clinical Note');

  String get clinicianNoteTagLabel =>
      isArabic ? 'تصنيف الملاحظة' : (isFrench ? 'Catégorie' : 'Note Tag');

  String get clinicianNoteBodyHint => isArabic
      ? 'اكتب ملاحظات المعاينة أو المتابعة...'
      : (isFrench
            ? 'Observations cliniques, évolution, plan de suivi...'
            : 'Clinical observations, contextual synthesis, follow-up focus...');

  String get saveNoteBtn => isArabic
      ? 'حفظ الملاحظة'
      : (isFrench ? 'Enregistrer la note' : 'Save Note');

  String get noClinicianNotesYet => isArabic
      ? 'ما فماش ملاحظات مسجّلة لهذا الملف حتى الآن.'
      : (isFrench
            ? 'Aucune note clinique enregistrée pour ce patient.'
            : 'No clinician session notes recorded for this patient yet.');

  String get ehrSummaryFullBtn => isArabic
      ? 'نسخ ملخص الاستشارة السريري'
      : (isFrench
            ? 'Copier le résumé de consultation'
            : 'Copy EHR Consultation Summary');

  String get metricMoodLabel =>
      isArabic ? 'قوة المشاعر (1–10)' : (isFrench ? 'Intensité (1–10)' : 'Mood (1–10)');

  String get metricSleepLabel =>
      isArabic ? 'النوم (س)' : (isFrench ? 'Sommeil (h)' : 'Sleep (h)');

  String get metricEnergyLabel =>
      isArabic ? 'الطاقة' : (isFrench ? 'Énergie' : 'Energy');

  String get metricAnxietyLabel =>
      isArabic ? 'التوتر' : (isFrench ? 'Tension' : 'Anxiety');

  String get patientNotFoundTitle => isArabic
      ? 'ملف المريض موش موجود'
      : (isFrench
            ? 'Résumé patient introuvable'
            : 'Patient summary not found');

  String get backToPatientsBtn => isArabic
      ? 'العودة لقائمة المرضى'
      : (isFrench ? 'Retour aux patients' : 'Back to Patients');

  String momentsLoggedLabel(int count) {
    if (isArabic) return '$count تسجيلات';
    if (isFrench) return '$count entrées';
    return '$count logs';
  }

  // ---------------------------------------------------------------------------
  // Milestone 4.1: Two-Way Care Loop — Between-Session Focus Plan
  // ---------------------------------------------------------------------------

  String get sharePostVisitFocusBtn => isArabic
      ? 'إرسال خطة التركيز للمريض'
      : (isFrench
            ? 'Envoyer le plan entre séances'
            : 'Send Between-Session Focus');

  String get composeFocusTitle => isArabic
      ? 'خطة التركيز بين الجلسات'
      : (isFrench
            ? 'Plan de suivi entre consultations'
            : 'Between-Session Focus Plan');

  String get composeFocusSubtitle => isArabic
      ? 'نقاط متّفق عليها مع المريض للملاحظة قبل الموعد الجاي — اختياري وقابل للتعديل من طرف المريض.'
      : (isFrench
            ? 'Repères collaboratifs choisis avec le patient jusqu’au prochain rendez-vous.'
            : 'Collaborative focus points agreed for the interval until the next consultation.');

  String get followUpWindowLabel => isArabic
      ? 'موعد المتابعة القادم'
      : (isFrench ? 'FENÊTRE DE SUIVI' : 'FOLLOW-UP HORIZON');

  String get followUpNoneLabel =>
      isArabic ? 'مفتوح' : (isFrench ? 'Flexible' : 'Open');

  String get focusItemsSectionLabel => isArabic
      ? 'أولويات المتابعة (اختر نقطة أو أكثر)'
      : (isFrench ? 'AXES CONVENUS (CHOIX RAPIDE)' : 'AGREED FOCUS AREAS');

  String get customFocusItemHint => isArabic
      ? 'أضف نقطة خاصة من الجلسة... (اختياري)'
      : (isFrench
            ? 'Ajouter un repère spécifique... (optionnel)'
            : 'Add a custom focus item... (optional)');

  String get observationCueLabel => isArabic
      ? 'ملاحظة للمرافقة بين المواعيد (اختياري)'
      : (isFrench
            ? 'NOTE D’OBSERVATION (OPTIONNEL)'
            : 'OBSERVATION CUE (OPTIONAL)');

  String get observationCueHint => isArabic
      ? 'مثلاً: لاحظ وقتاش ينقص التوتر بعد المغرب...'
      : (isFrench
            ? 'ex. Observer si l’apaisement du soir suit la coupure d’écran...'
            : 'e.g., Notice what helps settle evening tension before sleep...');

  String get generateCarePlanCodeBtn => isArabic
      ? 'إنشاء رمز خطة مشفّر'
      : (isFrench
            ? 'Générer un code plan chiffré'
            : 'Generate Encrypted Focus Code');

  String get sendFocusToPatientDeviceBtn => isArabic
      ? 'إرسال مباشرة لفضاء المريض على هذا الجهاز'
      : (isFrench
            ? 'Envoyer à l’espace patient local'
            : 'Deliver to Patient Workspace on This Device');

  String get focusDeliveredSnackbar => isArabic
      ? 'تم إرسال خطة التركيز إلى الصفحة الرئيسية للمريض.'
      : (isFrench
            ? 'Plan de suivi affiché dans l’accueil patient.'
            : 'Between-session focus delivered to Patient Home.');

  String get carePlanCodeCopiedSnackbar => isArabic
      ? 'تم نسخ رمز خطة التركيز المشفّر.'
      : (isFrench
            ? 'Code de plan chiffré copié.'
            : 'Encrypted focus plan code copied.');

  String get focusPresetSleepWindow => isArabic
      ? 'مراقبة ساعة النوم والاستيقاظ'
      : (isFrench
            ? 'Suivre le rythme veille / sommeil'
            : 'Note sleep & wake timing daily');

  String get focusPresetEveningLog => isArabic
      ? 'تسجيل لحظة المساء في التتبّع'
      : (isFrench
            ? 'Enregistrer un moment en soirée'
            : 'Log an evening mood check-in');

  String get focusPresetGroundingPause => isArabic
      ? 'وقفة تنفّس قصيرة وقت الضغط'
      : (isFrench
            ? 'Pause respiration courte en cas de pic'
            : 'Try a short breathing pause during spikes');

  String get focusPresetEnergyPattern => isArabic
      ? 'ملاحظة الطاقة بين الصباح والعشية'
      : (isFrench
            ? 'Comparer l’énergie matin vs soir'
            : 'Track morning vs evening energy');

  String get focusPresetThoughtLoop => isArabic
      ? 'تسمية فكرة مكررة بدون حكم'
      : (isFrench
            ? 'Nommer une rumination en fait / hypothèse'
            : 'Sort a recurring loop using Fact vs Assumption');

  String get focusPresetWhatHelped => isArabic
      ? 'تدوين حاجة صغيرة عاونتك كل نهار'
      : (isFrench
            ? 'Noter ce qui a apaisé la journée'
            : 'Capture one thing that helped steady the day');

  String get importCareFocusTitle => isArabic
      ? 'إضافة خطة تركيز من الطبيب'
      : (isFrench
            ? 'Importer un plan du psychiatre'
            : 'Import Focus Plan from Psychiatrist');

  String get importCareFocusSub => isArabic
      ? 'فكّ تشفير رمز MF-CAREPLAN-V1 من استشارتك'
      : (isFrench
            ? 'Déchiffrer un code MF-CAREPLAN-V1 reçu en consultation'
            : 'Decrypt an MF-CAREPLAN-V1 focus card from your visit');

  String get importCareFocusSubtitle => isArabic
      ? 'ألصق الرمز وكلمة السر باش تظهر أولويات الجلسة في الصفحة الرئيسية.'
      : (isFrench
            ? 'Collez le code reçu et la phrase secrète pour afficher vos repères sur l’accueil.'
            : 'Paste the care plan code and shared passphrase to pin your agreed focus points on Home.');

  String get carePlanCodeFieldLabel => isArabic
      ? 'رمز خطة التركيز (MF-CAREPLAN-V1:...)'
      : (isFrench ? 'Code plan de suivi' : 'Focus Plan Code');

  String get carePlanCodeFieldHint => 'MF-CAREPLAN-V1:...';

  String get carePlanImportedSnackbar => isArabic
      ? 'تمت إضافة خطة التركيز إلى الصفحة الرئيسية.'
      : (isFrench
            ? 'Plan de suivi activé sur votre accueil.'
            : 'Focus plan added to Home.');

  String get betweenSessionFocusTitle => isArabic
      ? 'تركيز بين الجلسات'
      : (isFrench ? 'REPERES ENTRE SEANCES' : 'BETWEEN-SESSION FOCUS');

  String fromClinicianByline(String name) {
    if (isArabic) return 'من $name';
    if (isFrench) return 'Avec $name';
    return 'Agreed with $name';
  }

  String followUpInDaysBadge(int days) {
    if (isArabic) return 'الموعد خلال $days ي';
    if (isFrench) return 'Suivi dans ${days}j';
    return 'Visit in ${days}d';
  }

  String get followUpTodayBadge =>
      isArabic ? 'موعد اليوم' : (isFrench ? 'Visite prévue' : 'Visit due');

  String get observationCueBadge => isArabic
      ? 'ملاحظة للتتبّع'
      : (isFrench ? 'Repère d’observation' : 'Observation note');

  String get dismissFocusBtn => isArabic
      ? 'إخفاء البطاقة'
      : (isFrench ? 'Masquer cette carte' : 'Dismiss focus card');

  String get clearFocusBtn =>
      isArabic ? 'مسح الخطة' : (isFrench ? 'Effacer le plan' : 'Clear plan');

  // ---------------------------------------------------------------------------
  // Milestone 4.3: Optional Daily Context & Routine Tags
  // ---------------------------------------------------------------------------

  String get dailyContextTagsLabel => isArabic
      ? 'روتين وسياق اليوم (اختياري)'
      : (isFrench
            ? 'Contexte & routine du jour (optionnel)'
            : 'Daily routine & context (optional)');

  String get dailyContextSectionTitle => isArabic
      ? 'ارتباطات السياق والروتين'
      : (isFrench
            ? 'CONTEXTE QUOTIDIEN & OBSERVATIONS'
            : 'DAILY CONTEXT & ROUTINE LINKS');

  String get dailyContextCorrelationSub => isArabic
      ? 'مقارنة إحصائية لما يرافق أيامك — ملاحظة وصفية فقط.'
      : (isFrench
            ? 'Moyennes observées avec chaque repère — simple observation statistique.'
            : 'Observed averages co-occurring with each tag — purely descriptive.');

  // ---------------------------------------------------------------------------
  // Milestone 5.1: Empirical Recovery Ledger (Observed Stabilizers)
  // ---------------------------------------------------------------------------

  String get observedStabilizersTitle => isArabic
      ? 'شنوة يعاونك ترتاح'
      : (isFrench
            ? 'Ce qui vous fait du bien'
            : 'What helps you feel better');

  String get observedStabilizersSub => isArabic
      ? 'أفعال وعادات رافقت تراجع التوتر أو توازناً أفضل في تسجيلاتك.'
      : (isFrench
            ? 'Actions et routines ayant accompagné un apaisement dans vos journaux.'
            : 'Self-reported actions and routines linked with calmer shifts in your logs.');

  String get stabilizerDisclaimer => isArabic
      ? 'ملاحظة وصفية مبنية على معطياتك الذاتية فقط — وليست وصفة طبية.'
      : (isFrench
            ? 'Observation descriptive issue de vos données — pas une prescription.'
            : 'Descriptive observation from your own check-ins — not medical advice.');

  String sameDayShiftStat(double delta) {
    final formatted = delta.toStringAsFixed(1);
    if (isArabic) return 'متوسط $formatted/10 في نفس اليوم';
    if (isFrench) return 'moy. $formatted/10 le même jour';
    return 'avg $formatted/10 same-day shift';
  }

  String stabilizerAvgMoodStat(double avg) {
    if (avg <= 4.5) {
      if (isArabic) return 'غالباً في أيام هادية';
      if (isFrench) return 'Souvent les jours calmes';
      return 'Often on calmer days';
    }
    if (avg <= 6.5) {
      if (isArabic) return 'أيام متوازنة';
      if (isFrench) return 'Journées plutôt stables';
      return 'Usually steady days';
    }
    if (isArabic) return 'عاونك في اللحظات الصعيبة';
    if (isFrench) return 'Utile dans les moments lourds';
    return 'Helpful on heavier moments';
  }

  // ---------------------------------------------------------------------------
  // Milestone 5.2: Visit-to-Visit Clinical Diff & 2-Min Pre-Visit Brief
  // ---------------------------------------------------------------------------

  String get preVisitBriefTitle => isArabic
      ? 'ملخص تحضير الزيارة (دقيقتين)'
      : (isFrench ? 'Préparation de visite (2 min)' : '2-Minute Visit Brief');

  String get preVisitBriefSubtitle => isArabic
      ? 'تجميع وصفي من تسجيلاتك باش تبدأ الجلسة بأهم المعطيات.'
      : (isFrench
            ? 'Synthèse automatique de vos observations pour démarrer votre consultation.'
            : 'Auto-synthesized highlights from your logs to make every visit count.');

  String get prepareForVisitBtn => isArabic
      ? 'تحضير للزيارة'
      : (isFrench ? 'Préparer la visite' : 'Prepare for Visit');

  String get focusPlanProgressLabel => isArabic
      ? 'خطة التركيز بين الجلسات'
      : (isFrench ? 'SUIVI DU PLAN D’ENTRETIEN' : 'FOCUS PLAN PROGRESS');

  String focusCompletedCountLabel(int done, int total) {
    if (isArabic) return '$done من $total مكتمل';
    if (isFrench) return '$done sur $total réalisé(s)';
    return '$done of $total completed';
  }

  String get focusFeedbackHelpful =>
      isArabic ? 'عاوني برشا' : (isFrench ? 'Utile' : 'Felt helpful');

  String get focusFeedbackTooHeavy => isArabic
      ? 'ثقيل شوية توّا'
      : (isFrench ? 'Trop lourd actuellement' : 'Too heavy right now');

  String get focusFeedbackAdjust => isArabic
      ? 'نحبّ نعدّلو مع الطبيب'
      : (isFrench ? 'À ajuster ensemble' : 'Want to adjust');

  String get continueToShareBtn => isArabic
      ? 'متابعة للمشاركة مع الطبيب'
      : (isFrench
            ? 'Continuer vers le partage'
            : 'Continue to Share with Psychiatrist');

  String get sinceLastVisitTitle => isArabic
      ? 'مقارنة منذ آخر زيارة'
      : (isFrench ? 'Depuis la dernière visite' : 'Since last visit');

  String visitIntervalBadge(int days) {
    if (isArabic) return 'خلال $days ي';
    if (isFrench) return '${days}j d’intervalle';
    return '${days}d apart';
  }

  String get focusFeedbackClinicianLabel => isArabic
      ? 'تقييم المريض لخطة التركيز'
      : (isFrench ? 'Retour sur le plan' : 'Focus plan feedback');

  String get addedContextsLabel => isArabic
      ? 'عوامل جديدة ظهرت'
      : (isFrench ? 'Nouveaux repères apparus' : 'Newly observed');

  String get reducedContextsLabel => isArabic
      ? 'عوامل تراجعت'
      : (isFrench ? 'Repères en recul' : 'Less frequent');

  // ---------------------------------------------------------------------------
  // Milestone 5.3: Zero-Cloud In-Room QR Handoff & Printable A4 Clinical Brief PDF
  // ---------------------------------------------------------------------------

  String get showInRoomQrBtn => isArabic
      ? 'إظهار رمز QR في العيادة'
      : (isFrench ? 'Afficher QR en cabinet' : 'Show In-Room QR');

  String get hideInRoomQrBtn =>
      isArabic ? 'إخفاء رمز QR' : (isFrench ? 'Masquer QR' : 'Hide QR Code');

  String get inRoomQrPinReminder => isArabic
      ? 'خلّي الطبيب يسكانّي الرمز وعطيه كلمة السر شفهياً — المعطيات ما تمشيش للسيرفر.'
      : (isFrench
            ? 'Le praticien scanne ce QR puis vous saisissez votre phrase secrète — zéro cloud.'
            : 'Let your psychiatrist scan this QR and enter your verbal room PIN — zero cloud.');

  String get qrCapacityExceededNote => isArabic
      ? 'حجم الحزمة أكبر من طاقة QR؛ استعمل نسخ الرمز المشفّر.'
      : (isFrench
            ? 'Paquet trop volumineux pour un seul QR ; utilisez la copie chiffrée.'
            : 'Packet exceeds single-QR byte capacity; copy the encrypted text code instead.');

  String get pasteFromClipboardBtn => isArabic
      ? 'لصق من الحافظة'
      : (isFrench ? 'Coller du presse-papiers' : 'Paste from Clipboard');

  String get previewClinicalBriefBtn => isArabic
      ? 'معاينة ملخص الزيارة PDF (A4)'
      : (isFrench ? 'Aperçu synthèse PDF (A4)' : 'Preview Printable A4 Brief');

  String get clinicalBriefTitle => isArabic
      ? 'ملخص استشارة سريري (A4)'
      : (isFrench
            ? 'Synthèse clinique A4'
            : 'Printable Consultation Brief (A4)');

  String get clinicalBriefSubtitle => isArabic
      ? 'وثيقة وصفية غير تشخيصية جاهزة للطباعة أو المشاركة.'
      : (isFrench
            ? 'Document descriptif non diagnostique prêt pour la consultation.'
            : 'Observational, non-diagnostic 1-page summary ready for clinical visits.');

  String get savePdfBriefBtn => isArabic
      ? 'حفظ ملف A4 PDF'
      : (isFrench ? 'Enregistrer en PDF A4' : 'Save A4 PDF');

  String get copyClinicalTextBtn => isArabic
      ? 'نسخ النص السريري'
      : (isFrench ? 'Copier le texte clinique' : 'Copy Clinical Text');

  String pdfSavedSnackbar(String fileName) {
    if (isArabic) return 'تم حفظ الملف: $fileName';
    if (isFrench) return 'PDF enregistré : $fileName';
    return 'Saved A4 PDF: $fileName';
  }

  // ---------------------------------------------------------------------------
  // Milestone 5.4: Forensic Loop Map
  // ---------------------------------------------------------------------------

  String get forensicLoopMapTitle => isArabic
      ? 'كيفاش تتسلسل اللحظة الصعيبة'
      : (isFrench
            ? 'Comment un moment difficile s’enchaîne'
            : 'How a tough moment unfolds');

  String get forensicLoopMapSub => isArabic
      ? 'العلاقة بين الموقف، الإحساس، الفكرة وشنوة اللّي يهدّيك.'
      : (isFrench
            ? 'Lien entre situation, émotion, pensée et ce qui apaise.'
            : 'How events, feelings, thoughts, and helpful habits connect.');

  String get forensicLoopNodeTrigger => isArabic
      ? 'السياق أو المحفّز المتكرر'
      : (isFrench ? 'Contexte ou déclencheur' : 'Recurring context / trigger');

  String get forensicLoopNodeAffect => isArabic
      ? 'التوقيت والشعور المصاحب'
      : (isFrench ? 'Rythme & vécu affectif' : 'Diurnal & affect pattern');

  String get forensicLoopNodeThought => isArabic
      ? 'الفكرة في السلسلة'
      : (isFrench ? 'Chaîne cognitive partagée' : 'Observed thought chain');

  String get forensicLoopNodeStabilizer => isArabic
      ? 'شنوة عاونك'
      : (isFrench
            ? 'Ce qui a aidé'
            : 'What helped');

  String forensicLoopNodesBadge(int count) => '$count/4';

  String get forensicLoopDisclaimer => isArabic
      ? 'ربط وصفي من تسجيلاتك فقط للمراجعة الواضحة — ليس تشخيصاً طبياً.'
      : (isFrench
            ? 'Synthèse descriptive de vos observations — ne constitue pas un diagnostic médical.'
            : 'Descriptive synthesis of recorded logs for clear review — not a medical diagnosis.');

  // ---------------------------------------------------------------------------
  // Milestone 6.1: Native PDF Share Sheet & In-Room Camera QR Scanner
  // ---------------------------------------------------------------------------

  String get sharePdfBriefBtn => isArabic
      ? 'مشاركة / طباعة A4 PDF'
      : (isFrench ? 'Partager / Imprimer PDF A4' : 'Share / Print A4 PDF');

  String get pdfShareSubject => isArabic
      ? 'Mindora — ملخص استشارة سريري (A4)'
      : (isFrench
            ? 'Mindora — Synthèse clinique A4'
            : 'Mindora — Clinical Consultation Brief (A4)');

  String get scanInRoomQrBtn => isArabic
      ? 'مسح رمز QR داخل العيادة'
      : (isFrench ? 'Scanner QR en cabinet' : 'Scan In-Room QR');

  String get qrScannerTitle => isArabic
      ? 'قارئ رمز النقل المشفّر'
      : (isFrench ? 'Scanner de transfert chiffré' : 'Encrypted Handoff QR');

  String get qrScannerSubtitle => isArabic
      ? 'وجّه الكاميرا نحو رمز QR — الفك يتم محلياً بدون خادم.'
      : (isFrench
            ? 'Visez le QR Mindora — lecture locale sans cloud.'
            : 'Point your camera at a Mindora QR code — stays offline.');

  String qrScannerWrongPrefixError(String expectedPrefix) {
    if (isArabic) {
      return 'هذا الرمز ليس حزمة Mindora متوقعة ($expectedPrefix).';
    }
    if (isFrench) {
      return 'Ce QR ne correspond pas au préfixe attendu ($expectedPrefix).';
    }
    return 'Not a matching Mindora handoff QR ($expectedPrefix).';
  }

  String get qrScannerUnsupportedNote => isArabic
      ? 'الكاميرا غير متوفرة على هذا الجهاز المكتبي — استعمل اللصق من الحافظة.'
      : (isFrench
            ? 'Caméra indisponible sur ce bureau — utilisez le collage depuis le presse-papiers.'
            : 'Camera preview is unavailable on this desktop target — use Paste from Clipboard.');

  String get qrScannerTorchTooltip => isArabic
      ? 'تشغيل أو إيقاف الإضاءة'
      : (isFrench ? 'Activer/couper la lampe' : 'Toggle torch');

  // ---------------------------------------------------------------------------
  // Milestone 7.1: Tactile 2D Orb Sculpting & 1-Tap Quick Note Sparks
  // ---------------------------------------------------------------------------

  String get orbTouchHint => isArabic
      ? 'اسحب فوق الدائرة أو اختر من الأسفل'
      : (isFrench
            ? 'Glissez sur l’orbe pour ajuster ou choisissez ci-dessous'
            : 'Glide on the orb to sculpt mood & intensity');

  String get quickSparksLabel => isArabic
      ? 'كلمات سريعة بضغطة وحدة (اختياري)'
      : (isFrench
            ? 'Notes rapides en un tap (optionnel)'
            : '1-tap note sparks (optional)');

  List<String> quickSparksForMood(String moodKey) {
    final norm = moodKey.trim().toLowerCase();
    if (isArabic) {
      return switch (norm) {
        'anxious' => const [
          'أفكار متسارعة',
          'ضغط خدمة',
          'محتاج نفس عميق',
          'حاسس بتوتر',
        ],
        'frustrated' => const [
          'برشا مطالب اليوم',
          'ما حسّيتش روحي مسموع',
          'تعب أعصاب',
          'محتاج شوية مساحة',
        ],
        'heavy' => const [
          'طاقتي طايحة اليوم',
          'ماشي بالشوية',
          'محتاج راحة',
          'نهار ثقيل شوية',
        ],
        'restless' => const [
          'تركيز مشتّت',
          'شاشات متأخرة',
          'طاقة زايدة بلا هدوء',
          'صعيب نرتاح توّة',
        ],
        _ => const [
          'لحظة هادية',
          'نوم مريح',
          'تركيز ثابت',
          'مرتاح اليوم',
        ],
      };
    }
    if (isFrench) {
      return switch (norm) {
        'anxious' => const [
          'Pensées rapides',
          'Pression du travail',
          'Besoin de souffler',
          'Tendu à l’avance',
        ],
        'frustrated' => const [
          'Trop de demandes',
          'Pas senti écouté',
          'Limite dépassée',
          'Besoin d’espace',
        ],
        'heavy' => const [
          'Batterie basse',
          'J’y vais doucement',
          'Besoin de repos',
          'Journée lourde',
        ],
        'restless' => const [
          'Esprit dispersé',
          'Écrans tardifs',
          'Trop d’élan intérieur',
          'Dur de poser',
        ],
        _ => const [
          'Moment paisible',
          'Bien dormi',
          'Énergie stable',
          'Reconnaissant',
        ],
      };
    }
    return switch (norm) {
      'anxious' => const [
        'Mind racing',
        'Work pressure',
        'Need a breather',
        'Uncertain ahead',
      ],
      'frustrated' => const [
        'Too many demands',
        'Felt unheard',
        'Boundary crossed',
        'Need space',
      ],
      'heavy' => const [
        'Low battery today',
        'Taking it slow',
        'Need rest',
        'Quietly holding on',
      ],
      'restless' => const [
        'Scattered focus',
        'Late screens',
        'High restless energy',
        'Hard to settle',
      ],
      _ => const [
        'Peaceful moment',
        'Slept well',
        'Steady energy',
        'Grateful today',
      ],
    };
  }

  // ---------------------------------------------------------------------------
  // Milestone 7.2: Elder-Friendly Somatic Steppers, Presets & Micro-Mirror
  // ---------------------------------------------------------------------------

  String get sleepPresetShortLabel =>
      isArabic ? 'أقل من 6س' : (isFrench ? '<6h' : '<6h');

  String get sleepPreset7hLabel => isArabic ? '7س' : '7h';

  String get sleepPreset8hLabel => isArabic ? '8س' : '8h';

  String get sleepPreset9hLabel => isArabic ? '9س+' : '9h+';

  String sliderDecreaseLabel(String metricName) => isArabic
      ? 'إنقاص $metricName'
      : (isFrench ? 'Diminuer $metricName' : 'Decrease $metricName');

  String sliderIncreaseLabel(String metricName) => isArabic
      ? 'زيادة $metricName'
      : (isFrench ? 'Augmenter $metricName' : 'Increase $metricName');

  String microMirrorCalmerShift(int dropPoints) {
    if (isArabic) {
      return 'تم تسجيل هدوء ملحوظ (-$dropPoints نقاط) مقارنة ببداية اليوم.';
    }
    if (isFrench) {
      return 'Apaisement observé (-$dropPoints pts) par rapport à plus tôt aujourd’hui.';
    }
    return 'Calmer shift observed (-$dropPoints pts) compared to earlier today.';
  }

  String microMirrorMomentCount(int count) {
    if (isArabic) {
      return 'تم توثيق اللحظة رقم $count اليوم — متابعة لطيفة لتغيّر يومك.';
    }
    if (isFrench) {
      return 'Moment n°$count noté aujourd’hui — vous observez l’évolution de votre journée.';
    }
    return 'Moment #$count logged today — gently mapping how your day unfolds.';
  }

  String microMirrorWeeklyRhythm(int daysCount) {
    if (isArabic) {
      if (daysCount == 1) return 'يوم واحد مسجّل هذا الأسبوع — خطوة أولى هادية نحو الوضوح.';
      if (daysCount == 2) return 'يومان مسجّلان هذا الأسبوع — إيقاعك الشخصي بدأ يتوضّح.';
      if (daysCount <= 10) return '$daysCount أيام مسجّلة هذا الأسبوع — إيقاعك الشخصي بدأ يتوضّح.';
      return '$daysCount يوماً مسجّلة هذا الأسبوع — إيقاعك الشخصي بدأ يتوضّح.';
    }
    if (isFrench) {
      return '$daysCount ${daysCount == 1 ? 'jour observé' : 'jours observés'} cette semaine — votre rythme personnel se dessine.';
    }
    return '$daysCount ${daysCount == 1 ? 'day' : 'days'} observed this week — your personal rhythm is taking shape.';
  }

  String get microMirrorFirstMoment => isArabic
      ? 'تم حفظ اللحظة — الملاحظة الصادقة تبني الوضوح خطوة بخطوة.'
      : (isFrench
            ? 'Moment enregistré — chaque observation honnête éclaire votre rythme.'
            : 'Moment captured — honest check-ins gently build self-clarity.');

  // ---------------------------------------------------------------------------
  // Milestone 7.3: Non-Punitive Discovery Milestones & Generative Mood Aura
  // ---------------------------------------------------------------------------

  String get discoveryMilestonesTitle => isArabic
      ? 'محطات الاكتشاف الشخصية'
      : (isFrench ? 'Repères de découverte' : 'Discovery milestones');

  String get discoveryMilestonesSub => isArabic
      ? 'تقدّم تراكمي لا يضيع أبداً حتى لو غبت أياماً.'
      : (isFrench
            ? 'Progrès cumulatif — aucune pause ne réinitialise votre parcours.'
            : 'Cumulative self-clarity — missing days never resets what you learned.');

  String discoveryBadgeCount(int unlocked, int total) => '$unlocked/$total';

  String get milestoneFirstTitle => isArabic
      ? 'أول بصمة'
      : (isFrench ? 'Première empreinte' : 'First Footprint');

  String get milestoneFirstSub => isArabic
      ? 'أول تسجيل يومي'
      : (isFrench ? 'Premier point noté' : 'First check-in saved');

  String get milestoneNuanceTitle => isArabic
      ? 'تسمية دقيقة'
      : (isFrench ? 'Nuances fines' : 'Nuance Finder');

  String get milestoneNuanceSub => isArabic
      ? '3 مشاعر فرعية'
      : (isFrench ? '3 vécus détaillés' : '3+ nuanced feelings');

  String get milestoneIntradayTitle => isArabic
      ? 'نبض اليوم'
      : (isFrench ? 'Variation du jour' : 'Day-to-Night Shift');

  String get milestoneIntradaySub => isArabic
      ? 'لحظتان في نفس اليوم'
      : (isFrench ? '2 moments un même jour' : 'Multi-moment check-in');

  String get milestoneStabilizerTitle => isArabic
      ? 'مرساة التهدئة'
      : (isFrench ? 'Ancrage repéré' : 'Anchor Found');

  String get milestoneStabilizerSub => isArabic
      ? 'لقيت حاجة تريّحك'
      : (isFrench
            ? 'Repère apaisant trouvé'
            : 'Found what helps');

  String get milestoneSevenDaysTitle => isArabic
      ? '7 أيام وعي'
      : (isFrench ? '7 jours observés' : '7 Rhythm Days');

  String get milestoneSevenDaysSub => isArabic
      ? 'إجمالي أيام تراكمية'
      : (isFrench ? 'Jours cumulés au total' : 'Cumulative logged days');

  String get openMoodAuraBtn => isArabic
      ? 'معاينة ومشاركة هالة المزاج'
      : (isFrench ? 'Voir & partager mon Aura' : 'View & Share Mood Aura');

  String get moodAuraTitle => isArabic
      ? 'ملصق هالة المزاج'
      : (isFrench ? 'Poster Aura personnelle' : 'Personal Mood Aura');

  String get moodAuraSubtitle => isArabic
      ? 'لوحة فنية لألوان إيقاعك بدون أي نصوص أو ملاحظات شخصية.'
      : (isFrench
            ? 'Œuvre générative de vos couleurs récentes — zéro note privée incluse.'
            : 'Generative artwork of your mood colors — zero private notes or triggers.');

  String get moodAuraHeader => isArabic
      ? 'Mindora · إيقاع الوعي الشخصي'
      : (isFrench
            ? 'Mindora · Aura de rythme personnel'
            : 'Mindora · Personal Rhythm Aura');

  String get moodAuraPrivateNotice => isArabic
      ? 'خاص بالكامل: يحتوي فقط على ألوان المزاج والأيام الملاحظة.'
      : (isFrench
            ? 'Confidentiel : affiche uniquement couleurs et rythme, jamais vos notes.'
            : 'Privacy-safe keepsake: exports color harmonies and rhythm only.');

  String moodAuraDaysLabel(int days) {
    if (isArabic) return '$days أيام ملاحظة';
    if (isFrench) return '$days j. observés';
    return '$days observed days';
  }

  String moodAuraMilestonesLabel(int unlocked, int total) {
    if (isArabic) return '$unlocked/$total محطات اكتشاف';
    if (isFrench) return '$unlocked/$total repères';
    return '$unlocked/$total milestones';
  }

  String get shareMoodAuraBtn => isArabic
      ? 'مشاركة صورة الهالة'
      : (isFrench ? 'Partager l’Aura PNG' : 'Share Mood Aura');

  String get saveMoodAuraBtn => isArabic
      ? 'حفظ الصورة محلياً'
      : (isFrench ? 'Enregistrer l’image' : 'Save Image');

  String moodAuraSavedSnackbar(String fileName) {
    if (isArabic) return 'تم حفظ صورة الهالة: $fileName';
    if (isFrench) return 'Image enregistrée : $fileName';
    return 'Saved Mood Aura: $fileName';
  }

  String get moodAuraShareSubject => isArabic
      ? 'Mindora — هالة إيقاعي الشخصي'
      : (isFrench
            ? 'Mindora — Mon Aura personnelle'
            : 'Mindora — Personal Mood Aura');

  String get moodAuraShareText => isArabic
      ? 'هالة ألوان إيقاعي الشخصي في Mindora (بدون أي ملاحظات خاصة).'
      : (isFrench
            ? 'Mon poster d’aura généré localement avec Mindora.'
            : 'My personal harmonic Mood Aura created locally in Mindora.');

  String get comfortModeTitle => isArabic
      ? 'وضع الراحة والوضوح البصري'
      : (isFrench ? 'Mode Confort & Clarté' : 'Comfort & Clarity Mode');

  String get comfortModeSub => isArabic
      ? 'خط أوضح وأكبر (+15%) وحدود أنقى لراحة العين في كل وقت'
      : (isFrench
            ? 'Texte agrandi (+15 %) et contours plus nets pour un confort de lecture optimal'
            : 'Larger readable text (+15%) and crisper borders for tired eyes or brighter rooms');

  String get comfortModeOnboardingHint => isArabic
      ? 'تحب خط أكبر وتباين أوضح؟ تنجم تفعّلو بضغطة وحدة.'
      : (isFrench
            ? 'Préférez-vous un texte plus grand et plus net ? Activez-le en un geste.'
            : 'Prefer larger text and crisper contrast? Toggle anytime in 1 tap.');

  // Phase 8.1 — Context-Aware Handoff Bridge (Check-In & Focus Plan -> Companion)
  String get companionBridgeTitle => isArabic
      ? 'مواصلة من تسجيلك اليوم'
      : (isFrench ? 'Depuis votre point du jour' : 'From today’s check-in');

  String get companionBridgeUnpackBtn => isArabic
      ? 'نفكّك شعور اليوم مع بعضنا'
      : (isFrench ? 'Explorer ce ressenti ensemble' : 'Unpack today’s check-in');

  String get companionBridgeSettleFirstBtn => isArabic
      ? 'تهدئة سريعة (دقيقتين)'
      : (isFrench ? 'S’apaiser d’abord (2 min)' : 'Settle first (2 min)');

  String companionBridgeFocusChip(String goalTitle) {
    if (isArabic) return 'تأمل في هدف المتابعة: $goalTitle';
    if (isFrench) return 'Explorer votre objectif : $goalTitle';
    return 'Reflect on care focus: $goalTitle';
  }

  String companionBridgePrompt({
    required String moodLabel,
    required int intensity,
    required List<String> tagLabels,
    required String note,
  }) {
    final tagSuffix = tagLabels.isEmpty ? '' : ' (${tagLabels.join(', ')})';
    final cleanNote = note.trim();
    if (isArabic) {
      final base =
          'سجّلت اليوم شعور "$moodLabel" بحدّة $intensity/10$tagSuffix.';
      if (cleanNote.isEmpty) {
        return '$base نحب نفهم شنية اللي صار بهدوء خطوة بخطوة.';
      }
      return '$base وملاحظتي: "$cleanNote". نحب نفكّك الفكرة معاك بهدوء.';
    }
    if (isFrench) {
      final base =
          'J’ai noté aujourd’hui un état « $moodLabel » ($intensity/10)$tagSuffix.';
      if (cleanNote.isEmpty) {
        return '$base Aidons-nous à démêler ce moment calmement.';
      }
      return '$base Ma note : « $cleanNote ». Aidons-nous à clarifier ce qui se passe.';
    }
    final base =
        'Today I logged feeling $moodLabel ($intensity/10)$tagSuffix.';
    if (cleanNote.isEmpty) {
      return '$base Help me untangle what is going on calmly, step by step.';
    }
    return '$base My note: "$cleanNote". Help me unpack this calmly.';
  }

  String companionBridgeFocusPrompt(String goalTitle) {
    if (isArabic) return 'خلّينا نشوفوا خطوة الطبيب: "$goalTitle". شنوة أبسط بداية اليوم؟';
    if (isFrench) return 'Voyons l’étape « $goalTitle ». Quel petit pas faire aujourd’hui ?';
    return 'Let’s look at my doctor’s step: "$goalTitle". What’s one easy start today?';
  }

  // Phase 8.2 — Zero-Typing Thought Sorter & Context-Aware Reply Sparks
  String get companionSparkFindFact => isArabic
      ? 'خلّينا نفرّقو بين الحقيقة والظنّ'
      : (isFrench
            ? 'Séparer le fait observable'
            : 'Separate the observable fact');

  String get companionSparkOtherAngle => isArabic
      ? 'اعطيني زاوية ثانية هادية'
      : (isFrench
            ? 'Voir un autre angle calme'
            : 'Show another calm angle');

  String get companionSparkKeepBrief => isArabic
      ? 'اختصرلي — تاعب شويّة اليوم'
      : (isFrench
            ? 'Fais court — je suis fatigué'
            : 'Keep it brief — I’m tired');

  // Phase 8.3 — Closed-Loop Relief Micro-Check -> Observed Stabilizers
  String get reliefCheckQuestion => isArabic
      ? 'حسّيت بالتوتّر خفّ شويّة؟'
      : (isFrench
            ? 'La tension a-t-elle un peu baissé ?'
            : 'Did the tension soften?');

  String get reliefCheckCalmer => isArabic
      ? 'أهدى توّة'
      : (isFrench ? 'Plus calme' : 'Calmer now');

  String get reliefCheckSlightly => isArabic
      ? 'شويّة'
      : (isFrench ? 'Un peu' : 'A little');

  String get reliefCheckNotYet => isArabic
      ? 'مازال شويّة'
      : (isFrench ? 'Pas encore' : 'Not yet');

  String get reliefLoggedConfirm => isArabic
      ? 'تزاد لـ شنوة يعاونك ترتاح'
      : (isFrench
            ? 'Ajouté à Ce qui vous fait du bien'
            : 'Saved to What helps you');

  String get reliefNotYetAck => isArabic
      ? 'عادي برشا، تنجّم تجرّب تمرين ثاني هادي وقت ما تحب.'
      : (isFrench
            ? 'C’est tout à fait normal. Vous pouvez essayer une autre option douce si vous le souhaitez.'
            : 'That is completely okay. You can try another calm option whenever you want.');

  String reliefTryAlternativeBtn(String alt) {
    if (isArabic) return 'جرّب: $alt';
    if (isFrench) return 'Essayer : $alt';
    return 'Try $alt';
  }

  // Phase 8.4 — Pocket Clarity Anchor Cards
  String get clarityAnchorTitle => isArabic
      ? 'بطاقة التوازن والوضوح'
      : (isFrench ? 'Carte d’ancrage de clarté' : 'Pocket Clarity Anchor');

  String get clarityAnchorSub => isArabic
      ? 'مرجعك الهادي وقت يرجعلك موقف يشبهلو.'
      : (isFrench
            ? 'Votre repère calme lorsqu’un moment similaire revient.'
            : 'Your calm reference when a similar moment returns.');

  String get clarityAnchorFactLabel => isArabic
      ? 'اللي صار بالحق'
      : (isFrench ? 'Fait observable' : 'Observed fact');

  String get clarityAnchorJumpLabel => isArabic
      ? 'الظنّ اللي طلع'
      : (isFrench ? 'Saut de pensée' : 'Mind’s jump');

  String get clarityAnchorGroundedLabel => isArabic
      ? 'النظرة الهادية'
      : (isFrench ? 'Perspective ancrée' : 'Grounded perspective');

  String get pocketAnchorsSectionTitle => isArabic
      ? 'بطاقات الوضوح متاعك'
      : (isFrench ? 'Vos cartes de clarté' : 'Pocket Clarity Anchors');


  // =========================================================================
  // Phase 9–13 — Cross-Generational Plain Language & UX Overhaul Strings
  // =========================================================================

  String get moodGood =>
      isArabic ? 'لباس وفرحان' : (isFrench ? 'Bien' : 'Good');

  String get moodWorriedPlain =>
      isArabic ? 'قلقان' : (isFrench ? 'Inquiet' : 'Worried');

  String get moodAnnoyedPlain =>
      isArabic ? 'متنرفز' : (isFrench ? 'Agacé' : 'Annoyed');

  String get moodLowPlain =>
      isArabic ? 'ثقيل وتاعب' : (isFrench ? 'Abattu' : 'Low');

  String get moodRestlessPlain =>
      isArabic ? 'مش ركح' : (isFrench ? 'Agité' : 'Restless');

  String get moodCalmPlain =>
      isArabic ? 'مرتاح وهادي' : (isFrench ? 'Calme' : 'Calm');

  String plainMoodLabel(String key) {
    final k = key.trim().toLowerCase();
    return switch (k) {
      'good' || 'happy' => moodGood,
      'calm' => moodCalmPlain,
      'anxious' || 'worried' => moodWorriedPlain,
      'frustrated' || 'annoyed' => moodAnnoyedPlain,
      'heavy' || 'low' => moodLowPlain,
      'restless' => moodRestlessPlain,
      _ => moodCalmPlain,
    };
  }

  String get howAreYouRightNow => isArabic
      ? 'كيفاش حاسس روحك توا؟'
      : (isFrench ? 'Comment vous sentez-vous ?' : 'How are you right now?');

  String get howStrongQuestion => isArabic
      ? 'قدّاش قوّتو؟'
      : (isFrench ? 'C’est fort comment ?' : 'How strong is it?');

  String get strengthALittle =>
      isArabic ? 'شويّة' : (isFrench ? 'Un peu' : 'A little');

  String get strengthMedium =>
      isArabic ? 'متوسّط' : (isFrench ? 'Moyen' : 'Medium');

  String get strengthALot =>
      isArabic ? 'برشا' : (isFrench ? 'Beaucoup' : 'A lot');

  String strengthWordForIntensity(int intensity) {
    if (intensity <= 4) return strengthALittle;
    if (intensity <= 7) return strengthMedium;
    return strengthALot;
  }

  String get undoBtn =>
      isArabic ? 'رجّع' : (isFrench ? 'Annuler' : 'Undo');

  String get skipBtn =>
      isArabic ? 'عدّي' : (isFrench ? 'Passer' : 'Skip');

  String get doneBtn =>
      isArabic ? 'تم' : (isFrench ? 'Terminé' : 'Done');

  String get stopBtn =>
      isArabic ? 'وقّف' : (isFrench ? 'Arrêter' : 'Stop');

  String get clearBtn =>
      isArabic ? 'مسح' : (isFrench ? 'Effacer' : 'Clear');

  String get deleteBtn =>
      isArabic ? 'حذف' : (isFrench ? 'Supprimer' : 'Delete');

  String get viewLabel =>
      isArabic ? 'شوف' : (isFrench ? 'Voir' : 'View');

  String get defaultFriendName =>
      isArabic ? 'صديقي' : (isFrench ? 'Ami' : 'Friend');

  // Navigation — Single-Job Plain Tab Labels
  String get navToday =>
      isArabic ? 'اليوم' : (isFrench ? 'Aujourd’hui' : 'Today');

  String get navMyDays =>
      isArabic ? 'أيامي' : (isFrench ? 'Mes jours' : 'My days');

  String get navTalk =>
      isArabic ? 'حوار' : (isFrench ? 'Parler' : 'Talk');

  String get navPatterns =>
      isArabic ? 'أنماطي' : (isFrench ? 'Repères' : 'Patterns');

  String get navMe =>
      isArabic ? 'أنا' : (isFrench ? 'Moi' : 'Me');

  // Today / Home Single-Job Copy
  String get addDetailsCta => isArabic
      ? '+ زيد النوم أو ملاحظة'
      : (isFrench
            ? '+ Ajouter sommeil ou note'
            : '+ Add sleep, tags or a note');

  String get takeOneMinuteBreather => isArabic
      ? 'خوذ دقيقة تنفّس هادي'
      : (isFrench
            ? 'Prendre 1 minute pour respirer'
            : 'Take a 1-minute breather');

  String get breatheQuickBtn =>
      isArabic ? 'تنفّس' : (isFrench ? 'Respirer' : 'Breathe');

  String get talkItOutBtn =>
      isArabic ? 'احكي عليها' : (isFrench ? 'En parler' : 'Talk it out');

  String get changeMoodLink =>
      isArabic ? 'بدّل' : (isFrench ? 'Changer' : 'Change');

  String get logNewMomentLink => isArabic
      ? '+ سجّل لحظة جديدة'
      : (isFrench ? '+ Autre moment' : '+ Log new moment');

  String youFeelTodayTitle(String moodLabel) {
    if (isArabic) return 'حاسس روحك $moodLabel اليوم';
    if (isFrench) return 'Vous vous sentez $moodLabel';
    return 'You feel $moodLabel today';
  }

  String daysThisWeekCount(int count) {
    if (isArabic) {
      if (count == 1) return 'يوم واحد';
      if (count == 2) return 'يومان';
      if (count >= 3 && count <= 10) return '$count أيام';
      return '$count يوم';
    }
    if (isFrench) return '$count ${count == 1 ? 'jour' : 'jours'}';
    return '$count ${count == 1 ? 'day' : 'days'}';
  }

  /// Formats [dt] into calm, human-readable text without raw database ISO codes.
  String formatHumanDate(DateTime dt, {DateTime? now}) {
    final ref = now ?? DateTime.now();
    final today = DateTime(ref.year, ref.month, ref.day);
    final target = DateTime(dt.year, dt.month, dt.day);
    final mLabel = monthName(dt.month);
    final shortDate = isArabic ? '${dt.day} $mLabel' : '${dt.day} $mLabel';
    final withYear = dt.year == ref.year ? shortDate : '$shortDate ${dt.year}';

    if (target == today) {
      return '$navToday · $shortDate';
    }
    if (target == today.subtract(const Duration(days: 1))) {
      final yday = isArabic ? 'البارح' : (isFrench ? 'Hier' : 'Yesterday');
      return '$yday · $shortDate';
    }
    return withYear;
  }

  /// Parses an ISO `YYYY-MM-DD` dateKey into friendly localized text.
  String formatHumanDateKey(String dateKey, {DateTime? now}) {
    final parsed = DateTime.tryParse(dateKey);
    if (parsed == null) return dateKey;
    return formatHumanDate(parsed, now: now);
  }

  /// Localized plain label for quick "what helped" chips stored by canonical key.
  String helpedOptionLabel(String key) {
    switch (key) {
      case 'Walk':
        return isArabic ? 'مشي خفيف' : (isFrench ? 'Marche' : 'Walk');
      case 'Breathing':
        return isArabic ? 'تنفّس' : (isFrench ? 'Respiration' : 'Breathing');
      case 'Quiet time':
        return isArabic ? 'وقت هادي' : (isFrench ? 'Temps calme' : 'Quiet time');
      case 'Talked':
        return isArabic ? 'حكيت مع حد' : (isFrench ? 'Parlé à quelqu’un' : 'Talked');
      case 'Rest':
        return isArabic ? 'راحة' : (isFrench ? 'Repos' : 'Rest');
      default:
        return key;
    }
  }

  String showAllCountLabel(int total) => isArabic
      ? 'عرض الكل ($total)'
      : (isFrench ? 'Voir tout ($total)' : 'Show all ($total)');

  String get showLessLabel =>
      isArabic ? 'عرض أقل' : (isFrench ? 'Voir moins' : 'Show less');

  String sessionsCountLabel(int n) {
    if (isArabic) {
      if (n == 1) return 'محادثة واحدة';
      if (n == 2) return 'محادثتان';
      if (n >= 3 && n <= 10) return '$n محادثات';
      return '$n محادثة';
    }
    if (isFrench) return '$n ${n == 1 ? 'échange' : 'échanges'}';
    return '$n ${n == 1 ? 'talk' : 'talks'}';
  }

  String get chooseFocusAreaHint => isArabic
      ? 'اختار موضوع أو لوج بالبحث على أي موضوع يهمّك'
      : (isFrench
            ? 'Choisissez un thème ou cherchez librement ci-dessus'
            : 'Pick a broad area below or search above');

  String selectedItemsCountLabel(int count) {
    if (isArabic) return '$count محدد';
    if (isFrench) return '$count sélectionné${count > 1 ? 's' : ''}';
    return '$count selected';
  }

  String get thisWeekHeader =>
      isArabic ? 'الجمعة هاذي' : (isFrench ? 'Cette semaine' : 'This week');

  // Progressive Details Sheet (1 Question Per Card)
  String stepProgressOf(int step, int total) {
    if (isArabic) return '$step من $total';
    if (isFrench) return '$step sur $total';
    return '$step of $total';
  }

  String get closerWordQuestion => isArabic
      ? 'فمّا كلمة أقرب لإحساسك؟'
      : (isFrench ? 'Un mot plus précis ?' : 'Any closer word for it?');

  String get howDidYouSleepQuestion => isArabic
      ? 'كيفاش رقدت الليلة الفايتة؟'
      : (isFrench ? 'Comment avez-vous dormi ?' : 'How did you sleep?');

  String get sleepUnder6 =>
      isArabic ? 'أقل من 6 س' : (isFrench ? 'Moins de 6h' : 'Under 6h');

  String get sleepAbout7 =>
      isArabic ? 'حوالي 7 س' : (isFrench ? 'Environ 7h' : 'About 7h');

  String get sleepAbout8 =>
      isArabic ? 'حوالي 8 س' : (isFrench ? 'Environ 8h' : 'About 8h');

  String get sleep9Plus =>
      isArabic ? '9 ساعات +' : (isFrench ? '9h ou plus' : '9h+');

  String get howIsYourEnergyQuestion => isArabic
      ? 'كيفاش طاقتك اليوم؟'
      : (isFrench ? 'Comment est votre énergie ?' : 'How is your energy?');

  String get energyLowLabel =>
      isArabic ? 'ضعيفة' : (isFrench ? 'Basse' : 'Low');

  String get energyOkayLabel =>
      isArabic ? 'لاباس' : (isFrench ? 'Correcte' : 'Okay');

  String get energyFullLabel =>
      isArabic ? 'قويّة' : (isFrench ? 'Pleine' : 'Full');

  String get whatWasPartOfTodayQuestion => isArabic
      ? 'شنوة كان جزء من نهارك؟'
      : (isFrench
            ? 'Qu’est-ce qui a marqué votre journée ?'
            : 'What was part of today?');

  String get quickNoteQuestion => isArabic
      ? 'تحب تزيد ملاحظة صغيرة؟ (اختياري)'
      : (isFrench
            ? 'Une petite note ? (facultatif)'
            : 'Anything to remember? (optional)');

  String get saveDetailsBtn => isArabic
      ? 'خزّن التفاصيل'
      : (isFrench ? 'Enregistrer' : 'Save details');

  String get detailsSavedToast => isArabic
      ? 'تخزّنت تفاصيل نهارك'
      : (isFrench ? 'Détails enregistrés' : 'Details saved');

  String get checkInRemovedUndo => isArabic
      ? 'تفسخت التسجيلة'
      : (isFrench ? 'Entrée supprimée' : 'Check-in removed');

  String get addCheckInForDayBtn => isArabic
      ? '+ سجّل لحظة للنهار هذا'
      : (isFrench ? '+ Ajouter pour ce jour' : '+ Log a moment for this day');

  // Talk Tab Plain Copy
  String talkSavedPill(int count) {
    if (isArabic) return 'محفوظة ($count)';
    if (isFrench) return 'Gardés ($count)';
    return 'Saved ($count)';
  }

  String get talkTrustStrip => isArabic
      ? 'محفوظ في تليفونك · مستوحى من CBT وموش علاج طبي'
      : (isFrench
            ? 'Privé sur ce téléphone · Inspiré des TCC, pas une thérapie'
            : 'Private on your phone · Inspired by CBT, not therapy');

  String get talkStarterPromptLabel => isArabic
      ? 'اختار موضوع ولا اكتب لتحت:'
      : (isFrench
            ? 'Touchez un sujet ou écrivez :'
            : 'Tap one to start, or write below:');

  String get talkStarterOverthinking => isArabic
      ? 'نخمّم برشا في حاجة'
      : (isFrench ? 'Je rumine quelque chose' : 'Overthinking something');

  String get talkStarterHeavy => isArabic
      ? 'حاسس بضيق وما عرفتش نسمّيه'
      : (isFrench ? 'Un poids difficile à nommer' : 'Heavy feeling I can’t name');

  String get talkStarterPeople => isArabic
      ? 'توتر مع شخص'
      : (isFrench ? 'Tension avec quelqu’un' : 'Tension with someone');

  String get talkStarterVent => isArabic
      ? 'نحب نفرّغ قلبي برك'
      : (isFrench ? 'Juste besoin de vider mon sac' : 'Just need to let it out');

  String get thoughtTypeFact => isArabic
      ? 'حقيقة — حاجة أي واحد يشوفها'
      : (isFrench
            ? 'Fait — observable de l’extérieur'
            : 'Fact — something anyone could see');

  String get thoughtTypeGuess => isArabic
      ? 'تخمين — ممكن أما موش أكيد'
      : (isFrench
            ? 'Supposition — pas encore sûr'
            : 'Guess — possible, not sure yet');

  String get thoughtTypeStory => isArabic
      ? 'سيناريو قلق — مخي سبق الأحداث'
      : (isFrench
            ? 'Scénario — mon esprit anticipe'
            : 'Worry story — my mind jumping ahead');

  String get trapMindReadingTitle => isArabic
      ? 'تخمين أفكار غيري'
      : (isFrench ? 'Deviner leurs pensées' : 'Guessing their thoughts');

  String get trapCatastrophizingTitle => isArabic
      ? 'توقّع الأسوأ طول'
      : (isFrench ? 'Imaginer le pire' : 'Jumping to the worst');

  String get trapAllOrNothingTitle => isArabic
      ? 'يا كل شي يا بلاش'
      : (isFrench ? 'Tout blanc ou tout noir' : 'All good or all bad');

  String get trapEmotionalReasoningTitle => isArabic
      ? 'إحساسي = حقيقة'
      : (isFrench ? 'Ressenti = fait' : 'Feeling = fact');

  String get trapMentalFilterTitle => isArabic
      ? 'نشوف كان الخايب'
      : (isFrench ? 'Ne voir que le négatif' : 'Only seeing the bad');

  String get trapOvergeneralizingTitle => isArabic
      ? 'ديما / عمري ما'
      : (isFrench ? 'Toujours / jamais' : 'Always / never');

  String get talkDeletedUndo =>
      isArabic ? 'تفسخ الحوار' : (isFrench ? 'Échange supprimé' : 'Talk removed');

  String get itemRemovedUndo =>
      isArabic ? 'تفسخ العنصر' : (isFrench ? 'Élément supprimé' : 'Item removed');

  String get customInstructionsSavedToast => isArabic
      ? 'تخزّنت تفضيلات الاستماع'
      : (isFrench
            ? 'Préférences d’écoute enregistrées'
            : 'Listening preferences saved');

  String get thoughtSavedToast => isArabic
      ? 'تحفظت الفكرة في ملخصك'
      : (isFrench ? 'Ajouté à votre résumé' : 'Saved to your summary');

  String get reflectionSavedToast => isArabic
      ? 'تسجّلت ملاحظتك'
      : (isFrench ? 'Note enregistrée' : 'Note saved');

  String get symptomLoggedToast => isArabic
      ? 'تسجّلت الملاحظة الجسدية'
      : (isFrench ? 'Ressenti enregistré' : 'Body note saved');

  String get savedToHelpfulToast => isArabic
      ? 'تزاد لـ شنوة يعاونك ترتاح'
      : (isFrench ? 'Ajouté à Ce qui vous aide' : 'Saved to What helps you');

  String get discoverySavedToast => isArabic
      ? 'تسجّلت الملاحظة'
      : (isFrench ? 'Découverte enregistrée' : 'Note saved');

  String get helpfulThoughtSavedToast => isArabic
      ? 'تسجّلت الفكرة المريحة'
      : (isFrench ? 'Pensée apaisante ajoutée' : 'Helpful thought saved');

  String get signInRequiredToast => isArabic
      ? 'ادخل بحسابك ولا كمّل على تليفونك برك'
      : (isFrench
            ? 'Connectez-vous ou continuez sur cet appareil'
            : 'Sign in or continue privately on this phone');

  String dialerCopiedToast(String phone) {
    if (isArabic) return 'تنسخ الرقم: $phone';
    if (isFrench) return 'Numéro copié : $phone';
    return 'Number copied: $phone';
  }

  String linkCopiedToast(String url) {
    if (isArabic) return 'تنسخ الرابط: $url';
    if (isFrench) return 'Lien copié : $url';
    return 'Link copied: $url';
  }

  String get infoBadge =>
      isArabic ? 'معلومة' : (isFrench ? 'Info' : 'Info');

  // Breathing & Relief Cues
  String get calmToolsHeader => isArabic
      ? 'أدوات تهدئة سريعة'
      : (isFrench ? 'Outils d’apaisement' : 'Quick calm tools');

  String get breatheInCue => isArabic
      ? 'تنفّس لداخل...'
      : (isFrench ? 'Inspirez doucement...' : 'Breathe in...');

  String get holdCue => isArabic
      ? 'شدّ النفس بلطف...'
      : (isFrench ? 'Retenez doucement...' : 'Hold gently...');

  String get breatheOutCue => isArabic
      ? 'خرّج النفس على مهلك...'
      : (isFrench ? 'Expirez lentement...' : 'Breathe out slowly...');

  String get restCue =>
      isArabic ? 'ارتاح...' : (isFrench ? 'Repos...' : 'Rest...');

  // Patterns Progressive Disclosure
  String get seeMoreDetailsBtn => isArabic
      ? 'شوف تفاصيل أكثر'
      : (isFrench ? 'Voir plus de détails' : 'See more details');

  String get hideDetailsBtn => isArabic
      ? 'اخفي التفاصيل'
      : (isFrench ? 'Masquer les détails' : 'Hide details');

  String get yourWeekHeader =>
      isArabic ? 'الجمعة متاعك' : (isFrench ? 'Votre semaine' : 'Your week');

  String get moodColorsPosterTitle => isArabic
      ? 'لوحة ألوانك'
      : (isFrench ? 'Votre poster de couleurs' : 'Your Mood Colors Poster');

  String get moodColorsPosterSub => isArabic
      ? 'حوّل شهرك لصورة حلوة'
      : (isFrench
            ? 'Transformez ce mois en image'
            : 'Turn this month into art');

  String get sunriseStyleLabel =>
      isArabic ? 'نهار دافي' : (isFrench ? 'Clair doux' : 'Daylight');

  String get twilightStyleLabel =>
      isArabic ? 'داكن نظيف' : (isFrench ? 'Sombre épuré' : 'Dark');

  // Theme & Reading Comfort Plain Labels
  String get lookAndReadingSection => isArabic
      ? 'الألوان وحجم الكتابة'
      : (isFrench ? 'Couleurs et lecture' : 'Look & reading');

  String get aboutMeAndRemindersSection => isArabic
      ? 'عليّا والتنبيهات'
      : (isFrench ? 'Moi et rappels' : 'About me & reminders');

  String get doctorVisitSection => isArabic
      ? 'زيارة الطبيب (اختياري)'
      : (isFrench ? 'Visite médicale (facultatif)' : 'Doctor visit (optional)');

  String get privacyLockBackupSection => isArabic
      ? 'الخصوصية، القفل والنسخة'
      : (isFrench ? 'Vie privée, code et sauvegarde' : 'Privacy, lock & backup');

  String get advancedCliniciansSection => isArabic
      ? 'للأطباء والإعدادات المتقدّمة'
      : (isFrench ? 'Pour cliniciens et avancé' : 'For clinicians & advanced');

  String get themeSunriseLabel =>
      isArabic ? 'نهاري' : (isFrench ? 'Clair' : 'Daylight');

  String get themeNightLabel =>
      isArabic ? 'داكن' : (isFrench ? 'Sombre' : 'Dark');

  String get themeAutoLabel =>
      isArabic ? 'تلقائي' : (isFrench ? 'Auto' : 'Auto');

  String get normalTextLabel =>
      isArabic ? 'عادي' : (isFrench ? 'Normal' : 'Normal');

  String get largerTextLabel =>
      isArabic ? 'كتابة كبيرة' : (isFrench ? 'Grand texte' : 'Larger text');

  String get toolboxAndBodyNotesLabel => isArabic
      ? 'أدوات الهدوء والجسم'
      : (isFrench ? 'Outils de calme et corps' : 'Calm & body tools');

  String get myStoryAndGoalsLabel => isArabic
      ? 'قصّتي وأهدافي'
      : (isFrench ? 'Mon profil et mes objectifs' : 'My story & goals');

  // Onboarding 3-Step Plain Copy
  String get ageUnder18 =>
      isArabic ? 'أقل من 18' : (isFrench ? 'Moins de 18 ans' : 'Under 18');

  String get age65Plus =>
      isArabic ? '65 سنة فأكثر' : (isFrench ? '65 ans et +' : '65+');

  String get continueBtn =>
      isArabic ? 'كمّل' : (isFrench ? 'Continuer' : 'Continue');

  String get saveAndEnterBtn => isArabic
      ? 'خزّن وادخل لـ Mindora'
      : (isFrench ? 'Enregistrer et entrer' : 'Save & open Mindora');

  String get welcomeBackLockTitle => isArabic
      ? 'مرحبا بيك من جديد'
      : (isFrench ? 'Bon retour' : 'Welcome back');

  String get onboardingStartBtn =>
      isArabic ? 'ابدأ' : (isFrench ? 'Commencer' : 'Start');

  String get onboardingAboutYouTitle => isArabic
      ? 'خلّينا نتعرّفوا عليك (اختياري)'
      : (isFrench ? 'Faisons connaissance (facultatif)' : 'A quick hello (optional)');

  String get onboardingContinuePrivatelyBtn => isArabic
      ? 'كمّل بخصوصية على تليفونك'
      : (isFrench
            ? 'Continuer en privé sur ce téléphone'
            : 'Continue privately on this phone');

  // Crisis Human Warmth
  String get crisisPauseHumanTitle => isArabic
      ? 'لحظة — سلامتك أهم حاجة'
      : (isFrench ? 'Pause — vous comptez' : 'Pause — you matter');

  String get openCalmBreathingBtn => isArabic
      ? 'افتح تمرين التنفّس'
      : (isFrench ? 'Ouvrir la respiration calme' : 'Open calm breathing');

  String get iAmSafeNowBtn => isArabic
      ? 'أنا بخير توا'
      : (isFrench ? 'Je suis en sécurité' : 'I am safe right now');

  // Pre-Permission & Backup Safety Copy
  String get cameraPermissionTitle => isArabic
      ? 'السماح بالكاميرا لمسح الرمز'
      : (isFrench ? 'Autoriser la caméra pour scanner' : 'Use camera to scan QR code');

  String get cameraPermissionBody => isArabic
      ? 'نستعملوا الكاميرا كان لمسح رمز الطبيب. تنجّم زادة تلصق الكود لتحت.'
      : (isFrench
            ? 'La caméra sert uniquement à scanner le code. Vous pouvez aussi le coller.'
            : 'Camera is only used to scan your doctor’s QR code. You can also paste the text code.');

  String get allowCameraBtn => isArabic
      ? 'افتح الكاميرا'
      : (isFrench ? 'Ouvrir la caméra' : 'Scan with camera');

  String get pasteTextCodeBtn => isArabic
      ? 'لصق الكود المكتوب'
      : (isFrench ? 'Coller le code texte' : 'Paste text code');

  String get reminderPermissionTitle => isArabic
      ? 'تذكير لطيف مرة في النهار'
      : (isFrench ? 'Un petit rappel doux par jour' : 'One gentle daily reminder');

  String get reminderPermissionBody => isArabic
      ? 'نبعثولك رسالة هادية بلاش ضغط وتنجّم توقفها في أي وقت.'
      : (isFrench
            ? 'Un message calme, sans pression, désactivable à tout moment.'
            : 'A calm check-in nudge with zero streak pressure. Turn off anytime.');

  String get enableReminderBtn => isArabic
      ? 'فعّل التذكير'
      : (isFrench ? 'Activer le rappel' : 'Turn on reminder');

  String get notNowBtn =>
      isArabic ? 'موش توا' : (isFrench ? 'Pas maintenant' : 'Not now');

  String get keepMyDataBtn => isArabic
      ? 'خلّي بياناتي'
      : (isFrench ? 'Garder mes données' : 'Keep my data');

  String get deleteEverythingForeverBtn => isArabic
      ? 'افسخ كل شي نهائياً'
      : (isFrench ? 'Tout supprimer définitivement' : 'Delete everything forever');

  String get restoreBackupPreviewTitle => isArabic
      ? 'معاينة النسخة قبل الاسترجاع'
      : (isFrench ? 'Aperçu avant restauration' : 'Preview before restoring');

  String restorePreviewSummary(int traces, int talks) {
    if (isArabic) return 'لقينا $traces تسجيلة يومية و $talks حوارات. تحب ترجّعهم لتليفونك؟';
    if (isFrench) return '$traces entrées et $talks échanges trouvés. Restaurer sur ce téléphone ?';
    return 'Found $traces check-ins and $talks talks. Restore them to this phone?';
  }

  String get restoreBackupBtn => isArabic
      ? 'استرجاع النسخة'
      : (isFrench ? 'Restaurer la sauvegarde' : 'Restore backup');

  // Inline string migration getters (Spec 05 Part 3)
  String get summaryHighlightsHeader => isArabic
      ? 'أهم النقاط'
      : (isFrench ? 'Points clés' : 'Key takeaways');

  String get talkTranscriptHeader => isArabic
      ? 'مقتطفات من الحوار'
      : (isFrench ? 'Extraits de l’échange' : 'Talk highlights');

  String get youSpeakerLabel =>
      isArabic ? 'أنت' : (isFrench ? 'Vous' : 'You');

  String get companionSpeakerLabel =>
      isArabic ? 'Mindora' : (isFrench ? 'Mindora' : 'Mindora');

  String get exportPreviewLabel => isArabic
      ? 'معاينة الملخص قبل المشاركة:'
      : (isFrench ? 'Aperçu du résumé :' : 'Summary preview:');

  String get toggleKeyVisibilityTooltip => isArabic
      ? 'إظهار أو إخفاء المفتاح'
      : (isFrench ? 'Afficher ou masquer la clé' : 'Show or hide key');

  String get listeningPrefsLabel => isArabic
      ? 'أسلوب الحوار'
      : (isFrench ? 'Style de discussion' : 'Conversation style');

  String get whyThisHelpsHeader => isArabic
      ? 'كيفاش يعاونك التمرين هذا'
      : (isFrench ? 'Pourquoi cela aide' : 'Why this helps');

  String get exploredBadge =>
      isArabic ? 'تم الفهم' : (isFrench ? 'Exploré' : 'Explored');

  String get whatHappenedAndHelpedHeader => isArabic
      ? 'شنوة صار وشنوة عاونك'
      : (isFrench ? 'Contexte et ce qui a aidé' : 'Context & what helped');

  String get sleepAndEnergyHeader => isArabic
      ? 'النوم والطاقة'
      : (isFrench ? 'Sommeil et énergie' : 'Sleep & energy');

  String get clearerViewHeader => isArabic
      ? 'نظرة أوضح'
      : (isFrench ? 'Vue plus claire' : 'Clearer view');

  String get companionNoteHeader => isArabic
      ? 'ملاحظة المتابعة'
      : (isFrench ? 'Note de suivi' : 'Consultation note');

  String get myNoteHeader => isArabic
      ? 'ملاحظتي'
      : (isFrench ? 'Ma note' : 'My note');

  String get topicHeader =>
      isArabic ? 'الموضوع' : (isFrench ? 'Catégorie' : 'Topic');

  String get mainTakeawayHeader => isArabic
      ? 'الفكرة الأساسية'
      : (isFrench ? 'Idée clé' : 'Main takeaway');

  String get symptomGroupLabel =>
      isArabic ? 'المجال' : (isFrench ? 'Domaine' : 'Group');

  String get bodySignsTab => isArabic
      ? 'إشارات البدن'
      : (isFrench ? 'Signes du corps' : 'Body signs');

  String get allFilterChip =>
      isArabic ? 'الكل' : (isFrench ? 'Tout' : 'All');

  String get removeFromProfileBtn => isArabic
      ? 'نحّي من ملفي'
      : (isFrench ? 'Retirer' : 'Remove');

  String get updateProfileBtn => isArabic
      ? 'تحديث'
      : (isFrench ? 'Mettre à jour' : 'Update');

  String get addToProfileBtn => isArabic
      ? 'زيد لملفي'
      : (isFrench ? 'Ajouter' : 'Add');

  String get keepNotesBtn => isArabic
      ? 'خلّي ملاحظاتي'
      : (isFrench ? 'Garder mes notes' : 'Keep my notes');

  String get clearAllNotesBtn => isArabic
      ? 'مسح كل الملاحظات'
      : (isFrench ? 'Effacer toutes les notes' : 'Clear all notes');

  String get keepProfileBtn => isArabic
      ? 'خلّي ملفي'
      : (isFrench ? 'Garder mon profil' : 'Keep my profile');

  String get resetProfileBtn => isArabic
      ? 'إعادة ضبط الملف'
      : (isFrench ? 'Réinitialiser le profil' : 'Reset profile');

  String get passphraseFieldLabel => isArabic
      ? 'كلمة السر'
      : (isFrench ? 'Mot de passe' : 'Passphrase');

  String get confirmPassphraseLabel => isArabic
      ? 'أكّد كلمة السر'
      : (isFrench ? 'Confirmer le mot de passe' : 'Confirm passphrase');

  String get reminderFrequencyLabel => isArabic
      ? 'التكرار'
      : (isFrench ? 'Rythme' : 'Frequency');

  String get everyDayChip =>
      isArabic ? 'كل نهار' : (isFrench ? 'Chaque jour' : 'Every day');

  String get everyTwoDaysChip =>
      isArabic ? 'نهار بنهار' : (isFrench ? 'Un jour sur deux' : 'Every 2 days');

  String formatRelativeTimeAgo(Duration diff) {
    if (diff.inMinutes < 60) {
      final mins = diff.inMinutes.clamp(1, 59);
      if (isArabic) return 'منذ $mins د';
      if (isFrench) return 'Il y a ${mins}min';
      return '${mins}m ago';
    }
    if (diff.inHours < 24) {
      if (isArabic) return 'منذ ${diff.inHours} س';
      if (isFrench) return 'Il y a ${diff.inHours}h';
      return '${diff.inHours}h ago';
    }
    if (isArabic) return 'منذ ${diff.inDays} ي';
    if (isFrench) return 'Il y a ${diff.inDays}j';
    return '${diff.inDays}d ago';
  }

  List<String> get gentleReminderBodies => isArabic
      ? const [
          'شنوة حالك توا؟ في لمستين برك كان تحب.',
          'خوذ نفس هادي — Mindora بحذاك وقت ما تحب.',
          'تحب تسجّل لون نهارك اليوم؟',
          'وقفة 5 ثواني تطمّن بيها على روحك.',
        ]
      : (isFrench
            ? const [
                'Comment allez-vous ? Deux gestes suffisent.',
                'Prenez une grande respiration — Mindora est là.',
                'Envie de noter la couleur de votre journée ?',
                'Cinq secondes de pause pour écouter comment ça va.',
              ]
            : const [
                'How are you feeling right now? Two taps if you’d like.',
                'Take one slow breath — Mindora is here whenever you want.',
                'Want to save a quick color for today?',
                'Pause for 5 seconds and check in with yourself.',
              ]);

  String get momentSavedGentleSupport => isArabic
      ? 'تسجّلت لحظتك. كان حاسس بثقل، زر مساعدة ديما بحذاك.'
      : (isFrench
            ? 'Moment enregistré. Besoin d’aide ? Le bouton Aide est toujours là.'
            : 'Saved. Feeling heavy? Tap Help anytime.');

  String get weeklyChip =>
      isArabic ? 'مرة في الجمعة' : (isFrench ? 'Chaque semaine' : 'Weekly');

  String get reminderPermissionDeniedToast => isArabic
      ? 'التنبيهات بقات مقفولة خاطر ما عطيتش الإذن.'
      : (isFrench
            ? 'Rappels désactivés : autorisation non accordée.'
            : 'Reminders stay off because notification permission was not granted.');

  String get exportEncryptedVaultTitle => isArabic
      ? 'احفظ نسخة محمية بكلمة سر'
      : (isFrench ? 'Sauvegarde protégée' : 'Save password-locked backup');

  String get exportEncryptedVaultDesc => isArabic
      ? 'اختار كلمة سر فيها 6 حروف على الأقل باش تحمي نسختك.'
      : (isFrench
            ? 'Choisissez un mot de passe (6 caractères min.) pour protéger votre sauvegarde.'
            : 'Choose a passphrase (at least 6 characters) to lock your backup.');

  String get passphraseTooShortError => isArabic
      ? 'كلمة السر لازم فيها 6 حروف على الأقل.'
      : (isFrench
            ? 'Le mot de passe doit faire au moins 6 caractères.'
            : 'Passphrase must be at least 6 characters.');

  String get passphraseMismatchError => isArabic
      ? 'كلمتي السر موش كيف كيف.'
      : (isFrench
            ? 'Les mots de passe ne correspondent pas.'
            : 'Passphrases do not match.');

  String get vaultCopiedToast => isArabic
      ? 'تنسخت النسخة المحمية للحافظة.'
      : (isFrench
            ? 'Sauvegarde protégée copiée.'
            : 'Locked backup copied to clipboard.');

  String get restoreEncryptedVaultDesc => isArabic
      ? 'لصق النسخة متاعك واكتب كلمة السر باش تشوف محتواها قبل الاسترجاع.'
      : (isFrench
            ? 'Collez votre sauvegarde et saisissez le mot de passe pour vérifier son contenu.'
            : 'Paste your backup text and passphrase to preview what will be restored.');

  String get backupJsonLabel => isArabic
      ? 'نص النسخة الاحتياطية'
      : (isFrench ? 'Texte de sauvegarde' : 'Backup text');

  String get pasteBackupFirstError => isArabic
      ? 'لصق نص النسخة متاعك قبل.'
      : (isFrench
            ? 'Veuillez d’abord coller votre sauvegarde.'
            : 'Please paste your backup text first.');

  String get noShareableTalksYet => isArabic
      ? 'ما فماش حوارات جاهزة للمشاركة توا.'
      : (isFrench
            ? 'Aucun échange partageable pour le moment.'
            : 'No non-private talks available to share yet.');

  String previewSharePacketBtn(int count) {
    if (isArabic) return 'معاينة الحزمة ($count)';
    if (isFrench) return 'Voir l’aperçu ($count)';
    return 'Preview summary ($count)';
  }

  String backupCompleteToast(int traces, int talks, int notes) {
    if (isArabic) return 'تخزّنت النسخة: $traces تسجيلة، $talks حوارات، $notes ملاحظات.';
    if (isFrench) return 'Sauvegarde prête : $traces entrées, $talks échanges, $notes notes.';
    return 'Backup saved: $traces check-ins, $talks talks, $notes notes.';
  }

  String get reminderSamplePrefix =>
      isArabic ? 'مثال:' : (isFrench ? 'Exemple :' : 'Example:');

  // Phase A–D: Me Header, 6-Step Adaptive Onboarding & Decision Engine, Daily Clinical Pulse, Doctor Portal
  String get meSpaceDefaultTitle => isArabic
      ? 'مساحتي الخاصة'
      : (isFrench ? 'Mon espace privé' : 'My Private Space');

  String get openDoctorWorkspaceBtn => isArabic
      ? 'افتح فضاء الطبيب'
      : (isFrench ? 'Ouvrir l’espace médecin' : 'Open Doctor Workspace');

  String get onboardingLanguageSubtitle => isArabic
      ? 'اختار لغتك والألوان وحجم الكتابة اللي يريحك'
      : (isFrench
            ? 'Choisissez votre langue, vos couleurs et la taille du texte'
            : 'Pick your language, look and comfortable text size');

  String get onboardingRoleTitle => isArabic
      ? 'شكون باش يستعمل التطبيق؟'
      : (isFrench ? 'Comment utilisez-vous Mindora ?' : 'How will you use Mindora?');

  String get onboardingRoleSubtitle => isArabic
      ? 'نحضّروا ليك الواجهة المناسبة حسب حاجتك.'
      : (isFrench
            ? 'Nous adaptons l’espace selon votre besoin.'
            : 'We shape the app around what you need first.');

  String get rolePatientTitle => isArabic
      ? 'لروحي (تتبّع يومي)'
      : (isFrench ? 'Pour moi-même' : 'For myself');

  String get rolePatientSub => isArabic
      ? 'سجّل مزاجك، نومك وطاقتك وافهم روحك بوضوح'
      : (isFrench
            ? 'Suivre mon humeur, mon sommeil et me sentir plus clair(e)'
            : 'Track my mood, sleep & feel clearer day by day');

  String get roleClinicianTitle => isArabic
      ? 'أنا طبيب نفسي / معالج'
      : (isFrench ? 'Je suis médecin / psychiatre' : 'I am a Doctor / Psychiatrist');

  String get roleClinicianSub => isArabic
      ? 'متابعة حالة المرضى، النوم والملخصات قبل الزيارة'
      : (isFrench
            ? 'Suivre mes patients, le sommeil et les bilans de visite'
            : 'Follow patients’ mood, sleep & pre-visit summaries');

  String get ageAutoComfortBanner => isArabic
      ? 'كبّرنا ليك الكتابة لراحة عينيك — تنجّم تبدّلها وقت ما تحب.'
      : (isFrench
            ? 'Texte agrandi activé pour votre confort — modifiable à tout moment.'
            : 'Larger text turned on for comfort — change anytime.');

  String get onboardingGoalsTitle => isArabic
      ? 'شنوّة تحب تعمل مع Mindora؟'
      : (isFrench ? 'Qu’est-ce qui vous amène ici ?' : 'What brings you to Mindora?');

  String get onboardingGoalsSub => isArabic
      ? 'اختار حاجة أو أكثر باش نعدّلو الصفحة الرئيسية ليك.'
      : (isFrench
            ? 'Choisissez une ou plusieurs options pour adapter votre accueil.'
            : 'Pick one or more so we tailor your daily home screen.');

  String get goalTrackMoodSleep => isArabic
      ? 'نتبع مزاجي ونومي كل يوم'
      : (isFrench ? 'Suivre mon humeur et mon sommeil' : 'Track my mood & sleep');

  String get goalDoctorVisits => isArabic
      ? 'نحضّر ملخص واضح لطبيبي'
      : (isFrench ? 'Préparer mes visites médicales' : 'Prepare clear updates for my doctor');

  String get goalCalmStress => isArabic
      ? 'نهدّي التوتر وكثرة التخمام'
      : (isFrench ? 'Apaiser le stress et les pensées' : 'Calm stress & racing thoughts');

  String get goalUnderstandEnergy => isArabic
      ? 'نفهم طاقتي وعاداتي اليومية'
      : (isFrench ? 'Comprendre mon énergie et rythme' : 'Understand my energy & daily habits');

  String get goalJustExploring => isArabic
      ? 'نستكشف برك لنفسي'
      : (isFrench ? 'Juste explorer pour moi' : 'Just checking in for myself');

  String get onboardingCareAndFocusTitle => isArabic
      ? 'شنوّة يأثّر في نهارك أكثر؟'
      : (isFrench ? 'Votre suivi et ce qui pèse le plus' : 'Your care & daily focus');

  String get onboardingDoctorCareQuestion => isArabic
      ? 'هل تتابع مع طبيب أو مختص حالياً؟'
      : (isFrench ? 'Êtes-vous suivi(e) par un médecin ?' : 'Are you seeing a doctor or specialist?');

  String get careRegularDoctor => isArabic
      ? 'إيه، بانتظام'
      : (isFrench ? 'Oui, régulièrement' : 'Yes, regularly');

  String get careOccasionalDoctor => isArabic
      ? 'أحياناً'
      : (isFrench ? 'De temps en temps' : 'Sometimes');

  String get careSelfOnly => isArabic
      ? 'لا، لروحي برك توا'
      : (isFrench ? 'Non, pour moi' : 'Not right now');

  String get onboardingFocusAreasQuestion => isArabic
      ? 'شنوّة أهم المواضيع اللي تحب تتابعها؟'
      : (isFrench ? 'Sur quoi voulez-vous garder un œil ?' : 'What affects your days most lately?');

  String get focusSleep =>
      isArabic ? 'النوم والليل' : (isFrench ? 'Sommeil' : 'Sleep & nights');

  String get focusEnergy =>
      isArabic ? 'الطاقة والتعب' : (isFrench ? 'Énergie' : 'Low energy');

  String get focusStress =>
      isArabic ? 'الضغط والقلق' : (isFrench ? 'Stress & anxiété' : 'Stress & tension');

  String get focusOverthinking =>
      isArabic ? 'كثرة التخمام' : (isFrench ? 'Ruminations' : 'Overthinking');

  String get focusWorkStudy =>
      isArabic ? 'الخدمة أو القراية' : (isFrench ? 'Travail / études' : 'Work / study');

  String get focusFamilySocial =>
      isArabic ? 'العائلة والمحيط' : (isFrench ? 'Famille / proches' : 'Family / social');

  String get focusRoutine =>
      isArabic ? 'انتظام الروتين' : (isFrench ? 'Routine quotidienne' : 'Keeping a routine');

  String get tailoredForYouTitle =>
      isArabic ? 'جاهز حسب اختيارك:' : (isFrench ? 'Préparé pour vous :' : 'Tailored for you:');

  String get summarySleepEnabled => isArabic
      ? 'سؤال النوم والطاقة الصباحي'
      : (isFrench ? 'Suivi sommeil & énergie' : 'Morning sleep & energy pulse');

  String get summaryDoctorReadyEnabled => isArabic
      ? 'ملخص جاهز لطبيبك'
      : (isFrench ? 'Résumé visite médecin prêt' : 'Doctor visit summary ready');

  String get summaryCalmToolsEnabled => isArabic
      ? 'تمرين تهدئة سريع على الرئيسية'
      : (isFrench ? 'Respiration calme rapide' : 'Quick calm tools on Home');

  String get summaryMinimalEnabled => isArabic
      ? 'واجهة بسيطة بلا تعب'
      : (isFrench ? 'Accueil simple et léger' : 'Light, calm Home layout');

  // Home Clinical Daily Pulse Copy
  String get morningPulseTitle => isArabic
      ? 'نقاط الصباح الصحية'
      : (isFrench ? 'Bilan du matin' : 'Morning health pulse');

  String get eveningPulseTitle => isArabic
      ? 'نقاط المساء السريعة'
      : (isFrench ? 'Bilan du soir' : 'Evening daily pulse');

  String get pulseForYouAndDoctorSub => isArabic
      ? 'لمسات سريعة تعاونك وتعاون طبيبك'
      : (isFrench ? '2 gestes utiles pour vous et votre médecin' : '10-second log for you & your doctor');

  String get sleepHoursQuestion => isArabic
      ? 'قدّاش رقدت البارح؟'
      : (isFrench ? 'Combien avez-vous dormi ?' : 'How long did you sleep?');

  String get sleepLt5h => isArabic ? 'أقل من 5 س' : (isFrench ? '< 5h' : '< 5h');
  String get sleep5to6h => isArabic ? '5–6 س' : (isFrench ? '5–6h' : '5–6h');
  String get sleep7to8h => isArabic ? '7–8 س' : (isFrench ? '7–8h' : '7–8h');
  String get sleep9plusH => isArabic ? '9+ س' : (isFrench ? '9h+' : '9h+');

  String get sleepQualityQuestion => isArabic
      ? 'كيفاش كان نومك؟'
      : (isFrench ? 'Qualité du sommeil ?' : 'How was your sleep?');

  String get sleepRestedLabel =>
      isArabic ? 'مرتاح' : (isFrench ? 'Reposant' : 'Rested');
  String get sleepWokeUpLabel =>
      isArabic ? 'تقطّع' : (isFrench ? 'Réveils' : 'Woke up');
  String get sleepHardLabel =>
      isArabic ? 'صعيب' : (isFrench ? 'Difficile' : 'Hard to sleep');

  String get morningEnergyQuestion => isArabic
      ? 'طاقتك توا؟'
      : (isFrench ? 'Votre niveau d’énergie ?' : 'Energy right now?');

  String get energyDrainedLabel =>
      isArabic ? 'تعبان برشا' : (isFrench ? 'Épuisé(e)' : 'Drained');
  String get energySteadyLabel =>
      isArabic ? 'لاباس' : (isFrench ? 'Stable' : 'Steady');
  String get energyHighLabel =>
      isArabic ? 'عالية / متوترة' : (isFrench ? 'Haute / tendue' : 'High / wired');

  String get stressTodayQuestion => isArabic
      ? 'التوتر أو الضغط اليوم؟'
      : (isFrench ? 'Tension ressentie aujourd’hui ?' : 'Stress or tension today?');

  String get stressCalmLabel =>
      isArabic ? 'هادي' : (isFrench ? 'Calme' : 'Calm');
  String get stressMildLabel =>
      isArabic ? 'خفيف' : (isFrench ? 'Léger' : 'Mild');
  String get stressHeavyLabel =>
      isArabic ? 'ثقيل' : (isFrench ? 'Lourd' : 'Heavy');
  String get stressOverwhelmedLabel =>
      isArabic ? 'مضغوط برشا' : (isFrench ? 'Submergé(e)' : 'Overwhelmed');

  String get whatShapedTodayQuestion => isArabic
      ? 'شنوّة أثّر اليوم وشنوّة ريّحك؟'
      : (isFrench ? 'Qu’est-ce qui a pesé ou aidé ?' : 'What shaped or helped today?');

  String get routineAnchorQuestion => isArabic
      ? 'التزمت بروتينك المعتاد اليوم؟'
      : (isFrench ? 'Routine habituelle tenue ?' : 'Kept your usual routine today?');

  String get routineYesLabel => isArabic ? 'إيه' : (isFrench ? 'Oui' : 'Yes');
  String get routinePartlyLabel => isArabic ? 'شوية' : (isFrench ? 'En partie' : 'Partly');
  String get routineNoLabel => isArabic ? 'موش اليوم' : (isFrench ? 'Pas aujourd’hui' : 'Not today');

  String get helperWalk => isArabic ? 'مشي خفيف' : (isFrench ? 'Marche' : 'Short walk');
  String get helperRest => isArabic ? 'راحة' : (isFrench ? 'Repos' : 'Quiet rest');
  String get helperBreathing => isArabic ? 'تنفّس هادي' : (isFrench ? 'Respiration' : 'Slow breathing');
  String get helperTalked => isArabic ? 'حكيت مع حد' : (isFrench ? 'Parler à un proche' : 'Talked with someone');
  String get helperQuiet => isArabic ? 'هدوء / قرآن / موسيقى' : (isFrench ? 'Moment calme' : 'Quiet time');

  String doctorVisitReadyTitle(int loggedDays) {
    if (isArabic) {
      if (loggedDays == 1) return 'ملخص طبيبك فيه يوم واحد مسجّل';
      if (loggedDays == 2) return 'ملخص طبيبك فيه يومان مسجّلان';
      if (loggedDays >= 3 && loggedDays <= 10) {
        return 'ملخص طبيبك فيه $loggedDays أيام مسجّلة';
      }
      return 'ملخص طبيبك فيه $loggedDays يوماً مسجّلاً';
    }
    if (isFrench) {
      return '$loggedDays ${loggedDays == 1 ? 'jour prêt' : 'jours prêts'} pour votre médecin';
    }
    return '$loggedDays ${loggedDays == 1 ? 'day' : 'days'} ready for your doctor visit';
  }

  String get doctorVisitReadySub => isArabic
      ? 'اضغط لتحضير نقاط الزيارة في دقيقتين'
      : (isFrench ? 'Touchez pour préparer votre rendez-vous' : 'Tap to review your 2-minute pre-visit summary');

  // Doctor Portal 7-Day Sparkline & SOAP-Lite Templates
  String sleep7dShortLabel(String sleepStr) {
    if (isArabic) return 'نوم 7أ: $sleepStr';
    if (isFrench) return 'Sommeil 7j : $sleepStr';
    return '7d Sleep: $sleepStr';
  }

  String get lowSleepFlagBadge => isArabic
      ? 'نوم أقل من 5.5 س'
      : (isFrench ? 'Sommeil < 5,5h' : 'Sleep < 5.5h');

  String get soapTemplateLabel => isArabic
      ? 'قوالب سريعة:'
      : (isFrench ? 'Modèles rapides :' : 'Quick templates:');

  String get soapCheckInBtn => isArabic
      ? 'معاينة SOAP'
      : (isFrench ? 'Note SOAP' : 'SOAP Check-In');

  String get soapSleepBtn => isArabic
      ? 'مراجعة النوم'
      : (isFrench ? 'Bilan sommeil' : 'Sleep Review');

  String get soapFollowUpBtn => isArabic
      ? 'خطة المتابعة'
      : (isFrench ? 'Plan de suivi' : 'Follow-Up');

  String soapTemplateBody(String kind) {
    if (kind == 'sleep') {
      if (isArabic) return 'نمط النوم الملاحظ:\nتغيّر الطاقة:\nنقاط النقاش القادمة:\n';
      if (isFrench) return 'Sommeil observé :\nImpact énergie :\nPoints à revoir :\n';
      return 'Observed sleep pattern:\nEnergy correlation:\nNext check-in focus:\n';
    }
    if (kind == 'followup') {
      if (isArabic) return 'أولويات المتابعة:\nعوامل مساعدة:\nتاريخ الموعد القادم:\n';
      if (isFrench) return 'Priorités de suivi :\nFacteurs aidants :\nProchaine étape :\n';
      return 'Follow-up priorities:\nReported stabilizers:\nAgreed focus:\n';
    }
    if (isArabic) return 'الشكوى / الملخص:\nالمعطيات الملاحظة:\nالتقييم:\nالخطة:\n';
    if (isFrench) return 'Subjectif (patient) :\nTendances observées :\nAnalyse :\nPlan :\n';
    return 'Subjective:\nObserved trends:\nAssessment:\nPlan:\n';
  }

  String get soapTemplateBodyStartMarker => '';

  // Talk / AI Chat Polish
  String get takeawayBookmarkedLabel => isArabic
      ? 'تم حفظ الخلاصة'
      : (isFrench ? 'Retenu' : 'Saved takeaway');
  String get alreadyFreshChatNotice => isArabic
      ? 'أنت ديجا في محادثة جديدة.'
      : (isFrench
            ? 'Vous êtes déjà dans une nouvelle discussion.'
            : 'Already in a fresh conversation.');
  String get privacyConsentPausedTag => isArabic
      ? 'محلي (المشاركة السحابية موقفة)'
      : (isFrench ? 'Local (partage cloud désactivé)' : 'Local (cloud consent off)');

  // Calm AI Companion Sanctuary (strictly non-diagnostic)
  String get talkConsultSpeaker => isArabic
      ? 'رفيق Mindora الذكي'
      : (isFrench ? 'Compagnon IA Mindora' : 'Mindora AI Companion');
  String get talkWelcomeHeadline => isArabic
      ? 'مرحباً بك. شنوة اللي شاغل بالك اليوم؟'
      : (isFrench
            ? 'Bonjour. Qu’est-ce qui pèse le plus sur vous aujourd’hui ?'
            : 'Welcome. What is weighing on you right now?');
  String get talkWelcomeSub => isArabic
      ? 'رفيق ذكي هادي يعاونك ترتّب أفكارك — ماهوش طبيب وما يشخّصش. تنجم تقفل أي حوار «ليّ وحدي» وقت ما تحب.'
      : (isFrench
            ? 'Un compagnon IA calme pour clarifier vos pensées — ni médecin ni diagnostic. Verrouillez une discussion en privé à tout moment.'
            : 'A calm AI companion to help sort your thoughts — not a doctor or diagnosis. Lock any talk as private anytime.');
  String get talkDoorwaySpinning => isArabic
      ? 'أفكار متسارعة تقلقني وتؤثّر على راحتي ونومي'
      : (isFrench
            ? 'Des pensées en boucle qui pèsent sur mon calme et mon sommeil'
            : 'Racing thoughts weighing on my rest and focus');
  String get talkDoorwayHeavyDay => isArabic
      ? 'نحسّ بضغط أو ثقل نفسي نحب نفصّلو'
      : (isFrench
            ? 'Un poids ou une tension forte à faire le point aujourd’hui'
            : 'A heavy feeling or strain I need to unpack');
  String get talkDoorwayJustSit => isArabic
      ? 'تعبان برشا اليوم — خلّي الأسئلة خفيفة ومختصرة'
      : (isFrench
            ? 'Je suis épuisé aujourd’hui — gardons l’échange court et doux'
            : 'Drained today — keep questions brief and gentle');
  String get talkComposerHint => isArabic
      ? 'اكتب أو اختار ردّ...'
      : (isFrench
            ? 'Écrivez ou choisissez...'
            : 'Write or tap a reply...');
  String get talkHistoryTooltip => isArabic
      ? 'محادثاتك السابقة'
      : (isFrench ? 'Échanges passés' : 'Past talks');
  String get talkHistoryShortBtn =>
      isArabic ? 'السجل' : (isFrench ? 'Passés' : 'History');

  List<({String label, String directive})> get aiInstructionPresets {
    if (isArabic) {
      return const [
        (
          label: 'قصير وهادي',
          directive:
              'خلّي الردود أقل من 3 جمل، وركّز على التنفّس وخطوات بسيطة للحظة الحالية.',
        ),
        (
          label: 'دافئ ولطيف',
          directive:
              'جاوب بلطف وصبر قبل ما تقترح طريقة ثانية للنظر في الأمور.',
        ),
        (
          label: 'وضوح خطوة بخطوة',
          directive:
              'اسأل سؤال واحد هادي في كل مرّة باش نفرقو بين الواقع والوساوس.',
        ),
        (
          label: 'مباشر وعملي',
          directive:
              'كون واضح وودود وعملي، واقترح خطوة صغيرة نجم نجرّبها توا.',
        ),
      ];
    }
    if (isFrench) {
      return const [
        (
          label: 'Court et apaisant',
          directive:
              'Garde des réponses de moins de 3 phrases. Mets l’accent sur la respiration et des gestes simples.',
        ),
        (
          label: 'Doux et chaleureux',
          directive:
              'Réponds avec chaleur et patience avant de proposer une autre perspective.',
        ),
        (
          label: 'Clarté étape par étape',
          directive:
              'Pose une seule question douce à la fois pour séparer les faits des inquiétudes.',
        ),
        (
          label: 'Direct et pratique',
          directive:
              'Sois clair, bienveillant et concret avec une petite action faisable tout de suite.',
        ),
      ];
    }
    return const [
      (
        label: 'Short & calm',
        directive:
            'Keep replies under 3 sentences. Focus on breathing and simple present-moment steps.',
      ),
      (
        label: 'Gentle & warm',
        directive:
            'Respond with warmth and patience before suggesting another way to look at things.',
      ),
      (
        label: 'Step-by-step clarity',
        directive:
            'Ask one gentle question at a time to help separate facts from worry stories.',
      ),
      (
        label: 'Direct & practical',
        directive:
            'Be clear, friendly, and practical with one small action I can try right now.',
      ),
    ];
  }
  String get talkKeepInsightAction => isArabic
      ? 'احفظ الجملة هذي'
      : (isFrench ? 'Garder cette idée' : 'Keep this insight');
  String get talkCopyAction => isArabic
      ? 'نسخ النص'
      : (isFrench ? 'Copier le texte' : 'Copy text');
  String get talkCopiedNotice => isArabic
      ? 'تم النسخ'
      : (isFrench ? 'Copié' : 'Copied');
  String get talkPrivateToggleTitle => isArabic
      ? 'خلّي الحديث هذا سري على تليفونك فقط'
      : (isFrench
            ? 'Garder cet échange privé sur l’appareil'
            : 'Keep this conversation private on device');
  String get talkPrivateEnabledNotice => isArabic
      ? 'الحديث سري الآن — ما يتشاركش لا مع الطبيب ولا مع السحابة.'
      : (isFrench
            ? 'Privé sur l’appareil — exclu de tout partage clinique ou cloud.'
            : 'Marked private — excluded from clinic sync and cloud calls.');
  String get talkCalmBreathOfferText => isArabic
      ? 'تبدو اللحظة مشحونة شوية — تحب ناخذو دقيقة تنفّس قبل؟'
      : (isFrench
            ? 'Ce moment semble intense — voulez-vous respirer 1 minute d’abord ?'
            : 'This feels heavy right now — want 60 seconds to settle your breath?');
  String get talkCalmBreathOfferBtn => isArabic
      ? 'دقيقة تنفّس هادي'
      : (isFrench ? 'Respirer 1 minute' : 'Try 1-minute breath');
  String talkContextRibbonCheckIn(String mood, int intensity) => isArabic
      ? 'سجّلت اليوم: $mood · $intensity/10 — تحب نحكيو فيه؟'
      : (isFrench
            ? 'Noté aujourd’hui : $mood · $intensity/10 — en parler ?'
            : 'Earlier today: $mood · $intensity/10 — want to unpack that?');
  String talkContextRibbonFocus(String itemTitle) => isArabic
      ? 'نقطة من طبيبك: $itemTitle'
      : (isFrench
            ? 'Suivi du médecin : $itemTitle'
            : 'Care note: $itemTitle');

  // Adaptive Condition Catalog (300+ -> 12 Tracks) & Non-Military Daily Ritual
  String get ritualSaveCollapseBtn =>
      isArabic ? 'تم · حفظ' : (isFrench ? 'Terminé' : 'Done');
  String get ritualSavedCompactBtn =>
      isArabic ? 'محفوظ · تعديل' : (isFrench ? 'Enregistré · Modifier' : 'Saved · Edit');
  String get ritualOpenOptionalBtn =>
      isArabic ? 'إضافة' : (isFrench ? 'Ajouter' : 'Open');
  String get ritualOptionalTag => isArabic
      ? 'اختياري · النوم والطاقة في 10 ثواني'
      : (isFrench ? 'Optionnel · sommeil et énergie' : 'Optional · sleep & energy');
  String ritualProgressLabel(int completed, int total) => '$completed / $total';
  String get ritualMorningTag => isArabic
      ? 'روتين الصباح · 10 ثواني'
      : (isFrench ? 'Rituel du matin · 10 s' : 'Morning check-in · 10 sec');
  String get ritualEveningTag => isArabic
      ? 'روتين المساء · 10 ثواني'
      : (isFrench ? 'Rituel du soir · 10 s' : 'Evening check-in · 10 sec');
  String get ritualSavedSummaryToast => isArabic
      ? 'تم الحفظ في متابعتك اليومية وملف الطبيب'
      : (isFrench
            ? 'Enregistré pour vous et votre médecin'
            : 'Saved for you & your doctor');
  String get ritualCompletedSummaryTitle => isArabic
      ? 'تم تسجيل نقاط اليوم'
      : (isFrench ? 'Repères du jour enregistrés' : 'Today’s focus logged');
  String ritualStreakPill(int days) {
    if (isArabic) {
      if (days == 1) return 'يوم واحد هذا الأسبوع';
      if (days == 2) return 'يومان هذا الأسبوع';
      if (days >= 3 && days <= 10) return '$days أيام هذا الأسبوع';
      return '$days يوماً هذا الأسبوع';
    }
    if (isFrench) {
      return '$days ${days == 1 ? 'jour' : 'jours'} cette semaine';
    }
    return '$days ${days == 1 ? 'day' : 'days'} this week';
  }
  String get pickWhatYouNavigateQuestion => isArabic
      ? 'شنوة المجالات اللي تحب نركّزو عليها معاك؟ (اختياري)'
      : (isFrench
            ? 'Que souhaitez-vous suivre en priorité ? (optionnel)'
            : 'What would you like Mindora to tailor for? (optional)');
  String get search300ConditionsCta => isArabic
      ? 'ابحث في +300 حالة وموضوع دقيق'
      : (isFrench
            ? 'Rechercher parmi 300+ vécus précis'
            : 'Search 300+ exact conditions');
  String get searchConditionsFieldHint => isArabic
      ? 'ابحث مثلاً: ثنائي القطب، وسواس، أرق، هلع، تشتت...'
      : (isFrench
            ? 'Ex. : bipolaire, TOC, insomnie, panique, TDAH...'
            : 'Search e.g. Bipolar, OCD, Insomnia, Panic, ADHD...');
  String get conditionsTrackingBanner => isArabic
      ? 'اختياراتك تساعد التطبيق يخصّص أسئلة اليوم لك ولطبيبك — وليس للتشخيص الطبي.'
      : (isFrench
            ? 'Ceci adapte vos questions quotidiennes pour vous et votre médecin — sans poser de diagnostic.'
            : 'This customizes your daily questions for you & your doctor — never a medical diagnosis.');
  String get noMatchingConditionsLabel => isArabic
      ? 'ما لقيناش نتيجة مطابقة — جرب كلمة أبسط ولا اختار مسار عام.'
      : (isFrench
            ? 'Aucun résultat — essayez un mot simple ou un parcours général.'
            : 'No match found — try a simpler word or pick a general track.');
  String get clinicalTracksSectionTitle => isArabic
      ? 'مسارات المتابعة اليومية'
      : (isFrench ? 'Parcours de suivi adaptés' : 'Active Care Tracks');
  String get doctorDossierConditionMarkersTitle => isArabic
      ? 'مؤشرات المتابعة الخاصة بالحالة'
      : (isFrench ? 'Repères spécifiques au parcours' : 'Condition-specific markers');
  String get yourDailyQuestionsPreviewLabel => isArabic
      ? 'الأسئلة اليومية اللي باش نركّزو عليها:'
      : (isFrench ? 'Vos repères quotidiens adaptés :' : 'Daily check-ins tailored for you:');

  // Two-Sided Product Edition, Roster Search & Clinic Pairing
  String get searchPatientsHint => isArabic
      ? 'ابحث بالاسم أو رمز المريض...'
      : (isFrench
            ? 'Rechercher un patient par nom ou ID...'
            : 'Search patient by name or ID...');

  String get clinicInviteCodeTitle => isArabic
      ? 'رمز العيادة لدعوة المرضى'
      : (isFrench
            ? 'Code clinique pour vos patients'
            : 'Clinic pairing code for patients');

  String get clinicInviteCodeSub => isArabic
      ? 'شارك هذا الرمز مع مرضاك باش يتواصلوا مع ملف العيادة'
      : (isFrench
            ? 'Donnez ce code à vos patients pour recevoir leur suivi'
            : 'Share this code with your patients so they link their updates to you');

  String get copyInviteMsgBtn => isArabic
      ? 'نسخ دعوة المريض'
      : (isFrench ? 'Copier l’invitation patient' : 'Copy patient invite');

  String get patientInviteCopiedToast => isArabic
      ? 'تم نسخ دعوة المريض ورمز العيادة'
      : (isFrench
            ? 'Invitation patient et code clinique copiés'
            : 'Patient invite & clinic code copied');

  String get clinicCodeOptionalTitle => isArabic
      ? 'عندك رمز عيادة من طبيبك؟ (اختياري)'
      : (isFrench
            ? 'Code clinique de votre médecin ? (facultatif)'
            : 'Have a clinic code from your doctor? (optional)');

  String get clinicCodeFieldHint => isArabic
      ? 'مثال: MIND-SBA-42'
      : (isFrench ? 'Ex : MIND-SBA-42' : 'e.g. MIND-SBA-42');

  String clinicInviteShareMessage(String doctor, String clinic, String code) {
    if (isArabic) {
      return 'مرحباً، استعمل تطبيق Mindora لمتابعة حالتك اليومية مع $doctor ($clinic). رمز العيادة: $code';
    }
    if (isFrench) {
      return 'Bonjour, suivez votre rythme quotidien sur Mindora avec $doctor ($clinic). Code clinique : $code';
    }
    return 'Welcome to Mindora for your daily follow-up with $doctor ($clinic). Clinic code: $code';
  }

  String get privacyBadgeTitle => isArabic
      ? 'خصوصية على تليفونك'
      : (isFrench ? 'Privé sur votre téléphone' : 'Private on device');

  String get clinicPortalAuthBanner => isArabic
      ? 'فضاء الأطباء والإدارة'
      : (isFrench
            ? 'Accès Médecin / Administration'
            : 'Doctor / Clinic Admin Access');

  String get clinicPortalAuthSub => isArabic
      ? 'إدارة قائمة مرضاك ومتابعة حالاتهم اليومية.'
      : (isFrench
            ? 'Accédez à votre liste de patients et à leur suivi clinique.'
            : 'Open your patient roster and follow up on shared logs.');

  String get addOrImportPatientBtn => isArabic
      ? 'إضافة / استيراد مريض'
      : (isFrench ? 'Ajouter / Importer' : 'Add / Import');

  String get invitePatientBtn => isArabic
      ? 'دعوة مريض'
      : (isFrench ? 'Inviter patient' : 'Invite patient');

  String get doctorEditionBadge => isArabic
      ? 'فضاء الطبيب والإدارة'
      : (isFrench ? 'Édition Médecin' : 'Doctor Edition');

  String get noSearchMatchPatients => isArabic
      ? 'ما لقيناش مريض يطابق بحثك.'
      : (isFrench
            ? 'Aucun patient ne correspond à cette recherche.'
            : 'No patients match this search.');

  String get clearFilterBtn =>
      isArabic ? 'مسح' : (isFrench ? 'Effacer' : 'Clear');

  String get filterSampleShort =>
      isArabic ? 'نماذج' : (isFrench ? 'Exemples' : 'Samples');

  String patientTrackCountLabel(int count) {
    if (isArabic) return '$count محاور';
    if (isFrench) return '$count suivis';
    return '$count tracked';
  }

  // Phase 2: Strictly Clinic-Only Patient Login & First-Login Welcome
  String get clinicLoginTitle => isArabic
      ? 'الدخول إلى Mindora'
      : (isFrench ? 'Se connecter à Mindora' : 'Log in to Mindora');

  String get clinicLoginSubtitle => isArabic
      ? 'استعمل كود الـ QR ولا المعطيات اللّي عطاهملك الطبيب متاعك.'
      : (isFrench
            ? 'Utilisez le QR code ou les identifiants remis par votre médecin.'
            : 'Use the QR code or login details your doctor gave you.');

  String get scanDoctorQrBtn => isArabic
      ? 'مسح كود الطبيب (QR)'
      : (isFrench ? 'Scanner le QR du médecin' : 'Scan doctor’s QR');

  String get scanDoctorQrSub => isArabic
      ? 'أسرع طريقة في العيادة — من غير ما تكتب شيء.'
      : (isFrench
            ? 'Le plus rapide au cabinet, sans rien taper.'
            : 'Fastest in the clinic — no typing needed.');

  String get scanDoctorQrSheetTitle => isArabic
      ? 'امسح كود العيادة'
      : (isFrench ? 'Scanner le QR de la clinique' : 'Scan clinic QR code');

  String get scanDoctorQrSheetSub => isArabic
      ? 'وجّه الكاميرا للكود اللّي على شاشة الطبيب.'
      : (isFrench
            ? 'Pointez votre caméra vers le code affiché sur l’écran du médecin.'
            : 'Point your camera at the invite code on your doctor’s screen.');

  String get enterQrCodeFallbackBtn => isArabic
      ? 'أو ألصق كود الدعوة'
      : (isFrench ? 'Ou coller le code d’invitation' : 'Or enter invite code');

  String get orLogInWithIdLabel => isArabic
      ? 'ولا أدخل بالمعرّف والكود PIN'
      : (isFrench
            ? 'Ou entrez votre identifiant et code PIN'
            : 'Or log in with your ID & PIN');

  String get loginIdentifierLabel => isArabic
      ? 'رقم الهاتف ولا اسم المستخدم'
      : (isFrench ? 'Téléphone ou identifiant' : 'Phone number or username');

  String get loginIdentifierHint => isArabic
      ? 'مثال: 22 444 555'
      : (isFrench ? 'ex. 22 444 555 ou yassine' : 'e.g. 22 444 555 or yassine');

  String get pinFieldLabel => isArabic
      ? 'الكود PIN ولا كلمة السر'
      : (isFrench ? 'Code PIN ou mot de passe' : 'PIN or password');

  String get pinFieldHint => isArabic
      ? 'أدخل الكود متاعك'
      : (isFrench ? 'Entrez votre code à 6 chiffres' : 'Enter your PIN');

  String get logInBtn =>
      isArabic ? 'دخول' : (isFrench ? 'Se connecter' : 'Log in');

  String get largerTextToggleLabel =>
      isArabic ? 'خط أكبر' : (isFrench ? 'Grand texte' : 'Larger text');

  String clinicWelcomeTitle(String name) {
    final clean = name.trim();
    if (clean.isEmpty) {
      return isArabic ? 'مرحبا بك' : (isFrench ? 'Bienvenue' : 'Welcome');
    }
    return isArabic
        ? 'مرحبا بك، $clean'
        : (isFrench ? 'Bienvenue, $clean' : 'Welcome, $clean');
  }

  String clinicWelcomeConnectedTo(String doctorName) => isArabic
      ? 'حسابك مربوط مع $doctorName'
      : (isFrench
            ? 'Vous êtes relié(e) à $doctorName'
            : 'You are connected to $doctorName');

  String get clinicWelcomeAutoSyncTitle => isArabic
      ? 'متابعة يومية تلقائية مع طبيبك'
      : (isFrench
            ? 'Partage automatique avec votre médecin'
            : 'Automatic updates for your doctor');

  String clinicWelcomeAutoSyncBody(String doctorName) => isArabic
      ? 'تسجيلاتك اليومية توصل أوتوماتيكياً لـ $doctorName باش تحضّر زيارتك الجاية. تنجم تقفل أي ملاحظة أو حوار "ليّ وحدي" وقت ما تحب.'
      : (isFrench
            ? 'Vos bilans quotidiens informent automatiquement $doctorName pour préparer vos visites. Vous pouvez verrouiller toute note ou discussion « Rien que pour moi » à tout moment.'
            : 'Your daily check-ins automatically update $doctorName so visits stay effortless. You can mark any note or talk "Keep just for me" anytime.');

  String get clinicWelcomeNotEmergencyTitle => isArabic
      ? 'هذا ما هوش رقم طوارئ 24/24'
      : (isFrench
            ? 'Pas une ligne d’urgence 24/7'
            : 'Not a 24/7 emergency monitor');

  String get clinicWelcomeNotEmergencyBody => isArabic
      ? 'طبيبك يراجع المعطيات قبل الموعد. كان تحس روحك في خطر، اضغط عالدرع الأحمر باش تلقى أرقام النجدة في الحين.'
      : (isFrench
            ? 'Votre médecin consulte vos bilans autour des rendez-vous. En cas d’urgence, appuyez sur le bouclier rouge pour obtenir une aide immédiate.'
            : 'Your doctor reviews updates around appointments. If you ever feel unsafe, tap the red shield for immediate emergency help lines.');

  String get setOwnPinOptionalBtn => isArabic
      ? 'تبديل الكود PIN لكود شخصي (اختياري)'
      : (isFrench
            ? 'Choisir mon propre code PIN (optionnel)'
            : 'Choose my own PIN (optional)');

  String get currentPinLabel => isArabic
      ? 'الكود PIN الحالي'
      : (isFrench ? 'Code PIN actuel' : 'Current PIN');

  String get newPinLabel => isArabic
      ? 'الكود PIN الجديد'
      : (isFrench ? 'Nouveau code PIN' : 'New PIN');

  String get saveNewPinBtn => isArabic
      ? 'حفظ الكود الجديد'
      : (isFrench ? 'Enregistrer le nouveau code' : 'Save new PIN');

  String get pinChangedToast => isArabic
      ? 'تبدّل الكود PIN متاعك بنجاح.'
      : (isFrench ? 'Votre code PIN a été mis à jour.' : 'Your PIN was updated.');

  String get enterAppBtn => isArabic
      ? 'ابدأ نهاري'
      : (isFrench ? 'Commencer ma journée' : 'Start my day');

  // --- Phase 3: Patient Minimalism, Privacy Lock & Clean Account ---
  String get keepJustForMeLabel => isArabic
      ? 'خلّيه ليا وحدي'
      : (isFrench ? 'Garder rien que pour moi' : 'Keep just for me');

  String get keepJustForMeDesc => isArabic
      ? 'سري على تليفونك · ما يتبعثش لطبيبك'
      : (isFrench
            ? 'Privé sur ce téléphone · non envoyé au médecin'
            : 'Private on this phone · not sent to your doctor');

  String get sharedWithDoctorStatus => isArabic
      ? 'يتشارك مع طبيبك تلقائيا'
      : (isFrench
            ? 'Inclus dans le suivi du médecin'
            : 'Included in doctor care view');

  String get syncedQuietLabel =>
      isArabic ? 'مزامن' : (isFrench ? 'Synchronisé' : 'Synced');

  String get savedOnPhoneLabel => isArabic
      ? 'محفوظ هنا'
      : (isFrench ? 'Sur cet appareil' : 'Saved on phone');

  String connectedToDoctorBadge(String doctorName) => isArabic
      ? 'مربوط مع $doctorName · مزامنة تلقائية'
      : (isFrench
            ? 'Suivi par $doctorName · Synchronisé'
            : 'Connected to $doctorName · Auto-synced');

  String get privacyAccountSection => isArabic
      ? 'الخصوصية والحساب'
      : (isFrench ? 'Confidentialité & compte' : 'Privacy & account');

  String get changePinBtn => isArabic
      ? 'تبديل الكود PIN'
      : (isFrench ? 'Changer mon code PIN' : 'Change my PIN');

  String get logOutBtn => isArabic
      ? 'خروج من الحساب'
      : (isFrench ? 'Se déconnecter' : 'Log out');

  String get logOutConfirmTitle => isArabic
      ? 'تحب تخرج من الحساب؟'
      : (isFrench ? 'Se déconnecter de Mindora ?' : 'Log out of Mindora?');

  String get logOutConfirmBody => isArabic
      ? 'معطياتك تبقى في أمان عند طبيبك، وتنجم ترجع وقت ما تحب بالكود أو بالـ QR.'
      : (isFrench
            ? 'Votre suivi reste en sécurité chez votre médecin. Vous pourrez vous reconnecter avec votre code PIN ou le QR du médecin.'
            : 'Your clinical connection stays safe with your doctor. You can sign back in anytime with your PIN or doctor QR.');

  // --- Phase 4: Doctor Admin Provisioning & Access Controls ---
  String get createPatientAccountBtn => isArabic
      ? 'زيد مريض'
      : (isFrench ? 'Ajouter un patient' : 'Add patient');

  String get createPatientTitle => isArabic
      ? 'فتح حساب مريض جديد'
      : (isFrench ? 'Créer un compte patient' : 'Create patient account');

  String get createPatientSubtitle => isArabic
      ? 'طلّع QR وكود مؤقت باش المريض يدخل مباشرة من غير تعقيد.'
      : (isFrench
            ? 'Générez un QR et un code PIN provisoire pour connecter le patient en consultation.'
            : 'Generate an in-office QR code and temporary PIN so your patient signs in once.');

  String get patientFullNameLabel => isArabic
      ? 'اسم المريض'
      : (isFrench ? 'Nom du patient' : 'Patient name');

  String get patientIdentifierLabel => isArabic
      ? 'رقم الهاتف أو اسم الدخول'
      : (isFrench ? 'Téléphone ou identifiant' : 'Phone number or username');

  String get patientAgeGroupLabel => isArabic
      ? 'الفئة العمرية'
      : (isFrench ? 'Tranche d’âge' : 'Age group');

  String get patientLanguageLabel => isArabic
      ? 'لغة التطبيق'
      : (isFrench ? 'Langue préférée' : 'Preferred language');

  String get patientCareTracksLabel => isArabic
      ? 'محاور المتابعة (اختياري)'
      : (isFrench ? 'Axes de suivi (optionnel)' : 'Focus areas (optional)');

  String get generatePatientAccessBtn => isArabic
      ? 'إنشاء الحساب والـ QR'
      : (isFrench ? 'Créer l’accès & QR' : 'Create account & QR');

  String get patientAccessReadyTitle => isArabic
      ? 'حساب المريض جاهز'
      : (isFrench ? 'Accès patient prêt' : 'Patient access ready');

  String get patientTempPinLabel => isArabic
      ? 'الكود المؤقت PIN'
      : (isFrench ? 'Code PIN provisoire' : 'Temporary PIN');

  String get patientQrExpireNote => isArabic
      ? 'صالح 24 ساعة · يتسكانا مرة برك · الـ QR ما فيه حتى معطيات شخصية'
      : (isFrench
            ? 'Valable 24h · usage unique · aucune donnée personnelle dans le QR'
            : 'Valid 24h · single scan · zero personal data inside QR');

  String get copyPinAndIdBtn => isArabic
      ? 'نسخ اسم الدخول والكود'
      : (isFrench ? 'Copier identifiant & PIN' : 'Copy login & PIN');

  String get accessCopiedToast => isArabic
      ? 'تنسخ اسم الدخول والكود المؤقت.'
      : (isFrench ? 'Identifiant et code PIN copiés.' : 'Login ID and PIN copied.');

  String get clinicAccessAdminSection => isArabic
      ? 'إدارة دخول المريض'
      : (isFrench ? 'Accès compte clinique' : 'Clinic account access');

  String get resetPinAndQrBtn => isArabic
      ? 'تبديل الكود و QR جديد'
      : (isFrench ? 'Nouveau code PIN & QR' : 'Reset PIN & new QR');

  String get pausePatientAccessBtn => isArabic
      ? 'تعليق الدخول'
      : (isFrench ? 'Suspendre l’accès' : 'Pause access');

  String get resumePatientAccessBtn => isArabic
      ? 'تفعيل الدخول'
      : (isFrench ? 'Rétablir l’accès' : 'Resume access');

  String get editCareTracksBtn => isArabic
      ? 'تبديل محاور المتابعة'
      : (isFrench ? 'Modifier les axes' : 'Edit focus areas');

  String get accountPausedBadge => isArabic
      ? 'الدخول معلق'
      : (isFrench ? 'Accès suspendu' : 'Access paused');

  String get accountActiveBadge => isArabic
      ? 'حساب نشط'
      : (isFrench ? 'Accès actif' : 'Active clinic access');

  String get accountPausedToast => isArabic
      ? 'تم تعليق دخول هذا الحساب.'
      : (isFrench ? 'L’accès patient a été suspendu.' : 'Patient access paused.');

  String get accountResumedToast => isArabic
      ? 'رجع الحساب يخدم بنجاح.'
      : (isFrench ? 'L’accès patient a été rétabli.' : 'Patient access resumed.');

  String get previewAsPatientDemoBtn => isArabic
      ? 'معاينة شاشة المريض (تجربة)'
      : (isFrench ? 'Aperçu vue Patient (Démo)' : 'Preview as Patient (Demo)');

  String get fillRequiredFieldsError => isArabic
      ? 'عمّر الاسم ورقم الهاتف ولا اسم الدخول قبل.'
      : (isFrench
            ? 'Veuillez saisir le nom et l’identifiant du patient.'
            : 'Please enter the patient name and phone or username.');

  // Phase 0: Clinician Auth Gate & Honest Roster Lifecycle
  String get clinicianAuthTitle => isArabic
      ? 'دخول فضاء الطبيب'
      : (isFrench ? 'Accès espace médecin' : 'Doctor workspace lock');

  String get clinicianAuthSubtitle => isArabic
      ? 'أدخل الرمز السري لعيادتك باش تحل ملفات المرضى.'
      : (isFrench
            ? 'Saisissez le code PIN de votre cabinet pour ouvrir vos dossiers.'
            : 'Enter your clinic PIN to open patient records.');

  String get clinicianPinSetupTitle => isArabic
      ? 'إعداد الرمز السري للطبيب'
      : (isFrench ? 'Créer votre code PIN médecin' : 'Set your clinic PIN');

  String get clinicianPinSetupSubtitle => isArabic
      ? 'احمي ملفات مرضاك برمز سري (من 4 إلى 6 أرقام) قبل ما تبدا.'
      : (isFrench
            ? 'Protégez les dossiers patients avec un code PIN (4 à 6 chiffres) avant de commencer.'
            : 'Protect patient records with a 4–6 digit clinic PIN before entering.');

  String get clinicianPinFieldLabel => isArabic
      ? 'الرمز السري للعيادة'
      : (isFrench ? 'Code PIN du cabinet' : 'Clinic PIN');

  String get clinicianConfirmPinLabel => isArabic
      ? 'تأكيد الرمز السري'
      : (isFrench ? 'Confirmer le code PIN' : 'Confirm PIN');

  String get clinicianUnlockBtn => isArabic
      ? 'فتح فضاء الطبيب'
      : (isFrench ? 'Ouvrir l’espace médecin' : 'Unlock workspace');

  String get clinicianCreatePinBtn => isArabic
      ? 'حفظ الرمز والدخول'
      : (isFrench ? 'Enregistrer et ouvrir' : 'Save PIN & enter');

  String get clinicianLockWorkspaceBtn => isArabic
      ? 'قفل فضاء الطبيب'
      : (isFrench ? 'Verrouiller l’espace médecin' : 'Lock workspace');

  String get clinicianPinTooShortError => isArabic
      ? 'الرمز السري لازم يكون فيه على الأقل 4 أرقام.'
      : (isFrench
            ? 'Le code PIN doit contenir au moins 4 chiffres.'
            : 'PIN must be at least 4 digits.');

  String get clinicianPinMismatchError => isArabic
      ? 'الرمزين ما يتطابقوش، عاود ثبت.'
      : (isFrench
            ? 'Les deux codes PIN ne correspondent pas.'
            : 'PINs do not match.');

  String get clinicianInvalidPinError => isArabic
      ? 'الرمز السري غير صحيح.'
      : (isFrench ? 'Code PIN incorrect.' : 'Incorrect clinic PIN.');

  String get awaitingFirstLoginBadge => isArabic
      ? 'في انتظار أول دخول'
      : (isFrench ? 'En attente de 1re connexion' : 'Awaiting first login');

  String get connectedNoCheckInsLabel => isArabic
      ? 'متصل · لا توجد تسجيلات بعد'
      : (isFrench ? 'Connecté · Aucun suivi encore' : 'Connected · No check-ins yet');

  String buildingBaselineBadge(int days) => isArabic
      ? 'تجميع المرجع ($days/7 أيام)'
      : (isFrench ? 'Repère en cours ($days/7 j)' : 'Building baseline ($days/7d)');

  // Phase 2: Exhaustive Localized Errors, Biometrics, Reminders & Doctor Preferences
  String localizedClinicAuthError(ClinicAuthErrorCode code) {
    switch (code) {
      case ClinicAuthErrorCode.invalidCredentials:
        return isArabic
            ? 'رقم الهاتف أو الرمز السري غير صحيح. ثبّت وعاود المحاولة.'
            : (isFrench
                  ? 'Identifiant ou code PIN incorrect. Vérifiez et réessayez.'
                  : 'Incorrect login ID or PIN. Please check and try again.');
      case ClinicAuthErrorCode.accountPaused:
        return isArabic
            ? 'حسابك موقوف مؤقتاً من العيادة. اتصل بطبيبك.'
            : (isFrench
                  ? 'Ce compte est mis en pause par votre cabinet. Contactez votre médecin.'
                  : 'This account is paused. Please contact your clinic.');
      case ClinicAuthErrorCode.inviteExpired:
        return isArabic
            ? 'رمز الدعوة هذا فات وقته. اطلب رمز جديد من طبيبك.'
            : (isFrench
                  ? 'Ce code d’invitation a expiré. Demandez un nouveau code à votre médecin.'
                  : 'This invitation code has expired. Ask your doctor for a new one.');
      case ClinicAuthErrorCode.inviteAlreadyUsed:
        return isArabic
            ? 'رمز الدعوة هذا استُعمل قبل. ادخل برقمك والرمز السري ولا اطلب رمز جديد.'
            : (isFrench
                  ? 'Ce code d’invitation a déjà été utilisé. Connectez-vous avec votre code PIN ou demandez un nouveau code.'
                  : 'This invitation code has already been used. Log in with your PIN or ask your doctor for a new code.');
      case ClinicAuthErrorCode.inviteRevoked:
        return isArabic
            ? 'طبيبك بدّل رمز الدعوة هذا. استعمل الرمز الجديد.'
            : (isFrench
                  ? 'Cette invitation a été remplacée par votre médecin. Utilisez le nouveau code.'
                  : 'This invitation was replaced by your doctor. Use the newer code.');
      case ClinicAuthErrorCode.invalidQrFormat:
        return isArabic
            ? 'رمز QR أو كود الدخول هذا غير صالح. ثبّت إنه من عيادتك.'
            : (isFrench
                  ? 'Code QR ou code d’accès non reconnu. Vérifiez qu’il provient de votre cabinet.'
                  : 'Unrecognized clinic QR or access code. Check that it came from your doctor.');
      case ClinicAuthErrorCode.duplicateIdentifier:
        return isArabic
            ? 'يوجد حساب مريض آخر مسجّل بنفس رقم الهاتف أو اسم الدخول.'
            : (isFrench
                  ? 'Un compte patient utilise déjà ce numéro ou cet identifiant.'
                  : 'A patient account already uses this phone number or username.');
      case ClinicAuthErrorCode.weakPin:
        return isArabic
            ? 'الرمز السري لازم يكون فيه على الأقل 4 أرقام.'
            : (isFrench
                  ? 'Le code PIN doit contenir au moins 4 caractères.'
                  : 'PIN must be at least 4 characters.');
      case ClinicAuthErrorCode.accountNotFound:
        return isArabic
            ? 'ما لقيناش حساب مريض بهذا المعرّف.'
            : (isFrench
                  ? 'Aucun compte patient trouvé pour cet identifiant.'
                  : 'Patient account not found.');
    }
  }

  String localizedClinicianSyncError(ClinicianSyncErrorCode code) {
    switch (code) {
      case ClinicianSyncErrorCode.invalidFormat:
        return isArabic
            ? 'رمز المزامنة غير مكتمل أو بصيغة غير صالحة.'
            : (isFrench
                  ? 'Format du code de synchronisation invalide ou incomplet.'
                  : 'Invalid or malformed sync code format.');
      case ClinicianSyncErrorCode.unsupportedVersion:
        return isArabic
            ? 'نسخة ملف المزامنة غير مدعومة في هذا الإصدار.'
            : (isFrench
                  ? 'Version du paquet de synchronisation non prise en charge.'
                  : 'Unsupported sync packet version.');
      case ClinicianSyncErrorCode.decryptionFailed:
        return isArabic
            ? 'تعذّر فك التشفير. ثبّت في كلمة المرور وعاود المحاولة.'
            : (isFrench
                  ? 'Déchiffrement impossible. Vérifiez la phrase secrète et réessayez.'
                  : 'Unable to decrypt sync code. Check the passphrase and try again.');
      case ClinicianSyncErrorCode.integrityMismatch:
        return isArabic
            ? 'فشل التحقق من سلامة الملف (أو وجود محتوى خاص محظور).'
            : (isFrench
                  ? 'Échec de vérification d’intégrité du paquet (ou contenu privé rejeté).'
                  : 'Packet integrity check failed (or private content was rejected).');
    }
  }

  String get genericActionError => isArabic
      ? 'صار مشكل صغير، عاود حاول بعد لحظة.'
      : (isFrench
            ? 'Une erreur s’est produite. Veuillez réessayer.'
            : 'Something went wrong. Please try again.');

  String get biometricUnlockReason => isArabic
      ? 'أكّد هويتك باش تحل خزينة Mindora'
      : (isFrench
            ? 'Authentifiez-vous pour déverrouiller Mindora'
            : 'Authenticate to unlock your Mindora vault');

  String get biometricEnableReason => isArabic
      ? 'أكّد البصمة لتفعيل قفل التطبيق'
      : (isFrench
            ? 'Confirmez la biométrie pour activer le verrouillage'
            : 'Confirm biometrics to enable app lock');

  String get clinicianBiometricReason => isArabic
      ? 'أكّد هويتك باش تحل فضاء الطبيب'
      : (isFrench
            ? 'Authentifiez-vous pour ouvrir l’espace médecin'
            : 'Unlock Mindora Doctor Workspace');

  String get reminderChannelName => isArabic
      ? 'تذكيرات يومية لطيفة'
      : (isFrench ? 'Rappels quotidiens doux' : 'Gentle Check-In Reminders');

  String get reminderChannelDescription => isArabic
      ? 'تذكير اختياري وبسيط باش تسجّل كيفاش تحس اليوم.'
      : (isFrench
            ? 'Rappels optionnels et bienveillants pour votre bilan quotidien.'
            : 'Optional, gentle prompts to pause and record a daily check-in.');

  String get workspacePreferencesSection => isArabic
      ? 'اللغة والمظهر'
      : (isFrench ? 'Langue et affichage' : 'Language & display');

  String get switchLanguageTooltip => isArabic
      ? 'تغيير اللغة'
      : (isFrench ? 'Changer de langue' : 'Switch language');

  String credentialsCopyText({
    required String patientName,
    required String loginId,
    required String pin,
    required String doctorName,
  }) {
    if (isArabic) {
      return 'Mindora — $patientName\nالمعرّف: $loginId\nالرمز السري المؤقت: $pin\nالطبيب: $doctorName';
    }
    if (isFrench) {
      return 'Mindora — $patientName\nIdentifiant : $loginId\nCode PIN temporaire : $pin\nMédecin : $doctorName';
    }
    return 'Mindora — $patientName\nLogin: $loginId\nTemporary PIN: $pin\nDoctor: $doctorName';
  }

  // Phase 3: Vector Multi-Page PDF & Patient Welcome Card Export
  String get printPdfBtn => isArabic
      ? 'طباعة ملف PDF'
      : (isFrench ? 'Imprimer le PDF' : 'Print PDF');

  String get includeClinicianNotesToggle => isArabic
      ? 'تضمين ملاحظات الطبيب الخاصة'
      : (isFrench
            ? 'Inclure mes notes cliniques'
            : 'Include doctor consultation notes');

  String get includeClinicianNotesSub => isArabic
      ? 'فعّلها لأرشيف الملف الطبي، وأغلقها قبل تسليم النسخة للمريض.'
      : (isFrench
            ? 'Activez pour le dossier médical, désactivez avant de remettre au patient.'
            : 'Keep on for EHR/referral archive; turn off before handing a copy to the patient.');

  String pdfPagesBadge(int pages) {
    if (isArabic) {
      if (pages == 1) return 'PDF متجه · صفحة واحدة';
      if (pages == 2) return 'PDF متجه · صفحتان';
      return 'PDF متجه · $pages صفحات';
    }
    if (isFrench) {
      return pages == 1 ? 'PDF vectoriel · 1 page' : 'PDF vectoriel · $pages pages';
    }
    return pages == 1 ? 'Vector PDF · 1 page' : 'Vector PDF · $pages pages';
  }

  String pageOfPagesLabel(int page, int total) => isArabic
      ? 'صفحة $page من $total'
      : (isFrench ? 'Page $page sur $total' : 'Page $page of $total');

  String get confidentialRecordBadge => isArabic
      ? 'وثيقة سريرية سرّية'
      : (isFrench ? 'Document clinique confidentiel' : 'Confidential clinical record');

  String get pdfExportFailedError => isArabic
      ? 'تعذّر حفظ أو مشاركة ملف PDF. عاود المحاولة.'
      : (isFrench
            ? 'Impossible d’exporter ou de partager le PDF. Veuillez réessayer.'
            : 'Could not export or share the PDF. Please try again.');

  String get pdfPrintedToast => isArabic
      ? 'تفتح نافذة الطباعة الآن.'
      : (isFrench ? 'Impression prête.' : 'Print dialog opened.');

  String get printWelcomeCardBtn => isArabic
      ? 'طباعة / حفظ بطاقة الدخول (PDF)'
      : (isFrench
            ? 'Imprimer / Enregistrer la carte d’accès (PDF)'
            : 'Print / Save Welcome Card (PDF)');

  String get welcomeCardTitle => isArabic
      ? 'بطاقة الدخول الشخصية إلى Mindora'
      : (isFrench
            ? 'Votre carte d’accès personnelle Mindora'
            : 'Your Personal Mindora Access Card');

  String get welcomeCardStepsTitle => isArabic
      ? 'كيفاش تدخل في 3 خطوات بسيطة'
      : (isFrench
            ? 'Comment vous connecter en 3 étapes simples'
            : 'How to sign in — 3 simple steps');

  String get welcomeCardStep1 => isArabic
      ? '1. افتح تطبيق Mindora على هاتفك.'
      : (isFrench
            ? '1. Ouvrez l’application Mindora sur votre téléphone.'
            : '1. Open the Mindora app on your phone.');

  String get welcomeCardStep2 => isArabic
      ? '2. اضغط على «امسح رمز QR متاع طبيبك»، ولا أدخل المعرّف والرمز السري أسفله.'
      : (isFrench
            ? '2. Touchez « Scanner le QR du médecin » ou saisissez votre identifiant et votre code PIN.'
            : '2. Tap “Scan doctor’s QR”, or type your Login ID and Temporary PIN below.');

  String get welcomeCardStep3 => isArabic
      ? '3. سجّل حالتك كل يوم بهدوء. تقدر تقفل أي ملاحظة خاصة باش تبقى ليك وحدك.'
      : (isFrench
            ? '3. Notez votre journée en douceur. Tout élément marqué « Privé » reste uniquement sur votre téléphone.'
            : '3. Check in gently each day. Any entry you mark “Keep just for me” stays strictly on your phone.');

  String get welcomeCardHelplinesFooter => isArabic
      ? 'في حالة طوارئ نفسية أو صحية عاجلة (تونس): الخط الأخضر 80 10 50 50 · الاستعجالي 190 · الحماية المدنية 198'
      : (isFrench
            ? 'Urgence médicale ou détresse aiguë (Tunisie) : Ligne Verte 80 10 50 50 · SAMU 190 · Protection Civile 198'
            : 'For urgent medical or mental health emergencies (Tunisia): Ligne Verte 80 10 50 50 · SAMU 190 · Civil Protection 198');

  String get tryAgainBtn => isArabic
      ? 'إعادة المحاولة'
      : (isFrench ? 'Réessayer' : 'Try again');

  String get preVisitAgendaHeader => isArabic
      ? 'نقاط التحضير للزيارة'
      : (isFrench ? 'Ordre du jour pré-visite' : 'Pre-visit agenda');

  String get postVisitFocusTitle => isArabic
      ? 'خطة التركيز بين الزيارات'
      : (isFrench ? 'Plan de suivi inter-séances' : 'Between-visit focus plan');

  String get baselineTableHeader => isArabic
      ? 'مقارنة آخر 7 أيام بالمرجع الشخصي'
      : (isFrench
            ? 'Métriques sur 7 jours vs repère personnel'
            : '7-day metrics vs personal baseline');

  String get baselineShiftsHeader => isArabic
      ? 'التغيّرات الملاحظة عن المرجع الشخصي'
      : (isFrench
            ? 'Écarts observés par rapport au repère'
            : 'Observed shifts from personal baseline');

  String get noShiftsDetectedLabel => isArabic
      ? 'لا توجد تغيّرات ملحوظة مقارنة بالمرجع الشخصي.'
      : (isFrench
            ? 'Aucun écart notable par rapport au repère personnel.'
            : 'No notable shifts detected relative to personal baseline.');

  String get sharedReflectionsTab => isArabic
      ? 'التأملات والحوارات المشتركة'
      : (isFrench ? 'Réflexions partagées' : 'Shared reflections');

  String get noSharedReflectionsLabel => isArabic
      ? 'لم تتم مشاركة أي جلسات تأمل في هذه الحزمة.'
      : (isFrench
            ? 'Aucune réflexion partagée dans ce paquet.'
            : 'No shared reflection sessions in this packet.');

  String get clinicianNotesTab => isArabic
      ? 'ملاحظات الطبيب السريرية'
      : (isFrench ? 'Notes cliniques du médecin' : 'Clinician consultation notes');

  String get encryptedQrHeader => isArabic
      ? 'رمز QR المشفّر لنقل البيانات داخل العيادة'
      : (isFrench
            ? 'QR chiffré pour transfert hors ligne en cabinet'
            : 'Encrypted in-room handoff QR');

  String get qrOfflineTransferHint => isArabic
      ? 'يمسح الطبيب هذا الرمز لاستيراد الحزمة محلياً دون رفعها للسحابة، باستخدام رمز المرور الشفهي.'
      : (isFrench
            ? 'Scannez ce QR pour importer le dossier localement hors ligne avec la phrase secrète convenue.'
            : 'Scan this QR in Mindora Doctor to import offline with the patient’s verbal room PIN.');

  String daysTrackedBadge(int count) {
    if (isArabic) {
      if (count == 1) return 'يوم واحد مسجّل';
      if (count == 2) return 'يومان مسجّلان';
      return '$count أيام مسجّلة';
    }
    if (isFrench) {
      return count == 1 ? '1 jour suivi' : '$count jours suivis';
    }
    return count == 1 ? '1 day tracked' : '$count days tracked';
  }

  // Phase 4: Doctor Portal Clinical Dossier, Clinical Queue Dashboard & Audit Log
  String get clinicalSummaryTitle => isArabic
      ? 'الملخص السريري (موثّق من الطبيب)'
      : (isFrench
            ? 'Synthèse clinique (documentée par le médecin)'
            : 'Clinical summary (clinician documented)');

  String get clinicianDocumentedBadge => isArabic
      ? 'موثّق من الطبيب'
      : (isFrench ? 'Documenté par le médecin' : 'Clinician documented');

  String get patientSelfReportedBadge => isArabic
      ? 'مصرّح به من المريض'
      : (isFrench ? 'Déclaré par le patient' : 'Patient self-reported');

  String get aiReflectionNonDiagnosticBadge => isArabic
      ? 'تأمل بمساعدة الذكاء الاصطناعي · غير تشخيصي'
      : (isFrench
            ? 'Réflexion assistée par IA · Non diagnostique'
            : 'AI-assisted reflection · Non-diagnostic');

  String get documentedDiagnosesTitle => isArabic
      ? 'التشخيصات الموثّقة'
      : (isFrench ? 'Diagnostics documentés' : 'Documented diagnoses');

  String get addDiagnosisBtn => isArabic
      ? 'إضافة تشخيص'
      : (isFrench ? 'Ajouter un diagnostic' : 'Add diagnosis');

  String get editDiagnosisTitle => isArabic
      ? 'تعديل التشخيص'
      : (isFrench ? 'Modifier le diagnostic' : 'Edit diagnosis');

  String get diagnosisLabelField => isArabic
      ? 'التشخيص السريري'
      : (isFrench ? 'Libellé du diagnostic' : 'Clinical diagnosis label');

  String get diagnosisCodeField => isArabic
      ? 'رمز ICD-11 / DSM-5 (اختياري)'
      : (isFrench
            ? 'Code CIM-11 / DSM-5 (optionnel)'
            : 'ICD-11 / DSM-5 code (optional)');

  String get diagnosisCertaintyLabel => isArabic
      ? 'درجة التأكيد'
      : (isFrench ? 'Certitude diagnostique' : 'Certainty');

  String get diagnosisStatusLabel => isArabic
      ? 'الحالة الحالية'
      : (isFrench ? 'Statut actuel' : 'Status');

  String get clinicalNotesOptionalField => isArabic
      ? 'ملاحظات سريرية (اختياري)'
      : (isFrench ? 'Notes cliniques (optionnel)' : 'Clinical notes (optional)');

  String get noDiagnosesRecordedLabel => isArabic
      ? 'لا يوجد تشخيص موثّق من الطبيب بعد.'
      : (isFrench
            ? 'Aucun diagnostic documenté par le médecin.'
            : 'No clinician-documented diagnoses yet.');

  String get currentMedicationsTitle => isArabic
      ? 'الأدوية الحالية'
      : (isFrench ? 'Traitements en cours' : 'Current medications');

  String get addMedicationBtn => isArabic
      ? 'إضافة دواء'
      : (isFrench ? 'Ajouter un traitement' : 'Add medication');

  String get editMedicationTitle => isArabic
      ? 'تعديل الدواء'
      : (isFrench ? 'Modifier le traitement' : 'Edit medication');

  String get medicationNameField => isArabic
      ? 'اسم الدواء'
      : (isFrench ? 'Nom du médicament' : 'Medication name');

  String get medicationDosageField => isArabic
      ? 'الجرعة (مثال: 300 ملغ)'
      : (isFrench ? 'Posologie (ex. 300 mg)' : 'Dosage (e.g. 300 mg)');

  String get medicationFrequencyField => isArabic
      ? 'التوقيت / التكرار (مثال: مساءً)'
      : (isFrench ? 'Fréquence (ex. le soir)' : 'Schedule (e.g. evening)');

  String get noMedicationsRecordedLabel => isArabic
      ? 'لا توجد أدوية مسجّلة في الملف.'
      : (isFrench ? 'Aucun traitement consigné.' : 'No medications recorded.');

  String get allergiesTitle => isArabic
      ? 'الحساسية والتفاعلات الدوائية'
      : (isFrench ? 'Allergies et intolérances' : 'Allergies & reactions');

  String get addAllergyBtn => isArabic
      ? 'إضافة حساسية'
      : (isFrench ? 'Ajouter une allergie' : 'Add allergy');

  String get allergySubstanceField => isArabic
      ? 'المادة أو الدواء'
      : (isFrench ? 'Substance ou médicament' : 'Substance or drug');

  String get allergyReactionField => isArabic
      ? 'التفاعل (اختياري)'
      : (isFrench ? 'Réaction observée (optionnel)' : 'Reaction (optional)');

  String get allergySeverityLabel =>
      isArabic ? 'الشدة' : (isFrench ? 'Sévérité' : 'Severity');

  String get noKnownAllergiesLabel => isArabic
      ? 'لا توجد حساسية معروفة (موثّق)'
      : (isFrench
            ? 'Aucune allergie connue (documenté)'
            : 'No known allergies documented');

  String get allergiesNotRecordedLabel => isArabic
      ? 'الحساسية غير مسجّلة بعد.'
      : (isFrench ? 'Allergies non renseignées.' : 'Allergies not recorded yet.');

  String get clinicalHistoryAndDetailsTitle => isArabic
      ? 'السوابق السريرية والبيانات'
      : (isFrench
            ? 'Antécédents et coordonnées'
            : 'Clinical history & demographics');

  String get editClinicalDetailsBtn => isArabic
      ? 'تعديل الملف السريري'
      : (isFrench ? 'Modifier le dossier' : 'Edit chart details');

  String get clinicFileNumberField => isArabic
      ? 'رقم الملف الطبي (MRN)'
      : (isFrench ? 'N° de dossier (IPP / MRN)' : 'Clinic file # (MRN)');

  String get patientPhoneField => isArabic
      ? 'هاتف المريض'
      : (isFrench ? 'Téléphone du patient' : 'Patient phone');

  String get biologicalSexField => isArabic
      ? 'الجنس'
      : (isFrench ? 'Sexe' : 'Sex');

  String get referralSourceField => isArabic
      ? 'جهة التحويل'
      : (isFrench ? 'Adressé par' : 'Referral source');

  String get emergencyContactNameField => isArabic
      ? 'اسم جهة الاتصال للطوارئ'
      : (isFrench ? 'Contact d’urgence (nom)' : 'Emergency contact name');

  String get emergencyContactPhoneField => isArabic
      ? 'هاتف جهة الاتصال للطوارئ'
      : (isFrench ? 'Contact d’urgence (tél.)' : 'Emergency contact phone');

  String get psychiatricHistoryField => isArabic
      ? 'السوابق النفسية'
      : (isFrench ? 'Antécédents psychiatriques' : 'Psychiatric history');

  String get medicalHistoryField => isArabic
      ? 'السوابق الطبية والجسدية'
      : (isFrench ? 'Antécédents médicaux' : 'Medical history');

  String get familyHistoryField => isArabic
      ? 'السوابق العائلية (اختياري)'
      : (isFrench
            ? 'Antécédents familiaux (optionnel)'
            : 'Family history (optional)');

  String get safetyProtectiveFactorsField => isArabic
      ? 'عوامل الحماية وملاحظات السلامة (غير تنبؤية)'
      : (isFrench
            ? 'Facteurs protecteurs et repères de sécurité (non prédictif)'
            : 'Protective factors & safety notes (non-predictive)');

  String get nextAppointmentTitle => isArabic
      ? 'الموعد القادم للمتابعة'
      : (isFrench ? 'Prochain rendez-vous' : 'Next follow-up appointment');

  String get noAppointmentScheduledLabel => isArabic
      ? 'لم يتم تحديد موعد قادم بعد.'
      : (isFrench
            ? 'Aucun rendez-vous planifié.'
            : 'No follow-up scheduled yet.');

  String get scheduleFollowUpBtn => isArabic
      ? 'تحديد موعد'
      : (isFrench ? 'Planifier' : 'Schedule');

  String get clearDateBtn =>
      isArabic ? 'إزالة التاريخ' : (isFrench ? 'Effacer la date' : 'Clear date');

  String get safetyPauseAlertBadge => isArabic
      ? 'تنبيه توقّف أمان'
      : (isFrench ? 'Pause sécurité déclenchée' : 'Safety pause triggered');

  String get safetyPauseAlertBanner => isArabic
      ? 'تم تفعيل توقّف الأمان في أحد حوارات المريض المشتركة — راجع قسم الحوارات المشتركة.'
      : (isFrench
            ? 'Une pause de sécurité a été déclenchée dans une réflexion partagée — consultez l’onglet Réflexions.'
            : 'A safety pause was triggered in a shared reflection — review in the Reflections tab.');

  String get patientSelfReportedProfileTitle => isArabic
      ? 'الملف الشخصي المصرّح به من المريض'
      : (isFrench
            ? 'Profil déclaré par le patient'
            : 'Patient self-reported profile');

  String get selfReportedTreatmentLabel => isArabic
      ? 'المتابعة المصرّح بها:'
      : (isFrench ? 'Suivi déclaré :' : 'Self-reported care:');

  String get selfReportedTriggersLabel => isArabic
      ? 'محفّزات ذكرها المريض:'
      : (isFrench ? 'Déclencheurs signalés :' : 'Reported triggers:');

  String get selfReportedGoalsLabel => isArabic
      ? 'أهداف المريض:'
      : (isFrench ? 'Objectifs du patient :' : 'Patient goals:');

  String get singlePatientShiftsTitle => isArabic
      ? 'التغيّرات الملاحظة مقارنة بمرجع المريض'
      : (isFrench
            ? 'Écarts observés par rapport au repère personnel'
            : 'Observed shifts vs. personal baseline');

  String get physicalTensionLabel => isArabic
      ? 'التوتر الجسدي'
      : (isFrench ? 'Tension physique' : 'Physical tension');

  String get preVisitQuestionSubLabel => isArabic
      ? 'سؤال المريض'
      : (isFrench ? 'Question du patient' : 'Patient question');

  String get preVisitHelpedSubLabel => isArabic
      ? 'ما ساعد مؤخراً'
      : (isFrench ? 'Ce qui a aidé récemment' : 'What helped recently');

  String get activeFocusPlanDoctorTitle => isArabic
      ? 'خطة التركيز النشطة بين الزيارات'
      : (isFrench
            ? 'Plan de suivi actif inter-séances'
            : 'Active between-session focus plan');

  String get updateFocusPlanBtn => isArabic
      ? 'تحديث الخطة'
      : (isFrench ? 'Mettre à jour' : 'Update plan');

  String get consentDetailsToggleLabel => isArabic
      ? 'تفاصيل نطاق الموافقة (7 عناصر)'
      : (isFrench
            ? 'Détails du consentement (7 éléments)'
            : 'Consent scope details (7 toggles)');

  String get consentWithheldLabel =>
      isArabic ? 'غير مشارك' : (isFrench ? 'Non partagé' : 'Withheld');

  String get consentIncludedLabel =>
      isArabic ? 'مشارك' : (isFrench ? 'Partagé' : 'Shared');

  String get noCheckInsLoggedYetLabel => isArabic
      ? 'لم يسجّل المريض أي حالة يومية بعد.'
      : (isFrench
            ? 'Aucun bilan quotidien enregistré pour le moment.'
            : 'No daily check-ins logged yet.');

  String get symptomsExcludedByConsentLabel => isArabic
      ? 'سجلات الأعراض مستثناة حسب اختيار موافقة المريض.'
      : (isFrench
            ? 'Les journaux de symptômes sont exclus par le consentement du patient.'
            : 'Symptom logs are excluded by the patient’s consent choice.');

  String get noSymptomLogsRecordedLabel => isArabic
      ? 'لا توجد سجلات أعراض مسجّلة في هذه الفترة.'
      : (isFrench
            ? 'Aucun symptôme enregistré sur cette période.'
            : 'No symptom logs recorded during this window.');

  String get aiSummaryBoxLabel => isArabic
      ? 'ملخص مساعد Mindora الذكي (غير تشخيصي)'
      : (isFrench
            ? 'Synthèse IA Mindora (non diagnostique)'
            : 'AI reflection summary (non-diagnostic)');

  String get patientTakeawayBoxLabel => isArabic
      ? 'خلاصة المريض بكلماته'
      : (isFrench
            ? 'Conclusion rédigée par le patient'
            : 'Patient’s own takeaway');

  String get editNoteTitle => isArabic
      ? 'تعديل الملاحظة السريرية'
      : (isFrench ? 'Modifier la note clinique' : 'Edit clinical note');

  String get deleteNoteConfirmTitle => isArabic
      ? 'حذف هذه الملاحظة؟'
      : (isFrench ? 'Supprimer cette note ?' : 'Delete this note?');

  String get deleteNoteConfirmBody => isArabic
      ? 'سيتم إزالة الملاحظة من الملف السريري. يمكنك التراجع مباشرة بعد الحذف.'
      : (isFrench
            ? 'Cette note sera retirée du dossier. Vous pourrez annuler juste après.'
            : 'This note will be removed from the chart. You can undo right away.');

  String get noteDeletedToast => isArabic
      ? 'تم حذف الملاحظة.'
      : (isFrench ? 'Note supprimée.' : 'Clinical note deleted.');

  String get resetPinConfirmTitle => isArabic
      ? 'إعادة تعيين الرمز السري وإنشاء QR جديد؟'
      : (isFrench
            ? 'Réinitialiser le PIN et générer un nouveau QR ?'
            : 'Reset PIN and generate a new QR?');

  String get resetPinConfirmBody => isArabic
      ? 'سيتم إلغاء الرمز السري المؤقت القديم فوراً وإنشاء رمز دخول جديد للمريض.'
      : (isFrench
            ? 'L’ancien code PIN temporaire sera invalidé immédiatement et un nouvel accès sera créé.'
            : 'The patient’s previous PIN and invite QR will be invalidated immediately.');

  String get markReviewedBtn => isArabic
      ? 'تأكيد المراجعة'
      : (isFrench ? 'Marquer comme revu' : 'Mark reviewed');

  String get reviewedToast => isArabic
      ? 'تم تأكيد مراجعة الملف.'
      : (isFrench ? 'Dossier marqué comme revu.' : 'Patient chart marked reviewed.');

  String get removeImportedPatientBtn => isArabic
      ? 'إزالة هذا الملف المستورد'
      : (isFrench ? 'Retirer ce dossier importé' : 'Remove imported record');

  String get removeImportedPatientConfirm => isArabic
      ? 'هل تريد حذف هذا الملف المستورد يدوياً وملاحظاته من هذا الجهاز؟'
      : (isFrench
            ? 'Supprimer ce dossier importé manuellement et ses notes de cet appareil ?'
            : 'Remove this manually imported record and its local notes from this device?');

  String get clinicalQueueTitle => isArabic
      ? 'قائمة المتابعة اليومية'
      : (isFrench ? 'File clinique du jour' : 'Clinical Queue');

  String get queueNeedsAttentionTitle => isArabic
      ? 'يحتاج انتباهك الآن'
      : (isFrench ? 'À examiner en priorité' : 'Needs attention now');

  String get queueUpcomingFollowUpsTitle => isArabic
      ? 'مواعيد المتابعة القادمة'
      : (isFrench ? 'Suivis planifiés' : 'Upcoming follow-ups');

  String get queueOnboardingWatchTitle => isArabic
      ? 'بانتظار الدخول الأول أو غير نشط'
      : (isFrench
            ? 'En attente de connexion ou inactifs'
            : 'Onboarding & engagement watch');

  String get queueAllClearLabel => isArabic
      ? 'لا توجد تنبيهات عاجلة الآن.'
      : (isFrench
            ? 'Aucune priorité urgente en attente.'
            : 'No urgent alerts right now.');

  String get kpiSafetyAlerts => isArabic
      ? 'تنبيهات أمان'
      : (isFrench ? 'Alertes sécurité' : 'Safety alerts');

  String get kpiPendingFollowUps => isArabic
      ? 'بانتظار الدخول'
      : (isFrench ? 'En attente' : 'Pending');

  String get filterAlerts =>
      isArabic ? 'تنبيهات' : (isFrench ? 'Alertes' : 'Alerts');

  String get filterPendingLogin =>
      isArabic ? 'بانتظار الدخول' : (isFrench ? 'En attente' : 'Pending');

  String get filterPaused =>
      isArabic ? 'متوقّف' : (isFrench ? 'En pause' : 'Paused');

  String get sortRecentLabel =>
      isArabic ? 'الأحدث' : (isFrench ? 'Récent' : 'Recent');

  String get sortPriorityLabel =>
      isArabic ? 'الأولوية' : (isFrench ? 'Priorité' : 'Priority');

  String get sortNameLabel =>
      isArabic ? 'الاسم أ-ي' : (isFrench ? 'Nom A–Z' : 'Name A–Z');

  String get noMatchingPatientsTitle => isArabic
      ? 'لا يوجد مرضى مطابقون لهذا الفلتر'
      : (isFrench
            ? 'Aucun patient ne correspond à ce filtre'
            : 'No patients match this filter');

  String get noMatchingPatientsSub => isArabic
      ? 'جرّب تغيير الفلتر أو مسح نص البحث لعرض كل المرضى.'
      : (isFrench
            ? 'Modifiez le filtre ou effacez la recherche pour afficher tous vos patients.'
            : 'Adjust the filter or clear search to view your full patient list.');

  String get clinicianLicenseRefField => isArabic
      ? 'رقم التسجيل المهني (CNOM)'
      : (isFrench ? 'N° d’inscription (CNOM / RPPS)' : 'Medical license # (CNOM)');

  String get clinicPhoneField => isArabic
      ? 'هاتف العيادة'
      : (isFrench ? 'Téléphone du cabinet' : 'Clinic phone');

  String get clinicAddressField => isArabic
      ? 'عنوان العيادة'
      : (isFrench ? 'Adresse du cabinet' : 'Clinic address');

  String get practiceProfileSavedToast => isArabic
      ? 'تم حفظ بيانات العيادة.'
      : (isFrench ? 'Profil du cabinet enregistré.' : 'Practice profile saved.');

  String get clinicAuditLogTitle => isArabic
      ? 'سجل نشاط وإدارة العيادة'
      : (isFrench ? 'Journal d’activité du cabinet' : 'Clinic activity & audit log');

  String get clinicAuditLogSub => isArabic
      ? 'عرض سجل إنشاء الحسابات، إعادة التعيين، الإيقاف وخطط المتابعة.'
      : (isFrench
            ? 'Historique des comptes créés, réinitialisations, pauses et plans envoyés.'
            : 'View account creation, PIN resets, access pauses, and focus plan actions.');

  String get clinicAuditLogEmpty => isArabic
      ? 'لا توجد عمليات مسجّلة في سجل النشاط بعد.'
      : (isFrench
            ? 'Aucune activité enregistrée pour le moment.'
            : 'No clinic activity recorded yet.');

  String localizedAuditAction(String actionName) {
    if (isArabic) {
      return switch (actionName) {
        'createdAccount' => 'إنشاء حساب مريض',
        'resetAccess' => 'إعادة تعيين الرمز السري و QR',
        'pausedAccount' => 'إيقاف دخول المريض مؤقتاً',
        'resumedAccount' => 'استئناف دخول المريض',
        'updatedTracks' => 'تحديث محاور المتابعة',
        'pushedFocusPlan' => 'إرسال خطة تركيز بين الزيارات',
        'patientQrLogin' => 'دخول المريض عبر QR',
        'patientPinLogin' => 'دخول المريض بالرمز السري',
        'patientPinChanged' => 'تغيير المريض لرمزه السري',
        'safetyNoticeAccepted' => 'موافقة المريض على إشعار الأمان',
        _ => actionName,
      };
    }
    if (isFrench) {
      return switch (actionName) {
        'createdAccount' => 'Compte patient créé',
        'resetAccess' => 'PIN et QR réinitialisés',
        'pausedAccount' => 'Accès patient suspendu',
        'resumedAccount' => 'Accès patient réactivé',
        'updatedTracks' => 'Axes de suivi mis à jour',
        'pushedFocusPlan' => 'Plan inter-séances envoyé',
        'patientQrLogin' => 'Connexion patient via QR',
        'patientPinLogin' => 'Connexion patient par PIN',
        'patientPinChanged' => 'Code PIN modifié par le patient',
        'safetyNoticeAccepted' => 'Notice de sécurité acceptée',
        _ => actionName,
      };
    }
    return switch (actionName) {
      'createdAccount' => 'Patient account created',
      'resetAccess' => 'PIN & QR reset',
      'pausedAccount' => 'Patient access paused',
      'resumedAccount' => 'Patient access resumed',
      'updatedTracks' => 'Focus tracks updated',
      'pushedFocusPlan' => 'Between-session focus plan sent',
      'patientQrLogin' => 'Patient signed in via QR',
      'patientPinLogin' => 'Patient signed in via PIN',
      'patientPinChanged' => 'Patient changed PIN',
      'safetyNoticeAccepted' => 'Patient accepted safety notice',
      _ => actionName,
    };
  }

  String localizedAgeRange(String raw) {
    switch (raw.trim()) {
      case 'under_18':
        return isArabic ? 'أقل من 18 سنة' : (isFrench ? 'Moins de 18 ans' : 'Under 18');
      case '18-24':
        return '18–24';
      case '25-44':
        return '25–44';
      case '45-64':
        return '45–64';
      case '65+':
        return '65+';
      default:
        return raw;
    }
  }

  String inactiveDaysBadge(int days) {
    if (isArabic) return 'بدون تسجيل منذ $days أيام';
    if (isFrench) return 'Inactif depuis ${days}j';
    return 'No logs for ${days}d';
  }

  String get clearOfflineImportsTitle => isArabic
      ? 'مسح الملفات المستوردة يدوياً'
      : (isFrench
            ? 'Effacer les imports hors ligne'
            : 'Clear offline imported packets');

  String get managedPatientsCountLabel => isArabic
      ? 'حسابات العيادة المُدارة'
      : (isFrench ? 'Patients suivis du cabinet' : 'Managed clinic patients');

  String get demoBannerNotice => isArabic
      ? 'يعرض حالياً ملفات تدريبية تجريبية.'
      : (isFrench
            ? 'Affiche les dossiers de démonstration.'
            : 'Showing demonstration patient records.');

  // Phase 5: Patient Portal Overhaul (Today, My days, Talk, Patterns, Me)
  String get addOptionalNoteChip => isArabic
      ? '+ إضافة ملاحظة (اختياري)'
      : (isFrench ? '+ Ajouter une note (optionnel)' : '+ Add a note (optional)');

  String get quickNoteInputHint => isArabic
      ? 'سطر قصير عن اليوم (اختياري)...'
      : (isFrench
            ? 'Quelques mots sur votre journée (optionnel)...'
            : 'A quick line about today (optional)...');

  String get syncingQuietLabel => isArabic
      ? 'جاري المزامنة...'
      : (isFrench ? 'Synchronisation...' : 'Syncing...');

  String get syncPausedQuietLabel => isArabic
      ? 'المزامنة متوقّفة'
      : (isFrench ? 'Synchro en pause' : 'Sync paused');

  String get syncPausedHelpToast => isArabic
      ? 'المزامنة مع طبيبك متوقّفة حالياً. ملاحظاتك محفوظة على هاتفك — اطلب من طبيبك تفعيلها.'
      : (isFrench
            ? 'La synchronisation avec votre médecin est en pause. Vos notes restent sur votre téléphone.'
            : 'Sync with your doctor is paused. Your notes stay safe on this phone — ask your doctor to resume.');

  String get allRecentEntriesTitle => isArabic
      ? 'كل تسجيلاتك الأخيرة'
      : (isFrench ? 'Toutes vos entrées récentes' : 'All recent entries');

  String get loadOlderEntriesBtn => isArabic
      ? 'عرض تسجيلات أقدم'
      : (isFrench ? 'Afficher les entrées plus anciennes' : 'Load older entries');

  String get privateOnlyFilterLabel => isArabic
      ? 'الخاصة فقط'
      : (isFrench ? 'Privées seulement' : 'Private only');

  String get deleteCheckInConfirmTitle => isArabic
      ? 'حذف هذا التسجيل؟'
      : (isFrench ? 'Supprimer cette entrée ?' : 'Delete this check-in?');

  String get deleteCheckInConfirmBody => isArabic
      ? 'سيتم حذف هذا التسجيل من يومياتك. يمكنك التراجع مباشرة بعد الحذف.'
      : (isFrench
            ? 'Cette entrée sera retirée de votre journal. Vous pourrez annuler juste après.'
            : 'This check-in will be removed from your history. You can undo right away.');

  String get editMoodSectionLabel => isArabic
      ? 'تعديل الشعور والقوة (اختياري)'
      : (isFrench
            ? 'Modifier le ressenti et l’intensité (optionnel)'
            : 'Update feeling & strength (optional)');

  String localizedWhatHelped(String raw) {
    final norm = raw.trim().toLowerCase();
    switch (norm) {
      case 'help_walk':
      case 'walk':
        return isArabic ? 'مشي خفيف' : (isFrench ? 'Marche' : 'Walk');
      case 'help_breathing':
      case 'breathing':
        return isArabic ? 'تنفّس هادئ' : (isFrench ? 'Respiration' : 'Breathing');
      case 'help_quiet_time':
      case 'quiet time':
        return isArabic ? 'وقت هدوء' : (isFrench ? 'Temps calme' : 'Quiet time');
      case 'help_talked':
      case 'talked':
        return isArabic
            ? 'حديث مع شخص'
            : (isFrench ? 'Parler à quelqu’un' : 'Talked');
      case 'help_rest':
      case 'rest':
        return isArabic ? 'راحة' : (isFrench ? 'Repos' : 'Rest');
      default:
        return raw.trim();
    }
  }

  String get talkCompanionDisclaimerBar => isArabic
      ? 'مساعد Mindora الذكي · مساحة هادئة للتأمل (ليس طبيباً)'
      : (isFrench
            ? 'Compagnon IA Mindora · Espace de réflexion (pas un médecin)'
            : 'Mindora AI Companion · Supportive reflection tool (not a doctor)');

  String get talkSharedShortPill => isArabic
      ? 'مشارك'
      : (isFrench ? 'Partagé' : 'Shared');

  String get talkPrivateShortPill => isArabic
      ? 'خاص'
      : (isFrench ? 'Privé' : 'Private');

  String get searchPastTalksHint => isArabic
      ? 'ابحث في حواراتك السابقة...'
      : (isFrench
            ? 'Rechercher dans vos échanges...'
            : 'Search past talks...');

  String get viewSummaryChip => isArabic
      ? 'عرض الملخص'
      : (isFrench ? 'Voir le bilan' : 'View summary');

  String get backToTalkBtn => isArabic
      ? 'العودة إلى الحوار'
      : (isFrench ? 'Retour au dialogue' : 'Back to Talk');

  String get editMyTakeawayTitle => isArabic
      ? 'تعديل خلاصتي'
      : (isFrench ? 'Modifier ma conclusion' : 'Edit my takeaway');

  String get saveTakeawayBtn => isArabic
      ? 'حفظ الخلاصة'
      : (isFrench ? 'Enregistrer' : 'Save takeaway');

  String get moodBalanceTitle => isArabic
      ? 'توازن أيامك الشعوري'
      : (isFrench ? 'Répartition de vos journées' : 'How your days felt');

  String get moodBandSteadierLabel => isArabic
      ? 'جيد وهادئ'
      : (isFrench ? 'Bien & Calme' : 'Good & Calm');

  String get moodBandTenseLabel => isArabic
      ? 'قلق ومتوتر'
      : (isFrench ? 'Inquiet & Agité' : 'Worried & Restless');

  String get moodBandHeavyLabel => isArabic
      ? 'ثقيل ومنزعج'
      : (isFrench ? 'Bas & Contrarié' : 'Low & Annoyed');

  String get careFromMyDoctorTitle => isArabic
      ? 'المتابعة مع طبيبي'
      : (isFrench ? 'Suivi avec mon médecin' : 'Care from my doctor');

  String get managedByDoctorBadge => isArabic
      ? 'بإشراف طبيبك'
      : (isFrench ? 'Géré par votre médecin' : 'Managed by your doctor');

  String get connectedToClinicBadge => isArabic
      ? 'مرتبط بالعيادة'
      : (isFrench ? 'Connecté au cabinet' : 'Connected to clinic');

  String localizedOnboardingGoal(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'track_mood_sleep':
        return isArabic
            ? 'متابعة المزاج والنوم'
            : (isFrench ? 'Suivre humeur et sommeil' : 'Track mood & sleep');
      case 'doctor_visits':
        return isArabic
            ? 'التحضير لزيارات الطبيب'
            : (isFrench
                  ? 'Préparer mes visites médicales'
                  : 'Prepare for doctor visits');
      case 'spot_triggers':
        return isArabic
            ? 'فهم المحفّزات اليومية'
            : (isFrench ? 'Repérer mes déclencheurs' : 'Spot daily triggers');
      case 'build_routine':
        return isArabic
            ? 'بناء روتين هادئ'
            : (isFrench ? 'Construire une routine' : 'Build a steady routine');
      case 'understand_patterns':
        return isArabic
            ? 'فهم أنماطي الشخصية'
            : (isFrench
                  ? 'Comprendre mes schémas'
                  : 'Understand personal patterns');
      case 'manage_stress':
        return isArabic
            ? 'تخفيف التوتر اليومي'
            : (isFrench ? 'Apaiser le stress' : 'Ease daily stress');
      default:
        return raw.replaceAll('_', ' ').trim();
    }
  }

  // Helper factory
  static AppStrings of(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return AppStrings(locale.languageCode);
  }
}

final appStringsProvider = Provider<AppStrings>((ref) {
  final locale = ref.watch(localeControllerProvider);
  return AppStrings(locale.languageCode);
});
