import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/config/app_edition.dart';
import '../../../../app/localization/app_strings.dart';
import '../../../../app/router/app_router.dart';
import '../../../../app/theme/mind_tokens.dart';
import '../../../../core/export/document_exporter.dart';
import '../../../../core/widgets/mind_badge.dart';
import '../../../../core/widgets/mind_button.dart';
import '../../../../core/widgets/mind_card.dart';
import '../../../../core/widgets/mind_pressable.dart';
import '../../../../core/widgets/mind_qr_code.dart';
import '../../../../core/widgets/mind_toast.dart';
import '../../../auth/controllers/auth_controller.dart';
import '../../../clinic_sync/controllers/clinic_sync_providers.dart';
import '../../../clinic_sync/domain/clinic_account_models.dart';
import '../../../profile/domain/clinical_condition_catalog.dart';
import '../../../profile/presentation/widgets/clinical_condition_search_sheet.dart';
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
  final TextEditingController _conditionCtrl = TextEditingController();

  String _ageRange = '25-44';
  String _preferredLang = 'ar';
  final Set<String> _selectedTracks = <String>{
    ClinicalTrack.sleepWake.id,
    ClinicalTrack.anxietyPanic.id,
  };
  final Set<String> _selectedConditionIds = <String>{};
  final List<String> _customConditions = <String>[];
  bool _showAllTracks = false;
  String _conditionQuery = '';

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
    _conditionCtrl.dispose();
    super.dispose();
  }

  void _selectCatalogCondition(ClinicalConditionItem item) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedConditionIds.add(item.id);
      _selectedTracks.add(item.track.id);
      _conditionCtrl.clear();
      _conditionQuery = '';
    });
  }

  void _addTypedCondition() {
    final text = _conditionCtrl.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.selectionClick();
    final exactCatalog = ClinicalConditionCatalog.all.where(
      (item) =>
          item.en.toLowerCase() == text.toLowerCase() ||
          item.fr.toLowerCase() == text.toLowerCase() ||
          item.ar.toLowerCase() == text.toLowerCase(),
    );
    setState(() {
      if (exactCatalog.isNotEmpty) {
        final match = exactCatalog.first;
        _selectedConditionIds.add(match.id);
        _selectedTracks.add(match.track.id);
      } else {
        final exists = _customConditions.any(
          (c) => c.toLowerCase() == text.toLowerCase(),
        );
        if (!exists) {
          _customConditions.add(text);
        }
      }
      _conditionCtrl.clear();
      _conditionQuery = '';
    });
  }

  Future<void> _openConditionCatalog() async {
    final res = await ClinicalConditionSearchSheet.show(
      context,
      initialConditionIds: _selectedConditionIds.toList(growable: false),
      initialTrackIds: _selectedTracks.toList(growable: false),
    );
    if (res == null || !mounted) return;
    setState(() {
      _selectedConditionIds
        ..clear()
        ..addAll(res.selectedConditionIds);
      _selectedTracks
        ..clear()
        ..addAll(res.selectedTrackIds);
      for (final cid in _selectedConditionIds) {
        final item = ClinicalConditionCatalog.byId(cid);
        if (item != null) {
          _selectedTracks.add(item.track.id);
        }
      }
    });
  }

  Future<void> _submitProvision(AppStrings strings) async {
    final name = _nameCtrl.text.trim();
    final identifier = _identifierCtrl.text.trim();
    if (name.isEmpty || identifier.isEmpty) {
      setState(() => _errorMsg = strings.fillRequiredFieldsError);
      return;
    }

    // Preserve any unsubmitted condition text the doctor left typed in the input.
    final pendingTypedCondition = _conditionCtrl.text.trim();
    if (pendingTypedCondition.isNotEmpty) {
      _addTypedCondition();
    }

    setState(() {
      _isSubmitting = true;
      _errorMsg = null;
    });

    try {
      final profile = await ref.read(clinicianProfileProvider.future);
      final clinicianLang = strings.isArabic
          ? 'ar'
          : (strings.isFrench ? 'fr' : 'en');
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
            clinicianLanguage: clinicianLang,
            assignedTrackIds: _selectedTracks.toList(growable: false),
            conditionIds: _selectedConditionIds.toList(growable: false),
            customConditions: List<String>.from(_customConditions),
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
    } catch (e, st) {
      debugPrint('CreatePatientAccountSheet._submitProvision failed: $e\n$st');
      if (mounted) {
        final strings = ref.read(appStringsProvider);
        setState(() {
          _errorMsg = kDebugMode
              ? '${strings.genericActionError} ($e)'
              : strings.genericActionError;
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

  Future<void> _copyQrPayload(
    ClinicProvisionResult result,
    AppStrings strings,
  ) async {
    await Clipboard.setData(ClipboardData(text: result.qrPayload));
    HapticFeedback.lightImpact();
    if (mounted) {
      showMindToast(context, strings.qrCodeCopiedToast);
    }
  }

  Future<void> _openPatientLoginForTesting(ClinicProvisionResult result) async {
    await Clipboard.setData(ClipboardData(text: result.qrPayload));
    await ref.read(authControllerProvider.notifier).signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('mf_clinician_demo_preview', true);
    if (!mounted) return;
    final router = GoRouter.maybeOf(context);
    Navigator.of(context).pop();
    router?.go(AppRouter.auth);
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
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 2,
          children: [
            Text(
              strings.patientClinicalConditionLabel,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: tokens.ink2,
              ),
            ),
            TextButton.icon(
              key: const ValueKey('admin-create-browse-conditions-btn'),
              onPressed: _openConditionCatalog,
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              icon: Icon(
                Icons.menu_book_outlined,
                size: 16,
                color: tokens.accentInk,
              ),
              label: Text(
                strings.browseAllConditionsBtn,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: tokens.accentInk,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          key: const ValueKey('admin-create-condition-input'),
          controller: _conditionCtrl,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.done,
          onChanged: (v) => setState(() => _conditionQuery = v.trim()),
          onSubmitted: (_) => _addTypedCondition(),
          style: TextStyle(fontSize: 14.5, color: tokens.ink),
          decoration: _fieldDecoration(
            tokens,
            null,
            hint: strings.patientConditionInputHint,
          ).copyWith(
            prefixIcon: Icon(
              Icons.search_rounded,
              size: 19,
              color: tokens.ink2,
            ),
            suffixIcon: _conditionQuery.isEmpty
                ? null
                : IconButton(
                    key: const ValueKey('admin-create-add-typed-condition-btn'),
                    tooltip: strings.addCustomConditionChip(_conditionQuery),
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    icon: Icon(
                      Icons.add_circle_outline_rounded,
                      size: 21,
                      color: tokens.accentInk,
                    ),
                    onPressed: _addTypedCondition,
                  ),
          ),
        ),
        if (_conditionQuery.isNotEmpty) ...[
          const SizedBox(height: 8),
          Builder(
            builder: (context) {
              final matches = ClinicalConditionCatalog.search(_conditionQuery)
                  .where((item) => !_selectedConditionIds.contains(item.id))
                  .take(6)
                  .toList(growable: false);
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in matches)
                    _optionChip(
                      key: ValueKey('admin-condition-suggestion-${item.id}'),
                      tokens: tokens,
                      label: item.localized(strings),
                      selected: false,
                      onTap: () => _selectCatalogCondition(item),
                    ),
                  _optionChip(
                    tokens: tokens,
                    label: strings.addCustomConditionChip(_conditionQuery),
                    selected: false,
                    onTap: _addTypedCondition,
                  ),
                ],
              );
            },
          ),
        ],
        if (_selectedConditionIds.isNotEmpty || _customConditions.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final cid in _selectedConditionIds)
                if (ClinicalConditionCatalog.byId(cid) case final item?)
                  _removableConditionChip(
                    tokens: tokens,
                    strings: strings,
                    label: item.localized(strings),
                    onRemove: () =>
                        setState(() => _selectedConditionIds.remove(cid)),
                  ),
              for (final custom in _customConditions)
                _removableConditionChip(
                  tokens: tokens,
                  strings: strings,
                  label: custom,
                  onRemove: () =>
                      setState(() => _customConditions.remove(custom)),
                ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 2,
          children: [
            Text(
              strings.patientCareTracksLabel,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: tokens.ink2,
              ),
            ),
            TextButton(
              key: const ValueKey('admin-create-toggle-all-tracks-btn'),
              onPressed: () =>
                  setState(() => _showAllTracks = !_showAllTracks),
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              child: Text(
                _showAllTracks
                    ? strings.showFewerFocusAreasBtn
                    : strings.showAllFocusAreasBtn,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: tokens.accentInk,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Builder(
          builder: (context) {
            final visibleTracks = _showAllTracks
                ? ClinicalTrack.values
                : <ClinicalTrack>{
                    ..._quickTracks,
                    ...ClinicalTrack.values.where(
                      (t) => _selectedTracks.contains(t.id),
                    ),
                  }.toList(growable: false);
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: visibleTracks.map((track) {
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
            );
          },
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
          key: const ValueKey<String>('admin-copy-qr-code-btn'),
          text: strings.copyQrCodeBtn,
          variant: MindButtonVariant.soft,
          leadingIcon: Icons.qr_code_rounded,
          isFullWidth: true,
          onPressed: () => _copyQrPayload(result, strings),
        ),
        if (kDebugMode && AppEditionConfig.isClinicianApp) ...[
          const SizedBox(height: 10),
          MindButton(
            key: const ValueKey<String>('admin-handover-test-patient-login-btn'),
            text: strings.testPatientLoginOnDeviceBtn,
            variant: MindButtonVariant.secondary,
            leadingIcon: Icons.login_rounded,
            isFullWidth: true,
            onPressed: () => _openPatientLoginForTesting(result),
          ),
        ],
        const SizedBox(height: 10),
        MindButton(
          text: strings.doneBtn,
          isFullWidth: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _removableConditionChip({
    required MindTokens tokens,
    required AppStrings strings,
    required String label,
    required VoidCallback onRemove,
  }) {
    return MindPressable(
      semanticLabel: '$label, ${strings.removeConditionTooltip}',
      onPressed: () {
        HapticFeedback.selectionClick();
        onRemove();
      },
      borderRadius: BorderRadius.circular(tokens.chipRadius),
      child: Container(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: tokens.infoSoft,
          borderRadius: BorderRadius.circular(tokens.chipRadius),
          border: Border.all(color: tokens.accentInk, width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: tokens.accentInk,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.close_rounded, size: 15, color: tokens.accentInk),
          ],
        ),
      ),
    );
  }

  Widget _optionChip({
    Key? key,
    required MindTokens tokens,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return MindPressable(
      key: key,
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

  InputDecoration _fieldDecoration(
    MindTokens tokens,
    String? label, {
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(fontSize: 14, color: tokens.ink2),
      hintStyle: TextStyle(fontSize: 13.5, color: tokens.ink3),
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
