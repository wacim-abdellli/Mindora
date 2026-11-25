import '../../../app/localization/app_strings.dart';
import '../../onboarding/domain/app_personalization_engine.dart';
import '../../profile/domain/clinical_condition_catalog.dart';
import '../../profile/domain/psychological_profile_model.dart';
import 'mind_trace_model.dart';

/// Visual interaction style for each condition-specific daily ritual prompt
/// so the check-in feels tactile and calm rather than a static questionnaire.
enum AdaptiveMetricVisualStyle {
  sleepArc,
  energyBattery,
  bubbleMeter,
  pillRow,
}

/// High-value longitudinal clinical dimensions tracked across all 12 care tracks.
enum AdaptiveMetricKind {
  sleepHours,
  sleepQuality,
  motorEnergy,
  anxietyTension,
  loopLoad,
  urgeResponse,
  anhedoniaSpark,
  traumaGrounded,
  focusFlow,
  sensoryLoad,
  emotionWave,
  bodyPresence,
  routineAnchor,
  urgeWave,
  daySpark,
}

class AdaptiveMetricOption {
  const AdaptiveMetricOption({
    required this.key,
    required this.widgetKey,
    required this.en,
    required this.fr,
    required this.ar,
    this.numericValue,
    this.level1to4 = 2,
    this.contextTag,
  });

  final String key;
  final String widgetKey;
  final String en;
  final String fr;
  final String ar;
  final double? numericValue;
  final int level1to4;
  final String? contextTag;

  String localized(AppStrings strings) {
    if (strings.isArabic) return ar;
    if (strings.isFrench) return fr;
    return en;
  }
}

class AdaptiveMetricSpec {
  const AdaptiveMetricSpec({
    required this.kind,
    required this.style,
    required this.enTitle,
    required this.frTitle,
    required this.arTitle,
    required this.enClinicianLabel,
    required this.frClinicianLabel,
    required this.arClinicianLabel,
    required this.options,
  });

  final AdaptiveMetricKind kind;
  final AdaptiveMetricVisualStyle style;
  final String enTitle;
  final String frTitle;
  final String arTitle;
  final String enClinicianLabel;
  final String frClinicianLabel;
  final String arClinicianLabel;
  final List<AdaptiveMetricOption> options;

  String localizedTitle(AppStrings strings) {
    if (strings.isArabic) return arTitle;
    if (strings.isFrench) return frTitle;
    return enTitle;
  }

  String localizedClinicianLabel(AppStrings strings) {
    if (strings.isArabic) return arClinicianLabel;
    if (strings.isFrench) return frClinicianLabel;
    return enClinicianLabel;
  }
}

/// Maps any user's 300+ condition selections / 12 Care Tracks into at most 3
/// fast, non-military visual questions per day, and syncs structured values to
/// [MindTraceModel] & clinician summaries.
abstract final class AdaptiveTrackingEngine {
  static const AdaptiveMetricSpec sleepHoursSpec = AdaptiveMetricSpec(
    kind: AdaptiveMetricKind.sleepHours,
    style: AdaptiveMetricVisualStyle.sleepArc,
    enTitle: 'How many hours did you sleep?',
    frTitle: 'Combien d’heures avez-vous dormi ?',
    arTitle: 'قدّاش من ساعة رقدت الليلة؟',
    enClinicianLabel: 'Sleep length',
    frClinicianLabel: 'Durée du sommeil',
    arClinicianLabel: 'ساعات النوم',
    options: [
      AdaptiveMetricOption(
        key: 'lt5',
        widgetKey: 'pulse-sleep-lt5',
        en: '<5h',
        fr: '<5h',
        ar: 'أقل من 5',
        numericValue: 4.5,
        level1to4: 1,
      ),
      AdaptiveMetricOption(
        key: '5to6',
        widgetKey: 'pulse-sleep-5to6',
        en: '5–6h',
        fr: '5–6h',
        ar: '5–6 س',
        numericValue: 5.5,
        level1to4: 2,
      ),
      AdaptiveMetricOption(
        key: '7to8',
        widgetKey: 'pulse-sleep-7to8',
        en: '7–8h',
        fr: '7–8h',
        ar: '7–8 س',
        numericValue: 7.5,
        level1to4: 3,
        contextTag: 'sleep_consistent',
      ),
      AdaptiveMetricOption(
        key: '9plus',
        widgetKey: 'pulse-sleep-9plus',
        en: '9h+',
        fr: '9h+',
        ar: '9+ س',
        numericValue: 9.0,
        level1to4: 4,
        contextTag: 'sleep_consistent',
      ),
    ],
  );

