import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../presentation/widgets/mind_qr_scanner_sheet.dart';

/// Hardware abstraction bridging native OS file sharing and live camera QR
/// scanning so consultation handoff sheets remain cleanly testable without
/// live hardware plugins during widget tests.
abstract class ClinicHandoffBridge {
  const ClinicHandoffBridge();

  Future<void> sharePdfFile({
    required String filePath,
    required String subject,
    required String text,
  });

  Future<void> sharePngFile({
    required String filePath,
    required String subject,
    required String text,
  }) async {}

  Future<String?> scanQrCode(
    BuildContext context, {
    required String expectedPrefix,
    required String title,
    required String subtitle,
  });
}

/// Production implementation backed by `share_plus` and `mobile_scanner`.
class DefaultClinicHandoffBridge extends ClinicHandoffBridge {
  const DefaultClinicHandoffBridge();

  @override
  Future<void> sharePdfFile({
    required String filePath,
    required String subject,
    required String text,
  }) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(filePath, mimeType: 'application/pdf')],
        subject: subject,
        text: text,
      ),
    );
  }

  @override
  Future<void> sharePngFile({
    required String filePath,
    required String subject,
    required String text,
  }) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(filePath, mimeType: 'image/png')],
        subject: subject,
        text: text,
      ),
    );
  }

  @override
  Future<String?> scanQrCode(
    BuildContext context, {
    required String expectedPrefix,
    required String title,
    required String subtitle,
  }) {
    return MindQrScannerSheet.show(
      context,
      expectedPrefix: expectedPrefix,
      title: title,
      subtitle: subtitle,
    );
  }
}
