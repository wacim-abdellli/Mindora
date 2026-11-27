import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
import '../../../core/widgets/mind_pressable.dart';
import '../../../core/widgets/mind_segmented.dart';
import '../../../core/widgets/mind_sheet.dart';
import '../../../core/widgets/mind_switch.dart';
import '../../../core/widgets/mind_toast.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../backup/data/unified_backup_service.dart';
import '../../case_file/presentation/clinical_export_preview_sheet.dart';
import '../../clinician/presentation/clinician_shell_screen.dart';
import '../../clinician/presentation/widgets/import_care_focus_sheet.dart';
import '../../clinician/presentation/widgets/pre_visit_brief_sheet.dart';
import '../../clinician/presentation/widgets/share_with_psychiatrist_sheet.dart';
import '../../investigation/controllers/investigation_providers.dart';
import '../../investigation/presentation/widgets/ai_engine_config_sheet.dart';
import '../../journal/controllers/journal_memory_controller.dart';
import '../../journal/presentation/widgets/journal_memory_sheet.dart';
import '../../journey/controllers/journey_controller.dart';
import '../../mind_trace/controllers/mind_trace_controller.dart';
import '../../observatory/controllers/observatory_controllers.dart';
import '../../observatory/data/local_symptom_repository.dart';
import '../../observatory/presentation/inner_observatory_screen.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../profile/presentation/psychological_profile_screen.dart';
import 'clinical_sharing_history_sheet.dart';

