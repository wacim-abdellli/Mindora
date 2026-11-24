import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mind_forensics/app/localization/app_strings.dart';
import 'package:mind_forensics/app/localization/locale_controller.dart';
import 'package:mind_forensics/app/theme/lab_theme.dart';
import 'package:mind_forensics/core/security/secure_key_manager.dart';
import 'package:mind_forensics/features/clinician/controllers/clinician_providers.dart';
import 'package:mind_forensics/features/clinician/domain/post_visit_focus_model.dart';
import 'package:mind_forensics/features/investigation/presentation/flash_case_screen.dart';
import 'package:mind_forensics/features/investigation/presentation/widgets/companion_context_bridge_card.dart';
import 'package:mind_forensics/features/mind_trace/controllers/mind_trace_controller.dart';
import 'package:mind_forensics/features/mind_trace/domain/mind_trace_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    SecureKeyManager.resetStaticCache();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Milestone 8.1: Context-Aware Check-In & Care Focus Handoff', () {
    testWidgets(
      'FlashCaseScreen shows check-in + care focus bridge when logged today and sends 1-tap prompt cleanly',
      (tester) async {
        tester.view.physicalSize = const Size(824, 1830);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.reset);

        final now = DateTime.now();
        final focusPlan = PostVisitFocusPlan(
          planId: 'plan_8_1',
          clinicianName: 'Dr. Amira',
          createdAt: now,
          focusItems: const [
            FocusGoalItem(
              id: 'g1',
              title: 'Pause 5 minutes before checking late emails',
            ),
          ],
        );

        final container = ProviderContainer();
        addTearDown(container.dispose);

        await container.read(mindTraceRepositoryProvider).saveTrace(
              MindTraceModel(
                id: 'trace_8_1',
                userId: 'test_user',
                date: now,
                overallMood: 'anxious',
                moodIntensity: 8,
                contextTags: const ['high_workload', 'late_caffeine_screens'],
                journalText: 'Tight chest before tomorrow presentation',
                createdAt: now,
                updatedAt: now,
              ),
            );
        await container
            .read(postVisitFocusControllerProvider.notifier)
            .savePlan(focusPlan);
        await container.read(mindTraceControllerProvider.future);
        await container.read(postVisitFocusControllerProvider.future);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: buildMindTheme(Brightness.dark),
              home: const FlashCaseScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Bridge card is visible with mood intensity, settle-first shortcut (>=7), and care focus chip
        expect(
          find.byKey(const ValueKey('companion-checkin-bridge-card')),
          findsOneWidget,
        );
        expect(find.textContaining('Anxious · 8/10'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('companion-bridge-settle-btn')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('companion-bridge-focus-btn')),
          findsOneWidget,
        );

        // 1-tap "Unpack today's check-in" is immediately above the fold and transitions into active dialogue
        final unpackBtn = find.byKey(
          const ValueKey('companion-bridge-unpack-btn'),
        );
        await tester.ensureVisible(unpackBtn);
        await tester.tap(unpackBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('companion-checkin-bridge-card')),
          findsNothing,
        );
        expect(find.text('Save Takeaway Report'), findsOneWidget);
        expect(
          find.textContaining('Tight chest before tomorrow presentation'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'CompanionContextBridgeCard stays hidden when empty and renders cleanly at 320px + 1.35x AR RTL',
      (tester) async {
        const enStrings = AppStrings('en');
        await tester.pumpWidget(
          MaterialApp(
            theme: buildMindTheme(Brightness.dark),
            home: Scaffold(
              body: CompanionContextBridgeCard(
                todayTrace: null,
                focusPlan: null,
                strings: enStrings,
                onStartPrompt: (_) {},
                onOpenSettleSupport: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('companion-checkin-bridge-card')),
          findsNothing,
        );

        // Stress test 320px + 1.35x Arabic RTL
        tester.view.physicalSize = const Size(320, 720);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final container = ProviderContainer();
        addTearDown(container.dispose);
        await container
            .read(localeControllerProvider.notifier)
            .setLanguage(AppLanguage.arabic);

        final now = DateTime.now();
        final arStrings = const AppStrings('ar');
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: buildMindTheme(Brightness.light, isArabic: true),
              home: Directionality(
                textDirection: TextDirection.rtl,
                child: MediaQuery(
                  data: const MediaQueryData(
                    size: Size(320, 720),
                    textScaler: TextScaler.linear(1.35),
                  ),
                  child: Scaffold(
                    body: SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: CompanionContextBridgeCard(
                        todayTrace: MindTraceModel(
                          id: 'ar_trace',
                          date: now,
                          overallMood: 'heavy',
                          moodIntensity: 8,
                          contextTags: const ['high_workload'],
                          journalText: 'تعب وضغط كبير في الخدمة اليوم',
                          createdAt: now,
                          updatedAt: now,
                        ),
                        focusPlan: PostVisitFocusPlan(
                          planId: 'p_ar',
                          clinicianName: 'د. أميرة',
                          createdAt: now,
                          focusItems: const [
                            FocusGoalItem(
                              id: 'g_ar',
                              title: 'أخذ استراحة قصيرة قبل المساء',
                            ),
                          ],
                        ),
                        strings: arStrings,
                        onStartPrompt: (_) {},
                        onOpenSettleSupport: () {},
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('companion-checkin-bridge-card')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  });
}
