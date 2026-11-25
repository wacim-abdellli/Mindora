import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/localization/app_strings.dart';
import '../../app/theme/lab_theme.dart';
import '../../app/theme/mind_tokens.dart';
import '../widgets/mind_pressable.dart';
import '../widgets/mind_toast.dart';
import 'safety_model.dart';

/// Persistent, high-contrast one-tap safety shield reachable from every tab.
class SupportButton extends ConsumerWidget {
  const SupportButton({super.key, this.compact = false});

  final bool compact;

  void _openSupportSheet(BuildContext context) {
    SupportModalSheet.show(context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final tokens = context.tokens;

    return Tooltip(
      message: strings.needSupportBtn,
      excludeFromSemantics: true,
      child: MindPressable(
        onPressed: () => _openSupportSheet(context),
        semanticLabel: strings.needSupportBtn,
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: tokens.safetySoft,
                shape: BoxShape.circle,
                border: Border.all(
                  color: tokens.safety.withValues(alpha: 0.38),
                  width: 1.2,
                ),
              ),
              child: Icon(
                Icons.shield_outlined,
                size: 20,
                color: tokens.safety,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Modal bottom sheet presenting Tunisian crisis & supportive resources
/// (`80 10 50 50`, `190`, `198`) with >= 48dp 1-tap call buttons.
class SupportModalSheet extends ConsumerWidget {
  const SupportModalSheet({super.key});

  static Future<void> show(BuildContext context) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const SupportModalSheet(),
    );
  }

  Future<void> _makeCall(
    BuildContext context,
    AppStrings strings,
    String phone,
  ) async {
    HapticFeedback.mediumImpact();
    final uri = Uri.parse('tel:$phone');
    var launched = false;
    try {
      if (await canLaunchUrl(uri)) {
        launched = await launchUrl(uri);
      }
    } catch (_) {
      launched = false;
    }
    if (!launched) {
      await Clipboard.setData(ClipboardData(text: _formatPhone(phone)));
      if (context.mounted) {
        showMindToast(context, strings.dialerCopiedToast(_formatPhone(phone)));
      }
    }
  }

  Future<void> _openWeb(
    BuildContext context,
    AppStrings strings,
    String url,
  ) async {
    final uri = Uri.parse(url);
    var launched = false;
    try {
      if (await canLaunchUrl(uri)) {
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      launched = false;
    }
    if (!launched) {
      await Clipboard.setData(ClipboardData(text: url));
      if (context.mounted) {
        showMindToast(context, strings.linkCopiedToast(url));
      }
    }
  }

  String _formatPhone(String raw) {
    if (raw == '80105050') return '80 10 50 50';
    return raw;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final strings = ref.watch(appStringsProvider);
    final resources = CrisisResource.tunisianResources;

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(tokens.sheetRadius),
          ),
          border: Border.all(color: tokens.line, width: 1),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: tokens.safetySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.shield_outlined,
                    color: tokens.safety,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.supportModalTitle,
                        style: LabTheme.textStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          color: tokens.ink,
                        ),
                      ),
                      Text(
                        strings.supportModalSub,
                        style: LabTheme.textStyle(
                          fontSize: 13.0,
                          color: tokens.ink2,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                  icon: Icon(Icons.close_rounded, size: 22, color: tokens.ink2),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              strings.supportModalBody,
              style: LabTheme.textStyle(
                fontSize: 14.5,
                color: tokens.ink2,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: resources.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (ctx, index) {
                  final res = resources[index];
                  final hasPhone = res.phone.isNotEmpty;

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: tokens.surface2,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: tokens.line, width: 1),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                res.localizedName(strings),
                                style: LabTheme.textStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: tokens.ink,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                res.localizedDescription(strings),
                                style: LabTheme.textStyle(
                                  fontSize: 13.0,
                                  height: 1.35,
                                  color: tokens.ink2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (hasPhone)
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: tokens.safety,
                              foregroundColor: tokens.isDark
                                  ? tokens.bg
                                  : MindTokens.pureWhiteConstant,
                              minimumSize: const Size(48, 48),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(Icons.phone_outlined, size: 16),
                            label: Text(
                              _formatPhone(res.phone),
                              style: LabTheme.textStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13.5,
                                color: tokens.isDark
                                    ? tokens.bg
                                    : MindTokens.pureWhiteConstant,
                              ),
                            ),
                            onPressed: () =>
                                _makeCall(context, strings, res.phone),
                          )
                        else if (res.website != null)
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: tokens.lineStrong),
                              minimumSize: const Size(48, 48),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () =>
                                _openWeb(context, strings, res.website!),
                            child: Text(
                              strings.infoBadge,
                              style: LabTheme.textStyle(
                                color: tokens.ink,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
