import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/theme/lab_theme.dart';
import '../../../core/widgets/mind_qr_code.dart';
import '../../insights/domain/forensic_loop_model.dart';
import '../../mind_trace/domain/affect_taxonomy.dart';
import '../../mind_trace/domain/daily_context_tags.dart';
import '../../mind_trace/domain/mind_trace_model.dart';
import '../domain/clinician_models.dart';
import 'clinician_sync_service.dart';

@immutable
class ClinicalBriefRenderResult {
  const ClinicalBriefRenderResult({
    required this.pdfBytes,
    required this.previewPngBytes,
    required this.plainSummary,
    required this.hasEmbeddedQr,
  });

  final Uint8List pdfBytes;
  final Uint8List previewPngBytes;
  final String plainSummary;
  final bool hasEmbeddedQr;
}

/// Pure-Dart 1-page A4 Consultation Brief renderer outputting both crisp
/// PNG previews (rendered with Inter & Noto Sans Arabic) and compliant
/// monochrome PDF 1.4 (`%PDF-1.4`) bytes without external native plugins.
class ClinicalBriefPdfService {
  const ClinicalBriefPdfService();

  static const double _pageW = 1240.0;
  static const double _pageH = 1754.0;

  Future<ClinicalBriefRenderResult> renderConsultationBrief({
    required ClinicianPatientRecord record,
    required AppStrings strings,
    String? encryptedCode,
  }) async {
    const syncService = ClinicianSyncService();
    final plainSummary = syncService.generateEhrClinicalNote(record, strings);

    final qrMatrix = (encryptedCode != null && encryptedCode.trim().isNotEmpty)
        ? MindQrCodeEncoder.encode(encryptedCode.trim())
        : null;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, _pageW, _pageH));

    // Print-ready pure white page ground
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, _pageW, _pageH),
      Paint()..color = const Color(0xFFFFFFFF),
    );

    final isRtl = strings.isArabic;
    final textDir = isRtl ? TextDirection.rtl : TextDirection.ltr;
    final align = isRtl ? TextAlign.right : TextAlign.left;
    final font = isRtl ? 'Noto Sans Arabic' : LabTheme.fontFamily;
    final fallback = LabTheme.fontFallback;

    const margin = 72.0;
    const contentW = _pageW - margin * 2;
    var y = margin;

    const ink = Color(0xFF0A0A0A);
    const ink2 = Color(0xFF4A5058);
    const lineColor = Color(0xFFD0D5DD);
    const boxBg = Color(0xFFF6F7F9);

    double drawText(
      String text, {
      required double x,
      required double top,
      required double maxWidth,
      required double fontSize,
      FontWeight weight = FontWeight.w400,
      Color color = ink,
      double lineHeight = 1.38,
    }) {
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontFamily: font,
            fontFamilyFallback: fallback,
            fontSize: fontSize,
            fontWeight: weight,
            color: color,
            height: lineHeight,
          ),
        ),
        textAlign: align,
        textDirection: textDir,
      )..layout(maxWidth: maxWidth);
      final drawX = isRtl ? (x + maxWidth - tp.width) : x;
      tp.paint(canvas, Offset(drawX, top));
      return tp.height;
    }

    // Header
    final title = strings.isArabic
        ? 'Mindora — ملخص استشارة سريري'
        : (strings.isFrench
              ? 'Mindora — SYNTHÈSE DE CONSULTATION'
              : 'Mindora — CLINICAL CONSULTATION BRIEF');
    y += drawText(
      title,
      x: margin,
      top: y,
      maxWidth: contentW,
      fontSize: 28,
      weight: FontWeight.w700,
    );
    y += 8;
    y += drawText(
      strings.clinicalBriefSubtitle,
      x: margin,
      top: y,
      maxWidth: contentW,
      fontSize: 18,
      color: ink2,
    );
    y += 18;
    canvas.drawLine(
      Offset(margin, y),
      Offset(_pageW - margin, y),
      Paint()
        ..color = ink
        ..strokeWidth = 2.0,
    );
    y += 20;

    // Patient metadata strip
    final packet = record.latestPacket;
    final scope = packet.consentScope;
    final metaLine =
        '${record.displayName}${record.isDemoCase ? ' [DEMO]' : ''} · '
        '${strings.daysWindowLabel(scope.windowDays)} · '
        '${strings.momentsLoggedLabel(packet.traces.length)} · '
        'ID: ${packet.packetId}';
    y += drawText(
      metaLine,
      x: margin,
      top: y,
      maxWidth: contentW,
      fontSize: 18,
      weight: FontWeight.w600,
    );
    y += 24;

    void drawSectionHeader(String heading) {
      y += drawText(
        heading,
        x: margin,
        top: y,
        maxWidth: contentW,
        fontSize: 17,
        weight: FontWeight.w700,
        color: ink2,
      );
      y += 6;
      canvas.drawLine(
        Offset(margin, y),
        Offset(_pageW - margin, y),
        Paint()
          ..color = lineColor
          ..strokeWidth = 1.2,
      );
      y += 12;
    }

    // 1. Pre-visit Agenda & Focus Feedback
    final agenda = packet.preVisitAgenda;
    if (scope.includePreVisitAgenda && agenda != null && !agenda.isEmpty) {
      drawSectionHeader(strings.preVisitAgendaSectionTitle);
      final lines = <String>[
        if (agenda.selectedTopics.isNotEmpty)
          '${strings.preVisitTopicsLabel}: ${agenda.selectedTopics.join(', ')}',
        if (agenda.patientQuestion.trim().isNotEmpty)
          'Question: ${agenda.patientQuestion.trim()}',
        if (agenda.whatHelpedRecently.trim().isNotEmpty)
          'Helpful recently: ${agenda.whatHelpedRecently.trim()}',
        if (agenda.focusPlanFeedback.trim().isNotEmpty)
          '${strings.focusFeedbackClinicianLabel}: ${agenda.focusPlanFeedback.trim()}',
      ];
      for (final line in lines) {
        y += drawText(
          line,
          x: margin,
          top: y,
          maxWidth: contentW,
          fontSize: 17,
        );
        y += 6;
      }
      y += 16;
    }

    // 2. Baseline & Visit Diff
    final baseline = record.baseline;
    final recent = record.recentBaseline;
    drawSectionHeader(strings.recentVsBaselineTitle);
    String fmt(double? v, [String suffix = '']) =>
        v == null ? '--' : '${v.toStringAsFixed(1)}$suffix';
    String delta(double? r, double? b, [String suffix = '']) {
      if (r == null || b == null) return '--';
      final d = r - b;
      return '${d >= 0 ? '+' : ''}${d.toStringAsFixed(1)}$suffix';
    }

    final metricLines = <String>[
      '${strings.metricMoodLabel}: 7d ${fmt(recent.averageMoodIntensity, '/10')} '
          '| Baseline ${fmt(baseline.averageMoodIntensity, '/10')} '
          '(${delta(recent.averageMoodIntensity, baseline.averageMoodIntensity)})',
      if (scope.includeSleepEnergyAnxiety) ...[
        '${strings.metricSleepLabel}: 7d ${fmt(recent.averageSleepHours, 'h')} '
            '| Baseline ${fmt(baseline.averageSleepHours, 'h')} '
            '(${delta(recent.averageSleepHours, baseline.averageSleepHours, 'h')})',
        '${strings.metricEnergyLabel}: 7d ${fmt(recent.averageEnergyLevel, '/10')} '
            '| Baseline ${fmt(baseline.averageEnergyLevel, '/10')} '
            '(${delta(recent.averageEnergyLevel, baseline.averageEnergyLevel)})',
        '${strings.metricAnxietyLabel}: 7d ${fmt(recent.averageAnxietyLevel, '/10')} '
            '| Baseline ${fmt(baseline.averageAnxietyLevel, '/10')} '
            '(${delta(recent.averageAnxietyLevel, baseline.averageAnxietyLevel)})',
      ],
    ];
    for (final line in metricLines) {
      y += drawText(line, x: margin, top: y, maxWidth: contentW, fontSize: 17);
      y += 6;
    }

    final visitDiff = record.visitDiff;
    if (visitDiff != null && visitDiff.hasMetricDelta) {
      y += 8;
      final diffParts = <String>[
        if (visitDiff.moodDelta != null)
          '${strings.metricMoodLabel}: ${visitDiff.moodDelta! >= 0 ? '+' : ''}${visitDiff.moodDelta!.toStringAsFixed(1)}',
        if (scope.includeSleepEnergyAnxiety && visitDiff.sleepDelta != null)
          '${strings.metricSleepLabel}: ${visitDiff.sleepDelta! >= 0 ? '+' : ''}${visitDiff.sleepDelta!.toStringAsFixed(1)}h',
        if (visitDiff.eveningIntensityDelta != null)
          '${strings.eveningBucketLabel}: ${visitDiff.eveningIntensityDelta! >= 0 ? '+' : ''}${visitDiff.eveningIntensityDelta!.toStringAsFixed(1)}',
      ];
      y += drawText(
        '${strings.sinceLastVisitTitle} (${strings.visitIntervalBadge(visitDiff.daysBetween)}): ${diffParts.join(' · ')}',
        x: margin,
        top: y,
        maxWidth: contentW,
        fontSize: 16,
        weight: FontWeight.w600,
      );
    }
    y += 20;

    // 3. Affect Spectrum, Context Links & Observed Stabilizers
    final footerHeight = qrMatrix != null ? 240.0 : 90.0;
    final bodyMaxY = _pageH - margin - footerHeight;

    if (y < bodyMaxY - 80 &&
        (baseline.emotionFrequencyMap.isNotEmpty ||
            baseline.diurnalIntensityAverages.isNotEmpty ||
            baseline.contextTagCorrelations.isNotEmpty ||
            baseline.recoveryLedger.hasEvidence)) {
      drawSectionHeader(strings.affectSpectrumSectionTitle);

      if (baseline.emotionFrequencyMap.isNotEmpty && y < bodyMaxY - 40) {
        final emotionsText = baseline.emotionFrequencyMap.entries
            .take(5)
            .map(
              (e) =>
                  '${AffectTaxonomy.localizedLabel(e.key, strings)} (${e.value}x)',
            )
            .join(', ');
        y += drawText(
          emotionsText,
          x: margin,
          top: y,
          maxWidth: contentW,
          fontSize: 17,
        );
        y += 8;
      }

      if (baseline.diurnalIntensityAverages.isNotEmpty && y < bodyMaxY - 40) {
        final diurnalParts = DayTimeBucket.values
            .where((b) => baseline.diurnalIntensityAverages.containsKey(b))
            .map((b) {
              final lbl = switch (b) {
                DayTimeBucket.morning => strings.morningBucketLabel,
                DayTimeBucket.afternoon => strings.afternoonBucketLabel,
                DayTimeBucket.evening => strings.eveningBucketLabel,
                DayTimeBucket.night => strings.nightBucketLabel,
              };
              return '$lbl: ${baseline.diurnalIntensityAverages[b]!.toStringAsFixed(1)}/10';
            })
            .join(' · ');
        y += drawText(
          diurnalParts,
          x: margin,
          top: y,
          maxWidth: contentW,
          fontSize: 17,
        );
        y += 10;
      }

      if (scope.includeSleepEnergyAnxiety &&
          baseline.contextTagCorrelations.isNotEmpty &&
          y < bodyMaxY - 50) {
        final tagLines = baseline.contextTagCorrelations
            .take(4)
            .map((c) {
              final label = DailyContextTags.localizedLabel(c.tagKey, strings);
              final mood = c.avgMoodIntensity != null
                  ? ', ${c.avgMoodIntensity!.toStringAsFixed(1)}/10'
                  : '';
              final sleep = c.avgSleepHours != null
                  ? ', ${c.avgSleepHours!.toStringAsFixed(1)}h'
                  : '';
              return '$label (${c.occurrences}x$mood$sleep)';
            })
            .join(' | ');
        y += drawText(
          '${strings.dailyContextSectionTitle}: $tagLines',
          x: margin,
          top: y,
          maxWidth: contentW,
          fontSize: 16,
        );
        y += 10;
      }

      if (scope.includeMoodMetrics &&
          baseline.recoveryLedger.hasEvidence &&
          y < bodyMaxY - 50) {
        final stabs = baseline.recoveryLedger.stabilizers
            .take(4)
            .map((s) {
              final label = s.localizedLabel(strings);
              final shift = s.avgSameDayShift != null && s.avgSameDayShift! < 0
                  ? ' (${s.avgSameDayShift!.toStringAsFixed(1)}/10)'
                  : '';
              return '$label (${s.totalOccurrences}x)$shift';
            })
            .join(' | ');
        y += drawText(
          '${strings.observedStabilizersTitle}: $stabs',
          x: margin,
          top: y,
          maxWidth: contentW,
          fontSize: 16,
          weight: FontWeight.w600,
        );
        y += 14;
      }

      if (scope.includeMoodMetrics && y < bodyMaxY - 55) {
        final loop = ForensicLoopLink.synthesize(
          baseline: baseline,
          cases: scope.includeSharedCases ? packet.sharedCases : const [],
          strings: strings,
          excludePrivateCases: true,
          includeSomatic: scope.includeSleepEnergyAnxiety,
        );
        if (loop.hasSufficientSignal) {
          y += drawText(
            '${strings.forensicLoopMapTitle}: ${loop.compactSummary(strings)}',
            x: margin,
            top: y,
            maxWidth: contentW,
            fontSize: 15,
            color: ink2,
          );
          y += 12;
        }
      }
    }

    // 4. Objective Baseline Divergences
    final divergences = record.divergences(strings);
    if (divergences.isNotEmpty && y < bodyMaxY - 60) {
      drawSectionHeader(strings.cohortObservationsTitle);
      for (final d in divergences.take(3)) {
        if (y >= bodyMaxY - 40) break;
        y += drawText(
          '• ${d.title}: ${d.baselineComparison}',
          x: margin,
          top: y,
          maxWidth: contentW,
          fontSize: 16,
        );
        y += 6;
      }
    }

    // Footer + optional embedded encrypted handoff QR
    final footerTop = _pageH - margin - footerHeight + 16;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(margin, footerTop, contentW, footerHeight - 24),
        const Radius.circular(12),
      ),
      Paint()..color = boxBg,
    );

    if (qrMatrix != null) {
      const qrBoxSize = 168.0;
      final qrX = isRtl ? margin + 20 : _pageW - margin - qrBoxSize - 20;
      final qrY = footerTop + 20;
      canvas.drawRect(
        Rect.fromLTWH(qrX, qrY, qrBoxSize, qrBoxSize),
        Paint()..color = const Color(0xFFFFFFFF),
      );
      const qQuiet = 2;
      final cell = qrBoxSize / (qrMatrix.size + qQuiet * 2);
      final dark = Paint()..color = const Color(0xFF000000);
      for (var r = 0; r < qrMatrix.size; r++) {
        for (var c = 0; c < qrMatrix.size; c++) {
          if (qrMatrix.isDark(r, c)) {
            canvas.drawRect(
              Rect.fromLTWH(
                qrX + (c + qQuiet) * cell,
                qrY + (r + qQuiet) * cell,
                cell + 0.15,
                cell + 0.15,
              ),
              dark,
            );
          }
        }
      }
      final noteX = isRtl ? (margin + qrBoxSize + 40) : (margin + 20);
      drawText(
        '${strings.inRoomQrPinReminder}\n${strings.stabilizerDisclaimer}',
        x: noteX,
        top: footerTop + 28,
        maxWidth: contentW - qrBoxSize - 64,
        fontSize: 16,
        color: ink2,
      );
    } else {
      drawText(
        strings.stabilizerDisclaimer,
        x: margin + 20,
        top: footerTop + 20,
        maxWidth: contentW - 40,
        fontSize: 16,
        color: ink2,
      );
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(_pageW.toInt(), _pageH.toInt());
    try {
      final pngData = await image.toByteData(format: ui.ImageByteFormat.png);
      final rgbaData = await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      if (pngData == null || rgbaData == null) {
        throw StateError('Failed to rasterize consultation brief page.');
      }

      final previewPngBytes = pngData.buffer.asUint8List();
      final pdfBytes = _buildPdf14FromRgba(
        rgba: rgbaData.buffer.asUint8List(),
        width: _pageW.toInt(),
        height: _pageH.toInt(),
      );

      return ClinicalBriefRenderResult(
        pdfBytes: pdfBytes,
        previewPngBytes: previewPngBytes,
        plainSummary: plainSummary,
        hasEmbeddedQr: qrMatrix != null,
      );
    } finally {
      image.dispose();
    }
  }

  /// Writes valid binary PDF 1.4 wrapping a zlib-compressed 24-bit RGB image
  /// inside a standard A4 `595x842` pt page with exact byte offsets in `xref`.
  Uint8List _buildPdf14FromRgba({
    required Uint8List rgba,
    required int width,
    required int height,
  }) {
    final rgb = Uint8List(width * height * 3);
    var src = 0;
    var dst = 0;
    while (src < rgba.length) {
      rgb[dst++] = rgba[src];
      rgb[dst++] = rgba[src + 1];
      rgb[dst++] = rgba[src + 2];
      src += 4;
    }

    final compressedRgb = Uint8List.fromList(zlib.encode(rgb));
    final contentCmd = 'q\n595 0 0 842 0 0 cm\n/Im0 Do\nQ\n';
    final contentBytes = contentCmd.codeUnits;

    final out = BytesBuilder(copy: false);
    void writeAscii(String s) => out.add(s.codeUnits);

    final offsets = <int>[];

    writeAscii('%PDF-1.4\n%\xE2\xE3\xCF\xD3\n');

    // 1: Catalog
    offsets.add(out.length);
    writeAscii('1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n');

    // 2: Pages
    offsets.add(out.length);
    writeAscii('2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n');

    // 3: Page
    offsets.add(out.length);
    writeAscii(
      '3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] '
      '/Resources << /XObject << /Im0 4 0 R >> >> /Contents 5 0 R >>\nendobj\n',
    );

    // 4: Image XObject
    offsets.add(out.length);
    writeAscii(
      '4 0 obj\n<< /Type /XObject /Subtype /Image /Width $width /Height $height '
      '/ColorSpace /DeviceRGB /BitsPerComponent 8 /Filter /FlateDecode '
      '/Length ${compressedRgb.length} >>\nstream\n',
    );
    out.add(compressedRgb);
    writeAscii('\nendstream\nendobj\n');

    // 5: Content stream
    offsets.add(out.length);
    writeAscii('5 0 obj\n<< /Length ${contentBytes.length} >>\nstream\n');
    out.add(contentBytes);
    writeAscii('endstream\nendobj\n');

    // Cross-reference table
    final xrefStart = out.length;
    writeAscii('xref\n0 ${offsets.length + 1}\n');
    writeAscii('0000000000 65535 f \n');
    for (final offset in offsets) {
      final padded = offset.toString().padLeft(10, '0');
      writeAscii('$padded 00000 n \n');
    }
    writeAscii(
      'trailer\n<< /Size ${offsets.length + 1} /Root 1 0 R >>\n'
      'startxref\n$xrefStart\n%%EOF\n',
    );

    return out.toBytes();
  }

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
