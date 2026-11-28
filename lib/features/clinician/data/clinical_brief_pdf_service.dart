import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/localization/mind_formatters.dart';
import '../../../app/theme/lab_theme.dart';
import '../../../core/widgets/mind_qr_code.dart';
import '../../insights/domain/forensic_loop_model.dart';
import '../../mind_trace/domain/affect_taxonomy.dart';
import '../../mind_trace/domain/daily_context_tags.dart';
import '../../mind_trace/domain/mind_trace_model.dart';
import '../domain/clinician_models.dart';
import '../domain/post_visit_focus_model.dart';
import 'clinician_sync_service.dart';
import 'pdf_font_loader.dart';

@immutable
class ClinicalBriefRenderResult {
  const ClinicalBriefRenderResult({
    required this.pdfBytes,
    required this.previewPngBytes,
    required this.plainSummary,
    required this.hasEmbeddedQr,
    this.pageCount = 1,
    this.isVectorPdf = true,
  });

  final Uint8List pdfBytes;
  final Uint8List previewPngBytes;
  final String plainSummary;
  final bool hasEmbeddedQr;
  final int pageCount;
  final bool isVectorPdf;
}

/// Multi-page searchable vector A4 Consultation Brief renderer powered by
/// `package:pdf`, embedding bundled `Inter` and `Noto Sans Arabic` TrueType
/// fonts with automatic RTL layout, running headers/footers, native vector QR
/// codes, and zero silent truncation.
class ClinicalBriefPdfService {
  const ClinicalBriefPdfService();

  static const PdfPageFormat _a4Format = PdfPageFormat(
    595,
    842,
    marginAll: 36,
  );

  static const PdfColor _pdfInk = PdfColor.fromInt(0xFF111114);
  static const PdfColor _pdfInk2 = PdfColor.fromInt(0xFF52525B);
  static const PdfColor _pdfLine = PdfColor.fromInt(0xFFD4D4D8);
  static const PdfColor _pdfWell = PdfColor.fromInt(0xFFF4F3EF);
  static const PdfColor _pdfAccent = PdfColor.fromInt(0xFF0F766E);
  static const PdfColor _pdfSafety = PdfColor.fromInt(0xFFBE123C);
  static const PdfColor _pdfSafetySoft = PdfColor.fromInt(0xFFFFF1F2);

