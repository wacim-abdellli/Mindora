import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/theme/mind_tokens.dart';
import '../../../../core/widgets/mind_button.dart';

/// Luxury dark modal QR scanner engineered for offline, zero-cloud in-room
/// handoff (`MF-CLINIC-V1:` and `MF-CAREPLAN-V1:`).
class MindQrScannerSheet extends ConsumerStatefulWidget {
  const MindQrScannerSheet({
    super.key,
    required this.expectedPrefix,
    required this.title,
    required this.subtitle,
  });

  final String expectedPrefix;
  final String title;
  final String subtitle;

  static Future<String?> show(
    BuildContext context, {
    required String expectedPrefix,
    required String title,
    required String subtitle,
  }) {
    return showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MindQrScannerSheet(
        expectedPrefix: expectedPrefix,
        title: title,
        subtitle: subtitle,
      ),
    );
  }

  @override
  ConsumerState<MindQrScannerSheet> createState() => _MindQrScannerSheetState();
}

class _MindQrScannerSheetState extends ConsumerState<MindQrScannerSheet> {
  MobileScannerController? _controller;
  final TextEditingController _codeCtrl = TextEditingController();
  bool _hasScanned = false;
  bool _torchOn = false;
  bool _cameraApproved = false;
  bool _pasteMode = false;
  String? _statusMessage;

  bool get _isCameraSupported =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  void _startCamera() {
    if (_controller == null && _isCameraSupported) {
      _controller = MobileScannerController(
        formats: const [BarcodeFormat.qrCode],
      );
    }
    setState(() {
      _pasteMode = false;
      _cameraApproved = true;
      _statusMessage = null;
    });
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final raw = data?.text?.trim();
    if (raw != null && raw.isNotEmpty && mounted) {
      setState(() {
        _codeCtrl.text = raw;
        _statusMessage = null;
      });
    }
  }

  void _submitPastedCode(AppStrings strings) {
    final cleaned = _codeCtrl.text.replaceAll(RegExp(r'\s+'), '');
    if (cleaned.isEmpty || !cleaned.startsWith(widget.expectedPrefix)) {
      setState(() {
        _statusMessage =
            strings.qrScannerWrongPrefixError(widget.expectedPrefix);
      });
      return;
    }
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(cleaned);
  }

  @override
  void dispose() {
    _controller?.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  void _onBarcodeDetect(BarcodeCapture capture, AppStrings strings) {
    if (_hasScanned || !mounted) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue?.replaceAll(RegExp(r'\s+'), '') ?? '';
      if (raw.isEmpty) continue;
      if (!raw.startsWith(widget.expectedPrefix)) {
        setState(() {
          _statusMessage =
              strings.qrScannerWrongPrefixError(widget.expectedPrefix);
        });
        return;
      }
      _hasScanned = true;
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop(raw);
      return;
    }
  }

  Future<void> _toggleTorch() async {
    final ctrl = _controller;
    if (ctrl == null) return;
    try {
      await ctrl.toggleTorch();
      if (mounted) {
        setState(() => _torchOn = !_torchOn);
      }
    } catch (_) {
      // Ignore torch unavailability on front/virtual lenses.
    }
  }

