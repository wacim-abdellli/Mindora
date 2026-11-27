import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/localization/locale_controller.dart';
import '../../../../app/theme/lab_theme.dart';
import '../../../../app/theme/mind_tokens.dart';
import '../../../../core/safety/crisis_keywords.dart';
import '../../../../core/safety/safety_interceptor.dart';
import '../../../../core/safety/support_button.dart';
import '../../../../core/widgets/bouncing_widget.dart';
import '../../../../core/widgets/fingerprint_thread_signature.dart';
import '../../../profile/controllers/profile_controller.dart';
import '../../controllers/mind_trace_controller.dart';
import '../../domain/dynamic_question_generator.dart';
import '../../domain/emotion_descriptors.dart';
import '../../domain/mind_trace_model.dart';
import 'trace_entry_detail_sheet.dart';

/// Multi-step, interactive Daily Mind Trace check-in wizard.
///
/// Steps:
/// 1. How are you feeling? (14 exact emotions + custom)
/// 2. Emotional intensity (1-10 interactive scale)
/// 3. How is your mind? (Racing thoughts, concentration, intrusive thoughts, mental clarity, disconnection)
/// 4. How is your body? (Energy level, sleep duration, sleep quality, physical tension)
///
/// Followed by a dedicated Completion Screen celebrating the recorded trace.
class DailyMindTraceStepper extends ConsumerStatefulWidget {
  const DailyMindTraceStepper({
    super.key,
    this.initialTrace,
    required this.onViewConstellation,
    this.onReturnHome,
  });

  final MindTraceModel? initialTrace;
  final VoidCallback onViewConstellation;
  final VoidCallback? onReturnHome;

  @override
  ConsumerState<DailyMindTraceStepper> createState() =>
      _DailyMindTraceStepperState();
}

class _DailyMindTraceStepperState extends ConsumerState<DailyMindTraceStepper> {
  int _currentStep = 0; // 0 to 3: Steps 1-4; 4: Completion Screen
  bool _isSaving = false;

  // Step 1: Emotions
  final Set<String> _selectedEmotions = {};
  String _overallMood = 'calm';

  // Step 2: Intensity
  double _moodIntensity = 5.0;

  // Step 3: Mind
  double _racingThoughts = 4.0;
  double _concentrationLevel = 6.0;
  double _intrusiveThoughts = 3.0;
  double _mentalClarity = 6.0;
  double _emotionalDisconnection = 2.0;
  final Map<String, TextEditingController> _dynamicQuestionControllers = {};

  // Step 4: Body
  double _energyLevel = 5.0;
  double _sleepHours = 7.0;
  int _sleepQuality = 4; // 1-5
  double _physicalTension = 4.0;

  // Completed saved trace cache
  MindTraceModel? _completedTrace;

  @override
  void initState() {
    super.initState();
    if (widget.initialTrace != null) {
      _hydrateFromTrace(widget.initialTrace!);
    }
  }

  void _hydrateFromTrace(MindTraceModel trace) {
    _overallMood = EmotionDescriptor.canonicalKey(trace.overallMood);
    _selectedEmotions.clear();
    _selectedEmotions.addAll(
      trace.selectedEmotions.map(EmotionDescriptor.canonicalKey),
    );
    _moodIntensity = trace.moodIntensity.toDouble();
    _racingThoughts = (trace.racingThoughts ?? 4).toDouble();
    _concentrationLevel = (trace.concentrationLevel ?? 6).toDouble();
    _intrusiveThoughts = (trace.intrusiveThoughts ?? 3).toDouble();
    _mentalClarity = (trace.mentalClarity ?? 6).toDouble();
    _emotionalDisconnection = (trace.emotionalDisconnection ?? 2).toDouble();
    _energyLevel = (trace.energyLevel ?? 5).toDouble();
    _sleepHours = trace.sleepHours ?? 7.0;
    _sleepQuality = trace.sleepQuality ?? 4;
    _physicalTension = (trace.physicalTension ?? 4).toDouble();
    for (final entry in trace.dynamicAnswers.entries) {
      _dynamicQuestionControllers[entry.key] =
          TextEditingController(text: entry.value);
    }
  }

