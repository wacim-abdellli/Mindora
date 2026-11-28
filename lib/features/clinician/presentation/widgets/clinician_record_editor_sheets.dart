import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/localization/mind_formatters.dart';
import '../../../../app/theme/mind_tokens.dart';
import '../../../../core/widgets/mind_badge.dart';
import '../../../../core/widgets/mind_banner.dart';
import '../../../../core/widgets/mind_button.dart';
import '../../../../core/widgets/mind_card.dart';
import '../../../../core/widgets/mind_empty_state.dart';
import '../../../../core/widgets/mind_pill.dart';
import '../../../../core/widgets/mind_skeleton.dart';
import '../../../../core/widgets/mind_switch.dart';
import '../../../../core/widgets/mind_toast.dart';
import '../../../profile/domain/clinical_condition_catalog.dart';
import '../../../profile/presentation/widgets/clinical_condition_search_sheet.dart';
import '../../controllers/clinician_providers.dart';
import '../../domain/clinician_models.dart';

/// Shared responsive modal shell for clinician clinical-record editors.
Widget _buildEditorShell(
  BuildContext context, {
  required MindTokens tokens,
  required String title,
  required Widget child,
  Widget? headerTrailing,
}) {
  final screenSize = MediaQuery.sizeOf(context);
  final isWide = screenSize.width >= 840;
  final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

  final sheet = Container(
    constraints: BoxConstraints(
      maxHeight: screenSize.height * 0.90,
      maxWidth: isWide ? 560 : double.infinity,
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
                  color: tokens.lineStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 14, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: tokens.ink,
                      ),
                    ),
                  ),
                  ?headerTrailing,
                  IconButton(
                    tooltip:
                        MaterialLocalizations.of(context).closeButtonTooltip,
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
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                child: child,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  return isWide ? Center(heightFactor: 1.0, child: sheet) : sheet;
}

InputDecoration _editorFieldDecoration(
  MindTokens tokens, {
  required String label,
  String? hint,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    labelStyle: TextStyle(fontSize: 13.5, color: tokens.ink2),
    hintStyle: TextStyle(fontSize: 13, color: tokens.ink3),
    filled: true,
    fillColor: tokens.surface2,
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
      borderSide: BorderSide(color: tokens.ink, width: 1.4),
    ),
  );
}

// =============================================================================
// 1. CLINICIAN DIAGNOSIS EDITOR SHEET
// =============================================================================

class ClinicianDiagnosisSheet extends ConsumerStatefulWidget {
  const ClinicianDiagnosisSheet({
    super.key,
    required this.patientId,
    required this.currentRecord,
    this.existing,
  });

  final String patientId;
  final ClinicianClinicalRecord currentRecord;
  final ClinicianDiagnosisEntry? existing;

  static Future<void> show(
    BuildContext context, {
    required String patientId,
    required ClinicianClinicalRecord currentRecord,
    ClinicianDiagnosisEntry? existing,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ClinicianDiagnosisSheet(
        patientId: patientId,
        currentRecord: currentRecord,
        existing: existing,
      ),
    );
  }

  @override
  ConsumerState<ClinicianDiagnosisSheet> createState() =>
      _ClinicianDiagnosisSheetState();
}

