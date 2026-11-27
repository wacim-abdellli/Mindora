import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/theme/mind_tokens.dart';
import '../../insights/data/pattern_awareness_service.dart';
import '../../insights/domain/personal_baseline_model.dart';
import '../../investigation/domain/case_model.dart';
import '../../mind_trace/domain/mind_trace_model.dart';
import '../data/clinical_export_log_service.dart';
import '../data/clinical_export_service.dart';

/// Plain-language clinical session brief preview sheet before anything leaves the app.
///
/// Section 12 Principle 6: "A plain-language preview before anything leaves the app."
/// Strictly follows Vercel Luxury Dark aesthetics, 0 emojis, and CBT clinical bounds.
class ClinicalExportPreviewSheet extends ConsumerStatefulWidget {
  const ClinicalExportPreviewSheet({
    super.key,
    required this.cases,
    this.baseline,
    this.weeklySummary,
    this.traces,
  });

  final List<CaseModel> cases;
  final PersonalBaseline? baseline;
  final WeeklySummaryReport? weeklySummary;
  final List<MindTraceModel>? traces;

  /// Shows the preview modal sheet.
  static Future<void> show(
    BuildContext context,
    List<CaseModel> cases, {
    PersonalBaseline? baseline,
    WeeklySummaryReport? weeklySummary,
    List<MindTraceModel>? traces,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClinicalExportPreviewSheet(
        cases: cases,
        baseline: baseline,
        weeklySummary: weeklySummary,
        traces: traces,
      ),
    );
  }

  @override
  ConsumerState<ClinicalExportPreviewSheet> createState() => _ClinicalExportPreviewSheetState();
}

class _ClinicalExportPreviewSheetState extends ConsumerState<ClinicalExportPreviewSheet> {
  final TextEditingController _noteController = TextEditingController();
  late String _generatedBrief;
  late int _excludedPrivateCount;

  @override
  void initState() {
    super.initState();
    final privateCases = widget.cases.where((c) => c.isPrivate).toList();
    _excludedPrivateCount = privateCases.length;
    _refreshBrief();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _refreshBrief() {
    final strings = ref.read(appStringsProvider);
    _generatedBrief = ClinicalExportService.generateSessionBrief(
      cases: widget.cases,
      strings: strings,
      recipientOrNote: _noteController.text,
      baseline: widget.baseline,
      weeklySummary: widget.weeklySummary,
      traces: widget.traces,
    );
  }

  void _handleCopy() async {
    HapticFeedback.mediumImpact();
    Clipboard.setData(ClipboardData(text: _generatedBrief));

    final shareableSessions = widget.cases.where((c) => !c.isPrivate).map((c) => c.caseNumber).toList();
    if (shareableSessions.isNotEmpty) {
      await ref.read(clinicalExportLogServiceProvider).logExport(
            sessionNumbers: shareableSessions,
            recipientOrNote: _noteController.text.trim(),
          );
    }

    if (mounted) {
      final strings = ref.read(appStringsProvider);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            strings.sessionBriefCopiedSuccess,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final strings = ref.watch(appStringsProvider);

    final border = tokens.line;
    final textPrimary = tokens.ink;
    final textSecondary = tokens.ink2;

    final shareableCases = widget.cases.where((c) => !c.isPrivate).toList();
    final hasTrackingData =
        (widget.baseline != null && widget.baseline!.totalRecordedDays > 0) ||
            (widget.weeklySummary != null &&
                widget.weeklySummary!.totalEntriesThisWeek > 0) ||
            (widget.traces?.isNotEmpty ?? false);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: BoxDecoration(
        color: context.tokens.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(context.tokens.sheetRadius)),
        border: Border(top: BorderSide(color: border, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Drag Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: context.tokens.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.shield_outlined, size: 18, color: textPrimary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.exportSessionBriefTitle,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          strings.sessionBriefSubtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12.5, color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: strings.closeBtn,
                    icon: Icon(Icons.close_rounded, size: 18, color: textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: border),

            // Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Clinical Disclaimer Banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.tokens.surface2,
                      borderRadius: BorderRadius.circular(context.tokens.buttonRadius),
                      border: Border.all(color: border, width: 1),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: context.tokens.safety,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            strings.clinicalDisclaimerNotice,
                            style: TextStyle(fontSize: 12.5, color: textSecondary, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Private Exclusion Alert if applicable
                  if (_excludedPrivateCount > 0) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: tokens.safetySoft,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: tokens.safety.withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lock_rounded,
                            size: 14,
                            color: tokens.safety,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              strings.privateCasesExcludedNote(_excludedPrivateCount),
                              style: TextStyle(
                                fontSize: 12.0,
                                fontWeight: FontWeight.w700,
                                color: tokens.safety,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 14),

                  // Optional Recipient / Note field
                  TextField(
                    controller: _noteController,
                    onChanged: (_) {
                      setState(() {
                        _refreshBrief();
                      });
                    },
                    style: TextStyle(fontSize: 13.5, color: textPrimary),
                    decoration: InputDecoration(
                      labelText: strings.recipientOrNoteLabel,
                      labelStyle: TextStyle(fontSize: 12.5, color: textSecondary),
                      hintText: strings.recipientOrNoteHint,
                      hintStyle: TextStyle(
                        fontSize: 12.5,
                        color: context.tokens.ink3,
                      ),
                      filled: true,
                      fillColor: context.tokens.surface2,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(context.tokens.buttonRadius),
                        borderSide: BorderSide(color: border, width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(context.tokens.buttonRadius),
                        borderSide: BorderSide(color: border, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(context.tokens.buttonRadius),
                        borderSide: BorderSide(color: context.tokens.ink, width: 1.2),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Live Preview Box
                  Text(
                    strings.isArabic ? 'معاينة المستند الصادر:' : (strings.isFrench ? 'Aperçu du document exporté :' : 'Export Document Preview:'),
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: context.tokens.surface2,
                      borderRadius: BorderRadius.circular(context.tokens.cardRadius),
                      border: Border.all(color: border, width: 1),
                    ),
                    child: SelectableText(
                      _generatedBrief,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontFeatures: const [FontFeature.tabularFigures()],
                        fontSize: 12.0,
                        height: 1.45,
                        color: textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Action Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: context.tokens.ink,
                    foregroundColor: context.tokens.bg,
                    disabledBackgroundColor: context.tokens.line,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(context.tokens.buttonRadius),
                    ),
                  ),
                  icon: const Icon(Icons.content_copy_rounded, size: 16),
                  label: Text(
                    strings.copySessionBriefBtn,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.6),
                  ),
                  onPressed:
                      (shareableCases.isEmpty && !hasTrackingData) ? null : _handleCopy,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

