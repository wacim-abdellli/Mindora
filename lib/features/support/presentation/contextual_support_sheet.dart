import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/router/app_router.dart';
import '../../../app/theme/mind_tokens.dart';
import '../../../core/safety/support_button.dart';
import '../../profile/controllers/profile_controller.dart';
import 'widgets/breathing_exercise_card.dart';
import 'widgets/grounding_exercise_card.dart';
import 'widgets/micro_action_card.dart';
import 'widgets/perspective_exploration_card.dart';
import 'widgets/routine_anchor_card.dart';

enum SupportChoice { settle, grounding, thoughts, action, routine }

/// Contextual Support: Shared Application Capability.
///
/// Accessible from anywhere across Mindora:
/// - Home, Investigator, Inner Observatory, AI Companion
/// - Opens with: "What would help right now?"
/// - 5 Curated choices, options-first, 0 emojis, immediate emergency exit
class ContextualSupportSheet extends ConsumerStatefulWidget {
  const ContextualSupportSheet({super.key, this.initialChoice});

  final SupportChoice? initialChoice;

  /// Global entry point to display Contextual Support from any screen.
  static Future<void> show(
    BuildContext context, {
    SupportChoice? initialChoice,
  }) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ContextualSupportSheet(initialChoice: initialChoice),
    );
  }

  @override
  ConsumerState<ContextualSupportSheet> createState() =>
      _ContextualSupportSheetState();
}

