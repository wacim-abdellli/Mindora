import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/router/app_router.dart';
import '../../../app/theme/mind_tokens.dart';
import '../../../core/widgets/mind_badge.dart';
import '../../../core/widgets/mind_button.dart';
import '../../../core/widgets/mind_card.dart';
import '../../../core/widgets/mind_pill.dart';
import '../../../core/widgets/mind_segmented.dart';
import '../../../core/widgets/smooth_spline_chart.dart';
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
import '../../track/presentation/widgets/track_mood_utils.dart';
import '../controllers/clinician_providers.dart';
import '../domain/clinician_models.dart';
import '../domain/visit_diff_model.dart';
import 'widgets/clinical_brief_preview_sheet.dart';
import 'widgets/compose_post_visit_focus_sheet.dart';

enum _ChartMetric { mood, sleep, energy, anxiety }

/// Four-view patient dossier (`Overview`, `Timeline`, `Cases`, `Notes`) inside
/// the Psychiatrist Workspace, strictly honoring the patient's consent scope.
class ClinicianPatientDetailScreen extends ConsumerStatefulWidget {
  const ClinicianPatientDetailScreen({
    super.key,
    required this.patientId,
    this.embedded = false,
  });

  final String patientId;
  final bool embedded;

  @override
  ConsumerState<ClinicianPatientDetailScreen> createState() =>
      _ClinicianPatientDetailScreenState();
}

