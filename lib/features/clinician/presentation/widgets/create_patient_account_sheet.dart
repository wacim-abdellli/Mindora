import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/theme/mind_tokens.dart';
import '../../../../core/export/document_exporter.dart';
import '../../../../core/widgets/mind_badge.dart';
import '../../../../core/widgets/mind_button.dart';
import '../../../../core/widgets/mind_card.dart';
import '../../../../core/widgets/mind_pressable.dart';
import '../../../../core/widgets/mind_qr_code.dart';
import '../../../../core/widgets/mind_toast.dart';
import '../../../clinic_sync/controllers/clinic_sync_providers.dart';
import '../../../clinic_sync/domain/clinic_account_models.dart';
import '../../../profile/domain/clinical_condition_catalog.dart';
import '../../controllers/clinician_providers.dart';
import '../../data/patient_welcome_card_pdf_service.dart';

/// Doctor Admin modal sheet for provisioning a clinic patient account and
/// generating a single-use scannable invite QR + 6-digit temporary PIN.
class CreatePatientAccountSheet extends ConsumerStatefulWidget {
  const CreatePatientAccountSheet({super.key, this.initialHandover});

  final ClinicProvisionResult? initialHandover;

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CreatePatientAccountSheet(),
    );
  }

  static Future<void> showAccessHandover(
    BuildContext context, {
    required ClinicProvisionResult result,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreatePatientAccountSheet(initialHandover: result),
    );
  }

  @override
  ConsumerState<CreatePatientAccountSheet> createState() =>
      _CreatePatientAccountSheetState();
}

