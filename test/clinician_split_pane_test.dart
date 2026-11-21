import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mind_forensics/app/localization/locale_controller.dart';
import 'package:mind_forensics/app/theme/lab_theme.dart';
import 'package:mind_forensics/core/security/secure_key_manager.dart';
import 'package:mind_forensics/core/widgets/mind_segmented.dart';
import 'package:mind_forensics/features/clinician/presentation/clinician_patient_detail_screen.dart';
import 'package:mind_forensics/features/clinician/presentation/clinician_shell_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    SecureKeyManager.resetStaticCache();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Milestone 4.2: Adaptive Tablet & Desktop Clinician Split-Pane Workspace', () {
    testWidgets(
      '1. Wide viewport (>= 840px) renders Navigation Rail, left triage roster, and live embedded dossier',
      (tester) async {
        tester.view.physicalSize = const Size(1100, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final container = ProviderContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: buildMindTheme(Brightness.dark),
              home: const ClinicianShellScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Embedded dossier renders live on the right alongside left triage list
        expect(find.byType(ClinicianPatientDetailScreen), findsOneWidget);
        expect(find.byType(MindSegmented), findsOneWidget);
        // Embedded dossier omits mobile back button
        expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);

        // Default selection is newest synced patient (Nadia B.)
        expect(
          find.textContaining('Why does my apprehension spike after 19:00'),
          findsOneWidget,
        );

        // Select Karim M. from left roster -> switches right dossier in-place
        await tester.scrollUntilVisible(
          find.text('Karim M.'),
          120,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text('Karim M.'));
        await tester.pumpAndSettle();

        expect(
          find.textContaining('Evenings feel noticeably steadier'),
          findsOneWidget,
        );

        // Switch to Notes view on the embedded dossier
        await tester.tap(find.text('Notes'));
        await tester.pumpAndSettle();
        expect(find.text('Send Between-Session Focus'), findsOneWidget);

        // Switch to Overview tab via navigation rail and jump back via observation card
        await tester.tap(find.text('Overview').first);
        await tester.pumpAndSettle();
        expect(find.text('COHORT BASELINE OBSERVATIONS'), findsOneWidget);

        await tester.tap(find.textContaining('Nadia B.').first);
        await tester.pumpAndSettle();
        expect(find.byType(ClinicianPatientDetailScreen), findsOneWidget);
        expect(
          find.textContaining('Why does my apprehension spike after 19:00'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '2. Narrow mobile viewport (< 840px) preserves floating bottom dock without embedded split pane',
      (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final container = ProviderContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: buildMindTheme(Brightness.dark),
              home: const ClinicianShellScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ClinicianPatientDetailScreen), findsNothing);
        expect(find.text('Patients'), findsOneWidget);
        expect(find.text('Overview'), findsOneWidget);
        expect(find.text('Practice'), findsOneWidget);
      },
    );

    testWidgets(
      '3. Wide split workspace passes accessibility guidelines and Arabic RTL 1.2x scaling without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(1024, 768);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final handle = tester.ensureSemantics();
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: buildMindTheme(Brightness.dark),
              home: const ClinicianShellScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        handle.dispose();

        // Arabic RTL + 1.2x scaled text on 1024px tablet
        await container
            .read(localeControllerProvider.notifier)
            .setLanguage(AppLanguage.arabic);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: buildMindTheme(Brightness.dark),
              locale: const Locale('ar'),
              home: MediaQuery(
                data: const MediaQueryData(
                  textScaler: TextScaler.linear(1.2),
                ),
                child: const Directionality(
                  textDirection: TextDirection.rtl,
                  child: ClinicianShellScreen(),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  });
}
