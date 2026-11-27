import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/localization/locale_controller.dart';
import '../../../app/router/app_router.dart';
import '../../../app/theme/display_comfort_controller.dart';
import '../../../app/theme/lab_theme.dart';
import '../../../app/theme/mind_tokens.dart';
import '../../../app/theme/theme_controller.dart';
import '../../../core/safety/support_button.dart';
import '../../../core/widgets/ambient_scaffold.dart';
import '../../../core/widgets/mind_badge.dart';
import '../../../core/widgets/mind_button.dart';
import '../../../core/widgets/mind_card.dart';
import '../../../core/widgets/mind_pressable.dart';
import '../../../core/widgets/mind_strength_picker.dart';
import '../../../core/widgets/mood_face.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../journey/controllers/journey_controller.dart';
import '../../mind_trace/controllers/mind_trace_controller.dart';
import '../../mind_trace/domain/mind_trace_model.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../profile/domain/clinical_condition_catalog.dart';
import '../../profile/domain/psychological_profile_model.dart';
import '../../profile/presentation/widgets/clinical_condition_search_sheet.dart';
import '../domain/app_personalization_engine.dart';

/// Adaptive, 100% options-first 5-step Patient onboarding for Mindora.
///
/// Step 1: Language (`English`, `Français`, `العربية`), Theme (`Daylight` / `Dark`) & Comfort size.
/// Step 2: Age group (Under 18 safeguard + hotlines; 65+ auto-enables Comfort Mode).
/// Step 3: Multi-select goals (shapes Home & Doctor Prep features).
/// Step 4: Care context + optional clinic code + Daily focus areas & Condition tracks.
/// Step 5: Decision Summary preview + First 2-tap MoodFace check-in.
///
/// NOTE: Doctor / Admin users launch via the dedicated Doctor Edition (`main_clinician.dart`)
/// or Sign In -> Doctor Portal; patients are never interrupted by a role gate here.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const int _totalSteps = 5;

  static const List<String> _ageRanges = [
    'under_18',
    '18-24',
    '25-44',
    '45-64',
    '65+',
  ];

  static const List<String> _goalKeys = [
    'track_mood_sleep',
    'doctor_visits',
    'calm_stress',
    'understand_energy',
    'just_exploring',
  ];

  static const List<String> _careContextKeys = [
    'regular_doctor',
    'occasional_doctor',
    'self_care',
  ];

  static const List<String> _focusAreaKeys = [
    'sleep',
    'energy',
    'stress',
    'overthinking',
    'work_study',
    'family_social',
    'routine',
  ];

  int _currentStep = 0;
  bool _hydrated = false;
  bool _isFinishing = false;
  bool _recordedFirstCheckIn = false;

  String _selectedAgeRange = '';
  final Set<String> _selectedGoals = <String>{};
  String _careContext = '';
  final TextEditingController _clinicCodeController = TextEditingController();
  final Set<String> _selectedFocusAreas = <String>{};
  final Set<String> _selectedConditionIds = <String>{};
  final Set<String> _selectedTrackIds = <String>{};
  AppMood _selectedMood = AppMood.calm;
  int _firstIntensity = 6;

  static const List<ClinicalTrack> _starterTracks = [
    ClinicalTrack.bipolarCycling,
    ClinicalTrack.depressiveSpectrum,
    ClinicalTrack.anxietyPanic,
    ClinicalTrack.obsessiveCompulsive,
    ClinicalTrack.sleepWake,
    ClinicalTrack.neurodevelopmental,
  ];

  bool get _isMinor =>
      _selectedAgeRange == 'under_18' || _selectedAgeRange == '<18';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hydrateFromExistingProfile();
    });
  }

  @override
  void dispose() {
    _clinicCodeController.dispose();
    super.dispose();
  }

  void _hydrateFromExistingProfile() {
    if (_hydrated) return;
    final profile = ref.read(profileControllerProvider).value;
    if (profile == null) return;
    _hydrated = true;

    setState(() {
      if (profile.ageRange.isNotEmpty) {
        _selectedAgeRange = profile.ageRange;
      }
      if (profile.selectedGoals.isNotEmpty) {
        _selectedGoals.addAll(profile.selectedGoals);
      }
      if (profile.careContext.isNotEmpty) {
        _careContext = profile.careContext;
      }
      if (profile.focusAreas.isNotEmpty) {
        _selectedFocusAreas.addAll(profile.focusAreas);
      }
      if (profile.selectedConditionIds.isNotEmpty) {
        _selectedConditionIds.addAll(profile.selectedConditionIds);
      }
      if (profile.selectedTrackIds.isNotEmpty) {
        _selectedTrackIds.addAll(profile.selectedTrackIds);
      }
      if (profile.onboardingStep > 0) {
        _currentStep = profile.onboardingStep.clamp(0, _totalSteps - 1);
      }
    });

    SharedPreferences.getInstance().then((prefs) {
      final savedCode = prefs.getString('mf_patient_clinic_code_v1');
      if (savedCode != null && savedCode.isNotEmpty && mounted) {
        _clinicCodeController.text = savedCode;
      }
    });
  }

  PsychologicalProfileModel _buildProfileDraft(
    PsychologicalProfileModel? base,
    String userId, {
    required int step,
  }) {
    final goalsList = _selectedGoals.toList(growable: false);
    final focusList = _selectedFocusAreas.toList(growable: false);
    return (base ?? PsychologicalProfileModel.empty(userId: userId)).copyWith(
      userId: userId,
      userRole: 'patient',
      ageRange: _selectedAgeRange,
      selectedGoals: goalsList,
      careContext: _careContext,
      professionalSupport: _careContext,
      focusAreas: focusList,
      selectedConditionIds: _selectedConditionIds.toList(growable: false),
      selectedTrackIds: _selectedTrackIds.toList(growable: false),
      onboardingStep: step,
      updatedAt: DateTime.now(),
    );
  }

  Future<void> _saveDraftProgress() async {
    final currentProfile = ref.read(profileControllerProvider).value;
    final userId = ref.read(authControllerProvider).user?.id ?? 'local_user';
    final draft = _buildProfileDraft(currentProfile, userId, step: _currentStep);
    await ref.read(profileControllerProvider.notifier).saveFullProfile(draft);
  }

  void _nextStep() {
    if (_currentStep >= _totalSteps - 1) {
      _finishOnboarding(saveInitialTrace: true);
      return;
    }
    setState(() => _currentStep += 1);
    _saveDraftProgress();
  }

  void _previousStep() {
    if (_currentStep <= 0) return;
    setState(() => _currentStep -= 1);
    _saveDraftProgress();
  }

  void _skipCurrentStep() {
    if (_currentStep >= _totalSteps - 1) {
      _finishOnboarding(saveInitialTrace: false);
      return;
    }
    _nextStep();
  }

  Future<void> _finishOnboarding({required bool saveInitialTrace}) async {
    if (_isFinishing) return;
    setState(() => _isFinishing = true);
    HapticFeedback.mediumImpact();

    try {
      final authCtrl = ref.read(authControllerProvider.notifier);
      await authCtrl.createAnonymousVault();
      await authCtrl.completeOnboarding();

      final currentProfile = await ref.read(profileControllerProvider.future);
      await ref.read(mindTraceControllerProvider.future);

      final userId = ref.read(authControllerProvider).user?.id ?? 'local_user';
      final profile = _buildProfileDraft(
        currentProfile,
        userId,
        step: _totalSteps,
      );

      await ref
          .read(profileControllerProvider.notifier)
          .saveFullProfile(profile);
      await ref.read(journeyControllerProvider.notifier).resetJourney();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('mf_preferred_workspace', 'patient');
      final clinicCode = _clinicCodeController.text.trim().toUpperCase();
      if (clinicCode.isNotEmpty) {
        await prefs.setString('mf_patient_clinic_code_v1', clinicCode);
      }

      if (saveInitialTrace && !_recordedFirstCheckIn) {
        _recordedFirstCheckIn = true;
        final now = DateTime.now();
        final newTrace = MindTraceModel(
          id: 'trace_${now.millisecondsSinceEpoch}',
          userId: userId,
          date: now,
          overallMood: _selectedMood.key,
          moodIntensity: _firstIntensity,
          energyLevel: null,
          selectedEmotions: [_selectedMood.key],
          createdAt: now,
          updatedAt: now,
        );
        await ref
            .read(mindTraceControllerProvider.notifier)
            .recordCheckIn(newTrace, generateAi: false);
      }

      if (mounted) {
        GoRouter.maybeOf(context)?.go(AppRouter.home);
      }
    } finally {
      if (mounted) {
        setState(() => _isFinishing = false);
      }
    }
  }

  String _ageLabel(String range, AppStrings strings) {
    if (range == 'under_18') return strings.ageUnder18;
    if (range == '65+') return strings.age65Plus;
    return range;
  }

  String _goalLabel(String key, AppStrings strings) => switch (key) {
    'track_mood_sleep' => strings.goalTrackMoodSleep,
    'doctor_visits' => strings.goalDoctorVisits,
    'calm_stress' => strings.goalCalmStress,
    'understand_energy' => strings.goalUnderstandEnergy,
    _ => strings.goalJustExploring,
  };

  IconData _goalIcon(String key) => switch (key) {
    'track_mood_sleep' => Icons.bedtime_outlined,
    'doctor_visits' => Icons.medical_information_outlined,
    'calm_stress' => Icons.air_rounded,
    'understand_energy' => Icons.bolt_outlined,
    _ => Icons.explore_outlined,
  };

  String _careLabel(String key, AppStrings strings) => switch (key) {
    'regular_doctor' => strings.careRegularDoctor,
    'occasional_doctor' => strings.careOccasionalDoctor,
    _ => strings.careSelfOnly,
  };

  String _focusLabel(String key, AppStrings strings) => switch (key) {
    'sleep' => strings.focusSleep,
    'energy' => strings.focusEnergy,
    'stress' => strings.focusStress,
    'overthinking' => strings.focusOverthinking,
    'work_study' => strings.focusWorkStudy,
    'family_social' => strings.focusFamilySocial,
    _ => strings.focusRoutine,
  };

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<PsychologicalProfileModel?>>(
      profileControllerProvider,
      (_, next) {
        if (next.hasValue && next.value != null && !_hydrated) {
          _hydrateFromExistingProfile();
        }
      },
    );

    final tokens = context.tokens;
    final strings = ref.watch(appStringsProvider);
    final activeLocale = ref.watch(localeControllerProvider);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return AmbientScaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(tokens, strings, activeLocale),
            if (_currentStep > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Row(
                  children: [
                    for (var i = 1; i < _totalSteps; i++) ...[
                      Expanded(
                        child: AnimatedContainer(
                          duration: reduceMotion
                              ? Duration.zero
                              : const Duration(milliseconds: 220),
                          height: 4,
                          decoration: BoxDecoration(
                            color: i <= _currentStep
                                ? tokens.primary
                                : tokens.lineStrong,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                      if (i < _totalSteps - 1) const SizedBox(width: 6),
                    ],
                  ],
                ),
              ),
            Expanded(
              child: AnimatedSwitcher(
                duration: reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 200),
                switchInCurve: Curves.easeOutCubic,
                child: _buildActiveStep(tokens, strings),
              ),
            ),
            _buildBottomBar(tokens, strings),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(
    MindTokens tokens,
    AppStrings strings,
    Locale activeLocale,
  ) {
    if (_currentStep == 0) {
      return const SizedBox(height: 8);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 2),
      child: Row(
        children: [
          IconButton(
            tooltip: strings.backBtn,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: _previousStep,
            icon: Icon(Icons.arrow_back_rounded, color: tokens.ink),
          ),
          Expanded(
            child: Text(
              strings.stepProgressOf(_currentStep + 1, _totalSteps),
              textAlign: TextAlign.center,
              style: LabTheme.textStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.w700,
                color: tokens.ink2,
              ),
            ),
          ),
          TextButton(
            onPressed: _skipCurrentStep,
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
    );
  }

  Widget _buildActiveStep(MindTokens tokens, AppStrings strings) {
    return switch (_currentStep) {
      0 => _buildStepWelcome(tokens, strings),
      1 => _buildStepAgeSafety(tokens, strings),
      2 => _buildStepGoals(tokens, strings),
      3 => _buildStepCareAndFocus(tokens, strings),
      _ => _buildStepFirstMood(tokens, strings),
    };
  }

  Widget _buildStepWelcome(MindTokens tokens, AppStrings strings) {
    final comfortMode = ref.watch(displayComfortProvider);
    final isDarkActive = Theme.of(context).brightness == Brightness.dark;
    final activeLocale = ref.watch(localeControllerProvider);

    return SingleChildScrollView(
      key: const ValueKey('onboarding_step_0'),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(
            child: MoodFace(
              mood: AppMood.good,
              size: 74,
              isSelected: true,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Mindora',
            textAlign: TextAlign.center,
            style: LabTheme.textStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.15,
              color: tokens.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            strings.onboardingWelcomeBody,
            textAlign: TextAlign.center,
            style: LabTheme.textStyle(
              fontSize: 15.5,
              height: 1.45,
              color: tokens.ink2,
            ),
          ),
          const SizedBox(height: 12),
          MindCard(
            variant: MindCardVariant.flat,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.verified_user_outlined, size: 18, color: tokens.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    strings.onboardingPrivacyPromise,
                    style: LabTheme.textStyle(
                      fontSize: 13.0,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                      color: tokens.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            strings.languageTitle,
            style: LabTheme.textStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.w700,
              color: tokens.ink,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < AppLanguage.values.length; i++) ...[
                Expanded(
                  child: Builder(
                    builder: (_) {
                      final lang = AppLanguage.values[i];
                      final selected = activeLocale.languageCode == lang.code;
                      return MindPressable(
                        key: ValueKey<String>('onboarding-lang-${lang.code}'),
                        semanticLabel: lang.displayName,
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          ref
                              .read(localeControllerProvider.notifier)
                              .setLanguage(lang);
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 48),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 12,
                          ),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selected ? tokens.primary : tokens.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selected ? tokens.primary : tokens.lineStrong,
                            ),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              lang.displayName,
                              maxLines: 1,
                              style: LabTheme.textStyle(
                                fontSize: 14.0,
                                fontWeight: FontWeight.w700,
                                color: selected ? tokens.onPrimary : tokens.ink,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (i < AppLanguage.values.length - 1) const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Text(
            strings.themeModeTitle,
            style: LabTheme.textStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.w700,
              color: tokens.ink,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final option in [
                (
                  dark: false,
                  icon: Icons.wb_sunny_outlined,
                  label: strings.themeDaylight,
                ),
                (
                  dark: true,
                  icon: Icons.dark_mode_outlined,
                  label: strings.themeNight,
                ),
              ]) ...[
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: isDarkActive == option.dark,
                    label: option.label,
                    child: MindPressable(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        ref
                            .read(themeControllerProvider.notifier)
                            .setTheme(
                              option.dark ? ThemeMode.dark : ThemeMode.light,
                            );
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 48),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isDarkActive == option.dark
                              ? tokens.primary
                              : tokens.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDarkActive == option.dark
                                ? tokens.primary
                                : tokens.lineStrong,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              option.icon,
                              size: 18,
                              color: isDarkActive == option.dark
                                  ? tokens.onPrimary
                                  : tokens.ink,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  option.label,
                                  maxLines: 1,
                                  style: LabTheme.textStyle(
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.w700,
                                    color: isDarkActive == option.dark
                                        ? tokens.onPrimary
                                        : tokens.ink,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (!option.dark) const SizedBox(width: 10),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Text(
            strings.comfortModeTitle,
            style: LabTheme.textStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.w700,
              color: tokens.ink,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _textSizeCard(
                  tokens: tokens,
                  sample: 'Aa',
                  sampleSize: 18,
                  label: strings.normalTextLabel,
                  selected: !comfortMode,
                  onTap: () => ref
                      .read(displayComfortProvider.notifier)
                      .setComfortMode(false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _textSizeCard(
                  key: const ValueKey('onboarding-comfort-mode-toggle'),
                  tokens: tokens,
                  sample: 'AA',
                  sampleSize: 22,
                  label: strings.largerTextLabel,
                  selected: comfortMode,
                  onTap: () => ref
                      .read(displayComfortProvider.notifier)
                      .setComfortMode(!comfortMode),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _textSizeCard({
    Key? key,
    required MindTokens tokens,
    required String sample,
    required double sampleSize,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: MindPressable(
        key: key,
        onPressed: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(tokens.tileRadius),
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: selected ? tokens.primary : tokens.surface,
            borderRadius: BorderRadius.circular(tokens.tileRadius),
            border: Border.all(
              color: selected ? tokens.primary : tokens.lineStrong,
              width: selected ? 2.0 : 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                sample,
                style: LabTheme.textStyle(
                  fontSize: sampleSize,
                  fontWeight: FontWeight.w800,
                  color: selected ? tokens.onPrimary : tokens.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: LabTheme.textStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w700,
                  color: selected ? tokens.onPrimary : tokens.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepAgeSafety(MindTokens tokens, AppStrings strings) {
    return SingleChildScrollView(
      key: const ValueKey('onboarding_step_age'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            strings.onboardingAboutYouTitle,
            style: LabTheme.textStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.25,
              color: tokens.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            strings.onboardingBasicInfoSubtitle,
            style: LabTheme.textStyle(
              fontSize: 15.5,
              height: 1.5,
              color: tokens.ink2,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _ageRanges.map((range) {
              final selected = _selectedAgeRange == range;
              return MindPressable(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedAgeRange = range);
                  if (range == '65+') {
                    ref.read(displayComfortProvider.notifier).setComfortMode(true);
                  }
                },
                borderRadius: BorderRadius.circular(tokens.buttonRadius),
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 112,
                    minHeight: 54,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? tokens.primary : tokens.surface,
                    borderRadius: BorderRadius.circular(tokens.buttonRadius),
                    border: Border.all(
                      color: selected ? tokens.primary : tokens.lineStrong,
                      width: selected ? 2.0 : 1.0,
                    ),
                  ),
                  child: Text(
                    _ageLabel(range, strings),
                    textAlign: TextAlign.center,
                    style: LabTheme.textStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: selected ? tokens.onPrimary : tokens.ink,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (_selectedAgeRange == '65+') ...[
            const SizedBox(height: 16),
            MindCard(
              variant: MindCardVariant.tint,
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(Icons.visibility_outlined, size: 20, color: tokens.ink),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      strings.ageAutoComfortBanner,
                      style: LabTheme.textStyle(
                        fontSize: 13.5,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                        color: tokens.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_isMinor) ...[
            const SizedBox(height: 18),
            MindCard(
              backgroundColor: tokens.safetySoft,
              borderColor: tokens.safety.withValues(alpha: 0.40),
              child: Row(
                children: [
                  Icon(Icons.shield_outlined, color: tokens.safety, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      strings.minorSupportNotice,
                      style: LabTheme.textStyle(
                        fontSize: 14.0,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                        color: tokens.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          MindCard(
            variant: MindCardVariant.flat,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.onboardingCrisisSafetyNote,
                  style: LabTheme.textStyle(
                    fontSize: 14.0,
                    height: 1.45,
                    color: tokens.ink2,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => SupportModalSheet.show(context),
                  icon: Icon(Icons.phone_in_talk_rounded, color: tokens.safety),
                  label: Text(
                    strings.openCrisisResourcesLabel,
                    style: LabTheme.textStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: tokens.safety,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepGoals(MindTokens tokens, AppStrings strings) {
    return SingleChildScrollView(
      key: const ValueKey('onboarding_step_goals'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            strings.onboardingGoalsTitle,
            style: LabTheme.textStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.25,
              color: tokens.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            strings.onboardingGoalsSub,
            style: LabTheme.textStyle(
              fontSize: 15.0,
              height: 1.45,
              color: tokens.ink2,
            ),
          ),
          const SizedBox(height: 18),
          for (final goalKey in _goalKeys) ...[
            MindPressable(
              key: ValueKey<String>('onboarding-goal-$goalKey'),
              onPressed: () {
                HapticFeedback.selectionClick();
                setState(() {
                  if (_selectedGoals.contains(goalKey)) {
                    _selectedGoals.remove(goalKey);
                  } else {
                    _selectedGoals.add(goalKey);
                  }
                });
              },
              borderRadius: BorderRadius.circular(tokens.rowRadius),
              child: Container(
                constraints: const BoxConstraints(minHeight: 58),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: _selectedGoals.contains(goalKey)
                      ? tokens.primary
                      : tokens.surface,
                  borderRadius: BorderRadius.circular(tokens.rowRadius),
                  border: Border.all(
                    color: _selectedGoals.contains(goalKey)
                        ? tokens.primary
                        : tokens.lineStrong,
                    width: _selectedGoals.contains(goalKey) ? 2.0 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _goalIcon(goalKey),
                      size: 22,
                      color: _selectedGoals.contains(goalKey)
                          ? tokens.onPrimary
                          : tokens.ink,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _goalLabel(goalKey, strings),
                        style: LabTheme.textStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: _selectedGoals.contains(goalKey)
                              ? tokens.onPrimary
                              : tokens.ink,
                        ),
                      ),
                    ),
                    Icon(
                      _selectedGoals.contains(goalKey)
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      size: 20,
                      color: _selectedGoals.contains(goalKey)
                          ? tokens.onPrimary
                          : tokens.ink3,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepCareAndFocus(MindTokens tokens, AppStrings strings) {
    return SingleChildScrollView(
      key: const ValueKey('onboarding_step_focus'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            strings.onboardingCareAndFocusTitle,
            style: LabTheme.textStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.25,
              color: tokens.ink,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            strings.onboardingDoctorCareQuestion,
            style: LabTheme.textStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: tokens.ink,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _careContextKeys.map((careKey) {
              final selected = _careContext == careKey;
              return MindPressable(
                key: ValueKey<String>('onboarding-care-$careKey'),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _careContext = careKey);
                },
                borderRadius: BorderRadius.circular(tokens.buttonRadius),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? tokens.primary : tokens.surface,
                    borderRadius: BorderRadius.circular(tokens.buttonRadius),
                    border: Border.all(
                      color: selected ? tokens.primary : tokens.lineStrong,
                    ),
                  ),
                  child: Text(
                    _careLabel(careKey, strings),
                    style: LabTheme.textStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: selected ? tokens.onPrimary : tokens.ink,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (_careContext == 'regular_doctor' ||
              _careContext == 'occasional_doctor') ...[
            const SizedBox(height: 16),
            MindCard(
              variant: MindCardVariant.tint,
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    strings.clinicCodeOptionalTitle,
                    style: LabTheme.textStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w700,
                      color: tokens.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    key: const ValueKey<String>('onboarding-clinic-code-input'),
                    controller: _clinicCodeController,
                    textCapitalization: TextCapitalization.characters,
                    style: LabTheme.textStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: tokens.ink,
                    ),
                    decoration: InputDecoration(
                      hintText: strings.clinicCodeFieldHint,
                      prefixIcon: Icon(
                        Icons.qr_code_outlined,
                        size: 20,
                        color: tokens.ink2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 22),
          Text(
            strings.onboardingFocusAreasQuestion,
            style: LabTheme.textStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: tokens.ink,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _focusAreaKeys.map((focusKey) {
              final selected = _selectedFocusAreas.contains(focusKey);
              return MindPressable(
                key: ValueKey<String>('onboarding-focus-$focusKey'),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    if (selected) {
                      _selectedFocusAreas.remove(focusKey);
                    } else {
                      _selectedFocusAreas.add(focusKey);
                    }
                  });
                },
                borderRadius: BorderRadius.circular(tokens.chipRadius),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? tokens.primary : tokens.surface2,
                    borderRadius: BorderRadius.circular(tokens.chipRadius),
                    border: Border.all(
                      color: selected ? tokens.primary : tokens.lineStrong,
                    ),
                  ),
                  child: Text(
                    _focusLabel(focusKey, strings),
                    style: LabTheme.textStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w700,
                      color: selected ? tokens.onPrimary : tokens.ink,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 22),
          Text(
            strings.pickWhatYouNavigateQuestion,
            style: LabTheme.textStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: tokens.ink,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _starterTracks.map((track) {
              final selected = _selectedTrackIds.contains(track.id);
              return MindPressable(
                key: ValueKey<String>('onboarding-track-${track.id}'),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    if (selected) {
                      _selectedTrackIds.remove(track.id);
                    } else {
                      _selectedTrackIds.add(track.id);
                    }
                  });
                },
                borderRadius: BorderRadius.circular(tokens.chipRadius),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? tokens.primary : tokens.surface2,
                    borderRadius: BorderRadius.circular(tokens.chipRadius),
                    border: Border.all(
                      color: selected ? tokens.primary : tokens.lineStrong,
                    ),
                  ),
                  child: Text(
                    track.localizedTitle(strings),
                    style: LabTheme.textStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: selected ? tokens.onPrimary : tokens.ink,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const ValueKey('onboarding-search-300-conditions-btn'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(48, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(tokens.buttonRadius),
              ),
              side: BorderSide(color: tokens.lineStrong),
            ),
            onPressed: () async {
              final res = await ClinicalConditionSearchSheet.show(
                context,
                initialConditionIds: _selectedConditionIds.toList(),
                initialTrackIds: _selectedTrackIds.toList(),
              );
              if (res != null && mounted) {
                setState(() {
                  _selectedConditionIds
                    ..clear()
                    ..addAll(res.selectedConditionIds);
                  _selectedTrackIds
                    ..clear()
                    ..addAll(res.selectedTrackIds);
                });
              }
            },
            icon: Icon(Icons.search_rounded, size: 18, color: tokens.ink),
            label: Text(
              _selectedConditionIds.isEmpty
                  ? strings.search300ConditionsCta
                  : '${strings.search300ConditionsCta} (${_selectedConditionIds.length})',
              style: LabTheme.textStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: tokens.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepFirstMood(MindTokens tokens, AppStrings strings) {
    final textScale = MediaQuery.textScalerOf(context).scale(16.0) / 16.0;
    final previewDraft = _buildProfileDraft(
      ref.read(profileControllerProvider).value,
      'preview',
      step: _totalSteps,
    );
    final plan = AppPersonalizationEngine.resolve(previewDraft);
    final resolvedTracks = ClinicalConditionCatalog.resolveTracks(previewDraft);
    final tailoredPills = <String>[
      for (final t in resolvedTracks)
        if (t != ClinicalTrack.generalWellness) t.localizedTitle(strings),
      if (plan.prioritizeSleepPulse) strings.summarySleepEnabled,
      if (plan.isDoctorFollowed) strings.summaryDoctorReadyEnabled,
      if (plan.emphasizeCalmTools) strings.summaryCalmToolsEnabled,
      if (plan.isMinimalExplorationMode) strings.summaryMinimalEnabled,
    ];

    return SingleChildScrollView(
      key: const ValueKey('onboarding_step_first_mood'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (tailoredPills.isNotEmpty) ...[
            MindCard(
              variant: MindCardVariant.tint,
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.tailoredForYouTitle,
                    style: LabTheme.textStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: tokens.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      for (final p in tailoredPills)
                        MindBadge(
                          icon: Icons.check_circle_outline_rounded,
                          label: p,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            strings.howAreYouRightNow,
            style: LabTheme.textStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.25,
              color: tokens.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            strings.onboardingFirstCheckInSubtitle,
            style: LabTheme.textStyle(
              fontSize: 15.0,
              height: 1.45,
              color: tokens.ink2,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = (constraints.maxWidth < 330 || textScale > 1.25)
                  ? 2
                  : 3;
              final tileWidth =
                  (constraints.maxWidth - (cols - 1) * 10) / cols;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final mood in AppMood.values)
                    SizedBox(
                      width: tileWidth,
                      child: MoodFaceTile(
                        mood: mood,
                        label: strings.plainMoodLabel(mood.key),
                        isSelected: _selectedMood == mood,
                        onTap: () => setState(() => _selectedMood = mood),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
            strings.howStrongQuestion,
            style: LabTheme.textStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: tokens.ink,
            ),
          ),
          const SizedBox(height: 10),
          MindStrengthPicker(
            selectedIntensity: _firstIntensity,
            aLittleLabel: strings.strengthALittle,
            mediumLabel: strings.strengthMedium,
            aLotLabel: strings.strengthALot,
            accentColor: MindTokens.moodColor(_selectedMood),
            onSelected: (v) => setState(() => _firstIntensity = v),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(MindTokens tokens, AppStrings strings) {
    final ctaLabel = _currentStep == 0
        ? strings.onboardingStartBtn
        : (_currentStep >= _totalSteps - 1
              ? strings.saveAndEnterBtn
              : strings.continueBtn);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MindButton(
            text: ctaLabel,
            isFullWidth: true,
            isLoading: _isFinishing,
            onPressed: _nextStep,
          ),
          if (_currentStep == 0) ...[
            const SizedBox(height: 10),
            MindButton(
              text: strings.signInTab,
              variant: MindButtonVariant.soft,
              isFullWidth: true,
              onPressed: () => GoRouter.maybeOf(context)?.push(AppRouter.auth),
            ),
          ],
        ],
      ),
    );
  }
}
