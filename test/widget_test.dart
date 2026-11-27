import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mind_forensics/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({
      'mf_onboarding_completed': true,
      'mf_auth_current_user':
          '{"id":"test_patient","codename":"Test Patient","authType":"clinicPin","clinicId":"cln_test","doctorId":"doc_test","createdAt":"2026-01-01T00:00:00.000"}',
    });
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets(
    'Mindora App smoke test with 5 bottom tabs and options-first Daily Check-in',
    (WidgetTester tester) async {
      // Build our app wrapped in ProviderScope
      await tester.pumpWidget(const ProviderScope(child: MindForensicsApp()));
      await tester.pumpAndSettle();

      // 1. Verify that the header renders
      expect(find.text('Mindora'), findsOneWidget);

      // 2. Verify all 5 persistent single-job bottom navigation tabs
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('My days'), findsOneWidget);
      expect(find.text('Talk'), findsOneWidget);
      expect(find.text('Patterns'), findsOneWidget);
      expect(find.text('Me'), findsOneWidget);
      expect(find.text('Observatory'), findsNothing);

      // 3. Verify single-job Today screen components (2-tap check-in + 1 breather card)
      expect(find.text('How are you right now?'), findsOneWidget);
      expect(find.text('Take a 1-minute breather'), findsOneWidget);
    },
  );
}
