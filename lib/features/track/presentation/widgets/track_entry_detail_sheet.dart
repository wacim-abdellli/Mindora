import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/localization/mind_formatters.dart';
import '../../../../app/theme/mind_tokens.dart';
import '../../../../core/safety/crisis_keywords.dart';
import '../../../../core/safety/safety_interceptor.dart';
import '../../../../core/safety/support_button.dart';
import '../../../../core/widgets/mind_button.dart';
import '../../../../core/widgets/mind_dialog.dart';
import '../../../../core/widgets/mind_pressable.dart';
import '../../../../core/widgets/mind_switch.dart';
import '../../../../core/widgets/mind_undo_banner.dart';
import '../../../../core/widgets/mood_face.dart';
import '../../../auth/controllers/auth_controller.dart';
import '../../../mind_trace/controllers/mind_trace_controller.dart';
import '../../../mind_trace/domain/affect_taxonomy.dart';
import '../../../mind_trace/domain/daily_context_tags.dart';
import '../../../mind_trace/domain/mind_trace_model.dart';
import 'track_mood_picker.dart';
import 'track_mood_utils.dart';

/// Detail inspector sheet for any Track entry with Edit, Explore with AI Guide,
/// and confirmation-gated Delete actions.
class TrackEntryDetailSheet extends ConsumerWidget {
  const TrackEntryDetailSheet({
    super.key,
    required this.trace,
    required this.onEdit,
    required this.onExploreWithAi,
    this.onDeleted,
  });

  final MindTraceModel trace;
  final VoidCallback onEdit;
  final VoidCallback onExploreWithAi;
  final VoidCallback? onDeleted;

  static Future<void> show(
    BuildContext context, {
    required MindTraceModel trace,
    required VoidCallback onEdit,
    required VoidCallback onExploreWithAi,
    VoidCallback? onDeleted,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TrackEntryDetailSheet(
        trace: trace,
        onEdit: onEdit,
        onExploreWithAi: onExploreWithAi,
        onDeleted: onDeleted,
      ),
    );
  }

