import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/localization/locale_controller.dart';
import '../../../app/router/app_router.dart';
import '../../../app/theme/lab_theme.dart';
import '../../../app/theme/mind_tokens.dart';
import '../../../core/security/app_lock_provider.dart';
import '../../../core/security/biometric_service.dart';
import '../../../core/widgets/mind_badge.dart';
import '../../../core/widgets/mind_button.dart';
import '../../../core/widgets/mind_card.dart';
import '../../../core/widgets/mind_segmented.dart';
import '../data/clinician_auth_service.dart';

/// Clinic PIN & optional Biometric gate for the Mindora Doctor Edition.
///
/// Ensures psychiatric records in `main_clinician.dart` are never exposed on
/// cold boot without explicit clinician unlock.
class ClinicianAuthScreen extends ConsumerStatefulWidget {
  const ClinicianAuthScreen({super.key});

  @override
  ConsumerState<ClinicianAuthScreen> createState() =>
      _ClinicianAuthScreenState();
}

class _ClinicianAuthScreenState extends ConsumerState<ClinicianAuthScreen> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();

  bool _loadingConfig = true;
  bool _isSetupMode = false;
  bool _submitting = false;
  bool _obscurePin = true;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _checkPinStatus();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _checkPinStatus() async {
    final hasPin = await ref.read(clinicianAuthServiceProvider).isPinConfigured();
    if (!mounted) return;
    setState(() {
      _isSetupMode = !hasPin;
      _loadingConfig = false;
    });
  }

  Future<void> _submit(AppStrings strings) async {
    final pin = _pinController.text.trim();
    if (pin.length < 4) {
      setState(() => _errorText = strings.clinicianPinTooShortError);
      return;
    }

    if (_isSetupMode) {
      final confirm = _confirmPinController.text.trim();
      if (pin != confirm) {
        setState(() => _errorText = strings.clinicianPinMismatchError);
        return;
      }
      setState(() {
        _submitting = true;
        _errorText = null;
      });
      try {
        await ref.read(clinicianAuthServiceProvider).setupPin(pin);
        HapticFeedback.mediumImpact();
        if (mounted) {
          GoRouter.maybeOf(context)?.go(AppRouter.clinician);
        }
      } finally {
        if (mounted) setState(() => _submitting = false);
      }
      return;
    }

    setState(() {
      _submitting = true;
      _errorText = null;
    });
    try {
      final ok = await ref.read(clinicianAuthServiceProvider).verifyAndUnlock(
            pin,
          );
      if (!mounted) return;
      if (ok) {
        HapticFeedback.mediumImpact();
        GoRouter.maybeOf(context)?.go(AppRouter.clinician);
      } else {
        HapticFeedback.heavyImpact();
        setState(() => _errorText = strings.clinicianInvalidPinError);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _tryBiometricUnlock(AppStrings strings) async {
    final ok = await ref.read(clinicianAuthServiceProvider).unlockWithBiometrics(
          BiometricSecurityService(),
          localizedReason: strings.clinicianAuthSubtitle,
        );
    if (!mounted) return;
    if (ok) {
      HapticFeedback.mediumImpact();
      GoRouter.maybeOf(context)?.go(AppRouter.clinician);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final strings = ref.watch(appStringsProvider);
    final locale = ref.watch(localeControllerProvider);
    final appLock = ref.watch(appLockProvider);

    final langIndex = switch (locale.languageCode) {
      'fr' => 1,
      'ar' => 2,
      _ => 0,
    };

    return Scaffold(
      backgroundColor: tokens.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Mindora',
                          style: LabTheme.textStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: tokens.ink,
                          ),
                        ),
                      ),
                      MindBadge(label: strings.doctorEditionBadge),
                    ],
                  ),
                  const SizedBox(height: 14),
                  MindSegmented(
                    index: langIndex,
                    labels: const ['English', 'Français', 'العربية'],
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
                  ),
                  const SizedBox(height: 24),
                  if (_loadingConfig)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else
                    MindCard(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: tokens.cardTint,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: tokens.line),
                              ),
                              child: Icon(
                                Icons.medical_services_outlined,
                                size: 26,
                                color: tokens.ink,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _isSetupMode
                                ? strings.clinicianPinSetupTitle
                                : strings.clinicianAuthTitle,
                            textAlign: TextAlign.center,
                            style: LabTheme.textStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              color: tokens.ink,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _isSetupMode
                                ? strings.clinicianPinSetupSubtitle
                                : strings.clinicianAuthSubtitle,
                            textAlign: TextAlign.center,
                            style: LabTheme.textStyle(
                              fontSize: 14,
                              height: 1.45,
                              color: tokens.ink2,
                            ),
                          ),
                          if (_errorText != null) ...[
                            const SizedBox(height: 14),
                            Container(
                              key: const ValueKey<String>(
                                'clinician-auth-error-banner',
                              ),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: tokens.safetySoft,
                                borderRadius: BorderRadius.circular(12),
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
                                      _errorText!,
                                      style: LabTheme.textStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: tokens.safety,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 18),
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: TextField(
                              key: const ValueKey<String>(
                                'clinician-auth-pin-field',
                              ),
                              controller: _pinController,
                              obscureText: _obscurePin,
                              keyboardType: TextInputType.number,
                              textInputAction: _isSetupMode
                                  ? TextInputAction.next
                                  : TextInputAction.done,
                              onSubmitted: (_) {
                                if (!_isSetupMode) _submit(strings);
                              },
                              style: LabTheme.textStyle(
                                fontSize: 16,
                                color: tokens.ink,
                              ),
                              decoration: InputDecoration(
                                labelText: strings.clinicianPinFieldLabel,
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
                                  onPressed: () =>
                                      setState(() => _obscurePin = !_obscurePin),
                                ),
                              ),
                            ),
                          ),
                          if (_isSetupMode) ...[
                            const SizedBox(height: 12),
                            Directionality(
                              textDirection: TextDirection.ltr,
                              child: TextField(
                                key: const ValueKey<String>(
                                  'clinician-auth-confirm-pin-field',
                                ),
                                controller: _confirmPinController,
                                obscureText: _obscurePin,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _submit(strings),
                                style: LabTheme.textStyle(
                                  fontSize: 16,
                                  color: tokens.ink,
                                ),
                                decoration: InputDecoration(
                                  labelText: strings.clinicianConfirmPinLabel,
                                  prefixIcon: Icon(
                                    Icons.verified_user_outlined,
                                    size: 20,
                                    color: tokens.ink2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 18),
                          MindButton(
                            key: const ValueKey<String>(
                              'clinician-auth-submit-btn',
                            ),
                            text: _isSetupMode
                                ? strings.clinicianCreatePinBtn
                                : strings.clinicianUnlockBtn,
                            leadingIcon: Icons.lock_open_rounded,
                            isFullWidth: true,
                            isLoading: _submitting,
                            onPressed: () => _submit(strings),
                          ),
                          if (!_isSetupMode && appLock.isEnabled) ...[
                            const SizedBox(height: 10),
                            MindButton(
                              text: strings.unlockWithBiometricsBtn,
                              variant: MindButtonVariant.secondary,
                              leadingIcon: Icons.fingerprint_rounded,
                              isFullWidth: true,
                              onPressed: () => _tryBiometricUnlock(strings),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
