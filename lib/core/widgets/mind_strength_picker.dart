import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/lab_theme.dart';
import '../../app/theme/mind_tokens.dart';
import 'mind_pressable.dart';

/// Human 3-level strength picker (`A little` = 3, `Medium` = 6, `A lot` = 9)
/// replacing fatiguing 1–10 numerical sliders while keeping `MindTraceModel`'s
/// 1–10 integer storage 100% backward-compatible.
class MindStrengthPicker extends StatelessWidget {
  const MindStrengthPicker({
    super.key,
    required this.selectedIntensity,
    required this.aLittleLabel,
    required this.mediumLabel,
    required this.aLotLabel,
    required this.onSelected,
    this.accentColor,
  });

  /// Currently stored 1–10 intensity (`null` when user has not picked yet).
  final int? selectedIntensity;
  final String aLittleLabel;
  final String mediumLabel;
  final String aLotLabel;
  final ValueChanged<int> onSelected;
  final Color? accentColor;

  static int bucketToIntensity(int bucket) => switch (bucket) {
    0 => 3,
    1 => 6,
    _ => 9,
  };

  static int? intensityToBucket(int? intensity) {
    if (intensity == null) return null;
    if (intensity <= 4) return 0;
    if (intensity <= 7) return 1;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final textScale = MediaQuery.textScalerOf(context).scale(16.0) / 16.0;
    final activeBucket = intensityToBucket(selectedIntensity);
    final accent = accentColor ?? tokens.primary;

    final options = [
      (bucket: 0, value: 3, label: aLittleLabel, key: 'strength-a-little'),
      (bucket: 1, value: 6, label: mediumLabel, key: 'strength-medium'),
      (bucket: 2, value: 9, label: aLotLabel, key: 'strength-a-lot'),
    ];

    Widget buildButton(
      ({int bucket, int value, String label, String key}) opt,
    ) {
      final selected = activeBucket == opt.bucket;
      final bg = selected ? tokens.primary : tokens.surface;
      final fg = selected ? tokens.onPrimary : tokens.ink;
      final borderColor = selected ? tokens.primary : tokens.lineStrong;

      return Semantics(
        button: true,
        selected: selected,
        label: opt.label,
        child: MindPressable(
          key: ValueKey<String>(opt.key),
          onPressed: () {
            HapticFeedback.selectionClick();
            onSelected(opt.value);
          },
          borderRadius: BorderRadius.circular(tokens.buttonRadius),
          child: AnimatedContainer(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            constraints: const BoxConstraints(minHeight: 56, minWidth: 72),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(tokens.buttonRadius),
              border: Border.all(
                color: selected ? accent : borderColor,
                width: selected ? 2.0 : 1.2,
              ),
              boxShadow: selected ? tokens.primaryButtonShadows : const [],
            ),
            child: Text(
              opt.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: LabTheme.fontFamily,
                fontFamilyFallback: LabTheme.fontFallback,
                fontSize: 15.5,
                height: 1.2,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final stackVertically = constraints.maxWidth < 310 || textScale > 1.3;
        if (stackVertically) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < options.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                buildButton(options[i]),
              ],
            ],
          );
        }
        return Row(
          children: [
            for (int i = 0; i < options.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(child: buildButton(options[i])),
            ],
          ],
        );
      },
    );
  }
}