class _ClinicianPatientDetailScreenState
    extends ConsumerState<ClinicianPatientDetailScreen> {
  int _segmentIndex = 0;
  _ChartMetric _chartMetric = _ChartMetric.mood;
  int? _activeSplineIndex;

  @override
  void initState() {
    super.initState();
    _scheduleMarkReviewed();
  }

  @override
  void didUpdateWidget(covariant ClinicianPatientDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.patientId != oldWidget.patientId) {
      _segmentIndex = 0;
      _chartMetric = _ChartMetric.mood;
      _activeSplineIndex = null;
      _scheduleMarkReviewed();
    }
  }

  void _scheduleMarkReviewed() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(clinicianRosterProvider.notifier).markReviewed(widget.patientId);
      }
    });
  }

  Future<void> _copyEhrSummary(
    ClinicianPatientRecord record,
    AppStrings strings,
    MindTokens tokens,
  ) async {
    final summary = ref
        .read(clinicianSyncServiceProvider)
        .generateEhrClinicalNote(record, strings);
    await Clipboard.setData(ClipboardData(text: summary));
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
      const loader = Center(child: CircularProgressIndicator(strokeWidth: 2));
      if (widget.embedded) {
        return ColoredBox(color: tokens.bg, child: loader);
      }
      return Scaffold(
        backgroundColor: tokens.bg,
        body: loader,
      );
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
    final dossierContent = Column(
      children: [
        // Header
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            widget.embedded ? 18 : 8,
            widget.embedded ? 12 : 8,
            12,
            4,
          ),
          child: Row(
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
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            patientRecord.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: tokens.ink,
                            ),
                          ),
                        ),
                        if (patientRecord.isDemoCase) ...[
                          const SizedBox(width: 8),
                          MindBadge(label: strings.demoDatasetBadge),
                        ],
                      ],
                    ),
                    Text(
                      '${strings.daysWindowLabel(patientRecord.latestPacket.consentScope.windowDays)} · '
                      '${strings.momentsLoggedLabel(patientRecord.latestPacket.traces.length)}',
                      style: TextStyle(fontSize: 12, color: tokens.ink2),
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
                  record: patientRecord,
                ),
              ),
              IconButton(
                tooltip: strings.copyEhrSummaryBtn,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                icon: Icon(Icons.content_copy_rounded, color: tokens.ink),
                onPressed: () =>
                    _copyEhrSummary(patientRecord, strings, tokens),
              ),
            ],
          ),
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
            0 => _buildOverviewTab(patientRecord, tokens, strings),
            1 => _buildTimelineTab(patientRecord, tokens, strings),
            2 => _buildCasesTab(patientRecord, tokens, strings),
            _ => _buildNotesTab(context, patientRecord, tokens, strings),
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

  // ---------------------------------------------------------------------------
  // VIEW 0: CLINICAL OVERVIEW
  // ---------------------------------------------------------------------------
  Widget _buildOverviewTab(
    ClinicianPatientRecord record,
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
            lbl = '${t.sleepHours!.toStringAsFixed(1)}h';
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
        // Consent Banner
        MindCard(
          variant: MindCardVariant.flat,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.consentScopeBannerTitle,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: tokens.ink2,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  MindBadge(label: strings.daysWindowLabel(scope.windowDays)),
                  if (scope.includeMoodMetrics)
                    MindBadge(label: strings.metricMoodLabel),
                  if (scope.includeSleepEnergyAnxiety)
                    MindBadge(label: strings.metricSleepLabel),
                  if (scope.includeSharedCases)
                    MindBadge(label: strings.dossierTabCases),
                ],
              ),
            ],
          ),
        ),

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
                    fontSize: 12,
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
                if (agenda.patientQuestion.trim().isNotEmpty)
                  Text(
                    agenda.patientQuestion.trim(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: tokens.ink,
                      height: 1.4,
                    ),
                  ),
                if (agenda.whatHelpedRecently.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    agenda.whatHelpedRecently.trim(),
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
        ],

        const SizedBox(height: 16),

        // 7-Day vs Baseline Table
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

        // Longitudinal Chart
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

        // Condition-Specific Care Track Markers (synced cleanly when consented)
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

        // Objective Baseline Shifts
        const SizedBox(height: 16),
        Text(
          strings.cohortObservationsTitle,
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
              strings.baselineSteadyBadge,
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

        // Affect Spectrum & Diurnal Rhythm
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
                            '${AffectTaxonomy.localizedLabel(e.key, strings)} (${e.value}x)',
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
                                '${_dayBucketLabel(b, strings)}: ${baseline.diurnalIntensityAverages[b]!.toStringAsFixed(1)}/10',
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],

        // Daily Context & Routine Links
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
                    '${c.occurrences}x',
                    if (c.avgMoodIntensity != null)
                      '${c.avgMoodIntensity!.toStringAsFixed(1)}/10',
                    if (c.avgSleepHours != null)
                      '${c.avgSleepHours!.toStringAsFixed(1)}h',
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

        // Observed Stabilizers (Empirical Recovery Ledger)
        if (scope.includeMoodMetrics && baseline.recoveryLedger.hasEvidence) ...[
          const SizedBox(height: 16),
          ObservedStabilizersCard(
            ledger: baseline.recoveryLedger,
            strings: strings,
          ),
        ],

        // Observed Forensic Loop (privacy-respecting: non-private cases only)
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
                  ForensicLoopMapCard(
                    loop: loop,
                    strings: strings,
                  ),
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _buildBaselineDeltaTable({
    required MindTokens tokens,
    required AppStrings strings,
    required PersonalBaseline recent,
    required PersonalBaseline baseline,
    required bool includeSomatic,
  }) {
    String fmt(double? v, [String suffix = '']) =>
        v == null ? '--' : '${v.toStringAsFixed(1)}$suffix';
    String delta(double? r, double? b, [String suffix = '']) {
      if (r == null || b == null) return '--';
      final diff = r - b;
      final sign = diff >= 0 ? '+' : '';
      return '$sign${diff.toStringAsFixed(1)}$suffix';
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
    String signed(double v, [String suffix = '']) {
      final sign = v >= 0 ? '+' : '';
      return '$sign${v.toStringAsFixed(1)}$suffix';
    }

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
              Icon(Icons.compare_arrows_rounded, size: 16, color: tokens.m1),
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
            '${strings.formatHumanDate(diff.previousGeneratedAt)} -> ${strings.formatHumanDate(diff.currentGeneratedAt)}',
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
  // VIEW 1: INTRA-DAY TIMELINE
  // ---------------------------------------------------------------------------
  Widget _buildTimelineTab(
    ClinicianPatientRecord record,
    MindTokens tokens,
    AppStrings strings,
  ) {
    final scope = record.latestPacket.consentScope;
    final traces = List<MindTraceModel>.from(record.latestPacket.traces)
      ..sort((a, b) => b.effectiveTimestamp.compareTo(a.effectiveTimestamp));

    return ListView(
      key: PageStorageKey<String>('dossier_timeline_${record.patientId}'),
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
      children: [
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
              strings.noPatientsEmptySub,
              style: TextStyle(fontSize: 13, color: tokens.ink2),
            ),
          )
        else
          ...traces.map((t) {
            final moodOpt = trackMoodOptionFor(t.overallMood);
            final nuanced = t.nuancedEmotions;
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
                        (t.sleepHours != null ||
                            t.energyLevel != null ||
                            t.anxietyLevel != null)) ...[
                      const SizedBox(height: 8),
                      Text(
                        [
                          if (t.sleepHours != null)
                            '${strings.metricSleepLabel}: ${t.sleepHours!.toStringAsFixed(1)}h',
                          if (t.energyLevel != null)
                            '${strings.metricEnergyLabel}: ${t.energyLevel}/10',
                          if (t.anxietyLevel != null)
                            '${strings.metricAnxietyLabel}: ${t.anxietyLevel}/10',
                        ].join(' · '),
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
                    if (scope.includePersonalNotes &&
                        t.journalText != null &&
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
                ),
              ),
            );
          }),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // VIEW 2: SHARED COGNITIVE CASES & SYMPTOM LOGS (READ-ONLY)
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
          child: Row(
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
              strings.noPatientsEmptySub,
              style: TextStyle(fontSize: 13, color: tokens.ink2),
            ),
          )
        else
          ...cases.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: MindCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${c.caseNumber} · ${c.title}',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: tokens.ink,
                      ),
                    ),
                    if (c.chain != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${c.chain!.trigger} -> ${c.chain!.thought} (${c.chain!.thoughtLabel.displayName}) -> ${c.chain!.behavior}',
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
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: tokens.surface2,
                          borderRadius: BorderRadius.circular(tokens.chipRadius),
                        ),
                        child: Text(
                          c.findingsSummary!.trim(),
                          style: TextStyle(
                            fontSize: 12.5,
                            color: tokens.ink,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                    if (c.userConclusion != null &&
                        c.userConclusion!.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: tokens.surface2,
                          borderRadius: BorderRadius.circular(tokens.chipRadius),
                        ),
                        child: Text(
                          c.userConclusion!.trim(),
                          style: TextStyle(
                            fontSize: 12.5,
                            color: tokens.ink,
                            height: 1.35,
                          ),
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
        if (!scope.includeSymptomReports || packet.symptomReports.isEmpty)
          MindCard(
            padding: const EdgeInsets.all(14),
            child: Text(
              strings.noPatientsEmptySub,
              style: TextStyle(fontSize: 13, color: tokens.ink2),
            ),
          )
        else
          ...packet.symptomReports.map(
            (report) => Padding(
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
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // VIEW 3: PRIVATE CLINICIAN CONSULTATION NOTES & EHR EXPORT
  // ---------------------------------------------------------------------------
  Widget _buildNotesTab(
    BuildContext context,
    ClinicianPatientRecord record,
    MindTokens tokens,
    AppStrings strings,
  ) {
    return ListView(
      key: PageStorageKey<String>('dossier_notes_${record.patientId}'),
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
      children: [
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
          onPressed: () => _openAddNoteSheet(context, record, tokens, strings),
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
                          onPressed: () => ref
                              .read(clinicianRosterProvider.notifier)
                              .deleteNote(record.patientId, note.id),
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
        MindButton(
          text: strings.sharePostVisitFocusBtn,
          variant: MindButtonVariant.soft,
          leadingIcon: Icons.send_outlined,
          isFullWidth: true,
          onPressed: () => ComposePostVisitFocusSheet.show(
            context,
            patientDisplayName: record.displayName,
          ),
        ),
        const SizedBox(height: 10),
        MindButton(
          text: strings.ehrSummaryFullBtn,
          variant: MindButtonVariant.primary,
          leadingIcon: Icons.content_copy_rounded,
          isFullWidth: true,
          onPressed: () => _copyEhrSummary(record, strings, tokens),
        ),
      ],
    );
  }

  Future<void> _openAddNoteSheet(
    BuildContext context,
    ClinicianPatientRecord record,
    MindTokens tokens,
    AppStrings strings,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddClinicianNoteSheet(patientId: record.patientId),
    );
  }
}

class _AddClinicianNoteSheet extends ConsumerStatefulWidget {
  const _AddClinicianNoteSheet({required this.patientId});

  final String patientId;

  @override
  ConsumerState<_AddClinicianNoteSheet> createState() =>
      _AddClinicianNoteSheetState();
}

class _AddClinicianNoteSheetState extends ConsumerState<_AddClinicianNoteSheet> {
  ClinicianNoteCategory _selectedCategory = ClinicianNoteCategory.assessment;
  final TextEditingController _bodyCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final strings = ref.watch(appStringsProvider);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  strings.addClinicianNoteBtn,
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
                      onTap: () => setState(
                        () => _bodyCtrl.text = strings.soapTemplateBody('soap'),
                      ),
                    ),
                    MindPill(
                      key: const ValueKey('soap-template-sleep'),
                      label: strings.soapSleepBtn,
                      isSelected: false,
                      onTap: () => setState(
                        () =>
                            _bodyCtrl.text = strings.soapTemplateBody('sleep'),
                      ),
                    ),
                    MindPill(
                      key: const ValueKey('soap-template-followup'),
                      label: strings.soapFollowUpBtn,
                      isSelected: false,
                      onTap: () => setState(
                        () => _bodyCtrl.text = strings.soapTemplateBody(
                          'followup',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _bodyCtrl,
                  maxLines: 4,
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
                  text: strings.saveNoteBtn,
                  isFullWidth: true,
                  isLoading: _isSaving,
                  onPressed: () async {
                    final text = _bodyCtrl.text.trim();
                    if (text.isEmpty) return;
                    setState(() => _isSaving = true);
                    final navigator = Navigator.of(context);
                    final now = DateTime.now();
                    try {
                      await ref.read(clinicianRosterProvider.notifier).addNote(
                            widget.patientId,
                            ClinicianSessionNote(
                              id: 'cn_${now.millisecondsSinceEpoch}',
                              createdAt: now,
                              updatedAt: now,
                              category: _selectedCategory,
                              content: text,
                            ),
                          );
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
  }
}