  static const AdaptiveMetricSpec sleepQualitySpec = AdaptiveMetricSpec(
    kind: AdaptiveMetricKind.sleepQuality,
    style: AdaptiveMetricVisualStyle.bubbleMeter,
    enTitle: 'How did waking up feel?',
    frTitle: 'Comment était le réveil ?',
    arTitle: 'كيفاش فقت الصباح؟',
    enClinicianLabel: 'Morning rest',
    frClinicianLabel: 'Qualité du réveil',
    arClinicianLabel: 'جودة النوم',
    options: [
      AdaptiveMetricOption(
        key: 'hard',
        widgetKey: 'pulse-sleepq-hard',
        en: 'Rough',
        fr: 'Haché',
        ar: 'متعب',
        numericValue: 2,
        level1to4: 1,
      ),
      AdaptiveMetricOption(
        key: 'woke',
        widgetKey: 'pulse-sleepq-woke',
        en: 'Broken',
        fr: 'Saccadé',
        ar: 'متقطع',
        numericValue: 3,
        level1to4: 2,
      ),
      AdaptiveMetricOption(
        key: 'rested',
        widgetKey: 'pulse-sleepq-rested',
        en: 'Rested',
        fr: 'Reposé',
        ar: 'مرتاح',
        numericValue: 5,
        level1to4: 4,
      ),
    ],
  );

  static const AdaptiveMetricSpec motorEnergySpec = AdaptiveMetricSpec(
    kind: AdaptiveMetricKind.motorEnergy,
    style: AdaptiveMetricVisualStyle.energyBattery,
    enTitle: 'Where is your inner battery & speed?',
    frTitle: 'Comment est votre batterie et rythme ?',
    arTitle: 'كيفاش طاقتك وسرعة إيقاعك؟',
    enClinicianLabel: 'Energy & activation',
    frClinicianLabel: 'Énergie & rythme',
    arClinicianLabel: 'الطاقة والنشاط',
    options: [
      AdaptiveMetricOption(
        key: 'drained',
        widgetKey: 'pulse-energy-drained',
        en: 'Drained',
        fr: 'À plat',
        ar: 'طايحة',
        numericValue: 2,
        level1to4: 1,
      ),
      AdaptiveMetricOption(
        key: 'low',
        widgetKey: 'pulse-energy-low',
        en: 'Slowed',
        fr: 'Ralenti',
        ar: 'هادية شوية',
        numericValue: 4,
        level1to4: 2,
      ),
      AdaptiveMetricOption(
        key: 'steady',
        widgetKey: 'pulse-energy-steady',
        en: 'Steady',
        fr: 'Stable',
        ar: 'متوازنة',
        numericValue: 7,
        level1to4: 3,
      ),
      AdaptiveMetricOption(
        key: 'high',
        widgetKey: 'pulse-energy-high',
        en: 'Revved',
        fr: 'Accéléré',
        ar: 'سريعة برشا',
        numericValue: 9,
        level1to4: 4,
      ),
    ],
  );

  static const AdaptiveMetricSpec anxietyTensionSpec = AdaptiveMetricSpec(
    kind: AdaptiveMetricKind.anxietyTension,
    style: AdaptiveMetricVisualStyle.bubbleMeter,
    enTitle: 'How much tension is in your body?',
    frTitle: 'Quel niveau de tension physique ?',
    arTitle: 'قدّاش فمّا شدّ ولا قلق في بدنك؟',
    enClinicianLabel: 'Body tension',
    frClinicianLabel: 'Tension corporelle',
    arClinicianLabel: 'التوتر الجسدي',
    options: [
      AdaptiveMetricOption(
        key: 'calm',
        widgetKey: 'pulse-stress-calm',
        en: 'Calm',
        fr: 'Calme',
        ar: 'هادي',
        numericValue: 2,
        level1to4: 1,
      ),
      AdaptiveMetricOption(
        key: 'mild',
        widgetKey: 'pulse-stress-mild',
        en: 'Mild',
        fr: 'Légère',
        ar: 'خفيف',
        numericValue: 4,
        level1to4: 2,
      ),
      AdaptiveMetricOption(
        key: 'heavy',
        widgetKey: 'pulse-stress-heavy',
        en: 'Tight',
        fr: 'Tendue',
        ar: 'مشدود',
        numericValue: 7,
        level1to4: 3,
      ),
      AdaptiveMetricOption(
        key: 'overwhelmed',
        widgetKey: 'pulse-stress-overwhelmed',
        en: 'Overwhelmed',
        fr: 'Débordée',
        ar: 'ضاغط برشا',
        numericValue: 9,
        level1to4: 4,
      ),
    ],
  );

  static const AdaptiveMetricSpec loopLoadSpec = AdaptiveMetricSpec(
    kind: AdaptiveMetricKind.loopLoad,
    style: AdaptiveMetricVisualStyle.bubbleMeter,
    enTitle: 'How loud were mental loops today?',
    frTitle: 'Intensité des boucles mentales aujourd’hui ?',
    arTitle: 'قدّاش كانت الأفكار المتكررة حاضرة اليوم؟',
    enClinicianLabel: 'Intrusive loop load',
    frClinicianLabel: 'Charge des boucles',
    arClinicianLabel: 'حدّة الأفكار المتكررة',
    options: [
      AdaptiveMetricOption(
        key: 'quiet',
        widgetKey: 'pulse-loop-quiet',
        en: 'Quiet',
        fr: 'Calme',
        ar: 'هادية',
        numericValue: 2,
        level1to4: 1,
      ),
      AdaptiveMetricOption(
        key: 'hum',
        widgetKey: 'pulse-loop-hum',
        en: 'Passing',
        fr: 'Passagères',
        ar: 'تجي وتعدّي',
        numericValue: 5,
        level1to4: 2,
      ),
      AdaptiveMetricOption(
        key: 'sticky',
        widgetKey: 'pulse-loop-sticky',
        en: 'Sticky',
        fr: 'Tenaces',
        ar: 'لاصقة شوية',
        numericValue: 8,
        level1to4: 4,
      ),
    ],
  );