class _ClinicianDiagnosisSheetState
    extends ConsumerState<ClinicianDiagnosisSheet> {
  late final TextEditingController _labelCtrl;
  late final TextEditingController _codeCtrl;
  late final TextEditingController _notesCtrl;
  late DiagnosisCertainty _certainty;
  late DiagnosisStatus _status;
  String _labelQuery = '';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _labelCtrl = TextEditingController(text: widget.existing?.label ?? '');
    _codeCtrl = TextEditingController(text: widget.existing?.code ?? '');
    _notesCtrl =
        TextEditingController(text: widget.existing?.clinicalNotes ?? '');
    _certainty = widget.existing?.certainty ?? DiagnosisCertainty.working;
    _status = widget.existing?.status ?? DiagnosisStatus.active;
    _labelQuery = widget.existing?.label ?? '';
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _codeCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save(AppStrings strings) async {
    final label = _labelCtrl.text.trim();
    if (label.isEmpty || _isSaving) return;
    setState(() => _isSaving = true);
    final navigator = Navigator.of(context);
    try {
      final doctorName =
          ref.read(clinicianProfileProvider).value?.displayName ?? '';
      final now = DateTime.now();
      final entry = ClinicianDiagnosisEntry(
        id: widget.existing?.id ?? 'dx_${now.millisecondsSinceEpoch}',
        code: _codeCtrl.text.trim(),
        label: label,
        certainty: _certainty,
        status: _status,
        documentedAt: widget.existing?.documentedAt ?? now,
        documentedByDoctorName:
            widget.existing?.documentedByDoctorName.isNotEmpty == true
                ? widget.existing!.documentedByDoctorName
                : doctorName,
        clinicalNotes: _notesCtrl.text.trim(),
      );

      final updatedList = widget.existing == null
          ? [entry, ...widget.currentRecord.diagnoses]
          : widget.currentRecord.diagnoses
              .map((d) => d.id == entry.id ? entry : d)
              .toList(growable: false);

      await ref.read(clinicianRosterProvider.notifier).updateClinicalRecord(
            widget.patientId,
            widget.currentRecord.copyWith(diagnoses: updatedList),
          );
      HapticFeedback.mediumImpact();
      if (mounted) navigator.pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _delete() async {
    final target = widget.existing;
    if (target == null || _isSaving) return;
    setState(() => _isSaving = true);
    final navigator = Navigator.of(context);
    try {
      final updatedList = widget.currentRecord.diagnoses
          .where((d) => d.id != target.id)
          .toList(growable: false);
      await ref.read(clinicianRosterProvider.notifier).updateClinicalRecord(
            widget.patientId,
            widget.currentRecord.copyWith(diagnoses: updatedList),
          );
      if (mounted) navigator.pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final strings = ref.watch(appStringsProvider);

    return _buildEditorShell(
      context,
      tokens: tokens,
      title: widget.existing == null
          ? strings.addDiagnosisBtn
          : strings.editDiagnosisTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MindBanner(
            body: strings.clinicianDocumentedBadge,
            tone: MindBannerTone.info,
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 2,
            children: [
              Text(
                strings.quickConditionSuggestionsLabel,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: tokens.ink2,
                ),
              ),
              TextButton.icon(
                key: const ValueKey<String>('dx-browse-catalog-btn'),
                onPressed: () async {
                  final picked = await ClinicalConditionSearchSheet.show(
                    context,
                    initialConditionIds: const [],
                    initialTrackIds: const [],
                  );
                  if (picked == null ||
                      picked.selectedConditionIds.isEmpty ||
                      !mounted) {
                    return;
                  }
                  final item = ClinicalConditionCatalog.byId(
                    picked.selectedConditionIds.first,
                  );
                  if (item == null) return;
                  setState(() {
                    _labelCtrl.text = item.localized(strings);
                    _labelQuery = '';
                  });
                },
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
            key: const ValueKey<String>('dx-label-field'),
            controller: _labelCtrl,
            onChanged: (v) => setState(() => _labelQuery = v.trim()),
            style: TextStyle(fontSize: 14, color: tokens.ink),
            decoration: _editorFieldDecoration(
              tokens,
              label: strings.diagnosisLabelField,
              hint: strings.patientConditionInputHint,
            ),
          ),
          if (_labelQuery.length >= 2) ...[
            Builder(
              builder: (context) {
                final suggestions = ClinicalConditionCatalog.search(_labelQuery)
                    .where(
                      (item) =>
                          item.localized(strings).toLowerCase() !=
                          _labelQuery.toLowerCase(),
                    )
                    .take(4)
                    .toList(growable: false);
                if (suggestions.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final item in suggestions)
                        MindPill(
                          label: item.localized(strings),
                          isSelected: false,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _labelCtrl.text = item.localized(strings);
                              _labelQuery = '';
                            });
                          },
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
          const SizedBox(height: 10),
          Directionality(
            textDirection: TextDirection.ltr,
            child: TextField(
              key: const ValueKey<String>('dx-code-field'),
              controller: _codeCtrl,
              style: TextStyle(fontSize: 14, color: tokens.ink),
              decoration: _editorFieldDecoration(
                tokens,
                label: strings.diagnosisCodeField,
                hint: '6A60 / F31',
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            strings.diagnosisCertaintyLabel,
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
            children: DiagnosisCertainty.values.map((c) {
              return MindPill(
                key: ValueKey<String>('dx-certainty-${c.name}'),
                label: c.localizedLabel(strings),
                isSelected: _certainty == c,
                onTap: () => setState(() => _certainty = c),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Text(
            strings.diagnosisStatusLabel,
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
            children: DiagnosisStatus.values.map((s) {
              return MindPill(
                key: ValueKey<String>('dx-status-${s.name}'),
                label: s.localizedLabel(strings),
                isSelected: _status == s,
                onTap: () => setState(() => _status = s),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey<String>('dx-notes-field'),
            controller: _notesCtrl,
            maxLines: 3,
            style: TextStyle(fontSize: 13.5, color: tokens.ink),
            decoration: _editorFieldDecoration(
              tokens,
              label: strings.clinicalNotesOptionalField,
            ),
          ),
          const SizedBox(height: 16),
          MindButton(
            key: const ValueKey<String>('dx-save-btn'),
            text: strings.saveChangesBtn,
            isFullWidth: true,
            isLoading: _isSaving,
            onPressed: () => _save(strings),
          ),
          if (widget.existing != null) ...[
            const SizedBox(height: 10),
            MindButton(
              key: const ValueKey<String>('dx-delete-btn'),
              text: strings.deleteEntryBtn,
              variant: MindButtonVariant.soft,
              isFullWidth: true,
              onPressed: _delete,
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// 2. CLINICIAN MEDICATION EDITOR SHEET
// =============================================================================

class ClinicianMedicationSheet extends ConsumerStatefulWidget {
  const ClinicianMedicationSheet({
    super.key,
    required this.patientId,
    required this.currentRecord,
    this.existing,
  });

  final String patientId;
  final ClinicianClinicalRecord currentRecord;
  final ClinicianMedicationEntry? existing;

  static Future<void> show(
    BuildContext context, {
    required String patientId,
    required ClinicianClinicalRecord currentRecord,
    ClinicianMedicationEntry? existing,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ClinicianMedicationSheet(
        patientId: patientId,
        currentRecord: currentRecord,
        existing: existing,
      ),
    );
  }

  @override
  ConsumerState<ClinicianMedicationSheet> createState() =>
      _ClinicianMedicationSheetState();
}

class _ClinicianMedicationSheetState
    extends ConsumerState<ClinicianMedicationSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _dosageCtrl;
  late final TextEditingController _freqCtrl;
  late final TextEditingController _noteCtrl;
  late MedicationStatus _status;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _dosageCtrl = TextEditingController(text: widget.existing?.dosage ?? '');
    _freqCtrl = TextEditingController(text: widget.existing?.frequency ?? '');
    _noteCtrl =
        TextEditingController(text: widget.existing?.prescriberNote ?? '');
    _status = widget.existing?.status ?? MedicationStatus.active;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dosageCtrl.dispose();
    _freqCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || _isSaving) return;
    setState(() => _isSaving = true);
    final navigator = Navigator.of(context);
    try {
      final now = DateTime.now();
      final entry = ClinicianMedicationEntry(
        id: widget.existing?.id ?? 'med_${now.millisecondsSinceEpoch}',
        name: name,
        dosage: _dosageCtrl.text.trim(),
        frequency: _freqCtrl.text.trim(),
        startedAt: widget.existing?.startedAt ?? now,
        status: _status,
        prescriberNote: _noteCtrl.text.trim(),
      );
      final updatedList = widget.existing == null
          ? [entry, ...widget.currentRecord.medications]
          : widget.currentRecord.medications
              .map((m) => m.id == entry.id ? entry : m)
              .toList(growable: false);

      await ref.read(clinicianRosterProvider.notifier).updateClinicalRecord(
            widget.patientId,
            widget.currentRecord.copyWith(medications: updatedList),
          );
      HapticFeedback.mediumImpact();
      if (mounted) navigator.pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _delete() async {
    final target = widget.existing;
    if (target == null || _isSaving) return;
    setState(() => _isSaving = true);
    final navigator = Navigator.of(context);
    try {
      final updatedList = widget.currentRecord.medications
          .where((m) => m.id != target.id)
          .toList(growable: false);
      await ref.read(clinicianRosterProvider.notifier).updateClinicalRecord(
            widget.patientId,
            widget.currentRecord.copyWith(medications: updatedList),
          );
      if (mounted) navigator.pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final strings = ref.watch(appStringsProvider);

    return _buildEditorShell(
      context,
      tokens: tokens,
      title: widget.existing == null
          ? strings.addMedicationBtn
          : strings.editMedicationTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const ValueKey<String>('med-name-field'),
            controller: _nameCtrl,
            style: TextStyle(fontSize: 14, color: tokens.ink),
            decoration: _editorFieldDecoration(
              tokens,
              label: strings.medicationNameField,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const ValueKey<String>('med-dosage-field'),
                  controller: _dosageCtrl,
                  style: TextStyle(fontSize: 14, color: tokens.ink),
                  decoration: _editorFieldDecoration(
                    tokens,
                    label: strings.medicationDosageField,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  key: const ValueKey<String>('med-freq-field'),
                  controller: _freqCtrl,
                  style: TextStyle(fontSize: 14, color: tokens.ink),
                  decoration: _editorFieldDecoration(
                    tokens,
                    label: strings.medicationFrequencyField,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            strings.diagnosisStatusLabel,
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
            children: MedicationStatus.values.map((s) {
              return MindPill(
                label: s.localizedLabel(strings),
                isSelected: _status == s,
                onTap: () => setState(() => _status = s),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteCtrl,
            maxLines: 2,
            style: TextStyle(fontSize: 13.5, color: tokens.ink),
            decoration: _editorFieldDecoration(
              tokens,
              label: strings.clinicalNotesOptionalField,
            ),
          ),
          const SizedBox(height: 16),
          MindButton(
            key: const ValueKey<String>('med-save-btn'),
            text: strings.saveChangesBtn,
            isFullWidth: true,
            isLoading: _isSaving,
            onPressed: _save,
          ),
          if (widget.existing != null) ...[
            const SizedBox(height: 10),
            MindButton(
              text: strings.deleteEntryBtn,
              variant: MindButtonVariant.soft,
              isFullWidth: true,
              onPressed: _delete,
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// 3. CLINICIAN ALLERGY EDITOR SHEET
// =============================================================================

class ClinicianAllergySheet extends ConsumerStatefulWidget {
  const ClinicianAllergySheet({
    super.key,
    required this.patientId,
    required this.currentRecord,
    this.existing,
  });

  final String patientId;
  final ClinicianClinicalRecord currentRecord;
  final ClinicianAllergyEntry? existing;

  static Future<void> show(
    BuildContext context, {
    required String patientId,
    required ClinicianClinicalRecord currentRecord,
    ClinicianAllergyEntry? existing,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ClinicianAllergySheet(
        patientId: patientId,
        currentRecord: currentRecord,
        existing: existing,
      ),
    );
  }

  @override
  ConsumerState<ClinicianAllergySheet> createState() =>
      _ClinicianAllergySheetState();
}

class _ClinicianAllergySheetState extends ConsumerState<ClinicianAllergySheet> {
  late final TextEditingController _substanceCtrl;
  late final TextEditingController _reactionCtrl;
  late AllergySeverity _severity;
  late bool _noKnownAllergies;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _substanceCtrl =
        TextEditingController(text: widget.existing?.substance ?? '');
    _reactionCtrl =
        TextEditingController(text: widget.existing?.reaction ?? '');
    _severity = widget.existing?.severity ?? AllergySeverity.moderate;
    _noKnownAllergies = widget.currentRecord.noKnownAllergies;
  }

  @override
  void dispose() {
    _substanceCtrl.dispose();
    _reactionCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final substance = _substanceCtrl.text.trim();
    if (substance.isEmpty && !_noKnownAllergies) return;
    setState(() => _isSaving = true);
    final navigator = Navigator.of(context);
    try {
      ClinicianClinicalRecord updated;
      if (substance.isEmpty && _noKnownAllergies) {
        updated = widget.currentRecord.copyWith(noKnownAllergies: true);
      } else {
        final now = DateTime.now();
        final entry = ClinicianAllergyEntry(
          id: widget.existing?.id ?? 'alg_${now.millisecondsSinceEpoch}',
          substance: substance,
          reaction: _reactionCtrl.text.trim(),
          severity: _severity,
        );
        final nextList = widget.existing == null
            ? [entry, ...widget.currentRecord.allergies]
            : widget.currentRecord.allergies
                .map((a) => a.id == entry.id ? entry : a)
                .toList(growable: false);
        updated = widget.currentRecord.copyWith(
          allergies: nextList,
          noKnownAllergies: false,
        );
      }
      await ref
          .read(clinicianRosterProvider.notifier)
          .updateClinicalRecord(widget.patientId, updated);
      HapticFeedback.mediumImpact();
      if (mounted) navigator.pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _delete() async {
    final target = widget.existing;
    if (target == null || _isSaving) return;
    setState(() => _isSaving = true);
    final navigator = Navigator.of(context);
    try {
      final nextList = widget.currentRecord.allergies
          .where((a) => a.id != target.id)
          .toList(growable: false);
      await ref.read(clinicianRosterProvider.notifier).updateClinicalRecord(
            widget.patientId,
            widget.currentRecord.copyWith(allergies: nextList),
          );
      if (mounted) navigator.pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final strings = ref.watch(appStringsProvider);

    return _buildEditorShell(
      context,
      tokens: tokens,
      title: strings.addAllergyBtn,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.existing == null &&
              widget.currentRecord.allergies.isEmpty) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    strings.noKnownAllergiesLabel,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: tokens.ink,
                    ),
                  ),
                ),
                MindSwitch(
                  value: _noKnownAllergies,
                  semanticLabel: strings.noKnownAllergiesLabel,
                  onChanged: (v) => setState(() => _noKnownAllergies = v),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            key: const ValueKey<String>('allergy-substance-field'),
            controller: _substanceCtrl,
            style: TextStyle(fontSize: 14, color: tokens.ink),
            decoration: _editorFieldDecoration(
              tokens,
              label: strings.allergySubstanceField,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const ValueKey<String>('allergy-reaction-field'),
            controller: _reactionCtrl,
            style: TextStyle(fontSize: 14, color: tokens.ink),
            decoration: _editorFieldDecoration(
              tokens,
              label: strings.allergyReactionField,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            strings.allergySeverityLabel,
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
            children: AllergySeverity.values.map((s) {
              return MindPill(
                label: s.localizedLabel(strings),
                isSelected: _severity == s,
                onTap: () => setState(() => _severity = s),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          MindButton(
            key: const ValueKey<String>('allergy-save-btn'),
            text: strings.saveChangesBtn,
            isFullWidth: true,
            isLoading: _isSaving,
            onPressed: _save,
          ),
          if (widget.existing != null) ...[
            const SizedBox(height: 10),
            MindButton(
              text: strings.deleteEntryBtn,
              variant: MindButtonVariant.soft,
              isFullWidth: true,
              onPressed: _delete,
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// 4. CLINICAL HISTORY, DEMOGRAPHICS & NEXT APPOINTMENT SHEET
// =============================================================================

class ClinicianHistoryDemographicsSheet extends ConsumerStatefulWidget {
  const ClinicianHistoryDemographicsSheet({
    super.key,
    required this.patientId,
    required this.currentRecord,
  });

  final String patientId;
  final ClinicianClinicalRecord currentRecord;

  static Future<void> show(
    BuildContext context, {
    required String patientId,
    required ClinicianClinicalRecord currentRecord,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ClinicianHistoryDemographicsSheet(
        patientId: patientId,
        currentRecord: currentRecord,
      ),
    );
  }

  @override
  ConsumerState<ClinicianHistoryDemographicsSheet> createState() =>
      _ClinicianHistoryDemographicsSheetState();
}

class _ClinicianHistoryDemographicsSheetState
    extends ConsumerState<ClinicianHistoryDemographicsSheet> {
  late final TextEditingController _fileNumberCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _sexCtrl;
  late final TextEditingController _referralCtrl;
  late final TextEditingController _emergNameCtrl;
  late final TextEditingController _emergPhoneCtrl;
  late final TextEditingController _psychHistoryCtrl;
  late final TextEditingController _medHistoryCtrl;
  late final TextEditingController _familyHistoryCtrl;
  late final TextEditingController _safetyNoteCtrl;
  DateTime? _nextAppointment;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final r = widget.currentRecord;
    _fileNumberCtrl = TextEditingController(text: r.clinicFileNumber);
    _phoneCtrl = TextEditingController(text: r.phone);
    _sexCtrl = TextEditingController(text: r.biologicalSex);
    _referralCtrl = TextEditingController(text: r.referralSource);
    _emergNameCtrl = TextEditingController(text: r.emergencyContactName);
    _emergPhoneCtrl = TextEditingController(text: r.emergencyContactPhone);
    _psychHistoryCtrl = TextEditingController(text: r.psychiatricHistory);
    _medHistoryCtrl = TextEditingController(text: r.medicalHistory);
    _familyHistoryCtrl = TextEditingController(text: r.familyHistory);
    _safetyNoteCtrl = TextEditingController(text: r.safetyObservationNote);
    _nextAppointment = r.nextAppointmentAt;
  }

  @override
  void dispose() {
    _fileNumberCtrl.dispose();
    _phoneCtrl.dispose();
    _sexCtrl.dispose();
    _referralCtrl.dispose();
    _emergNameCtrl.dispose();
    _emergPhoneCtrl.dispose();
    _psychHistoryCtrl.dispose();
    _medHistoryCtrl.dispose();
    _familyHistoryCtrl.dispose();
    _safetyNoteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save(AppStrings strings) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    final navigator = Navigator.of(context);
    try {
      final updated = widget.currentRecord.copyWith(
        clinicFileNumber: _fileNumberCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        biologicalSex: _sexCtrl.text.trim(),
        referralSource: _referralCtrl.text.trim(),
        emergencyContactName: _emergNameCtrl.text.trim(),
        emergencyContactPhone: _emergPhoneCtrl.text.trim(),
        psychiatricHistory: _psychHistoryCtrl.text.trim(),
        medicalHistory: _medHistoryCtrl.text.trim(),
        familyHistory: _familyHistoryCtrl.text.trim(),
        safetyObservationNote: _safetyNoteCtrl.text.trim(),
        nextAppointmentAt: _nextAppointment,
        clearNextAppointmentAt: _nextAppointment == null,
      );
      await ref
          .read(clinicianRosterProvider.notifier)
          .updateClinicalRecord(widget.patientId, updated);
      HapticFeedback.mediumImpact();
      if (mounted) {
        final rootCtx = navigator.context;
        navigator.pop();
        if (rootCtx.mounted) {
          showMindToast(
            rootCtx,
            strings.saveChangesBtn,
            variant: MindToastVariant.success,
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final strings = ref.watch(appStringsProvider);
    final now = DateTime.now();

    return _buildEditorShell(
      context,
      tokens: tokens,
      title: strings.clinicalHistoryAndDetailsTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Next follow-up quick picker
          Text(
            strings.nextAppointmentTitle,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: tokens.ink2,
            ),
          ),
          const SizedBox(height: 6),
          if (_nextAppointment != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: MindBadge(
                icon: Icons.event_outlined,
                label: MindFormatters.shortDate(_nextAppointment!, strings),
                backgroundColor: tokens.primarySoft,
                textColor: tokens.ink,
              ),
            ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final days in const [7, 14, 30])
                MindPill(
                  key: ValueKey<String>('appt-plus-${days}d'),
                  label: '+${MindFormatters.daysShort(days, strings)}',
                  isSelected: _nextAppointment != null &&
                      _nextAppointment!.difference(now).inDays.abs() == days,
                  onTap: () => setState(() {
                    _nextAppointment = DateTime(now.year, now.month, now.day)
                        .add(Duration(days: days));
                  }),
                ),
              if (_nextAppointment != null)
                MindPill(
                  label: strings.clearDateBtn,
                  isSelected: false,
                  onTap: () => setState(() => _nextAppointment = null),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: TextField(
                    key: const ValueKey<String>('chart-file-number-field'),
                    controller: _fileNumberCtrl,
                    style: TextStyle(fontSize: 14, color: tokens.ink),
                    decoration: _editorFieldDecoration(
                      tokens,
                      label: strings.clinicFileNumberField,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(fontSize: 14, color: tokens.ink),
                    decoration: _editorFieldDecoration(
                      tokens,
                      label: strings.patientPhoneField,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _sexCtrl,
                  style: TextStyle(fontSize: 14, color: tokens.ink),
                  decoration: _editorFieldDecoration(
                    tokens,
                    label: strings.biologicalSexField,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _referralCtrl,
                  style: TextStyle(fontSize: 14, color: tokens.ink),
                  decoration: _editorFieldDecoration(
                    tokens,
                    label: strings.referralSourceField,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _emergNameCtrl,
                  style: TextStyle(fontSize: 14, color: tokens.ink),
                  decoration: _editorFieldDecoration(
                    tokens,
                    label: strings.emergencyContactNameField,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: TextField(
                    controller: _emergPhoneCtrl,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(fontSize: 14, color: tokens.ink),
                    decoration: _editorFieldDecoration(
                      tokens,
                      label: strings.emergencyContactPhoneField,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey<String>('chart-psych-history-field'),
            controller: _psychHistoryCtrl,
            maxLines: 3,
            style: TextStyle(fontSize: 13.5, color: tokens.ink),
            decoration: _editorFieldDecoration(
              tokens,
              label: strings.psychiatricHistoryField,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _medHistoryCtrl,
            maxLines: 2,
            style: TextStyle(fontSize: 13.5, color: tokens.ink),
            decoration: _editorFieldDecoration(
              tokens,
              label: strings.medicalHistoryField,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _familyHistoryCtrl,
            maxLines: 2,
            style: TextStyle(fontSize: 13.5, color: tokens.ink),
            decoration: _editorFieldDecoration(
              tokens,
              label: strings.familyHistoryField,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _safetyNoteCtrl,
            maxLines: 2,
            style: TextStyle(fontSize: 13.5, color: tokens.ink),
            decoration: _editorFieldDecoration(
              tokens,
              label: strings.safetyProtectiveFactorsField,
            ),
          ),
          const SizedBox(height: 16),
          MindButton(
            key: const ValueKey<String>('chart-details-save-btn'),
            text: strings.saveChangesBtn,
            isFullWidth: true,
            isLoading: _isSaving,
            onPressed: () => _save(strings),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 5. CLINIC ACTIVITY & ACCESS AUDIT LOG SHEET
// =============================================================================

class ClinicAuditLogSheet extends ConsumerWidget {
  const ClinicAuditLogSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ClinicAuditLogSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final strings = ref.watch(appStringsProvider);
    final logAsync = ref.watch(clinicAuditLogProvider);
    final accounts = ref.watch(clinicDoctorAccountsProvider).value ?? const {};

    return _buildEditorShell(
      context,
      tokens: tokens,
      title: strings.clinicAuditLogTitle,
      child: logAsync.when(
        loading: () => const Column(
          children: [
            MindSkeleton.card(height: 64),
            SizedBox(height: 10),
            MindSkeleton.card(height: 64),
          ],
        ),
        error: (_, _) => MindEmptyState(
          icon: Icons.history_rounded,
          title: strings.clinicAuditLogEmpty,
          subtitle: strings.clinicAuditLogSub,
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return MindEmptyState(
              icon: Icons.history_rounded,
              title: strings.clinicAuditLogEmpty,
              subtitle: strings.clinicAuditLogSub,
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: entries.take(50).map((entry) {
              final patientName =
                  accounts[entry.patientId]?.displayName ?? entry.patientId;
              final ts =
                  '${MindFormatters.shortDate(entry.timestamp, strings)} · '
                  '${entry.timestamp.hour.toString().padLeft(2, '0')}:'
                  '${entry.timestamp.minute.toString().padLeft(2, '0')}';
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: MindCard(
                  variant: MindCardVariant.flat,
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        size: 16,
                        color: tokens.ink2,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.localizedAuditAction(entry.action.name),
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: tokens.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$patientName · $ts',
                              style: TextStyle(
                                fontSize: 12,
                                color: tokens.ink2,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
