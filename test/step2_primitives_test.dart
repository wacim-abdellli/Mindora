import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mind_forensics/app/theme/lab_theme.dart';
import 'package:mind_forensics/app/theme/mind_tokens.dart';
import 'package:mind_forensics/core/widgets/ambient_scaffold.dart';
import 'package:mind_forensics/core/widgets/icon_blob.dart';
import 'package:mind_forensics/core/widgets/mind_button.dart';
import 'package:mind_forensics/core/widgets/mind_card.dart';
import 'package:mind_forensics/core/widgets/mind_chip.dart';
import 'package:mind_forensics/core/widgets/mind_segmented.dart';
import 'package:mind_forensics/core/widgets/mind_sheet.dart';
import 'package:mind_forensics/core/widgets/mind_switch.dart';
import 'package:mind_forensics/core/widgets/mind_toast.dart';
import 'package:mind_forensics/core/widgets/organic_mood_orb.dart';
import 'package:mind_forensics/core/widgets/smooth_spline_chart.dart';

Widget _wrapTheme(Brightness brightness, Widget child, {bool rtl = false}) {
  return Directionality(
    textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
    child: ProviderScope(
      child: MaterialApp(
        theme: buildMindTheme(brightness, isArabic: rtl),
        home: Scaffold(body: Center(child: child)),
      ),
    ),
  );
}