  static const AdaptiveMetricSpec urgeResponseSpec = AdaptiveMetricSpec(
    kind: AdaptiveMetricKind.urgeResponse,
    style: AdaptiveMetricVisualStyle.pillRow,
    enTitle: 'When a strong urge hit, what happened?',
    frTitle: 'Face à une impulsion forte, qu’avez-vous fait ?',
    arTitle: 'وقت ما جاتك رغبة ملحّة، كيفاش تصرّفت؟',
    enClinicianLabel: 'Urge response',
    frClinicianLabel: 'Réponse à l’élan',
    arClinicianLabel: 'التعامل مع الدافع',
    options: [
      AdaptiveMetricOption(
        key: 'passed',
        widgetKey: 'pulse-urge-resp-passed',
        en: 'Let it pass',
        fr: 'Laissé passer',
        ar: 'خلّيتها تعدّي',
        level1to4: 1,
      ),
      AdaptiveMetricOption(
        key: 'paused',
        widgetKey: 'pulse-urge-resp-paused',
        en: 'Paused first',
        fr: 'Pris une pause',
        ar: 'وقفت وارتحت',
        level1to4: 2,
      ),
      AdaptiveMetricOption(
        key: 'acted',
        widgetKey: 'pulse-urge-resp-acted',
        en: 'Gave in',
        fr: 'Cédé / vérifié',
        ar: 'استجبت ليها',
        level1to4: 3,
      ),
    ],
  );

  static const AdaptiveMetricSpec anhedoniaSparkSpec = AdaptiveMetricSpec(
    kind: AdaptiveMetricKind.anhedoniaSpark,
    style: AdaptiveMetricVisualStyle.bubbleMeter,
    enTitle: 'Did anything spark a tiny lift today?',
    frTitle: 'Un petit élan ou plaisir aujourd’hui ?',
    arTitle: 'حسّيت بأي لحظة ارتياح أو متعة صغيرة اليوم؟',
    enClinicianLabel: 'Interest & enjoyment',
    frClinicianLabel: 'Élan & plaisir',
    arClinicianLabel: 'الشغف والانبساط',
    options: [
      AdaptiveMetricOption(
        key: 'flat',
        widgetKey: 'pulse-spark-flat',
        en: 'Felt flat',
        fr: 'Plat / lourd',
        ar: 'ثقيل / باهت',
        level1to4: 1,
      ),
      AdaptiveMetricOption(
        key: 'tiny',
        widgetKey: 'pulse-spark-tiny',
        en: 'Tiny spark',
        fr: 'Petit élan',
        ar: 'بصيص خفيف',
        level1to4: 2,
      ),
      AdaptiveMetricOption(
        key: 'warm',
        widgetKey: 'pulse-spark-warm',
        en: 'Present',
        fr: 'Bien présent',
        ar: 'حاضر وملموس',
        level1to4: 4,
      ),
    ],
  );

  static const AdaptiveMetricSpec traumaGroundedSpec = AdaptiveMetricSpec(
    kind: AdaptiveMetricKind.traumaGrounded,
    style: AdaptiveMetricVisualStyle.bubbleMeter,
    enTitle: 'How safe and anchored did you feel?',
    frTitle: 'Comment était votre sentiment de sécurité ?',
    arTitle: 'قدّاش حسّيت بالأمان والهدوء في محيطك؟',
    enClinicianLabel: 'Felt safety',
    frClinicianLabel: 'Sécurité ressentie',
    arClinicianLabel: 'الأمان والاستقرار',
    options: [
      AdaptiveMetricOption(
        key: 'anchored',
        widgetKey: 'pulse-safety-anchored',
        en: 'Anchored',
        fr: 'Ancré',
        ar: 'مطمان',
        numericValue: 2,
        level1to4: 1,
      ),
      AdaptiveMetricOption(
        key: 'unguarded',
        widgetKey: 'pulse-safety-guard',
        en: 'On guard',
        fr: 'Sur mes gardes',
        ar: 'حذر شوية',
        numericValue: 5,
        level1to4: 3,
      ),
      AdaptiveMetricOption(
        key: 'swamped',
        widgetKey: 'pulse-safety-swamped',
        en: 'Overwhelmed',
        fr: 'Submergé',
        ar: 'مضغوط برشا',
        numericValue: 8,
        level1to4: 4,
      ),
    ],
  );

