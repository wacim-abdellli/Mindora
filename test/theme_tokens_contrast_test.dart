import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mind_forensics/app/theme/lab_theme.dart';
import 'package:mind_forensics/app/theme/mind_tokens.dart';
import 'package:mind_forensics/app/theme/theme_controller.dart';
import 'package:mind_forensics/main.dart';

double _contrastRatio(Color foreground, Color background) {
  final bgOpaque = Color.alphaBlend(
    background,
    MindTokens.pureWhiteConstant,
  );
  final fgOpaque = Color.alphaBlend(foreground, bgOpaque);
  final l1 = fgOpaque.computeLuminance();
  final l2 = bgOpaque.computeLuminance();
  return (math.max(l1, l2) + 0.05) / (math.min(l1, l2) + 0.05);
}

void main() {
  group('Phase A — Unified Warm Daylight & Vercel Obsidian Dark Tokens', () {
    test('exact hex & alpha tokens match Vercel Zero-Purple specification', () {
      const light = MindTokens.light;
      const dark = MindTokens.dark;

      // Warm Alabaster Daylight (Default Light — zero purple)
      expect(light.bg, const Color(0xFFFAF9F6));
      expect(light.surface, const Color(0xFFFFFFFF));
      expect(light.surface2, const Color(0xFFF3F1EC));
      expect(light.surface3, const Color(0xFFEBE8E1));
      expect(light.line, const Color.fromRGBO(17, 17, 20, 0.09));
      expect(light.lineStrong, const Color.fromRGBO(17, 17, 20, 0.18));
      expect(light.ink, const Color(0xFF111114));
      expect(light.ink2, const Color(0xFF52525B));
      expect(light.ink3, const Color(0xFF5E5E68));
      expect(light.primary, const Color(0xFF111114));
      expect(light.onPrimary, const Color(0xFFFFFFFF));
      expect(light.onMood, const Color(0xFF111114));
      expect(light.safety, const Color(0xFFBE123C));
      expect(light.safetySoft, const Color(0xFFFFF1F2));
      expect(light.glow, 0.20);
      expect(light.orbGlowFactor, 1.0);
      expect(light.shadows.length, 2);
      expect(light.navGlass, const Color.fromRGBO(250, 249, 246, 0.92));
      expect(light.scrim, const Color.fromRGBO(9, 9, 11, 0.45));

      // Clean Vercel Obsidian-Zinc Dark (zero purple, zero #000000)
      expect(dark.bg, const Color(0xFF09090B));
      expect(dark.surface, const Color(0xFF111114));
      expect(dark.surface2, const Color(0xFF18181C));
      expect(dark.surface3, const Color(0xFF222228));
      expect(dark.line, const Color.fromRGBO(255, 255, 255, 0.09));
      expect(dark.lineStrong, const Color.fromRGBO(255, 255, 255, 0.18));
      expect(dark.ink, const Color(0xFFFAFAFA));
      expect(dark.ink2, const Color(0xFFA1A1AA));
      expect(dark.ink3, const Color(0xFF8B8B96));
      expect(dark.primary, const Color(0xFFFAFAFA));
      expect(dark.onPrimary, const Color(0xFF09090B));
      expect(dark.onMood, const Color(0xFF111114));
      expect(dark.safety, const Color(0xFFFB7185));
      expect(dark.safetySoft, const Color(0xFF2C1219));
      expect(dark.glow, 0.14);
      expect(dark.orbGlowFactor, 0.72);
      expect(dark.shadows, isEmpty);
      expect(dark.navGlass, const Color.fromRGBO(17, 17, 20, 0.92));
      expect(dark.scrim, const Color.fromRGBO(4, 4, 6, 0.70));
      expect(dark.focusRing, const Color(0xFF2DD4BF));

      // Canonical 6 vivid moods (zero purple)
      expect(MindTokens.moodColor(AppMood.good), const Color(0xFFFFC93C));
      expect(MindTokens.moodHighlight(AppMood.good), const Color(0xFFFFE58F));
      expect(MindTokens.moodColor(AppMood.calm), const Color(0xFF2DD4BF));
      expect(MindTokens.moodHighlight(AppMood.calm), const Color(0xFF99F6E4));
      expect(MindTokens.moodColor(AppMood.anxious), const Color(0xFF38BDF8));
      expect(
        MindTokens.moodHighlight(AppMood.anxious),
        const Color(0xFFBAE6FD),
      );
      expect(
        MindTokens.moodColor(AppMood.frustrated),
        const Color(0xFFFF7A59),
      );
      expect(
        MindTokens.moodHighlight(AppMood.frustrated),
        const Color(0xFFFFB49E),
      );
      expect(MindTokens.moodColor(AppMood.heavy), const Color(0xFF94A3B8));
      expect(MindTokens.moodHighlight(AppMood.heavy), const Color(0xFFCBD5E1));
      expect(MindTokens.moodColor(AppMood.restless), const Color(0xFFFBBF24));
      expect(
        MindTokens.moodHighlight(AppMood.restless),
        const Color(0xFFFDE68A),
      );
    });

    test('shared shapes & spacing match Spec 01 specification', () {
      for (final t in const [MindTokens.light, MindTokens.dark]) {
        expect(t.cardRadius, 24.0);
        expect(t.tileRadius, 22.0);
        expect(t.rowRadius, 20.0);
        expect(t.buttonRadius, 20.0);
        expect(t.chipRadius, 99.0);
        expect(t.inputRadius, 16.0);
        expect(t.iconButtonRadius, 16.0);
        expect(t.sheetRadius, 28.0);
        expect(t.screenPadding, 16.0);
        expect(t.blockGap, 16.0);
      }
    });

    test('tint & moodDayColor formulas compute exact alpha blends', () {
      const light = MindTokens.light;
      const dark = MindTokens.dark;

      expect(
        light.cardTint,
        Color.alphaBlend(
          light.m1.withValues(alpha: 0.14),
          light.surface,
        ),
      );
      expect(
        dark.cardTint,
        Color.alphaBlend(
          dark.m1.withValues(alpha: 0.10),
          dark.surface,
        ),
      );
      expect(
        light.selectedTint,
        Color.alphaBlend(
          light.m1.withValues(alpha: 0.22),
          light.surface,
        ),
      );
      expect(
        dark.selectedTint,
        Color.alphaBlend(
          dark.m1.withValues(alpha: 0.18),
          dark.surface,
        ),
      );
      expect(
        light.blobTint,
        Color.alphaBlend(
          light.m1.withValues(alpha: 0.36),
          light.surface,
        ),
      );
      expect(
        dark.blobTint,
        Color.alphaBlend(
          dark.m1.withValues(alpha: 0.28),
          dark.surface,
        ),
      );

      expect(
        light.moodDayColor(MindTokens.moodAnxious, 6),
        Color.alphaBlend(
          MindTokens.moodAnxious.withValues(alpha: 0.26 + 0.05 * 6),
          light.surface,
        ),
      );
      expect(
        dark.moodDayColor(MindTokens.moodAnxious, 6),
        Color.alphaBlend(
          MindTokens.moodAnxious.withValues(alpha: 0.20 + 0.04 * 6),
          dark.surface,
        ),
      );
    });
  });

  group('WCAG AA Contrast Gate (>= 4.5:1)', () {
    test(
      'ink, ink2, ink3 pass >= 4.5:1 on bg, surface, and surface2 in BOTH themes',
      () {
        for (final entry in const {
          'Light Dawn': MindTokens.light,
          'Dark Vercel': MindTokens.dark,
        }.entries) {
          final themeName = entry.key;
          final t = entry.value;
          final surfaces = {'bg': t.bg, 'surface': t.surface, 'surface2': t.surface2};
          final inks = {'ink': t.ink, 'ink2': t.ink2, 'ink3': t.ink3};

          for (final inkEntry in inks.entries) {
            for (final surfEntry in surfaces.entries) {
              final ratio = _contrastRatio(inkEntry.value, surfEntry.value);
              expect(
                ratio,
                greaterThanOrEqualTo(4.5),
                reason:
                    '$themeName ${inkEntry.key} on ${surfEntry.key} contrast = ${ratio.toStringAsFixed(2)}:1',
              );
            }
          }

          // Primary CTA: primary fill + onPrimary text
          expect(
            _contrastRatio(t.onPrimary, t.primary),
            greaterThanOrEqualTo(4.5),
            reason: '$themeName primary CTA contrast',
          );

          // Safety surfaces
          expect(
            _contrastRatio(t.safety, t.safetySoft),
            greaterThanOrEqualTo(4.5),
            reason: '$themeName safety on safetySoft contrast',
          );
          expect(
            _contrastRatio(t.safety, t.surface),
            greaterThanOrEqualTo(4.5),
            reason: '$themeName safety on surface contrast',
          );
        }

        // onMood on every mood color & highlight
        for (final mood in AppMood.values) {
          final c1Ratio = _contrastRatio(
            MindTokens.onMoodConstant,
            MindTokens.moodColor(mood),
          );
          final c2Ratio = _contrastRatio(
            MindTokens.onMoodConstant,
            MindTokens.moodHighlight(mood),
          );
          expect(
            c1Ratio,
            greaterThanOrEqualTo(4.5),
            reason: 'onMood on ${mood.key} c1 = ${c1Ratio.toStringAsFixed(2)}',
          );
          expect(
            c2Ratio,
            greaterThanOrEqualTo(4.5),
            reason: 'onMood on ${mood.key} c2 = ${c2Ratio.toStringAsFixed(2)}',
          );
        }
      },
    );
  });

  group('Typography & Arabic Support', () {
    test('Inter + Noto Sans Arabic fallback and zero Arabic letterSpacing', () async {
      expect(LabTheme.fontFamily, 'Inter');
      expect(LabTheme.fontFallback, contains('Noto Sans Arabic'));

      // Verify bundled Noto Sans Arabic assets are packaged & loadable by FontLoader
      final reg = await rootBundle.load('assets/fonts/NotoSansArabic-Regular.ttf');
      final semi = await rootBundle.load('assets/fonts/NotoSansArabic-SemiBold.ttf');
      final bold = await rootBundle.load('assets/fonts/NotoSansArabic-Bold.ttf');
      expect(reg.lengthInBytes, greaterThan(100000));
      expect(semi.lengthInBytes, greaterThan(100000));
      expect(bold.lengthInBytes, greaterThan(100000));

      final loader = FontLoader('Noto Sans Arabic')
        ..addFont(Future.value(reg))
        ..addFont(Future.value(semi))
        ..addFont(Future.value(bold));
      await loader.load();

      final lightTheme = buildMindTheme(Brightness.light);
      final arabicTheme = buildMindTheme(Brightness.dark, isArabic: true);

      expect(lightTheme.textTheme.bodyMedium?.fontFamily, 'Inter');
      expect(
        lightTheme.textTheme.bodyMedium?.fontFamilyFallback,
        contains('Noto Sans Arabic'),
      );
      expect(lightTheme.splashFactory, NoSplash.splashFactory);
      expect(lightTheme.dividerColor, MindTokens.light.line);

      expect(arabicTheme.textTheme.displayLarge?.letterSpacing, 0.0);
      expect(arabicTheme.textTheme.headlineMedium?.letterSpacing, 0.0);
      expect(arabicTheme.textTheme.bodyMedium?.letterSpacing, 0.0);
      expect(arabicTheme.textTheme.labelSmall?.letterSpacing, 0.0);
    });
  });

  group('ThemeMode Default, Preload & Persistence', () {
    test('defaults to ThemeMode.light (Sunrise) and preloads saved preference cleanly', () async {
      SharedPreferences.setMockInitialValues({});
      expect(
        await ThemeController.loadInitialThemeMode(),
        ThemeMode.light,
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(themeControllerProvider), ThemeMode.light);

      await container
          .read(themeControllerProvider.notifier)
          .setTheme(ThemeMode.dark);
      expect(container.read(themeControllerProvider), ThemeMode.dark);
      expect(
        await ThemeController.loadInitialThemeMode(),
        ThemeMode.dark,
      );

      await container
          .read(themeControllerProvider.notifier)
          .setTheme(ThemeMode.light);
      expect(
        await ThemeController.loadInitialThemeMode(),
        ThemeMode.light,
      );
    });

    testWidgets(
      'MindForensicsApp honors preloaded ThemeMode without flash and configures AnimatedTheme',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          ThemeController.keyTheme: 'dark',
        });
        final preloaded = await ThemeController.loadInitialThemeMode();
        expect(preloaded, ThemeMode.dark);

        final container = ProviderContainer(
          overrides: [
            initialThemeModeProvider.overrideWithValue(preloaded),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MindForensicsApp(),
          ),
        );
        await tester.pump();

        final hostFinder = find.byKey(const ValueKey('mind_animated_theme'));
        final animatedTheme = tester.widget<AnimatedTheme>(hostFinder);
        expect(animatedTheme.data.brightness, Brightness.dark);
        expect(
          animatedTheme.data.extension<MindTokens>()?.bg,
          const Color(0xFF09090B),
        );
        expect(animatedTheme.duration, const Duration(milliseconds: 200));

        // Dynamic mood switch animates m1/m2 with ~700ms duration
        container.read(activeMoodProvider.notifier).setMood(AppMood.anxious);
        await tester.pump();
        final moodAnimatedTheme = tester.widget<AnimatedTheme>(hostFinder);
        expect(moodAnimatedTheme.duration, const Duration(milliseconds: 700));
        expect(
          moodAnimatedTheme.data.extension<MindTokens>()?.m1,
          const Color(0xFF38BDF8),
        );
        expect(
          moodAnimatedTheme.data.extension<MindTokens>()?.m2,
          const Color(0xFFBAE6FD),
        );

        // Collapses to Duration.zero when disableAnimations is enabled.
        SharedPreferences.setMockInitialValues({
          ThemeController.keyTheme: 'light',
        });
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: ProviderScope(
              overrides: [
                initialThemeModeProvider.overrideWithValue(ThemeMode.light),
              ],
              child: const MindForensicsApp(),
            ),
          ),
        );
        await tester.pump();

        final reducedAnimatedTheme = tester.widget<AnimatedTheme>(
          find.byKey(const ValueKey('mind_animated_theme')),
        );
        expect(reducedAnimatedTheme.duration, Duration.zero);
        expect(reducedAnimatedTheme.data.brightness, Brightness.light);
        expect(
          reducedAnimatedTheme.data.extension<MindTokens>()?.bg,
          const Color(0xFFFAF9F6),
        );
      },
    );
  });
}
