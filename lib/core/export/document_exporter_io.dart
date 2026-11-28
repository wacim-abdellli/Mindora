import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

import 'document_exporter.dart';

bool get _isFlutterTest {
  try {
    return Platform.environment.containsKey('FLUTTER_TEST');
  } catch (_) {
    return false;
  }
}

bool get _isDesktop =>
    Platform.isWindows || Platform.isMacOS || Platform.isLinux;

Future<Directory> _resolveAccessibleDirectory() async {
  if (_isFlutterTest) {
    return Directory.systemTemp;
  }
  try {
    final downloads = await getDownloadsDirectory();
    if (downloads != null) return downloads;
  } catch (_) {}
  try {
    return await getApplicationDocumentsDirectory();
  } catch (_) {
    return Directory.systemTemp;
  }
}

Future<DocumentExportResult> saveDocumentBytes({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
  required String extensionLabel,
  required String extension,
}) async {
  final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');

  // On real Desktop environments, open a native Save As dialog defaulting to Downloads.
  if (_isDesktop && !_isFlutterTest) {
    final initialDir = await _resolveAccessibleDirectory();
    final location = await getSaveLocation(
      suggestedName: safeName,
      initialDirectory: initialDir.path,
      acceptedTypeGroups: [
        XTypeGroup(
          label: extensionLabel,
          extensions: [extension],
          mimeTypes: [mimeType],
        ),
      ],
    );
    if (location == null) {
      return DocumentExportResult(
        status: DocumentExportStatus.cancelled,
        fileName: safeName,
      );
    }
    final outPath = location.path.toLowerCase().endsWith('.$extension')
        ? location.path
        : '${location.path}.$extension';
    final file = File(outPath);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
    return DocumentExportResult(
      status: DocumentExportStatus.saved,
      fileName: safeName,
      savedPath: file.path,
    );
  }

  // Mobile or test environment: save to accessible Downloads/Documents folder.
  final dir = await _resolveAccessibleDirectory();
  await dir.create(recursive: true);
  final file = File('${dir.path}${Platform.pathSeparator}$safeName');
  await file.writeAsBytes(bytes, flush: true);
  return DocumentExportResult(
    status: DocumentExportStatus.saved,
    fileName: safeName,
    savedPath: file.path,
  );
}

Future<DocumentExportResult> printPdfDocument({
  required Uint8List bytes,
  required String documentName,
}) async {
  final safeName = documentName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  if (_isFlutterTest) {
    return DocumentExportResult(
      status: DocumentExportStatus.printed,
      fileName: safeName,
    );
  }
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
  if (_isFlutterTest) {
    return DocumentExportResult(
      status: DocumentExportStatus.shared,
      fileName: safeName,
    );
  }
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
