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
import '../../../app/theme/mind_tokens.dart';
import '../../../app/theme/theme_controller.dart';
import '../../../core/notifications/gentle_reminder_service.dart';
import '../../../core/safety/support_button.dart';
import '../../../core/security/app_lock_provider.dart';
import '../../../core/security/biometric_service.dart';
import '../../../core/security/secure_key_manager.dart';
import '../../../core/widgets/botanical_emblem.dart';
import '../../../core/widgets/mind_badge.dart';
import '../../../core/widgets/mind_button.dart';
import '../../../core/widgets/mind_card.dart';
import '../../../core/widgets/mind_page_container.dart';
import '../../../core/widgets/mind_pressable.dart';
import '../../../core/widgets/mind_segmented.dart';
import '../../../core/widgets/mind_switch.dart';
import '../../../core/widgets/mind_toast.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../backup/data/unified_backup_service.dart';
import '../../clinic_sync/controllers/clinic_sync_providers.dart';
import '../../clinic_sync/domain/clinic_account_models.dart';
import '../../clinician/presentation/clinician_shell_screen.dart';
import '../../investigation/controllers/investigation_providers.dart';
import '../../journal/controllers/journal_memory_controller.dart';
import '../../journey/controllers/journey_controller.dart';
import '../../mind_trace/controllers/mind_trace_controller.dart';
import '../../observatory/controllers/observatory_controllers.dart';
import '../../observatory/data/local_symptom_repository.dart';
import '../../observatory/presentation/inner_observatory_screen.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../profile/presentation/psychological_profile_screen.dart';

