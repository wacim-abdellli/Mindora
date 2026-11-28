import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/theme/mind_tokens.dart';
import '../../../../core/widgets/mind_badge.dart';
import '../../../../core/widgets/mind_button.dart';
import '../../../../core/widgets/mind_card.dart';
import '../../../../core/widgets/mind_pill.dart';
import '../../../insights/domain/personal_baseline_model.dart';
import '../../../mind_trace/controllers/mind_trace_controller.dart';
import '../../controllers/clinician_providers.dart';
import 'share_with_psychiatrist_sheet.dart';

/// Two-minute, options-first Patient Pre-Visit Consultation Brief.
///
/// Synthesizes period highlights, between-session focus completion, and
/// consultation priorities before handing off into [ShareWithPsychiatristSheet].
class PreVisitBriefSheet extends ConsumerStatefulWidget {
  const PreVisitBriefSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PreVisitBriefSheet(),
    );
  }

  @override
  ConsumerState<PreVisitBriefSheet> createState() =>
      _PreVisitBriefSheetState();
}

class _PreVisitBriefSheetState extends ConsumerState<PreVisitBriefSheet> {
  final Set<String> _selectedTopics = <String>{};
  final TextEditingController _questionController = TextEditingController();
  String _focusFeedback = '';

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  List<String> _topicOptions(AppStrings strings) => [
        strings.preVisitTopicSleep,
        strings.preVisitTopicEveningDips,
        strings.preVisitTopicWorkStrain,
        strings.preVisitTopicTreatmentQuestions,
        strings.preVisitTopicThoughtLoops,
        strings.preVisitTopicCopingReview,
      ];

  void _continueToShare(BuildContext context) {
    HapticFeedback.mediumImpact();
    final topics = _selectedTopics.toList(growable: false);
    final question = _questionController.text.trim();
    final feedback = _focusFeedback.trim();
    final navigator = Navigator.of(context);
    final parentContext = navigator.context;
    navigator.pop();
    ShareWithPsychiatristSheet.show(
      parentContext,
      initialTopics: topics,
      initialQuestion: question,
      initialFocusFeedback: feedback,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final strings = ref.watch(appStringsProvider);
    final traces = ref.watch(mindTraceControllerProvider).value ?? const [];
    final baseline = PersonalBaseline.fromTraces(traces, baselineDays: 30);
    final activeFocus = ref.watch(postVisitFocusControllerProvider).value;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    final stabilizers = baseline.recoveryLedger.stabilizers.take(2).toList();
    final feedbackChoices = [
      strings.focusFeedbackHelpful,
      strings.focusFeedbackTooHeavy,
      strings.focusFeedbackAdjust,
    ];

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.90,
      ),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(tokens.sheetRadius),
        ),
        border: Border(top: BorderSide(color: tokens.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: tokens.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      size: 20,
                      color: tokens.m1,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.preVisitBriefTitle,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: tokens.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            strings.preVisitBriefSubtitle,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: tokens.ink2,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip:
                          MaterialLocalizations.of(context).closeButtonTooltip,
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close_rounded, color: tokens.ink2),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: tokens.line),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Period Snapshot Highlights
                      MindCard(
                        variant: MindCardVariant.flat,
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                MindBadge(
                                  icon: Icons.calendar_today_outlined,
                                  label: strings.daysWindowLabel(
                                    baseline.totalRecordedDays,
                                  ),
                                ),
                                if (baseline.averageMoodIntensity != null)
                                  MindBadge(
                                    label:
                                        '${strings.metricMoodLabel}: ${baseline.averageMoodIntensity!.toStringAsFixed(1)}/10',
                                  ),
                                if (baseline.averageSleepHours != null)
                                  MindBadge(
                                    label:
                                        '${strings.metricSleepLabel}: ${baseline.averageSleepHours!.toStringAsFixed(1)}h',
                                  ),
                              ],
                            ),
                            if (stabilizers.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                '${strings.observedStabilizersTitle}: '
                                '${stabilizers.map((s) => s.localizedLabel(strings)).join(', ')}',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: tokens.ink2,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // 2. Active Focus Plan Review (Options-first feedback)
                      if (activeFocus != null && !activeFocus.isDismissed) ...[
                        const SizedBox(height: 16),
                        Text(
                          strings.focusPlanProgressLabel,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: tokens.ink2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        MindCard(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                strings.focusCompletedCountLabel(
                                  activeFocus.focusItems
                                      .where((i) => i.isCompleted)
                                      .length,
                                  activeFocus.focusItems.length,
                                ),
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: tokens.ink,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: feedbackChoices.map((choice) {
                                  final selected = _focusFeedback == choice;
                                  return MindPill(
                                    label: choice,
                                    isSelected: selected,
                                    onTap: () => setState(() {
                                      _focusFeedback = selected ? '' : choice;
                                    }),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // 3. Visit Priorities & Optional Question
                      Text(
                        strings.preVisitTopicsLabel,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: tokens.ink2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _topicOptions(strings).map((topic) {
                          final selected = _selectedTopics.contains(topic);
                          return MindPill(
                            label: topic,
                            isSelected: selected,
                            onTap: () => setState(() {
                              if (selected) {
                                _selectedTopics.remove(topic);
                              } else {
                                _selectedTopics.add(topic);
                              }
                            }),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _questionController,
                        maxLines: 2,
                        style: TextStyle(fontSize: 13.5, color: tokens.ink),
                        decoration: InputDecoration(
                          hintText: strings.preVisitQuestionHint,
                          hintStyle:
                              TextStyle(fontSize: 13, color: tokens.ink3),
                          filled: true,
                          fillColor: tokens.surface2,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(tokens.buttonRadius),
                            borderSide: BorderSide(color: tokens.line),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(tokens.buttonRadius),
                            borderSide: BorderSide(color: tokens.line),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(tokens.buttonRadius),
                            borderSide:
                                BorderSide(color: tokens.ink, width: 1.2),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),
                      MindButton(
                        text: strings.continueToShareBtn,
                        variant: MindButtonVariant.primary,
                        leadingIcon: Icons.arrow_forward_rounded,
                        isFullWidth: true,
                        onPressed: () => _continueToShare(context),
                      ),
                    ],
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