  static const AdaptiveMetricSpec focusFlowSpec = AdaptiveMetricSpec(
    kind: AdaptiveMetricKind.focusFlow,
    style: AdaptiveMetricVisualStyle.energyBattery,
    enTitle: 'How was your focus & task flow?',
    frTitle: 'Comment était votre concentration ?',
    arTitle: 'كيفاش كان تركيزك وإنجازك اليوم؟',
    enClinicianLabel: 'Focus flow',
    frClinicianLabel: 'Flux attentionnel',
    arClinicianLabel: 'التركيز والانتباه',
    options: [
      AdaptiveMetricOption(
        key: 'stuck',
        widgetKey: 'pulse-focus-stuck',
        en: 'Stuck',
        fr: 'Bloqué',
        ar: 'معلّق / صعيب',
        numericValue: 3,
        level1to4: 1,
      ),
      AdaptiveMetricOption(
        key: 'scattered',
        widgetKey: 'pulse-focus-scattered',
        en: 'Bouncy',
        fr: 'Dispersé',
        ar: 'مشتّت شوية',
        numericValue: 5,
        level1to4: 2,
      ),
      AdaptiveMetricOption(
        key: 'clear',
        widgetKey: 'pulse-focus-clear',
        en: 'Clear lane',
        fr: 'Fluide',
        ar: 'سلس وواضح',
        numericValue: 8,
        level1to4: 4,
      ),
    ],
  );

  static const AdaptiveMetricSpec sensoryLoadSpec = AdaptiveMetricSpec(
    kind: AdaptiveMetricKind.sensoryLoad,
    style: AdaptiveMetricVisualStyle.bubbleMeter,
    enTitle: 'How did sounds, light & surroundings feel?',
    frTitle: 'Comment était le confort sensoriel ?',
    arTitle: 'كيفاش كان حسّك مع الصوت والضوء والمحيط؟',
    enClinicianLabel: 'Sensory load',
    frClinicianLabel: 'Charge sensorielle',
    arClinicianLabel: 'الحمل الحسي',
    options: [
      AdaptiveMetricOption(
        key: 'quiet',
        widgetKey: 'pulse-sensory-quiet',
        en: 'Calm & quiet',
        fr: 'Calme & doux',
        ar: 'هادي ومريح',
        level1to4: 1,
      ),
      AdaptiveMetricOption(
        key: 'noisy',
        widgetKey: 'pulse-sensory-noisy',
        en: 'Busy',
        fr: 'Chargé',
        ar: 'مزدحم شوية',
        level1to4: 2,
      ),
      AdaptiveMetricOption(
        key: 'overloaded',
        widgetKey: 'pulse-sensory-overloaded',
        en: 'Too much',
        fr: 'Saturé',
        ar: 'مرهق للحواس',
        level1to4: 4,
      ),
    ],
  );

  static const AdaptiveMetricSpec emotionWaveSpec = AdaptiveMetricSpec(
    kind: AdaptiveMetricKind.emotionWave,
    style: AdaptiveMetricVisualStyle.bubbleMeter,
    enTitle: 'How sharp were emotion waves around people?',
    frTitle: 'Intensité des vagues relationnelles ?',
    arTitle: 'كيفاش كانت موجات الانفعال في علاقاتك اليوم؟',
    enClinicianLabel: 'Emotion wave reactivity',
    frClinicianLabel: 'Vagues relationnelles',
    arClinicianLabel: 'تقلّب الانفعالات',
    options: [
      AdaptiveMetricOption(
        key: 'steady',
        widgetKey: 'pulse-wave-steady',
        en: 'Steady',
        fr: 'Posée',
        ar: 'هادية',
        level1to4: 1,
      ),
      AdaptiveMetricOption(
        key: 'stung',
        widgetKey: 'pulse-wave-stung',
        en: 'Stung',
        fr: 'Sensible',
        ar: 'حساسة شوية',
        level1to4: 2,
      ),
      AdaptiveMetricOption(
        key: 'intense',
        widgetKey: 'pulse-wave-intense',
        en: 'Intense wave',
        fr: 'Vague forte',
        ar: 'موجة قوية',
        level1to4: 4,
      ),
    ],
  );

  static const AdaptiveMetricSpec bodyPresenceSpec = AdaptiveMetricSpec(
    kind: AdaptiveMetricKind.bodyPresence,
    style: AdaptiveMetricVisualStyle.bubbleMeter,
    enTitle: 'How connected do you feel in your body?',
    frTitle: 'Vous sentez-vous présent dans votre corps ?',
    arTitle: 'قدّاش تحس روحك حاضر في بدنك واللحظة؟',
    enClinicianLabel: 'Present-body connection',
    frClinicianLabel: 'Présence corporelle',
    arClinicianLabel: 'الحضور الجسدي',
    options: [
      AdaptiveMetricOption(
        key: 'present',
        widgetKey: 'pulse-presence-here',
        en: 'Here & grounded',
        fr: 'Bien présent',
        ar: 'حاضر ومثبّت',
        numericValue: 2,
        level1to4: 1,
      ),
      AdaptiveMetricOption(
        key: 'foggy',
        widgetKey: 'pulse-presence-foggy',
        en: 'Floaty / foggy',
        fr: 'Dans le flou',
        ar: 'ضبابي شوية',
        numericValue: 5,
        level1to4: 3,
      ),
      AdaptiveMetricOption(
        key: 'distant',
        widgetKey: 'pulse-presence-distant',
        en: 'Far away',
        fr: 'Lointain / coupé',
        ar: 'بعيد / متفارق',
        numericValue: 8,
        level1to4: 4,
      ),
    ],
  );

