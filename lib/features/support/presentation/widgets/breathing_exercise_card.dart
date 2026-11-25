import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/theme/lab_theme.dart';
import '../../../../app/theme/mind_tokens.dart';
import '../../../../core/widgets/mind_button.dart';
import '../../../investigation/presentation/widgets/vagal_breathing_visualizer.dart';
import 'relief_micro_check_card.dart';

/// Authoritative Box Breathing Pacer card:
/// - 4-4-4-4 vagal regulation rhythm
/// - Immediate Start, Pause, and Reset controls
/// - Zero fixed repetition penalty; stop anytime
/// - One-tap switch to Sensory Grounding alternative
class BreathingExerciseCard extends ConsumerStatefulWidget {
  const BreathingExerciseCard({
    super.key,
    required this.onSwitchToGrounding,
  });

  final VoidCallback onSwitchToGrounding;

  @override
  ConsumerState<BreathingExerciseCard> createState() =>
      _BreathingExerciseCardState();
}

class _BreathingExerciseCardState extends ConsumerState<BreathingExerciseCard> {
  bool _isActive = false;
  bool _hasCompletedAttempt = false;
  int _secondsLeft = 4;
  int _phase = 0; // 0: Inhale (4s), 1: Hold (4s), 2: Exhale (4s), 3: Hold (4s)
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleBreathing() {
    HapticFeedback.lightImpact();
    if (_isActive) {
      _stopBreathing();
    } else {
      _startBreathing();
    }
  }

  void _startBreathing() {
    setState(() {
      _isActive = true;
      _hasCompletedAttempt = true;
      _secondsLeft = 4;
      _phase = 0;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_secondsLeft > 1) {
          _secondsLeft--;
        } else {
          _secondsLeft = 4;
          _phase = (_phase + 1) % 4;
          if (_phase == 0) {
            HapticFeedback.mediumImpact();
          } else {
            HapticFeedback.selectionClick();
          }
        }
      });
    });
  }

  void _stopBreathing() {
    _timer?.cancel();
    setState(() {
      _isActive = false;
      _secondsLeft = 4;
      _phase = 0;
    });
  }

  String _getPhaseText(int phase, AppStrings strings) {
    return switch (phase) {
      0 => strings.breatheInCue,
      1 => strings.holdCue,
      2 => strings.breatheOutCue,
      _ => strings.restCue,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final strings = ref.watch(appStringsProvider);

    final tokens = context.tokens;
    final surfaceColor = tokens.surface;
    final borderColor = tokens.line;
    final textPrimary = tokens.ink;
    final textSecondary = tokens.ink2;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  strings.breathingTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: LabTheme.textStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    onPressed: widget.onSwitchToGrounding,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      foregroundColor: tokens.primary,
                    ),
                    child: Text(
                      strings.sensoryGroundingTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: LabTheme.textStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: tokens.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isActive) ...[
            VagalBreathingVisualizer(
              phase: _phase,
              secondsLeft: _secondsLeft,
              phaseText: _getPhaseText(_phase, strings),
              isDark: isDark,
            ),
            const SizedBox(height: 16),
          ] else ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: tokens.cardTintFor(tokens.m1),
                      border: Border.all(
                        color: tokens.line,
                      ),
                    ),
                    child: Icon(
                      Icons.air_rounded,
                      color: tokens.m1,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    strings.breathingDesc,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          MindButton(
            text: _isActive ? strings.stopBtn : strings.breatheQuickBtn,
            variant: _isActive
                ? MindButtonVariant.secondary
                : MindButtonVariant.primary,
            isFullWidth: true,
            onPressed: _toggleBreathing,
          ),
          if (_hasCompletedAttempt && !_isActive) ...[
            const SizedBox(height: 14),
            ReliefMicroCheckCard(
              exerciseActionKey: 'Breathing',
              alternativeLabel: strings.sensoryGroundingTitle,
              onTryAlternative: widget.onSwitchToGrounding,
            ),
          ],
        ],
      ),
    );
  }
}
