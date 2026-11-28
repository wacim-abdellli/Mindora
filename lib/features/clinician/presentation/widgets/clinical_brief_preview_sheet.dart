import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/theme/mind_tokens.dart';
import '../../../../core/export/document_exporter.dart';
import '../../../../core/widgets/mind_badge.dart';
import '../../../../core/widgets/mind_banner.dart';
import '../../../../core/widgets/mind_button.dart';
import '../../../../core/widgets/mind_skeleton.dart';
import '../../../../core/widgets/mind_switch.dart';
import '../../../../core/widgets/mind_toast.dart';
import '../../controllers/clinician_providers.dart';
import '../../data/clinical_brief_pdf_service.dart';
import '../../domain/clinician_models.dart';
import '../../domain/post_visit_focus_model.dart';

/// Displays the rendered multi-page searchable vector A4 Consultation Brief
/// with Download/Save As, Print, OS Share, optional doctor notes toggle,
/// and plain-text EHR copy — with explicit error handling and above-sheet toasts.
class ClinicalBriefPreviewSheet extends ConsumerStatefulWidget {
  const ClinicalBriefPreviewSheet({
    super.key,
    required this.record,
    this.encryptedCode,
    this.activeFocusPlan,
  });

  final ClinicianPatientRecord record;
  final String? encryptedCode;
  final PostVisitFocusPlan? activeFocusPlan;