  @override
  void dispose() {
    for (final c in _dynamicQuestionControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submitTrace() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    final now = DateTime.now();
    final uniqueTraceId = 'trace_${now.millisecondsSinceEpoch}';

    final mergedDynamicAnswers = <String, String>{
      if (widget.initialTrace != null) ...widget.initialTrace!.dynamicAnswers,
    };
    for (final entry in _dynamicQuestionControllers.entries) {
      final text = entry.value.text.trim();
      if (text.isNotEmpty) {
        mergedDynamicAnswers[entry.key] = text;
      } else {
        // Intentionally cleared/deleted by user in this session:
        mergedDynamicAnswers.remove(entry.key);
      }
    }

    // Layer 1 crisis pre-scan: Intercept Level 2 phrases immediately
    var highestLevel = 0;
    for (final answer in [
      ...mergedDynamicAnswers.values,
      ..._selectedEmotions,
    ]) {
      final level = CrisisKeywords.evaluateText(answer);
      if (level == 2) {
        setState(() => _isSaving = false);
        if (mounted) {
          SafetyInterceptor.showCrisisPauseDialog(context);
        }
        return;
      }
      if (level > highestLevel) highestLevel = level;
    }

    final effectiveMood = _selectedEmotions.isNotEmpty
        ? EmotionDescriptor.canonicalKey(_selectedEmotions.first)
        : EmotionDescriptor.canonicalKey(_overallMood);

    final canonicalEmotions = _selectedEmotions
        .map(EmotionDescriptor.canonicalKey)
        .toSet()
        .toList();

    final voicePath = widget.initialTrace?.voiceNotePath;

    final trace = widget.initialTrace != null
        ? widget.initialTrace!.copyWith(
            overallMood: effectiveMood,
            selectedEmotions: canonicalEmotions,
            moodIntensity: _moodIntensity.toInt(),
            energyLevel: _energyLevel.toInt(),
            sleepHours: _sleepHours,
            sleepQuality: _sleepQuality,
            physicalTension: _physicalTension.toInt(),
            concentrationLevel: _concentrationLevel.toInt(),
            mentalClarity: _mentalClarity.toInt(),
            racingThoughts: _racingThoughts.toInt(),
            intrusiveThoughts: _intrusiveThoughts.toInt(),
            emotionalDisconnection: _emotionalDisconnection.toInt(),
            dynamicAnswers: mergedDynamicAnswers,
            voiceNotePath: voicePath,
            isCompleted: true,
            updatedAt: now,
          )
        : MindTraceModel(
            id: uniqueTraceId,
            date: now,
            overallMood: effectiveMood,
            selectedEmotions: canonicalEmotions,
            moodIntensity: _moodIntensity.toInt(),
            energyLevel: _energyLevel.toInt(),
            sleepHours: _sleepHours,
            sleepQuality: _sleepQuality,
            physicalTension: _physicalTension.toInt(),
            concentrationLevel: _concentrationLevel.toInt(),
            mentalClarity: _mentalClarity.toInt(),
            racingThoughts: _racingThoughts.toInt(),
            intrusiveThoughts: _intrusiveThoughts.toInt(),
            emotionalDisconnection: _emotionalDisconnection.toInt(),
            dynamicAnswers: mergedDynamicAnswers,
            voiceNotePath: voicePath,
            isCompleted: true,
            createdAt: now,
            updatedAt: now,
          );

    try {
      await ref.read(mindTraceControllerProvider.notifier).recordCheckIn(
            trace,
            generateAi: false, // Prevents fabricated AI diagnostics if unconfigured
          );

      if (mounted) {
        setState(() {
          _completedTrace = trace;
          _currentStep = 4; // Move to Completion Screen
        });
        if (highestLevel == 1) {
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            SnackBar(
              content: Text(ref.read(appStringsProvider).needSupportBtn),
              action: SnackBarAction(
                label: ref.read(appStringsProvider).supportTitle,
                onPressed: () {
                  if (mounted) SupportModalSheet.show(context);
                },
              ),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _promptCustomEmotion(AppStrings strings, bool isDark) async {
    final textController = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final border = ctx.tokens.line;
        final bg = ctx.tokens.surface;
        final textPrimary = ctx.tokens.ink;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border.all(color: border),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.isArabic
                      ? 'إضافة شعور مخصص'
                      : (strings.isFrench ? 'Émotion personnalisée' : 'Custom Emotion'),
                  style: LabTheme.textStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: textController,
                  autofocus: true,
                  style: TextStyle(color: textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: strings.isArabic
                        ? 'دوّن الإحساس بدقة (مثال: حنين، سكينة)...'
                        : (strings.isFrench
                            ? 'Précisez le ressenti (ex. nostalgie, sérénité)...'
                            : 'Enter nuanced feeling (e.g. yearning, grounded)...'),
                    hintStyle: TextStyle(
                      color: ctx.tokens.ink3,
                      fontSize: 12,
                    ),
                    filled: true,
                    fillColor: ctx.tokens.surface2,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(ctx.tokens.buttonRadius),
                      borderSide: BorderSide(color: border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(ctx.tokens.buttonRadius),
                      borderSide: BorderSide(color: border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(ctx.tokens.buttonRadius),
                      borderSide: BorderSide(color: ctx.tokens.m1, width: 1.3),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        strings.isArabic
                            ? 'إلغاء'
                            : (strings.isFrench ? 'Annuler' : 'Cancel'),
                        style: TextStyle(color: ctx.tokens.ink2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ctx.tokens.ink,
                        foregroundColor: ctx.tokens.bg,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(ctx.tokens.buttonRadius),
                        ),
                      ),
                      onPressed: () {
                        final val = textController.text.trim();
                        if (val.isNotEmpty) {
                          final level = CrisisKeywords.evaluateText(val);
                          if (level == 2) {
                            Navigator.pop(ctx);
                            if (mounted) {
                              SafetyInterceptor.showCrisisPauseDialog(context);
                            }
                            return;
                          }
                          final canonical = EmotionDescriptor.canonicalKey(val);
                          setState(() {
                            _selectedEmotions.add(canonical);
                          });
                        }
                        Navigator.pop(ctx);
                      },
                      child: Text(
                        strings.isArabic
                            ? 'إضافة'
                            : (strings.isFrench ? 'Ajouter' : 'Add Emotion'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    textController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final strings = ref.watch(appStringsProvider);

    final tokens = context.tokens;
    final surfaceColor = tokens.surface;
    final borderColor = tokens.line;
    final textPrimary = tokens.ink;
    final textSecondary = tokens.ink2;

    if (_currentStep == 4) {
      return _buildCompletionScreen(
        isDark: isDark,
        strings: strings,
        surfaceColor: surfaceColor,
        borderColor: borderColor,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step Progress Bar
          _buildProgressBar(isDark, borderColor),

          const SizedBox(height: 16),

          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _getStepTitle(_currentStep, strings),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                    color: context.tokens.ink,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${strings.isArabic ? 'خطوة' : (strings.isFrench ? 'Étape' : 'Step')} ${_currentStep + 1}/4',
                style: TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w700,
                  color: textSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Render active step
          if (_currentStep == 0)
            _buildStep1Emotions(isDark, strings, surfaceColor, borderColor, textPrimary, textSecondary)
          else if (_currentStep == 1)
            _buildStep2Intensity(isDark, strings, surfaceColor, borderColor, textPrimary, textSecondary)
          else if (_currentStep == 2)
            _buildStep3Mind(isDark, strings, surfaceColor, borderColor, textPrimary, textSecondary)
          else if (_currentStep == 3)
            _buildStep4Body(isDark, strings, surfaceColor, borderColor, textPrimary, textSecondary),

          const SizedBox(height: 28),

          // Navigation Controls
          _buildNavigationRow(isDark, strings, borderColor, textPrimary, textSecondary),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildProgressBar(bool isDark, Color borderColor) {
    final progress = (_currentStep + 1) / 4.0;
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor: context.tokens.surface2,
            valueColor: AlwaysStoppedAnimation<Color>(context.tokens.ink),
          ),
        ),
      ],
    );
  }

  String _getStepTitle(int step, AppStrings strings) {
    switch (step) {
      case 0:
        return strings.isArabic
            ? '1. كيف تشعر اليوم؟'
            : (strings.isFrench
                ? '1. Comment vous sentez-vous ?'
                : '1. How Are You Feeling?');
      case 1:
        return strings.isArabic
            ? '2. شدة المشاعر'
            : (strings.isFrench ? '2. Intensité émotionnelle' : '2. Emotional Intensity');
      case 2:
        return strings.isArabic
            ? '3. حالة ذهنك وأفكارك'
            : (strings.isFrench ? '3. Comment va votre esprit ?' : '3. How Is Your Mind?');
      case 3:
        return strings.isArabic
            ? '4. حالة جسدك وطاقتك'
            : (strings.isFrench ? '4. Comment va votre corps ?' : '4. How Is Your Body?');
      default:
        return '';
    }
  }

  // ===========================================================================
  // STEP 1: HOW ARE YOU FEELING? (14 EMOTIONS)
  // ===========================================================================
  Widget _buildStep1Emotions(
    bool isDark,
    AppStrings strings,
    Color surfaceColor,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.isArabic
              ? 'اختر المشاعر التي تعبّر عن حالتك الآن'
              : 'Select all emotions that reflect your inner state right now.',
          style: LabTheme.textStyle(
            fontSize: 16,
            height: 1.3,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          strings.isArabic
              ? 'يمكنك اختيار أكثر من شعور أو إضافة شعور شخصي خاص.'
              : 'Multi-selection enabled. Nuanced mixtures welcome.',
          style: TextStyle(fontSize: 12.0, color: textSecondary),
        ),
        const SizedBox(height: 16),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.7,
          ),
          itemCount: EmotionDescriptor.library.length,
          itemBuilder: (context, index) {
            final desc = EmotionDescriptor.library[index];
            final isCustom = desc.key == 'custom';
            final isSelected = _selectedEmotions.contains(desc.key) ||
                _selectedEmotions.contains(desc.localized(strings)) ||
                _selectedEmotions.contains(desc.englishLabel) ||
                _selectedEmotions.contains(desc.frenchLabel) ||
                _selectedEmotions.contains(desc.arabicLabel);

            return InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                if (isCustom) {
                  _promptCustomEmotion(strings, isDark);
                } else {
                  setState(() {
                    if (isSelected) {
                      _selectedEmotions.remove(desc.key);
                      _selectedEmotions.remove(desc.localized(strings));
                      _selectedEmotions.remove(desc.englishLabel);
                      _selectedEmotions.remove(desc.frenchLabel);
                      _selectedEmotions.remove(desc.arabicLabel);
                    } else {
                      _selectedEmotions.add(desc.key);
                    }
                  });
                }
              },
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected
                      ? context.tokens.cardTint
                      : surfaceColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? context.tokens.ink
                        : borderColor,
                    width: isSelected ? 1.2 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      desc.icon,
                      size: 16,
                      color: isSelected
                          ? context.tokens.ink
                          : textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        desc.localized(strings),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? context.tokens.ink
                              : textPrimary,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: context.tokens.ink,
                      ),
                  ],
                ),
              ),
            );
          },
        ),

        // Custom emotions chips if any added
        if (_selectedEmotions
            .any((e) => EmotionDescriptor.findByAny(e) == null)) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            children: _selectedEmotions
                .where((e) => EmotionDescriptor.findByAny(e) == null)
                .map((custom) => Chip(
                      label: Text(
                        custom,
                        style: TextStyle(fontSize: 12.0, color: context.tokens.ink),
                      ),
                      backgroundColor: context.tokens.cardTint,
                      deleteIcon: Icon(Icons.close, size: 12, color: context.tokens.ink),
                      onDeleted: () {
                        setState(() => _selectedEmotions.remove(custom));
                      },
                      side: BorderSide(
                        color: context.tokens.ink.withValues(alpha: 0.4),
                        width: 0.8,
                      ),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }

  // ===========================================================================
  // STEP 2: EMOTIONAL INTENSITY (1-10)
  // ===========================================================================
  Widget _buildStep2Intensity(
    bool isDark,
    AppStrings strings,
    Color surfaceColor,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    final intensityVal = _moodIntensity.toInt();
    String intensityDesc = strings.isArabic
        ? 'متوسط / معتاد'
        : (strings.isFrench ? 'Modéré / Présent' : 'Moderate / Present');
    if (intensityVal <= 3) {
      intensityDesc = strings.isArabic
          ? 'خفيف / هادئ'
          : (strings.isFrench ? 'Léger / Calme' : 'Mild / Low Arousal');
    } else if (intensityVal >= 8) {
      intensityDesc = strings.isArabic
          ? 'مرتفع / شديد'
          : (strings.isFrench ? 'Élevé / Intense' : 'High / Intense Arousal');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.isArabic
              ? 'ما مدى شدة هذه المشاعر الآن؟'
              : (strings.isFrench
                  ? 'Avec quelle intensité ressentez-vous cela ?'
                  : 'How intensely do you feel this right now?'),
          style: LabTheme.textStyle(
            fontSize: 16,
            height: 1.3,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          strings.isArabic
              ? 'مقياس إدراكي من 1 (شعور طفيف جداً) إلى 10 (استثارة انفعالية قوية).'
              : 'Interactive 1 to 10 scale tracking arousal.',
          style: TextStyle(fontSize: 12.0, color: textSecondary),
        ),
        const SizedBox(height: 24),

        // Big Display Card
        Center(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: context.tokens.surface2,
              borderRadius: BorderRadius.circular(context.tokens.cardRadius),
              border: Border.all(
                color: borderColor,
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  '$intensityVal',
                  style: TextStyle(
                    fontSize: 54,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.0,
                    color: intensityVal >= 8
                        ? context.tokens.safety
                        : (intensityVal <= 3
                            ? context.tokens.ink
                            : textPrimary),
                  ),
                ),
                Text(
                  '/ 10',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.tokens.cardTint,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: context.tokens.ink.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    intensityDesc,
                    style: TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                      color: context.tokens.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Discrete numbers grid (2 rows of 5 for >= 48dp accessible tap targets)
        Column(
          children: [
            for (var rowIdx = 0; rowIdx < 2; rowIdx++) ...[
              if (rowIdx > 0) const SizedBox(height: 8),
              Row(
                children: List.generate(5, (colIdx) {
                  final val = rowIdx * 5 + colIdx + 1;
                  final isCurrent = val == intensityVal;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: colIdx < 4 ? 8 : 0),
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _moodIntensity = val.toDouble());
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 140),
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? context.tokens.ink
                                : surfaceColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isCurrent
                                  ? context.tokens.ink
                                  : borderColor,
                            ),
                          ),
                          child: Text(
                            '$val',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  isCurrent ? FontWeight.w800 : FontWeight.w600,
                              color: isCurrent
                                  ? context.tokens.bg
                                  : textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ],
        ),

        const SizedBox(height: 16),

        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: context.tokens.ink,
            inactiveTrackColor: context.tokens.surface2,
            thumbColor: context.tokens.ink,
            overlayColor: context.tokens.ink.withValues(alpha: 0.16),
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: _moodIntensity,
            min: 1,
            max: 10,
            divisions: 9,
            onChanged: (val) {
              HapticFeedback.selectionClick();
              setState(() => _moodIntensity = val);
            },
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // STEP 3: HOW IS YOUR MIND? (OPTIONAL COGNITIVE CHECK)
  // ===========================================================================
  Widget _buildStep3Mind(
    bool isDark,
    AppStrings strings,
    Color surfaceColor,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    final profile = ref.watch(profileControllerProvider).value;
    final locale = ref.watch(localeControllerProvider);
    final traces = ref.watch(mindTraceControllerProvider).value ?? [];

    final dynamicQuestions = DynamicQuestionGenerator.getQuestionsForUser(
      profile: profile,
      recentTraces: traces,
      languageCode: locale.languageCode,
    );

    for (final q in dynamicQuestions) {
      _dynamicQuestionControllers.putIfAbsent(q.id, () => TextEditingController());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                strings.isArabic
                    ? 'كيف تبدو وتيرة أفكارك اليوم؟'
                    : (strings.isFrench
                        ? 'Comment fonctionne votre esprit aujourd’hui ?'
                        : 'How is your mind operating today?'),
                style: LabTheme.textStyle(
                  fontSize: 16,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: context.tokens.surface2,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
              ),
              child: Text(
                strings.isArabic
                    ? 'اختياري'
                    : (strings.isFrench ? 'Optionnel' : 'Optional'),
                style: TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                  color: textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          strings.isArabic
              ? 'ملاحظة الأفكار التلقائية وسرعتها وتشتتها دون إصدار أحكام.'
              : (strings.isFrench
                  ? 'Observez le rythme, la concentration et la clarté mentale sans jugement.'
                  : 'Observe cognitive speed, focus, and clarity without judgment.'),
          style: TextStyle(fontSize: 12.0, color: textSecondary),
        ),
        const SizedBox(height: 20),

        // 1. Racing thoughts
        _buildMetricSlider(
          label: strings.isArabic
              ? 'تسارع وتزاحم الأفكار'
              : (strings.isFrench ? 'Pensées rapides' : 'Racing Thoughts'),
          subtitle: strings.isArabic
              ? 'أفكار متسارعة يصعب إيقافها'
              : (strings.isFrench
                  ? 'Pensées défilant rapidement'
                  : 'Thoughts racing rapidly'),
          value: _racingThoughts,
          onChanged: (v) => setState(() => _racingThoughts = v),
          isDark: isDark,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        ),
        const SizedBox(height: 12),

        // 2. Concentration
        _buildMetricSlider(
          label: strings.isArabic
              ? 'التركيز والقدرة على الانتباه'
              : (strings.isFrench ? 'Concentration & Attention' : 'Concentration & Focus'),
          subtitle: strings.isArabic
              ? 'سهولة البقاء في مهمة واحدة'
              : (strings.isFrench ? 'Capacité à rester concentré' : 'Ability to stay on task'),
          value: _concentrationLevel,
          onChanged: (v) => setState(() => _concentrationLevel = v),
          isDark: isDark,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        ),
        const SizedBox(height: 12),

        // 3. Intrusive thoughts
        _buildMetricSlider(
          label: strings.isArabic
              ? 'الأفكار المتسللة المزعجة'
              : (strings.isFrench ? 'Pensées intrusives' : 'Intrusive Thoughts'),
          subtitle: strings.isArabic
              ? 'أفكار غير مرغوبة تلح على الذهن'
              : (strings.isFrench
                  ? 'Pensées répétitives non souhaitées'
                  : 'Unwanted repetitive thoughts'),
          value: _intrusiveThoughts,
          onChanged: (v) => setState(() => _intrusiveThoughts = v),
          isDark: isDark,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        ),
        const SizedBox(height: 12),

        // 4. Mental clarity
        _buildMetricSlider(
          label: strings.isArabic
              ? 'الوضوح الذهني'
              : (strings.isFrench ? 'Clarté mentale' : 'Mental Clarity'),
          subtitle: strings.isArabic
              ? 'صفاء التفكير وغياب الضبابية'
              : (strings.isFrench
                  ? 'Clarté contre brouillard mental'
                  : 'Clarity versus brain fog'),
          value: _mentalClarity,
          onChanged: (v) => setState(() => _mentalClarity = v),
          isDark: isDark,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        ),
        const SizedBox(height: 12),

        // 5. Emotional disconnection
        _buildMetricSlider(
          label: strings.isArabic
              ? 'الانفصال الذهني أو الشعوري'
              : (strings.isFrench ? 'Déconnexion émotionnelle' : 'Emotional Disconnection'),
          subtitle: strings.isArabic
              ? 'الشعور بالتبلد أو الغربة عن الواقع'
              : (strings.isFrench ? 'Engourdissement ou détachement' : 'Numbness or detachment'),
          value: _emotionalDisconnection,
          onChanged: (v) => setState(() => _emotionalDisconnection = v),
          isDark: isDark,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        ),

        // Tailored inquiries if any
        if (dynamicQuestions.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            strings.isArabic
                ? 'أسئلة استبصار مخصصة'
                : (strings.isFrench ? 'Questions adaptées' : 'Tailored inquiries'),
            style: TextStyle(
              fontSize: 12.0,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              color: context.tokens.ink,
            ),
          ),
          const SizedBox(height: 10),
          ...dynamicQuestions.map((q) {
            final controller = _dynamicQuestionControllers[q.id]!;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(context.tokens.cardRadius),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      q.questionText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: controller,
                      maxLines: 2,
                      style: TextStyle(fontSize: 12, color: textPrimary),
                      decoration: InputDecoration(
                        hintText: strings.isArabic
                            ? 'دوّن إجابتك بحرية (اختياري)...'
                            : 'Optional brief reflection...',
                        hintStyle: TextStyle(
                            fontSize: 12.0,
                            color: textSecondary.withValues(alpha: 0.65)),
                        filled: true,
                        fillColor: context.tokens.surface2,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(context.tokens.buttonRadius),
                            borderSide: BorderSide(color: borderColor)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(context.tokens.buttonRadius),
                            borderSide: BorderSide(color: borderColor)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  // ===========================================================================
  // STEP 4: HOW IS YOUR BODY? (OPTIONAL SOMATIC CHECK)
  // ===========================================================================
  Widget _buildStep4Body(
    bool isDark,
    AppStrings strings,
    Color surfaceColor,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    final qualityLabels = strings.isArabic
        ? ['ضعيف جداً', 'متقطع', 'مقبول', 'جيد', 'مريح ومجدد']
        : ['Very Poor', 'Restless', 'Fair', 'Good', 'Restful'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                strings.isArabic
                    ? 'ماذا يخبرك جسدك اليوم؟'
                    : (strings.isFrench
                        ? 'Que communique votre corps ?'
                        : 'What is your body communicating?'),
                style: LabTheme.textStyle(
                  fontSize: 16,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: context.tokens.surface2,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
              ),
              child: Text(
                strings.isArabic
                    ? 'اختياري'
                    : (strings.isFrench ? 'Optionnel' : 'Optional'),
                style: TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                  color: textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          strings.isArabic
              ? 'مستويات النشاط، جودة النوم، والتوتر العضلي.'
              : (strings.isFrench
                  ? 'Énergie physique, sommeil et tension corporelle.'
                  : 'Physical energy, sleep metrics, and somatic tension.'),
          style: TextStyle(fontSize: 12.0, color: textSecondary),
        ),
        const SizedBox(height: 20),

        // 1. Energy level
        _buildMetricSlider(
          label: strings.isArabic
              ? 'مستوى الطاقة والنشاط'
              : (strings.isFrench ? 'Niveau d’énergie' : 'Energy Level'),
          subtitle: strings.isArabic
              ? 'من الإرهاق التام إلى الحيوية العالية'
              : (strings.isFrench
                  ? 'De l’épuisement à la pleine vitalité'
                  : 'Exhausted to high vitality'),
          value: _energyLevel,
          onChanged: (v) => setState(() => _energyLevel = v),
          isDark: isDark,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        ),
        const SizedBox(height: 16),

        // 2. Sleep duration
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(context.tokens.cardRadius),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    strings.isArabic
                        ? 'مدة النوم الليلة الماضية'
                        : (strings.isFrench ? 'Durée du sommeil' : 'Sleep Duration'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  Text(
                    '${_sleepHours.toStringAsFixed(1)} ${strings.isArabic ? 'ساعة' : (strings.isFrench ? 'heures' : 'hours')}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: context.tokens.ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: context.tokens.ink,
                  inactiveTrackColor: context.tokens.surface2,
                  thumbColor: context.tokens.ink,
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                ),
                child: Slider(
                  value: _sleepHours,
                  min: 0,
                  max: 14,
                  divisions: 28,
                  onChanged: (v) {
                    HapticFeedback.selectionClick();
                    setState(() => _sleepHours = v);
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 3. Sleep quality (1-5)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    strings.isArabic
                        ? 'جودة النوم'
                        : (strings.isFrench ? 'Qualité du sommeil' : 'Sleep Quality'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  Text(
                    qualityLabels[_sleepQuality - 1],
                    style: TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w800,
                      color: context.tokens.ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: List.generate(5, (idx) {
                  final score = idx + 1;
                  final isSelected = score == _sleepQuality;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Semantics(
                        button: true,
                        selected: isSelected,
                        label: '${strings.isArabic ? 'جودة النوم' : (strings.isFrench ? 'Qualité du sommeil' : 'Sleep quality')} $score/5, ${qualityLabels[idx]}',
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _sleepQuality = score);
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 48),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? context.tokens.cardTint
                                  : context.tokens.surface2,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? context.tokens.ink : borderColor,
                              ),
                            ),
                            child: Text(
                              '$score',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight:
                                    isSelected ? FontWeight.w800 : FontWeight.w600,
                                color: isSelected ? context.tokens.ink : textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 4. Physical tension
        _buildMetricSlider(
          label: strings.isArabic
              ? 'التوتر الجسدي الملحوظ'
              : (strings.isFrench ? 'Tension corporelle' : 'Physical Tension'),
          subtitle: strings.isArabic
              ? 'تشنج العضلات أو ثقل الصدر'
              : (strings.isFrench
                  ? 'Contraction musculaire ou oppression'
                  : 'Muscle clenching or body tightness'),
          value: _physicalTension,
          onChanged: (v) => setState(() => _physicalTension = v),
          isDark: isDark,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        ),
      ],
    );
  }

  // ===========================================================================
  // COMPLETION SCREEN
  // ===========================================================================
  Widget _buildCompletionScreen({
    required bool isDark,
    required AppStrings strings,
    required Color surfaceColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final trace = _completedTrace;
    final emotions = trace?.selectedEmotions ?? _selectedEmotions.toList();
    final intensity = trace?.moodIntensity ?? _moodIntensity.toInt();
    final journal = trace?.journalText?.trim();
    final hasJournal = journal != null && journal.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 12),

          // Celestial Starlight Badge
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.tokens.cardTint,
              border: Border.all(color: context.tokens.ink, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: context.tokens.ink.withValues(alpha: 0.16),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Center(
              child: FingerprintThreadSignature(size: 38, animated: true),
            ),
          ),

          const SizedBox(height: 20),

          // Title
          Text(
            strings.isArabic
                ? 'تم توثيق أثر اليوم بنجاح'
                : "Today's trace has been recorded.",
            textAlign: TextAlign.center,
            style: LabTheme.textStyle(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            strings.isArabic
                ? 'تم حفظ أثر فكرتك بأمان في أرشيفك الشخصي.'
                : 'Your thought trace is recorded in your personal archive on this device.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: textSecondary,
            ),
          ),

          const SizedBox(height: 24),

          // Summary Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(context.tokens.cardRadius),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Meta: Emotions & Intensity
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      strings.isArabic
                          ? 'الحالة المعاشة'
                          : (strings.isFrench ? 'État vécu' : 'Lived state'),
                      style: TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                        color: context.tokens.ink,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: context.tokens.surface2,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor),
                      ),
                      child: Text(
                        '${strings.isArabic ? 'الشدة' : (strings.isFrench ? 'Intensité' : 'Intensity')}: $intensity/10',
                        style: TextStyle(
                          fontSize: 12.0,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Emotions Badges
                if (emotions.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: emotions.map((emotion) {
                      final icon = EmotionDescriptor.iconForLabel(emotion);
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: context.tokens.surface2,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, size: 12, color: context.tokens.ink),
                            const SizedBox(width: 5),
                            Text(
                              emotion,
                              style: TextStyle(
                                fontSize: 12.0,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),

                const SizedBox(height: 14),
                Divider(color: borderColor, height: 1),
                const SizedBox(height: 14),

                // Grounding Reflection (No fabricated AI diagnostics)
                Text(
                  strings.isArabic
                      ? 'تأمل ورسوّ'
                      : (strings.isFrench
                          ? 'Réflexion ancrée'
                          : 'Grounded reflection'),
                  style: TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  hasJournal
                      ? '“$journal”'
                      : (strings.isArabic
                          ? '«ملاحظتك لمشاعرك وتسميتها دون لوم ذاتي هو أول خطوة لاستعادة التوازن والوضوح الإدراكي. أثرك مسجل بأمان.»'
                          : (strings.isFrench
                              ? '« Observer et nommer vos émotions crée un espace précieux entre impulsion et réponse. Votre empreinte est préservée. »'
                              : '“Noticing and naming your emotional experiences creates valuable space between impulse and response. Your trace is safely preserved.”')),
                  style: LabTheme.textStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Primary Button: View in The Thought Trace
          BouncingWidget(
            onTap: widget.onViewConstellation,
            child: Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                color: context.tokens.ink,
                borderRadius: BorderRadius.circular(context.tokens.buttonRadius),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.fingerprint_rounded,
                    size: 16,
                    color: context.tokens.bg,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    strings.isArabic
                        ? 'استكشاف أثر الأفكار'
                        : (strings.isFrench
                            ? 'Voir dans la chronologie'
                            : 'View timeline'),
                    style: TextStyle(
                      fontSize: 13.0,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1,
                      color: context.tokens.bg,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Secondary: Review full entry sheet
          if (trace != null)
            BouncingWidget(
              onTap: () {
                TraceEntryDetailSheet.show(context, trace: trace);
              },
              child: Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                ),
                alignment: Alignment.center,
                child: Text(
                  strings.isArabic
                      ? 'مراجعة تفاصيل الأثر'
                      : (strings.isFrench
                          ? 'Revoir les détails'
                          : 'Review entry details'),
                  style: TextStyle(
                    fontSize: 13.0,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                    color: textPrimary,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 10),

          // Return Home
          if (widget.onReturnHome != null)
            TextButton(
              onPressed: widget.onReturnHome,
              child: Text(
                strings.isArabic
                    ? 'العودة إلى الصفحة الرئيسية'
                    : (strings.isFrench ? 'Retour à l’accueil' : 'Return to Home'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ===========================================================================
  // NAVIGATION CONTROLS ROW
  // ===========================================================================
  Widget _buildNavigationRow(
    bool isDark,
    AppStrings strings,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    final isLastStep = _currentStep == 3;

    return Row(
      children: [
        if (_currentStep > 0) ...[
          Expanded(
            flex: 2,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _currentStep--);
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                ),
                alignment: Alignment.center,
                child: Text(
                  strings.isArabic
                      ? 'السابق'
                      : (strings.isFrench ? 'Retour' : 'Back'),
                  style: TextStyle(
                    fontSize: 13.0,
                    fontWeight: FontWeight.w700,
                    color: textSecondary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],

        // Optional Skip button for optional steps (Step 2: Mind, Step 3: Body)
        if (_currentStep >= 2 && !isLastStep) ...[
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _currentStep++);
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              child: Text(
                strings.isArabic
                    ? 'تخطي'
                    : (strings.isFrench ? 'Passer' : 'Skip'),
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],

        // Next or Submit Primary Button
        Expanded(
          flex: 4,
          child: BouncingWidget(
            onTap: _isSaving
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    if (isLastStep) {
                      _submitTrace();
                    } else {
                      setState(() => _currentStep++);
                    }
                  },
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: context.tokens.ink,
                borderRadius: BorderRadius.circular(context.tokens.buttonRadius),
              ),
              alignment: Alignment.center,
              child: _isSaving
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: context.tokens.bg,
                      ),
                    )
                  : Text(
                      isLastStep
                          ? strings.recordTraceBtn
                          : (strings.isArabic
                              ? 'متابعة'
                              : (strings.isFrench ? 'Continuer' : 'Continue')),
                      style: TextStyle(
                        fontSize: 13.0,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                        color: context.tokens.bg,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricSlider({
    required String label,
    required String subtitle,
    required double value,
    required ValueChanged<double> onChanged,
    required bool isDark,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.tokens.surface,
        borderRadius: BorderRadius.circular(context.tokens.cardRadius),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12.0, color: textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${value.toInt()}/10',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: context.tokens.ink,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: context.tokens.ink,
              inactiveTrackColor: context.tokens.surface2,
              thumbColor: context.tokens.ink,
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
              value: value,
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                onChanged(v);
              },
            ),
          ),
        ],
      ),
    );
  }
}
