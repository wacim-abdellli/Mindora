import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/theme/lab_theme.dart';
import '../../../../app/theme/mind_tokens.dart';
import '../../../../core/widgets/mind_button.dart';
import '../../../../core/widgets/mind_card.dart';
import '../../../../core/widgets/mind_strength_picker.dart';
import '../../../../core/widgets/mood_face.dart';
import '../../../mind_trace/domain/check_in_micro_mirror.dart';
import '../../../mind_trace/domain/mind_trace_model.dart';

/// Single-job 2-tap check-in sanctuary card for `Today` ([HomeScreen]).
///
/// Tap 1: Pick one of 6 drawn vector [MoodFace] characters (card floods softly
///        with that mood's color).
/// Tap 2: Pick `A little` / `Medium` / `A lot` -> auto-saves immediately!
/// Zero compulsory text boxes, zero 1–10 sliders, <= 32 words above the fold.
class HomeDailyCheckInCard extends StatefulWidget {
  const HomeDailyCheckInCard({
    super.key,
    required this.tokens,
    required this.strings,
    required this.isDark,
    required this.todayTrace,
    required this.traces,
    required this.selectedMoodIndex,
    required this.moodIntensity,
    required this.todayNoteController,
    required this.moodOptions,
    required this.onMoodSelected,
    required this.onIntensityChanged,
    required this.onSave,
    required this.getMoodLabel,
    required this.getMoodColor,
    this.todayTraces = const [],
    this.onQuickSave,
    this.onAddDetails,
    this.onBreatheTap,
    this.onTalkAboutIt,
    this.onLogAnotherMoment,
  });

  final MindTokens tokens;
  final AppStrings strings;
  final bool isDark;
  final MindTraceModel? todayTrace;
  final List<MindTraceModel> traces;
  final List<MindTraceModel> todayTraces;
  final int selectedMoodIndex;
  final double moodIntensity;
  final TextEditingController todayNoteController;
  final List<({String key, IconData icon})> moodOptions;
  final ValueChanged<int> onMoodSelected;
  final ValueChanged<double> onIntensityChanged;
  final VoidCallback onSave;
  final String Function(String key, AppStrings strings) getMoodLabel;
  final Color Function(String key) getMoodColor;
  final void Function(String moodKey, int intensity, {bool createNew})?
  onQuickSave;
  final ValueChanged<MindTraceModel>? onAddDetails;
  final VoidCallback? onBreatheTap;
  final ValueChanged<MindTraceModel>? onTalkAboutIt;
  final VoidCallback? onLogAnotherMoment;

  @override
  State<HomeDailyCheckInCard> createState() => _HomeDailyCheckInCardState();
}

class _HomeDailyCheckInCardState extends State<HomeDailyCheckInCard> {
  bool _isEditing = false;
  bool _creatingNewMoment = false;
  AppMood? _pickedMood;

