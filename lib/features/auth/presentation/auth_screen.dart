import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/router/app_router.dart';
import '../../../app/theme/lab_theme.dart';
import '../../../app/theme/mind_tokens.dart';
import '../../../core/safety/support_button.dart';
import '../../../core/security/app_lock_provider.dart';
import '../../../core/widgets/bouncing_widget.dart';
import '../../../core/widgets/fingerprint_thread_signature.dart';
import '../../clinician/presentation/clinician_shell_screen.dart';
import '../controllers/auth_controller.dart';
import '../domain/auth_state.dart';

/// The Sovereign Authentication & Vault Unlock Screen for Mind Forensics.
///
/// Features:
/// - Unlock existing cloud vault (Email & Password)
/// - Create new cloud vault (Email, Password, Codename)
/// - Instant Anonymous Sovereign Vault (Zero personal data, complete privacy)
/// - Quick Biometric Unlock for previously authorized devices
/// - Direct bridge to the 6-Step Onboarding Journey
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isSignUp = false;
  bool _obscurePassword = true;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _codenameController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _codenameController.dispose();
    super.dispose();
  }

  Future<void> _submitEmailAuth() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.lightImpact();

    final authCtrl = ref.read(authControllerProvider.notifier);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final codename = _codenameController.text.trim();

    bool success = false;
    if (_isSignUp) {
      success = await authCtrl.signUpWithEmail(
        email,
        password,
        codename: codename.isNotEmpty ? codename : null,
      );
    } else {
      success = await authCtrl.signInWithEmail(email, password);
    }

    if (success && mounted) {
      final authState = ref.read(authControllerProvider);
      if (!authState.hasCompletedOnboarding) {
        context.go(AppRouter.onboarding);
      } else {
        context.go(AppRouter.home);
      }
    }
  }

  Future<void> _continueAnonymously() async {
    HapticFeedback.mediumImpact();
    final user = await ref
        .read(authControllerProvider.notifier)
        .createAnonymousVault();

    if (user != null && mounted) {
      final authState = ref.read(authControllerProvider);
      if (!authState.hasCompletedOnboarding) {
        context.go(AppRouter.onboarding);
      } else {
        context.go(AppRouter.home);
      }
    }
  }

  Future<void> _quickBiometricUnlock() async {
    HapticFeedback.selectionClick();
    final lockNotifier = ref.read(appLockProvider.notifier);
    final unlocked = await lockNotifier.unlock(
      reason: 'Authenticate to access Mind Forensics',
    );
    if (unlocked && mounted) {
      final authState = ref.read(authControllerProvider);
      if (authState.user != null) {
        if (!authState.hasCompletedOnboarding) {
          context.go(AppRouter.onboarding);
        } else {
          context.go(AppRouter.home);
        }
      } else {
        final strings = ref.read(appStringsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              strings.isArabic
                  ? 'الرجاء تسجيل الدخول أو فتح الخزينة للمتابعة.'
                  : (strings.isFrench
                      ? 'Veuillez vous connecter ou ouvrir un espace privé pour continuer.'
                      : 'Sign in or continue to a vault session to enter.'),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final strings = ref.watch(appStringsProvider);
    final authState = ref.watch(authControllerProvider);
    final lockState = ref.watch(appLockProvider);

    final bg = tokens.bg;
    final surfaceColor = tokens.surface;
    final borderColor = tokens.line;
    final textPrimary = tokens.ink;
    final textSecondary = tokens.ink2;
    final sageAccent = tokens.ink;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          'Mind Forensics',
          style: LabTheme.textStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: textPrimary,
          ),
        ),
        actions: const [
          SupportButton(),
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          physics: const BouncingScrollPhysics(),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 8),
                const FingerprintThreadSignature(size: 72),
                const SizedBox(height: 20),

                // Editorial Title
                Text(
                  strings.authTitle,
                  textAlign: TextAlign.center,
                  style: LabTheme.textStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  strings.authSubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: textSecondary,
                  ),
                ),

                const SizedBox(height: 28),

                // Mode Switcher (Sign In vs Create Vault)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: tokens.surface2,
                    borderRadius: BorderRadius.circular(tokens.buttonRadius),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: BouncingWidget(
                          onTap: () {
                            if (_isSignUp) {
                              HapticFeedback.lightImpact();
                              setState(() => _isSignUp = false);
                              ref.read(authControllerProvider.notifier).clearError();
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            constraints: const BoxConstraints(minHeight: 40),
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: !_isSignUp
                                  ? tokens.ink
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(tokens.buttonRadius - 2),
                            ),
                            child: Text(
                              strings.signInTab.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: !_isSignUp
                                    ? tokens.bg
                                    : textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: BouncingWidget(
                          onTap: () {
                            if (!_isSignUp) {
                              HapticFeedback.lightImpact();
                              setState(() => _isSignUp = true);
                              ref.read(authControllerProvider.notifier).clearError();
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            constraints: const BoxConstraints(minHeight: 40),
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _isSignUp
                                  ? tokens.ink
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(tokens.buttonRadius - 2),
                            ),
                            child: Text(
                              strings.signUpTab.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: _isSignUp
                                    ? tokens.bg
                                    : textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Error Banner
                if (authState.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: tokens.safetySoft,
                      borderRadius: BorderRadius.circular(tokens.chipRadius),
                      border: Border.all(
                        color: tokens.safety.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 16,
                          color: tokens.safety,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            strings.localizeAuthError(authState.errorMessage!),
                            style: TextStyle(
                              color: tokens.safety,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Input Fields
                if (_isSignUp) ...[
                  _buildInputLabel(strings.codenameFieldLabel, textSecondary),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _codenameController,
                    style: TextStyle(color: textPrimary, fontSize: 13),
                    decoration: _inputDecoration(
                      strings.codenameFieldHint,
                      Icons.badge_outlined,
                      surfaceColor,
                      borderColor,
                      textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                _buildInputLabel(strings.emailFieldLabel, textSecondary),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: textPrimary, fontSize: 13),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required';
                    if (!v.contains('@')) return 'Enter a valid email address';
                    return null;
                  },
                  decoration: _inputDecoration(
                    strings.emailFieldHint,
                    Icons.alternate_email_rounded,
                    surfaceColor,
                    borderColor,
                    textSecondary,
                  ),
                ),

                const SizedBox(height: 16),

                _buildInputLabel(strings.passwordFieldLabel, textSecondary),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: TextStyle(color: textPrimary, fontSize: 13),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Password is required';
                    if (v.trim().length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                  decoration: _inputDecoration(
                    strings.passwordFieldHint,
                    Icons.lock_outline_rounded,
                    surfaceColor,
                    borderColor,
                    textSecondary,
                    suffixIcon: IconButton(
                      tooltip: strings.toggleVisibilityTooltip,
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 16,
                        color: textSecondary,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: tokens.ink,
                      foregroundColor: tokens.bg,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(tokens.buttonRadius),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: authState.status == AuthStatus.loading
                        ? null
                        : _submitEmailAuth,
                    child: authState.status == AuthStatus.loading
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: tokens.bg,
                            ),
                          )
                        : Text(
                            _isSignUp
                                ? strings.createVaultBtn.toUpperCase()
                                : strings.unlockVaultBtn.toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12.5,
                              letterSpacing: 0.6,
                            ),
                          ),
                  ),
                ),

                // Biometrics Quick Unlock Option (when enabled & a vault session exists)
                if (lockState.isEnabled && authState.user != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: sageAccent,
                        minimumSize: const Size.fromHeight(48),
                        side: BorderSide(
                          color: borderColor,
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(tokens.buttonRadius),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.fingerprint_rounded, size: 18),
                      label: Text(
                        strings.biometricUnlockBtn.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      onPressed: _quickBiometricUnlock,
                    ),
                  ),
                ],

                const SizedBox(height: 28),

                // Minimalist Divider with "OR"
                Row(
                  children: [
                    Expanded(child: Divider(color: borderColor, height: 1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: textSecondary.withValues(alpha: 0.6),
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: borderColor, height: 1)),
                  ],
                ),

                const SizedBox(height: 24),

                // Anonymous Sovereign Vault Card
                BouncingWidget(
                  onTap: _continueAnonymously,
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(tokens.cardRadius),
                      border: Border.all(
                        color: borderColor,
                        width: 1,
                      ),
                      boxShadow: tokens.shadows,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: sageAccent.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(tokens.chipRadius),
                              ),
                              child: Icon(
                                Icons.shield_outlined,
                                size: 18,
                                color: sageAccent,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          strings.anonymousOptionTitle,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                            color: textPrimary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: sageAccent.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'PRIVATE',
                                          style: TextStyle(
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.4,
                                            color: sageAccent,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    strings.anonymousChoiceBadge,
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: sageAccent,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                              color: sageAccent,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          strings.anonymousOptionSubtitle,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Link to Onboarding Journey
                InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.go(AppRouter.onboarding);
                  },
                  borderRadius: BorderRadius.circular(tokens.chipRadius),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          strings.newInvestigatorPrompt,
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          strings.startExplorationBtn,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: tokens.ink,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Direct Entry to Psychiatrist / Clinician Portal
                Semantics(
                  button: true,
                  label: strings.clinicianPortalBtnLabel,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      final router = GoRouter.maybeOf(context);
                      if (router != null) {
                        router.go(AppRouter.clinician);
                      } else {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ClinicianShellScreen(),
                          ),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(context.tokens.chipRadius),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.medical_services_outlined,
                              size: 15,
                              color: textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                strings.clinicianPortalBtnLabel,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: textSecondary,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label, Color textSecondary) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: textSecondary,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    String hint,
    IconData prefixIcon,
    Color surfaceColor,
    Color borderColor,
    Color textSecondary, {
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 12, color: textSecondary.withValues(alpha: 0.6)),
      prefixIcon: Icon(prefixIcon, size: 16, color: textSecondary),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: surfaceColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(context.tokens.buttonRadius),
        borderSide: BorderSide(color: borderColor, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(context.tokens.buttonRadius),
        borderSide: BorderSide(color: borderColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(context.tokens.buttonRadius),
        borderSide: BorderSide(color: context.tokens.ink, width: 1.2),
      ),
    );
  }
}

