import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_forensics/app/config/app_edition.dart';
import 'package:mind_forensics/app/theme/lab_theme.dart';
import 'package:mind_forensics/app/theme/mind_tokens.dart';
import 'package:mind_forensics/app/theme/theme_controller.dart';
import 'package:mind_forensics/core/widgets/mind_badge.dart';
import 'package:mind_forensics/core/widgets/mind_banner.dart';
import 'package:mind_forensics/core/widgets/mind_button.dart';
import 'package:mind_forensics/core/widgets/mind_dialog.dart';
import 'package:mind_forensics/core/widgets/mind_empty_state.dart';
import 'package:mind_forensics/core/widgets/mind_page_container.dart';
import 'package:mind_forensics/core/widgets/mind_pressable.dart';
import 'package:mind_forensics/core/widgets/mind_sheet.dart';
import 'package:mind_forensics/core/widgets/mind_skeleton.dart';
import 'package:mind_forensics/core/widgets/mind_switch.dart';
import 'package:mind_forensics/core/widgets/mind_toast.dart';
import 'package:mind_forensics/core/widgets/mind_undo_banner.dart';
import 'package:mind_forensics/features/investigation/domain/label_type.dart';
import 'package:mind_forensics/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

double _contrastRatio(Color a, Color b) {
  final lumA = a.computeLuminance();
  final lumB = b.computeLuminance();
  final lighter = lumA > lumB ? lumA : lumB;
  final darker = lumA > lumB ? lumB : lumA;
  return (lighter + 0.05) / (darker + 0.05);
}