  @override
  void didUpdateWidget(covariant HomeDailyCheckInCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.todayTrace?.id != widget.todayTrace?.id ||
        oldWidget.todayTrace?.updatedAt != widget.todayTrace?.updatedAt) {
      if (widget.todayTrace != null) {
        _isEditing = false;
        _creatingNewMoment = false;
        _pickedMood = null;
      }
    }
  }

  void _handleMoodTap(AppMood mood) {
    final idx = widget.moodOptions.indexWhere((o) => o.key == mood.key);
    if (idx != -1) {
      widget.onMoodSelected(idx);
    }
    setState(() => _pickedMood = mood);
  }

  void _handleStrengthTap(int intensity) {
    final mood = _pickedMood ?? AppMood.calm;
    HapticFeedback.mediumImpact();
    if (widget.onQuickSave != null) {
      widget.onQuickSave!(
        mood.key,
        intensity,
        createNew: _creatingNewMoment,
      );
    } else {
      widget.onIntensityChanged(intensity.toDouble());
      widget.onSave();
    }
    setState(() {
      _isEditing = false;
      _creatingNewMoment = false;
      _pickedMood = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;
    final strings = widget.strings;
    final todayTrace = widget.todayTrace;
    final showLoggedCard = todayTrace != null && !_isEditing;

    final activeFloodMood = showLoggedCard
        ? AppMood.fromKey(todayTrace.overallMood)
        : _pickedMood;
    final floodColor = activeFloodMood != null
        ? tokens.tint(
            MindTokens.moodColor(activeFloodMood),
            tokens.isDark ? 0.16 : 0.14,
          )
        : tokens.surface;

    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return AnimatedContainer(
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 340),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: floodColor,
        borderRadius: BorderRadius.circular(tokens.cardRadius),
        border: Border.all(
          color: activeFloodMood != null
              ? MindTokens.moodColor(activeFloodMood).withValues(alpha: 0.45)
              : tokens.line,
          width: 1.2,
        ),
        boxShadow: tokens.shadows,
      ),
      padding: const EdgeInsets.all(18),
      child: showLoggedCard
          ? _buildLoggedSummary(context, todayTrace, tokens, strings)
          : _buildTwoTapPicker(context, tokens, strings),
    );
  }

  Widget _buildTwoTapPicker(
    BuildContext context,
    MindTokens tokens,
    AppStrings strings,
  ) {
    final textScale = MediaQuery.textScalerOf(context).scale(16.0) / 16.0;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                strings.howAreYouRightNow,
                style: LabTheme.textStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                  color: tokens.ink,
                ),
              ),
            ),
            if (_isEditing && widget.todayTrace != null)
              TextButton(
                onPressed: () => setState(() {
                  _isEditing = false;
                  _creatingNewMoment = false;
                  _pickedMood = null;
                }),
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                child: Text(
                  strings.cancelActionLabel,
                  style: LabTheme.textStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: tokens.ink2,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final cols = (constraints.maxWidth < 318 || textScale > 1.25)
                ? 2
                : 3;
            final tileWidth = (constraints.maxWidth - (cols - 1) * 10) / cols;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final mood in AppMood.values)
                  SizedBox(
                    width: tileWidth,
                    child: MoodFaceTile(
                      key: ValueKey<String>('today-mood-${mood.key}'),
                      mood: mood,
                      label: strings.plainMoodLabel(mood.key),
                      isSelected: _pickedMood == mood,
                      onTap: () => _handleMoodTap(mood),
                    ),
                  ),
              ],
            );
          },
        ),
        AnimatedSize(
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          child: _pickedMood == null
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(top: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        strings.howStrongQuestion,
                        style: LabTheme.textStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: tokens.ink,
                        ),
                      ),
                      const SizedBox(height: 10),
                      MindStrengthPicker(
                        selectedIntensity: null,
                        aLittleLabel: strings.strengthALittle,
                        mediumLabel: strings.strengthMedium,
                        aLotLabel: strings.strengthALot,
                        accentColor: MindTokens.moodColor(_pickedMood!),
                        onSelected: _handleStrengthTap,
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildLoggedSummary(
    BuildContext context,
    MindTraceModel todayTrace,
    MindTokens tokens,
    AppStrings strings,
  ) {
    final mood = AppMood.fromKey(todayTrace.overallMood);
    final moodLabel = strings.plainMoodLabel(todayTrace.overallMood);
    final strengthLabel = strings.strengthWordForIntensity(
      todayTrace.moodIntensity,
    );
    final ts = todayTrace.effectiveTimestamp;
    final timeStr =
        '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}';

    final mirror = CheckInMicroMirror.build(
      latestToday: todayTrace,
      todayTraces: widget.todayTraces.isEmpty
          ? [todayTrace]
          : widget.todayTraces,
      allTraces: widget.traces,
      strings: strings,
    );

    final textScale = MediaQuery.textScalerOf(context).scale(16.0) / 16.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            MoodFace(
              mood: mood,
              size: 56,
              isSelected: true,
              semanticLabel: moodLabel,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.youFeelTodayTitle(moodLabel),
                    style: LabTheme.textStyle(
                      fontSize: 18.5,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                      color: tokens.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$strengthLabel · $timeStr',
                    style: LabTheme.textStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w600,
                      color: tokens.ink2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (mirror.isNotEmpty) ...[
          const SizedBox(height: 12),
          MindCard(
            variant: MindCardVariant.plain,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Text(
              mirror,
              style: LabTheme.textStyle(
                fontSize: 14.5,
                height: 1.45,
                color: tokens.ink,
              ),
            ),
          ),
        ],
        const SizedBox(height: 14),
        if (widget.onAddDetails != null) ...[
          MindButton(
            text: strings.addDetailsCta,
            variant: MindButtonVariant.soft,
            isFullWidth: true,
            onPressed: () => widget.onAddDetails!(todayTrace),
          ),
          const SizedBox(height: 10),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            final stack = constraints.maxWidth < 300 || textScale > 1.35;
            final breatheBtn = MindButton(
              text: strings.breatheQuickBtn,
              leadingIcon: Icons.air_rounded,
              variant: MindButtonVariant.secondary,
              isFullWidth: true,
              onPressed: widget.onBreatheTap,
            );
            final talkBtn = MindButton(
              text: strings.talkItOutBtn,
              leadingIcon: Icons.chat_bubble_outline_rounded,
              variant: MindButtonVariant.primary,
              isFullWidth: true,
              onPressed: widget.onTalkAboutIt != null
                  ? () => widget.onTalkAboutIt!(todayTrace)
                  : null,
            );
            if (stack) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  breatheBtn,
                  const SizedBox(height: 10),
                  talkBtn,
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: breatheBtn),
                const SizedBox(width: 10),
                Expanded(child: talkBtn),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          children: [
            TextButton(
              onPressed: () => setState(() {
                _isEditing = true;
                _creatingNewMoment = false;
                _pickedMood = mood;
              }),
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              child: Text(
                strings.changeMoodLink,
                style: LabTheme.textStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w700,
                  color: tokens.ink2,
                ),
              ),
            ),
            TextButton(
              onPressed: () => setState(() {
                _isEditing = true;
                _creatingNewMoment = true;
                _pickedMood = null;
              }),
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              child: Text(
                strings.logNewMomentLink,
                style: LabTheme.textStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w700,
                  color: tokens.primary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
