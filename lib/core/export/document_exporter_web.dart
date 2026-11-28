import 'dart:typed_data';

import 'package:printing/printing.dart';

import 'document_exporter.dart';

Future<DocumentExportResult> saveDocumentBytes({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
  required String extensionLabel,
  required String extension,
}) async {
  final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  await Printing.sharePdf(bytes: bytes, filename: safeName);
  return DocumentExportResult(
    status: DocumentExportStatus.saved,
    fileName: safeName,
  );
}

Future<DocumentExportResult> printPdfDocument({
  required Uint8List bytes,
  required String documentName,
}) async {
  final safeName = documentName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  final completed = await Printing.layoutPdf(
    name: safeName,
    onLayout: (_) async => bytes,
  );
  return DocumentExportResult(
    status: completed
        ? DocumentExportStatus.printed
        : DocumentExportStatus.cancelled,
    fileName: safeName,
  );
}

Future<DocumentExportResult> sharePdfDocument({
  required Uint8List bytes,
  required String fileName,
  required String subject,
  required String text,
}) async {
  final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  await Printing.sharePdf(
    bytes: bytes,
    filename: safeName,
    subject: subject,
    body: text,
  );
  return DocumentExportResult(
    status: DocumentExportStatus.shared,
    fileName: safeName,
  );
}
