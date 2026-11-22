import 'package:flutter/foundation.dart';

import '../../../app/localization/app_strings.dart';
import '../../investigation/domain/case_model.dart';
import '../../investigation/domain/label_type.dart';
import '../../mind_trace/domain/affect_taxonomy.dart';
import '../../mind_trace/domain/daily_context_tags.dart';
import '../../mind_trace/domain/mind_trace_model.dart';
import 'personal_baseline_model.dart';

/// Calm, non-diagnostic synthesis connecting recurring context/triggers,
/// somatic & affect patterns, dominant cognitive thought chains, and observed
/// stabilizers across a longitudinal window.
///
/// Enforces privacy isolation when [excludePrivateCases] is true (all clinician
/// exports, packets, PDFs, and dossier views).
@immutable
class ForensicLoopLink {
  const ForensicLoopLink({
    this.recurringContextOrTrigger,
    this.somaticAffectPattern,
    this.recurringThoughtTheme,
    this.thoughtLabel,
    this.observedStabilizer,
  });

  final String? recurringContextOrTrigger;
  final String? somaticAffectPattern;
  final String? recurringThoughtTheme;
  final LabelType? thoughtLabel;
  final String? observedStabilizer;

  int get populatedNodeCount {
    var count = 0;
    if (recurringContextOrTrigger != null) count++;
    if (somaticAffectPattern != null) count++;
    if (recurringThoughtTheme != null) count++;
    if (observedStabilizer != null) count++;
    return count;
  }

  /// Require at least two linked nodes before presenting a synthesized loop.
  bool get hasSufficientSignal => populatedNodeCount >= 2;

  /// Synthesizes an observational 4-stage forensic loop without altering data.
  static ForensicLoopLink synthesize({
    required PersonalBaseline baseline,
    required List<CaseModel> cases,
    required AppStrings strings,
    bool excludePrivateCases = false,
    bool includeSomatic = true,
  }) {
    final visibleCases = excludePrivateCases
        ? cases.where((c) => !c.isPrivate).toList(growable: false)
        : cases;

    // 1. Recurring context tag or trigger
    String? triggerNode;
    if (baseline.contextTagCorrelations.isNotEmpty) {
      final sorted = [...baseline.contextTagCorrelations]
        ..sort((a, b) {
          final moodCmp =
              (b.avgMoodIntensity ?? 0).compareTo(a.avgMoodIntensity ?? 0);
          if (moodCmp != 0) return moodCmp;
          return b.occurrences.compareTo(a.occurrences);
        });
      final top = sorted.first;
      final tagLabel = DailyContextTags.localizedLabel(top.tagKey, strings);
      final metrics = <String>['${top.occurrences}x'];
      if (top.avgMoodIntensity != null) {
        metrics.add('${top.avgMoodIntensity!.toStringAsFixed(1)}/10');
      }
      if (includeSomatic && top.avgSleepHours != null) {
        metrics.add('${top.avgSleepHours!.toStringAsFixed(1)}h');
      }
      final joined = metrics.join(' · ');
      triggerNode = strings.isArabic
          ? '$tagLabel \u2066($joined)\u2069'
          : '$tagLabel ($joined)';
    } else if (baseline.recurringTriggers.isNotEmpty) {
      triggerNode = _truncate(baseline.recurringTriggers.first, 64);
    } else {
      for (final c in visibleCases) {
        final t = c.chain?.trigger.trim() ?? '';
        if (t.isNotEmpty) {
          triggerNode = _truncate(t, 64);
          break;
        }
      }
    }

    // 2. Diurnal peak + co-occurring affect + optional somatic cue
    String? affectNode;
    final affectParts = <String>[];
    if (baseline.diurnalIntensityAverages.isNotEmpty) {
      final peak = baseline.diurnalIntensityAverages.entries.reduce(
        (a, b) => a.value >= b.value ? a : b,
      );
      affectParts.add(
        '${_bucketLabel(peak.key, strings)} ${peak.value.toStringAsFixed(1)}/10',
      );
    }
    if (baseline.emotionFrequencyMap.isNotEmpty) {
      final topEmotions = baseline.emotionFrequencyMap.entries
          .take(2)
          .map((e) => AffectTaxonomy.localizedLabel(e.key, strings))
          .join(' + ');
      affectParts.add(topEmotions);
    }
    if (includeSomatic && baseline.averageSleepHours != null) {
      affectParts.add('${baseline.averageSleepHours!.toStringAsFixed(1)}h');
    }
    if (affectParts.isNotEmpty) {
      affectNode = affectParts.join(' · ');
    }

    // 3. Dominant cognitive thought chain from non-private cases
    String? thoughtNode;
    LabelType? labelType;
    final sortedCases = [...visibleCases]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    for (final c in sortedCases) {
      final chain = c.chain;
      if (chain != null && chain.thought.trim().isNotEmpty) {
        thoughtNode = _truncate(chain.thought.trim(), 76);
        labelType = chain.thoughtLabel;
        break;
      }
    }

    // 4. Observed stabilizer from Recovery Ledger
    String? stabilizerNode;
    if (baseline.recoveryLedger.stabilizers.isNotEmpty) {
      final topStab = baseline.recoveryLedger.stabilizers.first;
      final stabLabel = topStab.localizedLabel(strings);
      final stat =
          topStab.avgSameDayShift != null && topStab.avgSameDayShift! < 0
              ? strings.sameDayShiftStat(topStab.avgSameDayShift!)
              : (topStab.avgCoOccurringIntensity != null
                    ? strings.stabilizerAvgMoodStat(
                        topStab.avgCoOccurringIntensity!,
                      )
                    : '${topStab.totalOccurrences}x');
      final metricSpan = '${topStab.totalOccurrences}x · $stat';
      stabilizerNode = strings.isArabic
          ? '$stabLabel \u2066($metricSpan)\u2069'
          : '$stabLabel ($metricSpan)';
    }

    return ForensicLoopLink(
      recurringContextOrTrigger: triggerNode,
      somaticAffectPattern: affectNode,
      recurringThoughtTheme: thoughtNode,
      thoughtLabel: labelType,
      observedStabilizer: stabilizerNode,
    );
  }

  /// Arrow-linked summary suitable for EHR plain text and 1-page A4 PDF notes.
  String compactSummary(AppStrings strings) {
    final segments = <String>[
      if (recurringContextOrTrigger != null)
        '${strings.forensicLoopNodeTrigger}: $recurringContextOrTrigger',
      if (somaticAffectPattern != null)
        '${strings.forensicLoopNodeAffect}: $somaticAffectPattern',
      if (recurringThoughtTheme != null)
        '${strings.forensicLoopNodeThought}'
            '${thoughtLabel != null ? ' [${thoughtLabel!.letter}]' : ''}: '
            '$recurringThoughtTheme',
      if (observedStabilizer != null)
        '${strings.forensicLoopNodeStabilizer}: $observedStabilizer',
    ];
    return segments.join(' -> ');
  }

  static String _bucketLabel(DayTimeBucket bucket, AppStrings strings) {
    return switch (bucket) {
      DayTimeBucket.morning => strings.morningBucketLabel,
      DayTimeBucket.afternoon => strings.afternoonBucketLabel,
      DayTimeBucket.evening => strings.eveningBucketLabel,
      DayTimeBucket.night => strings.nightBucketLabel,
    };
  }

  static String _truncate(String input, int maxChars) {
    final normalized = input.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= maxChars) return normalized;
    return '${normalized.substring(0, maxChars - 1)}…';
  }
}
