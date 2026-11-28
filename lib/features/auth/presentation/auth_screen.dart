import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/config/app_edition.dart';
import '../../../app/localization/app_strings.dart';
import '../../../app/localization/locale_controller.dart';
import '../../../app/router/app_router.dart';
import '../../../app/theme/display_comfort_controller.dart';
import '../../../app/theme/lab_theme.dart';
import '../../../app/theme/mind_tokens.dart';
import '../../../core/safety/support_button.dart';
import '../../../core/widgets/ambient_scaffold.dart';
import '../../../core/widgets/mind_button.dart';
import '../../../core/widgets/mind_card.dart';
import '../../../core/widgets/mind_page_container.dart';
import '../../../core/widgets/mind_pressable.dart';
import '../../../core/widgets/mind_segmented.dart';
import '../../../core/widgets/mood_face.dart';
import '../../clinic_sync/domain/clinic_account_models.dart';
import '../../clinician/controllers/clinician_providers.dart';
import '../controllers/auth_controller.dart';
import '../domain/auth_state.dart';

/// Strictly Clinic-Only Patient Login Screen for Mindora.
///
/// Designed for patients of every age (14 to 75+):
/// - Immediate Language (`EN / FR / AR`), `Larger text`, and Crisis Shield controls
/// - Hero CTA: `Scan doctor's QR` (1-scan in-office login, zero typing)
/// - Secondary Form: `Phone number or username` + `PIN`
/// - Zero public self-signup, zero local-vault jargon, zero clinician portal links
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _obscurePin = true;

  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _identifierController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _routeAfterAuth() async {
    if (!mounted) return;
    if (AppEditionConfig.isClinicianApp && kDebugMode) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('mf_clinician_demo_preview', true);
      if (!mounted) return;
    }
    final authState = ref.read(authControllerProvider);
    if (!authState.hasCompletedOnboarding) {
      final isClinic = authState.user?.isClinicAccount ?? false;
      GoRouter.maybeOf(context)?.go(
        isClinic ? AppRouter.clinicWelcome : AppRouter.onboarding,
      );
    } else {
      GoRouter.maybeOf(context)?.go(AppRouter.home);
    }
  }

  Future<void> _scanDoctorQr(AppStrings strings) async {
    HapticFeedback.mediumImpact();
    final qrPayload = await ref.read(clinicHandoffBridgeProvider).scanQrCode(
          context,
          expectedPrefix: ClinicInvitePayload.qrPrefix,
          title: strings.scanDoctorQrSheetTitle,
          subtitle: strings.scanDoctorQrSheetSub,
        );
    if (qrPayload == null || qrPayload.trim().isEmpty || !mounted) return;

    final success = await ref
        .read(authControllerProvider.notifier)
        .signInWithClinicQr(qrPayload);
    if (success) {
      await _routeAfterAuth();
    }
  }

  Future<void> _enterQrFallbackCode(
    AppStrings strings,
    MindTokens tokens,
  ) async {
    final rawCode = await showDialog<String>(
      context: context,
      builder: (_) => _EnterQrCodeDialog(strings: strings, tokens: tokens),
    );

    if (rawCode == null || rawCode.isEmpty || !mounted) return;
    final success = await ref
        .read(authControllerProvider.notifier)
        .signInWithClinicQr(rawCode);
    if (success) {
      await _routeAfterAuth();
    }
  }

  Future<void> _submitCredentials() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.lightImpact();

    final success = await ref
        .read(authControllerProvider.notifier)
        .signInWithClinicCredentials(
          _identifierController.text,
          _pinController.text,
        );
    if (success) {
      await _routeAfterAuth();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final strings = ref.watch(appStringsProvider);
    final authState = ref.watch(authControllerProvider);
    final locale = ref.watch(localeControllerProvider);
    final comfortMode = ref.watch(displayComfortProvider);
    final langIndex = switch (locale.languageCode) {
      'fr' => 1,
      'ar' => 2,
      _ => 0,
    };

    return AmbientScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Mindora',
          style: LabTheme.textStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: tokens.ink,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          physics: const BouncingScrollPhysics(),
          child: MindPageContainer(
            maxWidth: 460,
            padding: EdgeInsets.zero,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Accessible Language + Larger Text strip before anything else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final langControl = MindSegmented(
                        index: langIndex,
                        labels: const ['EN', 'FR', 'عربي'],
                        onChanged: (idx) {
                          HapticFeedback.selectionClick();
                          final lang = switch (idx) {
                            1 => AppLanguage.french,
                            2 => AppLanguage.arabic,
                            _ => AppLanguage.english,
                          };
                          ref
                              .read(localeControllerProvider.notifier)
                              .setLanguage(lang);
                        },
                      );
                      final comfortChip = MindPressable(
                        key: const ValueKey<String>('auth-larger-text-toggle'),
                        semanticLabel: strings.largerTextToggleLabel,
                        selected: comfortMode,
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          ref
                              .read(displayComfortProvider.notifier)
                              .setComfortMode(!comfortMode);
                        },
                        borderRadius: BorderRadius.circular(tokens.chipRadius),
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: comfortMode
                                ? tokens.primarySoft
                                : tokens.surface2,
                            borderRadius: BorderRadius.circular(
                              tokens.chipRadius,
                            ),
                            border: Border.all(
                              color: comfortMode
                                  ? tokens.primary
                                  : tokens.line,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'AA',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: tokens.ink,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  strings.largerTextToggleLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: tokens.ink,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );

                    final stackVertically = constraints.maxWidth < 330 ||
                        MediaQuery.textScalerOf(context).scale(14) > 16.5;
                    if (stackVertically) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          langControl,
                          const SizedBox(height: 10),
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: comfortChip,
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: langControl),
                        const SizedBox(width: 10),
                        comfortChip,
                      ],
                    );
                  },
                ),
                const SizedBox(height: 18),

                const Center(
                  child: MoodFace(
                    mood: AppMood.calm,
                    size: 68,
                    isSelected: true,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  strings.clinicLoginTitle,
                  textAlign: TextAlign.center,
                  style: LabTheme.textStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: tokens.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  strings.clinicLoginSubtitle,
                  textAlign: TextAlign.center,
                  style: LabTheme.textStyle(
                    fontSize: 15,
                    height: 1.45,
                    color: tokens.ink2,
                  ),
                ),
                if (authState.errorMessage != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    key: const ValueKey<String>('auth-error-banner'),
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: tokens.safetySoft,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: tokens.safety.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 18,
                          color: tokens.safety,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            authState.errorMessage!,
                            style: LabTheme.textStyle(
                              color: tokens.safety,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else
                  const SizedBox(height: 20),

                // Hero Card 1: 1-Scan Doctor QR Login (zero typing for any age)
                MindCard(
                  variant: MindCardVariant.tint,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.qr_code_scanner_rounded,
                            size: 22,
                            color: tokens.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              strings.scanDoctorQrBtn,
                              style: LabTheme.textStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16.5,
                                color: tokens.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        strings.scanDoctorQrSub,
                        style: LabTheme.textStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: tokens.ink2,
                        ),
                      ),
                      const SizedBox(height: 14),
                      MindButton(
                        key: const ValueKey<String>('auth-scan-qr-btn'),
                        text: strings.scanDoctorQrBtn,
                        leadingIcon: Icons.qr_code_scanner_rounded,
                        isFullWidth: true,
                        isLoading: authState.status == AuthStatus.loading,
                        onPressed: () => _scanDoctorQr(strings),
                      ),
                      const SizedBox(height: 6),
                      Center(
                        child: TextButton(
                          onPressed: () =>
                              _enterQrFallbackCode(strings, tokens),
                          style: TextButton.styleFrom(
                            minimumSize: const Size(48, 48),
                          ),
                          child: Text(
                            strings.enterQrCodeFallbackBtn,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: tokens.ink2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Card 2: Phone / Username + PIN Form
                MindCard(
                  padding: const EdgeInsets.all(18),
                  child: AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          strings.orLogInWithIdLabel,
                          style: LabTheme.textStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: tokens.ink,
                          ),
                        ),
                        const SizedBox(height: 14),

                        _fieldLabel(strings.loginIdentifierLabel, tokens),
                        const SizedBox(height: 6),
                        TextFormField(
                          key: const ValueKey<String>('auth-identifier-field'),
                          controller: _identifierController,
                          textDirection: TextDirection.ltr,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.username],
                          style: LabTheme.textStyle(
                            color: tokens.ink,
                            fontSize: 15.5,
                          ),
                          validator: (v) {
                            if (v == null || v.trim().length < 3) {
                              return strings.authIdentifierRequiredError;
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            hintText: strings.loginIdentifierHint,
                            prefixIcon: Icon(
                              Icons.person_outline_rounded,
                              size: 20,
                              color: tokens.ink2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        _fieldLabel(strings.pinFieldLabel, tokens),
                        const SizedBox(height: 6),
                        TextFormField(
                          key: const ValueKey<String>('auth-pin-field'),
                          controller: _pinController,
                          textDirection: TextDirection.ltr,
                          obscureText: _obscurePin,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          onFieldSubmitted: (_) => _submitCredentials(),
                          style: LabTheme.textStyle(
                            color: tokens.ink,
                            fontSize: 15.5,
                          ),
                          validator: (v) {
                            if (v == null || v.trim().length < 4) {
                              return strings.authPinTooShortError;
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            hintText: strings.pinFieldHint,
                            prefixIcon: Icon(
                              Icons.lock_outline_rounded,
                              size: 20,
                              color: tokens.ink2,
                            ),
                            suffixIcon: IconButton(
                              tooltip: strings.toggleVisibilityTooltip,
                              constraints: const BoxConstraints(
                                minWidth: 48,
                                minHeight: 48,
                              ),
                              icon: Icon(
                                _obscurePin
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 20,
                                color: tokens.ink2,
                              ),
                              onPressed: () {
                                setState(() => _obscurePin = !_obscurePin);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        MindButton(
                          key: const ValueKey<String>('auth-login-submit-btn'),
                          text: strings.logInBtn,
                          variant: MindButtonVariant.secondary,
                          isFullWidth: true,
                          isLoading: authState.status == AuthStatus.loading,
                          onPressed:
                              authState.isLockedOut ? null : _submitCredentials,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          strings.forgotPinClinicHelp,
                          key: const ValueKey<String>('auth-forgot-pin-help'),
                          textAlign: TextAlign.center,
                          style: LabTheme.textStyle(
                            fontSize: 12.5,
                            height: 1.4,
                            color: tokens.ink2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Center(child: EmergencyHelpLink()),
              ],
            ),
          ),
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String label, MindTokens tokens) {
    return Text(
      label,
      style: LabTheme.textStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
        color: tokens.ink,
      ),
    );
  }
}

class _EnterQrCodeDialog extends StatefulWidget {
  const _EnterQrCodeDialog({
    required this.strings,
    required this.tokens,
  });

  final AppStrings strings;
  final MindTokens tokens;

  @override
  State<_EnterQrCodeDialog> createState() => _EnterQrCodeDialogState();
}

class _EnterQrCodeDialogState extends State<_EnterQrCodeDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    final tokens = widget.tokens;
    return AlertDialog(
      backgroundColor: tokens.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: tokens.line),
      ),
      title: Text(
        strings.scanDoctorQrSheetTitle,
        style: LabTheme.textStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: tokens.ink,
        ),
      ),
      content: TextField(
        controller: _controller,
        minLines: 2,
        maxLines: 4,
        style: TextStyle(color: tokens.ink, fontSize: 14),
        decoration: InputDecoration(
          hintText: '${ClinicInvitePayload.qrPrefix}...',
          suffixIcon: IconButton(
            tooltip: strings.pasteFromClipboardBtn,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            icon: Icon(Icons.content_paste_rounded, color: tokens.ink2),
            onPressed: () async {
              final data = await Clipboard.getData(Clipboard.kTextPlain);
              final text = data?.text?.trim();
              if (text != null && text.isNotEmpty && mounted) {
                _controller.text = text;
              }
            },
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
          child: Text(strings.cancelBtn),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          style: FilledButton.styleFrom(minimumSize: const Size(64, 48)),
          child: Text(strings.logInBtn),
        ),
      ],
    );
  }
}
