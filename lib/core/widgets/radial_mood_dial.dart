import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/lab_theme.dart';
import '../../app/theme/mind_tokens.dart';
import 'mind_pressable.dart';

class MoodItem {
  const MoodItem({required this.key, required this.label, required this.icon});

  final String key;
  final String label;
  final IconData icon;
}

/// Radial Mood Selector Dial driven strictly by [MindTokens].
class RadialMoodDial extends StatelessWidget {
  const RadialMoodDial({
    super.key,
    required this.moods,
    required this.selectedIndex,
    required this.onChanged,
    this.showActiveLabel = true,
  });

  final List<MoodItem> moods;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final bool showActiveLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final activeMood = moods[selectedIndex.clamp(0, moods.length - 1)];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 180,
          width: double.infinity,
          child: Stack(
            alignment: Alignment.center,
            children: [
              ExcludeSemantics(
                child: RepaintBoundary(
                  child: CustomPaint(
                    size: const Size(260, 180),
                    painter: _RadialRipplesPainter(ringColor: tokens.lineStrong),
                  ),
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(moods.length, (index) {
                    final isSelected = index == selectedIndex;
                    final item = moods[index];

                    if (isSelected) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Semantics(
                          button: true,
                          selected: true,
                          label: activeMood.label,
                          child: Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: tokens.m1,
                              boxShadow: tokens.glow > 0
                                  ? [
                                      BoxShadow(
                                        color: tokens.m1.withValues(
                                          alpha: 0.35,
                                        ),
                                        blurRadius: 18,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : const <BoxShadow>[],
                            ),
                            child: ExcludeSemantics(
                              child: Icon(
                                item.icon,
                                size: 38,
                                color: tokens.onMood,
                              ),
                            ),
                          ),
                        ),
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: MindPressable(
                        semanticLabel: item.label,
                        borderRadius: BorderRadius.circular(24),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          onChanged(index);
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: tokens.surface2,
                            border: Border.all(color: tokens.line, width: 1.0),
                          ),
                          child: ExcludeSemantics(
                            child: Icon(
                              item.icon,
                              size: 22,
                              color: tokens.ink2,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
        if (showActiveLabel) ...[
          const SizedBox(height: 12),
          Text(
            activeMood.label,
            style: TextStyle(
              fontFamily: LabTheme.fontFamily,
              fontFamilyFallback: LabTheme.fontFallback,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: tokens.ink,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ],
    );
  }
}

class _RadialRipplesPainter extends CustomPainter {
  const _RadialRipplesPainter({required this.ringColor});

  final Color ringColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const rings = [48.0, 72.0, 100.0, 130.0];
    const alphas = [0.65, 0.45, 0.28, 0.14];

    for (int i = 0; i < rings.length; i++) {
      ringPaint.color = ringColor.withValues(alpha: alphas[i]);
      canvas.drawCircle(center, rings[i], ringPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadialRipplesPainter oldDelegate) =>
      oldDelegate.ringColor != ringColor;
}
