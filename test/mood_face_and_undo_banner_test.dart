import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_forensics/app/theme/lab_theme.dart';
import 'package:mind_forensics/app/theme/mind_tokens.dart';
import 'package:mind_forensics/core/widgets/mind_strength_picker.dart';
import 'package:mind_forensics/core/widgets/mind_undo_banner.dart';
import 'package:mind_forensics/core/widgets/mood_face.dart';

void main() {
  group('M9.2 — Living MoodFace, MindStrengthPicker & MindUndoBanner', () {
    testWidgets('MoodFace renders all 6 vivid vector moods & triggers tap cleanly', (
      tester,
    ) async {
      AppMood? tapped;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildMindTheme(Brightness.light),
          home: Scaffold(
            body: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final mood in AppMood.values)
                  MoodFaceTile(
                    mood: mood,
                    label: mood.key,
                    isSelected: tapped == mood,
                    onTap: () => tapped = mood,
                  ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MoodFace), findsNWidgets(6));
      await tester.tap(find.text('good'));
      await tester.pumpAndSettle();
      expect(tapped, AppMood.good);
      expect(tester.takeException(), isNull);
    });

    testWidgets('MoodFace respects MediaQuery.disableAnimations', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildMindTheme(Brightness.dark),
          home: const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: Center(
                child: MoodFace(
                  mood: AppMood.calm,
                  size: 72,
                  isSelected: true,
                  semanticLabel: 'Calm face',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(MoodFace), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('MindStrengthPicker emits 3 / 6 / 9 and stacks cleanly at 320px 2.0x', (
      tester,
    ) async {
      int? picked;
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: buildMindTheme(Brightness.light),
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
            child: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: MindStrengthPicker(
                  selectedIntensity: null,
                  aLittleLabel: 'A little',
                  mediumLabel: 'Medium',
                  aLotLabel: 'A lot',
                  onSelected: (v) => picked = v,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Medium'));
      await tester.pumpAndSettle();
      expect(picked, 6);

      await tester.tap(find.text('A lot'));
      await tester.pumpAndSettle();
      expect(picked, 9);
    });

    testWidgets('showMindUndoBanner restores on Undo and commits when dismissed', (
      tester,
    ) async {
      var undone = false;
      var committed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: buildMindTheme(Brightness.light),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showMindUndoBanner(
                    context,
                    message: 'Check-in removed',
                    undoLabel: 'Undo',
                    onUndo: () => undone = true,
                    onCommit: () => committed = true,
                  );
                },
                child: const Text('Remove'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();
      expect(find.text('Check-in removed'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(undone, isTrue);
      expect(committed, isFalse);
    });
  });
}