  void _retryCamera() {
    _controller?.dispose();
    _controller = null;
    _startCamera();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final strings = ref.watch(appStringsProvider);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        child: Container(
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
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: tokens.line,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      _pasteMode
                          ? Icons.content_paste_rounded
                          : Icons.qr_code_scanner_rounded,
                      size: 20,
                      color: tokens.m1,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: tokens.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.subtitle,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: tokens.ink2,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!_pasteMode && _isCameraSupported && _controller != null)
                      Tooltip(
                        message: strings.qrScannerTorchTooltip,
                        child: IconButton(
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                          onPressed: _toggleTorch,
                          icon: Icon(
                            _torchOn
                                ? Icons.flash_on_rounded
                                : Icons.flash_off_rounded,
                            color: _torchOn ? tokens.m1 : tokens.ink2,
                          ),
                        ),
                      ),
                    Tooltip(
                      message:
                          MaterialLocalizations.of(context).closeButtonTooltip,
                      child: IconButton(
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close_rounded, color: tokens.ink2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_pasteMode) ...[
                  TextField(
                    key: const ValueKey<String>('qr-paste-code-field'),
                    controller: _codeCtrl,
                    minLines: 2,
                    maxLines: 4,
                    autofocus: true,
                    style: TextStyle(fontSize: 14, color: tokens.ink),
                    onChanged: (_) {
                      if (_statusMessage != null) {
                        setState(() => _statusMessage = null);
                      }
                    },
                    decoration: InputDecoration(
                      hintText: '${widget.expectedPrefix}...',
                      hintStyle: TextStyle(fontSize: 13.5, color: tokens.ink3),
                      filled: true,
                      fillColor: tokens.surface2,
                      contentPadding: const EdgeInsets.all(14),
                      suffixIcon: IconButton(
                        tooltip: strings.pasteFromClipboardBtn,
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        icon: Icon(
                          Icons.content_paste_rounded,
                          color: tokens.ink2,
                        ),
                        onPressed: _pasteFromClipboard,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(tokens.inputRadius),
                        borderSide: BorderSide(color: tokens.line),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(tokens.inputRadius),
                        borderSide: BorderSide(color: tokens.line),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(tokens.inputRadius),
                        borderSide: BorderSide(color: tokens.ink, width: 1.2),
                      ),
                    ),
                  ),
                  if (_statusMessage != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _statusMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: tokens.safety,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  MindButton(
                    key: const ValueKey<String>('qr-paste-submit-btn'),
                    text: strings.continueBtn,
                    isFullWidth: true,
                    onPressed: () => _submitPastedCode(strings),
                  ),
                  const SizedBox(height: 8),
                  MindButton(
                    text: strings.pasteFromClipboardBtn,
                    leadingIcon: Icons.content_paste_rounded,
                    variant: MindButtonVariant.secondary,
                    isFullWidth: true,
                    onPressed: _pasteFromClipboard,
                  ),
                  if (_isCameraSupported) ...[
                    const SizedBox(height: 6),
                    Center(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          minimumSize: const Size(48, 48),
                        ),
                        onPressed: () => setState(() {
                          _pasteMode = false;
                          _statusMessage = null;
                        }),
                        child: Text(
                          strings.allowCameraBtn,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: tokens.ink2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ] else if (!_isCameraSupported) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: tokens.surface2,
                      borderRadius: BorderRadius.circular(tokens.inputRadius),
                      border: Border.all(color: tokens.line),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.videocam_off_outlined,
                          size: 36,
                          color: tokens.ink3,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          strings.qrScannerUnsupportedNote,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: tokens.ink2,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  MindButton(
                    key: const ValueKey<String>('qr-paste-mode-btn'),
                    text: strings.pasteTextCodeBtn,
                    leadingIcon: Icons.content_paste_rounded,
                    isFullWidth: true,
                    onPressed: () => setState(() {
                      _pasteMode = true;
                      _statusMessage = null;
                    }),
                  ),
                  const SizedBox(height: 8),
                  MindButton(
                    text: MaterialLocalizations.of(context).closeButtonTooltip,
                    variant: MindButtonVariant.ghost,
                    isFullWidth: true,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ] else if (!_cameraApproved || _controller == null) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: tokens.surface2,
                      borderRadius: BorderRadius.circular(tokens.inputRadius),
                      border: Border.all(color: tokens.line),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: tokens.primarySoft,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.camera_alt_outlined,
                            size: 28,
                            color: tokens.primary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          strings.cameraPermissionTitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w700,
                            color: tokens.ink,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          strings.cameraPermissionBody,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: tokens.ink2,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  MindButton(
                    text: strings.allowCameraBtn,
                    isFullWidth: true,
                    onPressed: _startCamera,
                  ),
                  const SizedBox(height: 8),
                  MindButton(
                    key: const ValueKey<String>('qr-paste-mode-btn'),
                    text: strings.pasteTextCodeBtn,
                    variant: MindButtonVariant.ghost,
                    isFullWidth: true,
                    onPressed: () => setState(() {
                      _pasteMode = true;
                      _statusMessage = null;
                    }),
                  ),
                ] else ...[
                  AspectRatio(
                    aspectRatio: 1.0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: tokens.bg,
                        borderRadius: BorderRadius.circular(tokens.inputRadius),
                        border: Border.all(color: tokens.lineStrong, width: 1.5),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          MobileScanner(
                            controller: _controller!,
                            onDetect: (cap) => _onBarcodeDetect(cap, strings),
                            errorBuilder: (context, error) {
                              final isDenied =
                                  error.errorCode ==
                                  MobileScannerErrorCode.permissionDenied;
                              return Center(
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    key: const ValueKey<String>(
                                      'qr-permission-denied-card',
                                    ),
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isDenied
                                            ? Icons.no_photography_outlined
                                            : Icons.videocam_off_outlined,
                                        size: 36,
                                        color: tokens.safety,
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        isDenied
                                            ? strings
                                                .cameraPermissionDeniedTitle
                                            : strings.cameraPermissionTitle,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.w700,
                                          color: tokens.ink,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        isDenied
                                            ? strings.cameraPermissionDeniedBody
                                            : strings.qrScannerUnsupportedNote,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 13,
                                          height: 1.4,
                                          color: tokens.ink2,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      MindButton(
                                        text: strings.retryCameraBtn,
                                        variant: MindButtonVariant.secondary,
                                        size: MindButtonSize.md,
                                        onPressed: _retryCamera,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          IgnorePointer(
                            child: Center(
                              child: Container(
                                width: 210,
                                height: 210,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: tokens.m1.withValues(alpha: 0.85),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_statusMessage != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _statusMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: tokens.safety,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  MindButton(
                    key: const ValueKey<String>('qr-paste-mode-btn'),
                    text: strings.pasteTextCodeBtn,
                    variant: MindButtonVariant.ghost,
                    isFullWidth: true,
                    onPressed: () => setState(() {
                      _pasteMode = true;
                      _statusMessage = null;
                    }),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
        ),
      ),
    );
  }
}