class _CreatePatientAccountSheetState
    extends ConsumerState<CreatePatientAccountSheet> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _identifierCtrl = TextEditingController();

  String _ageRange = '25-44';
  String _preferredLang = 'ar';
  final Set<String> _selectedTracks = <String>{
    ClinicalTrack.sleepWake.id,
    ClinicalTrack.anxietyPanic.id,
  };

  bool _isSubmitting = false;
  String? _errorMsg;
  ClinicProvisionResult? _handoverResult;

  static const _ageOptions = <(String id, String label)>[
    ('under_18', '< 18'),
    ('18-24', '18–24'),
    ('25-44', '25–44'),
    ('45-64', '45–64'),
    ('65+', '65+'),
  ];

  static const _langOptions = <(String code, String label)>[
    ('ar', 'العربية'),
    ('fr', 'Français'),
    ('en', 'English'),
  ];

  static const _quickTracks = <ClinicalTrack>[
    ClinicalTrack.sleepWake,
    ClinicalTrack.anxietyPanic,
    ClinicalTrack.depressiveSpectrum,
    ClinicalTrack.bipolarCycling,
    ClinicalTrack.traumaStress,
    ClinicalTrack.emotionRegulation,
  ];

  @override
  void initState() {
    super.initState();
    _handoverResult = widget.initialHandover;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _identifierCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitProvision(AppStrings strings) async {
    final name = _nameCtrl.text.trim();
    final identifier = _identifierCtrl.text.trim();
    if (name.isEmpty || identifier.isEmpty) {
      setState(() => _errorMsg = strings.fillRequiredFieldsError);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMsg = null;
    });

    try {
      final profile = await ref.read(clinicianProfileProvider.future);
      final result = await ref
          .read(clinicAuthRepositoryProvider)
          .createPatientAccount(
            doctorId: profile.doctorId,
            clinicId: profile.effectiveClinicCode,
            doctorName: profile.displayName,
            clinicName: profile.clinicName,
            displayName: name,
            loginIdentifier: identifier,
            ageRange: _ageRange,
            preferredLanguage: _preferredLang,
            assignedTrackIds: _selectedTracks.toList(growable: false),
          );

      ref.invalidate(clinicianRosterProvider);
      if (mounted) {
        HapticFeedback.mediumImpact();
        setState(() {
          _handoverResult = result;
          _isSubmitting = false;
        });
      }
    } on ClinicAuthException catch (e) {
      if (mounted) {
        final strings = ref.read(appStringsProvider);
        setState(() {
          _errorMsg = strings.localizedClinicAuthError(e.code);
          _isSubmitting = false;
        });
      }
    } catch (_) {
      if (mounted) {
        final strings = ref.read(appStringsProvider);
        setState(() {
          _errorMsg = strings.genericActionError;
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _exportWelcomeCardPdf(
    ClinicProvisionResult result,
    AppStrings strings,
  ) async {
    try {
      const pdfService = PatientWelcomeCardPdfService();
      final bytes = await pdfService.generateWelcomeCardPdf(provision: result);
      final slug = DocumentExporter.sanitizeFileName(
        result.account.displayName,
      );
      final fileName = 'mindora_welcome_$slug.pdf';
      final exported = await ref.read(documentExporterProvider).savePdf(
            bytes: bytes,
            fileName: fileName,
          );
      if (!mounted || exported.isCancelled) return;
      HapticFeedback.mediumImpact();
      showMindToast(
        context,
        strings.pdfSavedSnackbar(exported.fileName),
        variant: MindToastVariant.success,
      );
    } catch (_) {
      if (!mounted) return;
      showMindToast(
        context,
        strings.pdfExportFailedError,
        variant: MindToastVariant.error,
      );
    }
  }

  Future<void> _copyCredentials(
    ClinicProvisionResult result,
    AppStrings strings,
  ) async {
    final text = strings.credentialsCopyText(
      patientName: result.account.displayName,
      loginId: result.account.loginIdentifier,
      pin: result.temporaryPin,
      doctorName: result.account.doctorName,
    );
    await Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    if (mounted) {
      showMindToast(context, strings.accessCopiedToast);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final strings = ref.watch(appStringsProvider);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final handover = _handoverResult;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.92,
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
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
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
                padding: const EdgeInsetsDirectional.fromSTEB(20, 14, 12, 8),
                child: Row(
                  children: [
                    Icon(
                      handover != null
                          ? Icons.qr_code_2_rounded
                          : Icons.person_add_alt_1_outlined,
                      size: 22,
                      color: tokens.accentInk,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            handover != null
                                ? strings.patientAccessReadyTitle
                                : strings.createPatientTitle,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: tokens.ink,
                            ),
                          ),
                          if (handover == null) ...[
                            const SizedBox(height: 2),
                            Text(
                              strings.createPatientSubtitle,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: tokens.ink2,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: strings.closeBtn,
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      icon: Icon(Icons.close_rounded, color: tokens.ink2),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: tokens.line),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
                  child: handover != null
                      ? _buildHandoverView(handover, tokens, strings)
                      : _buildFormView(tokens, strings),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormView(MindTokens tokens, AppStrings strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const ValueKey('admin-create-name-field'),
          controller: _nameCtrl,
          textCapitalization: TextCapitalization.words,
          style: TextStyle(fontSize: 15, color: tokens.ink),
          decoration: _fieldDecoration(tokens, strings.patientFullNameLabel),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey('admin-create-identifier-field'),
          controller: _identifierCtrl,
          style: TextStyle(fontSize: 15, color: tokens.ink),
          decoration: _fieldDecoration(tokens, strings.patientIdentifierLabel),
        ),
        const SizedBox(height: 16),
        Text(
          strings.patientAgeGroupLabel,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: tokens.ink2,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _ageOptions.map((item) {
            final selected = _ageRange == item.$1;
            return _optionChip(
              tokens: tokens,
              label: item.$2,
              selected: selected,
              onTap: () => setState(() => _ageRange = item.$1),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Text(
          strings.patientLanguageLabel,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: tokens.ink2,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _langOptions.map((item) {
            final selected = _preferredLang == item.$1;
            return _optionChip(
              tokens: tokens,
              label: item.$2,
              selected: selected,
              onTap: () => setState(() => _preferredLang = item.$1),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Text(
          strings.patientCareTracksLabel,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: tokens.ink2,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _quickTracks.map((track) {
            final selected = _selectedTracks.contains(track.id);
            return _optionChip(
              tokens: tokens,
              label: track.localizedTitle(strings),
              selected: selected,
              onTap: () => setState(() {
                if (selected) {
                  _selectedTracks.remove(track.id);
                } else {
                  _selectedTracks.add(track.id);
                }
              }),
            );
          }).toList(),
        ),
        if (_errorMsg != null) ...[
          const SizedBox(height: 12),
          Text(
            _errorMsg!,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: tokens.safety,
            ),
          ),
        ],
        const SizedBox(height: 20),
        MindButton(
          key: const ValueKey('admin-create-submit-btn'),
          text: strings.generatePatientAccessBtn,
          leadingIcon: Icons.qr_code_2_rounded,
          isFullWidth: true,
          isLoading: _isSubmitting,
          onPressed: () => _submitProvision(strings),
        ),
      ],
    );
  }

  Widget _buildHandoverView(
    ClinicProvisionResult result,
    MindTokens tokens,
    AppStrings strings,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MindBadge(
          label:
              '${result.account.displayName} · ${result.account.loginIdentifier}',
          icon: Icons.verified_user_outlined,
          backgroundColor: tokens.primarySoft,
          textColor: tokens.ink,
        ),
        const SizedBox(height: 16),
        MindQrCodeView(
          data: result.qrPayload,
          size: 190,
          semanticLabel: strings.patientAccessReadyTitle,
          overflowNotice: strings.qrCapacityExceededNote,
        ),
        const SizedBox(height: 10),
        Text(
          strings.patientQrExpireNote,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: tokens.ink2, height: 1.35),
        ),
        const SizedBox(height: 16),
        MindCard(
          variant: MindCardVariant.tint,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                strings.patientTempPinLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: tokens.ink2,
                ),
              ),
              const SizedBox(height: 6),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  result.temporaryPin,
                  key: const ValueKey('admin-handover-pin-text'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4,
                    color: tokens.ink,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  result.account.loginIdentifier,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: tokens.ink2,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        MindButton(
          key: const ValueKey<String>('admin-print-welcome-card-btn'),
          text: strings.printWelcomeCardBtn,
          variant: MindButtonVariant.secondary,
          leadingIcon: Icons.picture_as_pdf_outlined,
          isFullWidth: true,
          onPressed: () => _exportWelcomeCardPdf(result, strings),
        ),
        const SizedBox(height: 10),
        MindButton(
          text: strings.copyPinAndIdBtn,
          variant: MindButtonVariant.soft,
          leadingIcon: Icons.copy_rounded,
          isFullWidth: true,
          onPressed: () => _copyCredentials(result, strings),
        ),
        const SizedBox(height: 10),
        MindButton(
          text: strings.doneBtn,
          isFullWidth: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _optionChip({
    required MindTokens tokens,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return MindPressable(
      semanticLabel: label,
      selected: selected,
      onPressed: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(tokens.chipRadius),
      child: Container(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? tokens.cardTint : tokens.surface2,
          borderRadius: BorderRadius.circular(tokens.chipRadius),
          border: Border.all(
            color: selected ? tokens.primary : tokens.line,
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              Icon(Icons.check_rounded, size: 15, color: tokens.ink),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? tokens.ink : tokens.ink2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(MindTokens tokens, String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(fontSize: 14, color: tokens.ink2),
      filled: true,
      fillColor: tokens.surface2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
    );
  }
}
