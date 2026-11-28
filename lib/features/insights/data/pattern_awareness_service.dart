import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/localization/app_strings.dart';
import '../../mind_trace/controllers/mind_trace_controller.dart';
import '../../mind_trace/domain/mind_trace_model.dart';
import '../domain/pattern_divergence_model.dart';
import '../domain/personal_baseline_model.dart';

/// Pure computation service for detecting meaningful multi-day divergences
/// from the user's personal baseline.
///
/// Strictly abides by Part 7.2 & Clinical Guardrails:
/// - Never labels as mania, hypomania, or depression.
/// - Never predicts relapse.
/// - Clearly cites evidence and communicates uncertainty.
class PatternAwarenessService {
  static List<PatternDivergence> detectDivergences({
    required List<MindTraceModel> traces,
    required PersonalBaseline baseline,
    AppStrings strings = const AppStrings('en'),
  }) {
    if (!baseline.hasSufficientData || traces.length < 2) {
      return [];
    }

    final isAr = strings.isArabic;
    final isFr = strings.isFrench;
    String tr(String en, String fr, String ar) => isAr ? ar : (isFr ? fr : en);

    final timeWindow = tr('Past 3–4 days', '3 à 4 derniers jours', 'آخر 3-4 أيام');
    final now = DateTime.now();
    final past3DaysCutoff = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 4));
    final recentTraces = traces.where((t) => !t.date.isBefore(past3DaysCutoff)).toList();

    if (recentTraces.length < 2) {
      return [];
    }

    recentTraces.sort((a, b) => a.date.compareTo(b.date));
    final List<PatternDivergence> divergences = [];

    // Telemetry extraction
    final recentSleeps = recentTraces
        .map((t) => t.sleepHours)
        .whereType<double>()
        .where((h) => h >= 0.0 && h <= 24.0)
        .toList();
    final recentAvgSleep = recentSleeps.isNotEmpty
        ? recentSleeps.reduce((a, b) => a + b) / recentSleeps.length
        : null;

    final recentEnergyValues = recentTraces
        .map((t) => t.energyLevel)
        .whereType<int>()
        .where((e) => e >= 1 && e <= 10)
        .toList();
    final recentAvgEnergy = recentEnergyValues.isNotEmpty
        ? recentEnergyValues.reduce((a, b) => a + b) / recentEnergyValues.length
        : null;

    final hasRacingThoughts = recentTraces.any((t) => (t.racingThoughts ?? 0) >= 6);

    final sleepDeficit = (baseline.averageSleepHours != null && recentAvgSleep != null)
        ? baseline.averageSleepHours! - recentAvgSleep
        : null;
    final energySurge = (baseline.averageEnergyLevel != null && recentAvgEnergy != null)
        ? recentAvgEnergy - baseline.averageEnergyLevel!
        : null;
    final energyDrop = (baseline.averageEnergyLevel != null && recentAvgEnergy != null)
        ? baseline.averageEnergyLevel! - recentAvgEnergy
        : null;

    // -------------------------------------------------------------------------
    // 1. Co-Occurring Combinations (Multi-Metric Shifts)
    // -------------------------------------------------------------------------
    // Combined Shift: Lower sleep co-occurring with elevated energy or racing thoughts
    if (sleepDeficit != null &&
        sleepDeficit >= 1.0 &&
        ((energySurge != null && energySurge >= 1.5) || hasRacingThoughts)) {
      final recSleep = recentAvgSleep!.toStringAsFixed(1);
      final baseSleep = baseline.averageSleepHours!.toStringAsFixed(1);
      final List<String> observations = [
        tr(
          'Recorded sleep averaged $recSleep hours across ${recentSleeps.length} nights (baseline: $baseSleep hours across ${baseline.sleepObservationCount} nights).',
          'Le sommeil enregistré était en moyenne de ${recSleep}h sur ${recentSleeps.length} nuits (repère : ${baseSleep}h sur ${baseline.sleepObservationCount} nuits).',
          'معدّل النوم المسجّل كان $recSleep ساعات على ${recentSleeps.length} ليالي (معدّلك المعتاد: $baseSleep ساعات على ${baseline.sleepObservationCount} ليلة).',
        ),
      ];
      if (baseline.averageEnergyLevel != null && recentAvgEnergy != null) {
        final recEng = recentAvgEnergy.toStringAsFixed(1);
        final baseEng = baseline.averageEnergyLevel!.toStringAsFixed(1);
        observations.add(
          tr(
            'Reported energy averaged $recEng/10 across ${recentEnergyValues.length} entries (baseline: $baseEng/10 across ${baseline.energyObservationCount} entries).',
            'L’énergie déclarée était en moyenne de $recEng/10 sur ${recentEnergyValues.length} bilans (repère : $baseEng/10 sur ${baseline.energyObservationCount} bilans).',
            'الطاقة المسجّلة كانت في حدود $recEng/10 على ${recentEnergyValues.length} تسجيلات (معدّلك المعتاد: $baseEng/10 على ${baseline.energyObservationCount} تسجيل).',
          ),
        );
      }
      if (hasRacingThoughts) {
        final maxRacing = recentTraces
            .map((t) => t.racingThoughts ?? 0)
            .reduce((a, b) => a > b ? a : b);
        observations.add(
          tr(
            'Racing thoughts were rated at $maxRacing/10 on a recent check-in.',
            'Des pensées rapides ont été notées à $maxRacing/10 sur un bilan récent.',
            'الأفكار السريعة اتقيّمت بـ $maxRacing/10 في متابعة قريبة.',
          ),
        );
      }

      final energyClauseEn = (energySurge != null && energySurge >= 1.5)
          ? 'reported energy is higher by ${energySurge.toStringAsFixed(1)} points'
          : 'energy ratings remain steady with your baseline';
      final energyClauseFr = (energySurge != null && energySurge >= 1.5)
          ? 'l’énergie déclarée est plus haute de ${energySurge.toStringAsFixed(1)} points'
          : 'l’énergie reste proche de votre repère habituel';
      final energyClauseAr = (energySurge != null && energySurge >= 1.5)
          ? 'والطاقة طالعة بـ ${energySurge.toStringAsFixed(1)} نقاط'
          : 'والطاقة قاعدة قريبة من معدّلك المعتاد';
      final sleepDiffStr = sleepDeficit.toStringAsFixed(1);

      divergences.add(
        PatternDivergence(
          id: 'div_activation_${now.millisecondsSinceEpoch}',
          category: DivergenceCategory.elevatedActivation,
          observationType: ObservationType.combinedMetricShift,
          title: tr(
            'Shift in Energy & Sleep: Combined Ratings',
            'Écart énergie et sommeil : notes combinées',
            'تبدّل في الطاقة والنوم: ملاحظة مشتركة',
          ),
          timeWindow: timeWindow,
          contributingObservations: observations,
          baselineComparison: tr(
            'Sleep is lower by ${sleepDiffStr}h while $energyClauseEn compared to your usual baseline.',
            'Le sommeil est plus bas de ${sleepDiffStr}h et $energyClauseFr par rapport à votre repère habituel.',
            'النوم ناقص بـ $sleepDiffStr ساعات $energyClauseAr مقارنة بمعدّلك المعتاد.',
          ),
          uncertaintyStatement: tr(
            'This observation reflects numbers and sensations you logged. It is an exploration of pattern shifts, not a clinical diagnosis or confirmed episode.',
            'Cette observation reflète uniquement les repères que vous avez notés. C’est une piste d’exploration, pas un diagnostic médical.',
            'هذه الملاحظة تعكس الأرقام والإحساس اللي سجّلتهم أنت، وهي استكشاف لتبدّل النسق فقط وموش تشخيص طبي.',
          ),
          userCheckInQuestion: tr(
            'Do you recognize this increase in energy and reduced rest in your routine over the last few days?',
            'Reconnaissez-vous cette hausse d’énergie ou ce repos réduit dans vos derniers jours ?',
            'تحسّ روحك أكثر نشاطاً ونومك أقلّ في الأيام الأخيرة؟',
          ),
          supportPlanPrompt: tr(
            'Consider reviewing your personal early-warning signs, evening wind-down routine, or calming activities.',
            'Pensez à revoir vos repères personnels de calme du soir ou vos activités apaisantes.',
            'يمكن يفيدك تراجع إشاراتك الأولى ولا روتين تهدئة قبل النوم.',
          ),
          therapistPrompt: tr(
            'If you feel ungrounded or this pattern continues, reviewing these logs with your doctor or therapist could be helpful.',
            'Si ce rythme continue ou vous déstabilise, partager ces notes avec un professionnel peut aider.',
            'كان حسّيت روحك موش مرتاح ولا استمرّ النسق هذا، مشاركة الملاحظات مع طبيب ولا مختص تنجم تعاونك.',
          ),
          detectedAt: now,
        ),
      );
    }

    // Combined Shift: Lower energy co-occurring with lower mood or heavy mood descriptors
    final recentIntensities = recentTraces.map((t) => t.moodIntensity).toList();
    final recentAvgIntensity = recentIntensities.isNotEmpty
        ? recentIntensities.reduce((a, b) => a + b) / recentIntensities.length
        : null;
    final hasHeavyOrLowMood = recentTraces.any((t) => t.overallMood == 'heavy' || t.overallMood == 'frustrated');
    final moodDrop = (baseline.averageMoodIntensity != null && recentAvgIntensity != null)
        ? baseline.averageMoodIntensity! - recentAvgIntensity
        : null;

    if (energyDrop != null &&
        energyDrop >= 1.5 &&
        ((moodDrop != null && moodDrop >= 1.2) || hasHeavyOrLowMood)) {
      final recEng = recentAvgEnergy!.toStringAsFixed(1);
      final baseEng = baseline.averageEnergyLevel!.toStringAsFixed(1);
      final List<String> observations = [
        tr(
          'Reported energy averaged $recEng/10 across ${recentEnergyValues.length} entries (baseline: $baseEng/10 across ${baseline.energyObservationCount} entries).',
          'L’énergie déclarée était en moyenne de $recEng/10 sur ${recentEnergyValues.length} bilans (repère : $baseEng/10 sur ${baseline.energyObservationCount} bilans).',
          'الطاقة المسجّلة كانت في حدود $recEng/10 على ${recentEnergyValues.length} تسجيلات (معدّلك المعتاد: $baseEng/10 على ${baseline.energyObservationCount} تسجيل).',
        ),
      ];
      if (moodDrop != null && moodDrop >= 1.2) {
        final recMood = recentAvgIntensity!.toStringAsFixed(1);
        final dropStr = moodDrop.toStringAsFixed(1);
        final baseMood = baseline.averageMoodIntensity!.toStringAsFixed(1);
        observations.add(
          tr(
            'Mood intensity averaged $recMood/10 (lower by $dropStr points compared to your baseline of $baseMood/10 across ${baseline.moodObservationCount} entries).',
            'L’intensité d’humeur moyenne était de $recMood/10 ($dropStr points de moins que votre repère de $baseMood/10 sur ${baseline.moodObservationCount} bilans).',
            'شدّة المزاج كانت $recMood/10 (أقلّ بـ $dropStr نقاط من معدّلك $baseMood/10 على ${baseline.moodObservationCount} تسجيل).',
          ),
        );
      }
      if (hasHeavyOrLowMood) {
        observations.add(
          tr(
            'Recorded mood state reflected lower energy or heavier sensations across recent entries.',
            'Les bilans récents mentionnent des ressentis plus lourds ou une baisse d’élan.',
            'التسجيلات الأخيرة عبّرت على إحساس أثقل ولا طاقة أضعف.',
          ),
        );
      }

      final energyDropStr = energyDrop.toStringAsFixed(1);
      divergences.add(
        PatternDivergence(
          id: 'div_low_${now.millisecondsSinceEpoch}',
          category: DivergenceCategory.lowActivation,
          observationType: ObservationType.combinedMetricShift,
          title: tr(
            'Drop in Energy & Mood: Combined Ratings',
            'Baisse d’énergie et d’humeur : notes combinées',
            'نزول في الطاقة والمزاج: ملاحظة مشتركة',
          ),
          timeWindow: timeWindow,
          contributingObservations: observations,
          baselineComparison: tr(
            'Energy is lower by $energyDropStr points compared to your 30-day baseline.',
            'L’énergie est inférieure de $energyDropStr points à votre repère sur 30 jours.',
            'الطاقة أقلّ بـ $energyDropStr نقاط مقارنة بمعدّلك على 30 يوم.',
          ),
          uncertaintyStatement: tr(
            'Fluctuations in vitality and mood are a natural part of living. This observation highlights a dip from your typical level.',
            'Les variations de tonus et d’humeur sont naturelles. Cette note signale simplement un creux par rapport à votre habitude.',
            'تقلّبات النشاط والمزاج حاجة طبيعية. هذه الملاحظة تبيّن برك إنّك تحت نسقك المعتاد.',
          ),
          userCheckInQuestion: tr(
            'Have you been feeling drained, carrying extra weight, or feeling less motivated lately?',
            'Vous sentez-vous plus fatigué, alourdi ou avec moins d’élan ces derniers jours ?',
            'تحسّ روحك تاعب ولا حامل ثقل ولا ناقص حماس الأيام هاذي؟',
          ),
          supportPlanPrompt: tr(
            'Gentle pacing, prioritizing basic rest, and small manageable steps can help without putting pressure on yourself.',
            'Aller à votre rythme, prioriser le repos et viser de petits pas peut aider sans pression.',
            'خذ راحتك بشوية، أعطي الأولوية للراحة، وخطوات صغيرة تكفي من غير ما تضغط على روحك.',
          ),
          therapistPrompt: tr(
            'If this feeling persists, bringing this observation to your therapist can provide support tailored to your needs.',
            'Si ce ressenti dure, en parler avec votre accompagnant ou thérapeute peut vous soutenir.',
            'كان الإحساس هذا طوّل، تنجم تورّي الملاحظة لطبيبك ولا مختصّك باش يعاونك.',
          ),
          detectedAt: now,
        ),
      );
    }

    // -------------------------------------------------------------------------
    // 2. Independent Metric Differences (Never Hidden by Other Metrics)
    // -------------------------------------------------------------------------
    // Independent Sleep difference: reported regardless of energy level
    final alreadyHasCombinedSleep = divergences.any((d) => d.category == DivergenceCategory.elevatedActivation);
    if (!alreadyHasCombinedSleep && sleepDeficit != null && sleepDeficit.abs() >= 1.0) {
      final recSleep = recentAvgSleep!.toStringAsFixed(1);
      final baseSleep = baseline.averageSleepHours!.toStringAsFixed(1);
      final diffStr = sleepDeficit.abs().toStringAsFixed(1);
      divergences.add(
        PatternDivergence(
          id: 'div_sleep_${now.millisecondsSinceEpoch}',
          category: DivergenceCategory.sleepDisruption,
          observationType: ObservationType.individualMetricShift,
          title: tr(
            'Observed Difference in Sleep Duration',
            'Variation observée de la durée du sommeil',
            'تبدّل ملاحظ في مدّة النوم',
          ),
          timeWindow: timeWindow,
          contributingObservations: [
            tr(
              'Recorded sleep averaged $recSleep hours across ${recentSleeps.length} nights (baseline: $baseSleep hours across ${baseline.sleepObservationCount} nights).',
              'Le sommeil enregistré était en moyenne de ${recSleep}h sur ${recentSleeps.length} nuits (repère : ${baseSleep}h sur ${baseline.sleepObservationCount} nuits).',
              'معدّل النوم المسجّل كان $recSleep ساعات على ${recentSleeps.length} ليالي (معدّلك المعتاد: $baseSleep ساعات على ${baseline.sleepObservationCount} ليلة).',
            ),
          ],
          baselineComparison: tr(
            'Sleep averaged ${recSleep}h (${sleepDeficit > 0 ? "lower" : "higher"} by ${diffStr}h compared to your baseline of ${baseSleep}h).',
            'Le sommeil moyen était de ${recSleep}h (${sleepDeficit > 0 ? "en baisse" : "en hausse"} de ${diffStr}h par rapport à votre repère de ${baseSleep}h).',
            'معدّل النوم $recSleep س (${sleepDeficit > 0 ? "أقلّ" : "أكثر"} بـ $diffStr ساعات مقارنة بمعدّلك $baseSleep س).',
          ),
          uncertaintyStatement: tr(
            'Sleep variations can stem from scheduling, environment, or temporary stress.',
            'Les écarts de sommeil viennent souvent des horaires, du cadre ou d’une charge passagère.',
            'تغيّر النوم ينجم يجي من تبدّل التوقيت ولا الجو ولا تعب وقتي.',
          ),
          userCheckInQuestion: tr(
            'How has your sleep schedule felt over these past few nights?',
            'Comment ressentez-vous votre rythme de sommeil ces dernières nuits ?',
            'كيفاش حسّيت نظام نومك في الليالي الأخيرة؟',
          ),
          supportPlanPrompt: tr(
            'Evening wind-down rituals, minimizing screen exposure, or resting without sleep pressure may be helpful.',
            'Un sas de calme le soir, moins d’écrans ou du repos sans pression de dormir peuvent aider.',
            'روتين تهدئة قبل النوم، تنقيص التليفون، ولا راحة من غير توتر ينجم يعاونك.',
          ),
          therapistPrompt: null,
          detectedAt: now,
        ),
      );
    }

    // Independent Energy difference: reported regardless of mood
    final alreadyHasCombinedEnergy = divergences.any((d) => d.category == DivergenceCategory.lowActivation || d.category == DivergenceCategory.elevatedActivation);
    if (!alreadyHasCombinedEnergy && energyDrop != null && energyDrop.abs() >= 1.5) {
      final recEng = recentAvgEnergy!.toStringAsFixed(1);
      final baseEng = baseline.averageEnergyLevel!.toStringAsFixed(1);
      final diffStr = energyDrop.abs().toStringAsFixed(1);
      divergences.add(
        PatternDivergence(
          id: 'div_energy_${now.millisecondsSinceEpoch}',
          category: energyDrop > 0 ? DivergenceCategory.lowActivation : DivergenceCategory.generalVariation,
          observationType: ObservationType.individualMetricShift,
          title: tr(
            'Observed Difference in Energy Level',
            'Variation observée du niveau d’énergie',
            'تبدّل ملاحظ في مستوى الطاقة',
          ),
          timeWindow: timeWindow,
          contributingObservations: [
            tr(
              'Reported energy averaged $recEng/10 across ${recentEnergyValues.length} entries (baseline: $baseEng/10 across ${baseline.energyObservationCount} entries).',
              'L’énergie déclarée était en moyenne de $recEng/10 sur ${recentEnergyValues.length} bilans (repère : $baseEng/10 sur ${baseline.energyObservationCount} bilans).',
              'الطاقة المسجّلة كانت في حدود $recEng/10 على ${recentEnergyValues.length} تسجيلات (معدّلك المعتاد: $baseEng/10 على ${baseline.energyObservationCount} تسجيل).',
            ),
          ],
          baselineComparison: tr(
            'Energy is ${energyDrop > 0 ? "lower" : "higher"} by $diffStr points compared to your baseline.',
            'L’énergie est ${energyDrop > 0 ? "plus basse" : "plus haute"} de $diffStr points par rapport à votre repère.',
            'الطاقة ${energyDrop > 0 ? "أقلّ" : "أعلى"} بـ $diffStr نقاط مقارنة بمعدّلك المعتاد.',
          ),
          uncertaintyStatement: tr(
            'Fluctuations in vitality and daily energy are normal bodily variations.',
            'Les variations d’élan et d’énergie au fil des jours sont normales.',
            'تقلّبات النشاط والطاقة حاجة عادية في الجسم.',
          ),
          userCheckInQuestion: tr(
            'Are you noticing changes in your daily energy or stamina?',
            'Remarquez-vous un changement dans votre énergie ou endurance quotidienne ?',
            'ملاحظ تغيّر في طاقتك ولا جهدك اليومي؟',
          ),
          supportPlanPrompt: tr(
            'Consider gentle pacing and prioritizing basic nourishment and rest.',
            'Pensez à modérer le rythme et à privilégier repos et alimentation simple.',
            'امشي بنسق خفيف وركّز على الراحة والأكل والماء.',
          ),
          therapistPrompt: null,
          detectedAt: now,
        ),
      );
    }

    // -------------------------------------------------------------------------
    // 3. Multi-Day Observations vs Single Observations (Physical Tension & Anxiety)
    // -------------------------------------------------------------------------
    final highTensionDays = recentTraces.where((t) => (t.physicalTension ?? 0) >= 7).length;
    final highAnxietyDays = recentTraces.where((t) => (t.anxietyLevel ?? 0) >= 7).length;

    if (highTensionDays > 0 || highAnxietyDays > 0) {
      final isMultiDay = highTensionDays >= 2 || highAnxietyDays >= 2;
      final daysCount = highTensionDays > highAnxietyDays ? highTensionDays : highAnxietyDays;
      divergences.add(
        PatternDivergence(
          id: 'div_tension_${now.millisecondsSinceEpoch}',
          category: DivergenceCategory.elevatedTension,
          observationType: isMultiDay ? ObservationType.longitudinalPattern : ObservationType.individualMetricShift,
          title: isMultiDay
              ? tr(
                  'Physical Tension or Stress Noted Across $daysCount Days',
                  'Tension physique ou stress noté sur $daysCount jours',
                  'توتر بدني ولا ضغط تسجّل على $daysCount أيام',
                )
              : tr(
                  'Physical Tension or Stress Noted on a Recent Check-in',
                  'Tension physique ou stress noté sur un bilan récent',
                  'توتر بدني ولا ضغط تسجّل في متابعة قريبة',
                ),
          timeWindow: timeWindow,
          contributingObservations: [
            isMultiDay
                ? tr(
                    'Physical tension or anxiety was rated 7/10 or higher on $daysCount separate recorded days ($highTensionDays tension check-ins, $highAnxietyDays anxiety check-ins).',
                    'Une tension physique ou anxiété ≥ 7/10 a été notée sur $daysCount jours distincts ($highTensionDays tension, $highAnxietyDays anxiété).',
                    'التوتر البدني ولا القلق تفوّق 7/10 في $daysCount أيام مختلفة ($highTensionDays متابعات توتر، $highAnxietyDays متابعات قلق).',
                  )
                : tr(
                    'Physical tension or anxiety was rated 7/10 or higher on a recent check-in.',
                    'Une tension physique ou anxiété ≥ 7/10 a été notée sur un bilan récent.',
                    'التوتر البدني ولا القلق وصل 7/10 أو أكثر في متابعة قريبة.',
                  ),
          ],
          baselineComparison: tr(
            'Tension and stress ratings are higher than your typical resting baseline.',
            'Les niveaux de tension sont plus élevés que votre repère de calme habituel.',
            'درجات التوتر والضغط طالعة على معدّلك المعتاد وقت الراحة.',
          ),
          uncertaintyStatement: tr(
            'Stress responses often reflect external demands or physical fatigue.',
            'Les réactions de tension reflètent souvent des sollicitations externes ou de la fatigue.',
            'ردود الفعل هاذي غالباً تجي من ضغوطات اليوم ولا تعب بدني.',
          ),
          userCheckInQuestion: tr(
            'Are you noticing tightness in your body, shallow breathing, or heightened stress?',
            'Sentez-vous des tensions corporelles, une respiration courte ou plus de pression ?',
            'تحسّ بشدّ في بدنك ولا نفس قصير ولا ضغط زايد؟',
          ),
          supportPlanPrompt: tr(
            'A few minutes of vagal breathing, progressive muscle relaxation, or a quiet walk can help signal safety to your body.',
            'Quelques minutes de respiration lente, de relâchement musculaire ou une marche calme peuvent apaiser le corps.',
            'دقائق تنفّس هادي، إرخاء عضلاتك بشوية، ولا مشية هادية ينجم يطمّن بدنك.',
          ),
          therapistPrompt: null,
          detectedAt: now,
        ),
      );
    }

    return divergences;
  }
}

