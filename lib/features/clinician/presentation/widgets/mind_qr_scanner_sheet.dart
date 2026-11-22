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
  bool _hasScanned = false;
  bool _torchOn = false;
  String? _statusMessage;

  bool get _isCameraSupported =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  @override
  void initState() {
    super.initState();
    if (_isCameraSupported) {
      _controller = MobileScannerController(
        formats: const [BarcodeFormat.qrCode],
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
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

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final strings = ref.watch(appStringsProvider);

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
                    Icons.qr_code_scanner_rounded,
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
                  if (_isCameraSupported && _controller != null)
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
              if (!_isCameraSupported || _controller == null) ...[
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
                          fontSize: 13,
                          color: tokens.ink2,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                MindButton(
                  text: MaterialLocalizations.of(context).closeButtonTooltip,
                  variant: MindButtonVariant.secondary,
                  isFullWidth: true,
                  onPressed: () => Navigator.of(context).pop(),
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
                          errorBuilder: (context, error) => Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Text(
                                strings.qrScannerUnsupportedNote,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: tokens.ink2,
                                ),
                              ),
                            ),
                          ),
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
              ],
            ],
          ),
        ),
      ),
    );
  }
}
