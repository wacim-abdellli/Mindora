import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/router/app_router.dart';
import '../../../../app/theme/mind_tokens.dart';
import '../../../../core/widgets/mind_button.dart';
import '../../../../core/widgets/mind_card.dart';
import '../../../../core/widgets/mind_intensity_picker.dart';
import '../../../../core/widgets/mind_pressable.dart';
import '../../../../core/widgets/mood_emblem.dart';
import '../../../../core/widgets/organic_mood_orb.dart';
import '../../../../core/widgets/quick_note_sparks_bar.dart';
import '../../../mind_trace/domain/affect_taxonomy.dart';
import '../../../mind_trace/domain/check_in_micro_mirror.dart';
import '../../../mind_trace/domain/mind_trace_model.dart';
import '../../../support/presentation/contextual_support_sheet.dart';

/// Daily Check-In Sanctuary card rendered inside [HomeScreen].
///
/// Options-first with zero compulsory blank essays:
/// - Interactive Check-In mode features a living [OrganicMoodOrb], a 3+2
///   tactile vector mood grid, unified 10-step intensity slider, optional single-line
///   note, and a single crisp primary action.
/// - Once recorded today, settles into an empathetic Sanctuary loop showing the
///   living orb, today's mood summary, nuanced feelings, intra-day shift trail,
///   and immediate 1-tap `Breathe` / `Talk about it` / `+ Log moment` next steps
///   alongside `Edit` and `VIEW`.
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
  final VoidCallback? onBreatheTap;
  final ValueChanged<MindTraceModel>? onTalkAboutIt;
  final VoidCallback? onLogAnotherMoment;

  @override
  State<HomeDailyCheckInCard> createState() => _HomeDailyCheckInCardState();
}

class _HomeDailyCheckInCardState extends State<HomeDailyCheckInCard> {
  bool _isEditing = false;
  int _saveBloomCount = 0;

  @override
  void didUpdateWidget(covariant HomeDailyCheckInCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.todayTrace == null && widget.todayTrace != null) {
      _isEditing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;
    final strings = widget.strings;
    final isDark = widget.isDark;
    final todayTrace = widget.todayTrace;
    final hasLoggedToday = todayTrace != null;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final viewLabel = strings.isArabic
        ? 'عرض'
        : (strings.isFrench ? 'VOIR' : 'VIEW');

    final showRecordedSummary = hasLoggedToday && !_isEditing;
    final cardVariant = showRecordedSummary ? MindCardVariant.tint : MindCardVariant.plain;

    final cardBody = MindCard(
      variant: cardVariant,
      padding: const EdgeInsets.all(16),
      child: showRecordedSummary
          ? _buildRecordedSummaryView(
              context: context,
              todayTrace: todayTrace,
              tokens: tokens,
              strings: strings,
              isDark: isDark,
              viewLabel: viewLabel,
            )
          : _buildInteractiveFormView(
              context: context,
              tokens: tokens,
              strings: strings,
              isDark: isDark,
              hasLoggedToday: hasLoggedToday,
              reduceMotion: reduceMotion,
            ),
    );

    if (reduceMotion) {
      return cardBody;
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: cardBody,
    );
  }

