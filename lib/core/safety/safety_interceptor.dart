import 'package:flutter/material.dart';
import '../../app/localization/app_strings.dart';
import '../../app/theme/mind_tokens.dart';
import 'crisis_keywords.dart';
import 'support_button.dart';

/// Two-Layer Safety Coordinator for Mindora.
///
/// Section 6 & Step 8.6:
/// Layer 1: Offline local keyword scan (zero AI required).
/// Layer 2: Model safetyLevel evaluation.
/// Rule: The HIGHEST safety level always wins.
class SafetyInterceptor {
  /// Evaluates user text and AI output to determine the winning safety level.
  ///
  /// Returns:
  /// - 0: Normal investigation proceeds as usual.
  /// - 1: Soft redirect (supportive tone, fewer hypotheses, shorter questions).
  /// - 2: Gentle pause (stop analysis, show warmth and crisis resources).
  static int resolveSafetyLevel({
    required String userText,
    required int aiSafetyLevel,
  }) {
    final layer1Level = CrisisKeywords.evaluateText(userText);
    // Highest level wins
    return layer1Level > aiSafetyLevel ? layer1Level : aiSafetyLevel;
  }

  /// Displays the Level 2 Gentle Pause dialog.
  ///
  /// Dual-theme sanctuary dialog: warm charcoal dark / sunlit linen light,
  /// hairline borders, outline vector shield icon, non-dismissible barrier.
  static void showCrisisPauseDialog(BuildContext context) {
    final tokens = context.tokens;
    final strings = AppStrings.of(context);

    final dialogBg = tokens.surface;
    final borderColor = tokens.line;
    final surfaceSubtle = tokens.surface2;
    final textPrimary = tokens.ink;
    final textSecondary = tokens.ink2;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: borderColor, width: 1),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: tokens.safetySoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.shield_outlined,
                color: tokens.safety,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                strings.crisisPauseTitle,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.crisisPauseBody,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.45,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: surfaceSubtle,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.greenLineTitle,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    strings.greenLineSubtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: tokens.m1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              strings.returnToCaseBtn,
              style: TextStyle(
                color: textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: tokens.safety,
              foregroundColor: tokens.bg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.shield_outlined, size: 15),
            label: Text(
              strings.viewSupportResourcesBtn,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const SupportModalSheet(),
              );
            },
          ),
        ],
      ),
    );
  }
}
