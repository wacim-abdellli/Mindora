import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/theme/mind_tokens.dart';
import '../../../../core/widgets/mind_badge.dart';
import '../../../../core/widgets/mind_button.dart';
import '../../../../core/widgets/mind_card.dart';
import '../../../../core/widgets/mind_pressable.dart';
import '../../../clinician/domain/post_visit_focus_model.dart';

/// Displays an active, patient-controllable between-session focus plan agreed
/// with the psychiatrist on the Home screen.
class HomePostVisitFocusCard extends ConsumerWidget {
  const HomePostVisitFocusCard({
    super.key,
    required this.plan,
    required this.onToggleItem,
    required this.onDismiss,
    this.onPrepareVisit,
  });

  final PostVisitFocusPlan plan;
  final ValueChanged<String> onToggleItem;
  final VoidCallback onDismiss;
  final VoidCallback? onPrepareVisit;

  String? _followUpLabel(AppStrings strings) {
    final followUp = plan.followUpDate;
    if (followUp == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(followUp.year, followUp.month, followUp.day);
    final diff = target.difference(today).inDays;
    if (diff <= 0) return strings.followUpTodayBadge;
    return strings.followUpInDaysBadge(diff);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final strings = ref.watch(appStringsProvider);
    final followUpBadge = _followUpLabel(strings);

    return MindCard(
      variant: MindCardVariant.tint,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.event_available_outlined,
                  size: 18,
                  color: tokens.m1,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.betweenSessionFocusTitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: strings.isArabic ? 0 : 0.2,
                        color: tokens.ink2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      strings.fromClinicianByline(plan.clinicianName),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: tokens.ink,
                      ),
                    ),
                  ],
                ),
              ),
              Semantics(
                button: true,
                label: strings.dismissFocusBtn,
                child: IconButton(
                  tooltip: strings.dismissFocusBtn,
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: tokens.ink2,
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onDismiss();
                  },
                ),
              ),
            ],
          ),
          if (followUpBadge != null) ...[
            const SizedBox(height: 6),
            MindBadge(
              icon: Icons.calendar_today_outlined,
              label: followUpBadge,
            ),
          ],
          if (plan.focusItems.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...plan.focusItems.map(
              (item) => Semantics(
                button: true,
                checked: item.isCompleted,
                label: item.title,
                child: MindPressable(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    onToggleItem(item.id);
                  },
                  borderRadius: BorderRadius.circular(tokens.chipRadius),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item.isCompleted
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            size: 20,
                            color: item.isCompleted ? tokens.m1 : tokens.ink2,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item.title,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: item.isCompleted
                                    ? FontWeight.w500
                                    : FontWeight.w600,
                                color: item.isCompleted
                                    ? tokens.ink2
                                    : tokens.ink,
                                decoration: item.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (plan.observationCue.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: tokens.surface2,
                borderRadius: BorderRadius.circular(tokens.chipRadius),
                border: Border.all(color: tokens.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.observationCueBadge,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: tokens.ink2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    plan.observationCue.trim(),
                    style: TextStyle(
                      fontSize: 12.5,
                      color: tokens.ink,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (onPrepareVisit != null) ...[
            const SizedBox(height: 12),
            MindButton(
              text: strings.prepareForVisitBtn,
              leadingIcon: Icons.assignment_outlined,
              variant: MindButtonVariant.soft,
              isFullWidth: true,
              onPressed: onPrepareVisit,
            ),
          ],
        ],
      ),
    );
  }
}