  static Future<void> show(
    BuildContext context, {
    required ClinicianPatientRecord record,
    String? encryptedCode,
    PostVisitFocusPlan? activeFocusPlan,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ClinicalBriefPreviewSheet(
        record: record,
        encryptedCode: encryptedCode,
        activeFocusPlan: activeFocusPlan,
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
  bool _includeClinicianNotes = true;
  bool _isRendering = false;
  bool _isSaving = false;
  bool _isPrinting = false;
  bool _isSharing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_result == null && _errorText == null && !_isRendering) {
      _render();
    }
  }

  String _buildFileName() {
    final now = DateTime.now();
    final datePart =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final slug = DocumentExporter.sanitizeFileName(widget.record.displayName);
    return 'mindora_brief_${slug}_$datePart.pdf';
  }

  Future<void> _render() async {
    setState(() {
      _isRendering = true;
      _errorText = null;
    });
    try {
      final strings = ref.read(appStringsProvider);
      final clinicianProfile = ref.read(clinicianProfileProvider).value;
      final res = await _pdfService.renderConsultationBrief(
        record: widget.record,
        strings: strings,
        encryptedCode: widget.encryptedCode,
        clinicianProfile: clinicianProfile,
        includeClinicianNotes: _includeClinicianNotes,
        activeFocusPlan: widget.activeFocusPlan,
      );
      if (mounted) {
        setState(() {
          _result = res;
          _isRendering = false;
        });
      }
    } catch (_) {
      if (mounted) {
        final strings = ref.read(appStringsProvider);
        setState(() {
          _errorText = strings.pdfExportFailedError;
          _isRendering = false;
        });
      }
    }
  }

  Future<void> _savePdf(AppStrings strings) async {
    final res = _result;
    if (res == null || _isSaving) return;
    setState(() {
      _isSaving = true;
      _errorText = null;
    });
    try {
      final fileName = _buildFileName();
      final exported = await ref.read(documentExporterProvider).savePdf(
            bytes: res.pdfBytes,
            fileName: fileName,
          );
      if (!mounted) return;
      if (exported.isCancelled) return;
      HapticFeedback.mediumImpact();
      showMindToast(
        context,
        strings.pdfSavedSnackbar(exported.fileName),
        variant: MindToastVariant.success,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorText = strings.pdfExportFailedError);
      showMindToast(
        context,
        strings.pdfExportFailedError,
        variant: MindToastVariant.error,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _printPdf(AppStrings strings) async {
    final res = _result;
    if (res == null || _isPrinting) return;
    setState(() {
      _isPrinting = true;
      _errorText = null;
    });
    try {
      final exported = await ref.read(documentExporterProvider).printPdf(
            bytes: res.pdfBytes,
            documentName: _buildFileName(),
          );
      if (!mounted || exported.isCancelled) return;
      HapticFeedback.mediumImpact();
      showMindToast(
        context,
        strings.pdfPrintedToast,
        variant: MindToastVariant.success,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorText = strings.pdfExportFailedError);
      showMindToast(
        context,
        strings.pdfExportFailedError,
        variant: MindToastVariant.error,
      );
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  Future<void> _sharePdf(AppStrings strings) async {
    final res = _result;
    if (res == null || _isSharing) return;
    setState(() {
      _isSharing = true;
      _errorText = null;
    });
    try {
      final fileName = _buildFileName();
      final filePath = await _pdfService.savePdfToLocalFile(
        res.pdfBytes,
        fileName: fileName,
      );
      await ref.read(clinicHandoffBridgeProvider).sharePdfFile(
            filePath: filePath,
            subject: strings.pdfShareSubject,
            text: strings.clinicalBriefSubtitle,
          );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorText = strings.pdfExportFailedError);
      showMindToast(
        context,
        strings.pdfExportFailedError,
        variant: MindToastVariant.error,
      );
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<void> _copyText(AppStrings strings) async {
    final res = _result;
    if (res == null) return;
    try {
      await Clipboard.setData(ClipboardData(text: res.plainSummary));
      HapticFeedback.mediumImpact();
      if (!mounted) return;
      showMindToast(
        context,
        strings.ehrCopiedSnackbar,
        variant: MindToastVariant.success,
      );
    } catch (_) {
      if (!mounted) return;
      showMindToast(
        context,
        strings.genericActionError,
        variant: MindToastVariant.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final strings = ref.watch(appStringsProvider);
    final screenSize = MediaQuery.sizeOf(context);
    final isWide = screenSize.width >= 840;

    final sheet = Container(
      constraints: BoxConstraints(
        maxHeight: screenSize.height * 0.90,
        maxWidth: isWide ? 600 : double.infinity,
      ),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(tokens.sheetRadius),
        ),
        border: Border(
          top: BorderSide(color: tokens.line),
          left: isWide ? BorderSide(color: tokens.line) : BorderSide.none,
          right: isWide ? BorderSide(color: tokens.line) : BorderSide.none,
        ),
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
                  color: tokens.lineStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 14, 12, 8),
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
                  IconButton(
                    tooltip:
                        MaterialLocalizations.of(context).closeButtonTooltip,
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded, color: tokens.ink2),
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
                    if (_errorText != null) ...[
                      MindBanner(
                        body: _errorText!,
                        tone: MindBannerTone.safety,
                        actionLabel: strings.tryAgainBtn,
                        onAction: _render,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_result == null && _isRendering)
                      const Column(
                        children: [
                          MindSkeleton.card(height: 240),
                          SizedBox(height: 12),
                          MindSkeleton.line(width: 220),
                        ],
                      )
                    else if (_result != null) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          MindBadge(
                            key: const ValueKey<String>('pdf-page-count-badge'),
                            icon: Icons.description_outlined,
                            label: strings.pdfPagesBadge(_result!.pageCount),
                            backgroundColor: tokens.primarySoft,
                            textColor: tokens.ink,
                          ),
                          MindBadge(
                            icon: Icons.verified_user_outlined,
                            label: strings.confidentialRecordBadge,
                          ),
                        ],
                      ),
                      if (widget.record.clinicianNotes.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: tokens.surface2,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: tokens.line),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      strings.includeClinicianNotesToggle,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: tokens.ink,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      strings.includeClinicianNotesSub,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: tokens.ink2,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              MindSwitch(
                                key: const ValueKey<String>(
                                  'pdf-include-notes-switch',
                                ),
                                value: _includeClinicianNotes,
                                semanticLabel:
                                    strings.includeClinicianNotesToggle,
                                onChanged: (val) {
                                  setState(() => _includeClinicianNotes = val);
                                  _render();
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            tokens.inputRadius,
                          ),
                          border: Border.all(color: tokens.line),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: AspectRatio(
                          aspectRatio: 595 / 842,
                          child: Image.memory(
                            _result!.previewPngBytes,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      MindButton(
                        key: const ValueKey<String>('pdf-share-btn'),
                        text: strings.sharePdfBriefBtn,
                        variant: MindButtonVariant.primary,
                        leadingIcon: Icons.ios_share_rounded,
                        isFullWidth: true,
                        isLoading: _isSharing,
                        onPressed: () => _sharePdf(strings),
                      ),
                      const SizedBox(height: 10),
                      MindButton(
                        key: const ValueKey<String>('pdf-save-btn'),
                        text: strings.savePdfBriefBtn,
                        variant: MindButtonVariant.secondary,
                        leadingIcon: Icons.download_rounded,
                        isFullWidth: true,
                        isLoading: _isSaving,
                        onPressed: () => _savePdf(strings),
                      ),
                      const SizedBox(height: 10),
                      MindButton(
                        key: const ValueKey<String>('pdf-print-btn'),
                        text: strings.printPdfBtn,
                        variant: MindButtonVariant.secondary,
                        leadingIcon: Icons.print_outlined,
                        isFullWidth: true,
                        isLoading: _isPrinting,
                        onPressed: () => _printPdf(strings),
                      ),
                      const SizedBox(height: 10),
                      MindButton(
                        key: const ValueKey<String>('pdf-copy-ehr-btn'),
                        text: strings.copyClinicalTextBtn,
                        variant: MindButtonVariant.soft,
                        leadingIcon: Icons.copy_rounded,
                        isFullWidth: true,
                        onPressed: () => _copyText(strings),
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

    return isWide ? Center(heightFactor: 1.0, child: sheet) : sheet;
  }
}
