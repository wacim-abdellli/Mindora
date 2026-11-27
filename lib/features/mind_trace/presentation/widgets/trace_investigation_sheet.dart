import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/theme/mind_tokens.dart';
import '../../../../core/safety/crisis_keywords.dart';
import '../../../../core/safety/safety_interceptor.dart';
import '../../../../core/safety/support_button.dart';
import '../../controllers/mind_trace_controller.dart';
import '../../domain/mind_trace_model.dart';
import '../../domain/thought_trace_investigation.dart';

/// Modal bottom sheet allowing users to deconstruct a saved thought trace
/// using Socratic reflective questions. Non-coercive, completely optional.
class TraceInvestigationSheet extends ConsumerStatefulWidget {
  const TraceInvestigationSheet({
    super.key,
    required this.trace,
  });

  final MindTraceModel trace;

  static Future<void> show(BuildContext context, MindTraceModel trace) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TraceInvestigationSheet(trace: trace),
    );
  }

  @override
  ConsumerState<TraceInvestigationSheet> createState() =>
      _TraceInvestigationSheetState();
}

class _TraceInvestigationSheetState
    extends ConsumerState<TraceInvestigationSheet> {
  final Map<String, TextEditingController> _controllers = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    for (final q in ThoughtTraceInvestigation.questions) {
      String initialVal = widget.trace.investigationAnswers[q.id] ?? '';
      if (initialVal.isEmpty) {
        if (q.id == 'trigger' && widget.trace.situation != null) {
          initialVal = widget.trace.situation!;
        } else if (q.id == 'response' &&
            widget.trace.behavioralResponse != null) {
          initialVal = widget.trace.behavioralResponse!;
        }
      }
      _controllers[q.id] = TextEditingController(text: initialVal);
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _handleSave() async {
    final updatedAnswers = <String, String>{};
    var highestSafety = 0;
    for (final entry in _controllers.entries) {
      final text = entry.value.text.trim();
      if (text.isNotEmpty) {
        final level = CrisisKeywords.evaluateText(text);
        if (level == 2) {
          if (mounted) SafetyInterceptor.showCrisisPauseDialog(context);
          return;
        }
        if (level > highestSafety) highestSafety = level;
        updatedAnswers[entry.key] = text;
      }
    }

    setState(() => _isSaving = true);
    final updatedTrace = widget.trace.copyWith(
      investigationAnswers: updatedAnswers,
      situation: updatedAnswers['trigger'],
      clearSituation: !updatedAnswers.containsKey('trigger'),
      behavioralResponse: updatedAnswers['response'],
      clearBehavioralResponse: !updatedAnswers.containsKey('response'),
      updatedAt: DateTime.now(),
    );

    try {
      await ref
          .read(mindTraceControllerProvider.notifier)
          .updateCheckIn(updatedTrace);
      if (mounted) {
        final strings = ref.read(appStringsProvider);
        final messenger = ScaffoldMessenger.maybeOf(context);
        final parentContext = Navigator.of(context).context;
        Navigator.of(context).pop();
        final savedMsg = strings.isArabic
            ? 'تم حفظ التأمل في سجلّك.'
            : (strings.isFrench
                ? 'Réflexion enregistrée dans votre suivi.'
                : 'Thought reflection saved to your record.');
        messenger?.showSnackBar(
          SnackBar(
            backgroundColor: context.tokens.surface2,
            content: Text(
              highestSafety == 1
                  ? '$savedMsg ${strings.needSupportBtn}'
                  : savedMsg,
              style: TextStyle(color: context.tokens.ink, fontSize: 13),
            ),
            action: highestSafety == 1
                ? SnackBarAction(
                    label: strings.supportTitle,
                    onPressed: () {
                      if (parentContext.mounted) {
                        SupportModalSheet.show(parentContext);
                      }
                    },
                  )
                : null,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final media = MediaQuery.of(context);
    final tokens = context.tokens;

    return Container(
      height: media.size.height * 0.90,
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(tokens.cardRadius)),
        border: Border(
          top: BorderSide(color: tokens.line, width: 1),
          left: BorderSide(color: tokens.line, width: 1),
          right: BorderSide(color: tokens.line, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: tokens.ink2.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.isArabic
                            ? 'استكشاف الفكرة'
                            : (strings.isFrench
                                ? 'Exploration de la pensée'
                                : 'Explore this thought'),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                          color: tokens.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        strings.isArabic
                            ? 'استكشف هذه اللحظة بفضول ولطف. جميع الأسئلة اختيارية.'
                            : (strings.isFrench
                                ? 'Explorez ce moment avec curiosité. Toutes les questions sont facultatives.'
                                : 'Explore this moment with curiosity and compassion. Every question is optional.'),
                        style: TextStyle(
                          fontSize: 12,
                          color: tokens.ink2,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: strings.closeBtn,
                  icon: Icon(Icons.close, color: tokens.ink2),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          Divider(color: tokens.line, height: 1),

          // Scrollable inquiry questions
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                // Thought preview anchor card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: tokens.surface2,
                    borderRadius: BorderRadius.circular(tokens.cardRadius),
                    border: Border.all(
                      color: tokens.ink.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: tokens.ink,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            strings.isArabic
                                ? 'الأثر قيد الفحص'
                                : (strings.isFrench
                                    ? 'Empreinte en cours d’examen'
                                    : 'Thought under reflection'),
                            style: TextStyle(
                              fontSize: 12.0,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                              color: tokens.ink2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '“${widget.trace.thoughtPreview}”',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: tokens.ink,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Render each of the 6 Socratic questions
                for (var i = 0;
                    i < ThoughtTraceInvestigation.questions.length;
                    i++) ...[
                  _buildQuestionSection(
                    ThoughtTraceInvestigation.questions[i],
                    index: i + 1,
                  ),
                  const SizedBox(height: 18),
                ],
              ],
            ),
          ),

          // Bottom Action
          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              12 + media.padding.bottom,
            ),
            decoration: BoxDecoration(
              color: tokens.surface,
              border: Border(
                top: BorderSide(color: tokens.line, width: 1),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: tokens.ink,
                  foregroundColor: tokens.bg,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(tokens.buttonRadius),
                  ),
                ),
                child: _isSaving
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            tokens.bg,
                          ),
                        ),
                      )
                    : Text(
                        strings.isArabic
                            ? 'حفظ التأمل والتفكيك'
                            : (strings.isFrench
                                ? 'Enregistrer la réflexion'
                                : 'Save reflection to trace'),
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionSection(
    ThoughtTraceInvestigationQuestion q, {
    required int index,
  }) {
    final controller = _controllers[q.id];

    final tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.surface2,
        borderRadius: BorderRadius.circular(tokens.cardRadius),
        border: Border.all(color: tokens.line, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: tokens.cardTint,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: tokens.ink.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '0$index',
                  style: TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.bold,
                    color: tokens.ink,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  q.category,
                  style: TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                    color: tokens.ink2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            q.question,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: tokens.ink,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            q.hint,
            style: TextStyle(
              fontSize: 12.0,
              fontStyle: FontStyle.italic,
              color: tokens.ink2.withValues(alpha: 0.85),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            maxLines: 3,
            minLines: 2,
            style: TextStyle(
              fontSize: 13,
              color: tokens.ink,
              height: 1.4,
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Record your observation (optional)...',
              hintStyle: TextStyle(
                fontSize: 12,
                color: tokens.ink3,
              ),
              filled: true,
              fillColor: tokens.surface,
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(tokens.buttonRadius),
                borderSide: BorderSide(color: tokens.line),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(tokens.buttonRadius),
                borderSide: BorderSide(color: tokens.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(tokens.buttonRadius),
                borderSide: BorderSide(color: tokens.ink, width: 1.2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