  Widget _buildRecordedSummaryView({
    required BuildContext context,
    required MindTraceModel todayTrace,
    required MindTokens tokens,
    required AppStrings strings,
    required bool isDark,
    required String viewLabel,
  }) {
    final moodKey = todayTrace.overallMood;
    final moodEnum = AppMood.fromKey(moodKey);
    final moodColor = MindTokens.moodColor(moodEnum);
    final moodLabel = widget.getMoodLabel(moodKey, strings);
    final note = todayTrace.journalText?.trim() ?? '';
    final nuanced = todayTrace.nuancedEmotions;
    final hasMultiMoments = widget.todayTraces.length > 1;
    final shiftTrail = hasMultiMoments
        ? strings.momentsTodayTrail(
            widget.todayTraces.length,
            '${widget.getMoodLabel(widget.todayTraces.first.overallMood, strings)} -> ${widget.getMoodLabel(widget.todayTraces.last.overallMood, strings)}',
          )
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            OrganicMoodOrb(
              moodKey: moodKey,
              intensity: todayTrace.moodIntensity,
              color: moodColor,
              size: 64,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 13,
                        color: moodColor,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          strings.loggedTodayEyebrow,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: strings.isArabic ? 0 : 0.7,
                            color: tokens.ink2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$moodLabel (${todayTrace.moodIntensity}/10)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: tokens.ink,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: tokens.blobTintFor(moodColor),
                          borderRadius:
                              BorderRadius.circular(tokens.chipRadius),
                          border: Border.all(
                            color: moodColor.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Text(
                          moodLabel,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: moodColor,
                          ),
                        ),
                      ),
                      Text(
                        strings.intensityLevelWord(todayTrace.moodIntensity),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: tokens.ink2,
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
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final fKey in nuanced.take(3))
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: tokens.surface2,
                    borderRadius: BorderRadius.circular(tokens.chipRadius),
                    border: Border.all(color: tokens.line),
                  ),
                  child: Text(
                    AffectTaxonomy.localizedLabel(fKey, strings),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: tokens.ink,
                    ),
                  ),
                ),
            ],
          ),
        ],
        if (shiftTrail != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: tokens.surface2,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: tokens.line),
            ),
            child: Row(
              children: [
                Icon(Icons.schedule_rounded, size: 13, color: moodColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    shiftTrail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: tokens.ink2,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (note.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: tokens.surface2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: tokens.line),
            ),
            child: Text(
              note,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                height: 1.35,
                color: tokens.ink2,
              ),
            ),
          ),
        ],
        const SizedBox(height: 10),
        Builder(
          builder: (context) {
            final mirror = CheckInMicroMirror.build(
              latestToday: todayTrace,
              todayTraces: widget.todayTraces.isNotEmpty
                  ? widget.todayTraces
                  : [todayTrace],
              allTraces: widget.traces,
              strings: strings,
            );
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: tokens.cardTint,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: tokens.line),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.spa_outlined, size: 14, color: moodColor),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      mirror,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        height: 1.35,
                        color: tokens.ink2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 14),
        Divider(height: 1, color: tokens.line),
        const SizedBox(height: 12),
        Text(
          strings.aGentleNextStepHeader,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: strings.isArabic ? 0 : 0.7,
            color: tokens.ink2,
          ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final textScale = MediaQuery.textScalerOf(context).scale(1.0);
            final breatheBtn = MindButton(
              text: strings.actionBreatheLabel,
              leadingIcon: Icons.air_rounded,
              variant: MindButtonVariant.soft,
              isFullWidth: constraints.maxWidth < 290 && textScale > 1.15,
              onPressed: widget.onBreatheTap ??
                  () => ContextualSupportSheet.show(
                        context,
                        initialChoice: SupportChoice.settle,
                      ),
            );
            final talkBtn = MindButton(
              text: strings.actionTalkAboutItLabel,
              leadingIcon: Icons.auto_awesome_outlined,
              variant: MindButtonVariant.soft,
              isFullWidth: constraints.maxWidth < 290 && textScale > 1.15,
              onPressed: () {
                if (widget.onTalkAboutIt != null) {
                  widget.onTalkAboutIt!(todayTrace);
                } else {
                  context.go(AppRouter.companion);
                }
              },
            );
            if (constraints.maxWidth < 290 && textScale > 1.15) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  breatheBtn,
                  const SizedBox(height: 8),
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
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          runSpacing: 2,
          children: [
            MindPressable(
              onPressed: () => setState(() => _isEditing = true),
              semanticLabel: strings.updateCheckInButton,
              borderRadius: BorderRadius.circular(tokens.chipRadius),
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.edit_outlined,
                      size: 15,
                      color: tokens.ink2,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        strings.updateCheckInButton,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: tokens.ink,
                          decoration: TextDecoration.underline,
                          decorationColor: moodColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            MindPressable(
              onPressed: widget.onLogAnotherMoment ??
                  () => context.go('${AppRouter.track}?newMoment=1'),
              semanticLabel: strings.logMomentShortBtn,
              borderRadius: BorderRadius.circular(tokens.chipRadius),
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_circle_outline_rounded,
                      size: 15,
                      color: moodColor,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        strings.logMomentShortBtn,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: tokens.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            MindPressable(
              onPressed: () => context.go('${AppRouter.track}?tab=1'),
              semanticLabel: viewLabel,
              borderRadius: BorderRadius.circular(tokens.chipRadius),
              child: Container(
                constraints: const BoxConstraints(minHeight: 48, minWidth: 56),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      viewLabel,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: tokens.ink,
                        letterSpacing: strings.isArabic ? 0 : 0.4,
                        decoration: TextDecoration.underline,
                        decorationColor: moodColor,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(
                      Directionality.of(context) == TextDirection.rtl
                          ? Icons.chevron_left_rounded
                          : Icons.chevron_right_rounded,
                      size: 16,
                      color: tokens.ink2,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInteractiveFormView({
    required BuildContext context,
    required MindTokens tokens,
    required AppStrings strings,
    required bool isDark,
    required bool hasLoggedToday,
    required bool reduceMotion,
  }) {
    final safeIdx = widget.selectedMoodIndex.clamp(
      0,
      widget.moodOptions.isEmpty ? 0 : widget.moodOptions.length - 1,
    );
    final activeMood = widget.moodOptions[safeIdx].key;
    final activeMoodEnum = AppMood.fromKey(activeMood);
    final activeMoodColor = MindTokens.moodColor(activeMoodEnum);
    final activeMoodSoft = tokens.blobTintFor(activeMoodColor);
    final roundedIntensity = widget.moodIntensity.round().clamp(1, 10);
    final previousTrace = widget.traces.firstOrNull;
    final rowOneCount =
        widget.moodOptions.length >= 3 ? 3 : widget.moodOptions.length;
    final hasSecondRow = widget.moodOptions.length > 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_isEditing && widget.todayTrace != null) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  strings.editEntryTitle,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: tokens.ink,
                  ),
                ),
              ),
              MindPressable(
                onPressed: () => setState(() => _isEditing = false),
                semanticLabel: strings.cancelBtn,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: tokens.ink2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ] else ...[
          Text(
            strings.homeQuestion,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.28,
              color: tokens.ink,
              letterSpacing: -0.2,
            ),
          ),
          if (!hasLoggedToday && previousTrace != null) ...[
            const SizedBox(height: 6),
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: tokens.surface2,
                  borderRadius: BorderRadius.circular(tokens.chipRadius),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MoodEmblem(
                      moodKey: previousTrace.overallMood,
                      size: 13,
                      color: widget.getMoodColor(previousTrace.overallMood),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '${strings.lastMoodLabel}: ${widget.getMoodLabel(previousTrace.overallMood, strings)} (${previousTrace.moodIntensity}/10)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11.5,
                          color: tokens.ink2,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],

        // Living Organic Mood Orb (responds smoothly to state + intensity + 2D touch)
        Center(
          child: OrganicMoodOrb(
            moodKey: activeMood,
            intensity: roundedIntensity,
            color: activeMoodColor,
            size: 88,
            celebrationRevision: _saveBloomCount,
            semanticLabel: widget.getMoodLabel(activeMood, strings),
            onIntensityChanged: (next) =>
                widget.onIntensityChanged(next.toDouble()),
            onMoodStep: (delta) {
              if (widget.moodOptions.length > 1) {
                final len = widget.moodOptions.length;
                widget.onMoodSelected(((safeIdx + delta) % len + len) % len);
              }
            },
            onTap: () {
              if (widget.moodOptions.length > 1) {
                widget.onMoodSelected(
                  (safeIdx + 1) % widget.moodOptions.length,
                );
              }
            },
          ),
        ),
        const SizedBox(height: 2),
        Center(
          child: Text(
            '${strings.intensityLevelWord(roundedIntensity)} · $roundedIntensity/10',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: tokens.ink2,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(height: 2),
        Center(
          child: Text(
            strings.orbTouchHint,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10.5,
              color: tokens.ink3,
            ),
          ),
        ),
        const SizedBox(height: 10),

        // 3 + 2 Tactile Emotion Tile Grid with invariant label geometry
        Row(
          children: [
            for (int i = 0; i < rowOneCount; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: _buildMoodTile(
                  option: widget.moodOptions[i],
                  index: i,
                  isSelected: i == safeIdx,
                  tokens: tokens,
                  strings: strings,
                  isDark: isDark,
                  reduceMotion: reduceMotion,
                ),
              ),
            ],
          ],
        ),
        if (hasSecondRow) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              for (int i = 3; i < widget.moodOptions.length; i++) ...[
                if (i > 3) const SizedBox(width: 8),
                Expanded(
                  child: _buildMoodTile(
                    option: widget.moodOptions[i],
                    index: i,
                    isSelected: i == safeIdx,
                    tokens: tokens,
                    strings: strings,
                    isDark: isDark,
                    reduceMotion: reduceMotion,
                  ),
                ),
              ],
            ],
          ),
        ],
        const SizedBox(height: 12),

        // Intensity Header & Word Badge
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      '${strings.moodIntensityLabel.toUpperCase()}: $roundedIntensity/10',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: strings.isArabic ? 0 : 0.7,
                        color: tokens.ink,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: activeMoodSoft,
                      borderRadius: BorderRadius.circular(tokens.chipRadius),
                      border: Border.all(
                        color: activeMoodColor.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      strings.intensityLevelWord(roundedIntensity),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: activeMoodColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            MoodEmblem(
              moodKey: activeMood,
              size: 20,
              color: activeMoodColor,
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Unified 10-step graduated waveform + progress rail intensity picker
        MindIntensityPicker(
          value: roundedIntensity,
          accentColor: activeMoodColor,
          strings: strings,
          onChanged: (next) => widget.onIntensityChanged(next.toDouble()),
        ),
        const SizedBox(height: 10),

        // Optional Daily Note Input
        TextField(
          controller: widget.todayNoteController,
          maxLines: 2,
          minLines: 1,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13.5,
            color: tokens.ink,
          ),
          decoration: InputDecoration(
            hintText: strings.todaysNoteHint,
            hintStyle: TextStyle(
              fontFamily: 'Inter',
              color: tokens.ink3,
              fontSize: 13,
            ),
            filled: true,
            fillColor: tokens.surface2,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: tokens.line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: tokens.line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: activeMoodColor, width: 1.4),
            ),
          ),
        ),
        const SizedBox(height: 6),
        QuickNoteSparksBar(
          moodKey: activeMood,
          controller: widget.todayNoteController,
          strings: strings,
        ),
        const SizedBox(height: 10),

        // Primary Save / Update CTA (Single primary CTA in this viewport)
        MindButton(
          text: hasLoggedToday
              ? strings.updateCheckInButton
              : strings.saveCheckInButton,
          leadingIcon: hasLoggedToday
              ? Icons.refresh_rounded
              : Icons.check_circle_outline_rounded,
          variant: MindButtonVariant.primary,
          onPressed: () {
            setState(() => _saveBloomCount++);
            widget.onSave();
            if (hasLoggedToday && mounted) {
              setState(() => _isEditing = false);
            }
          },
        ),
      ],
    );
  }

  Widget _buildMoodTile({
    required ({String key, IconData icon}) option,
    required int index,
    required bool isSelected,
    required MindTokens tokens,
    required AppStrings strings,
    required bool isDark,
    required bool reduceMotion,
  }) {
    final label = widget.getMoodLabel(option.key, strings);
    final moodColor = widget.getMoodColor(option.key);
    final tileRadius = BorderRadius.circular(16);

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: MindPressable(
        onPressed: () => widget.onMoodSelected(index),
        borderRadius: tileRadius,
        child: AnimatedContainer(
          duration:
              reduceMotion ? Duration.zero : const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: isSelected
                ? tokens.selectedTintFor(moodColor)
                : tokens.surface2,
            borderRadius: tileRadius,
            border: Border.all(
              color: isSelected ? moodColor : tokens.line,
              width: 1.4,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: moodColor.withValues(alpha: isDark ? 0.18 : 0.14),
                        border: Border.all(
                          color:
                              moodColor.withValues(alpha: isSelected ? 0.45 : 0.2),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: MoodEmblem(
                        moodKey: option.key,
                        size: 17,
                        color: moodColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? tokens.ink
                            : tokens.ink2,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                PositionedDirectional(
                  top: 6,
                  end: 6,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: moodColor,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.check_rounded,
                      size: 11,
                      color: moodColor.computeLuminance() > 0.45
                          ? tokens.onMood
                          : MindTokens.pureWhiteConstant,
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
