import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;

/// Cached bundled TrueType font set (`Inter` + `Noto Sans Arabic`) for crisp,
/// selectable, RTL-capable vector PDF generation across Mobile, Desktop, Web,
/// and headless unit tests.
@immutable
class MindPdfFonts {
  const MindPdfFonts({
    required this.regular,
    required this.bold,
    required this.arabicRegular,
    required this.arabicBold,
  });

  final pw.Font regular;
  final pw.Font bold;
  final pw.Font arabicRegular;
  final pw.Font arabicBold;

  pw.ThemeData themeFor({required bool isArabic}) {
    if (isArabic) {
      return pw.ThemeData.withFont(
        base: arabicRegular,
        bold: arabicBold,
        fontFallback: [regular, bold],
      );
    }
    return pw.ThemeData.withFont(
      base: regular,
      bold: bold,
      fontFallback: [arabicRegular, arabicBold],
    );
  }
}

abstract final class MindPdfFontLoader {
  static MindPdfFonts? _cached;

  /// Strips Unicode bidi isolate control characters (`U+2066..U+2069`) before
  /// passing text to `package:pdf` so TrueType fonts never draw tofu boxes.
  static String cleanForPdf(String raw) =>
      raw.replaceAll(RegExp('[\u2066-\u2069\u200E\u200F]'), '');

  static Future<MindPdfFonts> load() async {
    if (_cached != null) return _cached!;

    final regular = await _loadFont(
      'assets/fonts/Inter-Regular.ttf',
      fallback: pw.Font.helvetica(),
    );
    final bold = await _loadFont(
      'assets/fonts/Inter-Bold.ttf',
      fallback: pw.Font.helveticaBold(),
    );
    final arabicRegular = await _loadFont(
      'assets/fonts/NotoSansArabic-Regular.ttf',
      fallback: regular,
    );
    final arabicBold = await _loadFont(
      'assets/fonts/NotoSansArabic-Bold.ttf',
      fallback: bold,
    );

    _cached = MindPdfFonts(
      regular: regular,
      bold: bold,
      arabicRegular: arabicRegular,
      arabicBold: arabicBold,
    );
    return _cached!;
  }

  static Future<pw.Font> _loadFont(
    String assetPath, {
    required pw.Font fallback,
  }) async {
    try {
      final data = await rootBundle.load(assetPath);
      return pw.Font.ttf(data);
    } catch (_) {
      if (!kIsWeb) {
        try {
          final file = File(assetPath);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            return pw.Font.ttf(ByteData.sublistView(bytes));
          }
        } catch (_) {}
      }
      return fallback;
    }
  }
}
