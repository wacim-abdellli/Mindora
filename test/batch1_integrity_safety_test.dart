import 'package:flutter_test/flutter_test.dart';
import 'package:mind_forensics/app/localization/app_strings.dart';
import 'package:mind_forensics/core/safety/crisis_keywords.dart';
import 'package:mind_forensics/features/investigation/domain/label_type.dart';
import 'package:mind_forensics/features/investigation/domain/statement.dart';
import 'package:mind_forensics/features/mind_trace/domain/emotion_descriptors.dart';
import 'package:mind_forensics/features/mind_trace/domain/mind_trace_model.dart';
import 'package:mind_forensics/features/profile/domain/psychological_profile_model.dart';
import 'package:mind_forensics/features/track/presentation/widgets/track_mood_utils.dart';

void main() {
  group('Batch 1 Data Integrity & Safety Verification', () {
    test('MindTraceModel.copyWith clears nullable fields via explicit clear flags', () {
      final now = DateTime(2026, 11, 14, 10, 0);
      final base = MindTraceModel(
        id: 't1',
        date: now,
        overallMood: 'calm',
        moodIntensity: 5,
        energyLevel: 6,
        situation: 'Work / Demands',
        behavioralResponse: 'Walk',
        journalText: 'Initial note',
        createdAt: now,
        updatedAt: now,
      );

      final cleared = base.copyWith(
        clearEnergyLevel: true,
        clearSituation: true,
        clearBehavioralResponse: true,
        clearJournalText: true,
      );

      expect(cleared.energyLevel, isNull);
      expect(cleared.situation, isNull);
      expect(cleared.behavioralResponse, isNull);
      expect(cleared.journalText, isNull);
    });

    test('Statement.copyWith clears label and distortionTag cleanly', () {
      final stmt = Statement(
        id: 's1',
        text: 'They are ignoring me.',
        speaker: StatementSpeaker.user,
        label: LabelType.interpretation,
        distortionTag: 'mind_reading',
        timestamp: DateTime(2026, 11, 14),
      );

      final clearedLabel = stmt.copyWith(clearLabel: true);
      final clearedDistortion = clearedLabel.copyWith(clearDistortionTag: true);

      expect(clearedLabel.label, isNull);
      expect(clearedLabel.distortionTag, 'mind_reading');
      expect(clearedDistortion.label, isNull);
      expect(clearedDistortion.distortionTag, isNull);
    });

    test('EmotionDescriptor canonicalizes localized labels across EN/FR/AR', () {
      expect(EmotionDescriptor.canonicalKey('فرحان'), 'happy');
      expect(EmotionDescriptor.canonicalKey('Heureux'), 'happy');
      expect(EmotionDescriptor.canonicalKey('CALM'), 'calm');

      const fr = AppStrings('fr');
      const ar = AppStrings('ar');
      expect(trackMoodLabel('happy', fr), fr.moodGood);
      expect(trackMoodLabel('happy', ar), ar.moodGood);
    });

    test('PsychologicalProfileModel.isMinor protects canonical and legacy values', () {
      expect(
        PsychologicalProfileModel.empty().copyWith(ageRange: 'under_18').isMinor,
        isTrue,
      );
      expect(
        PsychologicalProfileModel.empty().copyWith(ageRange: '<18').isMinor,
        isTrue,
      );
      expect(
        PsychologicalProfileModel.empty().copyWith(ageRange: 'Under 18').isMinor,
        isTrue,
      );
      expect(
        PsychologicalProfileModel.empty().copyWith(ageRange: '25-34').isMinor,
        isFalse,
      );
    });

    test('CrisisKeywords handles diacritics, new phrases, and Tunisian benign idioms', () {
      expect(CrisisKeywords.evaluateText('Je me sens désespéré'), equals(1));
      expect(CrisisKeywords.evaluateText('Je veux mourir'), equals(2));
      expect(CrisisKeywords.evaluateText('Feeling suicidal tonight'), equals(2));
      expect(CrisisKeywords.evaluateText('نخمم بش ننتحر'), equals(2));
      expect(CrisisKeywords.evaluateText('نموت عليك يا صاحبي'), equals(0));
      expect(CrisisKeywords.evaluateText('نحب نموت اليوم'), equals(2));
    });
  });
}
