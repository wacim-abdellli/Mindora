import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mind_forensics/app/localization/app_strings.dart';

void main() {
  group('M9.3 — Grade-6 Plain Copy, Zero-Emoji & Jargon Gate', () {
    final emojiRegex = RegExp(
      r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]',
      unicode: true,
    );

    test('Zero Unicode emojis exist in lib/app/localization/app_strings.dart or UI widgets', () {
      final libDir = Directory('lib');
      final violations = <String>[];
      for (final entity in libDir.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final lines = entity.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (line.trimLeft().startsWith('//')) continue;
          if (emojiRegex.hasMatch(line)) {
            violations.add('${entity.path}:${i + 1}: ${line.trim()}');
          }
        }
      }
      expect(
        violations,
        isEmpty,
        reason: 'AGENTS.md Rule 5 forbids emojis in UI:\n${violations.join('\n')}',
      );
    });

    test('Key patient-facing AppStrings getters are free of clinical jargon across EN/FR/AR', () {
      const banned = [
        'vagal',
        'somatic',
        'activating catalyst',
        'cognitive distortion',
        'observed stabilizers',
        'forensic loop',
        'emotional granularity',
        'self-attunement',
        'inner observatory',
        'empirical reality',
      ];

      for (final lang in const ['en', 'fr', 'ar']) {
        final s = AppStrings(lang);
        final samples = <String, String>{
          'breathingTitle': s.breathingTitle,
          'observedStabilizersTitle': s.observedStabilizersTitle,
          'forensicLoopMapTitle': s.forensicLoopMapTitle,
          'forensicLoopMapSub': s.forensicLoopMapSub,
          'cognitiveDistortionSheetTitle': s.cognitiveDistortionSheetTitle,
          'tagDistortionBtn': s.tagDistortionBtn,
          'stageIncident': s.stageIncident,
          'stageEvidence': s.stageEvidence,
          'personalBaselineTitle': s.personalBaselineTitle,
          'emotionalVarietyTitle': s.emotionalVarietyTitle,
          'energyAndSleepTitle': s.energyAndSleepTitle,
          'reframe3Title': s.reframe3Title,
          'dailyInsightBody': s.dailyInsightBody,
          'nonJudgmentalNotice': s.nonJudgmentalNotice,
          'reliefLoggedConfirm': s.reliefLoggedConfirm,
          'crisisPauseBody': s.crisisPauseBody,
          'onboardingWelcomeBody': s.onboardingWelcomeBody,
          'onboardingPrivacyPromise': s.onboardingPrivacyPromise,
          'howAreYouRightNow': s.howAreYouRightNow,
          'strengthALittle': s.strengthALittle,
          'strengthMedium': s.strengthMedium,
          'strengthALot': s.strengthALot,
        };

        for (final entry in samples.entries) {
          expect(
            entry.value.trim(),
            isNotEmpty,
            reason: '$lang.${entry.key} must not be empty',
          );
          final lower = entry.value.toLowerCase();
          for (final word in banned) {
            expect(
              lower.contains(word),
              isFalse,
              reason: '$lang.${entry.key} still contains jargon "$word": "${entry.value}"',
            );
          }
        }
      }
    });

    test('All 6 plain mood labels and 4 gentle reminders exist in EN, FR, and Tunisian AR', () {
      for (final lang in const ['en', 'fr', 'ar']) {
        final s = AppStrings(lang);
        for (final key in const [
          'good',
          'calm',
          'anxious',
          'frustrated',
          'heavy',
          'restless',
        ]) {
          expect(s.plainMoodLabel(key).trim(), isNotEmpty);
        }
        expect(s.gentleReminderBodies.length, 4);
        for (final msg in s.gentleReminderBodies) {
          expect(msg.trim(), isNotEmpty);
          expect(msg.toLowerCase().contains('streak'), isFalse);
        }
      }
    });

    test('Zero #000000 pitch-black or purple tokens remain in MindTokens', () {
      final tokensFile = File('lib/app/theme/mind_tokens.dart');
      final contents = tokensFile.readAsStringSync();
      expect(
        contents.contains('0xFF000000'),
        isFalse,
        reason: 'Vercel palette forbids #000000 pure pitch-black backgrounds',
      );
      expect(
        contents.contains('0xFF1B1530'),
        isFalse,
        reason: 'Purple dark background #1B1530 must not appear in MindTokens',
      );
      expect(
        contents.contains('0xFF6A3DE8'),
        isFalse,
        reason: 'Purple primary #6A3DE8 must not appear in MindTokens',
      );
      expect(contents.contains('0xFFFAF9F6'), isTrue);
      expect(contents.contains('0xFF09090B'), isTrue);
    });

    test('All UI TextStyle literals in lib/ honor >= 12.0sp floor and avoid UI .toUpperCase()', () {
      final libDir = Directory('lib');
      final fontSizeRegex = RegExp(r'fontSize:\s*([0-9]+(?:\.[0-9]+)?)');
      final fontViolations = <String>[];
      final upperViolations = <String>[];

      for (final entity in libDir.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final normalizedPath = entity.path.replaceAll('\\', '/');
        final isPdfService = normalizedPath.endsWith('_pdf_service.dart');
        final isPresentation = normalizedPath.contains('/presentation/');
        final lines = entity.readAsLinesSync();

        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          final trimmed = line.trimLeft();
          if (trimmed.startsWith('//')) continue;

          if (!isPdfService) {
            for (final match in fontSizeRegex.allMatches(line)) {
              final value = double.tryParse(match.group(1) ?? '');
              if (value != null && value < 12.0) {
                fontViolations.add('$normalizedPath:${i + 1}: $trimmed');
              }
            }
          }

          if (isPresentation && line.contains('.toUpperCase()')) {
            // Allow clinic code uppercase input normalization
            final prevLine = i > 0 ? lines[i - 1] : '';
            final isClinicCode = line.contains('ClinicCode') ||
                line.contains('clinicCode') ||
                prevLine.contains('clinicCode') ||
                prevLine.contains('_clinicCodeCtrl');
            if (!isClinicCode) {
              upperViolations.add('$normalizedPath:${i + 1}: $trimmed');
            }
          }
        }
      }

      expect(
        fontViolations,
        isEmpty,
        reason: 'UI typography floor is 12.0sp:\n${fontViolations.join('\n')}',
      );
      expect(
        upperViolations,
        isEmpty,
        reason: 'Use sentence case instead of UI .toUpperCase():\n${upperViolations.join('\n')}',
      );
    });
  });
}