void main() {
  group('Step 2 — Token-Driven Primitives (Light Dawn & Dark Vercel)', () {
    testWidgets('MindCard variants respect Dawn shadows vs Vercel flat borders', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapTheme(
          Brightness.light,
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MindCard(child: Text('Plain')),
              MindCard(variant: MindCardVariant.tint, child: Text('Tint')),
              MindCard(variant: MindCardVariant.flat, child: Text('Flat')),
            ],
          ),
        ),
      );

      final lightContainers = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(MindCard),
              matching: find.byType(Container),
            ),
          )
          .toList();

      final plainDec = lightContainers[0].decoration! as BoxDecoration;
      final tintDec = lightContainers[1].decoration! as BoxDecoration;
      final flatDec = lightContainers[2].decoration! as BoxDecoration;

      expect(plainDec.color, MindTokens.light.surface);
      expect(plainDec.boxShadow, isNotEmpty);
      expect(tintDec.color, MindTokens.light.cardTint);
      expect(flatDec.color, MindTokens.light.surface2);
      expect(flatDec.boxShadow, isEmpty);

      await tester.pumpWidget(Container());
      await tester.pumpWidget(
        _wrapTheme(
          Brightness.dark,
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MindCard(child: Text('PlainDark')),
              MindCard(variant: MindCardVariant.tint, child: Text('TintDark')),
            ],
          ),
        ),
      );

      final darkContainers = tester
          .widgetList<Container>(
            find.descendant(
              of: find.widgetWithText(MindCard, 'PlainDark'),
              matching: find.byType(Container),
            ),
          )
          .toList();
      final darkTintContainers = tester
          .widgetList<Container>(
            find.descendant(
              of: find.widgetWithText(MindCard, 'TintDark'),
              matching: find.byType(Container),
            ),
          )
          .toList();
      final darkPlain = darkContainers.first.decoration! as BoxDecoration;
      final darkTint = darkTintContainers.first.decoration! as BoxDecoration;

      expect(darkPlain.color, MindTokens.dark.surface);
      expect(darkPlain.boxShadow, isEmpty);
      expect(darkTint.color, MindTokens.dark.cardTint);
    });

    testWidgets('MindButton variants enforce >=48dp and Vercel vs Dawn tokens', (
      tester,
    ) async {
      for (final variant in MindButtonVariant.values) {
        var taps = 0;
        await tester.pumpWidget(
          _wrapTheme(
            Brightness.dark,
            MindButton(
              text: variant.name,
              variant: variant,
              onPressed: () => taps++,
            ),
          ),
        );

        final size = tester.getSize(find.byType(MindButton));
        expect(size.height, greaterThanOrEqualTo(48));
        expect(size.width, greaterThanOrEqualTo(48));

        await tester.tap(find.byType(MindButton));
        await tester.pump();
        expect(taps, 1);
      }
    });

    testWidgets('MindChip, MindSwitch, MindSegmented & IconBlob pass tap & RTL checks', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      try {
        bool chipSelected = false;
        bool switchOn = false;
        int segment = 0;

        await tester.pumpWidget(
          _wrapTheme(
            Brightness.dark,
            StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MindChip(
                      label: 'Grounding',
                      selected: chipSelected,
                      onTap: () => setState(() => chipSelected = !chipSelected),
                    ),
                    const SizedBox(height: 12),
                    MindSwitch(
                      value: switchOn,
                      semanticLabel: 'Gentle reminders',
                      onChanged: (v) => setState(() => switchOn = v),
                    ),
                    const SizedBox(height: 12),
                    MindSegmented(
                      index: segment,
                      labels: const ['One', 'Two'],
                      onChanged: (i) => setState(() => segment = i),
                    ),
                    const SizedBox(height: 12),
                    const IconBlob(icon: Icons.eco_outlined),
                  ],
                );
              },
            ),
            rtl: true,
          ),
        );

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));

        await tester.tap(find.byType(MindChip));
        await tester.pump();
        expect(chipSelected, isTrue);
        expect(find.byIcon(Icons.check_rounded), findsOneWidget);

        await tester.tap(find.byType(MindSwitch));
        await tester.pump();
        expect(switchOn, isTrue);

        await tester.tap(find.text('Two'));
        await tester.pump();
        expect(segment, 1);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('AmbientScaffold renders top mood glow in both Sunrise Light and Twilight Dark', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildMindTheme(Brightness.light),
          home: const AmbientScaffold(body: Text('SunriseBody')),
        ),
      );
      expect(
        find.descendant(
          of: find.byType(AmbientScaffold),
          matching: find.byType(TweenAnimationBuilder<Color?>),
        ),
        findsOneWidget,
      );

      await tester.pumpWidget(Container());
      await tester.pumpWidget(
        MaterialApp(
          theme: buildMindTheme(Brightness.dark),
          home: const AmbientScaffold(body: Text('TwilightBody')),
        ),
      );
      expect(
        find.descendant(
          of: find.byType(AmbientScaffold),
          matching: find.byType(TweenAnimationBuilder<Color?>),
        ),
        findsOneWidget,
      );
    });

    testWidgets('showMindSheet, showMindToast, SmoothSplineChart & OrganicMoodOrb drag', (
      tester,
    ) async {
      int intensity = 5;
      int? selectedIdx;

      await tester.pumpWidget(
        _wrapTheme(
          Brightness.dark,
          Builder(
            builder: (context) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OrganicMoodOrb(
                    moodKey: 'calm',
                    intensity: intensity,
                    color: MindTokens.moodCalm,
                    size: 96,
                    onIntensityChanged: (next) => intensity = next,
                  ),
                  SmoothSplineChart(
                    values: const [0.2, 0.6, 0.8],
                    pointColors: const [
                      MindTokens.moodCalm,
                      MindTokens.moodAnxious,
                      MindTokens.moodFrustrated,
                    ],
                    activePointIndex: selectedIdx,
                    activePointLabel: 'Sample',
                    onPointSelected: (i) => selectedIdx = i,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      showMindToast(context, 'Saved safely');
                      showMindSheet<void>(
                        context: context,
                        builder: (_) => const Text('SheetBody'),
                      );
                    },
                    child: const Text('Trigger'),
                  ),
                ],
              );
            },
          ),
        ),
      );

      // Drag orb upward 32px -> intensity increments by 1-2
      await tester.drag(find.byType(OrganicMoodOrb), const Offset(0, -32));
      await tester.pump();
      expect(intensity, greaterThan(5));

      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();
      expect(find.byType(MindSheet), findsOneWidget);
      expect(find.text('SheetBody'), findsOneWidget);
      expect(find.text('Saved safely'), findsOneWidget);

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
    });
  });
}