/// Therapist-ready weekly clinical summary answering Part 7.3.
class WeeklySummaryReport {
  const WeeklySummaryReport({
    required this.weekRange,
    required this.totalEntriesThisWeek,
    required this.whatChangedSummary,
    required this.topSymptoms,
    required this.sleepTrend,
    required this.recurringTriggers,
    required this.divergencePoints,
    required this.suggestedTherapyTopics,
  });

  final String weekRange;
  final int totalEntriesThisWeek;
  final String whatChangedSummary;
  final List<String> topSymptoms;
  final String sleepTrend;
  final List<String> recurringTriggers;
  final List<String> divergencePoints;
  final List<String> suggestedTherapyTopics;

  factory WeeklySummaryReport.generate({
    required List<MindTraceModel> traces,
    required PersonalBaseline baseline,
    AppStrings strings = const AppStrings('en'),
  }) {
    final now = DateTime.now();
    final weekCutoff = now.subtract(const Duration(days: 7));
    final weekTraces = traces.where((t) => t.date.isAfter(weekCutoff)).toList();

    if (weekTraces.isEmpty) {
      return WeeklySummaryReport(
        weekRange: strings.isArabic
            ? 'آخر 7 أيام'
            : (strings.isFrench ? '7 derniers jours' : 'Past 7 days'),
        totalEntriesThisWeek: 0,
        whatChangedSummary: strings.isArabic
            ? 'لم تُسجّل ملاحظات خلال الأيام السبعة الماضية.'
            : (strings.isFrench
                ? 'Aucune observation enregistrée sur les 7 derniers jours.'
                : 'No entries recorded in the past 7 days to evaluate trends.'),
        topSymptoms: const [],
        sleepTrend: strings.baselineNeedsMoreData,
        recurringTriggers: const [],
        divergencePoints: const [],
        suggestedTherapyTopics: [
          strings.isArabic
              ? 'متابعة روتين ملاحظة يومي خفيف دون أي ضغط.'
              : (strings.isFrench
                  ? 'Installer un rythme d’observation court sans pression.'
                  : 'Establish a daily observation routine with 1-minute check-ins.'),
        ],
      );
    }

    final sleepList = weekTraces.map((t) => t.sleepHours).whereType<double>().toList();
    final avgSleepThisWeek = sleepList.isNotEmpty
        ? sleepList.reduce((a, b) => a + b) / sleepList.length
        : baseline.averageSleepHours;

    final avgMoodThisWeek =
        weekTraces.map((t) => t.moodIntensity).reduce((a, b) => a + b) / weekTraces.length;

    // What changed — treat |delta| < 0.1 as "Steady with your baseline" (never "±0.0")
    final baselineMood = baseline.averageMoodIntensity;
    final moodDiff = baselineMood != null ? avgMoodThisWeek - baselineMood : null;

    final baselineSleep = baseline.averageSleepHours;
    final sleepDiff = (avgSleepThisWeek != null && baselineSleep != null)
        ? avgSleepThisWeek - baselineSleep
        : null;

    String whatChanged = strings.isArabic
        ? 'هذا الأسبوع، بلغ متوسط شدة المزاج ${avgMoodThisWeek.toStringAsFixed(1)}/10 '
        : (strings.isFrench
            ? 'Cette semaine, l’intensité moyenne était de ${avgMoodThisWeek.toStringAsFixed(1)}/10 '
            : 'This week, mood intensity averaged ${avgMoodThisWeek.toStringAsFixed(1)}/10 ');
    if (moodDiff != null && baselineMood != null) {
      if (moodDiff.abs() < 0.1) {
        whatChanged += '(${strings.steadyWithBaseline}: ${baselineMood.toStringAsFixed(1)}/10). ';
      } else {
        final signed = '${moodDiff > 0 ? '+' : '-'}${moodDiff.abs().toStringAsFixed(1)}';
        whatChanged += strings.isArabic
            ? '($signed مقارنةً بمرجع ${baselineMood.toStringAsFixed(1)}/10). '
            : (strings.isFrench
                ? '($signed par rapport à votre repère de ${baselineMood.toStringAsFixed(1)}/10). '
                : '($signed points from baseline average of ${baselineMood.toStringAsFixed(1)}/10 across ${baseline.moodObservationCount} entries). ');
      }
    } else {
      whatChanged += strings.isArabic
          ? '(لا يوجد خط مرجعي للمقارنة بعد). '
          : (strings.isFrench
              ? '(repère en cours de calibration). '
              : '(no baseline available for comparison). ');
    }

    String sleepTrendStr;
    if (avgSleepThisWeek == null) {
      sleepTrendStr = strings.isArabic
          ? 'لم تُسجّل ساعات النوم هذا الأسبوع.'
          : (strings.isFrench
              ? 'La durée du sommeil n’a pas été notée cette semaine.'
              : 'Sleep duration was not recorded this week.');
    } else if (sleepDiff != null && baselineSleep != null) {
      final avgStr = '${avgSleepThisWeek.toStringAsFixed(1)}h';
      if (sleepDiff.abs() < 0.1) {
        sleepTrendStr = strings.isArabic
            ? 'متوسط النوم $avgStr/ليلة (${strings.steadyWithBaseline}).'
            : (strings.isFrench
                ? 'Sommeil moyen de $avgStr/nuit (${strings.steadyWithBaseline}).'
                : 'Average sleep was $avgStr/night (${strings.steadyWithBaseline}).');
      } else {
        final amt = '${sleepDiff.abs().toStringAsFixed(1)}h';
        sleepTrendStr = strings.isArabic
            ? 'متوسط النوم $avgStr/ليلة (${sleepDiff > 0 ? 'أعلى بـ' : 'أقل بـ'} $amt مقارنةً بمرجع ${baselineSleep.toStringAsFixed(1)}h).'
            : (strings.isFrench
                ? 'Sommeil moyen de $avgStr/nuit (${sleepDiff > 0 ? 'en hausse de' : 'en baisse de'} $amt vs ${baselineSleep.toStringAsFixed(1)}h).'
                : 'Average sleep was $avgStr/night (${sleepDiff > 0 ? 'up by ' : 'down by '}$amt from typical baseline of ${baselineSleep.toStringAsFixed(1)}h across ${baseline.sleepObservationCount} nights).');
      }
    } else {
      sleepTrendStr = strings.isArabic
          ? 'متوسط النوم ${avgSleepThisWeek.toStringAsFixed(1)}h/ليلة (المرجع قيد المعايرة).'
          : (strings.isFrench
              ? 'Sommeil moyen de ${avgSleepThisWeek.toStringAsFixed(1)}h/nuit (repère en cours).'
              : 'Average sleep was ${avgSleepThisWeek.toStringAsFixed(1)}h/night (no baseline available for comparison).');
    }

    // Top symptoms
    final symCounts = <String, int>{};
    for (final t in weekTraces) {
      final s = t.symptomsAndExperiences;
      if (s != null && s.isNotEmpty) {
        for (final p in s.split(RegExp(r'[,;\n]')).map((x) => x.trim()).where((x) => x.isNotEmpty)) {
          symCounts[p] = (symCounts[p] ?? 0) + 1;
        }
      }
    }
    final topSymptoms = (symCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
        .take(4)
        .map((e) => '${e.key} (${e.value}x)')
        .toList();

    // Topics to discuss with therapist
    final topics = <String>[];
    if (sleepDiff != null && sleepDiff.abs() >= 0.8 && avgSleepThisWeek != null && baseline.averageSleepHours != null) {
      final wSleep = avgSleepThisWeek.toStringAsFixed(1);
      final bSleep = baseline.averageSleepHours!.toStringAsFixed(1);
      topics.add(strings.isArabic
          ? 'مراجعة تغيّرات النوم الأخيرة ($wSleep س/ليلة مقابل $bSleep س في معدّلك).'
          : (strings.isFrench
              ? 'Revoir les écarts récents de sommeil ($wSleep h/nuit contre $bSleep h de repère).'
              : 'Review recent sleep shifts (${wSleep}h/night vs ${bSleep}h baseline).'));
    }
    if (topSymptoms.isNotEmpty) {
      final list = topSymptoms.take(2).join(', ');
      topics.add(strings.isArabic
          ? 'مناقشة التجارب المتكرّرة المسجّلة: $list.'
          : (strings.isFrench
              ? 'Échanger sur les ressentis récurrents notés : $list.'
              : 'Discuss recurring experiences logged: $list.'));
    }
    if (baseline.recurringTriggers.isNotEmpty) {
      final list = baseline.recurringTriggers.take(2).join(', ');
      topics.add(strings.isArabic
          ? 'استكشاف طرق تعامل مريحة مع المحفّزات المتكرّرة: $list.'
          : (strings.isFrench
              ? 'Explorer des stratégies apaisantes pour les déclencheurs fréquents : $list.'
              : 'Explore coping strategies for common triggers: $list.'));
    }
    if (topics.isEmpty) {
      topics.add(strings.isArabic
          ? 'متابعة عامّة لنسق اليوم وتوازن المزاج.'
          : (strings.isFrench
              ? 'Point général sur la régularité du rythme et l’équilibre émotionnel.'
              : 'General check-in on routine consistency and emotional balance.'));
    }

    return WeeklySummaryReport(
      weekRange: strings.isArabic
          ? 'آخر 7 أيام (${weekTraces.length} تسجيلات)'
          : (strings.isFrench
              ? '7 derniers jours (${weekTraces.length} bilans)'
              : 'Past 7 days (${weekTraces.length} check-ins)'),
      totalEntriesThisWeek: weekTraces.length,
      whatChangedSummary: whatChanged,
      topSymptoms: topSymptoms,
      sleepTrend: sleepTrendStr,
      recurringTriggers: baseline.recurringTriggers,
      divergencePoints: const [],
      suggestedTherapyTopics: topics,
    );
  }
}

// Providers
final personalBaselineProvider = Provider<PersonalBaseline>((ref) {
  return ref.watch(mindTraceControllerProvider.select((asyncVal) {
    return PersonalBaseline.fromTraces(asyncVal.value ?? []);
  }));
});

final patternDivergencesProvider = Provider<List<PatternDivergence>>((ref) {
  final strings = ref.watch(appStringsProvider);
  return ref.watch(mindTraceControllerProvider.select((asyncVal) {
    final traces = asyncVal.value ?? [];
    final baseline = PersonalBaseline.fromTraces(traces);
    return PatternAwarenessService.detectDivergences(
      traces: traces,
      baseline: baseline,
      strings: strings,
    );
  }));
});

final weeklySummaryProvider = Provider<WeeklySummaryReport>((ref) {
  final strings = ref.watch(appStringsProvider);
  return ref.watch(mindTraceControllerProvider.select((asyncVal) {
    final traces = asyncVal.value ?? [];
    final baseline = PersonalBaseline.fromTraces(traces);
    return WeeklySummaryReport.generate(
      traces: traces,
      baseline: baseline,
      strings: strings,
    );
  }));
});
