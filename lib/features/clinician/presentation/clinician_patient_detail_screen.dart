import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/localization/mind_formatters.dart';
import '../../../app/router/app_router.dart';
import '../../../app/theme/mind_tokens.dart';
import '../../../core/widgets/mind_badge.dart';
import '../../../core/widgets/mind_banner.dart';
import '../../../core/widgets/mind_button.dart';
import '../../../core/widgets/mind_card.dart';
import '../../../core/widgets/mind_dialog.dart';
import '../../../core/widgets/mind_pill.dart';
import '../../../core/widgets/mind_pressable.dart';
import '../../../core/widgets/mind_segmented.dart';
import '../../../core/widgets/mind_skeleton.dart';
import '../../../core/widgets/mind_toast.dart';
import '../../../core/widgets/smooth_spline_chart.dart';
import '../../clinic_sync/controllers/clinic_sync_providers.dart';
import '../../clinic_sync/domain/clinic_account_models.dart';
import '../../insights/domain/forensic_loop_model.dart';
import '../../insights/domain/personal_baseline_model.dart';
import '../../insights/presentation/widgets/forensic_loop_map_card.dart';
import '../../insights/presentation/widgets/observed_stabilizers_card.dart';
import '../../mind_trace/domain/adaptive_tracking_engine.dart';
import '../../mind_trace/domain/affect_taxonomy.dart';
import '../../mind_trace/domain/daily_context_tags.dart';
import '../../mind_trace/domain/mind_trace_model.dart';
import '../../observatory/domain/default_symptom_library.dart';
import '../../profile/domain/clinical_condition_catalog.dart';
import '../../profile/domain/psychological_profile_model.dart';
import '../../track/presentation/widgets/track_mood_utils.dart';
import '../controllers/clinician_providers.dart';
import '../domain/clinician_models.dart';
import '../domain/post_visit_focus_model.dart';
import '../domain/visit_diff_model.dart';
import 'widgets/clinical_brief_preview_sheet.dart';
import 'widgets/clinician_record_editor_sheets.dart';
import 'widgets/compose_post_visit_focus_sheet.dart';
import 'widgets/create_patient_account_sheet.dart';

final _dossierClinicAccountProvider =
    FutureProvider.autoDispose.family<ClinicPatientAccount?, String>(
      (ref, patientId) =>
          ref.watch(clinicAuthRepositoryProvider).getPatientAccount(patientId),
    );

enum _ChartMetric { mood, sleep, energy, anxiety }

enum _TimelineWindow { all, days7, days30 }

/// Complete 360° psychiatric patient clinical profile (`Overview`, `Timeline`,
/// `Cases`, `Notes`) with strict provenance separation between:
/// 1. Clinician-documented diagnoses, medications, allergies & clinical history
/// 2. Patient-reported longitudinal tracking & consented profile
/// 3. Non-diagnostic AI-assisted self-reflections
class ClinicianPatientDetailScreen extends ConsumerStatefulWidget {
  const ClinicianPatientDetailScreen({
    super.key,
    required this.patientId,
    this.embedded = false,
    this.autoMarkReviewed = true,
  });

  final String patientId;
  final bool embedded;
  final bool autoMarkReviewed;

  @override
  ConsumerState<ClinicianPatientDetailScreen> createState() =>
      _ClinicianPatientDetailScreenState();
}

