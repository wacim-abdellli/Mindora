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
import '../../../core/widgets/mind_segmented.dart';
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

/// Adaptive, 100% options-first 6-step onboarding for Mindora.
///
/// Step 1: Language (`العربية (تونس)`, `Français`, `English`), Theme & Comfort size.
/// Step 2: Role Gate (`For myself` vs `I am a Doctor / Psychiatrist` -> routes to `/clinician`).
/// Step 3: Age group (Under 18 safeguard + hotlines; 65+ auto-enables Comfort Mode).
/// Step 4: Multi-select goals (shapes Home & Doctor Prep features).
/// Step 5: Care context + Daily focus areas (Sleep, Energy, Stress, Overthinking, Routine).
/// Step 6: Decision Summary preview + First 2-tap MoodFace check-in.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const int _totalSteps = 6;

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

  String _userRole = 'patient';
  String _selectedAgeRange = '';
  final Set<String> _selectedGoals = <String>{};
  String _careContext = '';
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

  void _hydrateFromExistingProfile() {
    if (_hydrated) return;
    final profile = ref.read(profileControllerProvider).value;
    if (profile == null) return;
    _hydrated = true;

    setState(() {
      if (profile.userRole.isNotEmpty) {
        _userRole = profile.userRole;
      }
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
      userRole: _userRole,
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

  Future<void> _enterClinicianWorkspace() async {
    if (_isFinishing) return;
    setState(() {
      _userRole = 'clinician';
      _isFinishing = true;
    });
    HapticFeedback.mediumImpact();
    try {
      final authCtrl = ref.read(authControllerProvider.notifier);
      await authCtrl.createAnonymousVault();
      await authCtrl.completeOnboarding();

      final currentProfile = await ref.read(profileControllerProvider.future);
      final userId = ref.read(authControllerProvider).user?.id ?? 'local_user';
      final profile = _buildProfileDraft(
        currentProfile,
        userId,
        step: _totalSteps,
      );
      await ref
          .read(profileControllerProvider.notifier)
          .saveFullProfile(profile);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('mf_preferred_workspace', 'clinician');

      if (mounted) {
        GoRouter.maybeOf(context)?.go(AppRouter.clinician);
      }
    } finally {
      if (mounted) {
        setState(() => _isFinishing = false);
      }
    }
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Row(
                children: [
                  for (var i = 0; i < _totalSteps; i++) ...[
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
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 12, 4),
        child: Row(
          children: [
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppLanguage.values.map((lang) {
                  final selected = activeLocale.languageCode == lang.code;
                  return MindPressable(
                    semanticLabel: lang.displayName,
                    borderRadius: BorderRadius.circular(14),
                    onPressed: () {
                      ref
                          .read(localeControllerProvider.notifier)
                          .setLanguage(lang);
                    },
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: selected ? tokens.primary : tokens.surface2,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected ? tokens.primary : tokens.line,
                        ),
                      ),
                      child: Center(
                        widthFactor: 1.0,
                        heightFactor: 1.0,
                        child: Text(
                          lang.shortCode,
                          style: TextStyle(
                            fontFamily: LabTheme.fontFamily,
                            fontFamilyFallback: LabTheme.fontFallback,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: selected ? tokens.onPrimary : tokens.ink,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SupportButton(),
          ],
        ),
      );
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
          if (_currentStep != 1)
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
            )
          else
            const SupportButton(compact: true),
        ],
      ),
    );
  }

  Widget _buildActiveStep(MindTokens tokens, AppStrings strings) {
    return switch (_currentStep) {
      0 => _buildStepWelcome(tokens, strings),
      1 => _buildStepRoleGate(tokens, strings),
      2 => _buildStepAgeSafety(tokens, strings),
      3 => _buildStepGoals(tokens, strings),
      4 => _buildStepCareAndFocus(tokens, strings),
      _ => _buildStepFirstMood(tokens, strings),
    };
  }

  Widget _buildStepWelcome(MindTokens tokens, AppStrings strings) {
    final comfortMode = ref.watch(displayComfortProvider);
    final themeMode = ref.watch(themeControllerProvider);
    final activeLocale = ref.watch(localeControllerProvider);

    return SingleChildScrollView(
      key: const ValueKey('onboarding_step_0'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(
            child: MoodFace(
              mood: AppMood.good,
              size: 80,
              isSelected: true,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Mindora',
            textAlign: TextAlign.center,
            style: LabTheme.textStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.2,
              color: tokens.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            strings.onboardingWelcomeBody,
            textAlign: TextAlign.center,
            style: LabTheme.textStyle(
              fontSize: 16.0,
              height: 1.45,
              color: tokens.ink2,
            ),
          ),
          const SizedBox(height: 16),
          MindCard(
            variant: MindCardVariant.flat,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.lock_outline_rounded, size: 20, color: tokens.ink),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    strings.onboardingPrivacyPromise,
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
          const SizedBox(height: 18),
          Text(
            strings.languageTitle,
            style: LabTheme.textStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: tokens.ink,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppLanguage.values.map((lang) {
              final selected = activeLocale.languageCode == lang.code;
              return MindPressable(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  ref.read(localeControllerProvider.notifier).setLanguage(lang);
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48, minWidth: 96),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? tokens.primary : tokens.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected ? tokens.primary : tokens.lineStrong,
                    ),
                  ),
                  child: Text(
                    lang.displayName,
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
          const SizedBox(height: 16),
          Text(
            strings.themeModeTitle,
            style: LabTheme.textStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: tokens.ink,
            ),
          ),
          const SizedBox(height: 8),
          MindSegmented(
            index: themeMode == ThemeMode.dark ? 1 : 0,
            labels: [strings.themeDaylight, strings.themeNight],
            onChanged: (idx) {
              HapticFeedback.selectionClick();
              ref
                  .read(themeControllerProvider.notifier)
                  .setTheme(idx == 1 ? ThemeMode.dark : ThemeMode.light);
            },
          ),
          const SizedBox(height: 16),
          Text(
            strings.comfortModeTitle,
            style: LabTheme.textStyle(
              fontSize: 14.5,
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

  Widget _buildStepRoleGate(MindTokens tokens, AppStrings strings) {
    return SingleChildScrollView(
      key: const ValueKey('onboarding_step_role'),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            strings.onboardingRoleTitle,
            style: LabTheme.textStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.25,
              color: tokens.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            strings.onboardingRoleSubtitle,
            style: LabTheme.textStyle(
              fontSize: 15.5,
              height: 1.45,
              color: tokens.ink2,
            ),
          ),
          const SizedBox(height: 22),
          _roleOptionCard(
            key: const ValueKey('onboarding-role-patient'),
            tokens: tokens,
            icon: Icons.favorite_outline_rounded,
            title: strings.rolePatientTitle,
            subtitle: strings.rolePatientSub,
            selected: _userRole == 'patient',
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _userRole = 'patient');
              _nextStep();
            },
          ),
          const SizedBox(height: 14),
          _roleOptionCard(
            key: const ValueKey('onboarding-role-clinician'),
            tokens: tokens,
            icon: Icons.medical_services_outlined,
            title: strings.roleClinicianTitle,
            subtitle: strings.roleClinicianSub,
            selected: _userRole == 'clinician',
            onTap: _enterClinicianWorkspace,
          ),
        ],
      ),
    );
  }

  Widget _roleOptionCard({
    Key? key,
    required MindTokens tokens,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      selected: selected,
      label: title,
      child: MindPressable(
        key: key,
        onPressed: onTap,
        borderRadius: BorderRadius.circular(tokens.cardRadius),
        child: Container(
          constraints: const BoxConstraints(minHeight: 88),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: selected ? tokens.surface2 : tokens.surface,
            borderRadius: BorderRadius.circular(tokens.cardRadius),
            border: Border.all(
              color: selected ? tokens.primary : tokens.lineStrong,
              width: selected ? 2.0 : 1.0,
            ),
            boxShadow: tokens.shadows,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: selected ? tokens.primary : tokens.surface2,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: selected ? tokens.onPrimary : tokens.ink,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: LabTheme.textStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: tokens.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: LabTheme.textStyle(
                        fontSize: 13.5,
                        height: 1.4,
                        color: tokens.ink2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: tokens.ink2),
            ],
          ),
        ),
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
          if (_currentStep != 1)
            MindButton(
              text: ctaLabel,
              isFullWidth: true,
              isLoading: _isFinishing,
              onPressed: _nextStep,
            ),
          if (_currentStep == 0) ...[
            const SizedBox(height: 6),
            Center(
              child: TextButton(
                onPressed: () => GoRouter.maybeOf(context)?.push(AppRouter.auth),
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  foregroundColor: tokens.ink2,
                ),
                child: Text(
                  strings.signInTab,
                  style: LabTheme.textStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: tokens.ink2,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