  Future<void> _confirmAndDelete(
    BuildContext context,
    WidgetRef ref,
    AppStrings strings,
    MindTokens tokens,
    MindTraceModel deletedTrace,
  ) async {
    final confirmed = await showMindConfirmDialog(
      context,
      title: strings.deleteCheckInConfirmTitle,
      body: strings.deleteCheckInConfirmBody,
      confirmLabel: strings.deleteEntryBtn,
      cancelLabel: strings.cancelBtn,
      destructive: true,
      icon: Icons.delete_outline_rounded,
    );
    if (!confirmed || !context.mounted) return;
    HapticFeedback.mediumImpact();
    final notifier = ref.read(mindTraceControllerProvider.notifier);
    final rootContext = Navigator.of(context, rootNavigator: true).context;
    await notifier.deleteCheckIn(deletedTrace.id);
    if (context.mounted) {
      Navigator.of(context).pop();
      onDeleted?.call();
    }
    if (rootContext.mounted) {
      showMindUndoBanner(
        rootContext,
        message: strings.checkInRemovedUndo,
        undoLabel: strings.undoBtn,
        onUndo: () {
          notifier.recordCheckIn(deletedTrace, generateAi: false);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final strings = ref.watch(appStringsProvider);
    final liveTrace =
        (ref.watch(mindTraceControllerProvider).value ??
                const <MindTraceModel>[])
            .cast<MindTraceModel?>()
            .firstWhere((t) => t?.id == trace.id, orElse: () => trace) ??
        trace;
    final isClinicAccount =
        ref.watch(authControllerProvider).user?.isClinicAccount == true;
    final moodStyle = trackMoodOptionFor(liveTrace.overallMood);
    final moodText = trackMoodLabel(liveTrace.overallMood, strings);
    final ts = liveTrace.effectiveTimestamp;
    final hour = ts.hour.toString().padLeft(2, '0');
    final minute = ts.minute.toString().padLeft(2, '0');
    final nuanced = liveTrace.nuancedEmotions;
    final somaticPills = <String>[
      if (liveTrace.sleepHours != null)
        '${strings.sleepTrackingLabel}: ${MindFormatters.hours(liveTrace.sleepHours!, strings)}',
      if (liveTrace.energyLevel != null)
        '${strings.energyTrackingLabel}: ${liveTrace.energyLevel}/10',
      if (liveTrace.anxietyLevel != null)
        '${strings.anxietyTrackingLabel}: ${liveTrace.anxietyLevel}/10',
      if (liveTrace.physicalTension != null)
        '${strings.physicalTensionLabel}: ${liveTrace.physicalTension}/10',
    ];
    final helpedItems = liveTrace.behavioralResponse == null
        ? const <String>[]
        : liveTrace.behavioralResponse!
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .map(strings.localizedWhatHelped)
              .toList();

    return Container(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(tokens.cardRadius),
        ),
        border: Border.all(color: tokens.line),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: tokens.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${strings.formatHumanDate(liveTrace.effectiveTimestamp)} • $hour:$minute',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: tokens.ink2,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: tokens.selectedTintFor(moodStyle.color),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: moodStyle.color.withValues(
                                    alpha: 0.65,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  MoodFace(
                                    mood: AppMood.fromKey(liveTrace.overallMood),
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    moodText,
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                      color: tokens.ink,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: tokens.surface2,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                strings.strengthWordForIntensity(
                                  liveTrace.moodIntensity,
                                ),
                                style: TextStyle(
                                  fontSize: 13.0,
                                  fontWeight: FontWeight.w600,
                                  color: tokens.ink,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (nuanced.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final key in nuanced)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: tokens.selectedTintFor(moodStyle.color),
                          borderRadius: BorderRadius.circular(tokens.chipRadius),
                          border: Border.all(
                            color: moodStyle.color.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Text(
                          AffectTaxonomy.localizedLabel(key, strings),
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
              ],
              if (somaticPills.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final item in somaticPills)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: tokens.surface2,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: tokens.line),
                        ),
                        child: Text(
                          item,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: tokens.ink,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
              if (liveTrace.journalText != null &&
                  liveTrace.journalText!.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: tokens.surface2,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: tokens.line),
                  ),
                  child: Text(
                    liveTrace.journalText!.trim(),
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.48,
                      color: tokens.ink,
                    ),
                  ),
                ),
              ],
              if (liveTrace.contextTags.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  strings.whatWasPartOfTodayQuestion,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: strings.isArabic ? 0 : 0.2,
                    color: tokens.ink2,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: liveTrace.contextTags
                      .map(
                        (tag) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: tokens.surface2,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: tokens.line),
                          ),
                          child: Text(
                            DailyContextTags.localizedLabel(tag, strings),
                            style: TextStyle(fontSize: 12, color: tokens.ink),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
              if (helpedItems.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  strings.whatHelpedTodayLabel,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: strings.isArabic ? 0 : 0.2,
                    color: tokens.ink2,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: helpedItems
                      .map(
                        (item) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: tokens.surface2,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: tokens.line),
                          ),
                          child: Text(
                            item,
                            style: TextStyle(fontSize: 12, color: tokens.ink),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
              if (liveTrace.situation != null &&
                  liveTrace.situation!.trim().isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  strings.triggersContextHeader,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: strings.isArabic ? 0 : 0.2,
                    color: tokens.ink2,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: liveTrace.situation!
                      .split(',')
                      .map((s) => s.trim())
                      .where((s) => s.isNotEmpty)
                      .map(
                        (item) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: tokens.surface2,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: tokens.line),
                          ),
                          child: Text(
                            strings.trackTriggerDisplay(item),
                            style: TextStyle(fontSize: 12, color: tokens.ink),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 16),
              Container(
                key: const ValueKey('track-detail-privacy-card'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: tokens.surface2,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: liveTrace.isPrivate ? tokens.ink : tokens.line,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      liveTrace.isPrivate
                          ? Icons.lock_outline_rounded
                          : (isClinicAccount
                                ? Icons.health_and_safety_outlined
                                : Icons.smartphone_outlined),
                      size: 20,
                      color: liveTrace.isPrivate ? tokens.ink : tokens.m1,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.keepJustForMeLabel,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: tokens.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            liveTrace.isPrivate
                                ? strings.keepJustForMeDesc
                                : (isClinicAccount
                                      ? strings.sharedWithDoctorStatus
                                      : strings.localDeviceOnlyLabel),
                            style: TextStyle(
                              fontSize: 12,
                              color: tokens.ink2,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    MindSwitch(
                      value: liveTrace.isPrivate,
                      semanticLabel: strings.keepJustForMeLabel,
                      onChanged: (val) async {
                        if (val == liveTrace.isPrivate) return;
                        HapticFeedback.selectionClick();
                        await ref
                            .read(mindTraceControllerProvider.notifier)
                            .toggleTracePrivacy(liveTrace.id);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              MindButton(
                text: strings.exploreWithAiGuideBtn,
                isFullWidth: true,
                leadingIcon: Icons.forum_outlined,
                onPressed: () {
                  Navigator.of(context).pop();
                  onExploreWithAi();
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: MindPressable(
                      semanticLabel: strings.editEntryBtn,
                      borderRadius: BorderRadius.circular(tokens.buttonRadius),
                      onPressed: () {
                        Navigator.of(context).pop();
                        onEdit();
                      },
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 48),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: tokens.surface2,
                          borderRadius: BorderRadius.circular(
                            tokens.buttonRadius,
                          ),
                          border: Border.all(color: tokens.line),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              size: 16,
                              color: tokens.ink,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                strings.editEntryBtn,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: tokens.ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MindPressable(
                      semanticLabel: strings.deleteEntryBtn,
                      borderRadius: BorderRadius.circular(tokens.buttonRadius),
                      onPressed: () => _confirmAndDelete(
                        context,
                        ref,
                        strings,
                        tokens,
                        liveTrace,
                      ),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 48),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: tokens.safetySoft,
                          borderRadius: BorderRadius.circular(
                            tokens.buttonRadius,
                          ),
                          border: Border.all(
                            color: tokens.safety.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.delete_outline_rounded,
                              size: 17,
                              color: tokens.safety,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                strings.deleteEntryBtn,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: tokens.safety,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Modal editor for historical traces so editing past entries never overwrites
/// today's live Check-In Today form.
class EditPastTraceSheet extends ConsumerStatefulWidget {
  const EditPastTraceSheet({super.key, required this.trace});

  final MindTraceModel trace;

  static Future<void> show(BuildContext context, MindTraceModel trace) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditPastTraceSheet(trace: trace),
    );
  }

  @override
  ConsumerState<EditPastTraceSheet> createState() => _EditPastTraceSheetState();
}

class _EditPastTraceSheetState extends ConsumerState<EditPastTraceSheet> {
  late String _mood;
  late double _intensity;
  late TextEditingController _noteCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _mood = widget.trace.overallMood;
    _intensity = widget.trace.moodIntensity.toDouble().clamp(1, 10);
    _noteCtrl = TextEditingController(text: widget.trace.journalText ?? '');
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _noteCtrl.text.trim();
    final level = text.isNotEmpty ? CrisisKeywords.evaluateText(text) : 0;
    if (level == 2) {
      if (mounted) SafetyInterceptor.showCrisisPauseDialog(context);
      return;
    }
    setState(() => _saving = true);
    try {
      final existingEmotions = widget.trace.selectedEmotions;
      final mergedEmotions = <String>[
        _mood,
        ...existingEmotions.where(
          (e) =>
              e.toLowerCase() != _mood.toLowerCase() &&
              !AffectTaxonomy.isCoreMood(e),
        ),
      ];
      final updated = widget.trace.copyWith(
        overallMood: _mood,
        selectedEmotions: mergedEmotions,
        moodIntensity: _intensity.round(),
        journalText: text.isNotEmpty ? text : null,
        clearJournalText: text.isEmpty,
        updatedAt: DateTime.now(),
      );
      await ref
          .read(mindTraceControllerProvider.notifier)
          .updateCheckIn(updated);
      if (mounted) {
        final messenger = ScaffoldMessenger.maybeOf(context);
        final strings = ref.read(appStringsProvider);
        final rootCtx = context;
        Navigator.of(context).pop();
        if (level == 1 && messenger != null) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(strings.needSupportBtn),
              action: SnackBarAction(
                label: strings.supportTitle,
                onPressed: () {
                  if (rootCtx.mounted) SupportModalSheet.show(rootCtx);
                },
              ),
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final strings = ref.watch(appStringsProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(tokens.cardRadius),
          ),
          border: Border.all(color: tokens.line),
        ),
        padding: const EdgeInsetsDirectional.fromSTEB(20, 14, 20, 20),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${strings.editEntryTitle} · ${strings.formatHumanDate(widget.trace.effectiveTimestamp)}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: tokens.ink,
                  ),
                ),
                const SizedBox(height: 14),
                TrackMoodPicker(
                  selectedMoodKey: _mood,
                  strings: strings,
                  onSelect: (key) => setState(() => _mood = key),
                ),
                const SizedBox(height: 16),
                TrackIntensitySlider(
                  value: _intensity,
                  moodColor: trackMoodOptionFor(_mood).color,
                  strings: strings,
                  inCard: false,
                  onChanged: (v) => setState(() => _intensity = v),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _noteCtrl,
                  maxLines: 3,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13.5,
                    color: tokens.ink,
                  ),
                  decoration: InputDecoration(
                    hintText: strings.whatsOnYourMindHint,
                    filled: true,
                    fillColor: tokens.surface2,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: tokens.line),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                MindButton(
                  text: strings.saveChangesBtn,
                  isFullWidth: true,
                  isLoading: _saving,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
