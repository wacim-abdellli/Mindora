import 'package:flutter/material.dart';

import '../../app/localization/app_strings.dart';
import '../../app/theme/lab_theme.dart';
import '../../app/theme/mind_tokens.dart';
import '../widgets/mind_button.dart';
import 'crisis_keywords.dart';
import 'support_button.dart';

/// Two-Layer Safety Coordinator for Mindora.
///
/// Layer 1: Offline local keyword scan (zero AI required).
/// Layer 2: Model safetyLevel evaluation.
/// Rule: The HIGHEST safety level always wins.
class SafetyInterceptor {
  /// Evaluates user text and AI output to determine the winning safety level.
  static int resolveSafetyLevel({
    required String userText,
    required int aiSafetyLevel,
  }) {
    final layer1Level = CrisisKeywords.evaluateText(userText);
    return layer1Level > aiSafetyLevel ? layer1Level : aiSafetyLevel;
  }

  /// Displays the Level 2 Gentle Pause dialog with warm, Grade-4 human clarity
  /// and 1-tap Tunisian emergency support (80 10 50 50, 190, 198).
  static void showCrisisPauseDialog(BuildContext context) {
    final tokens = context.tokens;
    final strings = AppStrings.of(context);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: tokens.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: tokens.line, width: 1),
        ),
        title: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: tokens.safetySoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.shield_outlined,
                color: tokens.safety,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                strings.crisisPauseHumanTitle,
                style: LabTheme.textStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: tokens.ink,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                strings.crisisPauseBody,
                style: LabTheme.textStyle(
                  fontSize: 15.5,
                  height: 1.5,
                  color: tokens.ink2,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: tokens.safetySoft,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: tokens.safety.withValues(alpha: 0.30),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.greenLineTitle,
                      style: LabTheme.textStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        color: tokens.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      strings.greenLineSubtitle,
                      style: LabTheme.textStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: tokens.safety,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              MindButton(
                text: strings.viewSupportResourcesBtn,
                leadingIcon: Icons.phone_in_talk_rounded,
                variant: MindButtonVariant.danger,
                isFullWidth: true,
                onPressed: () {
                  Navigator.of(ctx).pop();
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    useRootNavigator: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const SupportModalSheet(),
                  );
                },
              ),
              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    foregroundColor: tokens.ink2,
                  ),
                  child: Text(
                    strings.iAmSafeNowBtn,
                    style: LabTheme.textStyle(
                      color: tokens.ink2,
                      fontWeight: FontWeight.w600,
                      fontSize: 14.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