  static const AdaptiveMetricSpec urgeWaveSpec = AdaptiveMetricSpec(
    kind: AdaptiveMetricKind.urgeWave,
    style: AdaptiveMetricVisualStyle.bubbleMeter,
    enTitle: 'How strong were craving or habit waves?',
    frTitle: 'Intensité des vagues d’envie aujourd’hui ?',
    arTitle: 'قدّاش كانت قوة موجة الدافع أو العادة اليوم؟',
    enClinicianLabel: 'Urge wave strength',
    frClinicianLabel: 'Force des envies',
    arClinicianLabel: 'حدّة موجات الدافع',
    options: [
      AdaptiveMetricOption(
        key: 'calm',
        widgetKey: 'pulse-urgewave-calm',
        en: 'Calm',
        fr: 'Calme',
        ar: 'هادية',
        level1to4: 1,
      ),
      AdaptiveMetricOption(
        key: 'tug',
        widgetKey: 'pulse-urgewave-tug',
        en: 'Passing tug',
        fr: 'Petite vague',
        ar: 'شدّة عابرة',
        level1to4: 2,
      ),
      AdaptiveMetricOption(
        key: 'strong',
        widgetKey: 'pulse-urgewave-strong',
        en: 'Strong wave',
        fr: 'Forte vague',
        ar: 'موجة قوية',
        level1to4: 4,
      ),
    ],
  );

  static const AdaptiveMetricSpec routineAnchorSpec = AdaptiveMetricSpec(
    kind: AdaptiveMetricKind.routineAnchor,
    style: AdaptiveMetricVisualStyle.pillRow,
    enTitle: 'Sleep, meals & daily rhythm today?',
    frTitle: 'Rythme sommeil, repas et repères ?',
    arTitle: 'روتين نومك وأوقاته اليوم كيفاش كان؟',
    enClinicianLabel: 'Daily routine rhythm',
    frClinicianLabel: 'Stabilité du rythme',
    arClinicianLabel: 'انتظام الروتين',
    options: [
      AdaptiveMetricOption(
        key: 'yes',
        widgetKey: 'pulse-routine-yes',
        en: 'Steady',
        fr: 'Régulier',
        ar: 'منتظم',
        contextTag: 'routine_kept',
      ),
      AdaptiveMetricOption(
        key: 'partly',
        widgetKey: 'pulse-routine-partly',
        en: 'Partly',
        fr: 'En partie',
        ar: 'نص نص',
      ),
      AdaptiveMetricOption(
        key: 'no',
        widgetKey: 'pulse-routine-no',
        en: 'Off beat',
        fr: 'Décalé',
        ar: 'متقلّب',
      ),
    ],
  );

  static const AdaptiveMetricSpec daySparkSpec = AdaptiveMetricSpec(
    kind: AdaptiveMetricKind.daySpark,
    style: AdaptiveMetricVisualStyle.pillRow,
    enTitle: 'One thing that shaped today?',
    frTitle: 'Un repère marquant aujourd’hui ?',
    arTitle: 'حاجة أثّرت في يومك اليوم؟',
    enClinicianLabel: 'Day context spark',
    frClinicianLabel: 'Repère du jour',
    arClinicianLabel: 'مؤثّر اليوم',
    options: [
      AdaptiveMetricOption(
        key: 'rest',
        widgetKey: 'pulse-help-rest',
        en: 'Quiet rest',
        fr: 'Moment calme',
        ar: 'راحة هادية',
      ),
      AdaptiveMetricOption(
        key: 'walk',
        widgetKey: 'pulse-help-walk',
        en: 'Moved body',
        fr: 'Bougé un peu',
        ar: 'حركة ومشي',
        contextTag: 'physical_movement',
      ),
      AdaptiveMetricOption(
        key: 'talked',
        widgetKey: 'pulse-help-talked',
        en: 'Connected',
        fr: 'Échangé',
        ar: 'تواصلت مع حد',
        contextTag: 'social_connection',
      ),
      AdaptiveMetricOption(
        key: 'heavy_work',
        widgetKey: 'pulse-tag-high_workload',
        en: 'Heavy day',
        fr: 'Journée chargée',
        ar: 'ضغط عمل',
        contextTag: 'high_workload',
      ),
    ],
  );

