import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/theme/mind_tokens.dart';
import '../../../../core/widgets/mind_button.dart';
import '../../data/clinical_brief_pdf_service.dart';
import '../../domain/clinician_models.dart';

/// Displays the rendered 1-page printable A4 Consultation Brief and allows
/// saving as PDF 1.4 locally or copying the plain-text clinical note.
class ClinicalBriefPreviewSheet extends ConsumerStatefulWidget {
  const ClinicalBriefPreviewSheet({
    super.key,
    required this.record,
    this.encryptedCode,
  });

  final ClinicianPatientRecord record;
  final String? encryptedCode;

  static Future<void> show(
    BuildContext context, {
    required ClinicianPatientRecord record,
    String? encryptedCode,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ClinicalBriefPreviewSheet(
        record: record,
        encryptedCode: encryptedCode,
      ),
    );
  }

  @override
  ConsumerState<ClinicalBriefPreviewSheet> createState() =>
      _ClinicalBriefPreviewSheetState();
}

class _ClinicalBriefPreviewSheetState
    extends ConsumerState<ClinicalBriefPreviewSheet> {
  final _pdfService = const ClinicalBriefPdfService();
  ClinicalBriefRenderResult? _result;
  String? _errorText;
  bool _isSaving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_result == null && _errorText == null) {
      _render();
    }
  }

  Future<void> _render() async {
    try {
      final strings = ref.read(appStringsProvider);
      final res = await _pdfService.renderConsultationBrief(
        record: widget.record,
        strings: strings,
        encryptedCode: widget.encryptedCode,
      );
      if (mounted) {
        setState(() => _result = res);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorText = e.toString());
      }
    }
  }

  Future<void> _savePdf(AppStrings strings, MindTokens tokens) async {
    final res = _result;
    if (res == null) return;
    setState(() => _isSaving = true);
    try {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'mind_forensics_brief_$ts.pdf';
      await _pdfService.savePdfToLocalFile(res.pdfBytes, fileName: fileName);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          backgroundColor: tokens.surface2,
          content: Text(
            strings.pdfSavedSnackbar(fileName),
            style: TextStyle(color: tokens.ink, fontSize: 13),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _copyText(AppStrings strings, MindTokens tokens) async {
    final res = _result;
    if (res == null) return;
    await Clipboard.setData(ClipboardData(text: res.plainSummary));
    HapticFeedback.mediumImpact();
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        backgroundColor: tokens.surface2,
        content: Text(
          strings.ehrCopiedSnackbar,
          style: TextStyle(color: tokens.ink, fontSize: 13),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final strings = ref.watch(appStringsProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.90,
      ),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(tokens.sheetRadius),
        ),
        border: Border(top: BorderSide(color: tokens.line)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: tokens.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
              child: Row(
                children: [
                  Icon(
                    Icons.picture_as_pdf_outlined,
                    size: 20,
                    color: tokens.ink,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.clinicalBriefTitle,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: tokens.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          strings.clinicalBriefSubtitle,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: tokens.ink2,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Tooltip(
                    message:
                        MaterialLocalizations.of(context).closeButtonTooltip,
                    child: IconButton(
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close_rounded, color: tokens.ink2),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: tokens.line),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_errorText != null)
                      Text(
                        _errorText!,
                        style: TextStyle(fontSize: 12.5, color: tokens.safety),
                      )
                    else if (_result == null)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else ...[
                      Container(
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(tokens.chipRadius),
                          border: Border.all(color: tokens.line),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: AspectRatio(
                          aspectRatio: 1240 / 1754,
                          child: Image.memory(
                            _result!.previewPngBytes,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      MindButton(
                        text: strings.savePdfBriefBtn,
                        variant: MindButtonVariant.primary,
                        leadingIcon: Icons.download_rounded,
                        isFullWidth: true,
                        isLoading: _isSaving,
                        onPressed: () => _savePdf(strings, tokens),
                      ),
                      const SizedBox(height: 10),
                      MindButton(
                        text: strings.copyClinicalTextBtn,
                        variant: MindButtonVariant.secondary,
                        leadingIcon: Icons.copy_rounded,
                        isFullWidth: true,
                        onPressed: () => _copyText(strings, tokens),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
