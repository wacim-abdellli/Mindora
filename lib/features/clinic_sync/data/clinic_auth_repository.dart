import '../../clinician/domain/clinician_models.dart';
import '../../clinician/domain/post_visit_focus_model.dart';
import '../../investigation/domain/case_model.dart';
import '../../mind_trace/domain/mind_trace_model.dart';
import '../../observatory/domain/symptom_report.dart';
import '../../profile/domain/psychological_profile_model.dart';
import '../domain/clinic_account_models.dart';

/// Backend-agnostic contract for Doctor-Admin patient provisioning and login.
///
/// Backed during dev/demos by [LocalClinicSimulatorRepository] and designed for
/// seamless swap to Firebase Auth + Cloud Functions before clinic production.
abstract class ClinicAuthRepository {
  Future<ClinicProvisionResult> createPatientAccount({
    required String doctorId,
    required String clinicId,
    required String doctorName,
    required String clinicName,
    required String displayName,
    required String loginIdentifier,
    required String ageRange,
    required String preferredLanguage,
    String? clinicianLanguage,
    List<String> assignedTrackIds = const [],
    List<String> conditionIds = const [],
    List<String> customConditions = const [],
    String? customTempPin,
    Duration inviteValidity = const Duration(hours: 24),
    DateTime? now,
  });

  Future<ClinicPatientAccount> signInWithCredentials({
    required String identifier,
    required String pinOrPassword,
    DateTime? now,
  });

  Future<ClinicPatientAccount> signInWithInviteQr({
    required String qrPayload,
    DateTime? now,
  });

  Future<ClinicProvisionResult> resetPatientAccess({
    required String doctorId,
    required String patientId,
    String? customTempPin,
    Duration inviteValidity = const Duration(hours: 24),
    DateTime? now,
  });

  Future<ClinicPatientAccount> setAccountStatus({
    required String doctorId,
    required String patientId,
    required ClinicAccountStatus status,
  });

  Future<ClinicPatientAccount> updateAssignedTracks({
    required String doctorId,
    required String patientId,
    required List<String> trackIds,
  });

  Future<ClinicPatientAccount> changePatientPin({
    required String patientId,
    required String currentPin,
    required String newPin,
    bool skipCurrentPinCheck = false,
  });

  Future<ClinicPatientAccount> markSafetyNoticeAccepted({
    required String patientId,
  });

  Future<ClinicPatientAccount?> getPatientAccount(String patientId);

  Future<List<ClinicPatientAccount>> listPatientsForDoctor(String doctorId);

  Future<List<ClinicAuditEntry>> listAuditLog({
    String? doctorId,
    String? patientId,
  });
}

/// Backend-agnostic contract for automatic, privacy-enforced sync between
/// Patient devices and their assigned Doctor workspace.
abstract class ClinicSyncRepository {
  Future<ClinicianSyncPacket?> syncPatientSnapshot({
    required String patientId,
    required List<MindTraceModel> traces,
    required List<CaseModel> cases,
    required List<SymptomReport> symptomReports,
    PsychologicalProfileModel? profile,
    DateTime? now,
  });

  Future<void> pushFocusPlanToPatient({
    required String doctorId,
    required String patientId,
    required PostVisitFocusPlan plan,
  });

  Future<ClinicPatientSyncInbox?> pullPatientInbox(String patientId);

  Future<List<ClinicianPatientRecord>> listSyncedPatientsForDoctor(
    String doctorId,
  );
}