  /// Deterministically resolves the top 2–3 visual daily ritual metrics
  /// for the user's selected condition tracks and time of day.
  static List<AdaptiveMetricSpec> buildDailyRitual({
    required PsychologicalProfileModel? profile,
    required AppPersonalizationPlan plan,
    required MindTraceModel? todayTrace,
    required int hour,
  }) {
    final tracks = plan.activeTracks.isNotEmpty
        ? plan.activeTracks
        : ClinicalConditionCatalog.resolveTracks(profile);
    final isMorning = hour >= 5 && hour < 14;
    final hasSleep = todayTrace?.sleepHours != null;

    final result = <AdaptiveMetricSpec>[];
    void addUnique(AdaptiveMetricSpec spec) {
      if (result.any((s) => s.kind == spec.kind)) return;
      if (result.length < 3) result.add(spec);
    }

    // 1. Critical clinical priority rules first (e.g., Bipolar sleep protection;
    // keep Sleep stably visible all day so tapping it never hides it mid-interaction)
    if (tracks.contains(ClinicalTrack.bipolarCycling)) {
      addUnique(sleepHoursSpec);
      addUnique(motorEnergySpec);
      addUnique(routineAnchorSpec);
    }

    if (tracks.contains(ClinicalTrack.sleepWake)) {
      addUnique(sleepHoursSpec);
      if (isMorning) addUnique(sleepQualitySpec);
    }

    if (tracks.contains(ClinicalTrack.perceptualGrounding)) {
      addUnique(sleepHoursSpec);
      addUnique(sensoryLoadSpec);
      addUnique(routineAnchorSpec);
    }

    if (tracks.contains(ClinicalTrack.depressiveSpectrum)) {
      if (isMorning || !hasSleep) addUnique(sleepHoursSpec);
      addUnique(anhedoniaSparkSpec);
      if (isMorning) addUnique(motorEnergySpec);
    }

    if (tracks.contains(ClinicalTrack.obsessiveCompulsive)) {
      addUnique(loopLoadSpec);
      addUnique(urgeResponseSpec);
      if (isMorning && !hasSleep) addUnique(sleepHoursSpec);
    }

    if (tracks.contains(ClinicalTrack.anxietyPanic)) {
      addUnique(anxietyTensionSpec);
      if (isMorning && !hasSleep) addUnique(sleepHoursSpec);
    }

    if (tracks.contains(ClinicalTrack.traumaStress)) {
      addUnique(traumaGroundedSpec);
      if (isMorning && !hasSleep) addUnique(sleepHoursSpec);
    }

    if (tracks.contains(ClinicalTrack.neurodevelopmental)) {
      addUnique(focusFlowSpec);
      addUnique(sensoryLoadSpec);
      if (isMorning && !hasSleep) addUnique(sleepHoursSpec);
    }

    if (tracks.contains(ClinicalTrack.emotionRegulation)) {
      addUnique(emotionWaveSpec);
      addUnique(urgeResponseSpec);
    }

    if (tracks.contains(ClinicalTrack.dissociativeSomatic)) {
      addUnique(bodyPresenceSpec);
      addUnique(anxietyTensionSpec);
    }

    if (tracks.contains(ClinicalTrack.urgeHabitRecovery)) {
      addUnique(urgeWaveSpec);
      addUnique(urgeResponseSpec);
    }

    // 2. General baseline fallback / filler (clean max 2 morning / 3 evening)
    if (isMorning) {
      if (result.isEmpty) {
        addUnique(sleepHoursSpec);
        addUnique(motorEnergySpec);
      } else if (result.length == 1) {
        addUnique(hasSleep ? motorEnergySpec : sleepHoursSpec);
      }
      if (plan.showRoutineAnchorQuestion && result.length < 3) {
        addUnique(routineAnchorSpec);
      }
    } else {
      if (result.isEmpty) {
        addUnique(anxietyTensionSpec);
        if (!hasSleep) addUnique(sleepHoursSpec);
        addUnique(daySparkSpec);
      } else if (result.length < 3) {
        if (!hasSleep && plan.prioritizeSleepPulse) {
          addUnique(sleepHoursSpec);
        }
        if (result.length < 3) {
          addUnique(daySparkSpec);
        }
      }
    }

    return result.take(3).toList(growable: false);
  }

  /// Checks whether the user already logged a value for [kind] today.
  static bool isMetricCompleted(AdaptiveMetricKind kind, MindTraceModel? trace) {
    if (trace == null) return false;
    final dyn = trace.dynamicAnswers;
    return switch (kind) {
      AdaptiveMetricKind.sleepHours => trace.sleepHours != null,
      AdaptiveMetricKind.sleepQuality => trace.sleepQuality != null,
      AdaptiveMetricKind.motorEnergy => trace.energyLevel != null,
      AdaptiveMetricKind.anxietyTension => trace.anxietyLevel != null,
      AdaptiveMetricKind.loopLoad => (dyn['track_loop_load'] ?? '').isNotEmpty,
      AdaptiveMetricKind.urgeResponse =>
        (dyn['track_urge_response'] ?? '').isNotEmpty,
      AdaptiveMetricKind.anhedoniaSpark =>
        (dyn['track_anhedonia'] ?? '').isNotEmpty,
      AdaptiveMetricKind.traumaGrounded =>
        (dyn['track_felt_safety'] ?? '').isNotEmpty,
      AdaptiveMetricKind.focusFlow =>
        (dyn['track_focus_flow'] ?? '').isNotEmpty ||
            trace.concentrationLevel != null,
      AdaptiveMetricKind.sensoryLoad =>
        (dyn['track_sensory_load'] ?? '').isNotEmpty,
      AdaptiveMetricKind.emotionWave =>
        (dyn['track_emotion_wave'] ?? '').isNotEmpty,
      AdaptiveMetricKind.bodyPresence =>
        (dyn['track_presence'] ?? '').isNotEmpty,
      AdaptiveMetricKind.urgeWave =>
        (dyn['track_urge_wave'] ?? '').isNotEmpty,
      AdaptiveMetricKind.routineAnchor =>
        (dyn['routine_adherence'] ?? '').isNotEmpty,
      AdaptiveMetricKind.daySpark =>
        (trace.behavioralResponse ?? '').trim().isNotEmpty ||
            trace.contextTags.any(
              (t) => t == 'high_workload' || t == 'physical_movement' || t == 'social_connection',
            ),
    };
  }

