import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/theme/mind_tokens.dart';
import '../../../../core/widgets/mind_button.dart';
import '../../controllers/clinician_providers.dart';
import '../../data/clinician_sync_service.dart';
import '../../domain/post_visit_focus_model.dart';

/// Patient-side modal sheet to decrypt and activate an `MF-CAREPLAN-V1:...`
/// between-session focus plan sent by their psychiatrist or clinician.
class ImportCareFocusSheet extends ConsumerStatefulWidget {
  const ImportCareFocusSheet({super.key});

  static Future<PostVisitFocusPlan?> show(BuildContext context) {
    return showModalBottomSheet<PostVisitFocusPlan?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ImportCareFocusSheet(),
    );
  }

  @override
  ConsumerState<ImportCareFocusSheet> createState() =>
      _ImportCareFocusSheetState();
}

class _ImportCareFocusSheetState extends ConsumerState<ImportCareFocusSheet> {
  final TextEditingController _codeCtrl = TextEditingController();
  final TextEditingController _passphraseCtrl = TextEditingController();
  bool _isDecrypting = false;
  String? _errorText;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _passphraseCtrl.dispose();
    super.dispose();
  }

  Future<void> _decryptAndSave(
    BuildContext context,
    AppStrings strings,
    MindTokens tokens,
  ) async {
    final code = _codeCtrl.text.trim();
    final pass = _passphraseCtrl.text.trim();

    if (!code
        .replaceAll(RegExp(r'\s+'), '')
        .startsWith(ClinicianSyncService.carePlanPrefix)) {
      setState(() => _errorText = strings.importInvalidCodeError);
      return;
    }
    if (pass.length < 6) {
      setState(() => _errorText = strings.handoffPassphraseMinError);
      return;
    }

    setState(() {
      _isDecrypting = true;
      _errorText = null;
    });

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);

    try {
      final plan = await ref
          .read(clinicianSyncServiceProvider)
          .decryptCarePlanCode(code, pass);
      await ref.read(postVisitFocusControllerProvider.notifier).savePlan(plan);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      navigator.pop(plan);
      messenger?.showSnackBar(
        SnackBar(
          backgroundColor: tokens.surface2,
          content: Text(
            strings.carePlanImportedSnackbar,
            style: TextStyle(color: tokens.ink, fontSize: 13),
          ),
        ),
      );
    } on ClinicianSyncException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = switch (e.code) {
          ClinicianSyncErrorCode.invalidFormat ||
          ClinicianSyncErrorCode.unsupportedVersion =>
            strings.importInvalidCodeError,
          ClinicianSyncErrorCode.decryptionFailed ||
          ClinicianSyncErrorCode.integrityMismatch =>
            strings.importWrongPassphraseError,
        };
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorText = strings.importWrongPassphraseError);
    } finally {
      if (mounted) setState(() => _isDecrypting = false);
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text != null && text.isNotEmpty && mounted) {
      setState(() {
        _codeCtrl.text = text;
        _errorText = null;
      });
    }
  }

  Future<void> _scanQrCode(AppStrings strings) async {
    final scanned = await ref.read(clinicHandoffBridgeProvider).scanQrCode(
          context,
          expectedPrefix: ClinicianSyncService.carePlanPrefix,
          title: strings.qrScannerTitle,
          subtitle: strings.qrScannerSubtitle,
        );
    if (scanned != null && scanned.isNotEmpty && mounted) {
      setState(() {
        _codeCtrl.text = scanned;
        _errorText = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final strings = ref.watch(appStringsProvider);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

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
                      Icons.assignment_returned_outlined,
                      size: 20,
                      color: tokens.accentInk,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        strings.importCareFocusTitle,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: tokens.ink,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip:
                          MaterialLocalizations.of(context).closeButtonTooltip,
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close_rounded, color: tokens.ink2),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  strings.importCareFocusSubtitle,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: tokens.ink2,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  strings.carePlanCodeFieldLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: tokens.ink2,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _codeCtrl,
                  maxLines: 3,
                  style: TextStyle(fontSize: 12.5, color: tokens.ink),
                  decoration: _fieldDecoration(
                    tokens,
                    strings.carePlanCodeFieldHint,
                  ),
                ),
                const SizedBox(height: 8),
                MindButton(
                  text: strings.scanInRoomQrBtn,
                  variant: MindButtonVariant.secondary,
                  leadingIcon: Icons.qr_code_scanner_rounded,
                  isFullWidth: true,
                  onPressed: () => _scanQrCode(strings),
                ),
                const SizedBox(height: 8),
                MindButton(
                  text: strings.pasteFromClipboardBtn,
                  variant: MindButtonVariant.soft,
                  leadingIcon: Icons.content_paste_rounded,
                  isFullWidth: true,
                  onPressed: _pasteFromClipboard,
                ),
                const SizedBox(height: 12),
                Text(
                  strings.handoffPassphraseLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: tokens.ink2,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _passphraseCtrl,
                  obscureText: true,
                  style: TextStyle(fontSize: 14, color: tokens.ink),
                  decoration: _fieldDecoration(
                    tokens,
                    strings.handoffPassphraseHint,
                  ),
                ),
                if (_errorText != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _errorText!,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: tokens.safety,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                MindButton(
                  text: strings.decryptAndImportBtn,
                  variant: MindButtonVariant.primary,
                  leadingIcon: Icons.lock_open_rounded,
                  isFullWidth: true,
                  isLoading: _isDecrypting,
                  onPressed: () => _decryptAndSave(context, strings, tokens),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(MindTokens tokens, String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 12.5, color: tokens.ink3),
      filled: true,
      fillColor: tokens.surface2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(tokens.buttonRadius),
        borderSide: BorderSide(color: tokens.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(tokens.buttonRadius),
        borderSide: BorderSide(color: tokens.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(tokens.buttonRadius),
        borderSide: BorderSide(color: tokens.ink, width: 1.2),
      ),
    );
  }
}