class _ClinicianPatientDetailScreenState
    extends ConsumerState<ClinicianPatientDetailScreen> {
  int _segmentIndex = 0;
  _ChartMetric _chartMetric = _ChartMetric.mood;
  _TimelineWindow _timelineWindow = _TimelineWindow.all;
  int? _activeSplineIndex;
  bool _historyExpanded = false;
  bool _selfProfileExpanded = false;
  bool _consentExpanded = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoMarkReviewed) {
      _scheduleMarkReviewed();
    }
  }

  @override
  void didUpdateWidget(covariant ClinicianPatientDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.patientId != oldWidget.patientId) {
      _segmentIndex = 0;
      _chartMetric = _ChartMetric.mood;
      _timelineWindow = _TimelineWindow.all;
      _activeSplineIndex = null;
      _historyExpanded = false;
      _selfProfileExpanded = false;
      _consentExpanded = false;
      if (widget.autoMarkReviewed) {
        _scheduleMarkReviewed();
      }
    }
  }

  void _scheduleMarkReviewed() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref
            .read(clinicianRosterProvider.notifier)
            .markReviewed(widget.patientId);
      }
    });
  }

  Future<void> _copyEhrSummary(
    ClinicianPatientRecord record,
    AppStrings strings,
  ) async {
    final summary = ref
        .read(clinicianSyncServiceProvider)
        .generateEhrClinicalNote(record, strings);
    await Clipboard.setData(ClipboardData(text: summary));
    HapticFeedback.mediumImpact();
    if (!mounted) return;
    showMindToast(
      context,
      strings.ehrCopiedSnackbar,
      variant: MindToastVariant.success,
    );
  }

  String _dayBucketLabel(DayTimeBucket bucket, AppStrings strings) {
    return switch (bucket) {
      DayTimeBucket.morning => strings.morningBucketLabel,
      DayTimeBucket.afternoon => strings.afternoonBucketLabel,
      DayTimeBucket.evening => strings.eveningBucketLabel,
      DayTimeBucket.night => strings.nightBucketLabel,
    };
  }

  String _formatDate(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}-'
        '${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')}';
  }

  String _symptomTitle(String id, AppStrings strings) {
    for (final entry in DefaultSymptomLibrary.entries) {
      if (entry.id == id) return entry.title(strings);
    }
    return id.replaceAll('sym_', '').replaceAll('_', ' ');
  }

  ({String label, Color bg, Color fg}) _accountStatusBadgeData(
    ClinicAccountStatus status,
    MindTokens tokens,
    AppStrings strings,
  ) {
    return switch (status) {
      ClinicAccountStatus.pendingFirstLogin => (
        label: strings.awaitingFirstLoginBadge,
        bg: tokens.warningSoft,
        fg: tokens.warning,
      ),
      ClinicAccountStatus.paused => (
        label: strings.accountPausedBadge,
        bg: tokens.safetySoft,
        fg: tokens.safety,
      ),
      ClinicAccountStatus.active => (
        label: strings.accountActiveBadge,
        bg: tokens.primarySoft,
        fg: tokens.ink,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final strings = ref.watch(appStringsProvider);
    final rosterAsync = ref.watch(clinicianRosterProvider);
    final roster = rosterAsync.value ?? const <ClinicianPatientRecord>[];

    ClinicianPatientRecord? record;
    for (final item in roster) {
      if (item.patientId == widget.patientId) {
        record = item;
        break;
      }
    }

    if (rosterAsync.isLoading && record == null) {
      const loader = Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            MindSkeleton.card(height: 88),
            SizedBox(height: 12),
            MindSkeleton.card(height: 160),
          ],
        ),
      );
      if (widget.embedded) {
        return ColoredBox(color: tokens.bg, child: loader);
      }
      return Scaffold(backgroundColor: tokens.bg, body: SafeArea(child: loader));
    }

    if (record == null) {
      final notFoundBody = Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: MindCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.folder_off_outlined, size: 28, color: tokens.ink2),
                const SizedBox(height: 12),
                Text(
                  strings.patientNotFoundTitle,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: tokens.ink,
                  ),
                ),
                if (!widget.embedded) ...[
                  const SizedBox(height: 16),
                  MindButton(
                    text: strings.backToPatientsBtn,
                    isFullWidth: true,
                    onPressed: () {
                      final router = GoRouter.maybeOf(context);
                      if (router != null) {
                        router.go(AppRouter.clinician);
                      } else {
                        Navigator.of(context).maybePop();
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      );

      if (widget.embedded) {
        return ColoredBox(color: tokens.bg, child: notFoundBody);
      }
      return Scaffold(
        backgroundColor: tokens.bg,
        appBar: AppBar(backgroundColor: tokens.bg, elevation: 0),
        body: notFoundBody,
      );
    }

    final patientRecord = record;
    final account =
        ref.watch(_dossierClinicAccountProvider(patientRecord.patientId)).value;
    final inbox =
        ref.watch(dossierPatientInboxProvider(patientRecord.patientId)).value;

    final dossierContent = Column(
      children: [
        // Pinned Clinical Identity & Alert Header
        _buildPinnedClinicalHeader(
          context: context,
          record: patientRecord,
          account: account,
          activeFocusPlan: inbox?.activeFocusPlan,
          tokens: tokens,
          strings: strings,
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 12),
          child: MindSegmented(
            index: _segmentIndex,
            labels: [
              strings.dossierTabOverview,
              strings.dossierTabTimeline,
              strings.dossierTabCases,
              strings.dossierTabNotes,
            ],
            onChanged: (idx) => setState(() => _segmentIndex = idx),
          ),
        ),

        Expanded(
          child: switch (_segmentIndex) {
            0 => _buildOverviewTab(
              patientRecord,
              inbox?.activeFocusPlan,
              tokens,
              strings,
            ),
            1 => _buildTimelineTab(patientRecord, tokens, strings),
            2 => _buildCasesTab(patientRecord, tokens, strings),
            _ => _buildNotesTab(
              context,
              patientRecord,
              account,
              tokens,
              strings,
            ),
          },
        ),
      ],
    );

    if (widget.embedded) {
      return ColoredBox(color: tokens.bg, child: dossierContent);
    }

    return Scaffold(
      backgroundColor: tokens.bg,
      body: SafeArea(child: dossierContent),
    );
  }

  Widget _buildPinnedClinicalHeader({
    required BuildContext context,
    required ClinicianPatientRecord record,
    required ClinicPatientAccount? account,
    required PostVisitFocusPlan? activeFocusPlan,
    required MindTokens tokens,
    required AppStrings strings,
  }) {
    final cr = record.clinicalRecord;
    final activeDx = record.activeDiagnoses;
    final statusBadge = account != null
        ? _accountStatusBadgeData(account.status, tokens, strings)
        : null;

    final metaParts = <String>[
      if (cr.clinicFileNumber.trim().isNotEmpty) '#${cr.clinicFileNumber.trim()}',
      if (account != null) strings.localizedAgeRange(account.ageRange),
      if (cr.biologicalSex.trim().isNotEmpty) cr.biologicalSex.trim(),
      if (cr.phone.trim().isNotEmpty)
        MindFormatters.ltrIsolate(cr.phone.trim())
      else if (account != null)
        MindFormatters.ltrIsolate(account.loginIdentifier),
      strings.daysWindowLabel(record.latestPacket.consentScope.windowDays),
      strings.momentsLoggedLabel(record.latestPacket.traces.length),
    ];

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        widget.embedded ? 18 : 8,
        widget.embedded ? 12 : 8,
        12,
        6,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (!widget.embedded) ...[
                IconButton(
                  tooltip: strings.backToPatientsBtn,
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                  icon: Icon(Icons.arrow_back_rounded, color: tokens.ink),
                  onPressed: () {
                    final nav = Navigator.of(context);
                    if (nav.canPop()) {
                      nav.pop();
                    } else {
                      GoRouter.maybeOf(context)?.go(AppRouter.clinician);
                    }
                  },
                ),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          record.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: tokens.ink,
                          ),
                        ),
                        if (record.isDemoCase)
                          MindBadge(label: strings.demoDatasetBadge),
                        if (statusBadge != null)
                          MindBadge(
                            label: statusBadge.label,
                            backgroundColor: statusBadge.bg,
                            textColor: statusBadge.fg,
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      metaParts.join(' · '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: tokens.ink2,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: strings.previewClinicalBriefBtn,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                icon: Icon(Icons.picture_as_pdf_outlined, color: tokens.ink),
                onPressed: () => ClinicalBriefPreviewSheet.show(
                  context,
                  record: record,
                  activeFocusPlan: activeFocusPlan,
                ),
              ),
              IconButton(
                tooltip: strings.copyEhrSummaryBtn,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                icon: Icon(Icons.content_copy_rounded, color: tokens.ink),
                onPressed: () => _copyEhrSummary(record, strings),
              ),
            ],
          ),
          // Critical Clinical Strip: Diagnoses, Allergies, Safety Pause, Unreviewed
          Padding(
            padding: EdgeInsetsDirectional.only(
              start: widget.embedded ? 0 : 10,
              top: 6,
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (record.hasSafetyPauseAlert)
                  MindBadge(
                    key: const ValueKey<String>('dossier-safety-pause-alert'),
                    icon: Icons.warning_amber_rounded,
                    label: strings.safetyPauseAlertBadge,
                    backgroundColor: tokens.safetySoft,
                    borderColor: tokens.safety,
                    textColor: tokens.safety,
                    onTap: () => setState(() => _segmentIndex = 2),
                  ),
                for (final dx in activeDx.take(3))
                  MindBadge(
                    icon: Icons.medical_information_outlined,
                    label:
                        '${dx.displayTitle} · ${dx.certainty.localizedLabel(strings)}',
                    backgroundColor: tokens.infoSoft,
                    borderColor: tokens.accentInk,
                    textColor: tokens.accentInk,
                    onTap: () => ClinicianDiagnosisSheet.show(
                      context,
                      patientId: record.patientId,
                      currentRecord: cr,
                      existing: dx,
                    ),
                  ),
                if (cr.allergies.isNotEmpty)
                  MindBadge(
                    icon: Icons.report_problem_outlined,
                    label:
                        '${strings.allergiesTitle}: ${cr.allergies.map((a) => a.substance).join(', ')}',
                    backgroundColor: tokens.warningSoft,
                    borderColor: tokens.warning,
                    textColor: tokens.warning,
                    onTap: () => ClinicianAllergySheet.show(
                      context,
                      patientId: record.patientId,
                      currentRecord: cr,
                      existing: cr.allergies.first,
                    ),
                  ),
                if (activeDx.isEmpty)
                  MindBadge(
                    key: const ValueKey<String>('dossier-header-add-dx-btn'),
                    icon: Icons.add_rounded,
                    label: strings.addDiagnosisBtn,
                    onTap: () => ClinicianDiagnosisSheet.show(
                      context,
                      patientId: record.patientId,
                      currentRecord: cr,
                    ),
                  ),
                if (record.hasUnreviewedUpdate)
                  MindBadge(
                    key: const ValueKey<String>('dossier-mark-reviewed-btn'),
                    icon: Icons.check_circle_outline_rounded,
                    label: strings.markReviewedBtn,
                    backgroundColor: tokens.primarySoft,
                    textColor: tokens.ink,
                    onTap: () async {
                      await ref
                          .read(clinicianRosterProvider.notifier)
                          .markReviewed(record.patientId);
                      if (context.mounted) {
                        showMindToast(
                          context,
                          strings.reviewedToast,
                          variant: MindToastVariant.success,
                        );
                      }
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // VIEW 0: CLINICAL OVERVIEW (60-SECOND PRE-VISIT SCAN)
  // ---------------------------------------------------------------------------
  Widget _buildOverviewTab(
    ClinicianPatientRecord record,
    PostVisitFocusPlan? activeFocusPlan,
    MindTokens tokens,
    AppStrings strings,
  ) {
    final packet = record.latestPacket;
    final scope = packet.consentScope;
    final baseline = record.baseline;
    final divergences = record.divergences(strings);
    final agenda = packet.preVisitAgenda;

    final effectiveMetric = !scope.includeSleepEnergyAnxiety
        ? _ChartMetric.mood
        : _chartMetric;

    final chronological = List<MindTraceModel>.from(packet.traces)
      ..sort((a, b) => a.effectiveTimestamp.compareTo(b.effectiveTimestamp));

    final chartValues = <double>[];
    final chartPointColors = <Color>[];
    final chartLabels = <String>[];
    for (final t in chronological) {
      double? norm;
      String lbl = '';
      switch (effectiveMetric) {
        case _ChartMetric.mood:
          norm = (t.moodIntensity / 10.0).clamp(0.0, 1.0);
          lbl = '${t.moodIntensity}/10';
        case _ChartMetric.sleep:
          if (t.sleepHours != null) {
            norm = (t.sleepHours! / 12.0).clamp(0.0, 1.0);
            lbl = MindFormatters.hours(t.sleepHours!, strings);
          }
        case _ChartMetric.energy:
          if (t.energyLevel != null) {
            norm = (t.energyLevel! / 10.0).clamp(0.0, 1.0);
            lbl = '${t.energyLevel}/10';
          }
        case _ChartMetric.anxiety:
          if (t.anxietyLevel != null) {
            norm = (t.anxietyLevel! / 10.0).clamp(0.0, 1.0);
            lbl = '${t.anxietyLevel}/10';
          }
      }
      if (norm != null) {
        chartValues.add(norm);
        chartPointColors.add(trackMoodOptionFor(t.overallMood).color);
        chartLabels.add('${_formatDate(t.date)} · $lbl');
      }
    }

    final safeActiveIdx = (_activeSplineIndex != null &&
            _activeSplineIndex! >= 0 &&
            _activeSplineIndex! < chartValues.length)
        ? _activeSplineIndex
        : null;

    return ListView(
      key: PageStorageKey<String>('dossier_overview_${record.patientId}'),
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
      children: [
        // 0. Urgent Safety Pause Banner (if triggered in any shared reflection)
        if (record.hasSafetyPauseAlert) ...[
          MindBanner(
            body: strings.safetyPauseAlertBanner,
            tone: MindBannerTone.safety,
            actionLabel: strings.dossierTabCases,
            onAction: () => setState(() => _segmentIndex = 2),
          ),
          const SizedBox(height: 14),
        ],

        // 1. Clinician-Documented Clinical Summary (Diagnoses, Meds, Allergies, History)
        _buildClinicianRecordCard(record, tokens, strings),

        // 2. Active Between-Session Focus Plan (if sent by Doctor)
        if (activeFocusPlan != null &&
            activeFocusPlan.focusItems.isNotEmpty) ...[
          const SizedBox(height: 14),
          _buildActiveFocusPlanCard(
            record: record,
            plan: activeFocusPlan,
            tokens: tokens,
            strings: strings,
          ),
        ],

        // 3. Patient Pre-Visit Agenda (including focusPlanFeedback even on Visit 1!)
        if (scope.includePreVisitAgenda && agenda != null && !agenda.isEmpty) ...[
          const SizedBox(height: 14),
          MindCard(
            variant: MindCardVariant.tint,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.preVisitTopicsLabel,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: tokens.ink2,
                  ),
                ),
                const SizedBox(height: 8),
                if (agenda.selectedTopics.isNotEmpty) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: agenda.selectedTopics
                        .map((topic) => MindBadge(label: topic))
                        .toList(),
                  ),
                  const SizedBox(height: 10),
                ],
                if (agenda.patientQuestion.trim().isNotEmpty) ...[
                  Text(
                    strings.preVisitQuestionSubLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: tokens.ink2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    agenda.patientQuestion.trim(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: tokens.ink,
                      height: 1.4,
                    ),
                  ),
                ],
                if (agenda.whatHelpedRecently.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    strings.preVisitHelpedSubLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: tokens.ink2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    agenda.whatHelpedRecently.trim(),
                    style: TextStyle(
                      fontSize: 13,
                      color: tokens.ink2,
                      height: 1.35,
                    ),
                  ),
                ],
                if (agenda.focusPlanFeedback.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  MindBadge(
                    icon: Icons.event_available_outlined,
                    label:
                        '${strings.focusFeedbackClinicianLabel}: ${agenda.focusPlanFeedback.trim()}',
                    isSelected: true,
                  ),
                ],
              ],
            ),
          ),
        ],

        const SizedBox(height: 16),

        // 4. 7-Day vs Personal Baseline Table
        Text(
          strings.recentVsBaselineTitle,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: tokens.ink2,
          ),
        ),
        const SizedBox(height: 8),
        MindCard(
          padding: const EdgeInsets.all(14),
          child: _buildBaselineDeltaTable(
            tokens: tokens,
            strings: strings,
            recent: record.recentBaseline,
            baseline: baseline,
            includeSomatic: scope.includeSleepEnergyAnxiety,
          ),
        ),

        if (record.visitDiff != null) ...[
          const SizedBox(height: 16),
          _buildVisitDiffCard(tokens, strings, record.visitDiff!, scope),
        ],

        // 5. Longitudinal Chart
        if (chartValues.length >= 2) ...[
          const SizedBox(height: 16),
          MindCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    MindPill(
                      label: strings.metricMoodLabel,
                      isSelected: effectiveMetric == _ChartMetric.mood,
                      onTap: () => setState(() {
                        _chartMetric = _ChartMetric.mood;
                        _activeSplineIndex = null;
                      }),
                    ),
                    if (scope.includeSleepEnergyAnxiety) ...[
                      MindPill(
                        label: strings.metricSleepLabel,
                        isSelected: effectiveMetric == _ChartMetric.sleep,
                        onTap: () => setState(() {
                          _chartMetric = _ChartMetric.sleep;
                          _activeSplineIndex = null;
                        }),
                      ),
                      MindPill(
                        label: strings.metricEnergyLabel,
                        isSelected: effectiveMetric == _ChartMetric.energy,
                        onTap: () => setState(() {
                          _chartMetric = _ChartMetric.energy;
                          _activeSplineIndex = null;
                        }),
                      ),
                      MindPill(
                        label: strings.metricAnxietyLabel,
                        isSelected: effectiveMetric == _ChartMetric.anxiety,
                        onTap: () => setState(() {
                          _chartMetric = _ChartMetric.anxiety;
                          _activeSplineIndex = null;
                        }),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 14),
                SmoothSplineChart(
                  values: chartValues,
                  pointColors: chartPointColors,
                  activePointIndex: safeActiveIdx,
                  activePointLabel:
                      safeActiveIdx != null ? chartLabels[safeActiveIdx] : null,
                  onPointSelected: (idx) =>
                      setState(() => _activeSplineIndex = idx),
                ),
              ],
            ),
          ),
        ],

        // 6. Single-Patient Observed Baseline Shifts (fixed single-patient copy!)
        const SizedBox(height: 16),
        Text(
          strings.singlePatientShiftsTitle,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: tokens.ink2,
          ),
        ),
        const SizedBox(height: 8),
        if (divergences.isEmpty)
          MindCard(
            padding: const EdgeInsets.all(14),
            child: Text(
              packet.traces.isEmpty
                  ? strings.noCheckInsLoggedYetLabel
                  : strings.noShiftsDetectedLabel,
              style: TextStyle(fontSize: 13, color: tokens.ink2),
            ),
          )
        else
          ...divergences.map(
            (d) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: MindCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.analytics_outlined,
                          size: 16,
                          color: tokens.safety,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            d.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: tokens.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      d.baselineComparison,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: tokens.ink2,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      d.uncertaintyStatement,
                      style: TextStyle(
                        fontSize: 12.0,
                        color: tokens.ink3,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // 7. Patient Self-Reported Profile (strictly separated provenance!)
        if (scope.includePsychologicalProfile &&
            packet.profileSnapshot != null) ...[
          const SizedBox(height: 16),
          _buildSelfReportedProfileAccordion(
            packet.profileSnapshot!,
            tokens,
            strings,
          ),
        ],

        // 8. Condition-Specific Care Track Markers
        if (scope.includeMoodMetrics) ...[
          Builder(
            builder: (context) {
              final tracks = ClinicalConditionCatalog.resolveTracks(
                record.latestPacket.profileSnapshot,
              );
              final markers = AdaptiveTrackingEngine.summarizeConditionMarkers(
                record.latestPacket.traces,
                tracks,
                strings,
              );
              final explicitTracks = tracks
                  .where((t) => t != ClinicalTrack.generalWellness)
                  .toList(growable: false);
              if (markers.isEmpty && explicitTracks.isEmpty) {
                return const SizedBox.shrink();
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  MindCard(
                    key: const ValueKey('clinician-condition-markers-card'),
                    variant: MindCardVariant.flat,
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.doctorDossierConditionMarkersTitle,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: tokens.ink,
                          ),
                        ),
                        if (explicitTracks.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final t in explicitTracks)
                                MindBadge(
                                  label: t.localizedTitle(strings),
                                  backgroundColor: tokens.cardTint,
                                  textColor: tokens.ink,
                                ),
                            ],
                          ),
                        ],
                        if (markers.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          for (final line in markers)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                '• $line',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: tokens.ink2,
                                  height: 1.4,
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],

        // 9. Affect Spectrum & Diurnal Rhythm
        if (baseline.emotionFrequencyMap.isNotEmpty ||
            baseline.diurnalIntensityAverages.isNotEmpty) ...[
          const SizedBox(height: 16),
          MindCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.affectSpectrumSectionTitle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: tokens.ink,
                  ),
                ),
                if (baseline.emotionFrequencyMap.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: baseline.emotionFrequencyMap.entries.take(6).map((e) {
                      return MindBadge(
                        label:
                            '${AffectTaxonomy.localizedLabel(e.key, strings)} (${MindFormatters.times(e.value, strings)})',
                      );
                    }).toList(),
                  ),
                ],
                if (baseline.diurnalIntensityAverages.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: DayTimeBucket.values
                        .where(
                          (b) => baseline.diurnalIntensityAverages.containsKey(b),
                        )
                        .map(
                          (b) => MindBadge(
                            label:
                                '${_dayBucketLabel(b, strings)}: ${MindFormatters.decimal(baseline.diurnalIntensityAverages[b]!, strings)}/10',
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],

        // 10. Daily Context & Routine Links
        if (scope.includeSleepEnergyAnxiety &&
            baseline.contextTagCorrelations.isNotEmpty) ...[
          const SizedBox(height: 16),
          MindCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.dailyContextSectionTitle,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: tokens.ink2,
                  ),
                ),
                const SizedBox(height: 10),
                ...baseline.contextTagCorrelations.take(6).map((c) {
                  final tag = DailyContextTags.byKey(c.tagKey);
                  final metrics = <String>[
                    MindFormatters.times(c.occurrences, strings),
                    if (c.avgMoodIntensity != null)
                      '${MindFormatters.decimal(c.avgMoodIntensity!, strings)}/10',
                    if (c.avgSleepHours != null)
                      MindFormatters.hours(c.avgSleepHours!, strings),
                  ];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: tokens.surface2,
                        borderRadius: BorderRadius.circular(tokens.chipRadius),
                        border: Border.all(color: tokens.line),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                tag?.icon ?? Icons.label_outline_rounded,
                                size: 15,
                                color: tokens.ink,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  DailyContextTags.localizedLabel(
                                    c.tagKey,
                                    strings,
                                  ),
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: tokens.ink,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Padding(
                            padding:
                                const EdgeInsetsDirectional.only(start: 23),
                            child: Text(
                              metrics.join(' · '),
                              style: TextStyle(
                                fontSize: 12,
                                color: tokens.ink2,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],

        // 11. Observed Stabilizers
        if (scope.includeMoodMetrics && baseline.recoveryLedger.hasEvidence) ...[
          const SizedBox(height: 16),
          ObservedStabilizersCard(
            ledger: baseline.recoveryLedger,
            strings: strings,
          ),
        ],

        // 12. Observed Loop Map (non-private cases only)
        if (scope.includeMoodMetrics)
          Builder(
            builder: (context) {
              final loop = ForensicLoopLink.synthesize(
                baseline: baseline,
                cases: scope.includeSharedCases
                    ? packet.sharedCases
                    : const [],
                strings: strings,
                excludePrivateCases: true,
                includeSomatic: scope.includeSleepEnergyAnxiety,
              );
              if (!loop.hasSufficientSignal) {
                return const SizedBox.shrink();
              }
              return Column(
                children: [
                  const SizedBox(height: 16),
                  ForensicLoopMapCard(loop: loop, strings: strings),
                ],
              );
            },
          ),

        // 13. Compact Expandable 7/7 Consent Scope Footer
        const SizedBox(height: 16),
        _buildConsentScopeFooter(scope, tokens, strings),
      ],
    );
  }

  Widget _buildClinicianRecordCard(
    ClinicianPatientRecord record,
    MindTokens tokens,
    AppStrings strings,
  ) {
    final cr = record.clinicalRecord;
    final hasCoreItems = cr.diagnoses.isNotEmpty ||
        cr.medications.isNotEmpty ||
        cr.allergies.isNotEmpty ||
        cr.noKnownAllergies ||
        cr.hasHistoryNotes;

    if (!hasCoreItems) {
      return MindCard(
        key: const ValueKey<String>('dossier-clinical-record-card'),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  strings.clinicalSummaryTitle,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: tokens.ink,
                  ),
                ),
                MindBadge(
                  label: strings.clinicianDocumentedBadge,
                  backgroundColor: tokens.infoSoft,
                  textColor: tokens.accentInk,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                MindBadge(
                  key: const ValueKey<String>('dossier-add-dx-btn'),
                  icon: Icons.add_rounded,
                  label: strings.addDiagnosisBtn,
                  onTap: () => ClinicianDiagnosisSheet.show(
                    context,
                    patientId: record.patientId,
                    currentRecord: cr,
                  ),
                ),
                MindBadge(
                  key: const ValueKey<String>('dossier-add-med-btn'),
                  icon: Icons.add_rounded,
                  label: strings.addMedicationBtn,
                  onTap: () => ClinicianMedicationSheet.show(
                    context,
                    patientId: record.patientId,
                    currentRecord: cr,
                  ),
                ),
                MindBadge(
                  key: const ValueKey<String>('dossier-add-allergy-btn'),
                  icon: Icons.add_rounded,
                  label: strings.addAllergyBtn,
                  onTap: () => ClinicianAllergySheet.show(
                    context,
                    patientId: record.patientId,
                    currentRecord: cr,
                  ),
                ),
                MindBadge(
                  key: const ValueKey<String>('dossier-edit-chart-btn'),
                  icon: Icons.edit_outlined,
                  label: strings.editClinicalDetailsBtn,
                  onTap: () => ClinicianHistoryDemographicsSheet.show(
                    context,
                    patientId: record.patientId,
                    currentRecord: cr,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return MindCard(
      key: const ValueKey<String>('dossier-clinical-record-card'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                strings.clinicalSummaryTitle,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: tokens.ink,
                ),
              ),
              MindBadge(
                label: strings.clinicianDocumentedBadge,
                backgroundColor: tokens.infoSoft,
                textColor: tokens.accentInk,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Diagnoses
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                strings.documentedDiagnosesTitle,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: tokens.ink2,
                ),
              ),
              MindBadge(
                key: const ValueKey<String>('dossier-add-dx-btn'),
                icon: Icons.add_rounded,
                label: strings.addDiagnosisBtn,
                onTap: () => ClinicianDiagnosisSheet.show(
                  context,
                  patientId: record.patientId,
                  currentRecord: cr,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (cr.diagnoses.isEmpty)
            Text(
              strings.noDiagnosesRecordedLabel,
              style: TextStyle(fontSize: 13, color: tokens.ink3),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: cr.diagnoses.map((dx) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: MindPressable(
                    semanticLabel:
                        '${dx.displayTitle}, ${dx.certainty.localizedLabel(strings)}',
                    onPressed: () => ClinicianDiagnosisSheet.show(
                      context,
                      patientId: record.patientId,
                      currentRecord: cr,
                      existing: dx,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 48),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: tokens.surface2,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: tokens.line),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dx.displayTitle,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: tokens.ink,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${dx.certainty.localizedLabel(strings)} · ${dx.status.localizedLabel(strings)} · ${MindFormatters.shortDate(dx.documentedAt, strings)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: tokens.ink2,
                                  ),
                                ),
                                if (dx.clinicalNotes.trim().isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    dx.clinicalNotes.trim(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: tokens.ink2,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Icon(
                            Icons.edit_outlined,
                            size: 16,
                            color: tokens.ink3,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: 12),
          Divider(height: 1, color: tokens.line),
          const SizedBox(height: 12),

          // Medications
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                strings.currentMedicationsTitle,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: tokens.ink2,
                ),
              ),
              MindBadge(
                key: const ValueKey<String>('dossier-add-med-btn'),
                icon: Icons.add_rounded,
                label: strings.addMedicationBtn,
                onTap: () => ClinicianMedicationSheet.show(
                  context,
                  patientId: record.patientId,
                  currentRecord: cr,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (cr.medications.isEmpty)
            Text(
              strings.noMedicationsRecordedLabel,
              style: TextStyle(fontSize: 13, color: tokens.ink3),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: cr.medications.map((med) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: MindPressable(
                    semanticLabel:
                        '${med.name}, ${med.regimenSummary}, ${med.status.localizedLabel(strings)}',
                    onPressed: () => ClinicianMedicationSheet.show(
                      context,
                      patientId: record.patientId,
                      currentRecord: cr,
                      existing: med,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 48),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: tokens.surface2,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: tokens.line),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  med.name,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: tokens.ink,
                                  ),
                                ),
                                if (med.regimenSummary.isNotEmpty)
                                  Text(
                                    med.regimenSummary,
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
                          MindBadge(label: med.status.localizedLabel(strings)),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: 12),
          Divider(height: 1, color: tokens.line),
          const SizedBox(height: 12),

          // Allergies
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                strings.allergiesTitle,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: tokens.ink2,
                ),
              ),
              MindBadge(
                key: const ValueKey<String>('dossier-add-allergy-btn'),
                icon: Icons.add_rounded,
                label: strings.addAllergyBtn,
                onTap: () => ClinicianAllergySheet.show(
                  context,
                  patientId: record.patientId,
                  currentRecord: cr,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (cr.allergies.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: cr.allergies.map((a) {
                return MindBadge(
                  icon: Icons.report_problem_outlined,
                  label:
                      '${a.substance}${a.reaction.trim().isNotEmpty ? ' · ${a.reaction.trim()}' : ''} (${a.severity.localizedLabel(strings)})',
                  backgroundColor: tokens.warningSoft,
                  borderColor: tokens.warning,
                  textColor: tokens.warning,
                  onTap: () => ClinicianAllergySheet.show(
                    context,
                    patientId: record.patientId,
                    currentRecord: cr,
                    existing: a,
                  ),
                );
              }).toList(),
            )
          else if (cr.noKnownAllergies)
            Text(
              strings.noKnownAllergiesLabel,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: tokens.ink2,
              ),
            )
          else
            Text(
              strings.allergiesNotRecordedLabel,
              style: TextStyle(fontSize: 13, color: tokens.ink3),
            ),

          const SizedBox(height: 12),
          Divider(height: 1, color: tokens.line),
          const SizedBox(height: 8),

          // Expandable Clinical History & Demographics
          MindPressable(
            key: const ValueKey<String>('dossier-history-accordion'),
            semanticLabel: strings.clinicalHistoryAndDetailsTitle,
            onPressed: () =>
                setState(() => _historyExpanded = !_historyExpanded),
            borderRadius: BorderRadius.circular(10),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      strings.clinicalHistoryAndDetailsTitle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: tokens.ink,
                      ),
                    ),
                  ),
                  Icon(
                    _historyExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: tokens.ink2,
                  ),
                ],
              ),
            ),
          ),
          if (_historyExpanded) ...[
            const SizedBox(height: 6),
            if (cr.psychiatricHistory.trim().isNotEmpty)
              _detailRow(
                strings.psychiatricHistoryField,
                cr.psychiatricHistory.trim(),
                tokens,
              ),
            if (cr.medicalHistory.trim().isNotEmpty)
              _detailRow(
                strings.medicalHistoryField,
                cr.medicalHistory.trim(),
                tokens,
              ),
            if (cr.familyHistory.trim().isNotEmpty)
              _detailRow(
                strings.familyHistoryField,
                cr.familyHistory.trim(),
                tokens,
              ),
            if (cr.safetyObservationNote.trim().isNotEmpty)
              _detailRow(
                strings.safetyProtectiveFactorsField,
                cr.safetyObservationNote.trim(),
                tokens,
              ),
            if (cr.emergencyContactName.trim().isNotEmpty ||
                cr.emergencyContactPhone.trim().isNotEmpty)
              _detailRow(
                strings.emergencyContactNameField,
                [
                  if (cr.emergencyContactName.trim().isNotEmpty)
                    cr.emergencyContactName.trim(),
                  if (cr.emergencyContactPhone.trim().isNotEmpty)
                    MindFormatters.ltrIsolate(cr.emergencyContactPhone.trim()),
                ].join(' · '),
                tokens,
              ),
            if (cr.referralSource.trim().isNotEmpty)
              _detailRow(
                strings.referralSourceField,
                cr.referralSource.trim(),
                tokens,
              ),
            const SizedBox(height: 8),
            MindButton(
              key: const ValueKey<String>('dossier-edit-chart-btn'),
              text: strings.editClinicalDetailsBtn,
              variant: MindButtonVariant.soft,
              leadingIcon: Icons.edit_outlined,
              isFullWidth: true,
              onPressed: () => ClinicianHistoryDemographicsSheet.show(
                context,
                patientId: record.patientId,
                currentRecord: cr,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, MindTokens tokens) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: tokens.ink2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(fontSize: 13, color: tokens.ink, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFocusPlanCard({
    required ClinicianPatientRecord record,
    required PostVisitFocusPlan plan,
    required MindTokens tokens,
    required AppStrings strings,
  }) {
    final doneCount = plan.focusItems.where((i) => i.isCompleted).length;
    return MindCard(
      key: const ValueKey<String>('dossier-active-focus-plan-card'),
      variant: MindCardVariant.flat,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag_outlined, size: 17, color: tokens.accentInk),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  strings.activeFocusPlanDoctorTitle,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: tokens.ink,
                  ),
                ),
              ),
              MindBadge(
                label: '$doneCount/${plan.focusItems.length}',
                backgroundColor: tokens.primarySoft,
                textColor: tokens.ink,
              ),
            ],
          ),
          if (plan.followUpDate != null) ...[
            const SizedBox(height: 4),
            Text(
              '${strings.nextAppointmentTitle}: ${MindFormatters.shortDate(plan.followUpDate!, strings)}',
              style: TextStyle(fontSize: 12, color: tokens.ink2),
            ),
          ],
          const SizedBox(height: 8),
          for (final item in plan.focusItems)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    item.isCompleted
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 16,
                    color: item.isCompleted ? tokens.accentInk : tokens.ink3,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.title,
                      style: TextStyle(fontSize: 13, color: tokens.ink),
                    ),
                  ),
                ],
              ),
            ),
          if (plan.observationCue.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              plan.observationCue.trim(),
              style: TextStyle(fontSize: 12.5, color: tokens.ink2, height: 1.35),
            ),
          ],
          const SizedBox(height: 8),
          MindButton(
            text: strings.updateFocusPlanBtn,
            variant: MindButtonVariant.soft,
            leadingIcon: Icons.send_outlined,
            isFullWidth: true,
            onPressed: () => ComposePostVisitFocusSheet.show(
              context,
              patientDisplayName: record.displayName,
              patientId: record.patientId,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelfReportedProfileAccordion(
    PsychologicalProfileModel profile,
    MindTokens tokens,
    AppStrings strings,
  ) {
    final hasAny = profile.conditions.isNotEmpty ||
        profile.selectedConditionIds.isNotEmpty ||
        profile.currentTreatment.trim().isNotEmpty ||
        profile.personalTriggers.trim().isNotEmpty ||
        profile.personalGoals.trim().isNotEmpty ||
        profile.selectedGoals.isNotEmpty;
    if (!hasAny) return const SizedBox.shrink();

    return MindCard(
      key: const ValueKey<String>('dossier-self-reported-profile-card'),
      variant: MindCardVariant.flat,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MindPressable(
            semanticLabel: strings.patientSelfReportedProfileTitle,
            onPressed: () =>
                setState(() => _selfProfileExpanded = !_selfProfileExpanded),
            borderRadius: BorderRadius.circular(10),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.patientSelfReportedProfileTitle,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: tokens.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          strings.patientSelfReportedBadge,
                          style: TextStyle(fontSize: 12, color: tokens.ink2),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _selfProfileExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: tokens.ink2,
                  ),
                ],
              ),
            ),
          ),
          if (_selfProfileExpanded) ...[
            const SizedBox(height: 8),
            if (profile.conditions.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: profile.conditions.map((c) {
                  return MindBadge(
                    label:
                        '${c.condition.displayName} (${c.status.displayName})',
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
            ],
            if (profile.currentTreatment.trim().isNotEmpty)
              _detailRow(
                strings.selfReportedTreatmentLabel,
                profile.currentTreatment.trim(),
                tokens,
              ),
            if (profile.personalTriggers.trim().isNotEmpty)
              _detailRow(
                strings.selfReportedTriggersLabel,
                profile.personalTriggers.trim(),
                tokens,
              ),
            if (profile.personalGoals.trim().isNotEmpty ||
                profile.selectedGoals.isNotEmpty)
              _detailRow(
                strings.selfReportedGoalsLabel,
                [
                  ...profile.selectedGoals.map((g) => g.replaceAll('_', ' ')),
                  if (profile.personalGoals.trim().isNotEmpty)
                    profile.personalGoals.trim(),
                ].join(' · '),
                tokens,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildConsentScopeFooter(
    ClinicalConsentScope scope,
    MindTokens tokens,
    AppStrings strings,
  ) {
    final toggles = <(String, bool)>[
      (strings.metricMoodLabel, scope.includeMoodMetrics),
      (strings.metricSleepLabel, scope.includeSleepEnergyAnxiety),
      (strings.personalNotesLabel, scope.includePersonalNotes),
      (strings.dossierTabCases, scope.includeSharedCases),
      (strings.sectionSymptoms, scope.includeSymptomReports),
      (strings.patientSelfReportedProfileTitle, scope.includePsychologicalProfile),
      (strings.preVisitAgendaHeader, scope.includePreVisitAgenda),
    ];

    return MindCard(
      key: const ValueKey<String>('dossier-consent-scope-footer'),
      variant: MindCardVariant.flat,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MindPressable(
            semanticLabel: strings.consentScopeBannerTitle,
            onPressed: () =>
                setState(() => _consentExpanded = !_consentExpanded),
            borderRadius: BorderRadius.circular(10),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Row(
                children: [
                  Icon(Icons.verified_user_outlined, size: 17, color: tokens.ink2),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${strings.consentScopeBannerTitle} · ${strings.daysWindowLabel(scope.windowDays)}',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: tokens.ink2,
                      ),
                    ),
                  ),
                  Icon(
                    _consentExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: tokens.ink2,
                  ),
                ],
              ),
            ),
          ),
          if (_consentExpanded) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: toggles.map((item) {
                return MindBadge(
                  icon: item.$2
                      ? Icons.check_circle_outline_rounded
                      : Icons.visibility_off_outlined,
                  label:
                      '${item.$1}: ${item.$2 ? strings.consentIncludedLabel : strings.consentWithheldLabel}',
                  backgroundColor:
                      item.$2 ? tokens.primarySoft : tokens.surface2,
                  textColor: item.$2 ? tokens.ink : tokens.ink3,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBaselineDeltaTable({
    required MindTokens tokens,
    required AppStrings strings,
    required PersonalBaseline recent,
    required PersonalBaseline baseline,
    required bool includeSomatic,
  }) {
    String fmt(double? v, [String suffix = '']) {
      if (v == null) return '--';
      if (suffix == 'h') return MindFormatters.hours(v, strings);
      return '${MindFormatters.decimal(v, strings)}$suffix';
    }

    String delta(double? r, double? b, [String suffix = '']) {
      if (r == null || b == null) return '--';
      return MindFormatters.signedDelta(r - b, strings, unit: suffix);
    }

    Widget row(
      String label,
      String recent,
      String base,
      String diff, {
      bool isHeader = false,
    }) {
      final style = TextStyle(
        fontSize: isHeader ? 12.0 : 13,
        fontWeight: isHeader ? FontWeight.w700 : FontWeight.w500,
        color: isHeader ? tokens.ink2 : tokens.ink,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(flex: 3, child: Text(label, style: style)),
            Expanded(
              flex: 2,
              child: Text(recent, textAlign: TextAlign.end, style: style),
            ),
            Expanded(
              flex: 2,
              child: Text(base, textAlign: TextAlign.end, style: style),
            ),
            Expanded(
              flex: 2,
              child: Text(diff, textAlign: TextAlign.end, style: style),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        row(
          strings.metricColumnLabel,
          strings.recent7dColumnLabel,
          strings.baselineColumnLabel,
          strings.deltaColumnLabel,
          isHeader: true,
        ),
        Divider(height: 1, color: tokens.line),
        row(
          strings.metricMoodLabel,
          fmt(recent.averageMoodIntensity),
          fmt(baseline.averageMoodIntensity),
          delta(recent.averageMoodIntensity, baseline.averageMoodIntensity),
        ),
        if (includeSomatic) ...[
          row(
            strings.metricSleepLabel,
            fmt(recent.averageSleepHours, 'h'),
            fmt(baseline.averageSleepHours, 'h'),
            delta(recent.averageSleepHours, baseline.averageSleepHours, 'h'),
          ),
          row(
            strings.metricEnergyLabel,
            fmt(recent.averageEnergyLevel),
            fmt(baseline.averageEnergyLevel),
            delta(recent.averageEnergyLevel, baseline.averageEnergyLevel),
          ),
          row(
            strings.metricAnxietyLabel,
            fmt(recent.averageAnxietyLevel),
            fmt(baseline.averageAnxietyLevel),
            delta(recent.averageAnxietyLevel, baseline.averageAnxietyLevel),
          ),
        ],
      ],
    );
  }

  Widget _buildVisitDiffCard(
    MindTokens tokens,
    AppStrings strings,
    VisitComparisonDiff diff,
    ClinicalConsentScope scope,
  ) {
    String signed(double v, [String suffix = '']) =>
        MindFormatters.signedDelta(v, strings, unit: suffix);

    final chips = <String>[
      if (diff.moodDelta != null)
        '${strings.metricMoodLabel}: ${signed(diff.moodDelta!)}',
      if (scope.includeSleepEnergyAnxiety && diff.sleepDelta != null)
        '${strings.metricSleepLabel}: ${signed(diff.sleepDelta!, 'h')}',
      if (scope.includeSleepEnergyAnxiety && diff.energyDelta != null)
        '${strings.metricEnergyLabel}: ${signed(diff.energyDelta!)}',
      if (scope.includeSleepEnergyAnxiety && diff.anxietyDelta != null)
        '${strings.metricAnxietyLabel}: ${signed(diff.anxietyDelta!)}',
      if (diff.eveningIntensityDelta != null)
        '${strings.eveningBucketLabel}: ${signed(diff.eveningIntensityDelta!)}',
    ];

    return MindCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.compare_arrows_rounded,
                size: 16,
                color: tokens.accentInk,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  strings.sinceLastVisitTitle,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: tokens.ink2,
                  ),
                ),
              ),
              MindBadge(label: strings.visitIntervalBadge(diff.daysBetween)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${strings.formatHumanDate(diff.previousGeneratedAt)} ${MindFormatters.rangeArrow(strings)} ${strings.formatHumanDate(diff.currentGeneratedAt)}',
            style: TextStyle(
              fontSize: 12.5,
              color: tokens.ink3,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (chips.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: chips.map((c) => MindBadge(label: c)).toList(),
            ),
          ],
          if (scope.includeSleepEnergyAnxiety &&
              diff.addedContextTags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              '${strings.addedContextsLabel}: '
              '${diff.addedContextTags.map((k) => DailyContextTags.localizedLabel(k, strings)).join(', ')}',
              style: TextStyle(
                fontSize: 12,
                color: tokens.ink2,
                height: 1.35,
              ),
            ),
          ],
          if (scope.includeSleepEnergyAnxiety &&
              diff.reducedContextTags.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '${strings.reducedContextsLabel}: '
              '${diff.reducedContextTags.map((k) => DailyContextTags.localizedLabel(k, strings)).join(', ')}',
              style: TextStyle(
                fontSize: 12,
                color: tokens.ink2,
                height: 1.35,
              ),
            ),
          ],
          if (scope.includePreVisitAgenda &&
              diff.focusPlanFeedback.isNotEmpty) ...[
            const SizedBox(height: 10),
            MindBadge(
              icon: Icons.event_available_outlined,
              label:
                  '${strings.focusFeedbackClinicianLabel}: ${diff.focusPlanFeedback}',
              isSelected: true,
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // VIEW 1: INTRA-DAY TRACKING TIMELINE
  // ---------------------------------------------------------------------------
  Widget _buildTimelineTab(
    ClinicianPatientRecord record,
    MindTokens tokens,
    AppStrings strings,
  ) {
    final scope = record.latestPacket.consentScope;
    final allTraces = List<MindTraceModel>.from(record.latestPacket.traces)
      ..sort((a, b) => b.effectiveTimestamp.compareTo(a.effectiveTimestamp));

    final anchor = allTraces.isNotEmpty ? allTraces.first.date : DateTime.now();
    final traces = allTraces.where((t) {
      return switch (_timelineWindow) {
        _TimelineWindow.all => true,
        _TimelineWindow.days7 => anchor.difference(t.date).inDays <= 7,
        _TimelineWindow.days30 => anchor.difference(t.date).inDays <= 30,
      };
    }).toList(growable: false);

    return ListView(
      key: PageStorageKey<String>('dossier_timeline_${record.patientId}'),
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
      children: [
        if (allTraces.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              MindPill(
                label: strings.filterAll,
                isSelected: _timelineWindow == _TimelineWindow.all,
                onTap: () =>
                    setState(() => _timelineWindow = _TimelineWindow.all),
              ),
              MindPill(
                label: MindFormatters.daysShort(7, strings),
                isSelected: _timelineWindow == _TimelineWindow.days7,
                onTap: () =>
                    setState(() => _timelineWindow = _TimelineWindow.days7),
              ),
              MindPill(
                label: MindFormatters.daysShort(30, strings),
                isSelected: _timelineWindow == _TimelineWindow.days30,
                onTap: () =>
                    setState(() => _timelineWindow = _TimelineWindow.days30),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (!scope.includePersonalNotes) ...[
          MindCard(
            variant: MindCardVariant.flat,
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(Icons.visibility_off_outlined, size: 16, color: tokens.ink2),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    strings.notesNotSharedNotice,
                    style: TextStyle(fontSize: 12.5, color: tokens.ink2),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (traces.isEmpty)
          MindCard(
            padding: const EdgeInsets.all(16),
            child: Text(
              strings.noCheckInsLoggedYetLabel,
              style: TextStyle(fontSize: 13, color: tokens.ink2),
            ),
          )
        else
          ...traces.map((t) {
            final moodOpt = trackMoodOptionFor(t.overallMood);
            final nuanced = t.nuancedEmotions;
            final somaticParts = <String>[
              if (t.sleepHours != null)
                '${strings.metricSleepLabel}: ${MindFormatters.hours(t.sleepHours!, strings)}',
              if (t.sleepQuality != null)
                '${strings.metricSleepLabel} ${t.sleepQuality}/5',
              if (t.energyLevel != null)
                '${strings.metricEnergyLabel}: ${t.energyLevel}/10',
              if (t.anxietyLevel != null)
                '${strings.metricAnxietyLabel}: ${t.anxietyLevel}/10',
              if (t.physicalTension != null)
                '${strings.physicalTensionLabel}: ${t.physicalTension}/10',
            ];

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: MindCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: moodOpt.color,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${trackMoodLabel(t.overallMood, strings)} · ${t.moodIntensity}/10',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: tokens.ink,
                            ),
                          ),
                        ),
                        Text(
                          '${strings.formatHumanDate(t.date)} · ${t.formattedTime} (${_dayBucketLabel(t.timeBucket, strings)})',
                          style: TextStyle(
                            fontSize: 12.0,
                            color: tokens.ink3,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                    if (nuanced.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: nuanced
                            .take(4)
                            .map(
                              (k) => MindBadge(
                                label: AffectTaxonomy.localizedLabel(k, strings),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    if (scope.includeSleepEnergyAnxiety &&
                        somaticParts.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        somaticParts.join(' · '),
                        style: TextStyle(
                          fontSize: 12,
                          color: tokens.ink2,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                    if (scope.includeSleepEnergyAnxiety &&
                        t.contextTags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: t.contextTags.map((k) {
                          final tag = DailyContextTags.byKey(k);
                          return MindBadge(
                            icon: tag?.icon,
                            label: DailyContextTags.localizedLabel(k, strings),
                          );
                        }).toList(),
                      ),
                    ],
                    if (scope.includePersonalNotes) ...[
                      if (t.situation != null &&
                          t.situation!.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          t.situation!.trim(),
                          style: TextStyle(fontSize: 12.5, color: tokens.ink2),
                        ),
                      ],
                      if (t.behavioralResponse != null &&
                          t.behavioralResponse!.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          t.behavioralResponse!.trim(),
                          style: TextStyle(fontSize: 12.5, color: tokens.ink2),
                        ),
                      ],
                      if (t.journalText != null &&
                          t.journalText!.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          t.journalText!.trim(),
                          style: TextStyle(
                            fontSize: 13,
                            color: tokens.ink,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // VIEW 2: PATIENT AI REFLECTIONS & SELF-LOGGED SYMPTOMS (NON-CLINICAL)
  // ---------------------------------------------------------------------------
  Widget _buildCasesTab(
    ClinicianPatientRecord record,
    MindTokens tokens,
    AppStrings strings,
  ) {
    final packet = record.latestPacket;
    final scope = packet.consentScope;
    final cases =
        packet.sharedCases.where((c) => !c.isPrivate).toList(growable: false);

    return ListView(
      key: PageStorageKey<String>('dossier_cases_${record.patientId}'),
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
      children: [
        MindCard(
          variant: MindCardVariant.flat,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lock_outline_rounded, size: 16, color: tokens.safety),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      strings.privateCasesNeverSharedNote,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: tokens.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                strings.aiReflectionNonDiagnosticBadge,
                style: TextStyle(fontSize: 12, color: tokens.ink2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Text(
          strings.sharedCasesTitle,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: tokens.ink2,
          ),
        ),
        const SizedBox(height: 8),

        if (!scope.includeSharedCases)
          MindCard(
            padding: const EdgeInsets.all(14),
            child: Text(
              strings.casesNotSharedNotice,
              style: TextStyle(fontSize: 13, color: tokens.ink2),
            ),
          )
        else if (cases.isEmpty)
          MindCard(
            padding: const EdgeInsets.all(14),
            child: Text(
              strings.noSharedReflectionsLabel,
              style: TextStyle(fontSize: 13, color: tokens.ink2),
            ),
          )
        else
          ...cases.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: MindCard(
                borderColor: c.isPausedForSafety ? tokens.safety : null,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (c.isPausedForSafety) ...[
                      MindBadge(
                        icon: Icons.warning_amber_rounded,
                        label: strings.safetyPauseAlertBadge,
                        backgroundColor: tokens.safetySoft,
                        borderColor: tokens.safety,
                        textColor: tokens.safety,
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      c.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: tokens.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${MindFormatters.shortDate(c.createdAt, strings)} · ${c.caseNumber}',
                      style: TextStyle(fontSize: 12, color: tokens.ink3),
                    ),
                    if (c.chain != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${c.chain!.trigger} ${MindFormatters.rangeArrow(strings)} '
                        '${c.chain!.thought} (${strings.localizedLabelName(c.chain!.thoughtLabel)}) '
                        '${MindFormatters.rangeArrow(strings)} ${c.chain!.behavior}',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: tokens.ink2,
                          height: 1.4,
                        ),
                      ),
                    ],
                    if (c.findingsSummary != null &&
                        c.findingsSummary!.trim().isNotEmpty &&
                        c.findingsSummary!.trim() !=
                            (c.userConclusion ?? '').trim()) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: tokens.surface2,
                          borderRadius: BorderRadius.circular(tokens.chipRadius),
                          border: Border.all(color: tokens.line),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.aiSummaryBoxLabel,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: tokens.ink2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              c.findingsSummary!.trim(),
                              style: TextStyle(
                                fontSize: 12.5,
                                color: tokens.ink,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (c.userConclusion != null &&
                        c.userConclusion!.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: tokens.cardTint,
                          borderRadius: BorderRadius.circular(tokens.chipRadius),
                          border: Border.all(color: tokens.line),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.patientTakeawayBoxLabel,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: tokens.accentInk,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              c.userConclusion!.trim(),
                              style: TextStyle(
                                fontSize: 12.5,
                                color: tokens.ink,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

        const SizedBox(height: 16),
        Text(
          strings.sharedSymptomsTitle,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: tokens.ink2,
          ),
        ),
        const SizedBox(height: 8),
        if (!scope.includeSymptomReports)
          MindCard(
            padding: const EdgeInsets.all(14),
            child: Text(
              strings.symptomsExcludedByConsentLabel,
              style: TextStyle(fontSize: 13, color: tokens.ink2),
            ),
          )
        else if (packet.symptomReports.isEmpty)
          MindCard(
            padding: const EdgeInsets.all(14),
            child: Text(
              strings.noSymptomLogsRecordedLabel,
              style: TextStyle(fontSize: 13, color: tokens.ink2),
            ),
          )
        else
          ...packet.symptomReports.map((report) {
            final details = <String>[
              if (report.onset != null && report.onset!.trim().isNotEmpty)
                report.onset!.replaceAll('_', ' '),
              if (report.somaticLocation != null &&
                  report.somaticLocation!.trim().isNotEmpty &&
                  report.somaticLocation != 'none')
                report.somaticLocation!.replaceAll('_', ' '),
              if (report.contextTrigger != null &&
                  report.contextTrigger!.trim().isNotEmpty)
                report.contextTrigger!.replaceAll('_', ' '),
            ];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: MindCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _formatDate(report.createdAt),
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: tokens.ink,
                            ),
                          ),
                        ),
                        MindBadge(label: '${report.intensity}/10'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: report.symptomIds
                          .map(
                            (id) => MindBadge(label: _symptomTitle(id, strings)),
                          )
                          .toList(),
                    ),
                    if (details.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        details.join(' · '),
                        style: TextStyle(fontSize: 12, color: tokens.ink2),
                      ),
                    ],
                    if (report.copingStrategiesTried.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: report.copingStrategiesTried
                            .map((s) => MindBadge(label: s.replaceAll('_', ' ')))
                            .toList(),
                      ),
                    ],
                    if (report.userAdaptiveAnswer != null &&
                        report.userAdaptiveAnswer!.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        report.userAdaptiveAnswer!.trim(),
                        style: TextStyle(
                          fontSize: 12.5,
                          color: tokens.ink,
                          height: 1.35,
                        ),
                      ),
                    ],
                    if (report.stabilizingStrategy != null &&
                        report.stabilizingStrategy!.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        report.stabilizingStrategy!.trim(),
                        style: TextStyle(
                          fontSize: 12,
                          color: tokens.accentInk,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // VIEW 3: CONSULTATIONS, SOAP NOTES & CLINIC ACCESS ADMIN
  // ---------------------------------------------------------------------------
  Widget _buildNotesTab(
    BuildContext context,
    ClinicianPatientRecord record,
    ClinicPatientAccount? account,
    MindTokens tokens,
    AppStrings strings,
  ) {
    final cr = record.clinicalRecord;
    return ListView(
      key: PageStorageKey<String>('dossier_notes_${record.patientId}'),
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
      children: [
        // Next Follow-Up Appointment Card
        MindCard(
          key: const ValueKey<String>('dossier-next-appointment-card'),
          variant: MindCardVariant.flat,
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.event_outlined, size: 19, color: tokens.accentInk),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.nextAppointmentTitle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: tokens.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      cr.nextAppointmentAt != null
                          ? MindFormatters.shortDate(
                              cr.nextAppointmentAt!,
                              strings,
                            )
                          : strings.noAppointmentScheduledLabel,
                      style: TextStyle(fontSize: 12.5, color: tokens.ink2),
                    ),
                  ],
                ),
              ),
              MindBadge(
                key: const ValueKey<String>('dossier-schedule-appt-btn'),
                icon: Icons.edit_calendar_outlined,
                label: strings.scheduleFollowUpBtn,
                onTap: () => ClinicianHistoryDemographicsSheet.show(
                  context,
                  patientId: record.patientId,
                  currentRecord: cr,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        MindCard(
          variant: MindCardVariant.flat,
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.shield_outlined, size: 16, color: tokens.ink2),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  strings.clinicianNotesPrivateNotice,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: tokens.ink2,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        MindButton(
          text: strings.addClinicianNoteBtn,
          variant: MindButtonVariant.soft,
          leadingIcon: Icons.note_add_outlined,
          isFullWidth: true,
          onPressed: () => _openNoteSheet(context, record),
        ),

        const SizedBox(height: 14),
        if (record.clinicianNotes.isEmpty)
          MindCard(
            padding: const EdgeInsets.all(16),
            child: Text(
              strings.noClinicianNotesYet,
              style: TextStyle(fontSize: 13, color: tokens.ink2),
            ),
          )
        else
          ...record.clinicianNotes.map(
            (note) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: MindCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        MindBadge(label: note.category.localizedLabel(strings)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            strings.formatHumanDate(note.createdAt),
                            style: TextStyle(
                              fontSize: 12.0,
                              color: tokens.ink3,
                            ),
                          ),
                        ),
                        IconButton(
                          key: ValueKey<String>('edit-note-${note.id}'),
                          tooltip: strings.editNoteTitle,
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                          icon: Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: tokens.ink2,
                          ),
                          onPressed: () =>
                              _openNoteSheet(context, record, existing: note),
                        ),
                        IconButton(
                          key: ValueKey<String>('delete-note-${note.id}'),
                          tooltip: strings.deleteEntryBtn,
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: tokens.ink2,
                          ),
                          onPressed: () => _confirmDeleteNote(
                            context,
                            record.patientId,
                            note,
                            strings,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      note.content,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: tokens.ink,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        const SizedBox(height: 16),
        if (account != null)
          _buildClinicAccessAdminCard(context, account, tokens, strings),

        MindButton(
          text: strings.sharePostVisitFocusBtn,
          variant: MindButtonVariant.soft,
          leadingIcon: Icons.send_outlined,
          isFullWidth: true,
          onPressed: () => ComposePostVisitFocusSheet.show(
            context,
            patientDisplayName: record.displayName,
            patientId: record.patientId,
          ),
        ),
        const SizedBox(height: 10),
        MindButton(
          text: strings.ehrSummaryFullBtn,
          variant: MindButtonVariant.primary,
          leadingIcon: Icons.content_copy_rounded,
          isFullWidth: true,
          onPressed: () => _copyEhrSummary(record, strings),
        ),

        // Individual delete for manually imported offline records (never demo/managed)
        if (!record.isDemoCase && account == null) ...[
          const SizedBox(height: 12),
          MindButton(
            key: const ValueKey<String>('dossier-remove-imported-btn'),
            text: strings.removeImportedPatientBtn,
            variant: MindButtonVariant.danger,
            leadingIcon: Icons.delete_outline_rounded,
            isFullWidth: true,
            onPressed: () =>
                _confirmRemoveImported(context, record.patientId, strings),
          ),
        ],
      ],
    );
  }

  Future<void> _confirmDeleteNote(
    BuildContext context,
    String patientId,
    ClinicianSessionNote note,
    AppStrings strings,
  ) async {
    final confirmed = await showMindConfirmDialog(
      context,
      title: strings.deleteNoteConfirmTitle,
      body: strings.deleteNoteConfirmBody,
      confirmLabel: strings.deleteEntryBtn,
      cancelLabel: strings.cancelBtn,
      destructive: true,
      icon: Icons.delete_outline_rounded,
    );
    if (!confirmed || !mounted) return;
    await ref.read(clinicianRosterProvider.notifier).deleteNote(
          patientId,
          note.id,
        );
    if (!context.mounted) return;
    showMindToast(context, strings.noteDeletedToast);
  }

  Future<void> _confirmRemoveImported(
    BuildContext context,
    String patientId,
    AppStrings strings,
  ) async {
    final confirmed = await showMindConfirmDialog(
      context,
      title: strings.removeImportedPatientBtn,
      body: strings.removeImportedPatientConfirm,
      confirmLabel: strings.deleteEntryBtn,
      cancelLabel: strings.cancelBtn,
      destructive: true,
      icon: Icons.delete_outline_rounded,
    );
    if (!confirmed || !mounted) return;
    await ref
        .read(clinicianRosterProvider.notifier)
        .removeImportedPatient(patientId);
    if (!context.mounted) return;
    if (!widget.embedded) {
      final nav = Navigator.of(context);
      if (nav.canPop()) {
        nav.pop();
      } else {
        GoRouter.maybeOf(context)?.go(AppRouter.clinician);
      }
    }
  }

  Future<void> _openNoteSheet(
    BuildContext context,
    ClinicianPatientRecord record, {
    ClinicianSessionNote? existing,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddClinicianNoteSheet(
        patientId: record.patientId,
        existingNote: existing,
      ),
    );
  }

  Widget _buildClinicAccessAdminCard(
    BuildContext context,
    ClinicPatientAccount account,
    MindTokens tokens,
    AppStrings strings,
  ) {
    final isPaused = account.status == ClinicAccountStatus.paused;
    final badge = _accountStatusBadgeData(account.status, tokens, strings);
    final langLabel = account.preferredLanguage == 'ar'
        ? 'العربية'
        : (account.preferredLanguage == 'fr' ? 'Français' : 'English');

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: MindCard(
        key: const ValueKey<String>('dossier-clinic-access-card'),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.admin_panel_settings_outlined,
                  size: 19,
                  color: tokens.ink,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    strings.clinicAccessAdminSection,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: tokens.ink,
                    ),
                  ),
                ),
                MindBadge(
                  label: badge.label,
                  backgroundColor: badge.bg,
                  textColor: badge.fg,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${MindFormatters.ltrIsolate(account.loginIdentifier)} · '
              '${strings.localizedAgeRange(account.ageRange)} · $langLabel',
              style: TextStyle(fontSize: 13, color: tokens.ink2),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                MindButton(
                  key: const ValueKey<String>('dossier-reset-pin-qr-btn'),
                  text: strings.resetPinAndQrBtn,
                  variant: MindButtonVariant.soft,
                  leadingIcon: Icons.qr_code_2_rounded,
                  onPressed: () =>
                      _resetPatientPinAndQr(context, account, strings),
                ),
                MindButton(
                  key: const ValueKey<String>('dossier-pause-resume-btn'),
                  text: isPaused
                      ? strings.resumePatientAccessBtn
                      : strings.pausePatientAccessBtn,
                  variant: MindButtonVariant.secondary,
                  leadingIcon: isPaused
                      ? Icons.play_circle_outline_rounded
                      : Icons.pause_circle_outline_rounded,
                  onPressed: () => _togglePauseResume(account, strings),
                ),
                MindButton(
                  key: const ValueKey<String>('dossier-edit-tracks-btn'),
                  text: strings.editCareTracksBtn,
                  variant: MindButtonVariant.secondary,
                  leadingIcon: Icons.tune_rounded,
                  onPressed: () =>
                      _editAssignedTracks(context, account, tokens, strings),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _resetPatientPinAndQr(
    BuildContext context,
    ClinicPatientAccount account,
    AppStrings strings,
  ) async {
    final confirmed = await showMindConfirmDialog(
      context,
      title: strings.resetPinConfirmTitle,
      body: strings.resetPinConfirmBody,
      confirmLabel: strings.resetPinAndQrBtn,
      cancelLabel: strings.cancelBtn,
      icon: Icons.qr_code_2_rounded,
    );
    if (!confirmed || !mounted) return;
    final res = await ref.read(clinicAuthRepositoryProvider).resetPatientAccess(
          doctorId: account.doctorId,
          patientId: account.patientId,
        );
    ref.invalidate(_dossierClinicAccountProvider(account.patientId));
    ref.invalidate(clinicDoctorAccountsProvider);
    ref.invalidate(clinicAuditLogProvider);
    if (context.mounted) {
      await CreatePatientAccountSheet.showAccessHandover(context, result: res);
    }
  }

  Future<void> _togglePauseResume(
    ClinicPatientAccount account,
    AppStrings strings,
  ) async {
    final nextStatus = account.status == ClinicAccountStatus.paused
        ? ClinicAccountStatus.active
        : ClinicAccountStatus.paused;
    await ref.read(clinicAuthRepositoryProvider).setAccountStatus(
          doctorId: account.doctorId,
          patientId: account.patientId,
          status: nextStatus,
        );
    ref.invalidate(_dossierClinicAccountProvider(account.patientId));
    ref.invalidate(clinicDoctorAccountsProvider);
    ref.invalidate(clinicAuditLogProvider);
    ref.invalidate(clinicianRosterProvider);
    if (mounted) {
      showMindToast(
        context,
        nextStatus == ClinicAccountStatus.paused
            ? strings.accountPausedToast
            : strings.accountResumedToast,
      );
    }
  }

  Future<void> _editAssignedTracks(
    BuildContext context,
    ClinicPatientAccount account,
    MindTokens tokens,
    AppStrings strings,
  ) async {
    final selected = Set<String>.from(account.assignedTrackIds);
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          backgroundColor: tokens.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: tokens.line),
          ),
          title: Text(
            strings.editCareTracksBtn,
            style: TextStyle(
              color: tokens.ink,
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: SingleChildScrollView(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ClinicalTrack.values.map((track) {
                final isSelected = selected.contains(track.id);
                return MindPressable(
                  semanticLabel: track.localizedTitle(strings),
                  selected: isSelected,
                  onPressed: () => setDialogState(() {
                    if (isSelected) {
                      selected.remove(track.id);
                    } else {
                      selected.add(track.id);
                    }
                  }),
                  borderRadius: BorderRadius.circular(tokens.chipRadius),
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? tokens.cardTint : tokens.surface2,
                      borderRadius: BorderRadius.circular(tokens.chipRadius),
                      border: Border.all(
                        color: isSelected ? tokens.primary : tokens.line,
                      ),
                    ),
                    child: Text(
                      track.localizedTitle(strings),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: tokens.ink,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              child: Text(strings.cancelBtn),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size(48, 48),
                backgroundColor: tokens.primary,
                foregroundColor: tokens.onPrimary,
              ),
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              child: Text(strings.saveChangesBtn),
            ),
          ],
        ),
      ),
    );
    if (saved != true || !mounted) return;
    await ref.read(clinicAuthRepositoryProvider).updateAssignedTracks(
          doctorId: account.doctorId,
          patientId: account.patientId,
          trackIds: selected.toList(growable: false),
        );
    ref.invalidate(_dossierClinicAccountProvider(account.patientId));
    ref.invalidate(clinicDoctorAccountsProvider);
    ref.invalidate(clinicAuditLogProvider);
    ref.invalidate(clinicianRosterProvider);
    if (context.mounted) {
      showMindToast(
        context,
        strings.saveChangesBtn,
        variant: MindToastVariant.success,
      );
    }
  }
}

class _AddClinicianNoteSheet extends ConsumerStatefulWidget {
  const _AddClinicianNoteSheet({
    required this.patientId,
    this.existingNote,
  });

  final String patientId;
  final ClinicianSessionNote? existingNote;

  @override
  ConsumerState<_AddClinicianNoteSheet> createState() =>
      _AddClinicianNoteSheetState();
}

class _AddClinicianNoteSheetState
    extends ConsumerState<_AddClinicianNoteSheet> {
  late ClinicianNoteCategory _selectedCategory;
  late final TextEditingController _bodyCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory =
        widget.existingNote?.category ?? ClinicianNoteCategory.assessment;
    _bodyCtrl = TextEditingController(text: widget.existingNote?.content ?? '');
  }

  @override
  void dispose() {
    _bodyCtrl.dispose();
    super.dispose();
  }

  /// Appends a SOAP template cleanly so existing typed notes are never erased.
  void _insertTemplate(String templateBody) {
    final current = _bodyCtrl.text.trim();
    final nextText =
        current.isEmpty ? templateBody : '$current\n\n$templateBody';
    setState(() {
      _bodyCtrl.text = nextText;
      _bodyCtrl.selection = TextSelection.collapsed(offset: nextText.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final strings = ref.watch(appStringsProvider);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final isWide = MediaQuery.sizeOf(context).width >= 840;
    final isEdit = widget.existingNote != null;

    final sheet = Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isEdit ? strings.editNoteTitle : strings.addClinicianNoteBtn,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: tokens.ink,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  strings.clinicianNoteTagLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: tokens.ink2,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ClinicianNoteCategory.values.map((cat) {
                    return MindPill(
                      label: cat.localizedLabel(strings),
                      isSelected: _selectedCategory == cat,
                      onTap: () => setState(() => _selectedCategory = cat),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Text(
                  strings.soapTemplateLabel,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: tokens.ink2,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    MindPill(
                      key: const ValueKey('soap-template-checkin'),
                      label: strings.soapCheckInBtn,
                      isSelected: false,
                      onTap: () =>
                          _insertTemplate(strings.soapTemplateBody('soap')),
                    ),
                    MindPill(
                      key: const ValueKey('soap-template-sleep'),
                      label: strings.soapSleepBtn,
                      isSelected: false,
                      onTap: () =>
                          _insertTemplate(strings.soapTemplateBody('sleep')),
                    ),
                    MindPill(
                      key: const ValueKey('soap-template-followup'),
                      label: strings.soapFollowUpBtn,
                      isSelected: false,
                      onTap: () =>
                          _insertTemplate(strings.soapTemplateBody('followup')),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _bodyCtrl,
                  maxLines: 5,
                  style: TextStyle(fontSize: 13.5, color: tokens.ink),
                  decoration: InputDecoration(
                    hintText: strings.clinicianNoteBodyHint,
                    hintStyle: TextStyle(color: tokens.ink3, fontSize: 13),
                    filled: true,
                    fillColor: tokens.surface2,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(tokens.buttonRadius),
                      borderSide: BorderSide(color: tokens.line),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                MindButton(
                  text: isEdit ? strings.saveChangesBtn : strings.saveNoteBtn,
                  isFullWidth: true,
                  isLoading: _isSaving,
                  onPressed: () async {
                    final text = _bodyCtrl.text.trim();
                    if (text.isEmpty) return;
                    setState(() => _isSaving = true);
                    final navigator = Navigator.of(context);
                    final now = DateTime.now();
                    try {
                      if (isEdit) {
                        await ref
                            .read(clinicianRosterProvider.notifier)
                            .updateNote(
                              widget.patientId,
                              widget.existingNote!.copyWith(
                                category: _selectedCategory,
                                content: text,
                                updatedAt: now,
                              ),
                            );
                      } else {
                        await ref
                            .read(clinicianRosterProvider.notifier)
                            .addNote(
                              widget.patientId,
                              ClinicianSessionNote(
                                id: 'cn_${now.millisecondsSinceEpoch}',
                                createdAt: now,
                                updatedAt: now,
                                category: _selectedCategory,
                                content: text,
                              ),
                            );
                      }
                      if (mounted) navigator.pop();
                    } finally {
                      if (mounted) setState(() => _isSaving = false);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return isWide ? Center(heightFactor: 1.0, child: sheet) : sheet;
  }
}
