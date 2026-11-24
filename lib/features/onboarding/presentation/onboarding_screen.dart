import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/localization/locale_controller.dart';
import '../../../app/router/app_router.dart';
import '../../../app/theme/display_comfort_controller.dart';
import '../../../app/theme/mind_tokens.dart';
import '../../../core/safety/crisis_keywords.dart';
import '../../../core/safety/safety_interceptor.dart';
import '../../../core/safety/support_button.dart';
import '../../../core/widgets/ambient_scaffold.dart';
import '../../../core/widgets/fingerprint_thread_signature.dart';
import '../../../core/widgets/mind_button.dart';
import '../../../core/widgets/mind_card.dart';
import '../../../core/widgets/mind_intensity_picker.dart';
import '../../../core/widgets/mind_pressable.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../journey/controllers/journey_controller.dart';
import '../../mind_trace/controllers/mind_trace_controller.dart';
import '../../mind_trace/domain/mind_trace_model.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../profile/domain/psychological_profile_model.dart';

/// Fast 4-step, options-first onboarding for Mindora.
///
/// Steps:
/// 0: Welcome, live EN/FR/AR switcher, privacy promise & account restore link
/// 1: Focus priorities (1-3 wrapped cards, optional)
/// 2: Comfort & safety check (optional age band + minor safeguard + support context)
/// 3: First check-in (5 core moods + 1-10 intensity) for a zero-blank-screen Home handoff
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const int _totalSteps = 4;

  static const List<String> _ageRanges = [
    'under_18',
    '18-24',
    '25-34',
    '35-44',
    '45-54',
    '55-64',
    '65+',
    'prefer_not_to_say',
  ];

  static const List<({String id, String canonicalGoal, IconData icon})>
  _focusOptions = [
    (
      id: 'stress',
      canonicalGoal: 'Ease stress & anxiety',
      icon: Icons.air_rounded,
    ),
    (
      id: 'mood',
      canonicalGoal: 'Understand mood patterns',
      icon: Icons.insights_rounded,
    ),
    (
      id: 'overthinking',
      canonicalGoal: 'Untangle overthinking',
      icon: Icons.psychology_alt_outlined,
    ),
    (
      id: 'sleep',
      canonicalGoal: 'Sleep & energy rhythm',
      icon: Icons.bedtime_outlined,
    ),
    (
      id: 'specialist',
      canonicalGoal: 'Reflect alongside a specialist',
      icon: Icons.handshake_outlined,
    ),
  ];

  static const List<({String key, IconData icon, Color color})> _moodOptions = [
    (key: 'calm', icon: Icons.water_drop_outlined, color: MindTokens.moodCalm),
    (key: 'anxious', icon: Icons.air_rounded, color: MindTokens.moodAnxious),
    (
      key: 'frustrated',
      icon: Icons.bolt_rounded,
      color: MindTokens.moodFrustrated,
    ),
    (key: 'heavy', icon: Icons.cloud_outlined, color: MindTokens.moodHeavy),
    (
      key: 'restless',
      icon: Icons.waves_rounded,
      color: MindTokens.moodRestless,
    ),
  ];

  int _currentStep = 0;
  bool _hydrated = false;
  bool _isFinishing = false;
  bool _recordedFirstCheckIn = false;

  // Step 2: Focus areas
  final Set<String> _selectedGoals = {};
  final TextEditingController _customGoalController = TextEditingController();
  bool _showCustomGoalField = false;

  // Step 3: Comfort & safety context
  String _selectedAgeRange = '';
  String _selectedProfessionalSupport = '';

  // Step 4: First check-in
  String _selectedMood = 'calm';
  int _firstIntensity = 5;

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
    _customGoalController.dispose();
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
      if (profile.professionalSupport.isNotEmpty) {
        _selectedProfessionalSupport = profile.professionalSupport;
      }
      if (profile.selectedGoals.isNotEmpty) {
        _selectedGoals.addAll(profile.selectedGoals);
      }
      if (profile.customGoal.isNotEmpty) {
        _customGoalController.text = profile.customGoal;
        _showCustomGoalField = true;
      }
      if (profile.onboardingStep > 0) {
        _currentStep = profile.onboardingStep.clamp(0, _totalSteps - 1);
      }
    });
  }

  Future<void> _saveDraftProgress() async {
    final currentProfile = ref.read(profileControllerProvider).value;
    final userId = ref.read(authControllerProvider).user?.id ?? 'local_user';
    final customGoalText = _customGoalController.text.trim();
    final goalsList = _selectedGoals.toList();
    final draft =
        (currentProfile ?? PsychologicalProfileModel.empty(userId: userId))
            .copyWith(
              ageRange: _selectedAgeRange,
              selectedGoals: goalsList,
              customGoal: customGoalText,
              personalGoals: [
                ...goalsList,
                if (customGoalText.isNotEmpty) customGoalText,
              ].join(', '),
              professionalSupport: _selectedProfessionalSupport,
              onboardingStep: _currentStep,
              updatedAt: DateTime.now(),
            );
    await ref.read(profileControllerProvider.notifier).saveFullProfile(draft);
  }

  void _nextStep() {
    if (_currentStep == 1) {
      final customGoalText = _customGoalController.text.trim();
      if (customGoalText.isNotEmpty &&
          CrisisKeywords.evaluateText(customGoalText) == 2) {
        SafetyInterceptor.showCrisisPauseDialog(context);
        return;
      }
    }
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
    final customGoalText = _customGoalController.text.trim();
    if (customGoalText.isNotEmpty &&
        CrisisKeywords.evaluateText(customGoalText) == 2) {
      SafetyInterceptor.showCrisisPauseDialog(context);
      return;
    }
    setState(() => _isFinishing = true);
    HapticFeedback.mediumImpact();

    try {
      final authCtrl = ref.read(authControllerProvider.notifier);
      await authCtrl.createAnonymousVault();
      await authCtrl.completeOnboarding();

      // Wait for post-vault Riverpod rebuilds to finish so neither notifier
      // overwrites the newly saved final profile or first check-in trace.
      final currentProfile = await ref.read(profileControllerProvider.future);
      await ref.read(mindTraceControllerProvider.future);

      final userId = ref.read(authControllerProvider).user?.id ?? 'local_user';
      final goalsList = _selectedGoals.toList();
      final fullGoals = [
        ...goalsList,
        if (customGoalText.isNotEmpty) customGoalText,
      ].join(', ');

      final profile = currentProfile.copyWith(
        userId: userId,
        ageRange: _selectedAgeRange,
        selectedGoals: goalsList,
        customGoal: customGoalText,
        personalGoals: fullGoals,
        professionalSupport: _selectedProfessionalSupport,
        onboardingStep: _totalSteps,
        updatedAt: DateTime.now(),
      );

      await ref
          .read(profileControllerProvider.notifier)
          .saveFullProfile(profile);
      await ref.read(journeyControllerProvider.notifier).resetJourney();

      if (saveInitialTrace && !_recordedFirstCheckIn) {
        _recordedFirstCheckIn = true;
        final now = DateTime.now();
        final newTrace = MindTraceModel(
          id: 'trace_${now.millisecondsSinceEpoch}',
          userId: userId,
          date: now,
          overallMood: _selectedMood,
          moodIntensity: _firstIntensity,
          energyLevel: null,
          selectedEmotions: [_selectedMood],
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

  String _focusLabel(String id, AppStrings strings) {
    switch (id) {
      case 'stress':
        return strings.focusGoalStress;
      case 'mood':
        return strings.focusGoalMood;
      case 'overthinking':
        return strings.focusGoalOverthinking;
      case 'sleep':
        return strings.focusGoalSleepEnergy;
      case 'specialist':
      default:
        return strings.focusGoalSpecialist;
    }
  }

  String _moodLabel(String key, AppStrings strings) {
    switch (key) {
      case 'calm':
        return strings.moodCalm;
      case 'anxious':
        return strings.moodAnxious;
      case 'frustrated':
        return strings.moodFrustrated;
      case 'heavy':
        return strings.moodHeavy;
      case 'restless':
      default:
        return strings.moodRestless;
    }
  }

  Color _moodColor(String key) {
    return _moodOptions
        .firstWhere((m) => m.key == key, orElse: () => _moodOptions.first)
        .color;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<PsychologicalProfileModel?>>(
      profileControllerProvider,
      (previous, next) {
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
            Expanded(
              child: AnimatedSwitcher(
                duration: reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeIn,
                layoutBuilder: (currentChild, previousChildren) {
                  return Stack(
                    alignment: Alignment.topCenter,
                    children: [...previousChildren, ?currentChild],
                  );
                },
                child: _buildActiveStep(tokens, strings),
              ),
            ),
            _buildBottomCtaBar(tokens, strings),
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
        padding: const EdgeInsets.fromLTRB(16, 10, 12, 6),
        child: Row(
          children: [
            Expanded(
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: AppLanguage.values.map((lang) {
                  final selected = activeLocale.languageCode == lang.code;
                  return MindPressable(
                    semanticLabel: lang.displayName,
                    borderRadius: BorderRadius.circular(12),
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
                        color: selected
                            ? tokens.selectedTintFor(tokens.m1)
                            : tokens.surface2,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected ? tokens.m1 : tokens.line,
                          width: selected ? 1.4 : 1.0,
                        ),
                      ),
                      child: Center(
                        widthFactor: 1.0,
                        heightFactor: 1.0,
                        child: Text(
                          lang.shortCode,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: selected ? tokens.ink : tokens.ink2,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SupportButton(compact: true),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            color: tokens.ink,
            tooltip: strings.backBtn,
            onPressed: _previousStep,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Row(
              children: List.generate(_totalSteps, (index) {
                final active = index <= _currentStep;
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: active ? tokens.m1 : tokens.line,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 6),
          MindPressable(
            semanticLabel: strings.onboardingSkip,
            borderRadius: BorderRadius.circular(tokens.chipRadius),
            onPressed: _skipCurrentStep,
            child: Container(
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              child: Text(
                strings.onboardingSkip,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: tokens.ink2,
                ),
              ),
            ),
          ),
          const SupportButton(compact: true),
        ],
      ),
    );
  }

  Widget _buildActiveStep(MindTokens tokens, AppStrings strings) {
    switch (_currentStep) {
      case 0:
        return _buildWelcomeStep(tokens, strings);
      case 1:
        return _buildFocusStep(tokens, strings);
      case 2:
        return _buildComfortSafetyStep(tokens, strings);
      case 3:
      default:
        return _buildFirstCheckInStep(tokens, strings);
    }
  }

  Widget _buildWelcomeStep(MindTokens tokens, AppStrings strings) {
    return SingleChildScrollView(
      key: const ValueKey('onboarding_step_0'),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepCounter(tokens, strings.onboardingStepOf(1, _totalSteps)),
          const SizedBox(height: 24),
          Center(
            child: Container(
              width: 108,
              height: 108,
              decoration: BoxDecoration(
                color: tokens.blobTintFor(tokens.m1),
                shape: BoxShape.circle,
                border: Border.all(color: tokens.m1.withValues(alpha: 0.25)),
              ),
              alignment: Alignment.center,
              child: FingerprintThreadSignature(
                size: 70,
                primaryColor: tokens.m1,
                accentColor: tokens.ink2,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            strings.onboardingWelcomeHeadline,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              height: 1.2,
              letterSpacing: -0.5,
              color: tokens.ink,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            strings.onboardingWelcomeBody,
            style: TextStyle(fontSize: 14.5, height: 1.55, color: tokens.ink2),
          ),
          const SizedBox(height: 24),
          MindCard(
            variant: MindCardVariant.plain,
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined, size: 20, color: tokens.m1),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    strings.onboardingPrivacyPromise,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.48,
                      color: tokens.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Builder(
            builder: (context) {
              final comfortMode = ref.watch(displayComfortProvider);
              return MindPressable(
                key: const ValueKey('onboarding-comfort-mode-toggle'),
                semanticLabel: strings.comfortModeTitle,
                borderRadius: BorderRadius.circular(14),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  ref.read(displayComfortProvider.notifier).toggle();
                },
                child: MindCard(
                  variant: MindCardVariant.plain,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.visibility_outlined,
                        size: 18,
                        color: tokens.m1,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.comfortModeTitle,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: tokens.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              strings.comfortModeOnboardingHint,
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.35,
                                color: tokens.ink2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IgnorePointer(
                        child: SizedBox(
                          height: 28,
                          child: Switch.adaptive(
                            value: comfortMode,
                            activeTrackColor: tokens.m1,
                            onChanged: (_) {},
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Center(
            child: MindPressable(
              semanticLabel: strings.signInPromptBtn,
              borderRadius: BorderRadius.circular(12),
              onPressed: () {
                GoRouter.maybeOf(context)?.push(AppRouter.auth);
              },
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                alignment: Alignment.center,
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Text(
                      strings.alreadyHaveVaultPrompt,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: tokens.ink2),
                    ),
                    Text(
                      strings.signInPromptBtn,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: tokens.m1,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFocusStep(MindTokens tokens, AppStrings strings) {
    return SingleChildScrollView(
      key: const ValueKey('onboarding_step_1'),
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepCounter(tokens, strings.onboardingStepOf(2, _totalSteps)),
          const SizedBox(height: 12),
          Text(
            strings.onboardingFocusTitle,
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w700,
              height: 1.25,
              letterSpacing: -0.4,
              color: tokens.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            strings.onboardingFocusSubtitle,
            style: TextStyle(fontSize: 13.5, height: 1.48, color: tokens.ink2),
          ),
          const SizedBox(height: 20),
          ..._focusOptions.map((option) {
            final isSelected = _selectedGoals.contains(option.canonicalGoal);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: MindPressable(
                semanticLabel: _focusLabel(option.id, strings),
                borderRadius: BorderRadius.circular(16),
                onPressed: () {
                  setState(() {
                    if (isSelected) {
                      _selectedGoals.remove(option.canonicalGoal);
                    } else {
                      _selectedGoals.add(option.canonicalGoal);
                    }
                  });
                  _saveDraftProgress();
                },
                child: Container(
                  constraints: const BoxConstraints(minHeight: 54),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? tokens.selectedTintFor(tokens.m1)
                        : tokens.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? tokens.m1 : tokens.line,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        option.icon,
                        size: 20,
                        color: isSelected ? tokens.m1 : tokens.ink2,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          _focusLabel(option.id, strings),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: tokens.ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(
                        isSelected
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 20,
                        color: isSelected ? tokens.m1 : tokens.line,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 6),
          MindPressable(
            semanticLabel: strings.addCustomGoalToggle,
            borderRadius: BorderRadius.circular(12),
            onPressed: () {
              setState(() => _showCustomGoalField = !_showCustomGoalField);
            },
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              alignment: AlignmentDirectional.centerStart,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _showCustomGoalField
                        ? Icons.expand_less_rounded
                        : Icons.add_circle_outline_rounded,
                    size: 18,
                    color: tokens.m1,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      strings.addCustomGoalToggle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: tokens.m1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_showCustomGoalField) ...[
            const SizedBox(height: 6),
            TextField(
              controller: _customGoalController,
              onChanged: (_) => _saveDraftProgress(),
              maxLines: 2,
              style: TextStyle(fontSize: 14, color: tokens.ink),
              decoration: InputDecoration(
                hintText: strings.customGoalHint,
                hintStyle: TextStyle(color: tokens.ink3, fontSize: 13),
                filled: true,
                fillColor: tokens.surface2,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
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
                  borderSide: BorderSide(color: tokens.focusRing, width: 2.0),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildComfortSafetyStep(MindTokens tokens, AppStrings strings) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final supportOptions = [
      (
        key: 'therapist',
        label: strings.supportOptionSpecialist,
        icon: Icons.psychology_outlined,
      ),
      (
        key: 'self_guided',
        label: strings.supportOptionSelfGuided,
        icon: Icons.self_improvement_rounded,
      ),
      (
        key: 'prefer_not_to_say',
        label: strings.supportOptionPreferNotToSay,
        icon: Icons.visibility_off_outlined,
      ),
    ];

    return SingleChildScrollView(
      key: const ValueKey('onboarding_step_2'),
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepCounter(tokens, strings.onboardingStepOf(3, _totalSteps)),
          const SizedBox(height: 12),
          Text(
            strings.onboardingComfortTitle,
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w700,
              height: 1.25,
              letterSpacing: -0.4,
              color: tokens.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            strings.onboardingComfortSubtitle,
            style: TextStyle(fontSize: 13.5, height: 1.48, color: tokens.ink2),
          ),
          const SizedBox(height: 20),
          Text(
            strings.ageRangeLabel.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
              color: tokens.ink2,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _ageRanges.map((range) {
              final selected = _selectedAgeRange == range;
              final display = strings.ageRangeDisplayName(range);
              return MindPressable(
                semanticLabel: display,
                borderRadius: BorderRadius.circular(14),
                onPressed: () {
                  setState(() => _selectedAgeRange = range);
                  _saveDraftProgress();
                },
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? tokens.selectedTintFor(tokens.m1)
                        : tokens.surface2,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected ? tokens.m1 : tokens.line,
                      width: selected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Center(
                    widthFactor: 1.0,
                    heightFactor: 1.0,
                    child: Text(
                      display,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: selected ? tokens.ink : tokens.ink2,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          AnimatedSize(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: _isMinor
                ? Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: tokens.safetySoft,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: tokens.safety.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 18,
                            color: tokens.safety,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              strings.minorSupportNotice,
                              style: TextStyle(
                                fontSize: 12.5,
                                height: 1.48,
                                color: tokens.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 22),
          Text(
            strings.supportSystemTitle.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
              color: tokens.ink2,
            ),
          ),
          const SizedBox(height: 10),
          ...supportOptions.map((opt) {
            final selected = _selectedProfessionalSupport == opt.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: MindPressable(
                semanticLabel: opt.label,
                borderRadius: BorderRadius.circular(16),
                onPressed: () {
                  setState(() => _selectedProfessionalSupport = opt.key);
                  _saveDraftProgress();
                },
                child: Container(
                  constraints: const BoxConstraints(minHeight: 50),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? tokens.selectedTintFor(tokens.m1)
                        : tokens.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected ? tokens.m1 : tokens.line,
                      width: selected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        opt.icon,
                        size: 19,
                        color: selected ? tokens.m1 : tokens.ink2,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          opt.label,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: tokens.ink,
                          ),
                        ),
                      ),
                      Icon(
                        selected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 18,
                        color: selected ? tokens.m1 : tokens.line,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: tokens.safetySoft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: tokens.safety.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.health_and_safety_outlined,
                      size: 18,
                      color: tokens.safety,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        strings.onboardingCrisisSafetyNote,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.48,
                          color: tokens.ink,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: MindPressable(
                    semanticLabel: strings.openCrisisResourcesLabel,
                    borderRadius: BorderRadius.circular(tokens.chipRadius),
                    onPressed: () => SupportModalSheet.show(context),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 48),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        strings.openCrisisResourcesLabel,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: tokens.safety,
                        ),
                      ),
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

  Widget _buildFirstCheckInStep(MindTokens tokens, AppStrings strings) {
    final activeMoodColor = _moodColor(_selectedMood);

    return SingleChildScrollView(
      key: const ValueKey('onboarding_step_3'),
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepCounter(tokens, strings.onboardingStepOf(4, _totalSteps)),
          const SizedBox(height: 12),
          Text(
            strings.howFeelingRightNow,
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w700,
              height: 1.25,
              letterSpacing: -0.4,
              color: tokens.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            strings.onboardingFirstCheckInSubtitle,
            style: TextStyle(fontSize: 13.5, height: 1.48, color: tokens.ink2),
          ),
          const SizedBox(height: 22),
          Text(
            strings.todaysCoreState,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
              color: tokens.ink2,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _moodOptions.map((mood) {
              final selected = _selectedMood == mood.key;
              final label = _moodLabel(mood.key, strings);
              return MindPressable(
                semanticLabel: label,
                borderRadius: BorderRadius.circular(16),
                onPressed: () {
                  setState(() => _selectedMood = mood.key);
                },
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 96,
                    minHeight: 48,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: selected ? 13.4 : 14.0,
                    vertical: selected ? 9.4 : 10.0,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? tokens.selectedTintFor(mood.color)
                        : tokens.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected ? mood.color : tokens.line,
                      width: selected ? 1.6 : 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        mood.icon,
                        size: 18,
                        color: selected ? mood.color : tokens.ink2,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: tokens.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          MindCard(
            variant: MindCardVariant.plain,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        strings.moodIntensityLabel,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: tokens.ink,
                        ),
                      ),
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 185),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: tokens.selectedTintFor(activeMoodColor),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$_firstIntensity/10 · ${strings.intensityLevelWord(_firstIntensity)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: tokens.ink,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                MindIntensityPicker(
                  value: _firstIntensity,
                  accentColor: activeMoodColor,
                  strings: strings,
                  onChanged: (rounded) =>
                      setState(() => _firstIntensity = rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCounter(MindTokens tokens, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: tokens.surface2,
        borderRadius: BorderRadius.circular(tokens.chipRadius),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: tokens.ink2,
        ),
      ),
    );
  }

  Widget _buildBottomCtaBar(MindTokens tokens, AppStrings strings) {
    final String primaryLabel;
    switch (_currentStep) {
      case 0:
        primaryLabel = strings.onboardingGetStarted;
        break;
      case 3:
        primaryLabel = strings.saveAndEnterAppBtn;
        break;
      default:
        primaryLabel = strings.onboardingContinue;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border(top: BorderSide(color: tokens.line)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MindButton(
            text: primaryLabel,
            variant: MindButtonVariant.primary,
            isFullWidth: true,
            isLoading: _isFinishing,
            onPressed: _nextStep,
          ),
          if (_currentStep == _totalSteps - 1) ...[
            const SizedBox(height: 8),
            MindButton(
              text: strings.skipAndEnterAppBtn,
              variant: MindButtonVariant.ghost,
              isFullWidth: true,
              onPressed: _isFinishing
                  ? null
                  : () => _finishOnboarding(saveInitialTrace: false),
            ),
          ],
        ],
      ),
    );
  }
}
