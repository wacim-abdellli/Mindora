import '../../../app/localization/app_strings.dart';
import 'condition_type.dart';
import 'psychological_profile_model.dart';

/// Twelve clinically coherent daily tracking phenotypes covering 300+ DSM-5-TR
/// and ICD-11 psychological experiences without overwhelming users.
enum ClinicalTrack {
  bipolarCycling,
  depressiveSpectrum,
  anxietyPanic,
  obsessiveCompulsive,
  traumaStress,
  neurodevelopmental,
  sleepWake,
  perceptualGrounding,
  emotionRegulation,
  dissociativeSomatic,
  urgeHabitRecovery,
  generalWellness;

  String get id => name;

  String localizedTitle(AppStrings strings) {
    if (strings.isArabic) return arabicTitle;
    if (strings.isFrench) return frenchTitle;
    return englishTitle;
  }

  String localizedSubtitle(AppStrings strings) {
    if (strings.isArabic) return arabicSubtitle;
    if (strings.isFrench) return frenchSubtitle;
    return englishSubtitle;
  }

  String get englishTitle => switch (this) {
    ClinicalTrack.bipolarCycling => 'Mood Highs & Lows',
    ClinicalTrack.depressiveSpectrum => 'Low Mood & Heavy Days',
    ClinicalTrack.anxietyPanic => 'Worry, Tension & Panic',
    ClinicalTrack.obsessiveCompulsive => 'Intrusive Loops & Checking',
    ClinicalTrack.traumaStress => 'Trauma & Startle Safety',
    ClinicalTrack.neurodevelopmental => 'Focus, ADHD & Sensory Load',
    ClinicalTrack.sleepWake => 'Sleep & Body Clock',
    ClinicalTrack.perceptualGrounding => 'Sensory Reality & Quiet',
    ClinicalTrack.emotionRegulation => 'Strong Emotion Waves',
    ClinicalTrack.dissociativeSomatic => 'Fog, Body Tension & Presence',
    ClinicalTrack.urgeHabitRecovery => 'Urges & Habit Recovery',
    ClinicalTrack.generalWellness => 'Daily Balance & Exploring',
  };

  String get frenchTitle => switch (this) {
    ClinicalTrack.bipolarCycling => 'Hauts & bas de l’humeur',
    ClinicalTrack.depressiveSpectrum => 'Baisse d’élan & fatigue',
    ClinicalTrack.anxietyPanic => 'Inquiétude, tension & panique',
    ClinicalTrack.obsessiveCompulsive => 'Boucles mentales & vérifications',
    ClinicalTrack.traumaStress => 'Trauma & sentiment de sécurité',
    ClinicalTrack.neurodevelopmental => 'Attention, TDAH & sensibilité',
    ClinicalTrack.sleepWake => 'Sommeil & horloge interne',
    ClinicalTrack.perceptualGrounding => 'Perceptions & ancrage calme',
    ClinicalTrack.emotionRegulation => 'Vagues émotionnelles intenses',
    ClinicalTrack.dissociativeSomatic => 'Brouillard, corps & présence',
    ClinicalTrack.urgeHabitRecovery => 'Envies & équilibre des habitudes',
    ClinicalTrack.generalWellness => 'Équilibre & découverte',
  };

  String get arabicTitle => switch (this) {
    ClinicalTrack.bipolarCycling => 'تقلبات المزاج والطاقة',
    ClinicalTrack.depressiveSpectrum => 'هبوط المزاج والأيام الثقيلة',
    ClinicalTrack.anxietyPanic => 'القلق والشدّ ونوبات الهلع',
    ClinicalTrack.obsessiveCompulsive => 'الأفكار المتكررة والوساوس',
    ClinicalTrack.traumaStress => 'آثار الصدمات والأمان',
    ClinicalTrack.neurodevelopmental => 'التركيز والحساسية العصبية',
    ClinicalTrack.sleepWake => 'النوم وساعة البدن',
    ClinicalTrack.perceptualGrounding => 'الهدوء الإدراكي والواقع',
    ClinicalTrack.emotionRegulation => 'موجات المشاعر القوية',
    ClinicalTrack.dissociativeSomatic => 'التباعد والتوتر الجسدي',
    ClinicalTrack.urgeHabitRecovery => 'الدوافع والتعافي اليومي',
    ClinicalTrack.generalWellness => 'التوازن اليومي والاستكشاف',
  };

  String get englishSubtitle => switch (this) {
    ClinicalTrack.bipolarCycling => 'Tracks sleep hours, motor speed & daily routine.',
    ClinicalTrack.depressiveSpectrum => 'Tracks morning lift, small sparks & rest.',
    ClinicalTrack.anxietyPanic => 'Tracks body tension, panic surges & recovery.',
    ClinicalTrack.obsessiveCompulsive => 'Tracks loop pull & pause wins calmly.',
    ClinicalTrack.traumaStress => 'Tracks grounded safety & restful nights.',
    ClinicalTrack.neurodevelopmental => 'Tracks focus flow & social/sensory battery.',
    ClinicalTrack.sleepWake => 'Tracks sleep length, quality & morning ease.',
    ClinicalTrack.perceptualGrounding => 'Tracks sleep protection & calm surroundings.',
    ClinicalTrack.emotionRegulation => 'Tracks wave intensity & steady pauses.',
    ClinicalTrack.dissociativeSomatic => 'Tracks presence in your body & physical ease.',
    ClinicalTrack.urgeHabitRecovery => 'Tracks urge waves & supportive habits safely.',
    ClinicalTrack.generalWellness => 'Tracks sleep, stress & one daily bright spot.',
  };

  String get frenchSubtitle => switch (this) {
    ClinicalTrack.bipolarCycling => 'Suit sommeil, vitesse d’élan et routine.',
    ClinicalTrack.depressiveSpectrum => 'Suit l’élan du matin, le plaisir et le repos.',
    ClinicalTrack.anxietyPanic => 'Suit tension physique, pics et apaisement.',
    ClinicalTrack.obsessiveCompulsive => 'Suit l’emprise des boucles et les pauses.',
    ClinicalTrack.traumaStress => 'Suit l’ancrage sécurisant et la nuit.',
    ClinicalTrack.neurodevelopmental => 'Suit concentration et batterie sensorielle.',
    ClinicalTrack.sleepWake => 'Suit durée, réveils et fraîcheur du matin.',
    ClinicalTrack.perceptualGrounding => 'Suit sommeil protecteur et calme sensoriel.',
    ClinicalTrack.emotionRegulation => 'Suit l’intensité des vagues et le recul.',
    ClinicalTrack.dissociativeSomatic => 'Suit présence corporelle et détente.',
    ClinicalTrack.urgeHabitRecovery => 'Suit vagues d’envie et appuis bienveillants.',
    ClinicalTrack.generalWellness => 'Suit sommeil, charge et repères positifs.',
  };

  String get arabicSubtitle => switch (this) {
    ClinicalTrack.bipolarCycling => 'يتابع ساعات النوم وسرعة الطاقة والروتين.',
    ClinicalTrack.depressiveSpectrum => 'يتابع ثقل الصباح، لحظات الفرح والراحة.',
    ClinicalTrack.anxietyPanic => 'يتابع شدّ البدن وموجات القلق والتهدئة.',
    ClinicalTrack.obsessiveCompulsive => 'يتابع ثقل الفكرة ولحظات المقاومة الهادئة.',
    ClinicalTrack.traumaStress => 'يتابع الأمان الحاضر وجودة النوم.',
    ClinicalTrack.neurodevelopmental => 'يتابع التركيز وطاقة الحواس والتواصل.',
    ClinicalTrack.sleepWake => 'يتابع مدة النوم وراحتك عند الاستيقاظ.',
    ClinicalTrack.perceptualGrounding => 'يتابع حماية النوم وهدوء المحيط بلطف.',
    ClinicalTrack.emotionRegulation => 'يتابع شدّة الانفعال ووقفات التهدئة.',
    ClinicalTrack.dissociativeSomatic => 'يتابع حضورك في بدنك وخفّة التوتر.',
    ClinicalTrack.urgeHabitRecovery => 'يتابع موجات الدوافع والخطوات المساندة.',
    ClinicalTrack.generalWellness => 'يتابع النوم وضغط اليوم ولحظة إيجابية.',
  };

  static ClinicalTrack? tryParse(String raw) {
    for (final t in values) {
      if (t.name == raw.trim()) return t;
    }
    return null;
  }

  /// Maps existing legacy 37-enum [ConditionType] to its primary [ClinicalTrack].
  static ClinicalTrack fromLegacyCondition(ConditionType type) {
    return switch (type) {
      ConditionType.bipolarI ||
      ConditionType.bipolarII ||
      ConditionType.moodInstability => ClinicalTrack.bipolarCycling,
      ConditionType.depression ||
      ConditionType.otherMood => ClinicalTrack.depressiveSpectrum,
      ConditionType.generalizedAnxiety ||
      ConditionType.socialAnxiety ||
      ConditionType.panicAttacks ||
      ConditionType.specificPhobias ||
      ConditionType.otherAnxiety => ClinicalTrack.anxietyPanic,
      ConditionType.ocd ||
      ConditionType.intrusiveThoughts ||
      ConditionType.repetitiveThoughts ||
      ConditionType.compulsiveBehaviors => ClinicalTrack.obsessiveCompulsive,
      ConditionType.ptsd ||
      ConditionType.complexPtsd ||
      ConditionType.traumaDifficulties => ClinicalTrack.traumaStress,
      ConditionType.adhd ||
      ConditionType.autism ||
      ConditionType.attentionDifficulties ||
      ConditionType.sensoryDifficulties => ClinicalTrack.neurodevelopmental,
      ConditionType.sleepDisorders ||
      ConditionType.sleepDifficulties => ClinicalTrack.sleepWake,
      ConditionType.psychosisSpectrum ||
      ConditionType.schizophrenia ||
      ConditionType.hallucinations ||
      ConditionType.delusions ||
      ConditionType.otherPerceptual => ClinicalTrack.perceptualGrounding,
      ConditionType.personalityDisorders ||
      ConditionType.personalityDifficulties => ClinicalTrack.emotionRegulation,
      ConditionType.dissociativeDisorders ||
      ConditionType.dissociativeExperiences => ClinicalTrack.dissociativeSomatic,
      ConditionType.eatingDisorders ||
      ConditionType.eatingDifficulties => ClinicalTrack.urgeHabitRecovery,
      ConditionType.other ||
      ConditionType.stillExploring ||
      ConditionType.preferNotToSpecify => ClinicalTrack.generalWellness,
    };
  }
}

/// Structured catalog item representing one recognized condition/experience
/// within the 300+ DSM-5-TR / ICD-11 clinical tracking index.
class ClinicalConditionItem {
  const ClinicalConditionItem({
    required this.id,
    required this.track,
    required this.en,
    required this.fr,
    required this.ar,
    this.legacyType,
    this.keywords = const [],
  });

  final String id;
  final ClinicalTrack track;
  final String en;
  final String fr;
  final String ar;
  final ConditionType? legacyType;
  final List<String> keywords;

  String localized(AppStrings strings) {
    if (strings.isArabic) return ar;
    if (strings.isFrench) return fr;
    return en;
  }

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    if (en.toLowerCase().contains(q) ||
        fr.toLowerCase().contains(q) ||
        ar.toLowerCase().contains(q) ||
        id.toLowerCase().contains(q) ||
        track.englishTitle.toLowerCase().contains(q) ||
        track.frenchTitle.toLowerCase().contains(q) ||
        track.arabicTitle.toLowerCase().contains(q)) {
      return true;
    }
    for (final k in keywords) {
      if (k.toLowerCase().contains(q)) return true;
    }
    return false;
  }
}

