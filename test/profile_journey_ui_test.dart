import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_forensics/app/localization/app_strings.dart';
import 'package:mind_forensics/features/journey/data/default_journey_curriculum.dart';
import 'package:mind_forensics/features/journey/presentation/journey_activity_detail_screen.dart';
import 'package:mind_forensics/features/profile/presentation/psychological_profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Psychological Profile & Journey UI Tests', () {
    testWidgets('PsychologicalProfileScreen renders conditions, details, and toggle',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PsychologicalProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check header and sections
      const en = AppStrings('en');
      expect(find.text(en.myPsychologicalProfileTitle), findsOneWidget);
      expect(find.text(en.conditionsSectionTitle), findsOneWidget);
      expect(find.text(en.optionalDetailsTitle), findsOneWidget);

      // Verify condition chips are visible
      expect(find.text('Depression'), findsOneWidget);
      expect(find.text('ADHD'), findsOneWidget);
      expect(find.text('OCD (Obsessive-Compulsive Disorder)'), findsOneWidget);

      // Verify AI Companion toggle exists
      expect(find.text('Share profile with AI companion'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);

      // Verify Save button exists
      expect(find.text('SAVE PROFILE'), findsOneWidget);
    });

    testWidgets('JourneyActivityDetailScreen allows writing reflection and completing',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});
      final activity = DefaultJourneyCurriculum.getActivities().first;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: JourneyActivityDetailScreen(activity: activity),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check title and purpose
      expect(find.text(activity.title), findsOneWidget);
      expect(find.text('CLINICAL PURPOSE'), findsOneWidget);
      expect(find.text('GUIDED INSTRUCTIONS'), findsOneWidget);
      expect(find.text('REFLECTION QUESTIONS'), findsOneWidget);

      // Enter reflection
      final textFields = find.byType(TextField);
      expect(textFields, findsAtLeastNWidgets(2));

      await tester.enterText(textFields.first, 'Observable situation was a missed call');
      await tester.pumpAndSettle();

      // Tap Mark as completed
      await tester.tap(find.text('Mark as Completed'));
      await tester.pumpAndSettle();

      // Verify completion badge changes
      expect(find.text('Completed'), findsAtLeastNWidgets(1));
    });
  });
}