/// Me & Preferences Screen.
///
/// Minimalist, age-inclusive 3-card settings layout:
/// 1. Look & reading (Theme swatches, Language, Reading Comfort, Larger Text)
/// 2. About me & reminders (Preferred name, Care focus, Symptoms, Reminders)
/// 3. Privacy & account (App lock, PIN, Privacy guarantees, Emergency help, Log out, Delete data)
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const String _prefGentleNotif = 'mf_gentle_notifications';
  static const String _prefNotifFreq = 'mf_notification_freq';

  bool _gentleNotifications = false;
  String _notificationFrequency = 'daily';

  @override
  void initState() {
    super.initState();
    _loadPersistedSettings();
  }

  Future<void> _loadPersistedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _gentleNotifications = prefs.getBool(_prefGentleNotif) ?? false;
        _notificationFrequency = prefs.getString(_prefNotifFreq) ?? 'daily';
      });
    }
  }

  Future<void> _setGentleNotifications(bool val) async {
    HapticFeedback.lightImpact();
    final strings = ref.read(appStringsProvider);
    if (val) {
      final approved = await GentleReminderService.showPrePermissionSheet(
        context,
        strings,
      );
      if (!approved || !mounted) return;
    }
    final scheduled = await ref.read(gentleReminderServiceProvider).syncSchedule(
          enabled: val,
          frequency: _notificationFrequency,
          strings: strings,
        );
    final effectiveEnabled = val && scheduled;
    if (mounted) {
      setState(() => _gentleNotifications = effectiveEnabled);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefGentleNotif, effectiveEnabled);
    if (val && !scheduled && mounted) {
      showMindToast(context, strings.reminderPermissionDeniedToast);
    }
  }

  Future<void> _setNotificationFrequency(String freq) async {
    HapticFeedback.selectionClick();
    setState(() => _notificationFrequency = freq);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefNotifFreq, freq);
    if (_gentleNotifications) {
      await ref.read(gentleReminderServiceProvider).syncSchedule(
            enabled: true,
            frequency: freq,
            strings: ref.read(appStringsProvider),
          );
    }
  }

  Future<void> _showEditPreferredNameDialog(
    BuildContext context,
    AppStrings strings,
    MindTokens tokens,
    String currentName,
  ) async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _EditPreferredNameDialog(
        strings: strings,
        tokens: tokens,
        initialName: currentName,
      ),
    );
    if (result != null && mounted) {
      await ref
          .read(profileControllerProvider.notifier)
          .updateAboutMe(preferredName: result);
    }
  }

  void _startDoubleConfirmReset(AppStrings strings, MindTokens tokens) {
    HapticFeedback.heavyImpact();
    showDialog<void>(
      context: context,
      builder: (step1Ctx) => AlertDialog(
        backgroundColor: tokens.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: tokens.line, width: 1),
        ),
        title: Text(
          strings.resetConfirmStep1Title,
          style: TextStyle(
            color: tokens.ink,
            fontSize: 16.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          strings.resetConfirmStep1Body,
          style: TextStyle(color: tokens.ink2, fontSize: 14, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(step1Ctx).pop(),
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            child: Text(
              strings.keepMyDataBtn,
              style: TextStyle(
                color: tokens.ink,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(48, 48),
              backgroundColor: tokens.safety,
              foregroundColor: tokens.onSafety,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(tokens.buttonRadius),
              ),
            ),
            onPressed: () {
              Navigator.of(step1Ctx).pop();
              _showFinalResetDialog(strings, tokens);
            },
            child: Text(
              strings.continueBtn,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
            ),
          ),
        ],
      ),
    );
  }

  void _showFinalResetDialog(AppStrings strings, MindTokens tokens) {
    showDialog<void>(
      context: context,
      builder: (step2Ctx) => AlertDialog(
        backgroundColor: tokens.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: tokens.safety.withValues(alpha: 0.45),
            width: 1,
          ),
        ),
        title: Text(
          strings.resetConfirmStep2Title,
          style: TextStyle(
            color: tokens.safety,
            fontSize: 16.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          strings.resetConfirmStep2Body,
          style: TextStyle(color: tokens.ink2, fontSize: 14, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(step2Ctx).pop(),
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            child: Text(
              strings.keepMyDataBtn,
              style: TextStyle(
                color: tokens.ink,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(48, 48),
              backgroundColor: tokens.safety,
              foregroundColor: tokens.onSafety,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(tokens.buttonRadius),
              ),
            ),
            onPressed: () async {
              Navigator.of(step2Ctx).pop();
              await _performFullLocalReset();
              if (mounted) {
                showMindToast(context, strings.allDataWipedSnackbar);
              }
            },
            child: Text(
              strings.deleteEverythingForeverBtn,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performFullLocalReset() async {
    await ref.read(caseRepositoryProvider).deleteAllCases();
    ref.invalidate(savedCasesProvider);
    ref.invalidate(activeCaseControllerProvider);
    await ref.read(mindTraceControllerProvider.notifier).clearAllTraces();
    await ref.read(journalMemoryControllerProvider.notifier).clearAll();
    await ref.read(profileControllerProvider.notifier).clearProfile();
    await ref.read(journeyControllerProvider.notifier).resetJourney();
    await ref.read(symptomRepositoryProvider).clearAllData();
    ref.invalidate(symptomReportsControllerProvider);
    ref.invalidate(symptomListControllerProvider);
    await ref.read(authControllerProvider.notifier).deleteAccount();
    await ref.read(appLockProvider.notifier).toggleBiometrics(false);
    await ref.read(gentleReminderServiceProvider).cancelReminders();
    // Do NOT wipe the shared master key here: doing so would orphan encrypted
    // clinic_directory_v1 & clinician_workspace_v1 partitions on shared devices.
    await ref.read(secureKeyManagerProvider).clearGeminiApiKey();
    await ref.read(secureKeyManagerProvider).clearGroqApiKey();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('mf_settings_ai_history');
    await prefs.remove(_prefGentleNotif);
    await prefs.remove(_prefNotifFreq);
    await prefs.remove(BiometricSecurityService.prefKeyBiometric);
    await prefs.remove('mind_forensics_clinical_export_history_v1');
    await prefs.remove(UnifiedBackupService.prefLastBackupTime);
    await prefs.remove(UnifiedBackupService.prefLastBackupJson);
    await prefs.remove(UnifiedBackupService.prefLastBackupCount);
    await prefs.remove(kDisplayComfortPrefKey);
    ref.invalidate(aiConfigProvider);
    ref.invalidate(displayComfortProvider);

    if (mounted) {
      setState(() {
        _gentleNotifications = false;
        _notificationFrequency = 'daily';
      });
      final router = GoRouter.maybeOf(context);
      if (router != null) {
        router.go(AppRouter.auth);
      }
    }
  }

  void _showPrivacyDialog(
    BuildContext context,
    AppStrings strings,
    MindTokens tokens,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tokens.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: tokens.line),
        ),
        title: Text(
          strings.privacyPrinciplesTitle,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: tokens.ink,
          ),
        ),
        content: SingleChildScrollView(
          child: Text(
            strings.privacyPrinciplesBody,
            style: TextStyle(
              fontSize: 13,
              color: tokens.ink2,
              height: 1.5,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            child: Text(
              strings.closeBtn,
              style: TextStyle(color: tokens.ink, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogOut(
    BuildContext context,
    AppStrings strings,
    MindTokens tokens,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: tokens.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: tokens.line),
        ),
        title: Text(
          strings.logOutConfirmTitle,
          style: TextStyle(
            color: tokens.ink,
            fontSize: 16.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          strings.logOutConfirmBody,
          style: TextStyle(color: tokens.ink2, fontSize: 14, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            child: Text(
              strings.cancelBtn,
              style: TextStyle(
                color: tokens.ink2,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(48, 48),
              backgroundColor: tokens.primary,
              foregroundColor: tokens.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(tokens.buttonRadius),
              ),
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: Text(
              strings.logOutBtn,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(authControllerProvider.notifier).signOut();
    if (!context.mounted) return;
    GoRouter.maybeOf(context)?.go(AppRouter.auth);
  }

  Future<void> _showChangePinDialog(
    BuildContext context,
    AppStrings strings,
    MindTokens tokens,
  ) async {
    final user = ref.read(authControllerProvider).user;
    if (user == null) return;
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => _ChangePinDialog(
        patientId: user.id,
        strings: strings,
        tokens: tokens,
      ),
    );
    if (changed == true && mounted) {
      showMindToast(this.context, strings.pinChangedToast);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final currentThemeMode = ref.watch(themeControllerProvider);
    final currentLocale = ref.watch(localeControllerProvider);
    final strings = ref.watch(appStringsProvider);
    final authState = ref.watch(authControllerProvider);
    final appLock = ref.watch(appLockProvider);
    final profileAsync = ref.watch(profileControllerProvider);
    final profile = profileAsync.value;

    final preferredName = profile?.preferredName.trim() ?? '';
    final authUser = authState.user;
    final isClinicConnected = authUser?.isClinicAccount == true;
    final isCloudLinked = authUser != null && !authUser.isAnonymous;

    final themeIndex = currentThemeMode == ThemeMode.light
        ? 0
        : (currentThemeMode == ThemeMode.dark ? 1 : 2);
    final langIndex = currentLocale.languageCode == 'ar'
        ? 2
        : (currentLocale.languageCode == 'fr' ? 1 : 0);
    final comfortMode = ref.watch(displayComfortProvider);

    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: AppBar(
        backgroundColor: tokens.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          strings.navMe,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: tokens.ink,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 48),
        child: MindPageContainer(
          maxWidth: 680,
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Warm Personal Header Card
            MindCard(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: tokens.primarySoft,
                      border: Border.all(
                        color: tokens.primary.withValues(alpha: 0.25),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const BotanicalEmblem(size: 36),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          preferredName.isNotEmpty
                              ? preferredName
                              : strings.meSpaceDefaultTitle,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: tokens.ink,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          strings.profileSubtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: tokens.ink2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        MindBadge(
                          label: isClinicConnected
                              ? strings.connectedToDoctorBadge(
                                  authUser!.doctorName ?? 'Mindora',
                                )
                              : (isCloudLinked
                                    ? strings.vaultStatusCloud
                                    : strings.vaultStatusAnonymous),
                          icon: isClinicConnected || isCloudLinked
                              ? Icons.cloud_done_outlined
                              : Icons.phonelink_lock_outlined,
                          backgroundColor: isClinicConnected || isCloudLinked
                              ? tokens.primarySoft
                              : tokens.surface2,
                          textColor: tokens.ink,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (AppEditionConfig.isClinicianApp &&
                (kDebugMode || profile?.userRole == 'clinician')) ...[
              const SizedBox(height: 14),
              MindButton(
                text: strings.openDoctorWorkspaceBtn,
                leadingIcon: Icons.medical_services_outlined,
                variant: MindButtonVariant.primary,
                isFullWidth: true,
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('mf_clinician_demo_preview', false);
                  if (!context.mounted) return;
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
              ),
            ],

            const SizedBox(height: 22),

            // Card 1: Look & reading
            _sectionLabel(strings.lookAndReadingSection, tokens),
            MindCard(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.themeModeTitle,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: tokens.ink,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildThemeSwatchStrip(
                          tokens: tokens,
                          strings: strings,
                          themeIndex: themeIndex,
                        ),
                        const SizedBox(height: 10),
                        MindSegmented(
                          index: themeIndex,
                          labels: [
                            strings.themeSunriseLabel,
                            strings.themeNightLabel,
                            strings.themeAutoLabel,
                          ],
                          onChanged: (idx) {
                            HapticFeedback.selectionClick();
                            final mode = idx == 0
                                ? ThemeMode.light
                                : (idx == 1
                                      ? ThemeMode.dark
                                      : ThemeMode.system);
                            ref
                                .read(themeControllerProvider.notifier)
                                .setTheme(mode);
                          },
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, thickness: 1, color: tokens.line),
                  _buildSwitchRow(
                    tokens: tokens,
                    icon: Icons.visibility_outlined,
                    title: strings.comfortModeTitle,
                    subtitle: strings.comfortModeSub,
                    value: comfortMode,
                    onChanged: (val) => ref
                        .read(displayComfortProvider.notifier)
                        .setComfortMode(val),
                  ),
                  Divider(height: 1, thickness: 1, color: tokens.line),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.languageTitle,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: tokens.ink,
                          ),
                        ),
                        const SizedBox(height: 10),
                        MindSegmented(
                          index: langIndex,
                          labels: const ['EN', 'FR', 'عربي'],
                          onChanged: (idx) {
                            HapticFeedback.selectionClick();
                            final lang = idx == 2
                                ? AppLanguage.arabic
                                : (idx == 1
                                      ? AppLanguage.french
                                      : AppLanguage.english);
                            ref
                                .read(localeControllerProvider.notifier)
                                .setLanguage(lang);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // Card 2: About me & reminders
            _sectionLabel(strings.aboutMeAndRemindersSection, tokens),
            MindCard(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildNavRow(
                    tokens: tokens,
                    icon: Icons.badge_outlined,
                    title: strings.preferredNameLabel,
                    trailingText: preferredName.isNotEmpty
                        ? preferredName
                        : strings.notSetLabel,
                    onTap: () => _showEditPreferredNameDialog(
                      context,
                      strings,
                      tokens,
                      preferredName,
                    ),
                  ),
                  Divider(height: 1, thickness: 1, color: tokens.line),
                  _buildNavRow(
                    tokens: tokens,
                    icon: Icons.psychology_outlined,
                    title: strings.myStoryAndGoalsLabel,
                    subtitle: strings.myAccountSub,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PsychologicalProfileScreen(),
                      ),
                    ),
                  ),
                  Divider(height: 1, thickness: 1, color: tokens.line),
                  _buildNavRow(
                    tokens: tokens,
                    icon: Icons.spa_outlined,
                    title: strings.toolboxAndBodyNotesLabel,
                    subtitle: strings.calmToolsHeader,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const InnerObservatoryScreen(),
                      ),
                    ),
                  ),
                  Divider(height: 1, thickness: 1, color: tokens.line),
                  _buildSwitchRow(
                    tokens: tokens,
                    icon: Icons.notifications_none_rounded,
                    title: strings.reminderPermissionTitle,
                    subtitle: strings.reminderPermissionBody,
                    value: _gentleNotifications,
                    onChanged: _setGentleNotifications,
                  ),
                  if (_gentleNotifications)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.reminderFrequencyLabel,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: tokens.ink,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _notifFreqChip(
                                'daily',
                                strings.everyDayChip,
                                tokens,
                              ),
                              _notifFreqChip(
                                'alternate',
                                strings.everyTwoDaysChip,
                                tokens,
                              ),
                              _notifFreqChip(
                                'weekly',
                                strings.weeklyChip,
                                tokens,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: tokens.surface2,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: tokens.line),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.notifications_active_outlined,
                                  size: 16,
                                  color: tokens.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${strings.reminderSamplePrefix} "${strings.gentleReminderBodies.first}"',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontStyle: FontStyle.italic,
                                      color: tokens.ink2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // Card 3: Minimalist Privacy, Safety & Account
            _sectionLabel(strings.privacyAccountSection, tokens),
            MindCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildSwitchRow(
                    tokens: tokens,
                    icon: Icons.fingerprint_rounded,
                    title: strings.biometricLockTitle,
                    subtitle: strings.biometricLockDesc,
                    value: appLock.isEnabled,
                    onChanged: (val) async {
                      final success = await ref
                          .read(appLockProvider.notifier)
                          .toggleBiometrics(val);
                      if (!success && val && context.mounted) {
                        showMindToast(
                          context,
                          strings.biometricNotAvailableSnackbar,
                        );
                      }
                    },
                  ),
                  if (isClinicConnected) ...[
                    Divider(height: 1, thickness: 1, color: tokens.line),
                    _buildNavRow(
                      tokens: tokens,
                      icon: Icons.pin_outlined,
                      title: strings.changePinBtn,
                      onTap: () => _showChangePinDialog(context, strings, tokens),
                    ),
                  ],
                  Divider(height: 1, thickness: 1, color: tokens.line),
                  _buildNavRow(
                    tokens: tokens,
                    icon: Icons.verified_user_outlined,
                    title: strings.privacyPrinciplesTitle,
                    onTap: () => _showPrivacyDialog(context, strings, tokens),
                  ),
                  Divider(height: 1, thickness: 1, color: tokens.line),
                  _buildNavRow(
                    tokens: tokens,
                    icon: Icons.health_and_safety_outlined,
                    iconColor: tokens.safety,
                    title: strings.supportCrisisRowTitle,
                    onTap: () => SupportModalSheet.show(context),
                  ),
                  if (authUser?.isAnonymous != true) ...[
                    Divider(height: 1, thickness: 1, color: tokens.line),
                    _buildNavRow(
                      tokens: tokens,
                      icon: Icons.logout_rounded,
                      title: strings.logOutBtn,
                      onTap: () => _confirmLogOut(context, strings, tokens),
                    ),
                  ],
                  Divider(height: 1, thickness: 1, color: tokens.line),
                  _buildNavRow(
                    tokens: tokens,
                    icon: Icons.delete_forever_outlined,
                    iconColor: tokens.safety,
                    title: strings.wipeDataTitle,
                    titleColor: tokens.safety,
                    subtitle: strings.wipeDataDesc,
                    onTap: () => _startDoubleConfirmReset(strings, tokens),
                  ),
                ],
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavRow({
    required MindTokens tokens,
    required IconData icon,
    required String title,
    String? subtitle,
    String? trailingText,
    Color? iconColor,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    final stackTrailingBadge = trailingText != null &&
        trailingText.isNotEmpty &&
        subtitle != null &&
        subtitle.isNotEmpty &&
        trailingText.length > 14;

    return MindPressable(
      semanticLabel: title,
      onPressed: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor ?? tokens.ink),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: titleColor ?? tokens.ink,
                    ),
                  ),
                  if (subtitle != null && subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: tokens.ink2,
                        height: 1.35,
                      ),
                    ),
                  ],
                  if (stackTrailingBadge) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: tokens.cardTint,
                        borderRadius: BorderRadius.circular(tokens.chipRadius),
                        border: Border.all(
                          color: tokens.ink.withValues(alpha: 0.32),
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          trailingText,
                          maxLines: 1,
                          softWrap: false,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: tokens.ink,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!stackTrailingBadge &&
                trailingText != null &&
                trailingText.isNotEmpty) ...[
              const SizedBox(width: 10),
              Flexible(
                fit: FlexFit.loose,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: tokens.surface2,
                    borderRadius: BorderRadius.circular(tokens.chipRadius),
                    border: Border.all(color: tokens.line),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      trailingText,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: tokens.ink,
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(width: 6),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 15,
              color: tokens.ink3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSwatchStrip({
    required MindTokens tokens,
    required AppStrings strings,
    required int themeIndex,
  }) {
    Widget buildCard({
      required int idx,
      required String semanticLabel,
      required ThemeMode targetMode,
      required Widget preview,
    }) {
      final selected = themeIndex == idx;
      return Expanded(
        child: MindPressable(
          semanticLabel: semanticLabel,
          selected: selected,
          onPressed: () {
            HapticFeedback.selectionClick();
            ref.read(themeControllerProvider.notifier).setTheme(targetMode);
          },
          borderRadius: BorderRadius.circular(tokens.iconButtonRadius),
          child: Container(
            height: 54,
            foregroundDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(tokens.iconButtonRadius),
              border: Border.all(
                color: selected ? tokens.ink : tokens.line,
                width: selected ? 1.8 : 1.0,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(tokens.iconButtonRadius),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  preview,
                  if (selected)
                    PositionedDirectional(
                      top: 7,
                      end: 7,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: tokens.ink,
                          border: Border.all(color: tokens.bg, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    Widget buildMiniFrame({
      required Color bg,
      required Color card,
      required Color border,
      required Color bar,
      required Color subBar,
    }) {
      return ColoredBox(
        color: bg,
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: border, width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 24,
                  height: 5,
                  decoration: BoxDecoration(
                    color: bar,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: subBar,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        buildCard(
          idx: 0,
          semanticLabel: strings.themeDaylight,
          targetMode: ThemeMode.light,
          preview: buildMiniFrame(
            bg: MindTokens.light.bg,
            card: MindTokens.light.surface,
            border: MindTokens.light.line,
            bar: MindTokens.light.ink,
            subBar: MindTokens.light.ink2.withValues(alpha: 0.35),
          ),
        ),
        const SizedBox(width: 8),
        buildCard(
          idx: 1,
          semanticLabel: strings.themeNight,
          targetMode: ThemeMode.dark,
          preview: buildMiniFrame(
            bg: MindTokens.dark.bg,
            card: MindTokens.dark.surface,
            border: MindTokens.dark.line,
            bar: MindTokens.dark.ink,
            subBar: MindTokens.dark.ink2.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(width: 8),
        buildCard(
          idx: 2,
          semanticLabel: strings.themeSystem,
          targetMode: ThemeMode.system,
          preview: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ColoredBox(
                  color: MindTokens.light.bg,
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Container(
                      width: 14,
                      height: 24,
                      decoration: BoxDecoration(
                        color: MindTokens.light.surface,
                        borderRadius: const BorderRadiusDirectional.horizontal(
                          start: Radius.circular(6),
                        ),
                        border: Border.all(
                          color: MindTokens.light.line,
                          width: 0.8,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: MindTokens.light.ink,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ColoredBox(
                  color: MindTokens.dark.bg,
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Container(
                      width: 14,
                      height: 24,
                      decoration: BoxDecoration(
                        color: MindTokens.dark.surface,
                        borderRadius: const BorderRadiusDirectional.horizontal(
                          end: Radius.circular(6),
                        ),
                        border: Border.all(
                          color: MindTokens.dark.line,
                          width: 0.8,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: MindTokens.dark.ink,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchRow({
    required MindTokens tokens,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: tokens.ink),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: tokens.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: tokens.ink2,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          MindSwitch(
            value: value,
            semanticLabel: title,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _notifFreqChip(
    String freq,
    String label,
    MindTokens tokens,
  ) {
    final isSelected = _notificationFrequency == freq;
    return MindPressable(
      semanticLabel: label,
      selected: isSelected,
      onPressed: () => _setNotificationFrequency(freq),
      borderRadius: BorderRadius.circular(tokens.chipRadius),
      child: Container(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? tokens.cardTint : tokens.surface2,
          borderRadius: BorderRadius.circular(tokens.chipRadius),
          border: Border.all(
            color: isSelected ? tokens.ink : tokens.line,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Icon(Icons.check_rounded, size: 15, color: tokens.ink),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? tokens.ink : tokens.ink2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String title, MindTokens tokens) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 8, start: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
          color: tokens.ink2,
        ),
      ),
    );
  }
}

class _EditPreferredNameDialog extends StatefulWidget {
  const _EditPreferredNameDialog({
    required this.strings,
    required this.tokens,
    required this.initialName,
  });

  final AppStrings strings;
  final MindTokens tokens;
  final String initialName;

  @override
  State<_EditPreferredNameDialog> createState() =>
      _EditPreferredNameDialogState();
}

class _EditPreferredNameDialogState extends State<_EditPreferredNameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

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
        borderRadius: BorderRadius.circular(tokens.cardRadius),
        side: BorderSide(color: tokens.line),
      ),
      title: Text(
        strings.preferredNameLabel,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: tokens.ink,
        ),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        style: TextStyle(color: tokens.ink, fontSize: 14),
        decoration: InputDecoration(
          hintText: strings.editPreferredNameHint,
          hintStyle: TextStyle(color: tokens.ink2, fontSize: 13),
          filled: true,
          fillColor: tokens.surface2,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(tokens.chipRadius),
            borderSide: BorderSide(color: tokens.line),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
          child: Text(
            strings.cancelBtn,
            style: TextStyle(color: tokens.ink2, fontSize: 13),
          ),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: const Size(48, 48),
            backgroundColor: tokens.ink,
            foregroundColor: tokens.bg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(tokens.buttonRadius),
            ),
          ),
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: Text(
            strings.saveChangesBtn,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _ChangePinDialog extends ConsumerStatefulWidget {
  const _ChangePinDialog({
    required this.patientId,
    required this.strings,
    required this.tokens,
  });

  final String patientId;
  final AppStrings strings;
  final MindTokens tokens;

  @override
  ConsumerState<_ChangePinDialog> createState() => _ChangePinDialogState();
}

class _ChangePinDialogState extends ConsumerState<_ChangePinDialog> {
  final TextEditingController _currentCtrl = TextEditingController();
  final TextEditingController _newCtrl = TextEditingController();
  String? _errorMsg;
  bool _saving = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
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
        strings.changePinBtn,
        style: TextStyle(
          color: tokens.ink,
          fontSize: 16.5,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _currentCtrl,
              obscureText: true,
              keyboardType: TextInputType.number,
              style: TextStyle(color: tokens.ink, fontSize: 14),
              decoration: InputDecoration(
                labelText: strings.currentPinLabel,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(tokens.buttonRadius),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newCtrl,
              obscureText: true,
              keyboardType: TextInputType.number,
              style: TextStyle(color: tokens.ink, fontSize: 14),
              decoration: InputDecoration(
                labelText: strings.newPinLabel,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(tokens.buttonRadius),
                ),
              ),
            ),
            if (_errorMsg != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMsg!,
                style: TextStyle(
                  color: tokens.safety,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
          child: Text(strings.cancelBtn),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: const Size(48, 48),
            backgroundColor: tokens.primary,
            foregroundColor: tokens.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(tokens.buttonRadius),
            ),
          ),
          onPressed: _saving
              ? null
              : () async {
                  final next = _newCtrl.text.trim();
                  if (next.length < 4) {
                    setState(() => _errorMsg = strings.pinFieldHint);
                    return;
                  }
                  setState(() {
                    _saving = true;
                    _errorMsg = null;
                  });
                  try {
                    await ref
                        .read(clinicAuthRepositoryProvider)
                        .changePatientPin(
                          patientId: widget.patientId,
                          currentPin: _currentCtrl.text.trim(),
                          newPin: next,
                        );
                    if (context.mounted) {
                      Navigator.of(context).pop(true);
                    }
                  } on ClinicAuthException catch (e) {
                    if (mounted) {
                      setState(() {
                        _saving = false;
                        _errorMsg = e.message;
                      });
                    }
                  }
                },
          child: Text(strings.saveNewPinBtn),
        ),
      ],
    );
  }
}
