import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      isArabic ? 'المساعد' : (isFrench ? 'Assistant' : 'AI Guide');
  String get navInvestigator =>
      isArabic ? 'المساعد النفسي' : (isFrench ? 'Assistant IA' : 'AI Guide');
  String get navProfile =>
      isArabic ? 'ملفي' : (isFrench ? 'Profil' : 'Profile');

  // Contextual Support
  String get contextualSupportTitle => isArabic
      ? 'دعم فوري'
      : (isFrench ? 'Soutien contextuel' : 'Contextual Support');
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
      ? 'المرصد الداخلي لاستكشاف الأعراض والتجارب'
      : (isFrench
            ? 'Accéder à l’Observatoire intérieur'
            : 'Open Inner Observatory for deeper psychological exploration');
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
      ? 'خط الأساس الشخصي'
      : (isFrench ? 'Ligne de base personnelle' : 'Personal Baseline');
  String get patternAwarenessTitle => isArabic
      ? 'ملاحظات الأنماط والتغيرات'
      : (isFrench ? 'Observations des schémas' : 'Pattern Awareness');
  String get baselineNeedsMoreData => isArabic
      ? 'يتطلب خط الأساس 3 أيام على الأقل من التسجيل للبدء'
      : (isFrench
            ? 'Au moins 3 jours d’observation nécessaires'
            : 'At least 3 observation days needed to establish your baseline');
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
      ? 'معايرة خط الأساس'
      : (isFrench ? 'Calibration du repère' : 'Calibrating baseline');
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
      ? 'المرحلة $step/6'
      : (isFrench ? 'PHASE $step/6' : 'PHASE $step/6');
  String get inProgressLabel =>
      isArabic ? 'قيد المعالجة' : (isFrench ? 'EN COURS' : 'IN PROGRESS');
  String get quickTriageLabel => isArabic
      ? 'فرز سريع 60 ثانية'
      : (isFrench ? 'TRIAGE RAPIDE 60s' : '60s QUICK TRIAGE');
  String get groundedAnchorTag => isArabic
      ? 'مرسى التعافي'
      : (isFrench ? 'ANCRAGE RECADRÉ' : 'GROUNDED ANCHOR');

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
      ? 'الجهاز العصبي يطلق إشارات الخطر قبل ما الفكرة الواعية تتشكل. وقت تفصل بين الإحساس الجسدي والتأويل الفكري، ترجعلك السيطرة على مساراتك العصبية.'
      : (isFrench
            ? 'Le système limbique déclenche l’alerte avant la pensée consciente. Séparer l’activation somatique de l’interprétation mentale restaure la régulation préfrontale.'
            : 'The nervous system sounds alarms before conscious thoughts form. Separating somatic body activation from mental narrative restores prefrontal regulation.');

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
      ? 'تهدئة التنبيه الجسدي (Somatic Safety)'
      : (isFrench ? 'Sécurité neuro-somatique' : 'Somatic Safety Anchor');
  String get reframe3Body => isArabic
      ? 'جهازي العصبي أطلق إنذاراً كاذباً للحماية. جسدي آمن في هذه اللحظة، ولا يوجد خطر حقيقي.'
      : (isFrench
            ? 'Mon système nerveux a sonné une fausse alerte par réflexe. Mon corps est en sécurité ici et maintenant.'
            : 'My sympathetic nervous system fired a false alarm. My physical body is safe here and now.');

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
      ? 'تنظيم العصب الحائر (4-4-4-4)'
      : (isFrench
            ? 'Régulation Vagale (4-4-4-4)'
            : 'Vagal Box Pacing (4-4-4-4)');
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
      ? 'إعدادات المنظومة'
      : (isFrench ? 'Paramètres Cliniques' : 'Clinical Settings');
  String get themeModeTitle => isArabic
      ? 'بيئة الإضاءة البصرية'
      : (isFrench ? 'Environnement Visuel' : 'Visual Environment');
  String get themeDaylight =>
      isArabic ? 'نهاري' : (isFrench ? 'Jour' : 'Daylight');
  String get themeNight =>
      isArabic ? 'ليلي' : (isFrench ? 'Sombre' : 'Charcoal');
  String get themeSystem =>
      isArabic ? 'النظام' : (isFrench ? 'Système' : 'System');
  String get languageTitle => isArabic
      ? 'لغة المنظومة'
      : (isFrench ? 'Langue clinique' : 'Clinical Language');
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
      ? 'قفل الأمان البيومتري'
      : (isFrench ? 'Verrouillage biométrique' : 'Biometric Security');
  String get biometricLockDesc => isArabic
      ? 'المصادقة بالبصمة لحماية سرية السجلات المعرفية'
      : (isFrench
            ? 'Empreinte requise pour accéder aux dossiers cliniques'
            : 'Require biometrics to access sensitive cognitive records');
  String get biometricVaultLockedTitle => isArabic
      ? 'الجلسة مقفلة'
      : (isFrench ? 'SESSION SÉCURISÉE' : 'SESSION LOCKED');
  String get biometricVaultLockedDesc => isArabic
      ? 'يلزم التحقق بالبصمة للوصول إلى سجلات وتفكيكات أفكارك الخاصة.'
      : (isFrench
            ? 'Authentification requise pour déverrouiller vos dossiers de déconstruction.'
            : 'Biometric authentication required to access your private cognitive session records.');
  String get unlockWithBiometricsBtn =>
      isArabic ? 'فتح القفل بالبصمة' : (isFrench ? 'DÉVERROUILLER' : 'UNLOCK');
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
      ? 'بروتوكول حماية وسرية البيانات'
      : (isFrench ? 'CONFIDENTIALITÉ & SÉCURITÉ' : 'DATA PRIVACY PROTOCOL');
  String get privacyPrinciplesTitle => isArabic
      ? 'المعايير السريرية للخصوصية'
      : (isFrench
            ? 'Normes de Confidentialité Médicale'
            : 'Clinical Privacy Standards');
  String get privacyPrinciplesBody => isArabic
      ? '1. حفظ محلي سيادي لكافة الجلسات على هاتفك فقط دون إرسالها لسيرفرات خارجية.\n2. لا يتم بيع أو مشاركة أي معطى شخصي مع أطراف ثالثة.\n3. لا يتم تدريب نماذج الذكاء الاصطناعي على بياناتك الخاصة.\n4. استقلالية تامة وملكية مطلقة لكل فكرة تسجلها.'
      : (isFrench
            ? '1. Stockage local souverain sur votre appareil sans transmission à des serveurs tiers.\n2. Aucune donnée n’est partagée, monétisée ou utilisée à des fins tierces.\n3. Vos pensées ne servent jamais à entraîner des modèles IA.\n4. Contrôle absolu et propriété totale de vos enregistrements cognitifs.'
            : '1. Sovereign local on-device storage without transmission to third-party servers.\n2. Zero data monetization, sharing, or advertising tracking.\n3. Your private thoughts are never used for AI model training.\n4. Complete sovereignty and ownership over every logged record.');
  String get allDataWipedSnackbar => isArabic
      ? 'تم مسح كافة السجلات المعرفية بنجاح.'
      : (isFrench
            ? 'Toutes les données ont été purgées avec succès.'
            : 'All clinical session records permanently cleared.');

  // Deconstruction Workflow (Clinical Stages)
  String get stageIncident => isArabic
      ? 'المحفز اللحظي'
      : (isFrench ? 'Catalyseur' : 'Activating Catalyst');
  String get stageEvidence => isArabic
      ? 'الحالة الجسدية والفكرية'
      : (isFrench ? 'État Somatique & Pensée' : 'Neural & Somatic State');
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
      ? 'المرحلة $step من 6  •  $stageTitle'
      : (isFrench
            ? 'PHASE $step SUR 6  •  ${stageTitle.toUpperCase()}'
            : 'PHASE $step OF 6  •  ${stageTitle.toUpperCase()}');

  String get whatHappenedQuestion => isArabic
      ? 'شنوة المحفز اللي أثار التوتر؟'
      : (isFrench
            ? 'Quel est le stimulus déclencheur ?'
            : 'What is the activating stimulus?');
  String get incidentHelpText => isArabic
      ? 'اختر من المحفزات السريعة بنقرة واحدة، أو اكتب جملة توضيحية إذا تحب:'
      : (isFrench
            ? 'Sélectionnez un déclencheur rapide en 1 tap, ou ajoutez une précision si nécessaire :'
            : 'Select a catalyst in 1 tap, or write a single brief note if desired:');
  String get incidentHint => isArabic
      ? 'أو اكتب باختصار: مثلاً شفت الإيميل وحسيت بضغط مفاجئ...'
      : (isFrench
            ? 'Ou notez brièvement le contexte...'
            : 'Or enter optional custom trigger context...');
  String get describeSituationWarning => isArabic
      ? 'الرجاء اختيار أو كتابة المحفز للمتابعة.'
      : (isFrench
            ? 'Veuillez sélectionner un stimulus pour continuer.'
            : 'Please select or enter a catalyst before proceeding.');
  String get proceedToEvidenceBtn => isArabic
      ? 'فحص الحالة الجسدية والفكرة'
      : (isFrench
            ? 'Analyser l’état somato-cognitif'
            : 'CONTINUE TO SOMATIC & NEURAL STATE');

  String get mapChainTitle => isArabic
      ? 'تحديد الاستجابة الجسدية والفكرة'
      : (isFrench
            ? 'Cartographie Somatique & Cognitive'
            : 'Map Somatic & Cognitive Response');
  String get mapChainSub => isArabic
      ? 'حدد أين استقر التوتر في جسدك وصنف الفكرة التلقائية السريعة:'
      : (isFrench
            ? 'Localisez la tension corporelle et qualifiez la pensée automatique :'
            : 'Locate where the body feels it and classify the automatic thought:');
  String get triggerLabel => isArabic
      ? 'المحفز المختار'
      : (isFrench ? 'Stimulus identifié' : 'Identified Catalyst');
  String get emotionLabel => isArabic
      ? 'الإحساس الجسدي / الشعور'
      : (isFrench
            ? 'Sensation somatique principale'
            : 'Primary Somatic / Emotional State');
  String get emotionalIntensityTitle => isArabic
      ? 'مستوى الاستثارة العصبية'
      : (isFrench ? 'INTENSITÉ SOMATIQUE' : 'SOMATIC AROUSAL INTENSITY');
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
      ? 'خلاصة الفرز بين الواقع الحسي والانحيازات العصبية التي ضخمت الموقف:'
      : (isFrench
            ? 'Séparation clinique entre réalité empirique et filtres déformants :'
            : 'Clinical triage between empirical reality and cognitive distortions:');
  String get fallbackFindingsSummary => isArabic
      ? '• الواقع الحسي الملموس: المنبه الخارجي وقع بشكل عادي دون وجود أي دليل على استهداف مقصود.\n• الانحياز المعرفي المرصود: قفز الجهاز العصبي إلى "قراءة الأفكار" وافتراض الرفض الشخصي لتجنب الصدمة.\n• الاستنتاج السريري: الخطر غير موجود مادياً وإنما تشكل كاستجابة إنذار وهمية داخلية.'
      : (isFrench
            ? '• Réalité empirique : L’événement extérieur s’est produit sans preuve d’intention malveillante.\n• Distorsion identifiée : Glissement automatique vers la "lecture de pensée" et la personnalisation.\n• Synthèse clinique : La menace est purement projective et ne requiert aucune défense active.'
            : '• Empirical Reality: The stimulus occurred without objective evidence of personal hostility.\n• Detected Distortion: The nervous system defaulted to "Mind Reading" and premature catastrophizing.\n• Clinical Assessment: The perceived threat is an internal projection rather than an immediate hazard.');
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
      ? 'المرحلة السابقة'
      : (isFrench ? 'PHASE PRÉCÉDENTE' : 'PREVIOUS PHASE');

  /// Formats an internal session identifier (e.g. "SESSION 01" or legacy "CASE 001") into localized display format.
  String formatSessionNumber(String rawNumber) {
    final digitsMatch = RegExp(r'\d+').firstMatch(rawNumber);
    final num = digitsMatch != null
        ? int.tryParse(digitsMatch.group(0) ?? '')
        : null;
    final formatted = num != null ? num.toString().padLeft(2, '0') : '01';
    if (isArabic) {
      return 'جلسة $formatted';
    }
    return 'SESSION $formatted';
  }

  // Case Report View
  String get caseReportTitle => isArabic
      ? 'تقرير الجلسة المعرفية'
      : (isFrench
            ? 'Rapport de Session Cognitive'
            : 'Cognitive Session Report');
  String get caseNotFound => isArabic
      ? 'الجلسة غير موجودة.'
      : (isFrench ? 'Session introuvable.' : 'Session record not found.');
  String get editVerdictTitle => isArabic
      ? 'تعديل إعادة التوجيه'
      : (isFrench ? 'MODIFIER LE RECADRAGE' : 'EDIT REFRAME');
  String get yourUpdatedTakeaway => isArabic
      ? 'صيغتك المعدلة...'
      : (isFrench ? 'Votre recadrage révisé...' : 'Your updated reframe...');
  String get saveVerdictBtn =>
      isArabic ? 'حفظ التعديل' : (isFrench ? 'ENREGISTRER' : 'SAVE REFRAME');
  String get deleteCaseFileTitle => isArabic
      ? 'حذف سجل الجلسة'
      : (isFrench ? 'PURGER LA SESSION' : 'PURGE SESSION RECORD');
  String get deleteCase => isArabic
      ? 'حذف الجلسة'
      : (isFrench ? 'Supprimer la session' : 'Delete Session');
  String get deleteCaseWarning => isArabic
      ? 'هذا الإجراء نهائي. سيتم حذف جميع بيانات الاستجابة الجسدية والتشخيص المعرفي لهذه الجلسة.'
      : (isFrench
            ? 'Cette action est irréversible. Toutes les données somatiques et cognitives seront définitivement effacées.'
            : 'This action is irreversible. All somatic and cognitive data for this session will be permanently purged.');
  String get deletePermanentlyBtn => isArabic
      ? 'حذف نهائي'
      : (isFrench ? 'PURGER DÉFINITIVEMENT' : 'PURGE PERMANENTLY');
  String get cancelBtn =>
      isArabic ? 'إلغاء' : (isFrench ? 'Annuler' : 'Cancel');
  String get incidentNarrativeHeader => isArabic
      ? '1. المحفز اللحظي (Activating Catalyst)'
      : (isFrench ? '1. STIMULUS DÉCLENCHEUR' : '1. ACTIVATING CATALYST');
  String get noNarrativeRecorded => isArabic
      ? 'لم يتم تسجيل محفز.'
      : (isFrench ? 'Aucun stimulus enregistré.' : 'No stimulus recorded.');
  String get observableChainHeader => isArabic
      ? '2. الاستجابة الجسدية والفكرية'
      : (isFrench
            ? '2. ÉTAT SOMATIQUE & PENSÉE'
            : '2. SOMATIC & NEURAL RESPONSE');
  String get hypothesesExaminedHeader => isArabic
      ? '3. النماذج التفسيرية المفحوصة'
      : (isFrench
            ? '3. MODÈLES CLINIQUES ALTERNATIFS'
            : '3. COGNITIVE MODELS EXAMINED');
  String get groundedVerdictHeader => isArabic
      ? '4. إعادة التوجيه المعتمدة (Adaptive Anchor)'
      : (isFrench
            ? '4. RECADRAGE ADAPTATIF ANCRÉ'
            : '4. ADAPTIVE REFRAME ANCHOR');
  String get finalTakeawayUserHeader => isArabic
      ? 'الركيزة المعرفية المعتمدة'
      : (isFrench ? 'RECADRAGE ANCRÉ' : 'ADOPTED REFRAME ANCHOR');
  String get editBtn => isArabic ? 'تعديل' : (isFrench ? 'MODIFIER' : 'EDIT');
  String get noConclusionYet => isArabic
      ? 'لم يُعتمد توجيه بعد.'
      : (isFrench
            ? 'Aucun recadrage ancré pour le moment.'
            : 'No reframe anchored yet.');
  String emotionTag(String emotion, int intensity) => isArabic
      ? 'الحالة الجسدية: $emotion (شدة $intensity/10)'
      : (isFrench
            ? 'ÉTAT SOMATIQUE : ${emotion.toUpperCase()} ($intensity/10)'
            : 'SOMATIC STATE: ${emotion.toUpperCase()} ($intensity/10)');
  String get triggerTitle =>
      isArabic ? 'المحفز' : (isFrench ? 'Stimulus' : 'Catalyst');
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
      ? 'البيانات الجسدية مخفية (وضع الخصوصية)'
      : (isFrench
            ? 'Données masquées (mode privé)'
            : 'Somatic state hidden (privacy mode)');
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
      ? 'إذا كنت تعيش في لحظة صعيبة، قلق شديد أو أزمة نفسية، مانكش وحدك. فما مختصين جاهزين يسمعوك ويعاونوك بسرية ومجاناً.'
      : (isFrench
            ? 'Si vous traversez un moment difficile, de grande anxiété ou de crise, vous n’avez pas à porter cela seul(e). Des spécialistes sont disponibles pour vous écouter.'
            : 'If you are experiencing overwhelming distress, severe anxiety, or a crisis, you don’t have to carry this alone. Free, confidential support is available right now.');
  String get crisisPauseTitle => isArabic
      ? 'وقفة هادئة لتنظيم الجهاز العصبي'
      : (isFrench
            ? 'Pause de Régulation Immédiate'
            : 'Gentle Neuro-Regulation Pause');
  String get crisisPauseBody => isArabic
      ? 'المعطيات تشير إلى استثارة عصبية عالية جداً. في هذه الحالة، التحليل المعرفي يزيد الضغط. الأولوية الآن هي تهدئة الجسد وتوفير الأمان والدعم السريري.'
      : (isFrench
            ? 'Les indicateurs révèlent une hyperarousal aigu. Dans cet état, l’analyse cognitive devient contre-productive. La priorité absolue est la sécurité et le soutien clinique immédiat.'
            : 'Indicators show acute autonomic hyperarousal. In this state, cognitive analysis increases strain. The absolute priority is immediate physiological safety and clinical support.');
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
      ? 'مساحة شخصية هادئة لملاحظة أفكارك ومشاعرك اليومية وفهم أنماطك بهدوء وبدون أحكام.'
      : (isFrench
            ? 'Un espace personnel et apaisé pour observer vos pensées, émotions et rythmes quotidiens sans jugement.'
            : 'A quiet, personal space to notice your thoughts, emotions, and daily patterns at your own pace without judgment.');
  String get onboardingPrivacyPromise => isArabic
      ? 'تُحفظ بياناتك بخصوصية تامة على جهازك افتراضياً. مستوحى من الوعي المعرفي — وليس علاجاً طبياً أو بديلاً عن المختص.'
      : (isFrench
            ? 'Stocké en privé sur votre appareil par défaut. Inspiré de la conscience cognitive — ceci n’est ni une thérapie ni un traitement médical.'
            : 'Stored privately on your device by default. Inspired by cognitive reflection — not medical treatment or therapy.');

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
      ? 'للحالات الطارئة: خطوط المساعدة التونسية (الرقم الأخضر 80 10 50 50، 190، 198) متوفرة دائماً بلمسة واحدة.'
      : (isFrench
            ? 'Ressources d’urgence : les lignes d’écoute (80 10 50 50 / 190 / 198) restent accessibles à tout moment en haut de l’écran.'
            : 'Immediate support: Tunisian crisis & emergency lines (80 10 50 50 / 190 / 198) stay 1 tap away in the top bar.');
  String get openCrisisResourcesLabel => isArabic
      ? 'عرض أرقام الطوارئ'
      : (isFrench ? 'Voir les numéros d’aide' : 'View emergency numbers');

  // Step 4: First Check-In & Zero-Blank-Screen Handoff
  String get onboardingFirstCheckInSubtitle => isArabic
      ? 'سجّل أول شعور ليك في لمستين باش تكون صفحتك الرئيسية حاضرة.'
      : (isFrench
            ? 'Enregistrez votre premier ressenti en deux gestes pour démarrer avec un accueil vivant.'
            : 'Log your first trace in two taps so your Home space greets you with today’s baseline.');
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
      ? 'هذه الجلسة محمية بدرع السرية. تم استبعادها تلقائياً ولا يمكن تصديرها إلا إذا قمت بإلغاء وضع الخصوصية أولاً.'
      : (isFrench
            ? 'Cette session est protégée par le bouclier de confidentialité. Elle ne peut être exportée sans déverrouillage préalable.'
            : 'This session is protected by your privacy shield and cannot be exported. Unlock privacy first to share.');

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
      ? 'إشعار سريري: Mindora مستوحى من مبادئ العلاج السلوكي المعرفي (CBT). الفرضيات الاستكشافية ليست تشخيصاً نفسياً أو استنتاجاً طبياً.'
      : (isFrench
            ? 'Avis clinique : Mindora est inspiré des approches TCC. Les hypothèses exploratoires ne sont pas des diagnostics médicaux.'
            : 'Clinical Notice: Mindora is inspired by CBT principles. Exploratory hypotheses are not medical diagnoses or clinical findings.');

  // Clinical Sharing History (Principle 5)
  String get clinicalSharingHistoryTitle => isArabic
      ? 'سجل التصدير والمشاركات السريرية'
      : (isFrench
            ? 'Historique des Partages Cliniques'
            : 'Clinical Sharing History');
  String get clinicalSharingHistoryDesc => isArabic
      ? 'سجل مرئي وتوثيق دقيق لكل ملخص جلسة تم نسخه أو تصديره (لا يتم أي تصدير تلقائي أبداً)'
      : (isFrench
            ? 'Journal visible de tous les bilans exportés (aucun envoi automatique)'
            : 'Visible audit log of all exported session briefs (zero automatic sharing)');
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
      ? 'المرافق بصدد التفكير...'
      : (isFrench ? 'Réflexion en cours...' : 'Reflecting...');
  String get typeMessageHint => isArabic
      ? 'احكي مع رفيقك الذكي (شنوة الفكرة اللي قالقتك؟)...'
      : (isFrench
            ? 'Échangez avec votre compagnon...'
            : 'Talk with your companion...');
  String get welcomeDialoguePrompt => isArabic
      ? 'أهلاً بيك. أنا هوني باش نسمعك ونفككوا مع بعضنا أي فكرة أو توتر مقلقك توا. شنوة اللي صاير معاك؟'
      : (isFrench
            ? 'Bienvenue. Je suis là pour explorer avec vous ce qui vous pèse. Quelle pensée ou situation traverse votre esprit ?'
            : 'Welcome. I am here to explore whatever thought or reaction is weighing on your mind right now. What happened, or what are you feeling?');
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
      ? 'مستكشف التشوهات المعرفية'
      : (isFrench ? 'DISTORSIONS COGNITIVES' : 'COGNITIVE DISTORTIONS');
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
  String get tagDistortionBtn =>
      isArabic ? '+ تشويه فكري' : (isFrench ? '+ Distorsion' : '+ Distortion');
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
      ? '«كل فكرة تترك أثراً. كل تدوينة تصبح جزءاً من سجل شخصي يمكنك مراجعته وفحصه وفهمه.»'
      : (isFrench
            ? '« Chaque pensée laisse une trace. Chaque entrée devient une archive personnelle à revisiter, examiner et comprendre. »'
            : '“Every thought leaves a trace. Every entry becomes part of a personal record that can be revisited, examined, and understood.”');
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
            : 'RECORD DAILY THOUGHT TRACE');
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
      ? '«تجاربك فريدة تماماً. ساعد Mindora على فهم عالمك النفسي، وتحدياتك، وما يهمك حقاً.»'
      : (isFrench
            ? '« Vos expériences sont uniques. Aidez Mindora à comprendre votre monde intérieur et ce qui compte pour vous. »'
            : '“Your experiences are unique. Help Mindora understand your psychological world, your challenges, and what matters to you.”');
  String get profileSecondaryQuote => isArabic
      ? 'شارك فقط ما ترتاح في مشاركته. يمكنك تحديث أو إزالة أي معلومة متى شئت دون قيود.'
      : (isFrench
            ? 'Ne partagez que ce qui vous convient. Vous pouvez modifier ou retirer vos informations à tout moment.'
            : 'Share only what you feel comfortable sharing. You can update or remove your information whenever you want.');
  String get sectionAboutMe =>
      isArabic ? 'عني (About Me)' : (isFrench ? 'À propos de moi' : 'About Me');
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
      ? 'يسمح للمرافق الذكي بتخصيص أسئلته وفقاً لحالتك وأهدافك الشخصية، مع الحفاظ على سرية بياناتك على هذا الجهاز فقط.'
      : (isFrench
            ? 'Permet au compagnon de personnaliser son écoute selon vos besoins en toute confidentialité locale.'
            : 'Allows your companion to personalize inquiry to your goals with strict on-device confidentiality.');
  String get saveProfileBtn => isArabic
      ? 'حفظ الملف النفسي'
      : (isFrench ? 'ENREGISTRER LE PROFIL' : 'SAVE PROFILE');
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
      : (isFrench ? 'ENREGISTRER LA RÉFLEXION' : 'SAVE REFLECTION');
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
      ? 'هذا المسار هو إطار مرن للاستبصار، وليس مقياساً لقيمتك الشخصية أو مؤشراً لتعافيك. يمكنك التنقل بحرية بين الأنشطة ومراجعتها متى شئت.'
      : (isFrench
            ? 'Ce parcours est un cadre bienveillant d’auto-observation. La progression ne mesure ni votre valeur ni votre guérison.'
            : 'This journey is a flexible framework for self-attunement. Progress is never a metric of your psychological worth or recovery.');
  String get toolkitLabTab =>
      isArabic ? 'مختبر الأدوات' : (isFrench ? 'Boîte à Outils' : 'Tools Lab');

  // =========================================================================
  // 3. Authentication & Account Onboarding
  // =========================================================================
  String get authTitle => isArabic
      ? 'الدخول إلى حسابك'
      : (isFrench ? 'Accès à votre compte' : 'Access Your Account');
  String get authSubtitle => isArabic
      ? 'مساحة استكشاف معرفية خاصة. ادخل إلى سجلاتك وتأملاتك الشخصية.'
      : (isFrench
            ? 'Espace d’exploration cognitive privé. Accédez à vos réflexions personnelles.'
            : 'A private cognitive exploration space. Access your personal reflection records.');
  String get signInTab =>
      isArabic ? 'تسجيل الدخول' : (isFrench ? 'Connexion' : 'Sign In');
  String get signUpTab => isArabic
      ? 'إنشاء حساب'
      : (isFrench ? 'Créer un compte' : 'Create Account');
  String get emailFieldLabel => isArabic
      ? 'البريد الإلكتروني'
      : (isFrench ? 'Adresse email' : 'Email Address');
  String get emailFieldHint => 'user@domain.com';
  String get passwordFieldLabel =>
      isArabic ? 'كلمة السر' : (isFrench ? 'Mot de passe' : 'Password');
  String get passwordFieldHint => isArabic
      ? '6 أحرف على الأقل'
      : (isFrench ? '6 caractères minimum' : 'At least 6 characters');
  String get codenameFieldLabel => isArabic
      ? 'الاسم المفضل أو المستعار (اختياري)'
      : (isFrench
            ? 'Nom ou alias (facultatif)'
            : 'Preferred Name or Alias (Optional)');
  String get codenameFieldHint => isArabic
      ? 'مثال: باحث'
      : (isFrench ? 'ex: Observateur' : 'e.g. Observer');
  String get createVaultBtn => isArabic
      ? 'إنشاء حساب'
      : (isFrench ? 'CRÉER UN COMPTE' : 'CREATE ACCOUNT');
  String get unlockVaultBtn =>
      isArabic ? 'تسجيل الدخول' : (isFrench ? 'SE CONNECTER' : 'SIGN IN');
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
      : (isFrench ? 'CONTINUER SANS COMPTE' : 'CONTINUE WITHOUT AN ACCOUNT');
  String get alreadyHaveVaultPrompt => isArabic
      ? 'لديك حساب سابق؟'
      : (isFrench ? 'Vous avez déjà un compte ?' : 'Already have an account?');
  String get newInvestigatorPrompt =>
      isArabic ? 'مستخدم جديد؟' : (isFrench ? 'Nouveau ici ?' : 'New here?');
  String get startExplorationBtn => isArabic
      ? 'ابدأ رحلة الاستكشاف'
      : (isFrench ? 'Commencer l’exploration' : 'Start Exploration');
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
      ? 'تساعدنا الفئة العمرية على معايرة وتيرة الدعم. تقديم السياق الجسدي اختياري تماماً ولا يترتب عليه أي افتراضات سريرية.'
      : (isFrench
            ? 'Votre tranche d’âge aide à calibrer le rythme. Le contexte physiologique est facultatif et sans suppositions cliniques.'
            : 'Your age range helps calibrate supportive pacing. Providing physiological context is completely voluntary and never creates clinical assumptions.');
  String get ageRangeLabel =>
      isArabic ? 'الفئة العمرية' : (isFrench ? 'Tranche d’âge' : 'Age Range');
  String get biologicalSexLabel => isArabic
      ? 'السياق الجسدي / الجنس (اختياري)'
      : (isFrench
            ? 'Contexte physiologique / Sexe (facultatif)'
            : 'Physiological Context / Sex (Optional)');
  String get biologicalSexHelperNote => isArabic
      ? 'اختياري: يساعد على مواءمة استبصار الطاقة والأنماط الجسدية دون أي قيود أو تصنيفات مسبقة.'
      : (isFrench
            ? 'Facultatif : aide à affiner l’observation des rythmes somatiques sans restriction.'
            : 'Voluntary: helps tailor somatic observation (such as physical energy rhythms) without clinical stereotyping or restrictions.');
  String get minorSupportNotice => isArabic
      ? 'تنبيه: التطبيق هو مساحة للاستبصار الذاتي وليس علاجاً طبياً أو تدخلاً طارئاً. إذا كنت تمر بضائقة حادة، تواصل مع شخص بالغ تثق به أو مع خدمات الطوارئ الطبية الرسمية.'
      : (isFrench
            ? 'Important : Mindora est un outil d’auto-observation, non un traitement médical. En cas de détresse intense, parlez-en à un adulte de confiance ou aux services d’urgence.'
            : 'Important: Mindora is a self-reflection tool, not medical treatment. If you are experiencing acute distress, reach out to a trusted adult, professional, or local emergency services.');

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
      ? 'اختر التجارب التي تشعر بها حالياً عبر مجالات المرصد الداخلي.'
      : (isFrench
            ? 'Sélectionnez les manifestations qui vous touchent parmi les domaines de l’Observatoire.'
            : 'Select the experiences you are currently navigating across the Observatory domains.');

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
      case '45-54':
        return isArabic ? '45 - 54 سنة' : (isFrench ? '45-54 ans' : '45-54');
      case '55-64':
        return isArabic ? '55 - 64 سنة' : (isFrench ? '55-64 ans' : '55-64');
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
      : (isFrench ? 'Conversations récentes' : 'Recent Conversations');
  String get noRecentConversations => isArabic
      ? 'لا توجد محادثات سابقة بعد. اختر نمطاً أعلاه للبدء.'
      : (isFrench
            ? 'Aucune conversation enregistrée. Choisissez un mode ci-dessus.'
            : 'No conversations saved yet. Select a mode above to begin.');
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
      : (isFrench ? 'TOTAL ENTRÉES' : 'TOTAL ENTRIES');
  String get uniqueDaysMetric => isArabic
      ? 'الأيام الملاحظة'
      : (isFrench ? 'JOURS OBSERVÉS' : 'DAYS OBSERVED');
  String get emotionSelectionsMetric => isArabic
      ? 'المشاعر المحددة'
      : (isFrench ? 'ÉMOTIONS CITÉES' : 'EMOTION TAGS');
  String get emotionalSpectrumTitle => isArabic
      ? 'توزيع المشاعر المعاشة'
      : (isFrench ? 'SPECTRE ÉMOTIONNEL' : 'REPORTED EMOTIONAL SPECTRUM');
  String get emotionalVarietyTitle => isArabic
      ? 'تنوع المشاعر واستبصارها'
      : (isFrench ? 'GRANULARITÉ ÉMOTIONNELLE' : 'EMOTIONAL GRANULARITY');
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
      ? 'مؤشرات النوم والطاقة الجسدية'
      : (isFrench
            ? 'SOMMEIL ET ÉNERGIE SOMATIQUE'
            : 'SOMATIC & SLEEP INSIGHTS');
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
      ? 'كل نقطة مضيئة تمثل يوماً موثقاً. لا توجد سلاسل تفوت، بل وعي مستمر بالذات.'
      : (isFrench
            ? 'Chaque point marque un jour observé. Sans calcul de série rompue, uniquement de la présence à soi.'
            : 'Each highlighted point marks an observed day. No broken streaks, only continuous self-awareness.');
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
  String filteredByDateLabel(String dateKey) => isArabic
      ? 'التاريخ المحدد: $dateKey'
      : (isFrench ? 'Filtre : $dateKey' : 'Selected: $dateKey');
  String get noEntriesForDayNote => isArabic
      ? 'ما فماش تسجيل في النهار هذا.'
      : (isFrench
            ? 'Aucun bilan enregistré ce jour-là.'
            : 'No check-in logged on this day.');
  String get exploreWithAiGuideBtn => isArabic
      ? 'استكشاف مع المساعد'
      : (isFrench ? 'Explorer avec l’Assistant IA' : 'Explore with AI Guide');
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
    if (isArabic) {
      return '$dayLabel ${dt.day} $mLabel';
    }
    return '${dayLabel.toUpperCase()} ${dt.day} ${mLabel.toUpperCase()}';
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
      ? 'السياق الشخصي وتفضيلات الحوار'
      : (isFrench
            ? 'Gérer le contexte personnel et les préférences'
            : 'Manage psychological context and preferences');
  String get mindAssistantEngineTitle => isArabic
      ? 'محرّك المساعد الذهني'
      : (isFrench ? 'Moteur d’Assistant Mental' : 'Mind Assistant Engine');
  String get mindAssistantEngineSub => isArabic
      ? 'وضع الاختبار المحلي أو الاتصال السحابي'
      : (isFrench
            ? 'Mode test local et diagnostics Gemini'
            : 'Gemini live AI & safe test mode status');
  String get sharePacketTitle => isArabic
      ? 'تحضير ملخص للمشاركة (اختياري)'
      : (isFrench ? 'Préparer un dossier de partage' : 'Build Share Packet');
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
      ? 'إعدادات محرّك الذكاء الاصطناعي'
      : (isFrench ? 'Réglages du moteur IA' : 'AI engine settings');
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
      ? 'مستقر مع خطك المرجعي'
      : (isFrench ? 'Stable avec votre repère' : 'Steady with your baseline');
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
      ? 'توزيع المشاعر، المؤشرات الجسدية وأرشيف التأملات'
      : (isFrench
            ? 'Spectre émotionnel, indices somatiques et archive'
            : 'Detailed emotion breakdown, somatic index & milestone archive');

  String get mostCommonThisWeekLabel => isArabic
      ? 'الشعور الأكثر تكراراً هذا الأسبوع'
      : (isFrench
            ? 'Ressenti le plus fréquent cette semaine'
            : 'Most common this week');
  String get baselineSleepComparisonTitle => isArabic
      ? 'النوم مقارنةً بخطك المرجعي'
      : (isFrench ? 'Sommeil vs repère habituel' : 'Sleep vs baseline');
  String get baselineMoodComparisonTitle => isArabic
      ? 'الشدّة المزاجية مقارنةً بخطك المرجعي'
      : (isFrench
            ? 'Intensité vs repère habituel'
            : 'Mood intensity vs baseline');

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
      return '$dir $amountStr (المرجع: $baseStr)';
    }
    if (isFrench) {
      final dir = delta > 0 ? 'plus haut de' : 'plus bas de';
      return '$dir $amountStr (repère : $baseStr)';
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
      ? 'المساعد والأمان'
      : (isFrench ? 'Assistant IA & Sécurité' : 'AI Guide & Security');
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
      ? 'كل التدوينات، الجلسات، الذكريات والملف الشخصي على هذا الجهاز باش يتمسحو نهائياً. ما فماش رجوع.'
      : (isFrench
            ? 'Toutes vos traces, conversations et données de profil seront supprimées de façon irréversible.'
            : 'All check-ins, AI Guide conversations, memories, and profile records on this device will be permanently removed.');
  String get confirmResetBtn => isArabic
      ? 'نعم، امسح كل شيء'
      : (isFrench ? 'Tout effacer' : 'Erase Everything');

  // Slice 3A: AI Engine Config & Non-Silent Runtime Notice
  String get aiEngineSheetTitle => isArabic
      ? 'محرك المساعد الذكي'
      : (isFrench ? 'MOTEUR DE L’ASSISTANT IA' : 'MIND ASSISTANT ENGINE');
  String get aiEngineLiveGroqBadge =>
      isArabic ? 'GROQ مباشر' : (isFrench ? 'GROQ EN DIRECT' : 'LIVE GROQ');
  String get aiEngineLiveGeminiBadge => isArabic
      ? 'GEMINI مباشر'
      : (isFrench ? 'GEMINI EN DIRECT' : 'LIVE GEMINI');
  String get aiEngineTestModeBadge => isArabic
      ? 'وضع التجربة (\$0.00)'
      : (isFrench ? 'MODE TEST (\$0.00)' : 'TEST MODE (\$0.00)');
  String get aiEngineSheetSubtitle => isArabic
      ? 'يدعم التطبيق محرك Groq أو Google Gemini للحوار المباشر، أو الوضع المحلي المجاني بدون إرسال بيانات.'
      : (isFrench
            ? 'Prend en charge Groq (Llama 3.3 gratuit) ou Google Gemini en direct, ou le simulateur local sans transmission.'
            : 'Mindora supports Groq (Llama 3.3 free tier) or Google Gemini for live specialist dialogue, or offline mock mode with zero transmission.');
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
          ? 'تم استبعاد $count ملف(ات) خاصة نهائياً — الجلسات الخاصة لا تُشارك أبداً.'
          : 'الجلسات المصنفة "خاصة" تُستبعد تلقائياً ولا تغادر جهازك أبداً.';
    }
    if (isFrench) {
      return count > 0
          ? '$count dossier(s) privé(s) exclu(s) — les explorations privées ne sont jamais partagées.'
          : 'Les explorations marquées privées sont toujours exclues automatiquement.';
    }
    return count > 0
        ? '$count private session(s) excluded — private cases never leave this gate.'
        : 'Sessions marked Private are always excluded automatically.';
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
      ? 'تغيّرات مرصودة'
      : (isFrench ? 'Écarts observés' : 'Baseline Shifts');

  String get kpiSharedUpdates => isArabic
      ? 'تحديثات جديدة'
      : (isFrench ? 'Nouveaux partages' : 'Shared Updates');

  String get filterAll => isArabic ? 'الكل' : (isFrench ? 'Tous' : 'All');

  String get filterShiftsNoted => isArabic
      ? 'تغيّرات مرصودة'
      : (isFrench ? 'Écarts notables' : 'Shifts Noted');

  String get filterNewUpdates =>
      isArabic ? 'جديد' : (isFrench ? 'Non lus' : 'New Updates');

  String get filterDemoCohort =>
      isArabic ? 'ملفات تجريبية' : (isFrench ? 'Démo clinique' : 'Demo Cohort');

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
      ? 'مستقر مقارنة بالمرجع'
      : (isFrench ? 'Ligne de base stable' : 'Steady vs baseline');

  String get noPatientsEmptyTitle => isArabic
      ? 'لا توجد ملفات مرضى بعد'
      : (isFrench ? 'Aucun dossier patient' : 'No patient records yet');

  String get noPatientsEmptySub => isArabic
      ? 'استورد حزمة مشفّرة من مريض أو فعّل المجموعة التجريبية من الإعدادات.'
      : (isFrench
            ? 'Importez un code chiffré ou activez les cas de démonstration dans Cabinet.'
            : 'Import an encrypted patient sync packet or enable the demo cohort in Practice.');

  String get cohortObservationsTitle => isArabic
      ? 'مؤشرات التغيّر عبر المرضى'
      : (isFrench
            ? 'OBSERVATIONS OBJECTIVÉES DE COHORTE'
            : 'COHORT BASELINE OBSERVATIONS');

  String get cohortTopFeelingsTitle => isArabic
      ? 'المشاعر الدقيقة الأكثر تكراراً'
      : (isFrench
            ? 'NUANCES ÉMOTIONNELLES DOMINANTES'
            : 'RECURRING AFFECT SPECTRUM');

  String get cohortAvgMetricsTitle => isArabic
      ? 'متوسط مؤشرات الـ 7 أيام'
      : (isFrench ? 'MOYENNES SUR 7 JOURS' : 'COHORT 7-DAY AVERAGES');

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
      ? 'أداة مساعدة للملاحظة السريرية وليست تشخيصاً آلياً. التحليل يعتمد على معطيات المريض الموافَق عليها.'
      : (isFrench
            ? 'Aide à l’observation clinique sans diagnostic automatisé. Toutes les données reflètent le consentement patient.'
            : 'Clinical observation aid only — never an automated diagnostic or prediction tool. Private cases stay strictly excluded.');

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
      ? 'تم فك تشفير الملف وإضافته بأمان.'
      : (isFrench
            ? 'Dossier déchiffré et importé avec succès.'
            : 'Patient packet decrypted and imported.');

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
      ? 'نسخ ملخص العيادة'
      : (isFrench ? 'Copier résumé dossier' : 'Copy EHR Note');

  String get ehrCopiedSnackbar => isArabic
      ? 'تم نسخ الملخص السريري المنظم.'
      : (isFrench
            ? 'Résumé structuré copié dans le presse-papiers.'
            : 'Structured EHR consultation summary copied.');

  String get consentScopeBannerTitle => isArabic
      ? 'نطاق موافقة المريض'
      : (isFrench ? 'PORTÉE DU CONSENTEMENT PATIENT' : 'PATIENT CONSENT SCOPE');

  String get recentVsBaselineTitle => isArabic
      ? 'آخر 7 أيام مقارنة بمرجع المريض'
      : (isFrench
            ? '7 DERNIERS JOURS VS LIGNE DE BASE'
            : '7-DAY RECENT VS PERSONAL BASELINE');

  String get metricColumnLabel =>
      isArabic ? 'المؤشر' : (isFrench ? 'Indicateur' : 'Metric');

  String get recent7dColumnLabel =>
      isArabic ? '7 أيام' : (isFrench ? '7j' : '7d');

  String get baselineColumnLabel =>
      isArabic ? 'المرجع' : (isFrench ? 'Base' : 'Baseline');

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
      isArabic ? 'شدة المزاج' : (isFrench ? 'Humeur' : 'Mood');

  String get metricSleepLabel =>
      isArabic ? 'النوم (س)' : (isFrench ? 'Sommeil (h)' : 'Sleep (h)');

  String get metricEnergyLabel =>
      isArabic ? 'الطاقة' : (isFrench ? 'Énergie' : 'Energy');

  String get metricAnxietyLabel =>
      isArabic ? 'التوتر' : (isFrench ? 'Tension' : 'Anxiety');

  String get patientNotFoundTitle => isArabic
      ? 'ملف المريض غير متوفر'
      : (isFrench
            ? 'Dossier patient introuvable'
            : 'Patient record unavailable');

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
      ? 'المهدّئات الملاحَظة'
      : (isFrench ? 'STABILISATEURS OBSERVÉS' : 'OBSERVED STABILIZERS');

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
    final formatted = avg.toStringAsFixed(1);
    if (isArabic) return 'معدّل الشدّة $formatted/10';
    if (isFrench) return 'intensité moy. $formatted/10';
    return 'avg mood $formatted/10';
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
      : (isFrench ? 'ÉVOLUTION DEPUIS LA DERNIÈRE VISITE' : 'SINCE LAST VISIT');

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
      ? 'خريطة الحلقة الملاحظة'
      : (isFrench ? 'CARTE DE BOUCLE OBSERVÉE' : 'OBSERVED FORENSIC LOOP');

  String get forensicLoopMapSub => isArabic
      ? 'ترابط وصفي بين السياق اليومي، التوقيت والمشاعر، الفكرة الملاحظة، وما يساعد على الهدوء.'
      : (isFrench
            ? 'Relie contexte quotidien, rythme émotionnel, chaîne cognitive et stabilisateurs observés.'
            : 'Descriptive link across daily context, diurnal affect, observed thought chains, and stabilizers.');

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
      ? 'عنصر التهدئة الملاحظ'
      : (isFrench ? 'Stabilisateur observé' : 'Observed stabilizer');

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
