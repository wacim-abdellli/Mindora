import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/router/app_router.dart';
import '../../../../app/theme/mind_tokens.dart';
import '../../../../core/widgets/mind_badge.dart';
import '../../../../core/widgets/mind_button.dart';
import '../../../../core/widgets/mind_card.dart';
import '../../../../core/widgets/mind_pill.dart';
import '../../../../core/widgets/mind_pressable.dart';
import '../../../../core/widgets/mind_qr_code.dart';
import '../../../../core/widgets/mind_switch.dart';
import '../../../auth/controllers/auth_controller.dart';
import '../../../case_file/data/clinical_export_log_service.dart';
import '../../../investigation/controllers/investigation_providers.dart';
import '../../../mind_trace/controllers/mind_trace_controller.dart';
import '../../../observatory/controllers/observatory_controllers.dart';
import '../../../profile/controllers/profile_controller.dart';
import '../../controllers/clinician_providers.dart';
import '../../domain/clinician_models.dart';
import 'clinical_brief_preview_sheet.dart';
import 'pre_visit_brief_sheet.dart';

/// Consent-scoped Care Handoff sheet on the Patient side.
///
/// Builds an encrypted `MF-CLINIC-V1:...` sync packet or delivers directly
/// into the on-device Psychiatrist Workspace while strictly excluding all
/// `isPrivate == true` investigation cases.
class ShareWithPsychiatristSheet extends ConsumerStatefulWidget {
  const ShareWithPsychiatristSheet({
    super.key,
    this.initialTopics = const [],
    this.initialQuestion = '',
    this.initialFocusFeedback = '',
  });

  final List<String> initialTopics;
  final String initialQuestion;
  final String initialFocusFeedback;

  static Future<void> show(
    BuildContext context, {
    List<String> initialTopics = const [],
    String initialQuestion = '',
    String initialFocusFeedback = '',
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ShareWithPsychiatristSheet(
        initialTopics: initialTopics,
        initialQuestion: initialQuestion,
        initialFocusFeedback: initialFocusFeedback,
      ),
    );
  }

  @override
  ConsumerState<ShareWithPsychiatristSheet> createState() =>
      _ShareWithPsychiatristSheetState();
}

