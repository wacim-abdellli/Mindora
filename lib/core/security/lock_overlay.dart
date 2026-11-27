import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/localization/app_strings.dart';
import '../../app/theme/lab_theme.dart';
import '../../app/theme/mind_tokens.dart';
import '../safety/support_button.dart';
import '../widgets/mind_button.dart';
import '../widgets/mind_toast.dart';
import 'app_lock_provider.dart';

/// Full-screen privacy lock overlay protecting private Mindora sessions.
///
/// Always preserves top-end [SupportButton] crisis access even while locked,
/// uses Warm Alabaster / Vercel Obsidian tokens, and provides a 56dp Unlock CTA.
class LockOverlay extends ConsumerStatefulWidget {
  const LockOverlay({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<LockOverlay> createState() => _LockOverlayState();
}

class _LockOverlayState extends ConsumerState<LockOverlay>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      ref.read(appLockProvider.notifier).lockManually();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lockState = ref.watch(appLockProvider);
    final strings = ref.watch(appStringsProvider);
    final tokens = context.tokens;

    if (!lockState.isInitialized) {
      return ColoredBox(color: tokens.bg, child: const SizedBox.expand());
    }

    if (!lockState.isLocked) {
      return widget.child;
    }

    return Directionality(
      textDirection: strings.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: tokens.bg,
        body: SafeArea(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 10, 12, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [SupportButton()],
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 24,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: tokens.primarySoft,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: tokens.primary.withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.lock_person_rounded,
                      size: 38,
                      color: tokens.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    strings.welcomeBackLockTitle,
                    textAlign: TextAlign.center,
                    style: LabTheme.textStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: tokens.ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    strings.biometricVaultLockedDesc,
                    textAlign: TextAlign.center,
                    style: LabTheme.textStyle(
                      fontSize: 15.5,
                      height: 1.5,
                      color: tokens.ink2,
                    ),
                  ),
                  const SizedBox(height: 32),
                  MindButton(
                    text: strings.unlockWithBiometricsBtn,
                    leadingIcon: Icons.lock_open_rounded,
                    isFullWidth: true,
                    onPressed: () async {
                      HapticFeedback.mediumImpact();
                      final success = await ref
                          .read(appLockProvider.notifier)
                          .unlock();
                      if (!success && context.mounted) {
                        showMindToast(context, strings.biometricFailedSnackbar);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
            ],
          ),
        ),
      ),
    );
  }
}
