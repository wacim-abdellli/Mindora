import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mind_forensics/app/localization/app_strings.dart';
import 'package:mind_forensics/app/localization/locale_controller.dart';
import 'package:mind_forensics/app/theme/lab_theme.dart';
import 'package:mind_forensics/core/security/secure_key_manager.dart';
import 'package:mind_forensics/features/insights/domain/recovery_ledger_model.dart';
import 'package:mind_forensics/features/mind_trace/controllers/mind_trace_controller.dart';
import 'package:mind_forensics/features/mind_trace/domain/mind_trace_model.dart';
import 'package:mind_forensics/features/support/presentation/widgets/breathing_exercise_card.dart';
import 'package:mind_forensics/features/support/presentation/widgets/grounding_exercise_card.dart';
import 'package:mind_forensics/features/support/presentation/widgets/relief_micro_check_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    SecureKeyManager.resetStaticCache();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Milestone 8.3: Closed-Loop Relief Micro-Check -> RecoveryLedger', () {
    testWidgets(
      'Pausing Box Breathing surfaces ReliefMicroCheckCard and logging Calmer now feeds RecoveryLedger with negative shift',
      (tester) async {
        tester.view.physicalSize = const Size(824, 1830);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.reset);

        final earlier = DateTime.now().subtract(const Duration(minutes: 20));
        final container = ProviderContainer();
        addTearDown(container.dispose);

        await container.read(mindTraceRepositoryProvider).saveTrace(
              MindTraceModel(
                id: 'peak_morning',
                date: earlier,
                overallMood: 'anxious',
                moodIntensity: 8,
                anxietyLevel: 8,
                createdAt: earlier,
                updatedAt: earlier,
              ),
            );
        await container.read(mindTraceControllerProvider.future);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: buildMindTheme(Brightness.dark),
              home: Scaffold(
                body: SingleChildScrollView(
                  child: BreathingExerciseCard(onSwitchToGrounding: () {}),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Not shown before user tries breathing
        expect(
          find.byKey(const ValueKey('relief-micro-check-card')),
          findsNothing,
        );

        // Start then stop breathing
        final strings = const AppStrings('en');
        await tester.tap(find.text(strings.breatheQuickBtn));
        await tester.pump();
        await tester.tap(find.text(strings.stopBtn));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('relief-micro-check-card')),
          findsOneWidget,
        );

        await tester.tap(find.byKey(const ValueKey('relief-check-calmer')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('relief-logged-confirmation')),
          findsOneWidget,
        );

        final traces = await container.read(mindTraceControllerProvider.future);
        expect(traces.length, equals(2));

        final ledger = RecoveryLedger.fromTraces(traces);
        expect(ledger.hasEvidence, isTrue);
        final breathing = ledger.stabilizers.firstWhere(
          (s) => s.key == 'breathing',
        );
        expect(breathing.sameDayRecoveryDays, equals(1));
        expect(breathing.avgSameDayShift, equals(-2.0));
      },
    );

    testWidgets(
      'Completing 5-4-3-2-1 Grounding offers Not Yet without false logging and renders cleanly at 320px + 1.35x AR RTL',
      (tester) async {
        tester.view.physicalSize = const Size(824, 1830);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.reset);

        var switchedToBreathing = false;
        final container = ProviderContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: buildMindTheme(Brightness.light),
              home: Scaffold(
                body: SingleChildScrollView(
                  child: GroundingExerciseCard(
                    onSwitchToBreathing: () => switchedToBreathing = true,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        for (var i = 0; i < 5; i++) {
          await tester.tap(find.text('Noticed • Next Step'));
          await tester.pumpAndSettle();
        }

        expect(
          find.byKey(const ValueKey('relief-micro-check-card')),
          findsOneWidget,
        );

        // Tap "Not yet": must NOT save any false trace, and must offer alternative switch
        await tester.tap(find.byKey(const ValueKey('relief-check-not-yet')));
        await tester.pumpAndSettle();

        final traces = await container.read(mindTraceControllerProvider.future);
        expect(traces, isEmpty);

        await tester.tap(
          find.byKey(const ValueKey('relief-try-alternative-btn')),
        );
        await tester.pumpAndSettle();
        expect(switchedToBreathing, isTrue);

        // Verify canonicalization of Grounding key in RecoveryLedger
        expect(RecoveryLedger.canonicalizeAction('Grounding'), equals('grounding'));
        expect(RecoveryLedger.canonicalizeAction('التثبيت الحسي'), equals('grounding'));

        // Narrow 320px + 1.35x Arabic RTL stress test on ReliefMicroCheckCard
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await container
            .read(localeControllerProvider.notifier)
            .setLanguage(AppLanguage.arabic);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: buildMindTheme(Brightness.light, isArabic: true),
              home: Directionality(
                textDirection: TextDirection.rtl,
                child: MediaQuery(
                  data: const MediaQueryData(
                    size: Size(320, 640),
                    textScaler: TextScaler.linear(1.35),
                  ),
                  child: Scaffold(
                    body: Padding(
                      padding: const EdgeInsets.all(12),
                      child: ReliefMicroCheckCard(
                        exerciseActionKey: 'Grounding',
                        alternativeLabel: const AppStrings('ar').breathingTitle,
                        onTryAlternative: () {},
                      ),
                    ),
                  ),
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
