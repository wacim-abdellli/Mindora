import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/theme/mind_tokens.dart';
import '../../../../core/widgets/mind_pressable.dart';
import '../../../mind_trace/controllers/mind_trace_controller.dart';
import '../../../mind_trace/domain/mind_trace_model.dart';

enum _ReliefChoice { calmer, slight, notYet }

/// Zero-pressure 1-tap check-in rendered after a calming exercise (Box Breathing
/// or 5-4-3-2-1 Grounding).
///
/// When the user reports that tension softened (`Calmer now` or `A little`),
/// records a lightweight follow-up trace tagged with [exerciseActionKey] so
/// `RecoveryLedger` and Insights automatically learn which calming resets truly
/// help this person. When `Not yet` is tapped, validates calmly without logging
/// a false stabilizer and offers a 1-tap switch to an alternative tool.
class ReliefMicroCheckCard extends ConsumerStatefulWidget {
  const ReliefMicroCheckCard({
    super.key,
    required this.exerciseActionKey,
    this.alternativeLabel,
    this.onTryAlternative,
  });

  /// Canonical stabilizer label (e.g. `'Breathing'` or `'Grounding'`).
  final String exerciseActionKey;
  final String? alternativeLabel;
  final VoidCallback? onTryAlternative;

  @override
  ConsumerState<ReliefMicroCheckCard> createState() =>
      _ReliefMicroCheckCardState();
}

class _ReliefMicroCheckCardState extends ConsumerState<ReliefMicroCheckCard> {
  _ReliefChoice? _selected;
  bool _isSaving = false;

  Future<void> _recordRelief(_ReliefChoice choice) async {
    if (_isSaving || _selected != null) return;
    HapticFeedback.selectionClick();

    if (choice == _ReliefChoice.notYet) {
      setState(() => _selected = choice);
      return;
    }

    setState(() {
      _selected = choice;
      _isSaving = true;
    });

    try {
      final latest = ref.read(todayTraceProvider);
      final now = DateTime.now();
      final traceDate = (latest != null && !now.isAfter(latest.date))
          ? latest.date.add(const Duration(minutes: 1))
          : now;
      final drop = choice == _ReliefChoice.calmer ? 2 : 1;
      final baselineIntensity = latest?.moodIntensity ?? 5;
      final nextIntensity = (baselineIntensity - drop).clamp(2, 10);
      final nextMood = choice == _ReliefChoice.calmer
          ? 'calm'
          : (latest?.overallMood ?? 'calm');

      final trace = MindTraceModel(
        id: 'relief_${traceDate.microsecondsSinceEpoch}',
        date: traceDate,
        overallMood: nextMood,
        selectedEmotions: [nextMood],
        moodIntensity: nextIntensity,
        energyLevel: latest?.energyLevel ?? 5,
        anxietyLevel: latest?.anxietyLevel != null
            ? (latest!.anxietyLevel! - drop).clamp(1, 10)
            : 3,
        sleepHours: latest?.sleepHours ?? 7.5,
        behavioralResponse: widget.exerciseActionKey,
        createdAt: traceDate,
        updatedAt: traceDate,
      );

      await ref
          .read(mindTraceControllerProvider.notifier)
          .recordCheckIn(trace, generateAi: false);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final strings = ref.watch(appStringsProvider);

    return Container(
      key: const ValueKey('relief-micro-check-card'),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.surface2,
        borderRadius: BorderRadius.circular(tokens.rowRadius),
        border: Border.all(color: tokens.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_selected == null) ...[
            Text(
              strings.reliefCheckQuestion,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: tokens.ink,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildOptionPill(
                  key: const ValueKey('relief-check-calmer'),
                  tokens: tokens,
                  icon: Icons.check_circle_outline_rounded,
                  label: strings.reliefCheckCalmer,
                  accent: MindTokens.moodCalm,
                  onPressed: () => _recordRelief(_ReliefChoice.calmer),
                ),
                _buildOptionPill(
                  key: const ValueKey('relief-check-slight'),
                  tokens: tokens,
                  icon: Icons.trending_down_rounded,
                  label: strings.reliefCheckSlightly,
                  accent: tokens.m1,
                  onPressed: () => _recordRelief(_ReliefChoice.slight),
                ),
                _buildOptionPill(
                  key: const ValueKey('relief-check-not-yet'),
                  tokens: tokens,
                  icon: Icons.refresh_rounded,
                  label: strings.reliefCheckNotYet,
                  accent: tokens.ink2,
                  onPressed: () => _recordRelief(_ReliefChoice.notYet),
                ),
              ],
            ),
          ] else if (_selected == _ReliefChoice.notYet) ...[
            Text(
              strings.reliefNotYetAck,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                height: 1.4,
                color: tokens.ink2,
              ),
            ),
            if (widget.onTryAlternative != null &&
                widget.alternativeLabel != null) ...[
              const SizedBox(height: 10),
              MindPressable(
                key: const ValueKey('relief-try-alternative-btn'),
                semanticLabel:
                    strings.reliefTryAlternativeBtn(widget.alternativeLabel!),
                borderRadius: BorderRadius.circular(tokens.chipRadius),
                onPressed: widget.onTryAlternative,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 44),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: tokens.surface,
                    borderRadius: BorderRadius.circular(tokens.chipRadius),
                    border: Border.all(color: tokens.m1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.swap_horiz_rounded,
                        size: 15,
                        color: tokens.m1,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          strings.reliefTryAlternativeBtn(
                            widget.alternativeLabel!,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: tokens.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ] else ...[
            Row(
              key: const ValueKey('relief-logged-confirmation'),
              children: [
                Icon(
                  Icons.verified_outlined,
                  size: 16,
                  color: MindTokens.moodCalm,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    strings.reliefLoggedConfirm,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: tokens.ink,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOptionPill({
    required Key key,
    required MindTokens tokens,
    required IconData icon,
    required String label,
    required Color accent,
    required VoidCallback onPressed,
  }) {
    return MindPressable(
      key: key,
      semanticLabel: label,
      borderRadius: BorderRadius.circular(tokens.chipRadius),
      onPressed: _isSaving ? null : onPressed,
      child: Container(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(tokens.chipRadius),
          border: Border.all(color: tokens.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: accent),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: tokens.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
