import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/localization/locale_controller.dart';
import '../../../app/router/app_router.dart';
import '../../../app/theme/lab_theme.dart';
import '../../../app/theme/mind_tokens.dart';
import '../../../core/safety/support_button.dart';
import '../../../core/widgets/ambient_scaffold.dart';
import '../../../core/widgets/mind_badge.dart';
import '../../../core/widgets/mind_button.dart';
import '../../../core/widgets/mind_card.dart';
import '../../../core/widgets/mind_toast.dart';
import '../../../core/widgets/mood_face.dart';
import '../../clinic_sync/controllers/clinic_sync_providers.dart';
import '../../clinic_sync/domain/clinic_account_models.dart';
import '../controllers/auth_controller.dart';

/// One-time transparency & welcome screen shown after a patient logs into a
/// doctor-provisioned clinic account for the first time.
class ClinicWelcomeScreen extends ConsumerStatefulWidget {
  const ClinicWelcomeScreen({super.key});

  @override
  ConsumerState<ClinicWelcomeScreen> createState() =>
      _ClinicWelcomeScreenState();
}

class _ClinicWelcomeScreenState extends ConsumerState<ClinicWelcomeScreen> {
  bool _showChangePin = false;
  bool _isSavingPin = false;
  bool _pinUpdated = false;
  bool _isCompleting = false;
  String? _pinError;

  final TextEditingController _currentPinCtrl = TextEditingController();
  final TextEditingController _newPinCtrl = TextEditingController();

  @override
  void dispose() {
    _currentPinCtrl.dispose();
    _newPinCtrl.dispose();
    super.dispose();
  }

  Future<void> _updatePin(AppStrings strings) async {
    final user = ref.read(authControllerProvider).user;
    if (user == null) return;

    final cur = _currentPinCtrl.text.trim();
    final next = _newPinCtrl.text.trim();
    if (next.length < 4) {
      setState(() => _pinError = strings.pinFieldHint);
      return;
    }

    setState(() {
      _isSavingPin = true;
      _pinError = null;
    });
    try {
      await ref.read(clinicAuthRepositoryProvider).changePatientPin(
            patientId: user.id,
            currentPin: cur,
            newPin: next,
          );
      if (mounted) {
        setState(() {
          _pinUpdated = true;
          _showChangePin = false;
          _isSavingPin = false;
        });
        showMindToast(context, strings.pinChangedToast);
      }
    } on ClinicAuthException catch (e) {
      if (mounted) {
        setState(() {
          _pinError = strings.localizedClinicAuthError(e.code);
          _isSavingPin = false;
        });
      }
    }
  }

  Future<void> _continueToHome() async {
    if (_isCompleting) return;
    HapticFeedback.mediumImpact();
    setState(() => _isCompleting = true);
    await ref.read(authControllerProvider.notifier).acceptClinicWelcome();
    if (mounted) {
      GoRouter.maybeOf(context)?.go(AppRouter.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final strings = ref.watch(appStringsProvider);
    final user = ref.watch(authControllerProvider).user;
    final patientName = user?.codename ?? '';
    final doctorName = user?.doctorName ??
        (strings.isArabic
            ? 'طبيبك'
            : (strings.isFrench ? 'votre médecin' : 'your doctor'));

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
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: MindBadge(
              key: const ValueKey<String>('clinic-welcome-lang-btn'),
              icon: Icons.language_rounded,
              label: AppLanguage.fromCode(strings.languageCode).shortCode,
              onTap: () {
                HapticFeedback.selectionClick();
                final next = switch (strings.languageCode) {
                  'en' => AppLanguage.french,
                  'fr' => AppLanguage.arabic,
                  _ => AppLanguage.english,
                };
                ref.read(localeControllerProvider.notifier).setLanguage(next);
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: MoodFace(
                  mood: AppMood.good,
                  size: 72,
                  isSelected: true,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                strings.clinicWelcomeTitle(patientName),
                textAlign: TextAlign.center,
                style: LabTheme.textStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: tokens.ink,
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: MindBadge(
                  icon: Icons.medical_services_outlined,
                  label: strings.clinicWelcomeConnectedTo(doctorName),
                  backgroundColor: tokens.primarySoft,
                  borderColor: tokens.primary.withValues(alpha: 0.3),
                  textColor: tokens.ink,
                ),
              ),
              const SizedBox(height: 20),

              // Card 1: Automatic Doctor Sync + "Keep just for me" guarantee
              MindCard(
                variant: MindCardVariant.tint,
                padding: const EdgeInsets.all(18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.sync_lock_outlined,
                      size: 22,
                      color: tokens.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.clinicWelcomeAutoSyncTitle,
                            style: LabTheme.textStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: tokens.ink,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            strings.clinicWelcomeAutoSyncBody(doctorName),
                            style: LabTheme.textStyle(
                              fontSize: 14.5,
                              height: 1.45,
                              color: tokens.ink2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Card 2: Emergency 2:00 AM safety notice
              MindCard(
                padding: const EdgeInsets.all(18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 22,
                      color: tokens.safety,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.clinicWelcomeNotEmergencyTitle,
                            style: LabTheme.textStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: tokens.ink,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            strings.clinicWelcomeNotEmergencyBody,
                            style: LabTheme.textStyle(
                              fontSize: 14,
                              height: 1.45,
                              color: tokens.ink2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Optional PIN personalization (expandable, non-forced)
              if (!_pinUpdated)
                MindCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      MindButton(
                        text: strings.setOwnPinOptionalBtn,
                        leadingIcon: Icons.pin_outlined,
                        variant: MindButtonVariant.soft,
                        isFullWidth: true,
                        onPressed: () =>
                            setState(() => _showChangePin = !_showChangePin),
                      ),
                      if (_showChangePin) ...[
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _currentPinCtrl,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: strings.currentPinLabel,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _newPinCtrl,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: strings.newPinLabel,
                          ),
                        ),
                        if (_pinError != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _pinError!,
                            style: TextStyle(
                              fontSize: 13,
                              color: tokens.safety,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        MindButton(
                          text: strings.saveNewPinBtn,
                          variant: MindButtonVariant.secondary,
                          isFullWidth: true,
                          isLoading: _isSavingPin,
                          onPressed: () => _updatePin(strings),
                        ),
                      ],
                    ],
                  ),
                ),

              const SizedBox(height: 20),
              MindButton(
                key: const ValueKey<String>('clinic-welcome-start-btn'),
                text: strings.enterAppBtn,
                trailingIcon: Icons.arrow_forward_rounded,
                isFullWidth: true,
                isLoading: _isCompleting,
                onPressed: _continueToHome,
              ),
              const SizedBox(height: 16),
              const Center(child: EmergencyHelpLink()),
            ],
          ),
        ),
      ),
    );
  }
}
