import 'dart:convert';

import 'conversation_mode.dart';
import 'label_type.dart';

/// Internal posture selected autonomously by the AI Companion per turn.
///
/// Users never have to pick clinical modes manually; this maps cleanly back onto
/// [ConversationMode] under the hood for pacing and session continuity.
enum AdaptivePosture {
  sootheListen,
  somaticGround,
  validateFeelings,
  gentleReframe,
  practicalStep,
  closingWarmth;

  String get wireKey => switch (this) {
    AdaptivePosture.sootheListen => 'soothe_listen',
    AdaptivePosture.somaticGround => 'somatic_ground',
    AdaptivePosture.validateFeelings => 'validate_feelings',
    AdaptivePosture.gentleReframe => 'gentle_reframe',
    AdaptivePosture.practicalStep => 'practical_step',
    AdaptivePosture.closingWarmth => 'closing_warmth',
  };

  static AdaptivePosture fromWire(String? raw) {
    final normalized = (raw ?? '').trim().toLowerCase();
    return switch (normalized) {
      'soothe_listen' || 'soothelisten' || 'just_talk' =>
        AdaptivePosture.sootheListen,
      'somatic_ground' || 'somaticground' || 'grounding' =>
        AdaptivePosture.somaticGround,
      'validate_feelings' || 'validatefeelings' || 'understand_emotion' =>
        AdaptivePosture.validateFeelings,
      'practical_step' || 'practicalstep' || 'guided_reflection' =>
        AdaptivePosture.practicalStep,
      'closing_warmth' || 'closingwarmth' => AdaptivePosture.closingWarmth,
      _ => AdaptivePosture.gentleReframe,
    };
  }

  ConversationMode toConversationMode() => switch (this) {
    AdaptivePosture.sootheListen || AdaptivePosture.closingWarmth =>
      ConversationMode.justTalk,
    AdaptivePosture.somaticGround => ConversationMode.grounding,
    AdaptivePosture.validateFeelings => ConversationMode.understandEmotion,
    AdaptivePosture.gentleReframe => ConversationMode.exploreThought,
    AdaptivePosture.practicalStep => ConversationMode.guidedReflection,
  };
}

/// Optional quiet calm-down suggestion surfaced only when genuinely needed.
enum CalmExerciseOffer {
  none,
  breathing,
  grounding;

  String get wireKey => name;

  static CalmExerciseOffer fromWire(String? raw) {
    final normalized = (raw ?? '').trim().toLowerCase();
    if (normalized == 'breathing') return CalmExerciseOffer.breathing;
    if (normalized == 'grounding') return CalmExerciseOffer.grounding;
    return CalmExerciseOffer.none;
  }
}

/// Structured adaptive turn returned by both live (Gemini/Groq) and local
/// companion engines so the UI stays serene and options-first.
class CompanionTurnResponse {
  const CompanionTurnResponse({
    required this.reply,
    this.chosenPosture = AdaptivePosture.gentleReframe,
    this.suggestedReplies = const [],
    this.offerCalmExercise = CalmExerciseOffer.none,
    this.silentThoughtType,
    this.silentDistortionTheme,
    this.silentTrigger,
    this.silentCoreThought,
    this.silentEmotion,
    this.silentIntensity,
    this.silentCopingBehavior,
    this.clinicalIntakeNote,
    this.saveWorthySummary,
  });

  final String reply;
  final AdaptivePosture chosenPosture;
  final List<String> suggestedReplies;
  final CalmExerciseOffer offerCalmExercise;
  final LabelType? silentThoughtType;
  final String? silentDistortionTheme;
  final String? silentTrigger;
  final String? silentCoreThought;
  final String? silentEmotion;
  final int? silentIntensity;
  final String? silentCopingBehavior;
  final String? clinicalIntakeNote;
  final String? saveWorthySummary;