/// Me & Preferences Screen.
///
/// Organized into 5 calm grouped cards (Look & reading, About me & reminders,
/// Doctor visit, Privacy, lock & backup, and collapsed For clinicians &
/// advanced) built with MindTokens, >= 48dp interactive targets, >= 12.5px
/// typography, reminder pre-permission, dry-run restore preview, and a
/// double-confirm local reset.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const String _prefAiHistory = 'mf_settings_ai_history';
  static const String _prefGentleNotif = 'mf_gentle_notifications';
  static const String _prefNotifFreq = 'mf_notification_freq';

  bool _aiHistoryAccess = true;
  bool _gentleNotifications = false;
  bool _showAdvanced = false;
  String _notificationFrequency = 'daily';

  @override
  void initState() {
    super.initState();
    _loadPersistedSettings();
  }

  Future<void> _loadPersistedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      final profileConsent =
          ref.read(profileControllerProvider).value?.shareWithAiCompanion;
      setState(() {
        _aiHistoryAccess =
            profileConsent ?? (prefs.getBool(_prefAiHistory) ?? true);
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

  Future<void> _setAiHistory(bool val) async {
    HapticFeedback.lightImpact();
    setState(() => _aiHistoryAccess = val);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefAiHistory, val);
    await ref.read(profileControllerProvider.notifier).setAiPersonalization(val);
  }

  Future<void> _promptEncryptedVaultExport(
    BuildContext context,
    AppStrings strings,
    MindTokens tokens,
  ) async {
    final passCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    String? errorMsg;

    final password = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          backgroundColor: tokens.surface,
          title: Text(
            strings.exportEncryptedVaultTitle,
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
                Text(
                  strings.exportEncryptedVaultDesc,
                  style: TextStyle(color: tokens.ink2, fontSize: 13.5),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passCtrl,
                  obscureText: true,
                  style: TextStyle(color: tokens.ink, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: strings.passphraseFieldLabel,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(tokens.buttonRadius),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: confirmCtrl,
                  obscureText: true,
                  style: TextStyle(color: tokens.ink, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: strings.confirmPassphraseLabel,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(tokens.buttonRadius),
                    ),
                  ),
                ),
                if (errorMsg != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    errorMsg!,
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
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text(strings.cancelBtn),
            ),
            FilledButton(
              onPressed: () {
                final p1 = passCtrl.text;
                final p2 = confirmCtrl.text;
                if (p1.length < 6) {
                  setDialogState(() {
                    errorMsg = strings.passphraseTooShortError;
                  });
                  return;
                }
                if (p1 != p2) {
                  setDialogState(() {
                    errorMsg = strings.passphraseMismatchError;
                  });
                  return;
                }
                Navigator.of(dialogCtx).pop(p1);
              },
              child: Text(strings.exportVaultBtn),
            ),
          ],
        ),
      ),
    );
    passCtrl.dispose();
    confirmCtrl.dispose();

    if (password == null || !mounted) return;
    HapticFeedback.lightImpact();
    final result = await ref
        .read(unifiedBackupServiceProvider)
        .createPasswordEncryptedBackup(password);
    if (!result.success || result.rawJson == null) {
      if (context.mounted) {
        showMindToast(context, result.message);
      }
      return;
    }

    await Clipboard.setData(ClipboardData(text: result.rawJson!));
    if (context.mounted) {
      showMindToast(context, strings.vaultCopiedToast);
    }
  }

  Future<void> _promptEncryptedVaultRestore(
    BuildContext context,
    AppStrings strings,
    MindTokens tokens,
  ) async {
    final jsonCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String? errorMsg;

    final payload = await showDialog<({String json, String password})>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          backgroundColor: tokens.surface,
          title: Text(
            strings.restoreBackupBtn,
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
                Text(
                  strings.restoreEncryptedVaultDesc,
                  style: TextStyle(color: tokens.ink2, fontSize: 13.5),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: jsonCtrl,
                  minLines: 3,
                  maxLines: 5,
                  style: TextStyle(color: tokens.ink, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: strings.backupJsonLabel,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(tokens.buttonRadius),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: passCtrl,
                  obscureText: true,
                  style: TextStyle(color: tokens.ink, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: strings.passphraseFieldLabel,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(tokens.buttonRadius),
                    ),
                  ),
                ),
                if (errorMsg != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    errorMsg!,
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
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text(strings.cancelBtn),
            ),
            FilledButton(
              onPressed: () {
                final raw = jsonCtrl.text.trim();
                final pwd = passCtrl.text;
                if (raw.isEmpty) {
                  setDialogState(() {
                    errorMsg = strings.pasteBackupFirstError;
                  });
                  return;
                }
                Navigator.of(dialogCtx).pop((json: raw, password: pwd));
              },
              child: Text(strings.continueBtn),
            ),
          ],
        ),
      ),
    );
    jsonCtrl.dispose();
    passCtrl.dispose();

    if (payload == null || !mounted) return;

    final backupSvc = ref.read(unifiedBackupServiceProvider);
    final preview = await backupSvc.previewPasswordEncryptedBackup(
      payload.json,
      payload.password,
    );
    if (!context.mounted) return;
    if (!preview.success || preview.rawJson == null) {
      showMindToast(context, preview.message);
      return;
    }

    final confirmed = await showMindSheet<bool>(
      context: context,
      title: strings.restoreBackupPreviewTitle,
      builder: (sheetCtx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            strings.restorePreviewSummary(
              preview.tracesCount,
              preview.sessionsCount,
            ),
            style: TextStyle(
              fontSize: 14.5,
              color: tokens.ink2,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          MindButton(
            text: strings.restoreBackupBtn,
            isFullWidth: true,
            onPressed: () => Navigator.of(sheetCtx).pop(true),
          ),
          const SizedBox(height: 8),
          MindButton(
            text: strings.cancelBtn,
            variant: MindButtonVariant.ghost,
            isFullWidth: true,
            onPressed: () => Navigator.of(sheetCtx).pop(false),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    HapticFeedback.mediumImpact();
    final result = await backupSvc.restoreFromBackupJson(preview.rawJson!);
    if (result.success) {
      ref.invalidate(savedCasesProvider);
      ref.invalidate(activeCaseControllerProvider);
      ref.invalidate(mindTraceControllerProvider);
      ref.invalidate(journalMemoryControllerProvider);
      ref.invalidate(profileControllerProvider);
      ref.invalidate(symptomReportsControllerProvider);
      ref.invalidate(symptomListControllerProvider);
      ref.invalidate(journeyControllerProvider);
    }
    if (context.mounted) {
      showMindToast(context, result.message);
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

  void _showUpgradeVaultSheet(
    BuildContext context,
    AppStrings strings,
    MindTokens tokens,
  ) {
    HapticFeedback.lightImpact();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final codenameController = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: tokens.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(tokens.sheetRadius)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud_upload_outlined, size: 20, color: tokens.ink),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    strings.linkEmailTitle,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: tokens.ink,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: strings.closeBtn,
                  icon: Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: tokens.ink2,
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              strings.linkEmailSubtitle,
              style: TextStyle(
                fontSize: 12,
                color: tokens.ink2,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: codenameController,
              style: TextStyle(color: tokens.ink, fontSize: 13),
              decoration: InputDecoration(
                hintText: strings.codenameFieldHint,
                labelText: strings.codenameFieldLabel,
                filled: true,
                fillColor: tokens.surface2,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(color: tokens.ink, fontSize: 13),
              decoration: InputDecoration(
                hintText: strings.emailFieldHint,
                labelText: strings.emailFieldLabel,
                filled: true,
                fillColor: tokens.surface2,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: passwordController,
              obscureText: true,
              style: TextStyle(color: tokens.ink, fontSize: 13),
              decoration: InputDecoration(
                hintText: strings.passwordFieldHint,
                labelText: strings.passwordFieldLabel,
                filled: true,
                fillColor: tokens.surface2,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 20),
            MindButton(
              text: strings.linkEmailBtn,
              isFullWidth: true,
              onPressed: () async {
                final email = emailController.text.trim();
                final password = passwordController.text.trim();
                final codename = codenameController.text.trim();

                final success = await ref
                    .read(authControllerProvider.notifier)
                    .linkEmail(
                      email,
                      password,
                      codename: codename.isNotEmpty ? codename : null,
                    );

                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                  if (mounted) {
                    showMindToast(
                      context,
                      success
                          ? strings.vaultStatusCloud
                          : strings.localizeAuthError(
                              ref.read(authControllerProvider).errorMessage ?? '',
                            ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
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
              foregroundColor: Colors.white,
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
              foregroundColor: Colors.white,
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
    await ref.read(secureKeyManagerProvider).wipeAllKeys();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefAiHistory);
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
        _aiHistoryAccess = true;
        _gentleNotifications = false;
        _notificationFrequency = 'daily';
      });
      final router = GoRouter.maybeOf(context);
      if (router != null) {
        router.go(AppRouter.auth);
      }
    }
  }

  Future<void> _openSharePacketBuilder(
    BuildContext context,
    AppStrings strings,
  ) async {
    final allCases = await ref.read(savedCasesProvider.future);
    if (!context.mounted) return;
    final tokens = context.tokens;
    final shareableCases = allCases.where((c) => !c.isPrivate).toList();
    final privateCount = allCases.length - shareableCases.length;
    final selectedIds = <String>{};

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: tokens.bg.withValues(alpha: 0.0),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final selectedCases =
              shareableCases.where((c) => selectedIds.contains(c.id)).toList();
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.82,
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: BoxDecoration(
              color: tokens.surface,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(tokens.sheetRadius),
              ),
              border: Border(top: BorderSide(color: tokens.line)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: tokens.line,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    strings.sharePacketTitle,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: tokens.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    strings.sharePacketSub,
                    style: TextStyle(fontSize: 12.5, color: tokens.ink2),
                  ),
                  if (privateCount > 0) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: tokens.surface2,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: tokens.line),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lock_outline_rounded,
                            size: 15,
                            color: tokens.ink,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              strings.privateCasesExcludedBanner(privateCount),
                              style: TextStyle(
                                fontSize: 12.5,
                                color: tokens.ink2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  if (shareableCases.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        strings.noShareableTalksYet,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: tokens.ink2,
                        ),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: shareableCases.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (_, idx) {
                          final item = shareableCases[idx];
                          final checked = selectedIds.contains(item.id);
                          final label = item.title.trim().isNotEmpty
                              ? item.title.trim()
                              : (item.incidentDescription.trim().isNotEmpty
                                  ? item.incidentDescription.trim()
                                  : item.caseNumber);
                          return InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => setSheetState(() {
                              if (checked) {
                                selectedIds.remove(item.id);
                              } else {
                                selectedIds.add(item.id);
                              }
                            }),
                            child: Container(
                              constraints: const BoxConstraints(minHeight: 48),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: checked
                                    ? tokens.cardTint
                                    : tokens.surface2,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: checked ? tokens.primary : tokens.line,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: checked,
                                    activeColor: tokens.primary,
                                    onChanged: (_) => setSheetState(() {
                                      if (checked) {
                                        selectedIds.remove(item.id);
                                      } else {
                                        selectedIds.add(item.id);
                                      }
                                    }),
                                  ),
                                  Expanded(
                                    child: Text(
                                      label,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: checked
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                        color: tokens.ink,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  if (shareableCases.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    MindButton(
                      text: strings.previewSharePacketBtn(selectedCases.length),
                      leadingIcon: Icons.visibility_outlined,
                      isFullWidth: true,
                      onPressed: selectedCases.isEmpty
                          ? null
                          : () {
                              Navigator.of(ctx).pop();
                              ClinicalExportPreviewSheet.show(
                                context,
                                selectedCases,
                              );
                            },
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final currentThemeMode = ref.watch(themeControllerProvider);
    final currentLocale = ref.watch(localeControllerProvider);
    final strings = ref.watch(appStringsProvider);
    final authState = ref.watch(authControllerProvider);
    final appLock = ref.watch(appLockProvider);
    final profileAsync = ref.watch(profileControllerProvider);
    final cases = ref.watch(savedCasesProvider).value ?? [];
    final profile = profileAsync.value;
    final aiHistoryEnabled =
        profile?.shareWithAiCompanion ?? _aiHistoryAccess;

    final preferredName = profile?.preferredName.trim() ?? '';
    final authUser = authState.user;
    final isCloudLinked = authUser != null && !authUser.isAnonymous;
    final accountValue = isCloudLinked
        ? (authUser.email ?? strings.vaultStatusCloud)
        : strings.localDeviceOnlyLabel;

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
        actions: const [
          SupportButton(),
          SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 48),
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
                          label: isCloudLinked
                              ? strings.vaultStatusCloud
                              : strings.vaultStatusAnonymous,
                          icon: isCloudLinked
                              ? Icons.cloud_done_outlined
                              : Icons.phonelink_lock_outlined,
                          backgroundColor: isCloudLinked
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

            // Doctor quick shortcut when registered in clinician role
            if (profile?.userRole == 'clinician') ...[
              const SizedBox(height: 14),
              MindButton(
                text: strings.openDoctorWorkspaceBtn,
                leadingIcon: Icons.medical_services_outlined,
                variant: MindButtonVariant.primary,
                isFullWidth: true,
                onPressed: () {
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
                          labels: const ['EN', 'FR', 'AR'],
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

            // Card 3: Doctor visit (optional)
            _sectionLabel(strings.doctorVisitSection, tokens),
            MindCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildNavRow(
                    tokens: tokens,
                    icon: Icons.assignment_outlined,
                    title: strings.preVisitBriefTitle,
                    subtitle: strings.preVisitBriefSubtitle,
                    onTap: () => PreVisitBriefSheet.show(context),
                  ),
                  Divider(height: 1, thickness: 1, color: tokens.line),
                  _buildNavRow(
                    tokens: tokens,
                    icon: Icons.health_and_safety_outlined,
                    title: strings.shareWithPsychiatristTitle,
                    subtitle: strings.shareWithPsychiatristSub,
                    onTap: () => ShareWithPsychiatristSheet.show(context),
                  ),
                  Divider(height: 1, thickness: 1, color: tokens.line),
                  _buildNavRow(
                    tokens: tokens,
                    icon: Icons.assignment_returned_outlined,
                    title: strings.importCareFocusTitle,
                    subtitle: strings.importCareFocusSub,
                    onTap: () => ImportCareFocusSheet.show(context),
                  ),
                  Divider(height: 1, thickness: 1, color: tokens.line),
                  _buildNavRow(
                    tokens: tokens,
                    icon: Icons.description_outlined,
                    title: strings.exportSummaryButton,
                    onTap: () => ClinicalExportPreviewSheet.show(context, cases),
                  ),
                  Divider(height: 1, thickness: 1, color: tokens.line),
                  _buildNavRow(
                    tokens: tokens,
                    icon: Icons.inventory_2_outlined,
                    title: strings.sharePacketTitle,
                    subtitle: strings.sharePacketSub,
                    onTap: () => _openSharePacketBuilder(context, strings),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // Card 4: Privacy, lock & backup
            _sectionLabel(strings.privacyLockBackupSection, tokens),
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
                  Divider(height: 1, thickness: 1, color: tokens.line),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: MindButton(
                                text: strings.backupNowBtn,
                                variant: MindButtonVariant.soft,
                                leadingIcon: Icons.cloud_upload_outlined,
                                onPressed: () async {
                                  HapticFeedback.mediumImpact();
                                  final result = await ref
                                      .read(unifiedBackupServiceProvider)
                                      .createFullBackup();
                                  if (context.mounted) {
                                    showMindToast(
                                      context,
                                      strings.backupCompleteToast(
                                        result.tracesCount,
                                        result.sessionsCount,
                                        result.memoriesCount,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: MindButton(
                                text: strings.exportVaultBtn,
                                variant: MindButtonVariant.secondary,
                                leadingIcon: Icons.enhanced_encryption_outlined,
                                onPressed: () => _promptEncryptedVaultExport(
                                  context,
                                  strings,
                                  tokens,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        MindButton(
                          text: strings.restoreBackupBtn,
                          variant: MindButtonVariant.secondary,
                          isFullWidth: true,
                          leadingIcon: Icons.restore_page_outlined,
                          onPressed: () => _promptEncryptedVaultRestore(
                            context,
                            strings,
                            tokens,
                          ),
                        ),
                      ],
                    ),
                  ),
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

            const SizedBox(height: 22),

            // Card 5: Collapsed For clinicians & advanced accordion
            MindCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  Semantics(
                    button: true,
                    expanded: _showAdvanced,
                    label: strings.advancedCliniciansSection,
                    child: MindPressable(
                      key: const ValueKey('me-advanced-accordion'),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        setState(() => _showAdvanced = !_showAdvanced);
                      },
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 56),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.tune_rounded,
                              size: 20,
                              color: tokens.ink2,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                strings.advancedCliniciansSection,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: tokens.ink,
                                ),
                              ),
                            ),
                            Icon(
                              _showAdvanced
                                  ? Icons.expand_less_rounded
                                  : Icons.expand_more_rounded,
                              size: 22,
                              color: tokens.ink2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_showAdvanced) ...[
                    Divider(height: 1, thickness: 1, color: tokens.line),
                    _buildNavRow(
                      tokens: tokens,
                      icon: Icons.medical_services_outlined,
                      title: strings.psychiatristWorkspaceTitle,
                      subtitle: strings.psychiatristWorkspaceSub,
                      onTap: () {
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
                    Divider(height: 1, thickness: 1, color: tokens.line),
                    _buildNavRow(
                      tokens: tokens,
                      icon: Icons.smart_toy_outlined,
                      title: strings.mindAssistantEngineTitle,
                      subtitle: strings.mindAssistantEngineSub,
                      onTap: () => AiEngineConfigSheet.show(context),
                    ),
                    Divider(height: 1, thickness: 1, color: tokens.line),
                    _buildSwitchRow(
                      tokens: tokens,
                      icon: Icons.memory_rounded,
                      title: strings.aiHistoryTitle,
                      subtitle: strings.aiHistoryDesc,
                      value: aiHistoryEnabled,
                      onChanged: _setAiHistory,
                    ),
                    Divider(height: 1, thickness: 1, color: tokens.line),
                    _buildNavRow(
                      tokens: tokens,
                      icon: Icons.auto_stories_outlined,
                      title: strings.memoryVaultTitle,
                      onTap: () => JournalMemorySheet.show(context),
                    ),
                    Divider(height: 1, thickness: 1, color: tokens.line),
                    _buildNavRow(
                      tokens: tokens,
                      icon: Icons.history_edu_outlined,
                      title: strings.clinicalSharingHistoryTitle,
                      subtitle: strings.clinicalSharingHistoryDesc,
                      onTap: () => ClinicalSharingHistorySheet.show(context),
                    ),
                    Divider(height: 1, thickness: 1, color: tokens.line),
                    _buildNavRow(
                      tokens: tokens,
                      icon: isCloudLinked
                          ? Icons.logout_rounded
                          : Icons.cloud_upload_outlined,
                      title: strings.accountStatusLabel,
                      subtitle: accountValue,
                      trailingText: isCloudLinked
                          ? strings.signOutBtn
                          : strings.linkEmailBtn,
                      onTap: () {
                        if (isCloudLinked) {
                          ref.read(authControllerProvider.notifier).signOut();
                        } else {
                          _showUpgradeVaultSheet(context, strings, tokens);
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
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

    return Semantics(
      button: true,
      label: title,
      child: MindPressable(
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
        child: Semantics(
          button: true,
          selected: selected,
          label: semanticLabel,
          child: MindPressable(
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
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: MindPressable(
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