Widget _wrapApp(
  Widget child, {
  Brightness brightness = Brightness.light,
  bool isArabic = false,
  bool disableAnimations = false,
}) {
  return MaterialApp(
    theme: buildMindTheme(brightness, isArabic: isArabic),
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  group('Phase 1: MindTokens WCAG 2.1 Contrast & Palette Integrity', () {
    test('All semantic, accent, safety, switch, disabled & label tokens pass WCAG AA (>= 4.5:1)', () {
      for (final tokens in [MindTokens.light, MindTokens.dark]) {
        // Zero pure pitch-black #000000 UI surfaces
        expect(tokens.bg, isNot(const Color(0xFF000000)));
        expect(tokens.surface, isNot(const Color(0xFF000000)));
        expect(tokens.surface2, isNot(const Color(0xFF000000)));

        // Accent ink on every neutral surface
        for (final surface in [tokens.bg, tokens.surface, tokens.surface2]) {
          expect(
            _contrastRatio(tokens.accentInk, surface),
            greaterThanOrEqualTo(4.5),
          );
        }

        // Safety & clinical status tokens
        expect(_contrastRatio(tokens.onSafety, tokens.safety), greaterThanOrEqualTo(4.5));
        expect(_contrastRatio(tokens.safety, tokens.safetySoft), greaterThanOrEqualTo(4.5));

        expect(_contrastRatio(tokens.success, tokens.surface), greaterThanOrEqualTo(4.5));
        expect(_contrastRatio(tokens.success, tokens.successSoft), greaterThanOrEqualTo(4.5));
        expect(_contrastRatio(tokens.onSuccess, tokens.success), greaterThanOrEqualTo(4.5));

        expect(_contrastRatio(tokens.warning, tokens.surface), greaterThanOrEqualTo(4.5));
        expect(_contrastRatio(tokens.warning, tokens.warningSoft), greaterThanOrEqualTo(4.5));
        expect(_contrastRatio(tokens.onWarning, tokens.warning), greaterThanOrEqualTo(4.5));

        expect(_contrastRatio(tokens.info, tokens.surface), greaterThanOrEqualTo(4.5));
        expect(_contrastRatio(tokens.info, tokens.infoSoft), greaterThanOrEqualTo(4.5));
        expect(_contrastRatio(tokens.onInfo, tokens.info), greaterThanOrEqualTo(4.5));

        // Switch thumb vs ON track (exceeds WCAG 1.4.11 3.0:1 and 1.4.3 4.5:1)
        expect(
          _contrastRatio(tokens.switchThumbOn, tokens.switchOnTrack),
          greaterThanOrEqualTo(4.5),
        );

        // Disabled button text vs disabled background
        expect(
          _contrastRatio(tokens.disabledInk, tokens.disabledBg),
          greaterThanOrEqualTo(4.5),
        );

        // Label badge icon foreground vs tinted badge background
        for (final label in LabelType.values) {
          expect(
            _contrastRatio(
              tokens.labelForeground(label),
              tokens.labelBackground(label),
            ),
            greaterThanOrEqualTo(4.5),
          );
        }
      }
    });

    test('LabTheme enforces Arabic letterSpacing: 0.0 and Noto Sans Arabic fallback', () {
      final arStyle = LabTheme.textStyle(letterSpacing: -0.6, isArabic: true);
      expect(arStyle.letterSpacing, 0.0);
      expect(arStyle.fontFamilyFallback, contains('Noto Sans Arabic'));

      final arTheme = buildMindTheme(Brightness.light, isArabic: true);
      expect(arTheme.textTheme.headlineLarge?.letterSpacing, 0.0);
      expect(arTheme.colorScheme.onError, MindTokens.light.onSafety);
    });
  });

  group('Phase 1: Desktop Keyboard, Focus, Semantics & Contrast Primitives', () {
    testWidgets('MindPressable activates on Enter and Space when focused', (tester) async {
      var activations = 0;
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        _wrapApp(
          MindPressable(
            focusNode: focusNode,
            semanticLabel: 'Primary action',
            borderRadius: BorderRadius.circular(14),
            onPressed: () => activations++,
            child: const SizedBox(
              width: 140,
              height: 48,
              child: Center(child: Text('Activate me')),
            ),
          ),
        ),
      );

      focusNode.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(activations, 1);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(activations, 2);
    });

    testWidgets('MindSwitch toggles on keyboard Space when focused', (tester) async {
      var toggled = false;
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        _wrapApp(
          StatefulBuilder(
            builder: (context, setState) => MindSwitch(
              value: toggled,
              focusNode: focusNode,
              semanticLabel: 'Reminders',
              onChanged: (next) => setState(() => toggled = next),
            ),
          ),
        ),
      );

      focusNode.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(toggled, isTrue);
    });

    testWidgets('MindBadge interactive tap target is >= 48x48 and never uses FittedBox', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrapApp(
          MindBadge(
            label: 'Clinical tag',
            onTap: () => tapped = true,
          ),
        ),
      );

      expect(find.byType(FittedBox), findsNothing);
      final size = tester.getSize(find.byType(MindBadge));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));

      await tester.tap(find.byType(MindBadge));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('MindButton supports sizes and accessible disabled/danger contrast', (tester) async {
      await tester.pumpWidget(
        _wrapApp(
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MindButton(
                text: 'Disabled action',
                variant: MindButtonVariant.primary,
                onPressed: null,
              ),
              SizedBox(height: 12),
              MindButton(
                text: 'Compact danger',
                variant: MindButtonVariant.danger,
                size: MindButtonSize.sm,
                onPressed: null,
              ),
            ],
          ),
          brightness: Brightness.dark,
        ),
      );

      for (final finder in [
        find.text('Disabled action'),
        find.text('Compact danger'),
      ]) {
        final text = tester.widget<Text>(finder);
        expect(text.style?.color, MindTokens.dark.disabledInk);
      }
    });

    testWidgets('MindUndoBanner renders high-contrast Undo button in Light and Dark', (tester) async {
      for (final brightness in [Brightness.light, Brightness.dark]) {
        var undone = false;
        await tester.pumpWidget(
          MaterialApp(
            key: ValueKey<Brightness>(brightness),
            theme: buildMindTheme(brightness),
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () {
                    showMindUndoBanner(
                      ctx,
                      message: 'Entry removed',
                      undoLabel: 'Undo',
                      onUndo: () => undone = true,
                    );
                  },
                  child: const Text('Delete'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        final undoText = tester.widget<Text>(find.text('Undo'));
        final tokens = MindTokens.forBrightness(brightness);
        expect(undoText.style?.color, tokens.ink);
        expect(
          _contrastRatio(tokens.ink, tokens.bg),
          greaterThanOrEqualTo(15.0),
        );

        await tester.tap(find.text('Undo'));
        await tester.pumpAndSettle();
        expect(undone, isTrue);
      }
    });
  });

  group('Phase 1: New Core Primitives & Overlay Toast', () {
    testWidgets('showMindToast renders above open MindSheet via root Overlay', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildMindTheme(Brightness.light),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showMindSheet<void>(
                    context: context,
                    title: 'Sheet Title',
                    showCloseButton: true,
                    builder: (sheetCtx) => MindButton(
                      text: 'Trigger Toast',
                      onPressed: () => showMindToast(
                        sheetCtx,
                        'Saved above sheet',
                        variant: MindToastVariant.success,
                      ),
                    ),
                  );
                },
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();
      expect(find.text('Sheet Title'), findsOneWidget);

      await tester.tap(find.text('Trigger Toast'));
      await tester.pump();
      expect(find.text('Saved above sheet'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);
    });

    testWidgets('MindSheet constrains width to 600px on desktop viewports', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: buildMindTheme(Brightness.light),
          home: const Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: MindSheet(
                title: 'Desktop Sheet',
                child: Text('Centered body'),
              ),
            ),
          ),
        ),
      );

      final container = find.descendant(
        of: find.byType(MindSheet),
        matching: find.byWidgetPredicate(
          (w) => w is Container && w.constraints?.maxWidth == 600,
        ),
      );
      expect(container, findsOneWidget);
    });

    testWidgets('MindBanner, MindDialog, MindEmptyState, MindErrorState, MindSkeleton & MindPageContainer work cleanly', (tester) async {
      var bannerAction = false;
      var emptyAction = false;
      var retried = false;

      await tester.pumpWidget(
        _wrapApp(
          SingleChildScrollView(
            child: MindPageContainer(
              maxWidth: 720,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MindBanner(
                    title: 'Clinical notice',
                    body: 'Review documented entries before exporting.',
                    tone: MindBannerTone.info,
                    actionLabel: 'Review',
                    onAction: () => bannerAction = true,
                  ),
                  const SizedBox(height: 12),
                  const MindSkeleton.line(width: 180),
                  const SizedBox(height: 8),
                  const MindSkeleton.card(height: 64),
                  const SizedBox(height: 12),
                  MindEmptyState(
                    icon: Icons.inbox_outlined,
                    title: 'No entries yet',
                    subtitle: 'Start with a quick mood check-in.',
                    actionLabel: 'Add entry',
                    onAction: () => emptyAction = true,
                  ),
                  MindErrorState(
                    title: 'Could not load',
                    message: 'Please try again in a moment.',
                    retryLabel: 'Retry',
                    onRetry: () => retried = true,
                  ),
                  Builder(
                    builder: (ctx) => MindButton(
                      text: 'Open Confirm',
                      onPressed: () => showMindConfirmDialog(
                        ctx,
                        title: 'Remove record?',
                        body: 'This action removes the record permanently.',
                        confirmLabel: 'Remove',
                        cancelLabel: 'Cancel',
                        destructive: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          disableAnimations: true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Review'));
      await tester.ensureVisible(find.text('Add entry'));
      await tester.tap(find.text('Add entry'));
      await tester.ensureVisible(find.text('Retry'));
      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(bannerAction, isTrue);
      expect(emptyAction, isTrue);
      expect(retried, isTrue);

      await tester.ensureVisible(find.text('Open Confirm'));
      await tester.tap(find.text('Open Confirm'));
      await tester.pumpAndSettle();
      expect(find.byType(MindDialog), findsOneWidget);
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();
      expect(find.byType(MindDialog), findsNothing);
    });

    testWidgets('Doctor Edition stays clinically neutral when activeMood changes', (tester) async {
      SharedPreferences.setMockInitialValues({
        'mf_onboarding_completed': true,
      });
      AppEditionConfig.setMainEdition(MindoraEdition.clinician);
      addTearDown(() => AppEditionConfig.setMainEdition(MindoraEdition.patient));

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MindForensicsApp(),
        ),
      );
      await tester.pumpAndSettle();

      container.read(activeMoodProvider.notifier).setMood(AppMood.frustrated);
      await tester.pumpAndSettle();

      final animatedTheme = tester.widget<AnimatedTheme>(
        find.byKey(const ValueKey('mind_animated_theme')),
      );
      final tokens = animatedTheme.data.extension<MindTokens>()!;
      expect(tokens.m1, MindTokens.moodCalm);
    });
  });
}
