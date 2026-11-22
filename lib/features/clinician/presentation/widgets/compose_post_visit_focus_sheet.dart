import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/router/app_router.dart';
import '../../../../app/theme/mind_tokens.dart';
import '../../../../core/widgets/mind_button.dart';
import '../../../../core/widgets/mind_card.dart';
import '../../../../core/widgets/mind_pill.dart';
import '../../../../core/widgets/mind_qr_code.dart';
import '../../controllers/clinician_providers.dart';
import '../../domain/post_visit_focus_model.dart';

/// Modal sheet inside the Psychiatrist Workspace allowing the clinician to compose
/// a non-diagnostic between-session focus plan (`MF-CAREPLAN-V1:...`) or deliver
/// it straight to the on-device Patient Home view.
class ComposePostVisitFocusSheet extends ConsumerStatefulWidget {
  const ComposePostVisitFocusSheet({
    super.key,
    required this.patientDisplayName,
  });

  final String patientDisplayName;

  static Future<void> show(
    BuildContext context, {
    required String patientDisplayName,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ComposePostVisitFocusSheet(
        patientDisplayName: patientDisplayName,
      ),
    );
  }

  @override
  ConsumerState<ComposePostVisitFocusSheet> createState() =>
      _ComposePostVisitFocusSheetState();
}