  /// Returns true when [opt] matches the stored value inside [trace].
  static bool isOptionSelected(
    AdaptiveMetricKind kind,
    AdaptiveMetricOption opt,
    MindTraceModel? trace,
  ) {
    if (trace == null) return false;
    final dyn = trace.dynamicAnswers;
    return switch (kind) {
      AdaptiveMetricKind.sleepHours =>
        trace.sleepHours != null &&
            opt.numericValue != null &&
            (trace.sleepHours! - opt.numericValue!).abs() < 0.4,
      AdaptiveMetricKind.sleepQuality =>
        trace.sleepQuality != null &&
            opt.numericValue != null &&
            trace.sleepQuality == opt.numericValue!.round(),
      AdaptiveMetricKind.motorEnergy =>
        trace.energyLevel != null &&
            opt.numericValue != null &&
            (trace.energyLevel! - opt.numericValue!.round()).abs() <= 1,
      AdaptiveMetricKind.anxietyTension =>
        trace.anxietyLevel != null &&
            opt.numericValue != null &&
            (trace.anxietyLevel! - opt.numericValue!.round()).abs() <= 1,
      AdaptiveMetricKind.loopLoad => dyn['track_loop_load'] == opt.key,
      AdaptiveMetricKind.urgeResponse => dyn['track_urge_response'] == opt.key,
      AdaptiveMetricKind.anhedoniaSpark => dyn['track_anhedonia'] == opt.key,
      AdaptiveMetricKind.traumaGrounded => dyn['track_felt_safety'] == opt.key,
      AdaptiveMetricKind.focusFlow => dyn['track_focus_flow'] == opt.key,
      AdaptiveMetricKind.sensoryLoad => dyn['track_sensory_load'] == opt.key,
      AdaptiveMetricKind.emotionWave => dyn['track_emotion_wave'] == opt.key,
      AdaptiveMetricKind.bodyPresence => dyn['track_presence'] == opt.key,
      AdaptiveMetricKind.urgeWave => dyn['track_urge_wave'] == opt.key,
      AdaptiveMetricKind.routineAnchor => dyn['routine_adherence'] == opt.key,
      AdaptiveMetricKind.daySpark =>
        dyn['track_day_spark'] == opt.key ||
            (opt.contextTag != null &&
                trace.contextTags.contains(opt.contextTag)) ||
            (trace.behavioralResponse ?? '').trim() == opt.en,
    };
  }

  /// Applies a 1-tap selection cleanly to [base] keeping both strongly typed
  /// [MindTraceModel] fields and `dynamicAnswers` in sync for Analytics & EHR.
  static MindTraceModel applySelection(
    MindTraceModel base,
    AdaptiveMetricKind kind,
    AdaptiveMetricOption opt, {
    required AppStrings strings,
  }) {
    final now = DateTime.now();
    final dyn = Map<String, String>.from(base.dynamicAnswers);
    final tags = List<String>.from(base.contextTags);

    void setTagExclusive(String tag, List<String> allInGroup) {
      tags.removeWhere(allInGroup.contains);
      tags.add(tag);
    }

    switch (kind) {
      case AdaptiveMetricKind.sleepHours:
        final hrs = opt.numericValue ?? 7.5;
        if (hrs >= 6.5) {
          if (!tags.contains('sleep_consistent')) tags.add('sleep_consistent');
        } else {
          tags.remove('sleep_consistent');
        }
        return base.copyWith(
          sleepHours: hrs,
          contextTags: tags,
          updatedAt: now,
        );
      case AdaptiveMetricKind.sleepQuality:
        return base.copyWith(
          sleepQuality: opt.numericValue?.round(),
          updatedAt: now,
        );
      case AdaptiveMetricKind.motorEnergy:
        final lvl = opt.numericValue?.round() ?? 5;
        dyn['motor_speed'] = opt.key;
        return base.copyWith(
          energyLevel: lvl,
          racingThoughts: opt.key == 'high' ? 7 : base.racingThoughts,
          dynamicAnswers: dyn,
          updatedAt: now,
        );
      case AdaptiveMetricKind.anxietyTension:
        final lvl = opt.numericValue?.round() ?? 4;
        return base.copyWith(
          anxietyLevel: lvl,
          physicalTension: lvl,
          updatedAt: now,
        );
      case AdaptiveMetricKind.loopLoad:
        dyn['track_loop_load'] = opt.key;
        return base.copyWith(
          intrusiveThoughts: opt.numericValue?.round(),
          dynamicAnswers: dyn,
          updatedAt: now,
        );
      case AdaptiveMetricKind.urgeResponse:
        dyn['track_urge_response'] = opt.key;
        return base.copyWith(
          dynamicAnswers: dyn,
          behavioralResponse: opt.localized(strings),
          updatedAt: now,
        );
      case AdaptiveMetricKind.anhedoniaSpark:
        dyn['track_anhedonia'] = opt.key;
        return base.copyWith(dynamicAnswers: dyn, updatedAt: now);
      case AdaptiveMetricKind.traumaGrounded:
        dyn['track_felt_safety'] = opt.key;
        return base.copyWith(
          emotionalDisconnection: opt.numericValue?.round(),
          dynamicAnswers: dyn,
          updatedAt: now,
        );
      case AdaptiveMetricKind.focusFlow:
        dyn['track_focus_flow'] = opt.key;
        return base.copyWith(
          concentrationLevel: opt.numericValue?.round(),
          dynamicAnswers: dyn,
          updatedAt: now,
        );
      case AdaptiveMetricKind.sensoryLoad:
        dyn['track_sensory_load'] = opt.key;
        return base.copyWith(dynamicAnswers: dyn, updatedAt: now);
      case AdaptiveMetricKind.emotionWave:
        dyn['track_emotion_wave'] = opt.key;
        return base.copyWith(dynamicAnswers: dyn, updatedAt: now);
      case AdaptiveMetricKind.bodyPresence:
        dyn['track_presence'] = opt.key;
        return base.copyWith(
          emotionalDisconnection: opt.numericValue?.round(),
          dynamicAnswers: dyn,
          updatedAt: now,
        );
      case AdaptiveMetricKind.urgeWave:
        dyn['track_urge_wave'] = opt.key;
        return base.copyWith(dynamicAnswers: dyn, updatedAt: now);
      case AdaptiveMetricKind.routineAnchor:
        dyn['routine_adherence'] = opt.key;
        if (opt.key == 'yes') {
          if (!tags.contains('routine_kept')) tags.add('routine_kept');
        } else {
          tags.remove('routine_kept');
        }
        return base.copyWith(
          dynamicAnswers: dyn,
          contextTags: tags,
          updatedAt: now,
        );
      case AdaptiveMetricKind.daySpark:
        dyn['track_day_spark'] = opt.key;
        const sparkTags = [
          'physical_movement',
          'social_connection',
          'high_workload',
        ];
        if (opt.contextTag != null) {
          setTagExclusive(opt.contextTag!, sparkTags);
        } else {
          tags.removeWhere(sparkTags.contains);
        }
        return base.copyWith(
          dynamicAnswers: dyn,
          behavioralResponse: opt.key == 'heavy_work'
              ? base.behavioralResponse
              : opt.localized(strings),
          contextTags: tags,
          updatedAt: now,
        );
    }
  }