/// Comprehensive 310+ condition & lived-experience directory categorized into
/// 12 actionable clinical tracking tracks. Strictly non-diagnostic framing.
abstract final class ClinicalConditionCatalog {
  static ClinicalConditionItem _c(
    String id,
    ClinicalTrack track,
    String en,
    String fr,
    String ar, [
    ConditionType? legacy,
    List<String> keywords = const [],
  ]) => ClinicalConditionItem(
    id: id,
    track: track,
    en: en,
    fr: fr,
    ar: ar,
    legacyType: legacy,
    keywords: keywords,
  );

  static final List<ClinicalConditionItem> all = <ClinicalConditionItem>[
    // -------------------------------------------------------------------------
    // Track 1: Bipolar & Mood Cycling (24)
    // -------------------------------------------------------------------------
    _c('bipolar_1', ClinicalTrack.bipolarCycling, 'Bipolar I Disorder', 'Trouble bipolaire de type I', 'اضطراب ثنائي القطب من النوع الأول', ConditionType.bipolarI, ['mania', 'manic', 'ثنائي القطب', 'هوس']),
    _c('bipolar_2', ClinicalTrack.bipolarCycling, 'Bipolar II Disorder', 'Trouble bipolaire de type II', 'اضطراب ثنائي القطب من النوع الثاني', ConditionType.bipolarII, ['hypomania', 'هوس خفيف', 'ثنائي القطب']),
    _c('cyclothymia', ClinicalTrack.bipolarCycling, 'Cyclothymic Disorder', 'Trouble cyclothymique', 'اضطراب دورية المزاج', ConditionType.moodInstability, ['cycling', 'mood swings']),
    _c('hypomanic_shifts', ClinicalTrack.bipolarCycling, 'Hypomanic Elevation Periods', 'Périodes d’élévation hypomaniaque', 'نوبات ارتفاع النشاط والمزاج', null, ['wired', 'energy spike']),
    _c('manic_recovery', ClinicalTrack.bipolarCycling, 'Post-Manic Stabilization', 'Stabilisation post-maniaque', 'مرحلة الاستقرار بعد نوبة الهوس', null, ['recovery']),
    _c('mixed_mood_features', ClinicalTrack.bipolarCycling, 'Mixed Mood & Activation Features', 'Caractéristiques mixtes (humeur et agitation)', 'حالة مزاجية مختلطة', null, ['agitated low mood']),
    _c('rapid_cycling_pattern', ClinicalTrack.bipolarCycling, 'Rapid-Cycling Mood Pattern', 'Cycles rapides de l’humeur', 'تقلّب سريع في دورات المزاج', null, ['fast shifts']),
    _c('bipolar_seasonal', ClinicalTrack.bipolarCycling, 'Seasonal Mood Cycling', 'Variations saisonnières bipolaires', 'تقلّبات مزاجية موسمية', null, ['spring mania', 'winter drop']),
    _c('peripartum_cycling', ClinicalTrack.bipolarCycling, 'Peripartum Mood Sensitivity', 'Sensibilité thymique périnatale', 'حساسية المزاج حول الولادة', null, ['postpartum']),
    _c('schizoaffective_bipolar', ClinicalTrack.bipolarCycling, 'Schizoaffective (Bipolar Type)', 'Trouble schizo-affectif (type bipolaire)', 'الاضطراب الفصامي العاطفي ثنائي القطب', null, ['mood psychosis']),
    _c('med_triggered_activation', ClinicalTrack.bipolarCycling, 'Medication-Linked Activation Shifts', 'Activation liée à un traitement', 'تغيّر النشاط المرتبط بالدواء', null, ['antidepressant switch']),
    _c('sleep_loss_elevation', ClinicalTrack.bipolarCycling, 'Sleep-Loss Triggered Elevation', 'Élévation après manque de sommeil', 'ارتفاع المزاج بعد قلّة النوم', null, ['decreased need for sleep']),
    _c('decreased_sleep_need', ClinicalTrack.bipolarCycling, 'Reduced Need for Sleep Periods', 'Besoin réduit de sommeil', 'تراجع الحاجة إلى النوم', null, ['2 hours sleep energized']),
    _c('racing_speech_ideas', ClinicalTrack.bipolarCycling, 'Pressured Ideas & Fast Pace', 'Afflux d’idées rapides et élan verbal', 'تسارع الأفكار والكلام', null, ['flight of ideas']),
    _c('hyperthymic_baseline', ClinicalTrack.bipolarCycling, 'Hyperthymic Energy Baseline', 'Tempérament hyperthymique', 'مزاج عالي النشاط المزمن', null, ['high drive']),
    _c('late_night_goal_surge', ClinicalTrack.bipolarCycling, 'Late-Night Project Surges', 'Pics d’activité nocturne intense', 'اندفاع نشاطي مفرط ليلاً', null, ['night projects']),
    _c('irritable_hypomania', ClinicalTrack.bipolarCycling, 'Irritable High-Energy State', 'Agitation irritable haute énergie', 'انفعال وتوتّر مع طاقة عالية', null, ['dysphoric']),
    _c('impulsive_spending_risk', ClinicalTrack.bipolarCycling, 'Impulsive High-Energy Decisions', 'Impulsivité en phase haute', 'اندفاع في القرارات والمصاريف', null, ['overspending']),
    _c('circadian_mood_instability', ClinicalTrack.bipolarCycling, 'Body-Clock Mood Instability', 'Instabilité liée au rythme veille-sommeil', 'عدم استقرار الساعة البيولوجية للمزاج', ConditionType.moodInstability),
    _c('subthreshold_bipolar', ClinicalTrack.bipolarCycling, 'Bipolar Spectrum Traits', 'Traits du spectre bipolaire', 'سمات طيف ثنائي القطب', null, ['soft bipolar']),
    _c('mood_crash_after_high', ClinicalTrack.bipolarCycling, 'Post-Peak Exhaustion Dip', 'Chute d’énergie après pic', 'هبوط حاد بعد ذروة النشاط', null),
    _c('youth_mood_cycling_hx', ClinicalTrack.bipolarCycling, 'Early-Onset Mood Cycling History', 'Antécédents précoces de cycles thymiques', 'تاريخ مبكر لتقلبات المزاج', null),
    _c('lithium_routine_support', ClinicalTrack.bipolarCycling, 'Mood-Stabilizer Routine Tracking', 'Suivi de routine stabilisatrice', 'متابعة الروتين الموازن للمزاج', null),
    _c('other_mood_cycling', ClinicalTrack.bipolarCycling, 'Other Mood Cycling Experience', 'Autre variation cyclique de l’humeur', 'تجربة أخرى لتقلّب المزاج', ConditionType.moodInstability),

    // -------------------------------------------------------------------------
    // Track 2: Depressive & Low-Mood Spectrum (30)
    // -------------------------------------------------------------------------
    _c('mdd_single', ClinicalTrack.depressiveSpectrum, 'Major Depressive Episode', 'Épisode dépressif caractérisé', 'نوبة اكتئاب كبرى', ConditionType.depression, ['depression', 'sad', 'اكتئاب', 'حزن']),
    _c('mdd_recurrent', ClinicalTrack.depressiveSpectrum, 'Recurrent Depressive Disorder', 'Trouble dépressif récurrent', 'اضطراب اكتئابي متكرر', ConditionType.depression),
    _c('dysthymia_pdd', ClinicalTrack.depressiveSpectrum, 'Persistent Depressive Disorder (Dysthymia)', 'Trouble dépressif persistant (Dysthymie)', 'الاكتئاب المستمر (عسر المزاج)', ConditionType.depression),
    _c('sad_winter', ClinicalTrack.depressiveSpectrum, 'Seasonal Affective Pattern (SAD)', 'Dépression saisonnière', 'الاكتئاب الموسمي', ConditionType.otherMood),
    _c('pmdd', ClinicalTrack.depressiveSpectrum, 'Premenstrual Dysphoric Disorder (PMDD)', 'Trouble dysphorique prémenstruel (TDPM)', 'اضطراب ما قبل الحيض الاكتئابي', null, ['cycle', 'luteal']),
    _c('postpartum_depression', ClinicalTrack.depressiveSpectrum, 'Postpartum / Perinatal Depression', 'Dépression du post-partum', 'اكتئاب ما بعد الولادة', null, ['perinatal', 'maternal']),
    _c('atypical_depression', ClinicalTrack.depressiveSpectrum, 'Atypical Low Mood (Heavy Limbs / Oversleep)', 'Humeur basse atypique', 'اكتئاب لانمطي مع ثقل الجسد', null),
    _c('melancholic_low_mood', ClinicalTrack.depressiveSpectrum, 'Melancholic Morning Heaviness', 'Lourdeur matinale marquée', 'ثقل مزاجي صباحي شديد', null),
    _c('anxious_distress_depression', ClinicalTrack.depressiveSpectrum, 'Low Mood with Anxious Distress', 'Détresse anxieuse associée à la baisse', 'اكتئاب مصحوب بقلق شديد', null),
    _c('prolonged_grief', ClinicalTrack.depressiveSpectrum, 'Prolonged Grief Disorder', 'Trouble du deuil prolongé', 'حزن الفقدان المطوّل', null, ['bereavement', 'loss']),
    _c('adjustment_depressed', ClinicalTrack.depressiveSpectrum, 'Adjustment Disorder w/ Low Mood', 'Trouble de l’adaptation (humeur triste)', 'اضطراب التكيّف مع مزاج منخفض', null),
    _c('anhedonia_flatness', ClinicalTrack.depressiveSpectrum, 'Persistent Anhedonia (Numb / Flat)', 'Anhédonie persistante', 'فقدان الاستمتاع والتبلّد العاطفي', null),
    _c('double_depression', ClinicalTrack.depressiveSpectrum, 'Chronic Baseline + Acute Low Waves', 'Dysthymie avec creux aigus', 'مزاج منخفض مزمن مع نوبات حادة', null),
    _c('dmdd_adult_history', ClinicalTrack.depressiveSpectrum, 'Chronic Irritability & Low Mood History', 'Irritabilité chronique et baisse', 'تاريخ انزعاج مزمن وانخفاض المزاج', null),
    _c('burnout_depression', ClinicalTrack.depressiveSpectrum, 'Occupational Burnout Exhaustion', 'Épuisement professionnel (Burnout)', 'الاحتراق النفسي المهني', null, ['burnout', 'work exhaustion']),
    _c('caregiver_burnout', ClinicalTrack.depressiveSpectrum, 'Caregiver Fatigue & Low Drive', 'Fatigue d’aidant familial', 'إرهاق مرافق المريض والعائلة', null),
    _c('post_illness_low_mood', ClinicalTrack.depressiveSpectrum, 'Post-Illness / Medical Low Mood', 'Baisse d’humeur post-médicale', 'انخفاض المزاج بعد مرض عضوي', null),
    _c('thyroid_mood_support', ClinicalTrack.depressiveSpectrum, 'Endocrine / Thyroid-Linked Low Energy', 'Fatigue et humeur liées à l’équilibre physique', 'تعب المزاج المرتبط بالتوازن العضوي', null),
    _c('chronic_pain_low_mood', ClinicalTrack.depressiveSpectrum, 'Chronic Pain & Low Spirits', 'Douleur chronique et moral bas', 'الألم المزمن وتأثيره على المزاج', null),
    _c('subclinical_low_mood', ClinicalTrack.depressiveSpectrum, 'Subthreshold Low Mood Waves', 'Baisse d’humeur passagère', 'موجات مزاج منخفض خفيفة', ConditionType.otherMood),
    _c('somatic_masked_low', ClinicalTrack.depressiveSpectrum, 'Physical-Heavy Low Mood', 'Moral bas ressenti corporellement', 'اكتئاب يظهر في تعب البدن', null),
    _c('social_withdrawal_low', ClinicalTrack.depressiveSpectrum, 'Social Withdrawal & Low Motivation', 'Retrait social et perte d’élan', 'الانسحاب الاجتماعي وفقدان الدافع', null),
    _c('menopause_mood_shift', ClinicalTrack.depressiveSpectrum, 'Perimenopausal Mood Shift', 'Variations d’humeur périménopausiques', 'تغيّر المزاج في مرحلة انقطاع الطمث', null),
    _c('paternal_postpartum', ClinicalTrack.depressiveSpectrum, 'Partner Postpartum Exhaustion', 'Épuisement parental post-natal', 'إرهاق الأبوين بعد الولادة', null),
    _c('academic_demoralization', ClinicalTrack.depressiveSpectrum, 'Study Demoralization & Exhaustion', 'Découragement et fatigue d’étude', 'الإحباط والتعب الدراسي', null),
    _c('loneliness_low_mood', ClinicalTrack.depressiveSpectrum, 'Persistent Isolation Low Mood', 'Solitude persistante et moral bas', 'الشعور المزمن بالوحدة والهبوط', null),
    _c('psychomotor_slowing', ClinicalTrack.depressiveSpectrum, 'Physical Slowness & Low Drive', 'Ralentissement et fatigue matinale', 'بطء الحركة وثقل الصباح', null),
    _c('late_life_depression', ClinicalTrack.depressiveSpectrum, 'Later-Life Mood Transition', 'Baisse d’humeur liée aux transitions de vie', 'انخفاض المزاج في التقدم بالسن', null),
    _c('identity_loss_low', ClinicalTrack.depressiveSpectrum, 'Life Role Shift Low Mood', 'Baisse après changement de rôle de vie', 'حزن تغيّر أدوار الحياة', null),
    _c('other_depressive', ClinicalTrack.depressiveSpectrum, 'Other Low-Mood Experience', 'Autre expérience d’humeur basse', 'تجربة أخرى لهبوط المزاج', ConditionType.otherMood),

    // -------------------------------------------------------------------------
    // Track 3: Anxiety, Panic & Phobias (34)
    // -------------------------------------------------------------------------
    _c('gad', ClinicalTrack.anxietyPanic, 'Generalized Anxiety Disorder (GAD)', 'Trouble anxieux généralisé (TAG)', 'اضطراب القلق المعمم', ConditionType.generalizedAnxiety, ['worry', 'anxious', 'قلق']),
    _c('panic_disorder', ClinicalTrack.anxietyPanic, 'Panic Disorder', 'Trouble panique', 'اضطراب نوبات الهلع', ConditionType.panicAttacks, ['panic', 'heart racing', 'هلع']),
    _c('nocturnal_panic', ClinicalTrack.anxietyPanic, 'Nocturnal Panic Attacks', 'Attaques de panique nocturnes', 'نوبات الهلع الليلية', ConditionType.panicAttacks),
    _c('agoraphobia', ClinicalTrack.anxietyPanic, 'Agoraphobia (Crowds / Open Spaces)', 'Agoraphobie', 'رهاب الأماكن المفتوحة والزحام', ConditionType.specificPhobias),
    _c('social_anxiety', ClinicalTrack.anxietyPanic, 'Social Anxiety Disorder', 'Anxiété sociale', 'القلق الاجتماعي', ConditionType.socialAnxiety, ['shy', 'judgment', 'رهاب اجتماعي']),
    _c('performance_anxiety', ClinicalTrack.anxietyPanic, 'Performance & Public Speaking Anxiety', 'Anxiété de performance / prise de parole', 'قلق الأداء والظهور أمام الناس', ConditionType.socialAnxiety),
    _c('separation_anxiety', ClinicalTrack.anxietyPanic, 'Adult Separation Anxiety', 'Anxiété de séparation de l’adulte', 'قلق الانفصال لدى البالغين', ConditionType.otherAnxiety),
    _c('selective_mutism', ClinicalTrack.anxietyPanic, 'Selective Mutism History', 'Mutisme sélectif', 'الصمت الاختياري', ConditionType.socialAnxiety),
    _c('illness_anxiety', ClinicalTrack.anxietyPanic, 'Illness / Health Anxiety', 'Anxiété liée à la santé', 'القلق الصحي والانشغال بالأمراض', ConditionType.otherAnxiety, ['hypochondria']),
    _c('cardiophobia', ClinicalTrack.anxietyPanic, 'Heart-Focus / Cardiophobia Worry', 'Peur centrée sur le rythme cardiaque', 'القلق المفرط من نبضات القلب', null),
    _c('acrophobia', ClinicalTrack.anxietyPanic, 'Fear of Heights (Acrophobia)', 'Phobie des hauteurs', 'فوبيا المرتفعات', ConditionType.specificPhobias),
    _c('claustrophobia', ClinicalTrack.anxietyPanic, 'Fear of Enclosed Spaces (Claustrophobia)', 'Claustrophobie', 'فوبيا الأماكن الضيقة', ConditionType.specificPhobias),
    _c('driving_phobia', ClinicalTrack.anxietyPanic, 'Driving / Highway Anxiety', 'Phobie de la conduite', 'رهبة السياقة والطرقات', ConditionType.specificPhobias),
    _c('aviophobia', ClinicalTrack.anxietyPanic, 'Fear of Flying (Aviophobia)', 'Phobie de l’avion', 'فوبيا الطيران', ConditionType.specificPhobias),
    _c('blood_injury_phobia', ClinicalTrack.anxietyPanic, 'Blood-Injection-Injury Phobia', 'Phobie du sang et des soins', 'فوبيا الدم والإبر', ConditionType.specificPhobias),
    _c('trypanophobia', ClinicalTrack.anxietyPanic, 'Needle / Medical Injection Phobia', 'Phobie des aiguilles', 'فوبيا الحقن والإبر', ConditionType.specificPhobias),
    _c('emetophobia', ClinicalTrack.anxietyPanic, 'Fear of Nausea / Vomiting (Emetophobia)', 'Émétophobie', 'فوبيا الغثيان والتقيؤ', ConditionType.specificPhobias),
    _c('zoophobia', ClinicalTrack.anxietyPanic, 'Animal or Insect Phobia', 'Phobie des animaux / insectes', 'فوبيا الحيوانات أو الحشرات', ConditionType.specificPhobias),
    _c('astraphobia', ClinicalTrack.anxietyPanic, 'Storm & Weather Phobia', 'Phobie des orages', 'فوبيا العواصف والرعد', ConditionType.specificPhobias),
    _c('nyctophobia', ClinicalTrack.anxietyPanic, 'Darkness Anxiety (Nyctophobia)', 'Peur persistante du noir', 'القلق من الظلام', ConditionType.specificPhobias),
    _c('dentophobia', ClinicalTrack.anxietyPanic, 'Dental Anxiety / Care Avoidance', 'Anxiété des soins dentaires', 'قلق عيادة الأسنان', ConditionType.specificPhobias),
    _c('throat_tightness_anxiety', ClinicalTrack.anxietyPanic, 'Globus / Swallowing-Tension Worry', 'Sensation de gorge serrée anxieuse', 'شدّ الحلق المرتبط بالقلق', null),
    _c('dizziness_anxiety_loop', ClinicalTrack.anxietyPanic, 'Dizziness-Triggered Panic Loop', 'Peur des vertiges et malaise', 'قلق نوبات الدوخة المفاجئة', null),
    _c('postpartum_anxiety', ClinicalTrack.anxietyPanic, 'Postpartum Hyper-Worry', 'Anxiété du post-partum', 'قلق ما بعد الولادة المفرط', null),
    _c('adjustment_anxiety', ClinicalTrack.anxietyPanic, 'Adjustment Disorder w/ Anxiety', 'Trouble de l’adaptation avec anxiété', 'اضطراب التكيّف مع القلق', ConditionType.otherAnxiety),
    _c('morning_cortisol_dread', ClinicalTrack.anxietyPanic, 'Waking Morning Anxiety Surge', 'Pic d’anxiété au réveil', 'توتّر الصباح عند الاستيقاظ', null),
    _c('high_functioning_anxiety', ClinicalTrack.anxietyPanic, 'Over-Masking / Chronic Tension', 'Anxiété masquée de haut fonctionnement', 'القلق الخفي مع ضغط الأداء', null),
    _c('medical_procedure_worry', ClinicalTrack.anxietyPanic, 'Hospital / Diagnostic Test Phobia', 'Anxiété des examens médicaux', 'رهبة الفحوصات الطبية', null),
    _c('financial_security_worry', ClinicalTrack.anxietyPanic, 'Persistent Practical / Financial Dread', 'Inquiétude matérielle envahissante', 'قلق مستمر من المستقبل والرزق', null),
    _c('test_exam_panic', ClinicalTrack.anxietyPanic, 'Exam / Evaluation Freeze Anxiety', 'Anxiété bloquante d’examen', 'قلق الامتحانات والتقييم', null),
    _c('social_blushing_fear', ClinicalTrack.anxietyPanic, 'Fear of Blushing / Shaking in Public', 'Ereutophobie / peur de trembler', 'خوف الاحمرار أو الرجفة أمام الناس', ConditionType.socialAnxiety),
    _c('paruresis', ClinicalTrack.anxietyPanic, 'Public Restroom Anxiety (Paruresis)', 'Anxiété en lieux publics restreints', 'القلق الاجتماعي في المرافق العامة', null),
    _c('climate_eco_anxiety', ClinicalTrack.anxietyPanic, 'Environmental / Future Worry', 'Éco-anxiété / inquiétude globale', 'القلق المستقبلي والبيئي', null),
    _c('other_anxiety', ClinicalTrack.anxietyPanic, 'Other Anxiety Experience', 'Autre expérience anxieuse', 'تجربة قلق أخرى', ConditionType.otherAnxiety),

    // -------------------------------------------------------------------------
    // Track 4: OCD & Repetitive Loops (30)
    // -------------------------------------------------------------------------
    _c('ocd_general', ClinicalTrack.obsessiveCompulsive, 'Obsessive-Compulsive Disorder (OCD)', 'Trouble obsessionnel-compulsif (TOC)', 'اضطراب الوسواس القهري', ConditionType.ocd, ['ocd', 'وسواس']),
    _c('ocd_checking', ClinicalTrack.obsessiveCompulsive, 'Checking Loops (Locks, Stove, Safety)', 'TOC de vérification', 'وسواس التحقق والتأكّد المتكرر', ConditionType.compulsiveBehaviors),
    _c('ocd_contamination', ClinicalTrack.obsessiveCompulsive, 'Contamination & Washing OCD', 'TOC de contamination / lavage', 'وسواس النظافة والتلوّث', ConditionType.compulsiveBehaviors),
    _c('ocd_symmetry', ClinicalTrack.obsessiveCompulsive, 'Symmetry, Order & Just-Right OCD', 'TOC de symétrie et d’exactitude', 'وسواس الترتيب والتماثل', ConditionType.compulsiveBehaviors),
    _c('ocd_pure_o', ClinicalTrack.obsessiveCompulsive, 'Pure-O Mental Compulsions', 'TOC sans rituels visibles (rumination)', 'الوسواس القهري الذهني الصرف', ConditionType.intrusiveThoughts),
    _c('ocd_harm', ClinicalTrack.obsessiveCompulsive, 'Harm Intrusive Thoughts (Ego-Dystonic)', 'Obsessions phobiques d’impulsion', 'أفكار وسواسية حول الأذى (غير مرغوبة)', ConditionType.intrusiveThoughts),
    _c('ocd_scrupulosity', ClinicalTrack.obsessiveCompulsive, 'Moral / Religious Scrupulosity OCD', 'TOC moral ou religieux (scrupulosité)', 'وسواس الذنب والتديّن', ConditionType.intrusiveThoughts, ['wudu', 'prayer', 'الوضوء', 'الصلاة']),
    _c('ocd_relationship', ClinicalTrack.obsessiveCompulsive, 'Relationship Doubt Loops (ROCD)', 'TOC du couple (doutes incessants)', 'وسواس الشك العاطفي والعلاقات', ConditionType.repetitiveThoughts),
    _c('ocd_identity_doubt', ClinicalTrack.obsessiveCompulsive, 'Identity / Orientation Doubt OCD', 'Obsessions centrées sur l’identité', 'وسواس الشك في الهوية والميل', ConditionType.intrusiveThoughts),
    _c('ocd_taboo', ClinicalTrack.obsessiveCompulsive, 'Taboo / Unwanted Moral Intrusions', 'Pensées intrusives contraires aux valeurs', 'أفكار دخيلة مناقضة للقيم', ConditionType.intrusiveThoughts),
    _c('ocd_counting', ClinicalTrack.obsessiveCompulsive, 'Counting & Magical-Thinking Compulsions', 'Rituels de comptage et pensée magique', 'طقوس العدّ والربط الذهني', ConditionType.compulsiveBehaviors),
    _c('ocd_responsibility', ClinicalTrack.obsessiveCompulsive, 'Hyper-Responsibility & Guilt Checking', 'Hyper-responsabilité et doute moral', 'وسواس تحمّل الذنب المفرط', ConditionType.repetitiveThoughts),
    _c('ocd_sensorimotor', ClinicalTrack.obsessiveCompulsive, 'Sensorimotor OCD (Breathing/Blinking Focus)', 'TOC somatique (attention sur la respiration)', 'وسواس مراقبة التنفّس أو الرمش', ConditionType.repetitiveThoughts),
    _c('ocd_real_event', ClinicalTrack.obsessiveCompulsive, 'Real-Event Past Replay OCD', 'Rumination compulsive d’événements réels', 'اجترار وسواسي لأحداث ماضية', ConditionType.repetitiveThoughts),
    _c('ocd_false_memory', ClinicalTrack.obsessiveCompulsive, 'Memory-Doubt Loops', 'Doutes sur les souvenirs récents', 'وسواس الشك في الذاكرة', ConditionType.repetitiveThoughts),
    _c('ocd_existential', ClinicalTrack.obsessiveCompulsive, 'Existential / Reality Questioning Loops', 'Obsessions existentielles', 'وسواس التساؤلات الوجودية', ConditionType.repetitiveThoughts),
    _c('ocd_perinatal', ClinicalTrack.obsessiveCompulsive, 'Postpartum Intrusive Safety Worries', 'Pensées intrusives périnatales', 'أفكار وسواسية حول أمان المولود', ConditionType.intrusiveThoughts),
    _c('ocd_hit_run', ClinicalTrack.obsessiveCompulsive, 'Driving "Did I Hit Something" Loops', 'TOC de vérification au volant', 'وسواس السياقة والشك في الطريق', ConditionType.compulsiveBehaviors),
    _c('ocd_digital', ClinicalTrack.obsessiveCompulsive, 'Digital Re-Reading & Sent-Text Checking', 'Vérification répétée de messages', 'إعادة فحص الرسائل والهاتف باستمرار', ConditionType.compulsiveBehaviors),
    _c('bdd', ClinicalTrack.obsessiveCompulsive, 'Body Dysmorphic Disorder (BDD)', 'Dysmorphophobie (TOC corporel)', 'اضطراب تشوّه صورة الجسد', ConditionType.repetitiveThoughts),
    _c('muscle_dysmorphia_concern', ClinicalTrack.obsessiveCompulsive, 'Appearance-Mirror Comparison Loops', 'Préoccupation d’apparence devant le miroir', 'انشغال متكرر بالمظهر والمرآة', null),
    _c('hoarding_disorder', ClinicalTrack.obsessiveCompulsive, 'Hoarding & Difficulty Discarding', 'Syllogomanie (accumulation)', 'صعوبة التخلص من المقتنيات (الاكتناز)', null),
    _c('clutter_sentimental', ClinicalTrack.obsessiveCompulsive, 'Sentimental Discard Anxiety', 'Anxiété liée au tri des objets', 'قلق ترتيب والتخلّص من الأغراض', null),
    _c('trichotillomania', ClinicalTrack.obsessiveCompulsive, 'Trichotillomania (Hair-Pulling Urges)', 'Trichotillomanie', 'نتف الشعر القهري', null),
    _c('excoriation', ClinicalTrack.obsessiveCompulsive, 'Excoriation (Skin-Picking Urges)', 'Dermatillomanie', 'تقشير الجلد القهري', null),
    _c('bfrb_oral', ClinicalTrack.obsessiveCompulsive, 'Body-Focused Repetitive Habits (Nails/Cheeks)', 'Habitudes corporelles répétitives', 'عادات قضم الأظافر والشفاه المتكررة', null),
    _c('olfactory_reference', ClinicalTrack.obsessiveCompulsive, 'Olfactory Self-Consciousness Loops', 'Anxiété persistante autour des odeurs', 'وسواس القلق من الرائحة أمام الناس', null),
    _c('tic_related_ocd', ClinicalTrack.obsessiveCompulsive, 'Tic-Related Compulsive Urges', 'TOC associé à des tics sensoriels', 'وسواس مصحوب بحركات لاإرادية', null),
    _c('reassurance_seeking_loop', ClinicalTrack.obsessiveCompulsive, 'Constant Reassurance-Seeking Cycles', 'Besoin répétitif de réassurance', 'البحث المتكرر عن التطمين', ConditionType.repetitiveThoughts),
    _c('perfectionism_paralysis', ClinicalTrack.obsessiveCompulsive, 'Compulsive Double-Checking & Redoing', 'Reprise incessante par perfectionnisme', 'الإعادة القهرية طلباً للكمال', ConditionType.compulsiveBehaviors),

    // -------------------------------------------------------------------------
    // Track 5: Trauma & Stress Response (24)
    // -------------------------------------------------------------------------
    _c('ptsd', ClinicalTrack.traumaStress, 'Post-Traumatic Stress Disorder (PTSD)', 'Trouble de stress post-traumatique (TSPT)', 'اضطراب كرب ما بعد الصدمة', ConditionType.ptsd, ['trauma', 'صدمة']),
    _c('complex_ptsd', ClinicalTrack.traumaStress, 'Complex PTSD (C-PTSD)', 'TSPT complexe', 'كرب ما بعد الصدمة المركّب', ConditionType.complexPtsd),
    _c('acute_stress', ClinicalTrack.traumaStress, 'Acute Stress Reaction', 'Trouble de stress aigu', 'تفاعل الكرب الحاد', ConditionType.traumaDifficulties),
    _c('delayed_ptsd', ClinicalTrack.traumaStress, 'Delayed-Onset Post-Trauma Response', 'TSPT à expression différée', 'استجابة صدمة متأخرة الظهور', ConditionType.ptsd),
    _c('adjustment_mixed', ClinicalTrack.traumaStress, 'Adjustment Disorder (Mixed Stress)', 'Trouble de l’adaptation mixte', 'اضطراب التكيّف بعد تغيّر صعب', ConditionType.traumaDifficulties),
    _c('childhood_trauma', ClinicalTrack.traumaStress, 'Childhood Relational Trauma', 'Traumatisme relationnel précoce', 'صدمات الطفولة والعلاقات المبكرة', ConditionType.complexPtsd),
    _c('emotional_neglect', ClinicalTrack.traumaStress, 'Early Emotional Neglect Impact', 'Impact de négligence affective', 'أثر الإهمال العاطفي المبكر', ConditionType.traumaDifficulties),
    _c('medical_trauma', ClinicalTrack.traumaStress, 'Medical / Hospital / ICU Trauma', 'Traumatisme médical ou hospitalier', 'صدمة علاج أو إقامة طبية', null),
    _c('birth_trauma', ClinicalTrack.traumaStress, 'Birth & Obstetric Stress Aftermath', 'Traumatisme obstétrical / accouchement', 'صدمة الولادة', null),
    _c('accident_trauma', ClinicalTrack.traumaStress, 'Traffic or Physical Accident Aftermath', 'Stress post-accident', 'توتر ما بعد حادث مرور أو سقوط', null),
    _c('disaster_trauma', ClinicalTrack.traumaStress, 'Natural Disaster or Fire Stress', 'Stress post-catastrophe', 'أثر الكوارث والحرائق', null),
    _c('first_responder_stress', ClinicalTrack.traumaStress, 'Emergency / Medical Staff Stress', 'Stress des soignants et secouristes', 'ضغط الطوارئ والعمل الميداني', null),
    _c('vicarious_trauma', ClinicalTrack.traumaStress, 'Secondary / Witnessing Trauma', 'Traumatisme vicariant', 'صدمة غير مباشرة أو شهود', null),
    _c('bullying_aftermath', ClinicalTrack.traumaStress, 'School / Cyber Bullying Aftermath', 'Séquelles de harcèlement', 'أثر التنمّر والمضايقة السابقة', null),
    _c('betrayal_trauma', ClinicalTrack.traumaStress, 'Relational Trust & Betrayal Injury', 'Traumatisme de trahison relationnelle', 'صدمة خيانة الثقة القريبة', null),
    _c('coercive_recovery', ClinicalTrack.traumaStress, 'Controlling Relationship Recovery', 'Reconstruction après emprise', 'التعافي من علاقة مسيطرة', null),
    _c('sudden_loss_shock', ClinicalTrack.traumaStress, 'Sudden Loss / Traumatic Grief', 'Choc de deuil brutal', 'صدمة الفقدان المفاجئ', null),
    _c('displacement_stress', ClinicalTrack.traumaStress, 'Migration / Uprooting Adaptation Stress', 'Stress de déracinement et exil', 'ضغط الاغتراب وتغيير الوطن', null),
    _c('workplace_mobbing', ClinicalTrack.traumaStress, 'Workplace Harassment Stress Recovery', 'Stress post-harcèlement professionnel', 'أثر ضغط أو تحرّش مهني', null),
    _c('hypervigilance_pattern', ClinicalTrack.traumaStress, 'Chronic Hypervigilance & Startle', 'Hypervigilance et sursaut', 'التيقّظ المفرط وسرعة الجفل', ConditionType.traumaDifficulties),
    _c('trauma_nightmares', ClinicalTrack.traumaStress, 'Distressing Stress Nightmares', 'Cauchemars post-traumatiques', 'كوابيس مرتبطة بالضغط الصدمي', null),
    _c('moral_injury', ClinicalTrack.traumaStress, 'Moral Injury & Values Conflict', 'Blessure morale', 'الألم الأخلاقي وتأنيب الضمير', null),
    _c('emotional_flashbacks', ClinicalTrack.traumaStress, 'Emotional Flashback Waves', 'Flashbacks émotionnels soudains', 'موجات استرجاع شعوري مفاجئة', ConditionType.complexPtsd),
    _c('threat_readiness_fatigue', ClinicalTrack.traumaStress, 'Nervous System Over-Alert Fatigue', 'Fatigue d’état d’alerte continu', 'إرهاق التأهّب الدائم للخطر', ConditionType.traumaDifficulties),

    // -------------------------------------------------------------------------
    // Track 6: Neurodevelopmental (ADHD / Autism / Executive Flow) (32)
    // -------------------------------------------------------------------------
    _c('adhd_combined', ClinicalTrack.neurodevelopmental, 'ADHD (Combined Presentation)', 'TDAH (forme mixte)', 'اضطراب تشتّت الانتباه وفرط الحركة', ConditionType.adhd, ['adhd', 'focus', 'تركيز']),
    _c('adhd_inattentive', ClinicalTrack.neurodevelopmental, 'ADHD (Predominantly Inattentive)', 'TDAH à prédominance inattentive', 'تشتّت الانتباه بدون فرط حركة', ConditionType.adhd),
    _c('adhd_hyperactive', ClinicalTrack.neurodevelopmental, 'ADHD (Hyperactive-Impulsive)', 'TDAH hyperactif-impulsif', 'فرط النشاط والاندفاعية', ConditionType.adhd),
    _c('late_id_adhd', ClinicalTrack.neurodevelopmental, 'Adult Late-Identified ADHD', 'TDAH reconnu à l’âge adulte', 'تشخيص متأخر لتشتت الانتباه لدى الكبار', ConditionType.adhd),
    _c('rsd', ClinicalTrack.neurodevelopmental, 'Rejection Sensitive Dysphoria (RSD)', 'Hypersensibilité au rejet (RSD)', 'الحساسية الشديدة للرفض أو النقد', null),
    _c('executive_dysfunction', ClinicalTrack.neurodevelopmental, 'Executive Dysfunction & Task Freeze', 'Dysfonction exécutive et blocage', 'صعوبة البدء والتنظيم (الشلل التنفيذي)', ConditionType.attentionDifficulties),
    _c('time_blindness', ClinicalTrack.neurodevelopmental, 'Time Blindness & Pacing Gaps', 'Cécité temporelle', 'صعوبة تقدير الوقت والمواعيد', null),
    _c('hyperfocus_crash', ClinicalTrack.neurodevelopmental, 'Hyperfocus & Post-Sprint Crash', 'Hyperfocus suivi d’épuisement', 'التركيز المفرط يتبعه إرهاق حاد', null),
    _c('autism_spectrum', ClinicalTrack.neurodevelopmental, 'Autism Spectrum Profile (ASD)', 'Trouble du spectre de l’autisme (TSA)', 'طيف التوحّد', ConditionType.autism, ['autism', 'توحد']),
    _c('autistic_masking', ClinicalTrack.neurodevelopmental, 'Social Masking Exhaustion', 'Fatigue de camouflage social', 'إرهاق التظاهر الاجتماعي (Masking)', ConditionType.autism),
    _c('autistic_burnout', ClinicalTrack.neurodevelopmental, 'Autistic / Sensory Burnout', 'Épuisement autistique / sensoriel', 'الإنهاك العصبي والحسي', ConditionType.autism),
    _c('audhd', ClinicalTrack.neurodevelopmental, 'AuDHD (Autism + ADHD Overlap)', 'Double profil TSA + TDAH', 'التداخل بين التوحّد وتشتّت الانتباه', ConditionType.adhd),
    _c('sensory_overload', ClinicalTrack.neurodevelopmental, 'Sensory Processing Overload (Sound/Light)', 'Surcharge sensorielle', 'الحساسية المفرطة للصوت والضوء واللمس', ConditionType.sensoryDifficulties),
    _c('misophonia', ClinicalTrack.neurodevelopmental, 'Misophonia (Trigger-Sound Distress)', 'Misophonie', 'الميزوفونيا (انزعاج حاد من أصوات معينة)', ConditionType.sensoryDifficulties),
    _c('auditory_processing', ClinicalTrack.neurodevelopmental, 'Auditory Filtering Fatigue', 'Fatigue de tri auditif', 'تعب فرز الأصوات في الأماكن المزدحمة', ConditionType.sensoryDifficulties),
    _c('tourette_syndrome', ClinicalTrack.neurodevelopmental, 'Tourette Syndrome', 'Syndrome de Gilles de la Tourette', 'متلازمة توريت', null),
    _c('motor_tics', ClinicalTrack.neurodevelopmental, 'Persistent Motor Tic Pattern', 'Tics moteurs persistants', 'حركات لاإرادية مستمرة (تشنجات حركية)', null),
    _c('vocal_tics', ClinicalTrack.neurodevelopmental, 'Persistent Vocal Tic Pattern', 'Tics vocaux persistants', 'أصوات لاإرادية متكررة', null),
    _c('dyslexia_fatigue', ClinicalTrack.neurodevelopmental, 'Dyslexia Reading / Study Fatigue', 'Fatigue liée à la dyslexie', 'إرهاق القراءة وعسر القراءة', null),
    _c('dyspraxia_dcd', ClinicalTrack.neurodevelopmental, 'Dyspraxia / Motor Planning Stress', 'Dyspraxie / trouble de coordination', 'صعوبة التناسق الحركي والتخطيط', null),
    _c('dyscalculia_load', ClinicalTrack.neurodevelopmental, 'Dyscalculia / Numerical Load Anxiety', 'Dyscalculie et stress chiffré', 'صعوبة التعامل مع الأرقام والحساب', null),
    _c('language_processing_fatigue', ClinicalTrack.neurodevelopmental, 'Word-Finding & Expressive Fatigue', 'Fatigue d’expression verbale', 'إرهاق التعبير واستحضار الكلمات', null),
    _c('cds_sluggish_tempo', ClinicalTrack.neurodevelopmental, 'Slow Cognitive Processing Tempo', 'Ralentissement du tempo attentif', 'بطء الإيقاع الذهني والتشتّت الحالم', ConditionType.attentionDifficulties),
    _c('high_intensity_gifted', ClinicalTrack.neurodevelopmental, 'Cognitive Overexcitability & Overthinking', 'Surexcitabilité intellectuelle', 'فرط التفكير والحساسية الفكرية', null),
    _c('alexithymia', ClinicalTrack.neurodevelopmental, 'Alexithymia (Hard-to-Name Feelings)', 'Alexithymie', 'صعوبة تمييز ووصف المشاعر', null),
    _c('pda_profile', ClinicalTrack.neurodevelopmental, 'Demand-Avoidance Overload Profile', 'Profil d’évitement des exigences', 'ضغط وتفادي الطلبات المتراكمة', null),
    _c('working_memory_drop', ClinicalTrack.neurodevelopmental, 'Short Working-Memory Slippage', 'Saturation de la mémoire de travail', 'تشبّع الذاكرة القريبة والنسيان السريع', ConditionType.attentionDifficulties),
    _c('transition_distress', ClinicalTrack.neurodevelopmental, 'Unexpected Schedule Shift Distress', 'Inconfort aux transitions imprévues', 'انزعاج عند تغيّر البرنامج فجأة', null),
    _c('social_cue_fatigue', ClinicalTrack.neurodevelopmental, 'Group Conversation Decoding Fatigue', 'Fatigue de décodage social', 'إرهاق متابعة الحوارات الجماعية', null),
    _c('stim_restlessness', ClinicalTrack.neurodevelopmental, 'Internal Motor Restlessness', 'Besoin de mouvement / agitation interne', 'تململ وحاجة مستمرة للحركة', null),
    _c('delayed_circadian_adhd', ClinicalTrack.neurodevelopmental, 'Neurodivergent Night-Owl Clock', 'Rythme veille-sommeil décalé TDAH', 'تأخر ساعة النوم المرافق لتشتت الانتباه', null),
    _c('dopamine_boredom_drop', ClinicalTrack.neurodevelopmental, 'Under-Stimulation Fog / Fatigue', 'Baisse brutale par sous-stimulation', 'فتور سريع عند غياب التحفيز', null),

    // -------------------------------------------------------------------------
    // Track 7: Sleep & Circadian Rhythm (24)
    // -------------------------------------------------------------------------
    _c('chronic_insomnia', ClinicalTrack.sleepWake, 'Chronic Insomnia Disorder', 'Insomnie chronique', 'الأرق المزمن', ConditionType.sleepDisorders, ['insomnia', 'أرق', 'نوم']),
    _c('sleep_onset_insomnia', ClinicalTrack.sleepWake, 'Difficulty Falling Asleep', 'Insomnie d’endormissement', 'صعوبة الدخول في النوم', ConditionType.sleepDifficulties),
    _c('sleep_maintenance_insomnia', ClinicalTrack.sleepWake, 'Frequent Middle-of-Night Waking', 'Réveils nocturnes répétés', 'تقطّع النوم والاستيقاظ المتكرر', ConditionType.sleepDifficulties),
    _c('early_morning_waking', ClinicalTrack.sleepWake, 'Unwanted Early-Morning Awakening', 'Réveil matinal précoce', 'الاستيقاظ المبكر قبل وقت النوم الكافي', ConditionType.sleepDifficulties),
    _c('paradoxical_insomnia', ClinicalTrack.sleepWake, 'Light / Unperceived Sleep Feeling', 'Insomnie paradoxale', 'إحساس بعدم النوم رغم الراحة الخفيفة', ConditionType.sleepDisorders),
    _c('hypersomnolence', ClinicalTrack.sleepWake, 'Hypersomnolence / Excessive Daytime Sleepiness', 'Hypersomnie', 'فرط النوم والنعاس النهاري', ConditionType.sleepDisorders),
    _c('non_restorative_sleep', ClinicalTrack.sleepWake, 'Non-Restorative Unrefreshing Sleep', 'Sommeil non réparateur', 'نوم غير مريح أو ثقيل عند الاستيقاظ', ConditionType.sleepDifficulties),
    _c('dswps_night_owl', ClinicalTrack.sleepWake, 'Delayed Sleep-Wake Phase (DSWPD)', 'Syndrome de retard de phase', 'متلازمة تأخّر طور النوم', ConditionType.sleepDisorders),
    _c('aswps_early_bird', ClinicalTrack.sleepWake, 'Advanced Sleep-Wake Phase', 'Syndrome d’avance de phase', 'تقدّم طور النوم المبكر جداً', ConditionType.sleepDisorders),
    _c('irregular_sleep_wake', ClinicalTrack.sleepWake, 'Irregular / Fragmented Sleep Pattern', 'Rythme veille-sommeil irrégulier', 'اضطراب وعدم انتظام أوقات النوم', ConditionType.sleepDifficulties),
    _c('non_24_sleep', ClinicalTrack.sleepWake, 'Free-Running Non-24h Sleep Rhythm', 'Rythme circadien libre (>24h)', 'انزياح ساعة النوم المستمر', ConditionType.sleepDisorders),
    _c('shift_work_sleep', ClinicalTrack.sleepWake, 'Shift-Work Circadian Strain', 'Trouble du travail posté / nuit', 'إرهاق النوم بسبب المناوبات الليلية', ConditionType.sleepDifficulties),
    _c('jet_lag_strain', ClinicalTrack.sleepWake, 'Travel & Time-Zone Rhythm Recovery', 'Décalage horaire persistant', 'اضطراب النوم بعد السفر وتغير التوقيت', null),
    _c('nightmare_disorder', ClinicalTrack.sleepWake, 'Recurrent Distressing Nightmares', 'Trouble des cauchemars', 'اضطراب الكوابيس المتكررة', ConditionType.sleepDisorders),
    _c('sleep_paralysis', ClinicalTrack.sleepWake, 'Recurrent Sleep Paralysis', 'Paralysie du sommeil', 'شلل النوم المتكرر (الجاثوم)', null, ['jathoum', 'جاثوم']),
    _c('hypnagogic_sensations', ClinicalTrack.sleepWake, 'Sleep-Transition Sensory Surges', 'Phénomènes hypnagogiques', 'تهيؤات لحظة الدخول أو الخروج من النوم', null),
    _c('confusional_arousals', ClinicalTrack.sleepWake, 'Confusional Morning Waking', 'Éveils confusionnels', 'ارتباك وتشويش عند الاستيقاظ المفاجئ', null),
    _c('sleepwalking_parasomnia', ClinicalTrack.sleepWake, 'Sleepwalking / Parasomnia Events', 'Somnambulisme', 'المشي أو التحدث أثناء النوم', null),
    _c('night_terrors', ClinicalTrack.sleepWake, 'Sleep Terror Arousals', 'Terreurs nocturnes', 'فزع النوم الليلي', null),
    _c('restless_legs', ClinicalTrack.sleepWake, 'Restless Legs Discomfort (RLS)', 'Syndrome des jambes sans repos', 'تململ الساقين ليلاً', null),
    _c('apnea_mood_overlap', ClinicalTrack.sleepWake, 'Sleep-Breathing Fatigue Overlap', 'Fatigue liée aux apnées du sommeil', 'إرهاق ومزاج متعب مرافق لتوقف التنفس الليلي', null),
    _c('conditioned_bed_arousal', ClinicalTrack.sleepWake, 'Bedtime Alertness Conditioning', 'Hyper-éveil au moment du coucher', 'تيقّظ الذهن بمجرد الاستلقاء للنوم', ConditionType.sleepDifficulties),
    _c('sunday_night_insomnia', ClinicalTrack.sleepWake, 'Pre-Workweek Anticipatory Insomnia', 'Insomnie d’anticipation hebdomadaire', 'أرق التفكير قبل بداية الأسبوع', ConditionType.sleepDifficulties),
    _c('napping_cycle_drift', ClinicalTrack.sleepWake, 'Daytime Nap & Night Drift Loop', 'Décalage sieste-nuit', 'تداخل القيلولة مع نوم الليل', null),

    // -------------------------------------------------------------------------
    // Track 8: Perceptions & Reality Grounding (24)
    // -------------------------------------------------------------------------
    _c('schizophrenia_support', ClinicalTrack.perceptualGrounding, 'Schizophrenia Recovery Support', 'Soutien dans la schizophrénie', 'متابعة التوازن في طيف الفصام', ConditionType.schizophrenia, ['schizo', 'فصام']),
    _c('schizoaffective_dep', ClinicalTrack.perceptualGrounding, 'Schizoaffective (Depressive Type)', 'Trouble schizo-affectif (dépressif)', 'الفصامي العاطفي الاكتئابي', ConditionType.psychosisSpectrum),
    _c('brief_psychotic', ClinicalTrack.perceptualGrounding, 'Post-Acute Brief Perceptual Episode', 'Récupération post-épisode bref', 'التعافي بعد نوبة إدراكية وجيزة', ConditionType.psychosisSpectrum),
    _c('delusional_experience', ClinicalTrack.perceptualGrounding, 'Persistent Fixed Beliefs / Worry', 'Idées fixes envahissantes', 'أفكار ثابتة مقلقة يصعب تجاهلها', ConditionType.delusions),
    _c('schizophreniform', ClinicalTrack.perceptualGrounding, 'Schizophreniform Recovery Period', 'Suivi post-trouble schizophréniforme', 'فترة المتابعة والتثبيت الإدراكي', ConditionType.psychosisSpectrum),
    _c('schizotypal_profile', ClinicalTrack.perceptualGrounding, 'Schizotypal Perceptual & Social Sensitivity', 'Sensibilité schizotypique', 'حساسية إدراكية واجتماعية خاصة', ConditionType.otherPerceptual),
    _c('attenuated_perceptual', ClinicalTrack.perceptualGrounding, 'Attenuated Sensory / Belief Shifts', 'Signaux perceptuels atténués', 'تغيّرات حسية أو فكرية أولية', ConditionType.otherPerceptual),
    _c('auditory_experiences', ClinicalTrack.perceptualGrounding, 'Hearing Voices / Auditory Experiences', 'Expériences auditives / voix', 'سماع أصوات أو تجارب سمعية خاصة', ConditionType.hallucinations),
    _c('visual_experiences', ClinicalTrack.perceptualGrounding, 'Visual Perceptual Shifts / Shadows', 'Perceptions visuelles inhabituelles', 'رؤية ظلال أو تصوّرات بصرية غير معتادة', ConditionType.hallucinations),
    _c('tactile_sensory_shifts', ClinicalTrack.perceptualGrounding, 'Unusual Skin / Body Sensations', 'Sensations tactiles inhabituelles', 'إحساسات جلدية أو جسدية غير مفسّرة', ConditionType.otherPerceptual),
    _c('olfactory_shifts', ClinicalTrack.perceptualGrounding, 'Unexplained Scent / Taste Experiences', 'Perceptions olfactives inhabituelles', 'روائح أو أذواق غير موجودة بالواقع', ConditionType.otherPerceptual),
    _c('ideas_of_reference', ClinicalTrack.perceptualGrounding, 'Over-Meaningful Coincidence Feelings', 'Idées de référence / signes personnels', 'إحساس بأن الإشارات والصدف موجهة لي', ConditionType.delusions),
    _c('paranoia_mistrust_waves', ClinicalTrack.perceptualGrounding, 'Intense Guardedness & Suspiciousness', 'Méfiance intense et sentiment de menace', 'شعور قوي بالمراقبة أو عدم الأمان', ConditionType.delusions),
    _c('thought_broadcast_distress', ClinicalTrack.perceptualGrounding, 'Thought Exposure / Privacy Worry', 'Sentiment d’exposition des pensées', 'القلق من انكشاف الأفكار للآخرين', ConditionType.otherPerceptual),
    _c('negative_drive_flatness', ClinicalTrack.perceptualGrounding, 'Low Motivation & Emotional Quietness', 'Apathie / baisse d’élan post-épisode', 'فتور الدافعية والانزواء الصامت', ConditionType.psychosisSpectrum),
    _c('post_episode_fog', ClinicalTrack.perceptualGrounding, 'Post-Episode Cognitive Recovery', 'Récupération cognitive post-crise', 'استرجاع التركيز بعد فترة اضطراب', ConditionType.psychosisSpectrum),
    _c('reality_checking_support', ClinicalTrack.perceptualGrounding, 'Calm Reality-Anchor Practice', 'Repères simples d’ancrage au réel', 'البحث عن مؤشرات الهدوء والواقع', ConditionType.otherPerceptual),
    _c('sleep_fragility_psychosis', ClinicalTrack.perceptualGrounding, 'Sleep Loss Perceptual Sensitivity', 'Sensibilité accrue si sommeil court', 'حساسية الإدراك عند نقص النوم', ConditionType.psychosisSpectrum),
    _c('crowds_perceptual_strain', ClinicalTrack.perceptualGrounding, 'Crowded-Environment Overwhelm', 'Surcharge perceptive en lieu bruyant', 'اضطراب الحواس في الأماكن الصاخبة', null),
    _c('medication_trust_support', ClinicalTrack.perceptualGrounding, 'Steady Care Plan & Routine Check', 'Suivi régulier du plan de soin', 'مرافقة الانتظام الهادئ في المتابعة', null),
    _c('social_trust_rebuild', ClinicalTrack.perceptualGrounding, 'Gentle Social Trust Rebuilding', 'Reprise douce de confiance sociale', 'استعادة الثقة والتواصل تدريجياً', null),
    _c('stress_perceptual_flare', ClinicalTrack.perceptualGrounding, 'High-Stress Perceptual Flare', 'Sensibilité perceptive sous stress', 'تأثر الإدراك تحت الضغط المرتفع', null),
    _c('late_night_thought_drift', ClinicalTrack.perceptualGrounding, 'Late-Night Sensory Drift', 'Dérive sensorielle nocturne', 'تشوّش الحواس عند السهر الطويل', null),
    _c('other_perceptual', ClinicalTrack.perceptualGrounding, 'Other Perceptual Experience', 'Autre expérience perceptive', 'تجربة إدراكية أخرى', ConditionType.otherPerceptual),

    // -------------------------------------------------------------------------
    // Track 9: Emotion Waves & Relationships (26)
    // -------------------------------------------------------------------------
    _c('bpd_traits', ClinicalTrack.emotionRegulation, 'Borderline / Intense Emotion Waves (BPD)', 'Trouble borderline / hypersensibilité', 'اضطراب الشخصية الحدية / الموجات القوية', ConditionType.personalityDisorders, ['bpd', 'eupd', 'حدية']),
    _c('abandonment_panic', ClinicalTrack.emotionRegulation, 'Intense Fear of Abandonment', 'Peur intense de l’abandon', 'الخوف الشديد من الهجر أو التخلّي', ConditionType.personalityDifficulties),
    _c('splitting_black_white', ClinicalTrack.emotionRegulation, 'Sudden Trust-to-Hurt Perception Swings', 'Bascule rapide tout-bon / tout-mauvais', 'تأرجح حاد في النظرة بين التقرّب والابتعاد', ConditionType.personalityDifficulties),
    _c('chronic_emptiness', ClinicalTrack.emotionRegulation, 'Persistent Inner Emptiness', 'Sentiment chronique de vide', 'فراغ داخلي متواصل', ConditionType.personalityDifficulties),
    _c('identity_instability', ClinicalTrack.emotionRegulation, 'Shifting Self-Image & Direction', 'Image de soi instable', 'تغيّر الإحساس بالذات والأهداف', null),
    _c('impulsive_coping_waves', ClinicalTrack.emotionRegulation, 'Impulsive Emotion-Escape Urges', 'Réactions impulsives sous émotion vive', 'ردود فعل متسرعة وقت الغضب أو الألم', null),
    _c('ied_anger', ClinicalTrack.emotionRegulation, 'Sudden Anger Surges (IED Pattern)', 'Accès explosifs intermittents', 'نوبات غضب حادة متقطعة', null),
    _c('avoidant_pd', ClinicalTrack.emotionRegulation, 'Avoidant Interpersonal Pattern', 'Personnalité évitante / crainte de critique', 'تجنّب العلاقات خوفاً من النقد والرفض', ConditionType.personalityDisorders),
    _c('dependent_pattern', ClinicalTrack.emotionRegulation, 'Strong Dependency in Decisions', 'Besoin fort d’appui pour décider', 'اعتمادية عالية في القرارات اليومية', ConditionType.personalityDifficulties),
    _c('ocpd_rigidity', ClinicalTrack.emotionRegulation, 'Rigid Perfectionism & Control (OCPD)', 'Personnalité obsessionnelle-compulsive', 'التصلّب الكمالي وضغط السيطرة', ConditionType.personalityDisorders),
    _c('paranoid_personality', ClinicalTrack.emotionRegulation, 'Chronic Interpersonal Guardedness', 'Méfiance relationnelle durable', 'حذر وتوقّع دائم للأذى في العلاقات', ConditionType.personalityDisorders),
    _c('schizoid_solitude', ClinicalTrack.emotionRegulation, 'Deep Solitude & Emotional Distance', 'Détachement relationnel profond', 'تفضيل العزلة وقلة التفاعل العاطفي', null),
    _c('approval_exhaustion', ClinicalTrack.emotionRegulation, 'Approval-Seeking & Visibility Strain', 'Épuisement par quête d’approbation', 'إرهاق البحث الدائم عن القبول', null),
    _c('shame_vulnerability', ClinicalTrack.emotionRegulation, 'Sharp Shame & Criticism Sensitivity', 'Vulnérabilité aiguë à la honte', 'جرح الكرامة والحساسية الحادة للنقد', null),
    _c('codependency', ClinicalTrack.emotionRegulation, 'Over-Caretaking / Codependency Loops', 'Sur-adaptation et codépendance', 'ذوبان الحدود وفرط التضحية للغير', ConditionType.personalityDifficulties),
    _c('fawn_people_pleasing', ClinicalTrack.emotionRegulation, 'Chronic People-Pleasing Response', 'Soumission affective par peur du conflit', 'إرضاء الآخرين على حساب النفس', null),
    _c('boundary_guilt', ClinicalTrack.emotionRegulation, 'Guilt After Setting Personal Boundaries', 'Culpabilité à poser des limites', 'تأنيب الضمير عند قول "لا"', null),
    _c('conflict_freeze', ClinicalTrack.emotionRegulation, 'Shutdown / Freeze During Arguments', 'Sidération en situation de conflit', 'انجماد وصمت ثقيل أثناء الخلاف', null),
    _c('shame_spirals', ClinicalTrack.emotionRegulation, 'Intense Self-Disgust / Shame Spirals', 'Spirales intenses de honte', 'دوامات الخجل وجلد الذات القاسي', null),
    _c('jealousy_loops', ClinicalTrack.emotionRegulation, 'Relational Jealousy Rumination', 'Jalousie envahissante / comparaison', 'غيرة مؤلمة ومقارنات متكررة', null),
    _c('empathic_distress', ClinicalTrack.emotionRegulation, 'Absorbing Others’ Pain Overwhelm', 'Surcharge par empathie douloureuse', 'التأثر الزائد بمشاكل الآخرين', null),
    _c('rapid_affective_lability', ClinicalTrack.emotionRegulation, 'Hour-to-Hour Affective Swings', 'Labilité émotionnelle intra-journalière', 'تبدّل حاد للمشاعر في نفس اليوم', ConditionType.moodInstability),
    _c('post_argument_spiral', ClinicalTrack.emotionRegulation, 'Post-Conflict Escalation Recovery', 'Temps long à redescendre après conflit', 'صعوبة التهدئة بعد شجار عاطفي', null),
    _c('passive_resentment', ClinicalTrack.emotionRegulation, 'Silent Resentment Accumulation', 'Accumulation de rancœur non dite', 'تراكم الضيق المكتوم تجاه القريبين', null),
    _c('attachment_anxious_loop', ClinicalTrack.emotionRegulation, 'Anxious Attachment Waves', 'Attachement anxieux / alerte de lien', 'القلق المستمر من فتور العلاقات', null),
    _c('other_emotion_reg', ClinicalTrack.emotionRegulation, 'Other Emotion Regulation Challenge', 'Autre défi de régulation affective', 'تحدٍ آخر في تنظيم الانفعالات', ConditionType.personalityDifficulties),

    // -------------------------------------------------------------------------
    // Track 10: Dissociation & Body Sensations (22)
    // -------------------------------------------------------------------------
    _c('dpdr', ClinicalTrack.dissociativeSomatic, 'Depersonalization / Derealization (DPDR)', 'Dépersonnalisation / Déréalisation', 'اختلال الأنية والغربة عن الواقع', ConditionType.dissociativeDisorders, ['dpdr', 'unreal', 'fog', 'تباعد']),
    _c('dreamlike_fog', ClinicalTrack.dissociativeSomatic, 'Persistent Dreamlike / Glass-Wall Fog', 'Brouillard / sensation de vitre', 'إحساس بالعيش خلف زجاج أو في حلم', ConditionType.dissociativeExperiences),
    _c('dissociative_amnesia', ClinicalTrack.dissociativeSomatic, 'Stress-Related Time & Memory Gaps', 'Amnésie dissociative sous stress', 'فجوات ذاكرة عند الضغط الشديد', ConditionType.dissociativeDisorders),
    _c('fugue_history', ClinicalTrack.dissociativeSomatic, 'Dissociative Wandering / Fugue History', 'Antécédents de fugue dissociative', 'تاريخ انقطاع مكاني أو شرود حاد', ConditionType.dissociativeDisorders),
    _c('structural_dissociation', ClinicalTrack.dissociativeSomatic, 'Compartmentalized Self / Parts Experience', 'Dissociation structurelle / compartimentée', 'تجزّؤ الإحساس الداخلي عند التوتر', ConditionType.dissociativeDisorders),
    _c('did_osdd_support', ClinicalTrack.dissociativeSomatic, 'Complex Dissociative (DID / OSDD) Support', 'Soutien dissociation complexe', 'مرافقة حالات التفارق المركّب', ConditionType.dissociativeDisorders),
    _c('dorsal_freeze', ClinicalTrack.dissociativeSomatic, 'Freeze / Numb Collapse Response', 'Figement / anesthésie émotionnelle', 'انجماد أو تبلّد الجسد وقت الضغط', ConditionType.dissociativeExperiences),
    _c('somatic_symptom_disorder', ClinicalTrack.dissociativeSomatic, 'Somatic Symptom & Physical Distress', 'Trouble à symptomatologie somatique', 'التركيز المؤلم على الأعراض الجسدية', null),
    _c('fnd_functional', ClinicalTrack.dissociativeSomatic, 'Functional Neurological Stress Overlap', 'Symptômes fonctionnels (TNF)', 'أعراض عصبية وظيفية مرتبطة بالتوتر', null),
    _c('pnes_stress_link', ClinicalTrack.dissociativeSomatic, 'Stress-Linked Non-Epileptic Spells', 'Crises fonctionnelles liées au stress', 'نوبات توتر وظيفية غير صرعية', null),
    _c('conversion_fatigue', ClinicalTrack.dissociativeSomatic, 'Sudden Weakness / Functional Voice Loss', 'Fatigue ou faiblesse de conversion', 'ضعف جسدي أو بحة صوتية تحت الصدمة', null),
    _c('central_sensitization', ClinicalTrack.dissociativeSomatic, 'Chronic Pain & Stress Amplification', 'Sensibilisation centrale et douleur', 'ألم مزمن يتضاعف مع الإجهاد', null),
    _c('fibromyalgia_overlap', ClinicalTrack.dissociativeSomatic, 'Fibromyalgia Mood & Fog Overlap', 'Fibromyalgie (douleur, fatigue, brouillard)', 'فيبروميالجيا وتعب الجسد مع الضبابية', null),
    _c('tension_migraine_loop', ClinicalTrack.dissociativeSomatic, 'Stress Headaches / Tension Migraines', 'Céphalées de tension et migraines', 'صداع التوتر والشقيقة المرتبط بالإجهاد', null),
    _c('ibs_gut_brain', ClinicalTrack.dissociativeSomatic, 'Gut-Brain Stress Sensitivity (IBS)', 'Sensibilité digestive axe intestin-cerveau', 'تشنّج القولون العصبي وتوتر المعدة', null),
    _c('dysautonomia_pots_overlap', ClinicalTrack.dissociativeSomatic, 'Autonomic / POTS Heart-Rate Sensitivity', 'Sensibilité autonome / tachycardie debout', 'اضطراب التوازن اللاإرادي وخفقان الوقوف', null),
    _c('tinnitus_distress', ClinicalTrack.dissociativeSomatic, 'Tinnitus Focus & Sleep Distress', 'Acouphènes et surcharge attentionnelle', 'طنين الأذن المؤثر على الهدوء والنوم', null),
    _c('pppd_dizziness', ClinicalTrack.dissociativeSomatic, 'Persistent Dizziness (PPPD) Stress Loop', 'Vertiges persistants perceptifs', 'دوخة مستمرة مرتبطة بالتوتر الحسي', null),
    _c('tmj_clenching', ClinicalTrack.dissociativeSomatic, 'Jaw Clenching / Muscle Armoring', 'Serrage des mâchoires et crispation', 'صرّ الأسنان وتشنج الرقبة والكتفين', null),
    _c('air_hunger_loop', ClinicalTrack.dissociativeSomatic, 'Shallow Breath & Air-Hunger Awareness', 'Sensation de manque d’air somatique', 'إحساس ضيق النفس وتنفس سطحي', null),
    _c('numbness_paresthesia', ClinicalTrack.dissociativeSomatic, 'Stress Tingling & Limb Heaviness', 'Fourmillements et lourdeur nerveuse', 'تنميل الأطراف وخدر التوتر', null),
    _c('other_dissociative', ClinicalTrack.dissociativeSomatic, 'Other Dissociative or Body Experience', 'Autre vécu dissociatif ou corporel', 'تجربة تباعد أو جسدية أخرى', ConditionType.dissociativeExperiences),

    // -------------------------------------------------------------------------
    // Track 11: Urges, Eating Peace & Habit Recovery (24 — ZERO diet/calories!)
    // -------------------------------------------------------------------------
    _c('binge_urge_recovery', ClinicalTrack.urgeHabitRecovery, 'Binge Urge & Emotional Relief Recovery', 'Récupération face aux impulsions compulsives', 'التعافي من نوبات الأكل الانفعالي', ConditionType.eatingDisorders, ['binge', 'eating']),
    _c('restrictive_control_anxiety', ClinicalTrack.urgeHabitRecovery, 'Control & Restraint Anxiety Recovery', 'Apaisement de l’anxiété de contrôle alimentaire', 'تهدئة القلق والتقييد الصارم حول الأكل', ConditionType.eatingDisorders),
    _c('compensatory_urge_support', ClinicalTrack.urgeHabitRecovery, 'Post-Meal Distress & Urge Support', 'Soutien face à la détresse après les repas', 'مساندة الهدوء بعد الوجبات ودون قسوة', ConditionType.eatingDisorders),
    _c('arfid_sensory', ClinicalTrack.urgeHabitRecovery, 'Sensory Food Texture & Fear (ARFID)', 'Sélectivité sensorielle alimentaire (ARFID)', 'النفور الحسي أو الخوف من قوام الطعام', ConditionType.eatingDifficulties),
    _c('night_emotional_urges', ClinicalTrack.urgeHabitRecovery, 'Late-Night Emotional Soothing Urges', 'Impulsions émotionnelles nocturnes', 'موجات التهدئة بالأكل في وقت متأخر', ConditionType.eatingDifficulties),
    _c('rigid_rule_anxiety', ClinicalTrack.urgeHabitRecovery, 'Rigid-Rule Anxiety Around Meals', 'Anxiété liée aux règles rigides', 'توتر القواعد الصارمة غير المرنة', ConditionType.eatingDifficulties),
    _c('body_checking_urges', ClinicalTrack.urgeHabitRecovery, 'Repetitive Checking & Self-Criticism', 'Vérifications corporelles répétées', 'تفحّص المظهر والنقد الجسدي المتكرر', ConditionType.eatingDifficulties),
    _c('pica_rumination_support', ClinicalTrack.urgeHabitRecovery, 'Unusual Ingestion / Regurgitation Support', 'Suivi de conduites atypiques', 'متابعة عادات الأكل غير المعتادة', ConditionType.eatingDisorders),
    _c('gambling_recovery', ClinicalTrack.urgeHabitRecovery, 'Gambling / Risk-Chase Urge Recovery', 'Récupération jeu pathologique', 'التعافي من دافع المقامرة والمجازفة', null),
    _c('gaming_escape_urge', ClinicalTrack.urgeHabitRecovery, 'Excessive Gaming Escape Loops', 'Échappatoire compulsive par le jeu vidéo', 'الهروب المفرط إلى الألعاب الإلكترونية', null),
    _c('scrolling_dopamine_loop', ClinicalTrack.urgeHabitRecovery, 'Compulsive Scrolling & Screen Loops', 'Défilement compulsif nocturne', 'التصفّح القهري المستمر على الهاتف', null),
    _c('compulsive_shopping', ClinicalTrack.urgeHabitRecovery, 'Compulsive Spending / Buying Relief', 'Achats compulsifs pour calmer un vide', 'الشراء المندفع لتخفيف التوتر', null),
    _c('compulsive_sexual_habit', ClinicalTrack.urgeHabitRecovery, 'Compulsive Habit Cycle Recovery', 'Gestion d’habitudes compulsives intimes', 'تنظيم وضبط العادات القهرية الخاصة', null),
    _c('workaholism_compulsion', ClinicalTrack.urgeHabitRecovery, 'Compulsive Overworking / Inability to Rest', 'Travail compulsif sans repos', 'إدمان العمل والعجز عن التوقف للراحة', null),
    _c('alcohol_urge_support', ClinicalTrack.urgeHabitRecovery, 'Alcohol Moderation / Sobriety Cravings', 'Soutien sobriété et envies d’alcool', 'مساندة التعافي ومقاومة دافع الكحول', null, ['alcohol', 'sobriety']),
    _c('nicotine_craving', ClinicalTrack.urgeHabitRecovery, 'Nicotine / Smoking / Vaping Urges', 'Gestion des envies de tabac ou vape', 'متابعة موجات الرغبة في التدخين', null),
    _c('caffeine_crash_loop', ClinicalTrack.urgeHabitRecovery, 'Caffeine Overuse & Anxiety Swing', 'Excès de caféine et rebond anxieux', 'إفراط الكافيين وتذبذب القلق', null),
    _c('cannabis_urge_mood', ClinicalTrack.urgeHabitRecovery, 'Cannabis Dependence & Mood Recovery', 'Soutien sevrage cannabis et humeur', 'مساندة تقليل الحشيش واستقرار المزاج', null),
    _c('sedative_taper_support', ClinicalTrack.urgeHabitRecovery, 'Sleep/Calm Medication Taper Stress', 'Accompagnement de sevrage suivi médicalement', 'مرافقة قلق تخفيض المهدئات بإشراف طبي', null),
    _c('stimulant_crash_recovery', ClinicalTrack.urgeHabitRecovery, 'Stimulant / Energy-Aid Rebound Fatigue', 'Rebond de fatigue post-stimulants', 'إرهاق ما بعد المنشطات', null),
    _c('paws_mood_waves', ClinicalTrack.urgeHabitRecovery, 'Post-Adjustment Recovery Mood Waves', 'Vagues émotionnelles post-arrêt', 'موجات المزاج بعد التوقف عن عادة', null),
    _c('urge_surfing_practice', ClinicalTrack.urgeHabitRecovery, 'General Impulse & Craving Wave Support', 'Traversée calme des pics d’envie', 'مرافقة ركوب موجة الدافع دون اندفاع', null),
    _c('recovery_routine_guard', ClinicalTrack.urgeHabitRecovery, 'Daily Recovery Stability Support', 'Protection des appuis de stabilité', 'حماية خطوات التعافي والاستقرار اليومي', null),
    _c('habit_reversal_support', ClinicalTrack.urgeHabitRecovery, 'Habit Reversal & Trigger Pause', 'Remplacement bienveillant d’habitude', 'تبديل العادات المتكررة بهدوء', null),

    // -------------------------------------------------------------------------
    // Track 12: General Balance & Still Exploring (22)
    // -------------------------------------------------------------------------
    _c('general_stress', ClinicalTrack.generalWellness, 'Everyday Stress & Load Management', 'Gestion du stress quotidien', 'إدارة ضغوط الحياة اليومية', ConditionType.other),
    _c('academic_exam_stress', ClinicalTrack.generalWellness, 'Student & Exam Preparation Stress', 'Stress des études et concours', 'ضغط الدراسة والمناظرات والامتحانات', ConditionType.other),
    _c('thesis_phd_strain', ClinicalTrack.generalWellness, 'Thesis / Research Isolation Strain', 'Pression de thèse et recherche', 'إرهاق البحث العلمي وكتابة الأطروحة', ConditionType.other),
    _c('career_transition', ClinicalTrack.generalWellness, 'Career Change & Direction Doubt', 'Transition professionnelle', 'قلق التحوّل المهني وتغيير المسار', ConditionType.other),
    _c('financial_uncertainty', ClinicalTrack.generalWellness, 'Unemployment or Financial Pressure', 'Pression financière ou recherche d’emploi', 'ضغط البطالة والالتزامات المادية', ConditionType.other),
    _c('new_parent_balance', ClinicalTrack.generalWellness, 'New Parent Adjustment & Exhaustion', 'Adaptation à la parentalité', 'التكيّف وإرهاق تربية الأبناء', ConditionType.other),
    _c('family_caregiving', ClinicalTrack.generalWellness, 'Family Caregiving Emotional Load', 'Charge d’aidant familial', 'حمل العناية بأحد أفراد العائلة', ConditionType.other),
    _c('relationship_breakup', ClinicalTrack.generalWellness, 'Breakup or Divorce Recovery', 'Séparation ou transition de couple', 'التعافي بعد انفصال أو طلاق', ConditionType.other),
    _c('expat_homesickness', ClinicalTrack.generalWellness, 'Living Abroad & Homesickness', 'Expatriation et mal du pays', 'الغربة والحنين للعائلة والبلاد', ConditionType.other),
    _c('social_loneliness', ClinicalTrack.generalWellness, 'Social Loneliness & Connection', 'Solitude sociale et besoin de lien', 'الوحدة والحاجة إلى الونس والتواصل', ConditionType.other),
    _c('imposter_syndrome', ClinicalTrack.generalWellness, 'Imposter Syndrome & Self-Doubt', 'Syndrome de l’imposteur', 'شعور عدم الاستحقاق والشك في الكفاءة', ConditionType.other),
    _c('creative_block', ClinicalTrack.generalWellness, 'Creative Exhaustion & Self-Criticism', 'Blocage créatif et doute de soi', 'الجمود الإبداعي ونقد الذات', ConditionType.other),
    _c('existential_questioning', ClinicalTrack.generalWellness, 'Life Meaning & Purpose Reflection', 'Questionnement de sens et valeurs', 'البحث عن المعنى ووضوح الوجهة', ConditionType.other),
    _c('normal_grief', ClinicalTrack.generalWellness, 'Grief & Loss Processing', 'Traversée d’un deuil', 'مساندة حزن فقدان عزيز', ConditionType.other),
    _c('sleep_rebuild', ClinicalTrack.generalWellness, 'Gentle Sleep Hygiene Rebuild', 'Recalage doux du rythme de sommeil', 'إعادة تنظيم مواعيد النوم بهدوء', ConditionType.sleepDifficulties),
    _c('screen_fatigue', ClinicalTrack.generalWellness, 'Digital Fatigue & Over-News Stress', 'Fatigue numérique et surcharge d’écrans', 'إرهاق الشاشات ومتابعة الأخبار', ConditionType.other),
    _c('hsp_sensitivity', ClinicalTrack.generalWellness, 'High Emotional Sensitivity (HSP)', 'Hypersensibilité émotionnelle', 'الحساسية العاطفية العالية', ConditionType.other),
    _c('identity_exploration', ClinicalTrack.generalWellness, 'Personal Growth & Self-Understanding', 'Connaissance de soi', 'فهم الذات والنمو الشخصي', ConditionType.stillExploring),
    _c('mindful_habit', ClinicalTrack.generalWellness, 'Building a Calm Daily Check-In Habit', 'Installer un rituel quotidien calme', 'بناء عادة يومية هادئة للاطمئنان', ConditionType.stillExploring),
    _c('still_exploring', ClinicalTrack.generalWellness, 'Still Exploring What Fits Me', 'Encore en exploration', 'مازلت أستكشف ما يناسبني', ConditionType.stillExploring),
    _c('prefer_not_specify', ClinicalTrack.generalWellness, 'Prefer Not to Specify Right Now', 'Je préfère ne pas préciser', 'أفضّل عدم التحديد حالياً', ConditionType.preferNotToSpecify),
    _c('doctor_prep_general', ClinicalTrack.generalWellness, 'Preparing Notes for a Doctor Visit', 'Préparer mes repères pour une visite médicale', 'تنظيم ملاحظاتي للزيارة الطبية', ConditionType.other),
  ];

