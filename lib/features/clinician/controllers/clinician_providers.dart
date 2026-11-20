import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/security/secure_key_manager.dart';
import '../data/clinician_sync_service.dart';
import '../data/demo_clinical_cohort.dart';
import '../data/local_clinician_repository.dart';
import '../domain/clinician_models.dart';

final clinicianRepositoryProvider = Provider<LocalClinicianRepository>((ref) {
  final keyManager = ref.watch(secureKeyManagerProvider);
  return LocalClinicianRepository(keyManager: keyManager);
});

final clinicianSyncServiceProvider = Provider<ClinicianSyncService>((ref) {
  return const ClinicianSyncService();
});

class WorkspaceRoleNotifier extends Notifier<AppWorkspaceRole> {
  @override
  AppWorkspaceRole build() {
    _hydrateRole();
    return AppWorkspaceRole.patient;
  }

  Future<void> _hydrateRole() async {
    final saved = await ref.read(clinicianRepositoryProvider).loadWorkspaceRole();
    state = saved;
  }

  Future<void> setRole(AppWorkspaceRole role) async {
    state = role;
    await ref.read(clinicianRepositoryProvider).saveWorkspaceRole(role);
  }
}

final workspaceRoleProvider =
    NotifierProvider<WorkspaceRoleNotifier, AppWorkspaceRole>(
  WorkspaceRoleNotifier.new,
);

class ClinicianDemoEnabledNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    return ref.watch(clinicianRepositoryProvider).isDemoEnabled();
  }

  Future<void> setEnabled(bool enabled) async {
    state = AsyncValue.data(enabled);
    await ref.read(clinicianRepositoryProvider).setDemoEnabled(enabled);
  }
}

final clinicianDemoEnabledProvider =
    AsyncNotifierProvider<ClinicianDemoEnabledNotifier, bool>(
  ClinicianDemoEnabledNotifier.new,
);

class ClinicianProfileNotifier extends AsyncNotifier<ClinicianProfile> {
  @override
  Future<ClinicianProfile> build() async {
    return ref.watch(clinicianRepositoryProvider).loadClinicianProfile();
  }

  Future<void> updateProfile(ClinicianProfile profile) async {
    state = AsyncValue.data(profile);
    await ref.read(clinicianRepositoryProvider).saveClinicianProfile(profile);
  }
}

final clinicianProfileProvider =
    AsyncNotifierProvider<ClinicianProfileNotifier, ClinicianProfile>(
  ClinicianProfileNotifier.new,
);

class ClinicianRosterNotifier
    extends AsyncNotifier<List<ClinicianPatientRecord>> {
  @override
  Future<List<ClinicianPatientRecord>> build() async {
    final repo = ref.watch(clinicianRepositoryProvider);
    final demoEnabled = await ref.watch(clinicianDemoEnabledProvider.future);

    final imported = await repo.loadImportedPatients();
    final List<ClinicianPatientRecord> combined = [...imported];

    if (demoEnabled) {
      final demoNotesMap = await repo.loadDemoNotes();
      final demoReviewedMap = await repo.loadDemoReviewedMap();
      final demoRecords = DemoClinicalCohort.buildRecords();
      for (final demo in demoRecords) {
        final mergedNotes = demoNotesMap.containsKey(demo.patientId)
            ? demoNotesMap[demo.patientId]!
            : demo.clinicianNotes;
        final mergedReviewed = demoReviewedMap[demo.patientId] ?? demo.reviewedAt;
        combined.add(
          demo.copyWith(
            clinicianNotes: mergedNotes,
            reviewedAt: mergedReviewed,
          ),
        );
      }
    }

    combined.sort((a, b) => b.lastSyncedAt.compareTo(a.lastSyncedAt));
    return combined;
  }

  /// Imports a verified, consent-scoped [ClinicianSyncPacket] and preserves any
  /// existing private clinician notes for returning patients.
  Future<ClinicianPatientRecord> importPacket(ClinicianSyncPacket packet) async {
    final repo = ref.read(clinicianRepositoryProvider);
    final existingImported = await repo.loadImportedPatients();
    final existingIdx = existingImported.indexWhere(
      (r) => r.patientId == packet.patientAnonymousId && !r.isDemoCase,
    );
    final existingNotes = existingIdx >= 0
        ? existingImported[existingIdx].clinicianNotes
        : const <ClinicianSessionNote>[];
    final importedAt = existingIdx >= 0
        ? existingImported[existingIdx].importedAt
        : packet.generatedAt;

    final sanitizedPacket = ClinicianSyncPacket.fromJson(packet.toJson());

    final record = ClinicianPatientRecord(
      patientId: sanitizedPacket.patientAnonymousId,
      displayName: sanitizedPacket.patientDisplayName,
      isDemoCase: false,
      importedAt: importedAt,
      lastSyncedAt: sanitizedPacket.generatedAt,
      latestPacket: sanitizedPacket,
      clinicianNotes: existingNotes,
      reviewedAt: null,
    );

    await repo.upsertPatient(record);
    ref.invalidateSelf();
    await future;
    return record;
  }

  Future<void> addNote(String patientId, ClinicianSessionNote note) async {
    final repo = ref.read(clinicianRepositoryProvider);
    final currentList = state.value ?? await future;
    final idx = currentList.indexWhere((r) => r.patientId == patientId);
    if (idx < 0) return;

    final target = currentList[idx];
    final updated = target.copyWith(
      clinicianNotes: [note, ...target.clinicianNotes],
    );
    await repo.upsertPatient(updated);
    final nextList = [...currentList];
    nextList[idx] = updated;
    state = AsyncValue.data(nextList);
  }

  Future<void> deleteNote(String patientId, String noteId) async {
    final repo = ref.read(clinicianRepositoryProvider);
    final currentList = state.value ?? await future;
    final idx = currentList.indexWhere((r) => r.patientId == patientId);
    if (idx < 0) return;

    final target = currentList[idx];
    final updated = target.copyWith(
      clinicianNotes: target.clinicianNotes
          .where((n) => n.id != noteId)
          .toList(growable: false),
    );
    await repo.upsertPatient(updated);
    final nextList = [...currentList];
    nextList[idx] = updated;
    state = AsyncValue.data(nextList);
  }

  Future<void> markReviewed(String patientId) async {
    final repo = ref.read(clinicianRepositoryProvider);
    final currentList = state.value ?? await future;
    final idx = currentList.indexWhere((r) => r.patientId == patientId);
    if (idx < 0) return;

    final target = currentList[idx];
    if (!target.hasUnreviewedUpdate) return;

    final updated = target.copyWith(reviewedAt: DateTime.now());
    await repo.upsertPatient(updated);
    final nextList = [...currentList];
    nextList[idx] = updated;
    state = AsyncValue.data(nextList);
  }

  Future<void> removeImportedPatient(String patientId) async {
    final repo = ref.read(clinicianRepositoryProvider);
    await repo.deletePatient(patientId);
    final currentList = state.value ?? const [];
    state = AsyncValue.data(
      currentList
          .where((r) => r.patientId != patientId || r.isDemoCase)
          .toList(growable: false),
    );
  }

  Future<void> clearImportedPatients() async {
    final repo = ref.read(clinicianRepositoryProvider);
    await repo.clearImportedPatients();
    final currentList = state.value ?? const [];
    state = AsyncValue.data(
      currentList.where((r) => r.isDemoCase).toList(growable: false),
    );
  }
}

final clinicianRosterProvider =
    AsyncNotifierProvider<ClinicianRosterNotifier, List<ClinicianPatientRecord>>(
  ClinicianRosterNotifier.new,
);