  /// Extracts localized, doctor-ready condition-specific readings from [traces]
  /// for both `Patterns` (`InsightsScreen`) and `ClinicianSyncService`.
  static List<String> summarizeConditionMarkers(
    List<MindTraceModel> traces,
    Set<ClinicalTrack> tracks,
    AppStrings strings,
  ) {
    if (traces.isEmpty) return const [];
    final latest = traces.first;
    final dyn = latest.dynamicAnswers;
    final lines = <String>[];

    String? pickOptLabel(AdaptiveMetricSpec spec, String? key) {
      if (key == null || key.isEmpty) return null;
      for (final o in spec.options) {
        if (o.key == key) return o.localized(strings);
      }
      return key;
    }

    void addIfPresent(AdaptiveMetricSpec spec, String dynKey) {
      final val = pickOptLabel(spec, dyn[dynKey]);
      if (val != null) {
        lines.add('${spec.localizedClinicianLabel(strings)}: $val');
      }
    }

    if (tracks.contains(ClinicalTrack.bipolarCycling) ||
        dyn.containsKey('motor_speed') ||
        dyn.containsKey('routine_adherence')) {
      addIfPresent(motorEnergySpec, 'motor_speed');
      addIfPresent(routineAnchorSpec, 'routine_adherence');
    }
    if (tracks.contains(ClinicalTrack.obsessiveCompulsive) ||
        dyn.containsKey('track_loop_load') ||
        dyn.containsKey('track_urge_response')) {
      addIfPresent(loopLoadSpec, 'track_loop_load');
      addIfPresent(urgeResponseSpec, 'track_urge_response');
    }
    if (tracks.contains(ClinicalTrack.depressiveSpectrum) ||
        dyn.containsKey('track_anhedonia')) {
      addIfPresent(anhedoniaSparkSpec, 'track_anhedonia');
    }
    if (tracks.contains(ClinicalTrack.traumaStress) ||
        dyn.containsKey('track_felt_safety')) {
      addIfPresent(traumaGroundedSpec, 'track_felt_safety');
    }
    if (tracks.contains(ClinicalTrack.neurodevelopmental) ||
        dyn.containsKey('track_focus_flow') ||
        dyn.containsKey('track_sensory_load')) {
      addIfPresent(focusFlowSpec, 'track_focus_flow');
      addIfPresent(sensoryLoadSpec, 'track_sensory_load');
    }
    if (tracks.contains(ClinicalTrack.emotionRegulation) ||
        dyn.containsKey('track_emotion_wave')) {
      addIfPresent(emotionWaveSpec, 'track_emotion_wave');
    }
    if (tracks.contains(ClinicalTrack.dissociativeSomatic) ||
        dyn.containsKey('track_presence')) {
      addIfPresent(bodyPresenceSpec, 'track_presence');
    }
    if (tracks.contains(ClinicalTrack.urgeHabitRecovery) ||
        dyn.containsKey('track_urge_wave')) {
      addIfPresent(urgeWaveSpec, 'track_urge_wave');
    }

    return lines;
  }
}
