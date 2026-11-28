import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'document_exporter_io.dart'
    if (dart.library.js_interop) 'document_exporter_web.dart'
    as impl;

enum DocumentExportStatus { saved, shared, printed, cancelled }

@immutable
class DocumentExportResult {
  const DocumentExportResult({
    required this.status,
    required this.fileName,
    this.savedPath,
  });

  final DocumentExportStatus status;
  final String fileName;
  final String? savedPath;

  bool get isCancelled => status == DocumentExportStatus.cancelled;
}

/// Cross-platform document export abstraction (Desktop Save As, Web direct
/// browser download, Mobile accessible Downloads/Documents save, and native Print).
abstract class DocumentExporter {
  const DocumentExporter();

  Future<DocumentExportResult> savePdf({
    required Uint8List bytes,
    required String fileName,
  });

  Future<DocumentExportResult> savePng({
    required Uint8List bytes,
    required String fileName,
  });

  Future<DocumentExportResult> printPdf({
    required Uint8List bytes,
    required String documentName,
  });

  Future<DocumentExportResult> sharePdf({
    required Uint8List bytes,
    required String fileName,
    required String subject,
    required String text,
  });

  /// Sanitizes user/patient names into safe cross-platform filenames.
  static String sanitizeFileName(String raw) {
    final cleaned = raw
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9._-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return cleaned.isEmpty ? 'mindora_document' : cleaned;
  }
}

/// Production exporter selecting IO (Android/iOS/Windows/macOS/Linux) or Web.
class DefaultDocumentExporter extends DocumentExporter {
  const DefaultDocumentExporter();

  @override
  Future<DocumentExportResult> savePdf({
    required Uint8List bytes,
    required String fileName,
  }) => impl.saveDocumentBytes(
    bytes: bytes,
    fileName: fileName,
    mimeType: 'application/pdf',
    extensionLabel: 'PDF Document',
    extension: 'pdf',
  );

  @override
  Future<DocumentExportResult> savePng({
    required Uint8List bytes,
    required String fileName,
  }) => impl.saveDocumentBytes(
    bytes: bytes,
    fileName: fileName,
    mimeType: 'image/png',
    extensionLabel: 'PNG Image',
    extension: 'png',
  );

  @override
  Future<DocumentExportResult> printPdf({
    required Uint8List bytes,
    required String documentName,
  }) => impl.printPdfDocument(bytes: bytes, documentName: documentName);

  @override
  Future<DocumentExportResult> sharePdf({
    required Uint8List bytes,
    required String fileName,
    required String subject,
    required String text,
  }) => impl.sharePdfDocument(
    bytes: bytes,
    fileName: fileName,
    subject: subject,
    text: text,
  );
}

final documentExporterProvider = Provider<DocumentExporter>((ref) {
  return const DefaultDocumentExporter();
});