  static final Map<String, ClinicalConditionItem> _byId = {
    for (final item in all) item.id: item,
  };

  static ClinicalConditionItem? byId(String id) => _byId[id.trim()];

  static List<ClinicalConditionItem> byTrack(ClinicalTrack track) =>
      all.where((e) => e.track == track).toList(growable: false);

  static List<ClinicalConditionItem> search(String query) {
    final q = query.trim();
    if (q.isEmpty) return all;
    return all.where((e) => e.matches(q)).toList(growable: false);
  }

  /// Resolves every active [ClinicalTrack] from structured IDs, tracks,
  /// legacy 37-enum entries, and onboarding focus areas.
  static Set<ClinicalTrack> resolveTracks(PsychologicalProfileModel? profile) {
    final tracks = <ClinicalTrack>{};
    if (profile == null) {
      tracks.add(ClinicalTrack.generalWellness);
      return tracks;
    }

    for (final rawTrack in profile.selectedTrackIds) {
      final parsed = ClinicalTrack.tryParse(rawTrack);
      if (parsed != null) tracks.add(parsed);
    }

    for (final id in profile.selectedConditionIds) {
      final item = byId(id);
      if (item != null) tracks.add(item.track);
    }

    for (final entry in profile.conditions) {
      tracks.add(ClinicalTrack.fromLegacyCondition(entry.condition));
    }

    // Fallback inference from lightweight onboarding focus areas
    // (skip 'sleep' -> handled smoothly by AppPersonalizationPlan.prioritizeSleepPulse)
    if (tracks.isEmpty) {
      if (profile.focusAreas.contains('overthinking')) {
        tracks.add(ClinicalTrack.obsessiveCompulsive);
      } else if (profile.focusAreas.contains('stress')) {
        tracks.add(ClinicalTrack.anxietyPanic);
      }
    }

    if (tracks.isEmpty) {
      tracks.add(ClinicalTrack.generalWellness);
    }
    return tracks;
  }
}
