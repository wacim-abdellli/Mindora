import 'package:flutter/foundation.dart';

import '../../insights/domain/personal_baseline_model.dart';
import '../../mind_trace/domain/mind_trace_model.dart';
import 'clinician_models.dart';

/// Consent-aware clinical delta comparing a patient's previously synced
/// consultation snapshot with their current packet.
@immutable
class VisitComparisonDiff {
  const VisitComparisonDiff({
    required this.previousGeneratedAt,
    required this.currentGeneratedAt,
    required this.daysBetween,
    this.moodDelta,
    this.sleepDelta,
    this.energyDelta,
    this.anxietyDelta,
    this.eveningIntensityDelta,
    this.addedContextTags = const [],
    this.reducedContextTags = const [],
    this.focusPlanFeedback = '',
  });

  final DateTime previousGeneratedAt;
  final DateTime currentGeneratedAt;
  final int daysBetween;
  final double? moodDelta;
  final double? sleepDelta;
  final double? energyDelta;
  final double? anxietyDelta;
  final double? eveningIntensityDelta;
  final List<String> addedContextTags;
  final List<String> reducedContextTags;
  final String focusPlanFeedback;

  bool get hasMetricDelta =>
      moodDelta != null ||
      sleepDelta != null ||
      energyDelta != null ||
      anxietyDelta != null ||
      eveningIntensityDelta != null;

  factory VisitComparisonDiff.compute(
    ClinicianSyncPacket previous,
    ClinicianSyncPacket current,
  ) {
    final prevDay = DateTime(
      previous.generatedAt.year,
      previous.generatedAt.month,
      previous.generatedAt.day,
    );
    final curDay = DateTime(
      current.generatedAt.year,
      current.generatedAt.month,
      current.generatedAt.day,
    );
    final daysBetween = curDay.difference(prevDay).inDays.abs();

    final allowMood = previous.consentScope.includeMoodMetrics &&
        current.consentScope.includeMoodMetrics;
    final allowSomatic = allowMood &&
        previous.consentScope.includeSleepEnergyAnxiety &&
        current.consentScope.includeSleepEnergyAnxiety;

    final prevBase = PersonalBaseline.fromTraces(
      previous.traces,
      baselineDays: previous.consentScope.windowDays.clamp(1, 365),
      referenceDate: previous.generatedAt,
    );
    final curBase = PersonalBaseline.fromTraces(
      current.traces,
      baselineDays: current.consentScope.windowDays.clamp(1, 365),
      referenceDate: current.generatedAt,
    );

    double? diffOf(double? prev, double? cur) {
      if (prev == null || cur == null) return null;
      return double.parse((cur - prev).toStringAsFixed(1));
    }

    final moodDelta = allowMood
        ? diffOf(prevBase.averageMoodIntensity, curBase.averageMoodIntensity)
        : null;
    final sleepDelta = allowSomatic
        ? diffOf(prevBase.averageSleepHours, curBase.averageSleepHours)
        : null;
    final energyDelta = allowSomatic
        ? diffOf(prevBase.averageEnergyLevel, curBase.averageEnergyLevel)
        : null;
    final anxietyDelta = allowSomatic
        ? diffOf(prevBase.averageAnxietyLevel, curBase.averageAnxietyLevel)
        : null;

    final eveningIntensityDelta = allowMood
        ? diffOf(
            prevBase.diurnalIntensityAverages[DayTimeBucket.evening],
            curBase.diurnalIntensityAverages[DayTimeBucket.evening],
          )
        : null;

    final addedTags = <String>[];
    final reducedTags = <String>[];
    if (allowSomatic) {
      final prevKeys =
          prevBase.contextTagCorrelations.map((c) => c.tagKey).toSet();
      final curKeys =
          curBase.contextTagCorrelations.map((c) => c.tagKey).toSet();
      for (final k in curKeys) {
        if (!prevKeys.contains(k)) addedTags.add(k);
      }
      for (final k in prevKeys) {
        if (!curKeys.contains(k)) reducedTags.add(k);
      }
      addedTags.sort();
      reducedTags.sort();
    }

    final feedback = current.consentScope.includePreVisitAgenda
        ? (current.preVisitAgenda?.focusPlanFeedback.trim() ?? '')
        : '';

    return VisitComparisonDiff(
      previousGeneratedAt: previous.generatedAt,
      currentGeneratedAt: current.generatedAt,
      daysBetween: daysBetween,
      moodDelta: moodDelta,
      sleepDelta: sleepDelta,
      energyDelta: energyDelta,
      anxietyDelta: anxietyDelta,
      eveningIntensityDelta: eveningIntensityDelta,
      addedContextTags: addedTags,
      reducedContextTags: reducedTags,
      focusPlanFeedback: feedback,
    );
  }
}
