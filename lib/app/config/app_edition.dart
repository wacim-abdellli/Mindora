/// Defines whether the binary / active launch boots into the Patient mobile
/// companion or the Doctor / Clinic Admin roster workspace.
///
/// Build the dedicated Doctor / Admin edition with:
/// `flutter run -t lib/main_clinician.dart`
/// or:
/// `--dart-define=MINDORA_EDITION=clinician`
enum MindoraEdition {
  patient,
  clinician;

  static MindoraEdition fromString(String raw) {
    return raw.trim().toLowerCase() == 'clinician'
        ? MindoraEdition.clinician
        : MindoraEdition.patient;
  }
}

class AppEditionConfig {
  AppEditionConfig._();

  static const String _envEdition = String.fromEnvironment(
    'MINDORA_EDITION',
    defaultValue: 'patient',
  );

  static MindoraEdition? _entryOverride;
  static MindoraEdition? _testOverride;

  /// Active product edition resolved from test override -> entrypoint override -> `--dart-define`.
  static MindoraEdition get current =>
      _testOverride ??
      _entryOverride ??
      MindoraEdition.fromString(_envEdition);

  static bool get isClinicianApp => current == MindoraEdition.clinician;
  static bool get isPatientApp => current == MindoraEdition.patient;

  /// Called by `lib/main_clinician.dart` before bootstrapping the app.
  static void setMainEdition(MindoraEdition edition) {
    _entryOverride = edition;
  }

  /// Test helper to exercise Patient vs Doctor edition routing safely.
  static void configureForTesting(MindoraEdition? edition) {
    _testOverride = edition;
  }
}