  static bool get _isTestEnv {
    if (kIsWeb) return false;
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  Future<ClinicalBriefRenderResult> renderConsultationBrief({
    required ClinicianPatientRecord record,
    required AppStrings strings,
    String? encryptedCode,
    ClinicianProfile? clinicianProfile,
    bool includeClinicianNotes = true,
    PostVisitFocusPlan? activeFocusPlan,
  }) async {
    const syncService = ClinicianSyncService();
    final plainSummary = syncService.generateEhrClinicalNote(record, strings);
    final fonts = await MindPdfFontLoader.load();

    final isRtl = strings.isArabic;
    final dir = isRtl ? pw.TextDirection.rtl : pw.TextDirection.ltr;
    final clean = MindPdfFontLoader.cleanForPdf;
    final trimmedCode = encryptedCode?.trim();
    final hasQr = trimmedCode != null && trimmedCode.isNotEmpty;

    final packet = record.latestPacket;
    final scope = packet.consentScope;
    final baseline = record.baseline;
    final recent = record.recentBaseline;
    final divergences = record.divergences(strings);
    final visitDiff = record.visitDiff;
    final agenda = packet.preVisitAgenda;
    final generatedAt = DateTime.now();

    final doc = pw.Document(
      version: PdfVersion.pdf_1_4,
      title: clean('${strings.clinicalBriefTitle} — ${record.displayName}'),
      author: clean(clinicianProfile?.displayName ?? 'Mindora'),
      creator: 'Mindora Clinical Workspace',
      theme: fonts.themeFor(isArabic: isRtl),
    );

    final shareableCases = packet.sharedCases
        .where((c) => !c.isPrivate)
        .toList(growable: false);

    final loop = scope.includeMoodMetrics
        ? ForensicLoopLink.synthesize(
            baseline: baseline,
            cases: scope.includeSharedCases ? shareableCases : const [],
            strings: strings,
            excludePrivateCases: true,
            includeSomatic: scope.includeSleepEnergyAnxiety,
          )
        : null;

    String fmtVal(double? v, {String unit = ''}) {
      if (v == null) return '--';
      if (unit == 'h') return clean(MindFormatters.hours(v, strings));
      return '${MindFormatters.decimal(v, strings)}$unit';
    }

    String fmtDelta(double? r, double? b, {String unit = ''}) {
      if (r == null || b == null) return '--';
      return clean(MindFormatters.signedDelta(r - b, strings, unit: unit));
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: _a4Format,
        textDirection: dir,
        header: (ctx) => _buildHeader(
          strings: strings,
          profile: clinicianProfile,
          generatedAt: generatedAt,
          isRtl: isRtl,
        ),
        footer: (ctx) => _buildFooter(
          strings: strings,
          pageNumber: ctx.pageNumber,
          pagesCount: ctx.pagesCount,
        ),
        build: (ctx) {
          final widgets = <pw.Widget>[];

          // Block 1: Patient Identity & Consent Scope
          widgets.add(
            _buildPatientIdentityBox(
              record: record,
              strings: strings,
              isRtl: isRtl,
            ),
          );
          widgets.add(pw.SizedBox(height: 12));

          // Block 1B: Clinician-Documented Clinical Summary (Diagnoses, Meds, Allergies)
          final cr = record.clinicalRecord;
          if (cr.diagnoses.isNotEmpty ||
              cr.medications.isNotEmpty ||
              cr.allergies.isNotEmpty ||
              cr.noKnownAllergies) {
            widgets.add(_sectionTitle(strings.clinicalSummaryTitle));
            widgets.add(
              _cardBox(
                children: [
                  if (cr.diagnoses.isNotEmpty)
                    _labeledLine(
                      '${strings.documentedDiagnosesTitle}:',
                      cr.diagnoses
                          .map(
                            (d) =>
                                '${d.displayTitle} (${d.certainty.localizedLabel(strings)}, ${d.status.localizedLabel(strings)})',
                          )
                          .join(isRtl ? '، ' : '; '),
                    ),
                  if (cr.medications.isNotEmpty) ...[
                    if (cr.diagnoses.isNotEmpty) pw.SizedBox(height: 3),
                    _labeledLine(
                      '${strings.currentMedicationsTitle}:',
                      cr.medications
                          .map(
                            (m) =>
                                '${m.name}${m.regimenSummary.isNotEmpty ? ' (${m.regimenSummary})' : ''} [${m.status.localizedLabel(strings)}]',
                          )
                          .join(isRtl ? '، ' : '; '),
                    ),
                  ],
                  if (cr.allergies.isNotEmpty || cr.noKnownAllergies) ...[
                    if (cr.diagnoses.isNotEmpty || cr.medications.isNotEmpty)
                      pw.SizedBox(height: 3),
                    _labeledLine(
                      '${strings.allergiesTitle}:',
                      cr.allergies.isNotEmpty
                          ? cr.allergies
                              .map(
                                (a) =>
                                    '${a.substance}${a.reaction.trim().isNotEmpty ? ' — ${a.reaction.trim()}' : ''} (${a.severity.localizedLabel(strings)})',
                              )
                              .join(isRtl ? '، ' : '; ')
                          : strings.noKnownAllergiesLabel,
                    ),
                  ],
                ],
              ),
            );
            widgets.add(pw.SizedBox(height: 12));
          }

          // Block 2: Pre-Visit Agenda & Active Focus Plan
          if (scope.includePreVisitAgenda && agenda != null && !agenda.isEmpty) {
            widgets.add(_sectionTitle(strings.preVisitAgendaHeader));
            widgets.add(
              _cardBox(
                children: [
                  if (agenda.selectedTopics.isNotEmpty)
                    _labeledLine(
                      strings.isArabic
                          ? 'المواضيع:'
                          : (strings.isFrench ? 'Sujets :' : 'Topics:'),
                      agenda.selectedTopics.join(isRtl ? '، ' : ', '),
                    ),
                  if (agenda.patientQuestion.trim().isNotEmpty)
                    _labeledLine(
                      strings.isArabic
                          ? 'سؤال المريض:'
                          : (strings.isFrench ? 'Question :' : 'Question:'),
                      agenda.patientQuestion.trim(),
                    ),
                  if (agenda.whatHelpedRecently.trim().isNotEmpty)
                    _labeledLine(
                      strings.isArabic
                          ? 'ما ساعد مؤخراً:'
                          : (strings.isFrench
                                ? 'Ce qui a aidé :'
                                : 'Helpful recently:'),
                      agenda.whatHelpedRecently.trim(),
                    ),
                  if (agenda.focusPlanFeedback.trim().isNotEmpty)
                    _labeledLine(
                      strings.isArabic
                          ? 'تعليق على خطة التركيز:'
                          : (strings.isFrench
                                ? 'Retour plan de suivi :'
                                : 'Focus plan feedback:'),
                      agenda.focusPlanFeedback.trim(),
                    ),
                ],
              ),
            );
            widgets.add(pw.SizedBox(height: 12));
          }

          if (activeFocusPlan != null && activeFocusPlan.focusItems.isNotEmpty) {
            widgets.add(_sectionTitle(strings.postVisitFocusTitle));
            widgets.add(
              _cardBox(
                children: [
                  for (final item in activeFocusPlan.focusItems)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 3),
                      child: pw.Text(
                        clean(
                          '${item.isCompleted ? '[x]' : '[ ]'} ${item.title}',
                        ),
                        style: const pw.TextStyle(fontSize: 9.5, color: _pdfInk),
                      ),
                    ),
                  if (activeFocusPlan.observationCue.trim().isNotEmpty) ...[
                    pw.SizedBox(height: 4),
                    pw.Text(
                      clean(activeFocusPlan.observationCue.trim()),
                      style: const pw.TextStyle(fontSize: 9, color: _pdfInk2),
                    ),
                  ],
                ],
              ),
            );
            widgets.add(pw.SizedBox(height: 12));
          }

          // Block 3: Objective Longitudinal Metrics Table
          widgets.add(_sectionTitle(strings.baselineTableHeader));
          widgets.add(
            pw.Table(
              border: pw.TableBorder.all(color: _pdfLine, width: 0.6),
              columnWidths: const {
                0: pw.FlexColumnWidth(2.6),
                1: pw.FlexColumnWidth(1.5),
                2: pw.FlexColumnWidth(1.5),
                3: pw.FlexColumnWidth(1.4),
              },
              children: [
                _metricRow(
                  [
                    strings.metricColumnLabel,
                    strings.recent7dColumnLabel,
                    strings.baselineColumnLabel,
                    strings.deltaColumnLabel,
                  ],
                  isHeader: true,
                ),
                _metricRow([
                  strings.metricMoodLabel,
                  fmtVal(recent.averageMoodIntensity, unit: '/10'),
                  fmtVal(baseline.averageMoodIntensity, unit: '/10'),
                  fmtDelta(
                    recent.averageMoodIntensity,
                    baseline.averageMoodIntensity,
                  ),
                ]),
                if (scope.includeSleepEnergyAnxiety) ...[
                  _metricRow([
                    strings.metricSleepLabel,
                    fmtVal(recent.averageSleepHours, unit: 'h'),
                    fmtVal(baseline.averageSleepHours, unit: 'h'),
                    fmtDelta(
                      recent.averageSleepHours,
                      baseline.averageSleepHours,
                      unit: 'h',
                    ),
                  ]),
                  _metricRow([
                    strings.metricEnergyLabel,
                    fmtVal(recent.averageEnergyLevel, unit: '/10'),
                    fmtVal(baseline.averageEnergyLevel, unit: '/10'),
                    fmtDelta(
                      recent.averageEnergyLevel,
                      baseline.averageEnergyLevel,
                    ),
                  ]),
                  _metricRow([
                    strings.metricAnxietyLabel,
                    fmtVal(recent.averageAnxietyLevel, unit: '/10'),
                    fmtVal(baseline.averageAnxietyLevel, unit: '/10'),
                    fmtDelta(
                      recent.averageAnxietyLevel,
                      baseline.averageAnxietyLevel,
                    ),
                  ]),
                ],
              ],
            ),
          );
          widgets.add(pw.SizedBox(height: 10));

          // Visit-to-Visit Comparison
          if (visitDiff != null &&
              (visitDiff.hasMetricDelta ||
                  visitDiff.focusPlanFeedback.isNotEmpty ||
                  visitDiff.addedContextTags.isNotEmpty ||
                  visitDiff.reducedContextTags.isNotEmpty)) {
            final diffParts = <String>[
              if (visitDiff.moodDelta != null)
                '${strings.metricMoodLabel}: ${clean(MindFormatters.signedDelta(visitDiff.moodDelta!, strings))}',
              if (scope.includeSleepEnergyAnxiety && visitDiff.sleepDelta != null)
                '${strings.metricSleepLabel}: ${clean(MindFormatters.signedDelta(visitDiff.sleepDelta!, strings, unit: 'h'))}',
              if (scope.includeSleepEnergyAnxiety && visitDiff.energyDelta != null)
                '${strings.metricEnergyLabel}: ${clean(MindFormatters.signedDelta(visitDiff.energyDelta!, strings))}',
              if (scope.includeSleepEnergyAnxiety &&
                  visitDiff.anxietyDelta != null)
                '${strings.metricAnxietyLabel}: ${clean(MindFormatters.signedDelta(visitDiff.anxietyDelta!, strings))}',
            ];
            widgets.add(
              _cardBox(
                children: [
                  pw.Text(
                    clean(
                      '${strings.sinceLastVisitTitle} (${MindFormatters.daysShort(visitDiff.daysBetween, strings)})',
                    ),
                    style: pw.TextStyle(
                      fontSize: 9.5,
                      fontWeight: pw.FontWeight.bold,
                      color: _pdfAccent,
                    ),
                  ),
                  if (diffParts.isNotEmpty) ...[
                    pw.SizedBox(height: 3),
                    pw.Text(
                      clean(diffParts.join('  |  ')),
                      style: const pw.TextStyle(fontSize: 9, color: _pdfInk),
                    ),
                  ],
                  if (visitDiff.addedContextTags.isNotEmpty) ...[
                    pw.SizedBox(height: 3),
                    _labeledLine(
                      '${strings.addedContextsLabel}:',
                      visitDiff.addedContextTags
                          .map((k) => DailyContextTags.localizedLabel(k, strings))
                          .join(isRtl ? '، ' : ', '),
                    ),
                  ],
                  if (visitDiff.reducedContextTags.isNotEmpty) ...[
                    pw.SizedBox(height: 2),
                    _labeledLine(
                      strings.isArabic
                          ? 'سياقات أقل تكراراً:'
                          : (strings.isFrench
                                ? 'Contextes moins fréquents :'
                                : 'Reduced contexts:'),
                      visitDiff.reducedContextTags
                          .map((k) => DailyContextTags.localizedLabel(k, strings))
                          .join(isRtl ? '، ' : ', '),
                    ),
                  ],
                ],
              ),
            );
            widgets.add(pw.SizedBox(height: 10));
          }

          // Affect Spectrum, Context Links & Stabilizers
          if (baseline.emotionFrequencyMap.isNotEmpty ||
              baseline.contextTagCorrelations.isNotEmpty ||
              baseline.recoveryLedger.hasEvidence) {
            widgets.add(_sectionTitle(strings.affectSpectrumSectionTitle));
            widgets.add(
              _cardBox(
                children: [
                  if (baseline.emotionFrequencyMap.isNotEmpty)
                    _labeledLine(
                      '${strings.recurringFeelingsLabel}:',
                      baseline.emotionFrequencyMap.entries
                          .take(6)
                          .map(
                            (e) =>
                                '${AffectTaxonomy.localizedLabel(e.key, strings)} (${MindFormatters.times(e.value, strings)})',
                          )
                          .join(isRtl ? '، ' : ', '),
                    ),
                  if (baseline.diurnalIntensityAverages.isNotEmpty) ...[
                    pw.SizedBox(height: 3),
                    _labeledLine(
                      '${strings.diurnalRhythmLabel}:',
                      DayTimeBucket.values
                          .where(
                            (b) => baseline.diurnalIntensityAverages.containsKey(b),
                          )
                          .map((b) {
                            final label = switch (b) {
                              DayTimeBucket.morning => strings.morningBucketLabel,
                              DayTimeBucket.afternoon =>
                                strings.afternoonBucketLabel,
                              DayTimeBucket.evening => strings.eveningBucketLabel,
                              DayTimeBucket.night => strings.nightBucketLabel,
                            };
                            return '$label ${MindFormatters.decimal(baseline.diurnalIntensityAverages[b]!, strings)}/10';
                          })
                          .join('  |  '),
                    ),
                  ],
                  if (scope.includeSleepEnergyAnxiety &&
                      baseline.contextTagCorrelations.isNotEmpty) ...[
                    pw.SizedBox(height: 3),
                    _labeledLine(
                      '${strings.dailyContextSectionTitle}:',
                      baseline.contextTagCorrelations
                          .take(5)
                          .map(
                            (c) =>
                                '${DailyContextTags.localizedLabel(c.tagKey, strings)} (${MindFormatters.times(c.occurrences, strings)})',
                          )
                          .join('  |  '),
                    ),
                  ],
                  if (baseline.recoveryLedger.hasEvidence) ...[
                    pw.SizedBox(height: 3),
                    _labeledLine(
                      '${strings.observedStabilizersTitle}:',
                      baseline.recoveryLedger.stabilizers
                          .take(5)
                          .map(
                            (s) =>
                                '${s.localizedLabel(strings)} (${MindFormatters.times(s.totalOccurrences, strings)})',
                          )
                          .join('  |  '),
                    ),
                  ],
                ],
              ),
            );
            widgets.add(pw.SizedBox(height: 10));
          }

          if (loop != null && loop.hasSufficientSignal) {
            widgets.add(_sectionTitle(strings.forensicLoopMapTitle));
            widgets.add(
              _cardBox(
                children: [
                  pw.Text(
                    clean(loop.compactSummary(strings)),
                    style: const pw.TextStyle(
                      fontSize: 9.2,
                      color: _pdfInk,
                      lineSpacing: 2,
                    ),
                  ),
                ],
              ),
            );
            widgets.add(pw.SizedBox(height: 10));
          }

          // Block 4: ALL Objective Baseline Shifts (zero truncation)
          widgets.add(_sectionTitle(strings.baselineShiftsHeader));
          if (divergences.isEmpty) {
            widgets.add(
              pw.Text(
                clean(strings.noShiftsDetectedLabel),
                style: const pw.TextStyle(fontSize: 9.5, color: _pdfInk2),
              ),
            );
          } else {
            for (final d in divergences) {
              widgets.add(
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 5),
                  child: _cardBox(
                    children: [
                      pw.Text(
                        clean('${d.title} (${d.timeWindow})'),
                        style: pw.TextStyle(
                          fontSize: 9.5,
                          fontWeight: pw.FontWeight.bold,
                          color: _pdfInk,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        clean(d.baselineComparison),
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: _pdfInk2,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          }
          widgets.add(pw.SizedBox(height: 10));

          // Block 5: Patient-Reported & AI-Assisted Reflections (strict provenance split)
          widgets.add(_sectionTitle(strings.sharedReflectionsTab));
          if (!scope.includeSharedCases) {
            widgets.add(
              pw.Text(
                clean(
                  strings.isArabic
                      ? 'مستثناة بموافقة المريض.'
                      : (strings.isFrench
                            ? 'Exclues par consentement du patient.'
                            : 'Excluded by patient consent.'),
                ),
                style: const pw.TextStyle(fontSize: 9.5, color: _pdfInk2),
              ),
            );
          } else if (shareableCases.isEmpty) {
            widgets.add(
              pw.Text(
                clean(strings.noSharedReflectionsLabel),
                style: const pw.TextStyle(fontSize: 9.5, color: _pdfInk2),
              ),
            );
          } else {
            for (final c in shareableCases) {
              final hasAiSummary = c.findingsSummary != null &&
                  c.findingsSummary!.trim().isNotEmpty;
              final hasPatientTakeaway = c.userConclusion != null &&
                  c.userConclusion!.trim().isNotEmpty;
              widgets.add(
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 6),
                  child: _cardBox(
                    borderColor: c.isPausedForSafety ? _pdfSafety : _pdfLine,
                    bgColor: c.isPausedForSafety ? _pdfSafetySoft : _pdfWell,
                    children: [
                      pw.Text(
                        clean('${c.caseNumber} — ${c.title}'),
                        style: pw.TextStyle(
                          fontSize: 9.5,
                          fontWeight: pw.FontWeight.bold,
                          color: _pdfInk,
                        ),
                      ),
                      if (c.chain != null) ...[
                        pw.SizedBox(height: 3),
                        pw.Text(
                          clean(
                            '${c.chain!.trigger} ${MindFormatters.rangeArrow(strings)} ${c.chain!.thought} (${strings.localizedLabelName(c.chain!.thoughtLabel)}) ${MindFormatters.rangeArrow(strings)} ${c.chain!.emotion} (${c.chain!.emotionIntensity}/10)',
                          ),
                          style: const pw.TextStyle(
                            fontSize: 8.8,
                            color: _pdfInk2,
                          ),
                        ),
                      ],
                      if (hasAiSummary) ...[
                        pw.SizedBox(height: 3),
                        _labeledLine(
                          strings.isArabic
                              ? 'ملخص مساعد Mindora الذكي (غير تشخيصي):'
                              : (strings.isFrench
                                    ? 'Synthèse IA Mindora (non diagnostique) :'
                                    : 'AI-Generated Summary (non-diagnostic):'),
                          c.findingsSummary!.trim(),
                        ),
                      ],
                      if (hasPatientTakeaway) ...[
                        pw.SizedBox(height: 3),
                        _labeledLine(
                          strings.isArabic
                              ? 'خلاصة المريض بنفسه:'
                              : (strings.isFrench
                                    ? 'Conclusion rédigée par le patient :'
                                    : 'Patient’s Own Takeaway:'),
                          c.userConclusion!.trim(),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }
          }

          // Self-logged Symptom Observations
          if (scope.includeSymptomReports && packet.symptomReports.isNotEmpty) {
            widgets.add(pw.SizedBox(height: 8));
            widgets.add(_sectionTitle(strings.sectionSymptoms));
            for (final rep in packet.symptomReports) {
              final dateStr = MindFormatters.shortDate(rep.createdAt, strings);
              final items = rep.symptomIds.join(', ');
              final noteText = (rep.userAdaptiveAnswer ?? '').trim();
              widgets.add(
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Text(
                    clean(
                      '• $dateStr — $items (${rep.intensity}/10)${noteText.isNotEmpty ? ' · $noteText' : ''}',
                    ),
                    style: const pw.TextStyle(fontSize: 9, color: _pdfInk),
                  ),
                ),
              );
            }
          }

          // Block 6: Clinician Consultation Notes (toggled ON for archive, OFF for patient handout)
          if (includeClinicianNotes && record.clinicianNotes.isNotEmpty) {
            widgets.add(pw.SizedBox(height: 10));
            widgets.add(_sectionTitle(strings.clinicianNotesTab));
            for (final note in record.clinicianNotes) {
              final dateStr = MindFormatters.shortDate(note.createdAt, strings);
              widgets.add(
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 5),
                  child: _cardBox(
                    children: [
                      pw.Text(
                        clean('$dateStr · ${note.category.shortCode}'),
                        style: pw.TextStyle(
                          fontSize: 8.5,
                          fontWeight: pw.FontWeight.bold,
                          color: _pdfInk2,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        clean(note.content.trim()),
                        style: const pw.TextStyle(
                          fontSize: 9.2,
                          color: _pdfInk,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          }

          // Native Vector QR Block (if encrypted code provided)
          if (hasQr) {
            pw.Widget? qrWidget;
            try {
              qrWidget = pw.BarcodeWidget(
                barcode: pw.Barcode.qrCode(),
                data: trimmedCode,
                width: 108,
                height: 108,
                drawText: false,
              );
            } catch (_) {
              qrWidget = null;
            }
            if (qrWidget != null) {
              widgets.add(pw.SizedBox(height: 12));
              widgets.add(
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: _pdfWell,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: _pdfLine, width: 0.7),
                  ),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.all(6),
                        color: PdfColors.white,
                        child: qrWidget,
                      ),
                      pw.SizedBox(width: 12),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              clean(strings.encryptedQrHeader),
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                                color: _pdfInk,
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              clean(strings.qrOfflineTransferHint),
                              style: const pw.TextStyle(
                                fontSize: 8.8,
                                color: _pdfInk2,
                                lineSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          }

          return widgets;
        },
      ),
    );

    final pdfBytes = await doc.save();
    final pageCount = doc.document.pdfPageList.pages.length;

    // Generate crisp Page-1 PNG preview thumbnail (live rasterizer on devices,
    // reliable pure-Flutter canvas cover preview in headless test environments).
    Uint8List? previewPng;
    if (!_isTestEnv) {
      try {
        await for (final page in Printing.raster(pdfBytes, pages: const [0], dpi: 110)) {
          previewPng = await page.toPng();
          break;
        }
      } catch (_) {
        previewPng = null;
      }
    }
    previewPng ??= await _renderFallbackCoverPng(
      record: record,
      strings: strings,
      clinicianProfile: clinicianProfile,
      encryptedCode: hasQr ? trimmedCode : null,
      pageCount: pageCount,
    );

    return ClinicalBriefRenderResult(
      pdfBytes: pdfBytes,
      previewPngBytes: previewPng,
      plainSummary: plainSummary,
      hasEmbeddedQr: hasQr,
      pageCount: pageCount,
      isVectorPdf: true,
    );
  }

  pw.Widget _buildHeader({
    required AppStrings strings,
    required ClinicianProfile? profile,
    required DateTime generatedAt,
    required bool isRtl,
  }) {
    final clean = MindPdfFontLoader.cleanForPdf;
    final doctorLine = profile != null
        ? [
            profile.displayName,
            if (profile.specialty.trim().isNotEmpty) profile.specialty.trim(),
            if (profile.clinicName.trim().isNotEmpty) profile.clinicName.trim(),
            if (profile.licenseRef.trim().isNotEmpty)
              profile.licenseRef.trim(),
          ].join(' · ')
        : 'Mindora Clinical Workspace';

    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 8),
      margin: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _pdfLine, width: 0.8)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  clean('Mindora — ${strings.clinicalBriefTitle}'),
                  style: pw.TextStyle(
                    fontSize: 13.5,
                    fontWeight: pw.FontWeight.bold,
                    color: _pdfInk,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  clean(doctorLine),
                  style: const pw.TextStyle(fontSize: 8.5, color: _pdfInk2),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 3,
                ),
                decoration: pw.BoxDecoration(
                  color: _pdfWell,
                  borderRadius: pw.BorderRadius.circular(4),
                  border: pw.Border.all(color: _pdfLine, width: 0.5),
                ),
                child: pw.Text(
                  clean(strings.confidentialRecordBadge),
                  style: pw.TextStyle(
                    fontSize: 7.5,
                    fontWeight: pw.FontWeight.bold,
                    color: _pdfInk,
                  ),
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                clean(MindFormatters.shortDate(generatedAt, strings)),
                style: const pw.TextStyle(fontSize: 8, color: _pdfInk2),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter({
    required AppStrings strings,
    required int pageNumber,
    required int pagesCount,
  }) {
    final clean = MindPdfFontLoader.cleanForPdf;
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 6),
      margin: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _pdfLine, width: 0.6)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Text(
              clean(strings.clinicalBoundaryNote),
              style: const pw.TextStyle(fontSize: 7.5, color: _pdfInk2),
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Text(
            clean(strings.pageOfPagesLabel(pageNumber, pagesCount)),
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: _pdfInk,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPatientIdentityBox({
    required ClinicianPatientRecord record,
    required AppStrings strings,
    required bool isRtl,
  }) {
    final clean = MindPdfFontLoader.cleanForPdf;
    final packet = record.latestPacket;
    final scope = packet.consentScope;
    final demoTag = record.isDemoCase
        ? (strings.isArabic
              ? ' [نموذج تجريبي]'
              : (strings.isFrench ? ' [DÉMO]' : ' [DEMO]'))
        : '';

    final consentParts = <String>[
      if (scope.includeMoodMetrics) strings.metricMoodLabel,
      if (scope.includeSleepEnergyAnxiety) strings.metricSleepLabel,
      if (scope.includeSymptomReports) strings.sectionSymptoms,
      if (scope.includeSharedCases) strings.sharedReflectionsTab,
    ];

    return _cardBox(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
              child: pw.Text(
                clean('${record.displayName}$demoTag'),
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: _pdfInk,
                ),
              ),
            ),
            pw.Directionality(
              textDirection: pw.TextDirection.ltr,
              child: pw.Text(
                packet.packetId,
                style: const pw.TextStyle(fontSize: 8.5, color: _pdfInk2),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          clean(
            '${MindFormatters.daysShort(scope.windowDays, strings)} · ${strings.daysTrackedBadge(packet.traces.length)} · ${consentParts.join(isRtl ? '، ' : ', ')}',
          ),
          style: const pw.TextStyle(fontSize: 8.8, color: _pdfInk2),
        ),
      ],
    );
  }

  pw.Widget _sectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Text(
        MindPdfFontLoader.cleanForPdf(title),
        style: pw.TextStyle(
          fontSize: 10.5,
          fontWeight: pw.FontWeight.bold,
          color: _pdfInk,
        ),
      ),
    );
  }

  pw.Widget _cardBox({
    required List<pw.Widget> children,
    PdfColor borderColor = _pdfLine,
    PdfColor bgColor = _pdfWell,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(9),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: borderColor, width: 0.6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  pw.Widget _labeledLine(String label, String value) {
    final clean = MindPdfFontLoader.cleanForPdf;
    return pw.RichText(
      text: pw.TextSpan(
        children: [
          pw.TextSpan(
            text: '${clean(label)} ',
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: _pdfInk,
            ),
          ),
          pw.TextSpan(
            text: clean(value),
            style: const pw.TextStyle(fontSize: 9, color: _pdfInk2),
          ),
        ],
      ),
    );
  }

  pw.TableRow _metricRow(List<String> cells, {bool isHeader = false}) {
    final clean = MindPdfFontLoader.cleanForPdf;
    return pw.TableRow(
      decoration: isHeader ? const pw.BoxDecoration(color: _pdfWell) : null,
      children: [
        for (var i = 0; i < cells.length; i++)
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 5),
            child: i > 0 && !isHeader
                ? pw.Directionality(
                    textDirection: pw.TextDirection.ltr,
                    child: pw.Text(
                      clean(cells[i]),
                      textAlign: pw.TextAlign.right,
                      style: const pw.TextStyle(fontSize: 9, color: _pdfInk),
                    ),
                  )
                : pw.Text(
                    clean(cells[i]),
                    textAlign: i == 0 ? pw.TextAlign.left : pw.TextAlign.right,
                    style: pw.TextStyle(
                      fontSize: isHeader ? 8.5 : 9,
                      fontWeight: isHeader
                          ? pw.FontWeight.bold
                          : pw.FontWeight.normal,
                      color: isHeader ? _pdfInk2 : _pdfInk,
                    ),
                  ),
          ),
      ],
    );
  }

  /// Headless-safe Page-1 cover PNG thumbnail used when platform PDF rasterizer
  /// is unavailable (e.g. unit/widget tests).
  Future<Uint8List> _renderFallbackCoverPng({
    required ClinicianPatientRecord record,
    required AppStrings strings,
    required ClinicianProfile? clinicianProfile,
    required String? encryptedCode,
    required int pageCount,
  }) async {
    const w = 620.0;
    const h = 877.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, w, h),
      Paint()..color = const Color(0xFFFFFFFF),
    );

    final isRtl = strings.isArabic;
    final textDir = isRtl ? TextDirection.rtl : TextDirection.ltr;
    final align = isRtl ? TextAlign.right : TextAlign.left;
    const margin = 38.0;
    const contentW = w - margin * 2;
    var y = margin;

    double paintText(
      String text, {
      required double size,
      FontWeight weight = FontWeight.w400,
      Color color = const Color(0xFF111114),
    }) {
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontFamily: LabTheme.fontFamily,
            fontFamilyFallback: LabTheme.fontFallback,
            fontSize: size,
            fontWeight: weight,
            color: color,
            height: 1.35,
          ),
        ),
        textAlign: align,
        textDirection: textDir,
      )..layout(maxWidth: contentW);
      final drawX = isRtl ? (margin + contentW - tp.width) : margin;
      tp.paint(canvas, Offset(drawX, y));
      return tp.height;
    }

    y += paintText(
      'Mindora — ${strings.clinicalBriefTitle}',
      size: 16,
      weight: FontWeight.w700,
    );
    y += 4;
    if (clinicianProfile != null) {
      y += paintText(
        '${clinicianProfile.displayName} · ${clinicianProfile.clinicName}',
        size: 10.5,
        color: const Color(0xFF52525B),
      );
      y += 6;
    }
    canvas.drawLine(
      Offset(margin, y),
      Offset(w - margin, y),
      Paint()
        ..color = const Color(0xFFD4D4D8)
        ..strokeWidth = 1.2,
    );
    y += 12;
    y += paintText(
      '${record.displayName} · ${strings.pdfPagesBadge(pageCount)}',
      size: 13,
      weight: FontWeight.w700,
    );
    y += 8;

    final recent = record.recentBaseline;
    final base = record.baseline;
    y += paintText(
      '${strings.metricMoodLabel}: ${recent.averageMoodIntensity?.toStringAsFixed(1) ?? '--'}/10  |  ${strings.metricSleepLabel}: ${recent.averageSleepHours != null ? MindFormatters.hours(recent.averageSleepHours!, strings) : '--'}  (${strings.baselineColumnLabel}: ${base.averageSleepHours != null ? MindFormatters.hours(base.averageSleepHours!, strings) : '--'})',
      size: 10.5,
      color: const Color(0xFF52525B),
    );
    y += 12;

    if (encryptedCode != null) {
      final matrix = MindQrCodeEncoder.encode(encryptedCode);
      if (matrix != null) {
        const qrSize = 112.0;
        final cell = qrSize / matrix.size;
        final qrX = isRtl ? margin : (w - margin - qrSize);
        final darkPaint = Paint()..color = const Color(0xFF000000);
        for (var r = 0; r < matrix.size; r++) {
          for (var c = 0; c < matrix.size; c++) {
            if (matrix.isDark(r, c)) {
              canvas.drawRect(
                Rect.fromLTWH(qrX + c * cell, y + r * cell, cell, cell),
                darkPaint,
              );
            }
          }
        }
      }
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(w.toInt(), h.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  /// Writes PDF bytes to [directory] (or system temp for legacy direct callers).
  Future<String> savePdfToLocalFile(
    Uint8List pdfBytes, {
    required String fileName,
    Directory? directory,
  }) async {
    final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final targetDir = directory ?? Directory.systemTemp;
    await targetDir.create(recursive: true);
    final file = File('${targetDir.path}${Platform.pathSeparator}$safeName');
    await file.writeAsBytes(pdfBytes, flush: true);
    return file.path;
  }
}
