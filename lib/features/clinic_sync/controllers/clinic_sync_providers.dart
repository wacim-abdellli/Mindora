import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/locale_controller.dart';
import '../../../app/theme/display_comfort_controller.dart';
import '../../../app/theme/theme_controller.dart';
import '../../../core/security/secure_key_manager.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/domain/auth_user.dart';
import '../../clinician/data/local_care_plan_repository.dart';
import '../../clinician/domain/clinician_models.dart';
import '../../clinician/domain/post_visit_focus_model.dart';
import '../../investigation/data/local_case_repository.dart';
import '../../investigation/domain/case_model.dart';
import '../../mind_trace/data/local_mind_trace_repository.dart';
import '../../mind_trace/domain/mind_trace_model.dart';
import '../../observatory/data/local_symptom_repository.dart';
import '../../observatory/domain/symptom_report.dart';
import '../../profile/data/local_profile_repository.dart';
import '../../profile/domain/psychological_profile_model.dart';
import '../data/clinic_auth_repository.dart';
import '../data/local_clinic_simulator_repository.dart';
import '../domain/clinic_account_models.dart';

/// Concrete simulator instance shared across Auth & Sync abstractions.
final localClinicSimulatorProvider =
    Provider<LocalClinicSimulatorRepository>((ref) {
  final keyManager = ref.watch(secureKeyManagerProvider);
  return LocalClinicSimulatorRepository(keyManager: keyManager);
});

final clinicAuthRepositoryProvider = Provider<ClinicAuthRepository>((ref) {
  return ref.watch(localClinicSimulatorProvider);
});

final clinicSyncRepositoryProvider = Provider<ClinicSyncRepository>((ref) {
  return ref.watch(localClinicSimulatorProvider);
});

class ClinicSyncStatusNotifier extends Notifier<ClinicSyncStatus> {
  @override
  ClinicSyncStatus build() => const ClinicSyncStatus();

  void setSavedOffline() {
    state = state.copyWith(phase: ClinicSyncPhase.savedOffline, clearError: true);
  }

  void setSyncing() {
    state = state.copyWith(phase: ClinicSyncPhase.syncing, clearError: true);
  }

  void setSynced(DateTime timestamp) {
    state = ClinicSyncStatus(
      phase: ClinicSyncPhase.synced,
      lastSyncedAt: timestamp,
    );
  }

  void setError(String message) {
    state = state.copyWith(
      phase: ClinicSyncPhase.pausedOrError,
      errorMessage: message,
    );
  }
}

final clinicSyncStatusProvider =
    NotifierProvider<ClinicSyncStatusNotifier, ClinicSyncStatus>(
  ClinicSyncStatusNotifier.new,
);

final clinicAutoSyncCoordinatorProvider =
    Provider<ClinicAutoSyncCoordinator>((ref) {
  return ClinicAutoSyncCoordinator(ref);
});

/// Coordinates silent offline-first synchronization between the Patient session
/// and the Doctor Admin workspace, and seeds patient device preferences on login.
class ClinicAutoSyncCoordinator {
  ClinicAutoSyncCoordinator(this._ref);

  final Ref _ref;

  /// Seeds local encrypted profile, language, and accessibility defaults
  /// from the Doctor-created [ClinicPatientAccount].
  Future<void> applyProvisionedPreferences(ClinicPatientAccount account) async {
    final keyManager = _ref.read(secureKeyManagerProvider);
    final profileRepo = LocalProfileRepository(keyManager: keyManager);
    final existing = await profileRepo.getProfile(userId: account.patientId);
    final inbox = await _ref
        .read(clinicSyncRepositoryProvider)
        .pullPatientInbox(account.patientId);

    final trackIds = (inbox != null && inbox.assignedTrackIds.isNotEmpty)
        ? inbox.assignedTrackIds
        : account.assignedTrackIds;

    final updatedProfile = existing.copyWith(
      userId: account.patientId,
      preferredName: existing.preferredName.isNotEmpty
          ? existing.preferredName
          : account.displayName,
      ageRange: account.ageRange,
      preferredLanguage: account.preferredLanguage,
      userRole: 'patient',
      careContext: 'regular_doctor',
      selectedTrackIds: trackIds,
      updatedAt: DateTime.now(),
    );
    await profileRepo.saveProfile(updatedProfile, userId: account.patientId);

    if (inbox?.activeFocusPlan != null) {
      final careRepo = LocalCarePlanRepository(
        userId: account.patientId,
        keyManager: keyManager,
      );
      await careRepo.savePlan(inbox!.activeFocusPlan!);
    }

    // Apply language & 65+ visual comfort defaults smoothly
    final lang = switch (account.preferredLanguage.toLowerCase()) {
      'fr' => AppLanguage.french,
      'ar' => AppLanguage.arabic,
      _ => AppLanguage.english,
    };
    await _ref.read(localeControllerProvider.notifier).setLanguage(lang);

    if (account.ageRange == '65+') {
      await _ref.read(displayComfortProvider.notifier).setComfortMode(true);
      await _ref
          .read(themeControllerProvider.notifier)
          .setTheme(ThemeMode.light);
    }
  }

