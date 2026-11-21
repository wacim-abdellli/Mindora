import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/localization/locale_controller.dart';
import '../../../app/router/app_router.dart';
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
import '../../auth/controllers/auth_controller.dart';
import '../../backup/data/unified_backup_service.dart';
import '../../case_file/presentation/clinical_export_preview_sheet.dart';
import '../../clinician/presentation/clinician_shell_screen.dart';
import '../../clinician/presentation/widgets/import_care_focus_sheet.dart';
import '../../clinician/presentation/widgets/share_with_psychiatrist_sheet.dart';
import '../../investigation/controllers/investigation_providers.dart';
import '../../investigation/presentation/widgets/ai_engine_config_sheet.dart';
import '../../journal/controllers/journal_memory_controller.dart';
import '../../journal/presentation/widgets/journal_memory_sheet.dart';
import '../../journey/controllers/journey_controller.dart';
import '../../mind_trace/controllers/mind_trace_controller.dart';
import '../../observatory/controllers/observatory_controllers.dart';
import '../../observatory/data/local_symptom_repository.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../profile/presentation/psychological_profile_screen.dart';
import 'clinical_sharing_history_sheet.dart';

/// Profile & Clinical Preferences Screen.
///
/// Organized into 4 grouped cards (You, Display & Language, AI Guide & Security,
/// Data & Crisis) built with MindTokens, >= 48dp interactive targets, >= 11.5px
/// typography, and a double-confirm local reset.
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            strings.isArabic
                ? 'تعذر تفعيل التنبيهات لأن إذن الإشعارات غير ممنوح.'
                : (strings.isFrench
                    ? 'Autorisation de notification refusée ; les rappels restent désactivés.'
                    : 'Notification permission was denied; gentle reminders remain off.'),
          ),
        ),
      );
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
            strings.isArabic
                ? 'تصدير خزينة مشفرة بكلمة سر'
                : (strings.isFrench
                    ? 'Exporter un coffre chiffré'
                    : 'Export Encrypted Vault'),
            style: TextStyle(
              color: tokens.ink,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.isArabic
                      ? 'أدخل كلمة سر لحماية النسخة المصدرة (6 أحرف على الأقل). بدونها لا يمكن فك التشفير.'
                      : (strings.isFrench
                          ? 'Choisissez un mot de passe pour chiffrer votre sauvegarde (6 caractères minimum).'
                          : 'Enter a passphrase to encrypt your backup (min 6 characters). Required later to restore.'),
                  style: TextStyle(color: tokens.ink2, fontSize: 12.5),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passCtrl,
                  obscureText: true,
                  style: TextStyle(color: tokens.ink, fontSize: 13.5),
                  decoration: InputDecoration(
                    labelText: strings.isArabic
                        ? 'كلمة السر'
                        : (strings.isFrench ? 'Mot de passe' : 'Passphrase'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(tokens.buttonRadius),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: confirmCtrl,
                  obscureText: true,
                  style: TextStyle(color: tokens.ink, fontSize: 13.5),
                  decoration: InputDecoration(
                    labelText: strings.isArabic
                        ? 'تأكيد كلمة السر'
                        : (strings.isFrench ? 'Confirmer' : 'Confirm password'),
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
                      fontSize: 12,
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
                    errorMsg = strings.isArabic
                        ? 'يجب أن تكون كلمة السر 6 أحرف على الأقل.'
                        : (strings.isFrench
                            ? 'Le mot de passe doit contenir au moins 6 caractères.'
                            : 'Passphrase must be at least 6 characters.');
                  });
                  return;
                }
                if (p1 != p2) {
                  setDialogState(() {
                    errorMsg = strings.isArabic
                        ? 'كلمتا السر غير متطابقتين.'
                        : (strings.isFrench
                            ? 'Les mots de passe ne correspondent pas.'
                            : 'Passphrases do not match.');
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(result.message),
          ),
        );
      }
      return;
    }

    await Clipboard.setData(ClipboardData(text: result.rawJson!));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            strings.isArabic
                ? 'تم نسخ الخزينة المشفرة إلى الحافظة بأمان.'
                : (strings.isFrench
                    ? 'Coffre chiffré copié dans le presse-papiers.'
                    : 'Password-encrypted vault backup copied to clipboard.'),
          ),
        ),
      );
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
            strings.isArabic
                ? 'استعادة خزينة مشفرة'
                : (strings.isFrench
                    ? 'Restaurer un coffre chiffré'
                    : 'Restore Encrypted Vault'),
            style: TextStyle(
              color: tokens.ink,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.isArabic
                      ? 'ألصق نص النسخة الاحتياطية المشفرة وأدخل كلمة السر لاستعادة السجلات دون فقدان البيانات الحالية.'
                      : (strings.isFrench
                          ? 'Collez la sauvegarde chiffrée et saisissez le mot de passe associé.'
                          : 'Paste your exported vault backup JSON and enter the passphrase used to lock it.'),
                  style: TextStyle(color: tokens.ink2, fontSize: 12.5),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: jsonCtrl,
                  minLines: 3,
                  maxLines: 5,
                  style: TextStyle(color: tokens.ink, fontSize: 12),
                  decoration: InputDecoration(
                    labelText: strings.isArabic
                        ? 'محتوى النسخة الاحتياطية (JSON)'
                        : (strings.isFrench
                            ? 'Contenu de sauvegarde (JSON)'
                            : 'Encrypted Backup JSON'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(tokens.buttonRadius),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: passCtrl,
                  obscureText: true,
                  style: TextStyle(color: tokens.ink, fontSize: 13.5),
                  decoration: InputDecoration(
                    labelText: strings.isArabic
                        ? 'كلمة السر'
                        : (strings.isFrench ? 'Mot de passe' : 'Passphrase'),
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
                      fontSize: 12,
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
                    errorMsg = strings.isArabic
                        ? 'الرجاء لصق نص النسخة الاحتياطية أولاً.'
                        : (strings.isFrench
                            ? 'Veuillez coller la sauvegarde.'
                            : 'Please paste your backup payload first.');
                  });
                  return;
                }
                Navigator.of(dialogCtx).pop((json: raw, password: pwd));
              },
              child: Text(
                strings.isArabic
                    ? 'استعادة'
                    : (strings.isFrench ? 'Restaurer' : 'Restore'),
              ),
            ),
          ],
        ),
      ),
    );
    jsonCtrl.dispose();
    passCtrl.dispose();

    if (payload == null || !mounted) return;
    HapticFeedback.mediumImpact();
    final result = await ref
        .read(unifiedBackupServiceProvider)
        .restoreFromPasswordEncryptedBackup(payload.json, payload.password);
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(result.message),
        ),
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? strings.vaultStatusCloud
                            : strings.localizeAuthError(
                                ref.read(authControllerProvider).errorMessage ?? '',
                              ),
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
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
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          strings.resetConfirmStep1Body,
          style: TextStyle(color: tokens.ink2, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(step1Ctx).pop(),
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            child: Text(
              strings.cancelBtn,
              style: TextStyle(color: tokens.ink2, fontSize: 13),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(48, 48),
              backgroundColor: tokens.safety,
              foregroundColor: tokens.bg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(tokens.buttonRadius),
              ),
            ),
            onPressed: () {
              Navigator.of(step1Ctx).pop();
              _showFinalResetDialog(strings, tokens);
            },
            child: Text(
              strings.continueActionBtn,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
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
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          strings.resetConfirmStep2Body,
          style: TextStyle(color: tokens.ink2, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(step2Ctx).pop(),
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            child: Text(
              strings.cancelBtn,
              style: TextStyle(color: tokens.ink2, fontSize: 13),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(48, 48),
              backgroundColor: tokens.safety,
              foregroundColor: tokens.bg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(tokens.buttonRadius),
              ),
            ),
            onPressed: () async {
              Navigator.of(step2Ctx).pop();
              await _performFullLocalReset();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(strings.allDataWipedSnackbar),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text(
              strings.confirmResetBtn,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
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
    ref.invalidate(aiConfigProvider);

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
                              strings.isArabic
                                  ? 'تم استبعاد $privateCount جلسات خاصة تلقائياً.'
                                  : (strings.isFrench
                                      ? '$privateCount sessions privées exclues automatiquement.'
                                      : '$privateCount private sessions automatically excluded.'),
                              style: TextStyle(
                                fontSize: 11.5,
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
                        strings.isArabic
                            ? 'لا توجد جلسات غير خاصة جاهزة للمشاركة بعد.'
                            : (strings.isFrench
                                ? 'Aucune session partageable disponible pour le moment.'
                                : 'No non-private reflections available to include yet.'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
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
                                  color: checked ? tokens.ink : tokens.line,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: checked,
                                    activeColor: tokens.ink,
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
                                        fontSize: 13,
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
                    SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: tokens.ink,
                          foregroundColor: tokens.bg,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              tokens.buttonRadius,
                            ),
                          ),
                        ),
                        onPressed: selectedCases.isEmpty
                            ? null
                            : () {
                                Navigator.of(ctx).pop();
                                ClinicalExportPreviewSheet.show(
                                  context,
                                  selectedCases,
                                );
                              },
                        icon: const Icon(Icons.visibility_outlined, size: 18),
                        label: Text(
                          strings.isArabic
                              ? 'معاينة الحزمة (${selectedCases.length})'
                              : (strings.isFrench
                                  ? 'Aperçu du dossier (${selectedCases.length})'
                                  : 'Preview Share Packet (${selectedCases.length})'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
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

    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: AppBar(
        backgroundColor: tokens.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          strings.settingsTitle.toUpperCase(),
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13.5,
            letterSpacing: 1.0,
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
          // Header Card
          MindCard(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tokens.cardTint,
                    border: Border.all(
                      color: tokens.ink.withValues(alpha: 0.32),
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
                            : strings.authTitle,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: tokens.ink,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        strings.profileSubtitle,
                        style: TextStyle(
                          fontSize: 12.5,
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
                        backgroundColor:
                            isCloudLinked ? tokens.cardTint : tokens.selectedTint,
                        textColor: tokens.ink,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // Group 1: You
          _sectionLabel(strings.profileGroupYou, tokens),
          MindCard(
            padding: EdgeInsets.zero,
            child: Column(
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
                  title: strings.myPsychologicalProfileTitle,
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
              ],
            ),
          ),

          const SizedBox(height: 22),

          // Group 2: Display & Language
          _sectionLabel(strings.profileGroupDisplay, tokens),
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
                        strings.themeModeTitle.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: tokens.ink2,
                          letterSpacing: 0.8,
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
                          strings.themeDaylight,
                          strings.themeNight,
                          strings.themeSystem,
                        ],
                        onChanged: (idx) {
                          HapticFeedback.selectionClick();
                          final mode = idx == 0
                              ? ThemeMode.light
                              : (idx == 1 ? ThemeMode.dark : ThemeMode.system);
                          ref
                              .read(themeControllerProvider.notifier)
                              .setTheme(mode);
                        },
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, thickness: 1, color: tokens.line),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.languageTitle.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: tokens.ink2,
                          letterSpacing: 0.8,
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
                Divider(height: 1, thickness: 1, color: tokens.line),
                _buildSwitchRow(
                  tokens: tokens,
                  icon: Icons.notifications_none_rounded,
                  title: strings.isArabic
                      ? 'تنبيهات لطيفة غير ملحة'
                      : (strings.isFrench
                          ? 'Rappels doux et bienveillants'
                          : 'Gentle Non-Pressuring Reminders'),
                  subtitle: strings.isArabic
                      ? 'تذكير اختياري بتدوين أثرك دون أي ضغط'
                      : (strings.isFrench
                          ? 'Un mot doux pour votre point du jour, sans pression'
                          : 'Optional gentle prompt when you want a check-in nudge'),
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
                          strings.isArabic
                              ? 'الوتيرة المفضلة'
                              : (strings.isFrench ? 'Rythme' : 'Frequency'),
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
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
                              strings.isArabic
                                  ? 'يومياً'
                                  : (strings.isFrench ? 'Quotidien' : 'Daily'),
                              tokens,
                            ),
                            _notifFreqChip(
                              'alternate',
                              strings.isArabic
                                  ? 'يوم بيوم'
                                  : (strings.isFrench
                                      ? 'Un jour sur deux'
                                      : 'Alternate Days'),
                              tokens,
                            ),
                            _notifFreqChip(
                              'weekly',
                              strings.isArabic
                                  ? 'أسبوعياً'
                                  : (strings.isFrench
                                      ? 'Hebdomadaire'
                                      : 'Weekly'),
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
                                color: tokens.ink,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  strings.isArabic
                                      ? 'مثال: "أثر ذهنك اليومي ينتظرك وقتما تكون مستعداً."'
                                      : (strings.isFrench
                                          ? 'Exemple : « Votre empreinte du jour vous attend quand vous êtes prêt(e). »'
                                          : 'Sample: "Your daily Mind Trace is waiting whenever you\'re ready."'),
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontStyle: FontStyle.italic,
                                    color: tokens.ink,
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

          // Group 3: AI Guide & Security
          _sectionLabel(strings.profileGroupAiSecurity, tokens),
          MindCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(strings.biometricNotAvailableSnackbar),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // Group 4: Data & Crisis
          _sectionLabel(strings.profileGroupDataCrisis, tokens),
          MindCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
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
                Divider(height: 1, thickness: 1, color: tokens.line),
                _buildNavRow(
                  tokens: tokens,
                  icon: Icons.history_edu_outlined,
                  title: strings.clinicalSharingHistoryTitle,
                  subtitle: strings.clinicalSharingHistoryDesc,
                  onTap: () => ClinicalSharingHistorySheet.show(context),
                ),
                Divider(height: 1, thickness: 1, color: tokens.line),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
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
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        strings.isArabic
                                            ? 'اكتمل النسخ الاحتياطي: ${result.tracesCount} أثر، ${result.sessionsCount} جلسات، ${result.memoriesCount} خلاصات محفوظة.'
                                            : (strings.isFrench
                                                ? 'Sauvegarde terminée : ${result.tracesCount} empreintes, ${result.sessionsCount} sessions, ${result.memoriesCount} souvenirs préservés.'
                                                : 'Backup complete: ${result.tracesCount} traces, ${result.sessionsCount} sessions, ${result.memoriesCount} memories preserved.'),
                                      ),
                                      behavior: SnackBarBehavior.floating,
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
                      SizedBox(
                        width: double.infinity,
                        child: MindButton(
                          text: strings.isArabic
                              ? 'استعادة خزينة مشفرة'
                              : (strings.isFrench
                                  ? 'Restaurer un coffre chiffré'
                                  : 'Restore Encrypted Vault'),
                          variant: MindButtonVariant.secondary,
                          isFullWidth: true,
                          leadingIcon: Icons.restore_page_outlined,
                          onPressed: () => _promptEncryptedVaultRestore(
                            context,
                            strings,
                            tokens,
                          ),
                        ),
                      ),
                    ],
                  ),
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
                  icon: Icons.verified_user_outlined,
                  title: strings.privacyPrinciplesTitle,
                  onTap: () => _showPrivacyDialog(context, strings, tokens),
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
                          fontSize: 12,
                          color: tokens.ink2,
                          height: 1.3,
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
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
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
                          fontSize: 11.5,
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
                Icons.chevron_right_rounded,
                size: 18,
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
          Semantics(
            label: title,
            child: Switch.adaptive(
              value: value,
              activeTrackColor: tokens.m1,
              onChanged: onChanged,
            ),
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
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: tokens.ink2,
          letterSpacing: 1.0,
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
