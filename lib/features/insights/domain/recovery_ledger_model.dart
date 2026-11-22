import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/localization/app_strings.dart';
import '../../mind_trace/domain/daily_context_tags.dart';
import '../../mind_trace/domain/mind_trace_model.dart';

/// Empirical, non-diagnostic record of a self-reported action or positive
/// routine context that co-occurred with lower intensity or same-day calming.
@immutable
class ObservedStabilizer {
  const ObservedStabilizer({
    required this.key,
    required this.sourceType,
    required this.totalOccurrences,
    this.highIntensityDays = 0,
    this.sameDayRecoveryDays = 0,
    this.avgSameDayShift,
    this.avgCoOccurringIntensity,
  });

  final String key;

  /// Either `'action'` (from `behavioralResponse`) or `'context'` (from `contextTags`).
  final String sourceType;

  final int totalOccurrences;
  final int highIntensityDays;
  final int sameDayRecoveryDays;

  /// Mean end-of-day shift relative to earlier same-day peak (`last - peak`).
  /// Negative values indicate a downward calming shift later the same day.
  final double? avgSameDayShift;

  /// Mean mood intensity (1–10) across entries where this stabilizer appeared.
  final double? avgCoOccurringIntensity;

  IconData get icon {
    if (sourceType == 'context') {
      return DailyContextTags.byKey(key)?.icon ?? Icons.spa_outlined;
    }
    return switch (key) {
      'walk' => Icons.directions_walk_rounded,
      'quiet_time' => Icons.self_improvement_rounded,
      'breathing' => Icons.air_rounded,
      'talked' => Icons.forum_outlined,
      'rest' => Icons.bedtime_outlined,
      _ => Icons.check_circle_outline_rounded,
    };
  }

  String localizedLabel(AppStrings strings) {
    if (sourceType == 'context') {
      return DailyContextTags.localizedLabel(key, strings);
    }
    return switch (key) {
      'walk' => strings.trackHelpedDisplay('Walk'),
      'quiet_time' => strings.trackHelpedDisplay('Quiet time'),
      'breathing' => strings.trackHelpedDisplay('Breathing'),
      'talked' => strings.trackHelpedDisplay('Talked'),
      'rest' => strings.trackHelpedDisplay('Rest'),
      _ => _capitalize(key),
    };
  }

  static String _capitalize(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return raw;
    return '${trimmed[0].toUpperCase()}${trimmed.substring(1)}';
  }
}

/// Deterministic local Empirical Recovery Ledger computed purely from
/// the user's own intra-day moments, coping actions, and positive routines.
@immutable
class RecoveryLedger {
  const RecoveryLedger({
    this.stabilizers = const [],
    this.multiMomentShiftDays = 0,
    this.averageRecoveryDrop,
  });

  const RecoveryLedger.empty()
      : stabilizers = const [],
        multiMomentShiftDays = 0,
        averageRecoveryDrop = null;

  final List<ObservedStabilizer> stabilizers;
  final int multiMomentShiftDays;
  final double? averageRecoveryDrop;

  bool get hasEvidence => stabilizers.isNotEmpty;

  /// Only supportive routine/protective tags are treated as potential stabilizers.
  /// Stressor markers such as `high_workload` and `late_caffeine_screens` are excluded.
  static const Set<String> positiveContextTagKeys = {
    'routine_kept',
    'sleep_consistent',
    'physical_movement',
    'social_connection',
  };