class _ShareWithPsychiatristSheetState
    extends ConsumerState<ShareWithPsychiatristSheet> {
  ClinicalConsentScope _scope = const ClinicalConsentScope();
  late final Set<String> _selectedTopics;
  late final TextEditingController _questionController;
  final TextEditingController _helpedController = TextEditingController();
  final TextEditingController _passphraseController = TextEditingController();
  late String _focusPlanFeedback;

  bool _isGeneratingCode = false;
  bool _isDeliveringLocal = false;
  bool _showQr = false;
  String? _generatedCode;
  String? _errorText;

  Future<void> _openPrintableBrief() async {
    final packet = await _buildCurrentPacket();
    if (!mounted) return;
    final record = ClinicianPatientRecord(
      patientId: packet.patientAnonymousId,
      displayName: packet.patientDisplayName,
      isDemoCase: false,
      importedAt: packet.generatedAt,
      lastSyncedAt: packet.generatedAt,
      latestPacket: packet,
    );
    await ClinicalBriefPreviewSheet.show(
      context,
      record: record,
      encryptedCode: _generatedCode,
    );
  }

  @override
  void initState() {
    super.initState();
    _selectedTopics = Set<String>.from(widget.initialTopics);
    _questionController = TextEditingController(text: widget.initialQuestion);
    _focusPlanFeedback = widget.initialFocusFeedback;
  }

  @override
  void dispose() {
    _questionController.dispose();
    _helpedController.dispose();
    _passphraseController.dispose();
    super.dispose();
  }

  List<String> _topicOptions(AppStrings strings) => [
        strings.preVisitTopicSleep,
        strings.preVisitTopicEveningDips,
        strings.preVisitTopicWorkStrain,
        strings.preVisitTopicTreatmentQuestions,
        strings.preVisitTopicThoughtLoops,
        strings.preVisitTopicCopingReview,
      ];

  Future<ClinicianSyncPacket> _buildCurrentPacket() async {
    final auth = ref.read(authControllerProvider).user;
    final profile = ref.read(profileControllerProvider).value;
    final traces =
        ref.read(mindTraceControllerProvider).value ?? const [];
    final cases = await ref.read(savedCasesProvider.future);
    final symptoms =
        ref.read(symptomReportsControllerProvider).value ?? const [];

    final displayName = (profile?.preferredName.trim().isNotEmpty ?? false)
        ? profile!.preferredName.trim()
        : ((auth?.codename.trim().isNotEmpty ?? false)
            ? auth!.codename.trim()
            : 'Patient');
    final anonymousId = (auth?.id.trim().isNotEmpty ?? false)
        ? auth!.id.trim()
        : 'local_patient';

    final agenda = _scope.includePreVisitAgenda
        ? PreVisitAgenda(
            selectedTopics: _selectedTopics.toList(growable: false),
            patientQuestion: _questionController.text.trim(),
            whatHelpedRecently: _helpedController.text.trim(),
            focusPlanFeedback: _focusPlanFeedback.trim(),
            updatedAt: DateTime.now(),
          )
        : null;

    final syncService = ref.read(clinicianSyncServiceProvider);
    return syncService.buildPatientPacket(
      patientDisplayName: displayName,
      patientAnonymousId: anonymousId,
      consentScope: _scope,
      traces: traces,
      cases: cases,
      symptomReports: symptoms,
      profile: profile,
      preVisitAgenda: agenda,
    );
  }

  Future<void> _logClinicalHandoff(ClinicianSyncPacket packet) async {
    final sessionNumbers = packet.sharedCases
        .where((c) => !c.isPrivate)
        .map((c) => c.caseNumber)
        .toList(growable: false);
    try {
      await ref.read(clinicalExportLogServiceProvider).logExport(
            sessionNumbers: sessionNumbers,
            recipientOrNote:
                'Care Handoff (${packet.consentScope.windowDays}d, ${packet.traces.length} logs)',
          );
    } catch (_) {
      // Audit logging should not block user handoff if storage fails.
    }
  }

  Future<void> _generateEncryptedCode(AppStrings strings) async {
    final pass = _passphraseController.text.trim();
    if (pass.length < 6) {
      setState(() {
        _errorText = strings.handoffPassphraseMinError;
      });
      return;
    }

    setState(() {
      _isGeneratingCode = true;
      _errorText = null;
    });

    try {
      final packet = await _buildCurrentPacket();
      final syncService = ref.read(clinicianSyncServiceProvider);
      final code = await syncService.encryptPacketToShareCode(packet, pass);
      await _logClinicalHandoff(packet);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() {
        _generatedCode = code;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingCode = false;
        });
      }
    }
  }

  Future<void> _copyGeneratedCode(AppStrings strings, MindTokens tokens) async {
    final code = _generatedCode;
    if (code == null || code.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: code));
    HapticFeedback.lightImpact();
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        backgroundColor: tokens.surface2,
        content: Text(
          strings.syncCodeCopiedSnackbar,
          style: TextStyle(color: tokens.ink, fontSize: 13),
        ),
      ),
    );
  }

  Future<void> _sendToLocalWorkspace(
    BuildContext context,
    AppStrings strings,
    MindTokens tokens,
  ) async {
    setState(() {
      _isDeliveringLocal = true;
      _errorText = null;
    });

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final router = GoRouter.maybeOf(context);

    try {
      final packet = await _buildCurrentPacket();
      await ref.read(clinicianRosterProvider.notifier).importPacket(packet);
      await _logClinicalHandoff(packet);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      navigator.pop();
      messenger?.showSnackBar(
        SnackBar(
          backgroundColor: tokens.surface2,
          content: Text(
            strings.sentToLocalClinicianSnackbar,
            style: TextStyle(color: tokens.ink, fontSize: 13),
          ),
          action: router == null
              ? null
              : SnackBarAction(
                  label: strings.openClinicianWorkspaceBtn,
                  textColor: tokens.m1,
                  onPressed: () => router.go(AppRouter.clinician),
                ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isDeliveringLocal = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final strings = ref.watch(appStringsProvider);
    final casesAsync = ref.watch(savedCasesProvider);
    final allCases = casesAsync.value ?? const [];
    final privateCount = allCases.where((c) => c.isPrivate).length;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

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
                padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.health_and_safety_outlined,
                      size: 20,
                      color: tokens.m1,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.shareWithPsychiatristTitle,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: tokens.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            strings.careHandoffSubtitle,
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
                      message: MaterialLocalizations.of(context).closeButtonTooltip,
                      child: IconButton(
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
                      // Hard Privacy Exclusion Banner
                      MindCard(
                        variant: MindCardVariant.flat,
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.lock_outline_rounded,
                              size: 16,
                              color: tokens.safety,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                strings.privateCasesExcludedBanner(privateCount),
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: tokens.ink,
                                  height: 1.35,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Share Window Selector
                      Text(
                        strings.timeWindowLabel,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: tokens.ink2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [7, 14, 30, 90].map((days) {
                          return MindPill(
                            label: strings.daysWindowLabel(days),
                            isSelected: _scope.windowDays == days,
                            onTap: () => setState(
                              () => _scope = _scope.copyWith(windowDays: days),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 18),

                      // Granular Consent Toggles
                      Text(
                        strings.whatToShareLabel,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: tokens.ink2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      MindCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _consentRow(
                              tokens: tokens,
                              title: strings.scopeMoodMetricsLabel,
                              value: _scope.includeMoodMetrics,
                              onChanged: (v) => setState(
                                () => _scope =
                                    _scope.copyWith(includeMoodMetrics: v),
                              ),
                            ),
                            Divider(height: 1, color: tokens.line),
                            _consentRow(
                              tokens: tokens,
                              title: strings.scopeSleepEnergyAnxietyLabel,
                              value: _scope.includeSleepEnergyAnxiety,
                              onChanged: (v) => setState(
                                () => _scope = _scope.copyWith(
                                  includeSleepEnergyAnxiety: v,
                                ),
                              ),
                            ),
                            Divider(height: 1, color: tokens.line),
                            _consentRow(
                              tokens: tokens,
                              title: strings.scopePersonalNotesLabel,
                              value: _scope.includePersonalNotes,
                              onChanged: (v) => setState(
                                () => _scope =
                                    _scope.copyWith(includePersonalNotes: v),
                              ),
                            ),
                            Divider(height: 1, color: tokens.line),
                            _consentRow(
                              tokens: tokens,
                              title: strings.scopeSharedCasesLabel,
                              value: _scope.includeSharedCases,
                              onChanged: (v) => setState(
                                () => _scope =
                                    _scope.copyWith(includeSharedCases: v),
                              ),
                            ),
                            Divider(height: 1, color: tokens.line),
                            _consentRow(
                              tokens: tokens,
                              title: strings.scopeSymptomReportsLabel,
                              value: _scope.includeSymptomReports,
                              onChanged: (v) => setState(
                                () => _scope =
                                    _scope.copyWith(includeSymptomReports: v),
                              ),
                            ),
                            Divider(height: 1, color: tokens.line),
                            _consentRow(
                              tokens: tokens,
                              title: strings.scopeProfileSnapshotLabel,
                              value: _scope.includePsychologicalProfile,
                              onChanged: (v) => setState(
                                () => _scope = _scope.copyWith(
                                  includePsychologicalProfile: v,
                                ),
                              ),
                            ),
                            Divider(height: 1, color: tokens.line),
                            _consentRow(
                              tokens: tokens,
                              title: strings.scopePreVisitAgendaLabel,
                              value: _scope.includePreVisitAgenda,
                              onChanged: (v) => setState(
                                () => _scope =
                                    _scope.copyWith(includePreVisitAgenda: v),
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (_scope.includePreVisitAgenda) ...[
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                strings.preVisitAgendaSectionTitle,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: tokens.ink2,
                                ),
                              ),
                            ),
                            MindBadge(
                              icon: Icons.assignment_outlined,
                              label: strings.prepareForVisitBtn,
                              onTap: () {
                                final nav = Navigator.of(context);
                                final rootCtx = nav.context;
                                nav.pop();
                                PreVisitBriefSheet.show(rootCtx);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_focusPlanFeedback.isNotEmpty) ...[
                          MindBadge(
                            icon: Icons.event_available_outlined,
                            label:
                                '${strings.focusFeedbackClinicianLabel}: $_focusPlanFeedback',
                            isSelected: true,
                          ),
                          const SizedBox(height: 8),
                        ],
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _topicOptions(strings).map((topic) {
                            final selected = _selectedTopics.contains(topic);
                            return MindPill(
                              label: topic,
                              isSelected: selected,
                              onTap: () {
                                setState(() {
                                  if (selected) {
                                    _selectedTopics.remove(topic);
                                  } else {
                                    _selectedTopics.add(topic);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _questionController,
                          maxLines: 2,
                          style: TextStyle(fontSize: 13.5, color: tokens.ink),
                          decoration: _fieldDecoration(
                            tokens,
                            strings.preVisitQuestionHint,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _helpedController,
                          maxLines: 2,
                          style: TextStyle(fontSize: 13.5, color: tokens.ink),
                          decoration: _fieldDecoration(
                            tokens,
                            strings.preVisitHelpedHint,
                          ),
                        ),
                      ],

                      const SizedBox(height: 18),

                      // Channel 1: Encrypted Offline Handoff Code
                      Text(
                        strings.handoffPassphraseLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: tokens.ink2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _passphraseController,
                        obscureText: true,
                        style: TextStyle(fontSize: 14, color: tokens.ink),
                        decoration: _fieldDecoration(
                          tokens,
                          strings.handoffPassphraseHint,
                        ),
                      ),

                      if (_errorText != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _errorText!,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: tokens.safety,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],

                      const SizedBox(height: 12),
                      MindButton(
                        text: strings.generateSyncCodeBtn,
                        variant: MindButtonVariant.soft,
                        leadingIcon: Icons.enhanced_encryption_outlined,
                        isFullWidth: true,
                        isLoading: _isGeneratingCode,
                        onPressed: () => _generateEncryptedCode(strings),
                      ),

                      if (_generatedCode != null) ...[
                        const SizedBox(height: 10),
                        MindCard(
                          variant: MindCardVariant.flat,
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SelectableText(
                                _generatedCode!,
                                maxLines: 4,
                                style: TextStyle(
                                  fontSize: 12.0,
                                  color: tokens.ink2,
                                ),
                              ),
                              const SizedBox(height: 10),
                              MindButton(
                                text: strings.copySyncCodeBtn,
                                variant: MindButtonVariant.secondary,
                                leadingIcon: Icons.copy_rounded,
                                isFullWidth: true,
                                onPressed: () =>
                                    _copyGeneratedCode(strings, tokens),
                              ),
                              const SizedBox(height: 8),
                              MindButton(
                                text: _showQr
                                    ? strings.hideInRoomQrBtn
                                    : strings.showInRoomQrBtn,
                                variant: MindButtonVariant.soft,
                                leadingIcon: Icons.qr_code_2_rounded,
                                isFullWidth: true,
                                onPressed: () =>
                                    setState(() => _showQr = !_showQr),
                              ),
                              if (_showQr) ...[
                                const SizedBox(height: 12),
                                MindQrCodeView(
                                  data: _generatedCode!,
                                  size: 196,
                                  semanticLabel: strings.showInRoomQrBtn,
                                  overflowNotice:
                                      strings.qrCapacityExceededNote,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  strings.inRoomQrPinReminder,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12.0,
                                    color: tokens.ink2,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 12),

                      // Channel 2: Direct On-Device Clinical Workspace Delivery
                      MindButton(
                        text: strings.sendToLocalClinicianBtn,
                        variant: MindButtonVariant.primary,
                        leadingIcon: Icons.medical_services_outlined,
                        isFullWidth: true,
                        isLoading: _isDeliveringLocal,
                        onPressed: () =>
                            _sendToLocalWorkspace(context, strings, tokens),
                      ),

                      const SizedBox(height: 10),

                      // Channel 3: Printable 1-Page A4 Clinical Brief (PDF)
                      MindButton(
                        text: strings.previewClinicalBriefBtn,
                        variant: MindButtonVariant.secondary,
                        leadingIcon: Icons.picture_as_pdf_outlined,
                        isFullWidth: true,
                        onPressed: _openPrintableBrief,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _consentRow({
    required MindTokens tokens,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return MindPressable(
      onPressed: () => onChanged(!value),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: tokens.ink,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              MindSwitch(
                value: value,
                semanticLabel: title,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(MindTokens tokens, String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 13, color: tokens.ink3),
      filled: true,
      fillColor: tokens.surface2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
