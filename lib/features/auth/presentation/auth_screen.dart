import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/config/app_edition.dart';
import '../../../app/localization/app_strings.dart';
import '../../../app/router/app_router.dart';
import '../../../app/theme/lab_theme.dart';
import '../../../app/theme/mind_tokens.dart';
import '../../../core/safety/support_button.dart';
import '../../../core/security/app_lock_provider.dart';
import '../../../core/widgets/ambient_scaffold.dart';
import '../../../core/widgets/mind_button.dart';
import '../../../core/widgets/mind_card.dart';
import '../../../core/widgets/mind_segmented.dart';
import '../../../core/widgets/mind_toast.dart';
import '../../../core/widgets/mood_face.dart';
import '../../clinician/presentation/clinician_shell_screen.dart';
import '../controllers/auth_controller.dart';
import '../domain/auth_state.dart';

/// Calm, plain-language entry screen for Mindora.
///
/// Leads with the private local-phone option ("Continue privately on this phone")
/// while offering optional email sign-in / account creation and Psychiatrist
/// Workspace entry below, with zero jargon or ALL-CAPS labels.
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

    final success = _isSignUp
        ? await authCtrl.signUpWithEmail(
            email,
            password,
            codename: codename.isNotEmpty ? codename : null,
          )
        : await authCtrl.signInWithEmail(email, password);

    if (success && mounted) {
      if (AppEditionConfig.isClinicianApp) {
        GoRouter.maybeOf(context)?.go(AppRouter.clinician);
        return;
      }
      final authState = ref.read(authControllerProvider);
      if (!authState.hasCompletedOnboarding) {
        GoRouter.maybeOf(context)?.go(AppRouter.onboarding);
      } else {
        GoRouter.maybeOf(context)?.go(AppRouter.home);
      }
    }
  }

  Future<void> _continueAnonymously() async {
    HapticFeedback.mediumImpact();
    final user = await ref
        .read(authControllerProvider.notifier)
        .createAnonymousVault();

    if (user != null && mounted) {
      if (AppEditionConfig.isClinicianApp) {
        GoRouter.maybeOf(context)?.go(AppRouter.clinician);
        return;
      }
      final authState = ref.read(authControllerProvider);
      if (!authState.hasCompletedOnboarding) {
        GoRouter.maybeOf(context)?.go(AppRouter.onboarding);
      } else {
        GoRouter.maybeOf(context)?.go(AppRouter.home);
      }
    }
  }

  Future<void> _quickBiometricUnlock() async {
    HapticFeedback.selectionClick();
    final lockNotifier = ref.read(appLockProvider.notifier);
    final unlocked = await lockNotifier.unlock(
      reason: 'Unlock Mindora',
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
        showMindToast(context, strings.signInRequiredToast);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final strings = ref.watch(appStringsProvider);
    final authState = ref.watch(authControllerProvider);
    final lockState = ref.watch(appLockProvider);

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
        actions: const [SupportButton(), SizedBox(width: 8)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          physics: const BouncingScrollPhysics(),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: MoodFace(
                    mood: AppMood.calm,
                    size: 72,
                    isSelected: true,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  strings.authTitle,
                  textAlign: TextAlign.center,
                  style: LabTheme.textStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: tokens.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  strings.authSubtitle,
                  textAlign: TextAlign.center,
                  style: LabTheme.textStyle(
                    fontSize: 15,
                    height: 1.45,
                    color: tokens.ink2,
                  ),
                ),
                const SizedBox(height: 22),

                // Hero Card 1: Private on this phone (Recommended)
                MindCard(
                  variant: MindCardVariant.tint,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            size: 22,
                            color: tokens.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              strings.anonymousOptionTitle,
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
                        strings.anonymousOptionSubtitle,
                        style: LabTheme.textStyle(
                          fontSize: 14.0,
                          height: 1.45,
                          color: tokens.ink2,
                        ),
                      ),
                      const SizedBox(height: 14),
                      MindButton(
                        text: strings.onboardingContinuePrivatelyBtn,
                        isFullWidth: true,
                        onPressed: _continueAnonymously,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // Card 2: Optional Local Profile Sign-In / Creation
                MindCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      MindSegmented(
                        index: _isSignUp ? 1 : 0,
                        labels: [strings.signInTab, strings.signUpTab],
                        onChanged: (idx) {
                          setState(() => _isSignUp = idx == 1);
                          ref
                              .read(authControllerProvider.notifier)
                              .clearError();
                        },
                      ),
                      const SizedBox(height: 10),
                      Text(
                        strings.localProfileOnlyNote,
                        style: LabTheme.textStyle(
                          fontSize: 13.0,
                          height: 1.4,
                          color: tokens.ink2,
                        ),
                      ),
                      const SizedBox(height: 14),

                      if (authState.errorMessage != null) ...[
                        Container(
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
                                  strings.localizeAuthError(
                                    authState.errorMessage!,
                                  ),
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
                      ],

                      if (_isSignUp) ...[
                        _fieldLabel(strings.codenameFieldLabel, tokens),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _codenameController,
                          style: LabTheme.textStyle(
                            color: tokens.ink,
                            fontSize: 15.5,
                          ),
                          decoration: InputDecoration(
                            hintText: strings.codenameFieldHint,
                            prefixIcon: Icon(
                              Icons.badge_outlined,
                              size: 20,
                              color: tokens.ink2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      _fieldLabel(strings.emailFieldLabel, tokens),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: LabTheme.textStyle(
                          color: tokens.ink,
                          fontSize: 15.5,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty || !v.contains('@')) {
                            return strings.emailFieldHint;
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: strings.emailFieldHint,
                          prefixIcon: Icon(
                            Icons.alternate_email_rounded,
                            size: 20,
                            color: tokens.ink2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      _fieldLabel(strings.passwordFieldLabel, tokens),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: LabTheme.textStyle(
                          color: tokens.ink,
                          fontSize: 15.5,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().length < 6) {
                            return strings.passwordFieldHint;
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: strings.passwordFieldHint,
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
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 20,
                              color: tokens.ink2,
                            ),
                            onPressed: () {
                              setState(
                                () => _obscurePassword = !_obscurePassword,
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      MindButton(
                        text: _isSignUp
                            ? strings.createVaultBtn
                            : strings.unlockVaultBtn,
                        variant: MindButtonVariant.secondary,
                        isFullWidth: true,
                        isLoading: authState.status == AuthStatus.loading,
                        onPressed: _submitEmailAuth,
                      ),

                      if (lockState.isEnabled && authState.user != null) ...[
                        const SizedBox(height: 10),
                        MindButton(
                          text: strings.biometricUnlockBtn,
                          leadingIcon: Icons.fingerprint_rounded,
                          variant: MindButtonVariant.soft,
                          isFullWidth: true,
                          onPressed: _quickBiometricUnlock,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Onboarding shortcut (Patient Edition only)
                if (!AppEditionConfig.isClinicianApp)
                  MindButton(
                    text: strings.startExplorationBtn,
                    variant: MindButtonVariant.soft,
                    leadingIcon: Icons.tune_rounded,
                    isFullWidth: true,
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      GoRouter.maybeOf(context)?.go(AppRouter.onboarding);
                    },
                  ),

                const SizedBox(height: 8),

                // Dedicated Psychiatrist / Clinic Admin Portal Card
                MindCard(
                  variant: MindCardVariant.flat,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.medical_services_outlined,
                            size: 20,
                            color: tokens.ink,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              strings.clinicPortalAuthBanner,
                              style: LabTheme.textStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: tokens.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        strings.clinicPortalAuthSub,
                        style: LabTheme.textStyle(
                          fontSize: 13.0,
                          height: 1.4,
                          color: tokens.ink2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      MindButton(
                        key: const ValueKey<String>('auth-clinician-portal-btn'),
                        text: strings.clinicianPortalBtnLabel,
                        leadingIcon: Icons.medical_services_outlined,
                        variant: MindButtonVariant.soft,
                        isFullWidth: true,
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          final router = GoRouter.maybeOf(context);
                          if (router != null) {
                            router.go(AppRouter.clinician);
                          } else {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const ClinicianShellScreen(),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
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
