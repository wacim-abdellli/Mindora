import 'app/config/app_edition.dart';
import 'main.dart' as app_entry;

/// Dedicated Doctor / Clinic Admin entrypoint for psychiatrists and clinics.
///
/// Launches directly into the Clinician Workspace (full patients roster,
/// clinic pairing code, and clinical follow-up dossiers) without patient
/// onboarding steps.
Future<void> main() async {
  AppEditionConfig.setMainEdition(MindoraEdition.clinician);
  await app_entry.bootstrapMindoraApp(edition: MindoraEdition.clinician);
}
