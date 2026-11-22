import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/localization/app_strings.dart';
import '../../app/theme/mind_tokens.dart';
import '../widgets/bouncing_widget.dart';
import 'app_lock_provider.dart';

/// Full-screen biometric lock overlay protecting private cognitive sessions.
///
/// Luxury Vercel Dark aesthetic:
/// OLED pitch black (#000000), 1.0px hairline borders, monochrome action button,
/// and zero emoji clutter.
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
    final bg = tokens.bg;

    if (!lockState.isInitialized) {
      return ColoredBox(color: bg, child: const SizedBox.expand());
    }

    if (!lockState.isLocked) {
      return widget.child;
    }

    final surface = tokens.surface;
    final border = tokens.line;
    final textPrimary = tokens.ink;
    final textSecondary = tokens.ink2;

    return Directionality(
      textDirection: strings.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Biometric Icon Container
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: border, width: 1),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.fingerprint_rounded,
                        size: 32,
                        color: textPrimary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Tag
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: tokens.surface2,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: border),
                    ),
                    child: Text(
                      strings.biometricVaultLockedTitle.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: tokens.ink2,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'Mindora',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: textPrimary,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    strings.biometricVaultLockedDesc,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: textSecondary,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Unlock Action Button
                  SizedBox(
                    width: double.infinity,
                    child: BouncingWidget(
                      onTap: () async {
                        HapticFeedback.mediumImpact();
                        final success = await ref
                            .read(appLockProvider.notifier)
                            .unlock();
                        if (!success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: tokens.surface,
                              content: Text(
                                strings.biometricFailedSnackbar,
                                style: TextStyle(
                                  color: tokens.ink,
                                  fontSize: 12.5,
                                ),
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: tokens.ink,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: border, width: 1),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.lock_open_rounded,
                              size: 16,
                              color: tokens.bg,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              strings.unlockWithBiometricsBtn.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: tokens.bg,
                              ),
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
        ),
      ),
    );
  }
}
