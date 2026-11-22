import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mind_forensics/app/localization/app_strings.dart';
import 'package:mind_forensics/app/theme/lab_theme.dart';
import 'package:mind_forensics/app/theme/mind_tokens.dart';
import 'package:mind_forensics/core/widgets/fingerprint_thread_signature.dart';
import 'package:mind_forensics/core/widgets/mind_button.dart';
import 'package:mind_forensics/core/widgets/mind_segmented.dart';
import 'package:mind_forensics/core/widgets/organic_mood_orb.dart';
import 'package:mind_forensics/features/clinician/presentation/clinician_patient_detail_screen.dart';
import 'package:mind_forensics/features/home/presentation/home_screen.dart';
import 'package:mind_forensics/features/investigation/presentation/widgets/vagal_breathing_visualizer.dart';
import 'package:mind_forensics/features/support/presentation/contextual_support_sheet.dart';
import 'package:mind_forensics/features/track/presentation/widgets/track_mood_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Phase 8 Accessibility & Reduced Motion Guidelines', () {
    testWidgets('TrackMoodPicker meets tap target and labeled button guidelines',
        (tester) async {
      final handle = tester.ensureSemantics();
      try {
        String selected = 'heavy';
        await tester.pumpWidget(
          MaterialApp(
            theme: buildMindTheme(Brightness.dark),
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 360,
                  child: TrackMoodPicker(
                    selectedMoodKey: selected,
                    strings: const AppStrings('en'),
                    onSelect: (key) => selected = key,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

        await tester.tap(find.text('Calm'));
        await tester.pumpAndSettle();
        expect(selected, 'calm');
      } finally {
        handle.dispose();
      }
    });

    testWidgets('MindButton and MindSegmented meet tap target and labeled button guidelines',
        (tester) async {
      final handle = tester.ensureSemantics();
      try {
        var pressed = false;
        var segment = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: buildMindTheme(Brightness.dark),
            home: StatefulBuilder(
              builder: (context, setState) => Scaffold(
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MindSegmented(
                          index: segment,
                          labels: const ['Overview', 'Timeline'],
                          onChanged: (idx) => setState(() => segment = idx),
                        ),
                        const SizedBox(height: 16),
                        MindButton(
                          text: 'Save Check-In',
                          onPressed: () => pressed = true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

        await tester.tap(find.text('Timeline'));
        await tester.pumpAndSettle();
        expect(segment, 1);

        await tester.tap(find.text('Save Check-In'));
        await tester.pumpAndSettle();
        expect(pressed, isTrue);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('ClinicianPatientDetailScreen meets labeled and tap target guidelines',
        (tester) async {
      tester.view.physicalSize = const Size(900, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: buildMindTheme(Brightness.dark),
              home: const ClinicianPatientDetailScreen(patientId: 'demo_nadia_b'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      } finally {
        handle.dispose();
      }
    });

    testWidgets('Reduced motion disables infinite loops and settles cleanly',
        (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: MaterialApp(
              theme: buildMindTheme(Brightness.dark),
              home: const Scaffold(
                body: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FingerprintThreadSignature(
                      size: 72,
                      animated: true,
                      primaryColor: MindTokens.moodRestless,
                      accentColor: MindTokens.moodCalm,
                    ),
                    OrganicMoodOrb(
                      moodKey: 'calm',
                      intensity: 6,
                      color: MindTokens.moodCalm,
                      size: 80,
                      animateChanges: true,
                    ),
                    VagalBreathingVisualizer(
                      phase: 0,
                      secondsLeft: 4,
                      phaseText: 'Inhale',
                      isDark: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        // Should settle immediately without timing out under disableAnimations: true.
        await tester.pumpAndSettle();
        expect(find.byType(VagalBreathingVisualizer), findsOneWidget);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('ContextualSupportSheet meets Android/iOS/labeled guidelines',
        (tester) async {
      tester.view.physicalSize = const Size(900, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: ContextualSupportSheet(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      } finally {
        handle.dispose();
      }
    });

    testWidgets('HomeScreen meets labeled and tap target guidelines',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      } finally {
        handle.dispose();
      }
    });
  });
}
