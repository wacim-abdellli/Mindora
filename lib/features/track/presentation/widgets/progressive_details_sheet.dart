import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/theme/lab_theme.dart';
import '../../../../app/theme/mind_tokens.dart';
import '../../../../core/safety/crisis_keywords.dart';
import '../../../../core/safety/safety_interceptor.dart';
import '../../../../core/widgets/mind_button.dart';
import '../../../../core/widgets/mind_chip.dart';
import '../../../../core/widgets/mind_pressable.dart';
import '../../../../core/widgets/mind_sheet.dart';
import '../../../../core/widgets/mind_toast.dart';
import '../../../../core/widgets/quick_note_sparks_bar.dart';
import '../../../mind_trace/controllers/mind_trace_controller.dart';
import '../../../mind_trace/domain/affect_taxonomy.dart';
import '../../../mind_trace/domain/daily_context_tags.dart';
import '../../../mind_trace/domain/mind_trace_model.dart';

/// Optional 1-question-per-card enrichment sheet (`Skip` on every card, zero sliders).
///
/// Card 1: Closer feeling word (`AffectTaxonomy`)
/// Card 2: Sleep duration (4 big tiles) & Energy (3 big tiles)
/// Card 3: Today's context tags & What helped
/// Card 4: Optional quick note with 1-tap sparks + synchronous crisis check
class ProgressiveDetailsSheet extends ConsumerStatefulWidget {
  const ProgressiveDetailsSheet({
    super.key,
    required this.trace,
  });

  final MindTraceModel trace;

  static Future<MindTraceModel?> show(
    BuildContext context, {
    required MindTraceModel trace,
  }) {
    return showMindSheet<MindTraceModel>(
      context: context,
      showGrabHandle: true,
      showCloseButton: false,
      builder: (_) => ProgressiveDetailsSheet(trace: trace),
    );
  }

  @override
  ConsumerState<ProgressiveDetailsSheet> createState() =>
      _ProgressiveDetailsSheetState();
}