  static final RegExp _emojiRegex = RegExp(
    r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]',
    unicode: true,
  );

  static String sanitizeText(String input) =>
      input.replaceAll(_emojiRegex, '').replaceAll(RegExp(r'\s{2,}'), ' ').trim();

  static List<String> sanitizeOptions(Iterable<dynamic> rawOptions) {
    final seen = <String>{};
    final result = <String>[];
    for (final item in rawOptions) {
      final clean = sanitizeText(item.toString());
      if (clean.isEmpty || clean.length > 76) continue;
      final key = clean.toLowerCase();
      if (seen.add(key)) {
        result.add(clean);
      }
      if (result.length >= 3) break;
    }
    return result;
  }

  static LabelType? parseThoughtType(String? raw) {
    final normalized = (raw ?? '').trim().toLowerCase();
    if (normalized == 'fact') return LabelType.fact;
    if (normalized == 'assumption' || normalized == 'guess') {
      return LabelType.assumption;
    }
    if (normalized == 'interpretation' || normalized == 'story') {
      return LabelType.interpretation;
    }
    return null;
  }

  static String? normalizeDistortionTheme(String? raw) {
    final clean = sanitizeText(raw ?? '');
    if (clean.isEmpty || clean.toLowerCase() == 'none') return null;
    final lower = clean.toLowerCase();
    if (lower.contains('mind_read') || lower.contains('mind read')) {
      return 'Mind Reading';
    }
    if (lower.contains('catastroph')) return 'Catastrophizing';
    if (lower.contains('all_or_nothing') || lower.contains('all-or-nothing')) {
      return 'All-or-Nothing Thinking';
    }
    if (lower.contains('emotional_reason') || lower.contains('emotional reason')) {
      return 'Emotional Reasoning';
    }
    if (lower.contains('overgeneral')) return 'Overgeneralizing';
    if (lower.contains('filter')) return 'Mental Filtering';
    return clean;
  }

  /// Strict Gemini JSON response schema enforcing adaptive structured output.
  static Map<String, dynamic> get geminiResponseSchema => {
    'type': 'OBJECT',
    'required': [
      'reply',
      'chosen_posture',
      'suggested_replies',
      'offer_calm_exercise',
    ],
    'properties': {
      'reply': {'type': 'STRING'},
      'chosen_posture': {
        'type': 'STRING',
        'enum': [
          'soothe_listen',
          'somatic_ground',
          'validate_feelings',
          'gentle_reframe',
          'practical_step',
          'closing_warmth',
        ],
      },
      'suggested_replies': {
        'type': 'ARRAY',
        'items': {'type': 'STRING'},
      },
      'offer_calm_exercise': {
        'type': 'STRING',
        'enum': ['none', 'breathing', 'grounding'],
      },
      'silent_thought_type': {
        'type': 'STRING',
        'enum': ['fact', 'assumption', 'interpretation', 'none'],
      },
      'silent_distortion_theme': {'type': 'STRING'},
      'silent_trigger': {'type': 'STRING'},
      'silent_core_thought': {'type': 'STRING'},
      'silent_emotion': {'type': 'STRING'},
      'silent_intensity': {'type': 'INTEGER'},
      'silent_coping_behavior': {'type': 'STRING'},
      'clinical_intake_note': {'type': 'STRING'},
      'save_worthy_summary': {'type': 'STRING'},
    },
  };

  /// Attempts to parse raw JSON (optionally wrapped in markdown fences) into a
  /// clean [CompanionTurnResponse]. Returns null if reply is empty/unusable.
  static CompanionTurnResponse? tryParseJson(String raw) {
    var cleaned = raw.trim();
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    cleaned = cleaned.trim();

    try {
      final decoded = jsonDecode(cleaned);
      if (decoded is! Map<String, dynamic>) return null;
      final reply = sanitizeText(decoded['reply']?.toString() ?? '');
      if (reply.isEmpty) return null;

      final rawSuggestions = decoded['suggested_replies'];
      final suggested = rawSuggestions is List
          ? sanitizeOptions(rawSuggestions)
          : const <String>[];

      String? cleanOptional(String key) {
        final v = sanitizeText(decoded[key]?.toString() ?? '');
        return v.isEmpty ? null : v;
      }

      int? parsedIntensity;
      final rawInt = decoded['silent_intensity'];
      if (rawInt is num) {
        parsedIntensity = rawInt.round().clamp(1, 10);
      } else if (rawInt is String) {
        final parsed = int.tryParse(rawInt.trim());
        if (parsed != null) parsedIntensity = parsed.clamp(1, 10);
      }

      return CompanionTurnResponse(
        reply: reply,
        chosenPosture: AdaptivePosture.fromWire(
          decoded['chosen_posture']?.toString(),
        ),
        suggestedReplies: suggested,
        offerCalmExercise: CalmExerciseOffer.fromWire(
          decoded['offer_calm_exercise']?.toString(),
        ),
        silentThoughtType: parseThoughtType(
          decoded['silent_thought_type']?.toString(),
        ),
        silentDistortionTheme: normalizeDistortionTheme(
          decoded['silent_distortion_theme']?.toString(),
        ),
        silentTrigger: cleanOptional('silent_trigger'),
        silentCoreThought: cleanOptional('silent_core_thought'),
        silentEmotion: cleanOptional('silent_emotion'),
        silentIntensity: parsedIntensity,
        silentCopingBehavior: cleanOptional('silent_coping_behavior'),
        clinicalIntakeNote: cleanOptional('clinical_intake_note'),
        saveWorthySummary: cleanOptional('save_worthy_summary'),
      );
    } catch (_) {
      return null;
    }
  }
}