  /// Syncs non-private patient data automatically to the assigned doctor.
  Future<ClinicianSyncPacket?> syncActivePatient({
    AuthUser? userOverride,
    List<MindTraceModel>? tracesOverride,
    List<CaseModel>? casesOverride,
    List<SymptomReport>? symptomReportsOverride,
    PsychologicalProfileModel? profileOverride,
  }) async {
    final user = userOverride ?? _ref.read(authControllerProvider).user;
    if (user == null || !user.isClinicAccount) {
      return null;
    }

    final statusNotifier = _ref.read(clinicSyncStatusProvider.notifier);
    statusNotifier.setSyncing();

    try {
      final keyManager = _ref.read(secureKeyManagerProvider);
      final traces = tracesOverride ??
          await LocalMindTraceRepository(
            userId: user.id,
            keyManager: keyManager,
          ).getAllTraces();
      final cases = casesOverride ??
          await LocalCaseRepository(
            userId: user.id,
            keyManager: keyManager,
          ).getAllCases();
      final symptoms = symptomReportsOverride ??
          await LocalSymptomRepository(
            userId: user.id,
            keyManager: keyManager,
          ).getAllReports();
      final profile = profileOverride ??
          await LocalProfileRepository(
            keyManager: keyManager,
          ).getProfile(userId: user.id);

      final packet = await _ref
          .read(clinicSyncRepositoryProvider)
          .syncPatientSnapshot(
            patientId: user.id,
            traces: traces,
            cases: cases,
            symptomReports: symptoms,
            profile: profile,
          );

      // Pull doctor updates (updated tracks or new focus plan)
      await pullInboxUpdates(userOverride: user);

      if (!_ref.mounted) return packet;
      statusNotifier.setSynced(packet?.generatedAt ?? DateTime.now());
      return packet;
    } on ClinicAuthException catch (e) {
      if (_ref.mounted) {
        statusNotifier.setError(e.message);
      }
      return null;
    } catch (_) {
      if (_ref.mounted) {
        statusNotifier.setSavedOffline();
      }
      return null;
    }
  }

  /// Pulls any updated Care Tracks or Between-Visit Focus Plans pushed by Doctor.
  Future<void> pullInboxUpdates({AuthUser? userOverride}) async {
    final user = userOverride ?? _ref.read(authControllerProvider).user;
    if (user == null || !user.isClinicAccount) return;

    final inbox = await _ref
        .read(clinicSyncRepositoryProvider)
        .pullPatientInbox(user.id);
    if (inbox == null) return;

    final keyManager = _ref.read(secureKeyManagerProvider);
    final profileRepo = LocalProfileRepository(keyManager: keyManager);
    final profile = await profileRepo.getProfile(userId: user.id);
    if (profile.selectedTrackIds.join(',') !=
        inbox.assignedTrackIds.join(',')) {
      await profileRepo.saveProfile(
        profile.copyWith(
          selectedTrackIds: inbox.assignedTrackIds,
          updatedAt: DateTime.now(),
        ),
        userId: user.id,
      );
    }

    if (inbox.activeFocusPlan != null) {
      final careRepo = LocalCarePlanRepository(
        userId: user.id,
        keyManager: keyManager,
      );
      final currentPlan = await careRepo.loadActivePlan();
      final incoming = inbox.activeFocusPlan!;
      final isNewPlan = currentPlan == null ||
          incoming.planId != currentPlan.planId ||
          incoming.createdAt.isAfter(currentPlan.createdAt);
      if (isNewPlan) {
        await careRepo.savePlan(incoming);
      }
    }
  }

  /// Convenience helper for Doctor Admin to push a focus plan directly into sync.
  Future<void> pushDoctorFocusPlan({
    required String doctorId,
    required String patientId,
    required PostVisitFocusPlan plan,
  }) async {
    await _ref.read(clinicSyncRepositoryProvider).pushFocusPlanToPatient(
          doctorId: doctorId,
          patientId: patientId,
          plan: plan,
        );
  }
}
