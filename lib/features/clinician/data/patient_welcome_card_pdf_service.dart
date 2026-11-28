import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../app/localization/app_strings.dart';
import '../../../app/localization/mind_formatters.dart';
import '../../clinic_sync/domain/clinic_account_models.dart';
import 'pdf_font_loader.dart';

/// Generates an elderly-friendly printable A5/A4 Patient Clinic Access Welcome
/// Card PDF in the patient's chosen language (`EN` / `FR` / `AR`), featuring a
/// crisp vector QR code (>= 52mm × 52mm), high-contrast Login ID + Temporary PIN,
/// 3 simple sign-in steps, and Tunisian emergency helplines.
class PatientWelcomeCardPdfService {
  const PatientWelcomeCardPdfService();

  static const PdfPageFormat _cardFormat = PdfPageFormat(
    420,
    595,
    marginAll: 28,
  );

  static const PdfColor _ink = PdfColor.fromInt(0xFF111114);
  static const PdfColor _ink2 = PdfColor.fromInt(0xFF52525B);
  static const PdfColor _line = PdfColor.fromInt(0xFFD4D4D8);
  static const PdfColor _well = PdfColor.fromInt(0xFFF4F3EF);
  static const PdfColor _accent = PdfColor.fromInt(0xFF0F766E);
  static const PdfColor _safety = PdfColor.fromInt(0xFFBE123C);
  static const PdfColor _safetySoft = PdfColor.fromInt(0xFFFFF1F2);

  Future<Uint8List> generateWelcomeCardPdf({
    required ClinicProvisionResult provision,
    AppStrings? stringsOverride,
  }) async {
    final patientLang = provision.account.preferredLanguage.trim().isNotEmpty
        ? provision.account.preferredLanguage.trim()
        : 'en';
    final strings = stringsOverride ?? AppStrings(patientLang);
    final isRtl = strings.isArabic;
    final dir = isRtl ? pw.TextDirection.rtl : pw.TextDirection.ltr;
    final clean = MindPdfFontLoader.cleanForPdf;
    final fonts = await MindPdfFontLoader.load();

    final doc = pw.Document(
      version: PdfVersion.pdf_1_4,
      title: clean('${strings.welcomeCardTitle} — ${provision.account.displayName}'),
      author: clean(provision.account.doctorName),
      creator: 'Mindora Clinic Workspace',
      theme: fonts.themeFor(isArabic: isRtl),
    );

    doc.addPage(
      pw.Page(
        pageFormat: _cardFormat,
        textDirection: dir,
        build: (ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Mindora',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: _ink,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          clean(strings.welcomeCardTitle),
                          style: const pw.TextStyle(fontSize: 10, color: _ink2),
                        ),
                      ],
                    ),
                  ),
                  pw.Text(
                    clean(MindFormatters.shortDate(DateTime.now(), strings)),
                    style: const pw.TextStyle(fontSize: 8.5, color: _ink2),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Divider(color: _line, thickness: 0.8),
              pw.SizedBox(height: 8),

              // Patient + Doctor attribution
              pw.Text(
                clean(provision.account.displayName),
                style: pw.TextStyle(
                  fontSize: 15,
                  fontWeight: pw.FontWeight.bold,
                  color: _ink,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                clean(
                  '${provision.account.doctorName} · ${provision.account.clinicName}',
                ),
                style: const pw.TextStyle(fontSize: 9.5, color: _accent),
              ),
              pw.SizedBox(height: 14),

              // Large scannable vector QR + Credentials box
              pw.Container(
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  color: _well,
                  borderRadius: pw.BorderRadius.circular(10),
                  border: pw.Border.all(color: _line, width: 0.8),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.BarcodeWidget(
                        barcode: pw.Barcode.qrCode(),
                        data: provision.qrPayload,
                        width: 126,
                        height: 126,
                        drawText: false,
                      ),
                    ),
                    pw.SizedBox(width: 14),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            clean(strings.loginIdentifierLabel),
                            style: const pw.TextStyle(
                              fontSize: 8.5,
                              color: _ink2,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Directionality(
                            textDirection: pw.TextDirection.ltr,
                            child: pw.Text(
                              provision.account.loginIdentifier,
                              style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                                color: _ink,
                              ),
                            ),
                          ),
                          pw.SizedBox(height: 10),
                          pw.Text(
                            clean(strings.patientTempPinLabel),
                            style: const pw.TextStyle(
                              fontSize: 8.5,
                              color: _ink2,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Directionality(
                            textDirection: pw.TextDirection.ltr,
                            child: pw.Text(
                              provision.temporaryPin,
                              style: pw.TextStyle(
                                fontSize: 20,
                                fontWeight: pw.FontWeight.bold,
                                letterSpacing: 2.5,
                                color: _ink,
                              ),
                            ),
                          ),
                          pw.SizedBox(height: 8),
                          pw.Text(
                            clean(strings.patientQrExpireNote),
                            style: const pw.TextStyle(
                              fontSize: 7.8,
                              color: _ink2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),

              // 3 Simple Numbered Steps
              pw.Text(
                clean(strings.welcomeCardStepsTitle),
                style: pw.TextStyle(
                  fontSize: 10.5,
                  fontWeight: pw.FontWeight.bold,
                  color: _ink,
                ),
              ),
              pw.SizedBox(height: 6),
              for (final step in [
                strings.welcomeCardStep1,
                strings.welcomeCardStep2,
                strings.welcomeCardStep3,
              ])
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 5),
                  child: pw.Text(
                    clean(step),
                    style: const pw.TextStyle(
                      fontSize: 9.2,
                      color: _ink,
                      lineSpacing: 1.6,
                    ),
                  ),
                ),

              pw.Spacer(),

              // Emergency Helplines Footer (Tunisia)
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: _safetySoft,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: _safety, width: 0.6),
                ),
                child: pw.Text(
                  clean(strings.welcomeCardHelplinesFooter),
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: _safety,
                    lineSpacing: 1.4,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }
}
