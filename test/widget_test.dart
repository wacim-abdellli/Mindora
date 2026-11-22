import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mind_forensics/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({'mf_onboarding_completed': true});
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

      // 2. Verify all 5 persistent bottom navigation tabs (Flo-style standard navigation)
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Track'), findsOneWidget);
      expect(find.text('AI Guide'), findsAtLeastNWidgets(1));
      expect(find.text('Insights'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Observatory'), findsNothing);

      // 3. Verify streamlined daily sanctuary components on Home
      expect(find.text('Exercises for you'), findsOneWidget);
      expect(find.text('Relieve stress'), findsOneWidget);

      // 4. Verify options-first Daily check-in elements on Home screen (no compulsory note)
      expect(find.text('Log Daily Check-in'), findsOneWidget);
    },
  );
}
