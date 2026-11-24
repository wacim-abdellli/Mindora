import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/localization/app_strings.dart';
import '../../app/theme/mind_tokens.dart';
import 'mind_pill.dart';

/// Mood-responsive 1-tap phrase chips that optionally compose into any note
/// [TextEditingController] without forcing blank-field typing.
class QuickNoteSparksBar extends StatelessWidget {
  const QuickNoteSparksBar({
    super.key,
    required this.moodKey,
    required this.controller,
    required this.strings,
    this.onChanged,
  });

  final String moodKey;
  final TextEditingController controller;
  final AppStrings strings;
  final VoidCallback? onChanged;

  static List<String> _splitParts(String raw) {
    return raw
        .split(RegExp(r'\s*[·,]\s*'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  void _toggleSpark(String spark) {
    HapticFeedback.selectionClick();
    final parts = _splitParts(controller.text);
    final idx = parts.indexWhere(
      (p) => p.toLowerCase() == spark.toLowerCase(),
    );
    if (idx >= 0) {
      parts.removeAt(idx);
    } else {
      parts.add(spark);
    }
    final nextText = parts.join(' · ');
    controller.value = TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: nextText.length),
    );
    onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final sparks = strings.quickSparksForMood(moodKey);
    if (sparks.isEmpty) return const SizedBox.shrink();

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final activeLower =
            _splitParts(value.text).map((p) => p.toLowerCase()).toSet();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.quickSparksLabel,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: tokens.ink3,
              ),
            ),
            const SizedBox(height: 4),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (int i = 0; i < sparks.length; i++) ...[
                    if (i > 0) const SizedBox(width: 6),
                    MindPill(
                      label: sparks[i],
                      fontSize: 11.5,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 5,
                      ),
                      isSelected: activeLower.contains(sparks[i].toLowerCase()),
                      onTap: () => _toggleSpark(sparks[i]),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