class _ProgressiveDetailsSheetState
    extends ConsumerState<ProgressiveDetailsSheet> {
  static const int _totalCards = 4;
  int _cardIndex = 0;
  bool _saving = false;

  late final Set<String> _nuanced;
  double? _sleepHours;
  int? _energyLevel;
  late final Set<String> _contextTags;
  late final Set<String> _helped;
  late final TextEditingController _noteCtrl;

  static const List<String> _helpedOptions = [
    'Walk',
    'Breathing',
    'Quiet time',
    'Talked',
    'Rest',
  ];

  @override
  void initState() {
    super.initState();
    final t = widget.trace;
    _nuanced = {...t.nuancedEmotions};
    _sleepHours = t.sleepHours;
    _energyLevel = t.energyLevel;
    _contextTags = {...t.contextTags};
    _helped = {
      if (t.behavioralResponse != null && t.behavioralResponse!.trim().isNotEmpty)
        ...t.behavioralResponse!
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty),
    };
    _noteCtrl = TextEditingController(text: t.journalText ?? '');
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveAndClose() async {
    if (_saving) return;
    final note = _noteCtrl.text.trim();
    if (note.isNotEmpty && CrisisKeywords.evaluateText(note) == 2) {
      SafetyInterceptor.showCrisisPauseDialog(context);
      return;
    }

    setState(() => _saving = true);
    HapticFeedback.mediumImpact();

    final baseMood = widget.trace.overallMood;
    final updated = widget.trace.copyWith(
      selectedEmotions: <String>[
        baseMood,
        ..._nuanced.where((e) => e.toLowerCase() != baseMood.toLowerCase()),
      ],
      sleepHours: _sleepHours,
      energyLevel: _energyLevel,
      contextTags: _contextTags.toList(),
      behavioralResponse: _helped.isEmpty ? null : _helped.join(', '),
      journalText: note.isEmpty ? null : note,
      clearJournalText: note.isEmpty,
      updatedAt: DateTime.now(),
    );

    await ref
        .read(mindTraceControllerProvider.notifier)
        .updateCheckIn(updated);

    if (mounted) {
      final strings = ref.read(appStringsProvider);
      setState(() => _saving = false);
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(updated);
      }
      showMindToast(context, strings.detailsSavedToast);
    }
  }

  void _nextOrSave() {
    if (_cardIndex >= _totalCards - 1) {
      _saveAndClose();
      return;
    }
    setState(() => _cardIndex += 1);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final strings = ref.watch(appStringsProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top stepper bar: Back / "1 of 4" / Skip
        Row(
          children: [
            if (_cardIndex > 0)
              IconButton(
                tooltip: strings.backBtn,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                onPressed: () => setState(() => _cardIndex -= 1),
                icon: Icon(Icons.arrow_back_rounded, color: tokens.ink),
              )
            else
              const SizedBox(width: 48),
            Expanded(
              child: Text(
                strings.stepProgressOf(_cardIndex + 1, _totalCards),
                textAlign: TextAlign.center,
                style: LabTheme.textStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: tokens.ink2,
                ),
              ),
            ),
            TextButton(
              onPressed: _nextOrSave,
              style: TextButton.styleFrom(
                minimumSize: const Size(56, 48),
                foregroundColor: tokens.ink2,
              ),
              child: Text(
                strings.skipBtn,
                style: LabTheme.textStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: tokens.ink2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildCardContent(tokens, strings),
        const SizedBox(height: 20),
        MindButton(
          text: _cardIndex >= _totalCards - 1
              ? strings.saveDetailsBtn
              : strings.continueBtn,
          isFullWidth: true,
          isLoading: _saving,
          onPressed: _nextOrSave,
        ),
        if (_cardIndex < _totalCards - 1) ...[
          const SizedBox(height: 6),
          Center(
            child: TextButton(
              onPressed: _saveAndClose,
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              child: Text(
                strings.doneBtn,
                style: LabTheme.textStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: tokens.primary,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCardContent(MindTokens tokens, AppStrings strings) {
    return switch (_cardIndex) {
      0 => _buildCardNuance(tokens, strings),
      1 => _buildCardSleepEnergy(tokens, strings),
      2 => _buildCardContext(tokens, strings),
      _ => _buildCardNote(tokens, strings),
    };
  }

  Widget _buildCardNuance(MindTokens tokens, AppStrings strings) {
    final options =
        AffectTaxonomy.prioritizedForCore(widget.trace.overallMood).take(6);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.closerWordQuestion,
          style: LabTheme.textStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: tokens.ink,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final item in options)
              MindChip(
                label: item.localized(strings),
                selected: _nuanced.contains(item.key),
                onTap: () {
                  setState(() {
                    if (!_nuanced.remove(item.key)) {
                      _nuanced.add(item.key);
                    }
                  });
                },
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildCardSleepEnergy(MindTokens tokens, AppStrings strings) {
    final sleepChoices = [
      (hours: 5.5, label: strings.sleepUnder6),
      (hours: 7.0, label: strings.sleepAbout7),
      (hours: 8.0, label: strings.sleepAbout8),
      (hours: 9.0, label: strings.sleep9Plus),
    ];
    final energyChoices = [
      (level: 3, label: strings.energyLowLabel),
      (level: 6, label: strings.energyOkayLabel),
      (level: 8, label: strings.energyFullLabel),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.howDidYouSleepQuestion,
          style: LabTheme.textStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: tokens.ink,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final choice in sleepChoices)
              _choiceTile(
                tokens: tokens,
                label: choice.label,
                selected: _sleepHours != null &&
                    (_sleepHours! - choice.hours).abs() < 0.6,
                onTap: () => setState(() => _sleepHours = choice.hours),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          strings.howIsYourEnergyQuestion,
          style: LabTheme.textStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: tokens.ink,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (var i = 0; i < energyChoices.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(
                child: _choiceTile(
                  tokens: tokens,
                  label: energyChoices[i].label,
                  selected: _energyLevel != null &&
                      ((_energyLevel! <= 4 && i == 0) ||
                          (_energyLevel! > 4 && _energyLevel! <= 7 && i == 1) ||
                          (_energyLevel! >= 8 && i == 2)),
                  onTap: () =>
                      setState(() => _energyLevel = energyChoices[i].level),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _choiceTile({
    required MindTokens tokens,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return MindPressable(
      onPressed: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        constraints: const BoxConstraints(minHeight: 52, minWidth: 96),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? tokens.primary : tokens.surface2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? tokens.primary : tokens.lineStrong,
            width: selected ? 2.0 : 1.0,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: LabTheme.textStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: selected ? tokens.onPrimary : tokens.ink,
          ),
        ),
      ),
    );
  }

  Widget _buildCardContext(MindTokens tokens, AppStrings strings) {
    final tags = DailyContextTags.all.take(6).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.whatWasPartOfTodayQuestion,
          style: LabTheme.textStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: tokens.ink,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tag in tags)
              MindChip(
                label: tag.localized(strings),
                leadingIcon: tag.icon,
                selected: _contextTags.contains(tag.key),
                onTap: () {
                  setState(() {
                    if (!_contextTags.remove(tag.key)) {
                      _contextTags.add(tag.key);
                    }
                  });
                },
              ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          strings.forensicLoopNodeStabilizer,
          style: LabTheme.textStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: tokens.ink,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in _helpedOptions)
              MindChip(
                label: item,
                selected: _helped.contains(item),
                onTap: () {
                  setState(() {
                    if (!_helped.remove(item)) {
                      _helped.add(item);
                    }
                  });
                },
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildCardNote(MindTokens tokens, AppStrings strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.quickNoteQuestion,
          style: LabTheme.textStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: tokens.ink,
          ),
        ),
        const SizedBox(height: 12),
        QuickNoteSparksBar(
          moodKey: widget.trace.overallMood,
          controller: _noteCtrl,
          strings: strings,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _noteCtrl,
          minLines: 2,
          maxLines: 4,
          style: LabTheme.textStyle(fontSize: 15.5, color: tokens.ink),
          decoration: InputDecoration(
            hintText: strings.quickNoteQuestion,
          ),
        ),
      ],
    );
  }
}