class _ContextualSupportSheetState
    extends ConsumerState<ContextualSupportSheet> {
  SupportChoice? _activeChoice;

  @override
  void initState() {
    super.initState();
    _activeChoice = widget.initialChoice;
  }

  void _selectChoice(SupportChoice choice) {
    HapticFeedback.selectionClick();
    setState(() {
      _activeChoice = choice;
    });
  }

  void _backToMenu() {
    HapticFeedback.selectionClick();
    setState(() {
      _activeChoice = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final strings = ref.watch(appStringsProvider);
    final isAr = strings.isArabic;

    final tokens = context.tokens;
    final bg = tokens.surface;
    final surfaceColor = tokens.surface;
    final borderColor = tokens.line;
    final textPrimary = tokens.ink;
    final textSecondary = tokens.ink2;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(tokens.sheetRadius),
        ),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Drag Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: tokens.lineStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Top Header Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_activeChoice != null)
                    Expanded(
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: InkWell(
                          onTap: _backToMenu,
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isAr
                                      ? Icons.arrow_forward_ios_rounded
                                      : Icons.arrow_back_ios_rounded,
                                  size: 14,
                                  color: textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    isAr
                                        ? 'الخيارات'
                                        : (strings.isFrench
                                            ? 'Choix'
                                            : 'Choices'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: Text(
                        strings.contextualSupportTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: textSecondary,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: strings.closeBtn,
                    icon: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: textSecondary,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, thickness: 1),

            // Main Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: _activeChoice == null
                    ? _buildChoiceMenu(
                        strings,
                        isDark,
                        textPrimary,
                        textSecondary,
                        surfaceColor,
                        borderColor,
                      )
                    : _buildActiveExercise(strings),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceMenu(
    AppStrings strings,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color surfaceColor,
    Color borderColor,
  ) {
    final profile = ref.watch(profileControllerProvider).value;
    final allGoals = [
      ...?profile?.selectedGoals,
      if (profile?.personalGoals.isNotEmpty == true) profile!.personalGoals,
    ].join(' ').toLowerCase();
    final allSymptoms = (profile?.selectedSymptoms ?? [])
        .join(' ')
        .toLowerCase();

    final suggestSettle =
        allGoals.contains('anxiety') ||
        allGoals.contains('somatic') ||
        allSymptoms.contains('apprehension') ||
        allSymptoms.contains('surge');
    final suggestThoughts =
        allGoals.contains('thought') ||
        allGoals.contains('pattern') ||
        allSymptoms.contains('scatter') ||
        allSymptoms.contains('fog');
    final suggestAction =
        allGoals.contains('focus') ||
        allGoals.contains('inertia') ||
        allSymptoms.contains('inertia') ||
        allSymptoms.contains('avoidance');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Opening Invitation
        Text(
          strings.whatWouldHelpPrompt,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          strings.whatWouldHelpSubtitle,
          style: TextStyle(fontSize: 12, color: textSecondary, height: 1.4),
        ),
        const SizedBox(height: 18),

        // Choice 1: Settle Myself
        _buildChoiceTile(
          title: strings.needSettleTitle,
          subtitle: strings.needSettleDesc,
          icon: Icons.air_rounded,
          accentColor: MindTokens.moodCalm,
          isSuggested: suggestSettle,
          onTap: () => _selectChoice(SupportChoice.settle),
          isDark: isDark,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          surfaceColor: surfaceColor,
          borderColor: borderColor,
        ),
        const SizedBox(height: 10),

        // Choice 2: Stuck in Thoughts
        _buildChoiceTile(
          title: strings.needThoughtsTitle,
          subtitle: strings.needThoughtsDesc,
          icon: Icons.psychology_outlined,
          accentColor: MindTokens.moodAnxious,
          isSuggested: suggestThoughts,
          onTap: () => _selectChoice(SupportChoice.thoughts),
          isDark: isDark,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          surfaceColor: surfaceColor,
          borderColor: borderColor,
        ),
        const SizedBox(height: 10),

        // Choice 3: Can't get started
        _buildChoiceTile(
          title: strings.needActionTitle,
          subtitle: strings.needActionDesc,
          icon: Icons.play_circle_outline_rounded,
          accentColor: context.tokens.ink,
          isSuggested: suggestAction,
          onTap: () => _selectChoice(SupportChoice.action),
          isDark: isDark,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          surfaceColor: surfaceColor,
          borderColor: borderColor,
        ),
        const SizedBox(height: 10),

        // Choice 4: Routine Help
        _buildChoiceTile(
          title: strings.needRoutineTitle,
          subtitle: strings.needRoutineDesc,
          icon: Icons.calendar_today_outlined,
          accentColor: context.tokens.ink,
          onTap: () => _selectChoice(SupportChoice.routine),
          isDark: isDark,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          surfaceColor: surfaceColor,
          borderColor: borderColor,
        ),
        const SizedBox(height: 10),

        // Choice 5: Explore Something Else (Navigates to Observatory)
        _buildChoiceTile(
          title: strings.needExploreTitle,
          subtitle: strings.needExploreDesc,
          icon: Icons.explore_outlined,
          accentColor: textSecondary,
          onTap: () {
            Navigator.of(context).pop();
            context.push(AppRouter.observatory);
          },
          isDark: isDark,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          surfaceColor: surfaceColor,
          borderColor: borderColor,
        ),
        const SizedBox(height: 20),

        // Global Crisis Access Button
        Builder(
          builder: (ctx) {
            final sheetTokens = ctx.tokens;
            return Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: sheetTokens.safetySoft,
                borderRadius: BorderRadius.circular(sheetTokens.buttonRadius),
                border: Border.all(
                  color: sheetTokens.safety.withValues(alpha: 0.45),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(sheetTokens.buttonRadius),
                  onTap: () {
                    final rootNav = Navigator.of(ctx, rootNavigator: true);
                    Navigator.of(ctx).pop();
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (rootNav.mounted) {
                        SupportModalSheet.show(rootNav.context);
                      }
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.phone_in_talk_outlined,
                          size: 20,
                          color: sheetTokens.safety,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                strings.needCrisisHelp,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: sheetTokens.safety,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                strings.emergencyCallDirect,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          strings.isArabic
                              ? Icons.arrow_back_ios_rounded
                              : Icons.arrow_forward_ios_rounded,
                          size: 13,
                          color: sheetTokens.safety,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildChoiceTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required Color surfaceColor,
    required Color borderColor,
    bool isSuggested = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(icon, size: 20, color: accentColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                          ),
                          if (isSuggested) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                Localizations.localeOf(context).languageCode == 'ar'
                                    ? 'مقترح'
                                    : (Localizations.localeOf(context).languageCode == 'fr'
                                          ? 'Suggéré'
                                          : 'Suggested'),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: accentColor,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveExercise(AppStrings strings) {
    switch (_activeChoice!) {
      case SupportChoice.settle:
        return BreathingExerciseCard(
          onSwitchToGrounding: () =>
              setState(() => _activeChoice = SupportChoice.grounding),
        );
      case SupportChoice.grounding:
        return GroundingExerciseCard(
          onSwitchToBreathing: () =>
              setState(() => _activeChoice = SupportChoice.settle),
        );
      case SupportChoice.thoughts:
        return const PerspectiveExplorationCard();
      case SupportChoice.action:
        return const MicroActionCard();
      case SupportChoice.routine:
        return const RoutineAnchorCard();
    }
  }
}