class _ComposePostVisitFocusSheetState
    extends ConsumerState<ComposePostVisitFocusSheet> {
  final Set<String> _selectedPresets = <String>{};
  int? _followUpDays = 14;
  final TextEditingController _customItemCtrl = TextEditingController();
  final TextEditingController _cueCtrl = TextEditingController();
  final TextEditingController _passphraseCtrl = TextEditingController();

  bool _isGenerating = false;
  bool _isDeliveringLocal = false;
  String? _generatedCode;
  String? _errorText;

  @override
  void dispose() {
    _customItemCtrl.dispose();
    _cueCtrl.dispose();
    _passphraseCtrl.dispose();
    super.dispose();
  }

  List<String> _presetOptions(AppStrings strings) => [
        strings.focusPresetSleepWindow,
        strings.focusPresetEveningLog,
        strings.focusPresetGroundingPause,
        strings.focusPresetEnergyPattern,
        strings.focusPresetThoughtLoop,
        strings.focusPresetWhatHelped,
      ];

  List<String> _collectFocusTitles(AppStrings strings) {
    final titles = <String>[];
    for (final preset in _presetOptions(strings)) {
      if (_selectedPresets.contains(preset)) {
        titles.add(preset);
      }
    }
    final custom = _customItemCtrl.text.trim();
    if (custom.isNotEmpty) {
      titles.add(custom);
    }
    return titles;
  }

  PostVisitFocusPlan _buildPlan(AppStrings strings) {
    final profile = ref.read(clinicianProfileProvider).value;
    final clinicianName = profile?.displayName ?? 'Clinician';
    final clinicName = profile?.clinicName ?? '';
    final now = DateTime.now();
    final followUpDate = _followUpDays != null
        ? DateTime(now.year, now.month, now.day)
            .add(Duration(days: _followUpDays!))
        : null;

    final rawTitles = _collectFocusTitles(strings);
    final titles = rawTitles.isEmpty
        ? [strings.focusPresetEveningLog]
        : rawTitles;

    return ref.read(clinicianSyncServiceProvider).buildPostVisitFocusPlan(
          clinicianName: clinicianName,
          clinicName: clinicName,
          focusTitles: titles,
          followUpDate: followUpDate,
          observationCue: _cueCtrl.text.trim(),
          referenceNow: now,
        );
  }

  Future<void> _generateEncryptedCode(AppStrings strings) async {
    final pass = _passphraseCtrl.text.trim();
    if (pass.length < 6) {
      setState(() => _errorText = strings.handoffPassphraseMinError);
      return;
    }
    setState(() {
      _isGenerating = true;
      _errorText = null;
    });
    try {
      final plan = _buildPlan(strings);
      final code = await ref
          .read(clinicianSyncServiceProvider)
          .encryptCarePlanToCode(plan, pass);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() {
        _generatedCode = code;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorText = e.toString());
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _copyCode(AppStrings strings, MindTokens tokens) async {
    final code = _generatedCode;
    if (code == null || code.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: code));
    HapticFeedback.lightImpact();
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        backgroundColor: tokens.surface2,
        content: Text(
          strings.carePlanCodeCopiedSnackbar,
          style: TextStyle(color: tokens.ink, fontSize: 13),
        ),
      ),
    );
  }

  Future<void> _deliverLocally(
    BuildContext context,
    AppStrings strings,
    MindTokens tokens,
  ) async {
    setState(() {
      _isDeliveringLocal = true;
      _errorText = null;
    });

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final router = GoRouter.maybeOf(context);

    try {
      final plan = _buildPlan(strings);
      await ref.read(postVisitFocusControllerProvider.notifier).savePlan(plan);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      navigator.pop();
      messenger?.showSnackBar(
        SnackBar(
          backgroundColor: tokens.surface2,
          content: Text(
            strings.focusDeliveredSnackbar,
            style: TextStyle(color: tokens.ink, fontSize: 13),
          ),
          action: router == null
              ? null
              : SnackBarAction(
                  label: strings.patientViewChipLabel,
                  textColor: tokens.m1,
                  onPressed: () => router.go(AppRouter.home),
                ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorText = e.toString());
    } finally {
      if (mounted) setState(() => _isDeliveringLocal = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final strings = ref.watch(appStringsProvider);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.90,
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
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
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
                child: Row(
                  children: [
                    Icon(Icons.send_outlined, size: 20, color: tokens.m1),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${strings.composeFocusTitle} · ${widget.patientDisplayName}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w700,
                              color: tokens.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            strings.composeFocusSubtitle,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: tokens.ink2,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Tooltip(
                      message:
                          MaterialLocalizations.of(context).closeButtonTooltip,
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close_rounded, color: tokens.ink2),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: tokens.line),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        strings.followUpWindowLabel,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: strings.isArabic ? 0 : 0.7,
                          color: tokens.ink2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final d in [7, 14, 30])
                            MindPill(
                              label: strings.daysWindowLabel(d),
                              isSelected: _followUpDays == d,
                              onTap: () => setState(() => _followUpDays = d),
                            ),
                          MindPill(
                            label: strings.followUpNoneLabel,
                            isSelected: _followUpDays == null,
                            onTap: () => setState(() => _followUpDays = null),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      Text(
                        strings.focusItemsSectionLabel,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: strings.isArabic ? 0 : 0.7,
                          color: tokens.ink2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _presetOptions(strings).map((preset) {
                          final selected = _selectedPresets.contains(preset);
                          return MindPill(
                            label: preset,
                            isSelected: selected,
                            onTap: () {
                              setState(() {
                                if (selected) {
                                  _selectedPresets.remove(preset);
                                } else {
                                  _selectedPresets.add(preset);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _customItemCtrl,
                        style: TextStyle(fontSize: 13.5, color: tokens.ink),
                        decoration: _fieldDecoration(
                          tokens,
                          strings.customFocusItemHint,
                        ),
                      ),

                      const SizedBox(height: 16),
                      Text(
                        strings.observationCueLabel,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: strings.isArabic ? 0 : 0.7,
                          color: tokens.ink2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _cueCtrl,
                        maxLines: 2,
                        style: TextStyle(fontSize: 13.5, color: tokens.ink),
                        decoration: _fieldDecoration(
                          tokens,
                          strings.observationCueHint,
                        ),
                      ),

                      const SizedBox(height: 16),
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
                        const SizedBox(height: 8),
                        Text(
                          _errorText!,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: tokens.safety,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],

                      const SizedBox(height: 12),
                      MindButton(
                        text: strings.generateCarePlanCodeBtn,
                        variant: MindButtonVariant.soft,
                        leadingIcon: Icons.enhanced_encryption_outlined,
                        isFullWidth: true,
                        isLoading: _isGenerating,
                        onPressed: () => _generateEncryptedCode(strings),
                      ),

                      if (_generatedCode != null) ...[
                        const SizedBox(height: 10),
                        MindCard(
                          variant: MindCardVariant.flat,
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SelectableText(
                                _generatedCode!,
                                maxLines: 4,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: tokens.ink2,
                                ),
                              ),
                              const SizedBox(height: 10),
                              MindButton(
                                text: strings.copySyncCodeBtn,
                                variant: MindButtonVariant.secondary,
                                leadingIcon: Icons.copy_rounded,
                                isFullWidth: true,
                                onPressed: () => _copyCode(strings, tokens),
                              ),
                              const SizedBox(height: 12),
                              MindQrCodeView(
                                data: _generatedCode!,
                                size: 170,
                                semanticLabel: strings.showInRoomQrBtn,
                                overflowNotice: strings.qrCapacityExceededNote,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                strings.inRoomQrPinReminder,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: tokens.ink2,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 12),
                      MindButton(
                        text: strings.sendFocusToPatientDeviceBtn,
                        variant: MindButtonVariant.primary,
                        leadingIcon: Icons.home_outlined,
                        isFullWidth: true,
                        isLoading: _isDeliveringLocal,
                        onPressed: () =>
                            _deliverLocally(context, strings, tokens),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(MindTokens tokens, String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 13, color: tokens.ink3),
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
