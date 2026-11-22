import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_forensics/app/theme/lab_theme.dart';
import 'package:mind_forensics/core/widgets/bouncing_widget.dart';
import 'package:mind_forensics/core/widgets/mind_button.dart';
import 'package:mind_forensics/core/widgets/mind_segmented.dart';
import 'package:mind_forensics/features/investigation/presentation/widgets/vagal_breathing_visualizer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Interactive UX Widgets Tests', () {
    testWidgets('BouncingWidget renders child and responds to tap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BouncingWidget(
              onTap: () => tapped = true,
              child: const Text('Tap Me'),
            ),
          ),
        ),
      );

      expect(find.text('Tap Me'), findsOneWidget);

      await tester.tap(find.text('Tap Me'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('MindButton triggers callback and blocks taps while loading',
        (tester) async {
      var tapCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildMindTheme(Brightness.dark),
          home: Scaffold(
            body: Column(
              children: [
                MindButton(
                  text: 'Save Check-In',
                  onPressed: () => tapCount++,
                ),
                MindButton(
                  text: 'Busy Action',
                  isLoading: true,
                  onPressed: () => tapCount += 10,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('Save Check-In'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(tapCount, 1);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byType(CircularProgressIndicator));
      await tester.pump();
      expect(tapCount, 1);
    });

    testWidgets('MindSegmented switches active segment on tap', (tester) async {
      var current = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildMindTheme(Brightness.dark),
          home: StatefulBuilder(
            builder: (context, setState) => Scaffold(
              body: MindSegmented(
                index: current,
                labels: const ['Overview', 'Timeline', 'Cases'],
                onChanged: (idx) => setState(() => current = idx),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Timeline'));
      await tester.pumpAndSettle();
      expect(current, 1);

      await tester.tap(find.text('Cases'));
      await tester.pumpAndSettle();
      expect(current, 2);
    });

    testWidgets('VagalBreathingVisualizer displays seconds and phase', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VagalBreathingVisualizer(
              phase: 0,
              secondsLeft: 4,
              phaseText: 'Inhale',
              isDark: true,
            ),
          ),
        ),
      );

      expect(find.text('4'), findsOneWidget);
      expect(find.text('INHALE'), findsOneWidget);
    });
  });
}