  factory RecoveryLedger.fromTraces(
    List<MindTraceModel> traces, {
    int windowDays = 30,
  }) {
    if (traces.isEmpty) return const RecoveryLedger.empty();

    final effectiveWindowDays = windowDays.clamp(1, 365);
    var latestDate = traces.first.date;
    for (final t in traces) {
      if (t.date.isAfter(latestDate)) {
        latestDate = t.date;
      }
    }
    final anchorDay = DateTime(latestDate.year, latestDate.month, latestDate.day);
    final earliestIncluded = anchorDay.subtract(
      Duration(days: effectiveWindowDays - 1),
    );
    final exclusiveEnd = anchorDay.add(const Duration(days: 1));

    final scoped = traces
        .where(
          (t) =>
              !t.date.isBefore(earliestIncluded) && t.date.isBefore(exclusiveEnd),
        )
        .toList();
    if (scoped.isEmpty) return const RecoveryLedger.empty();

    // Group all entries per calendar day sorted chronologically.
    final byDay = <String, List<MindTraceModel>>{};
    for (final t in scoped) {
      byDay.putIfAbsent(t.dateKey, () => []).add(t);
    }

    int recoveryShiftDaysCount = 0;
    final overallRecoveryDeltas = <int>[];

    // Per-stabilizer accumulators keyed by "$sourceType::$canonicalKey"
    final occurrencesByKey = <String, int>{};
    final intensitiesByKey = <String, List<int>>{};
    final highDaysByKey = <String, Set<String>>{};
    final recoveryDaysByKey = <String, Set<String>>{};
    final sameDayShiftsByKey = <String, List<int>>{};

    void recordToken({
      required String sourceType,
      required String key,
      required String dayKey,
      required int traceIntensity,
      required int dayPeakIntensity,
      int? sameDayDelta,
    }) {
      final composite = '$sourceType::$key';
      occurrencesByKey[composite] = (occurrencesByKey[composite] ?? 0) + 1;
      if (traceIntensity >= 1 && traceIntensity <= 10) {
        intensitiesByKey.putIfAbsent(composite, () => []).add(traceIntensity);
      }
      if (dayPeakIntensity >= 7) {
        highDaysByKey.putIfAbsent(composite, () => <String>{}).add(dayKey);
      }
      if (sameDayDelta != null) {
        sameDayShiftsByKey.putIfAbsent(composite, () => []).add(sameDayDelta);
        if (sameDayDelta <= -2) {
          recoveryDaysByKey.putIfAbsent(composite, () => <String>{}).add(dayKey);
        }
      }
    }

    for (final entry in byDay.entries) {
      final dayKey = entry.key;
      final dayList = entry.value
        ..sort((a, b) => a.effectiveTimestamp.compareTo(b.effectiveTimestamp));

      final dayPeak = dayList.map((t) => t.moodIntensity).reduce(math.max);

      int? sameDayDelta;
      if (dayList.length >= 2) {
        final earlierPeak = dayList
            .sublist(0, dayList.length - 1)
            .map((t) => t.moodIntensity)
            .reduce(math.max);
        final lastIntensity = dayList.last.moodIntensity;
        final delta = lastIntensity - earlierPeak;
        sameDayDelta = delta;
        if (delta <= -2) {
          recoveryShiftDaysCount++;
          overallRecoveryDeltas.add(delta);
        }
      }

      // Track distinct days cleanly if same token logged multiple times same day,
      // while avoiding double-counting shift deltas per day per stabilizer.
      final seenDayTokensForShift = <String>{};

      for (final trace in dayList) {
        for (final actionKey in _extractActionKeys(trace.behavioralResponse)) {
          final composite = 'action::$actionKey';
          final firstForDay = seenDayTokensForShift.add(composite);
          recordToken(
            sourceType: 'action',
            key: actionKey,
            dayKey: dayKey,
            traceIntensity: trace.moodIntensity,
            dayPeakIntensity: dayPeak,
            sameDayDelta: firstForDay ? sameDayDelta : null,
          );
        }

        for (final rawTag in trace.contextTags) {
          final tag = rawTag.trim();
          if (!positiveContextTagKeys.contains(tag)) continue;
          final composite = 'context::$tag';
          final firstForDay = seenDayTokensForShift.add(composite);
          recordToken(
            sourceType: 'context',
            key: tag,
            dayKey: dayKey,
            traceIntensity: trace.moodIntensity,
            dayPeakIntensity: dayPeak,
            sameDayDelta: firstForDay ? sameDayDelta : null,
          );
        }
      }
    }

    if (occurrencesByKey.isEmpty) {
      return RecoveryLedger(
        stabilizers: const [],
        multiMomentShiftDays: recoveryShiftDaysCount,
        averageRecoveryDrop: _mean(overallRecoveryDeltas),
      );
    }

    final stabilizers = occurrencesByKey.keys.map((composite) {
      final sep = composite.indexOf('::');
      final sourceType = composite.substring(0, sep);
      final key = composite.substring(sep + 2);
      final shifts = sameDayShiftsByKey[composite] ?? const <int>[];
      final intensities = intensitiesByKey[composite] ?? const <int>[];
      return ObservedStabilizer(
        key: key,
        sourceType: sourceType,
        totalOccurrences: occurrencesByKey[composite] ?? 0,
        highIntensityDays: highDaysByKey[composite]?.length ?? 0,
        sameDayRecoveryDays: recoveryDaysByKey[composite]?.length ?? 0,
        avgSameDayShift: _mean(shifts),
        avgCoOccurringIntensity: _mean(intensities),
      );
    }).toList()
      ..sort((a, b) {
        final byRecovery = b.sameDayRecoveryDays.compareTo(a.sameDayRecoveryDays);
        if (byRecovery != 0) return byRecovery;

        final aShift = a.avgSameDayShift ?? 999.0;
        final bShift = b.avgSameDayShift ?? 999.0;
        final byShift = aShift.compareTo(bShift); // more negative first
        if (byShift != 0) return byShift;

        final byOcc = b.totalOccurrences.compareTo(a.totalOccurrences);
        if (byOcc != 0) return byOcc;

        return a.key.compareTo(b.key);
      });

    return RecoveryLedger(
      stabilizers: stabilizers,
      multiMomentShiftDays: recoveryShiftDaysCount,
      averageRecoveryDrop: _mean(overallRecoveryDeltas),
    );
  }

  static List<String> _extractActionKeys(String? rawBehavioralResponse) {
    if (rawBehavioralResponse == null || rawBehavioralResponse.trim().isEmpty) {
      return const [];
    }
    final parts = rawBehavioralResponse
        .split(RegExp(r'[,;\n]+'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty);
    final seen = <String>{};
    final result = <String>[];
    for (final part in parts) {
      final canonical = canonicalizeAction(part);
      if (canonical.isNotEmpty && seen.add(canonical)) {
        result.add(canonical);
      }
    }
    return result;
  }

  /// Maps multilingual quick-select `whatHelped` choices onto stable keys while
  /// normalizing custom responses cleanly.
  static String canonicalizeAction(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    final lower = trimmed.toLowerCase();
    return switch (lower) {
      'walk' || 'marche' || 'مشي' || 'مشي هادئ' => 'walk',
      'quiet time' || 'moment calme' || 'وقت هادئ' => 'quiet_time',
      'breathing' || 'respiration' || 'تنفس' || 'تنفّس' => 'breathing',
      'talked' || 'échange' || 'echange' || 'فضفضة' || 'فضفضة مع قريب' =>
        'talked',
      'rest' || 'repos' || 'راحة' => 'rest',
      _ => lower,
    };
  }

  static double? _mean(List<int> values) {
    if (values.isEmpty) return null;
    final sum = values.fold<int>(0, (acc, v) => acc + v);
    return double.parse((sum / values.length).toStringAsFixed(1));
  }
}
