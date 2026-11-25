import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/controllers/profile_controller.dart';
import '../../profile/domain/psychological_profile_model.dart';

/// Deterministic, privacy-preserving decision output derived from the user's
/// adaptive onboarding answers (`PsychologicalProfileModel`).
///
/// Directly tailors:
/// - Initial workspace routing (`clinician` vs `patient`)
/// - Accessibility Comfort Mode recommendation (`65+`)
/// - Which clinical daily pulse questions surface first on `Today`
/// - Whether Doctor Visit Prep & Routine Anchor prompts are highlighted
@immutable
class AppPersonalizationPlan {
  const AppPersonalizationPlan({
    required this.isClinician,
    required this.recommendComfortMode,
    required this.prioritizeSleepPulse,
    required this.isDoctorFollowed,
    required this.showRoutineAnchorQuestion,
    required this.emphasizeCalmTools,
    required this.isMinimalExplorationMode,
    required this.primaryNextActionKey,
  });

  final bool isClinician;
  final bool recommendComfortMode;
  final bool prioritizeSleepPulse;
  final bool isDoctorFollowed;
  final bool showRoutineAnchorQuestion;
  final bool emphasizeCalmTools;
  final bool isMinimalExplorationMode;

  /// One of `'clinician_workspace'`, `'doctor_visit_ready'`,
  /// `'morning_sleep_pulse'`, `'calm_breather'`, or `'daily_checkin'`.
  final String primaryNextActionKey;
}

abstract final class AppPersonalizationEngine {
  static AppPersonalizationPlan resolve(PsychologicalProfileModel? profile) {
    if (profile == null) {
      return const AppPersonalizationPlan(
        isClinician: false,
        recommendComfortMode: false,
        prioritizeSleepPulse: true,
        isDoctorFollowed: false,
        showRoutineAnchorQuestion: false,
        emphasizeCalmTools: true,
        isMinimalExplorationMode: false,
        primaryNextActionKey: 'daily_checkin',
      );
    }

    final isClinician = profile.userRole == 'clinician';
    final recommendComfortMode = profile.ageRange.trim() == '65+';

    final isDoctorFollowed =
        profile.careContext == 'regular_doctor' ||
        profile.careContext == 'occasional_doctor' ||
        profile.selectedGoals.contains('doctor_visits');

    final prioritizeSleepPulse =
        profile.focusAreas.contains('sleep') ||
        profile.focusAreas.contains('energy') ||
        profile.selectedGoals.contains('track_mood_sleep') ||
        profile.selectedGoals.contains('understand_energy') ||
        isDoctorFollowed;

    final showRoutineAnchorQuestion =
        profile.focusAreas.contains('routine') ||
        profile.careContext == 'regular_doctor';

    final emphasizeCalmTools =
        profile.focusAreas.contains('stress') ||
        profile.focusAreas.contains('overthinking') ||
        profile.selectedGoals.contains('calm_stress');

    final onlyExploring =
        profile.selectedGoals.length == 1 &&
        profile.selectedGoals.contains('just_exploring') &&
        profile.focusAreas.isEmpty &&
        !isDoctorFollowed;

    late final String nextAction;
    if (isClinician) {
      nextAction = 'clinician_workspace';
    } else if (isDoctorFollowed) {
      nextAction = 'doctor_visit_ready';
    } else if (prioritizeSleepPulse) {
      nextAction = 'morning_sleep_pulse';
    } else if (emphasizeCalmTools) {
      nextAction = 'calm_breather';
    } else {
      nextAction = 'daily_checkin';
    }

    return AppPersonalizationPlan(
      isClinician: isClinician,
      recommendComfortMode: recommendComfortMode,
      prioritizeSleepPulse: prioritizeSleepPulse,
      isDoctorFollowed: isDoctorFollowed,
      showRoutineAnchorQuestion: showRoutineAnchorQuestion,
      emphasizeCalmTools: emphasizeCalmTools,
      isMinimalExplorationMode: onlyExploring,
      primaryNextActionKey: nextAction,
    );
  }
}

final appPersonalizationPlanProvider = Provider<AppPersonalizationPlan>((ref) {
  final profile = ref.watch(profileControllerProvider).value;
  return AppPersonalizationEngine.resolve(profile);
});
