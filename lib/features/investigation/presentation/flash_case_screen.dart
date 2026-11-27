import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/localization/locale_controller.dart';
import '../../../app/theme/lab_theme.dart';
import '../../../app/theme/mind_tokens.dart';
import '../../../core/safety/support_button.dart';
import '../../../core/widgets/mind_pressable.dart';
import '../../../core/widgets/mind_sheet.dart';
import '../../journal/presentation/widgets/journal_memory_sheet.dart';
import '../../profile/controllers/profile_controller.dart';
import '../controllers/investigation_providers.dart';
import '../domain/case_model.dart';
import '../domain/statement.dart';
import 'ai_companion_hub_view.dart';
import 'widgets/ai_engine_config_sheet.dart';
import 'widgets/custom_ai_instructions_sheet.dart';
import 'widgets/live_dialogue_view.dart';

/// Calm single-bar `Talk` sanctuary:
/// - Minimalist 56dp AppBar (`Talk` + quiet status dot, `[History]`, `[+]`, `[...]`, `[Help]`)
/// - Zero manual mode-picker clutter: AI adapts tone & quick options dynamically
class FlashCaseScreen extends ConsumerStatefulWidget {
  const FlashCaseScreen({super.key, this.initialHubView = false});

  final bool initialHubView;

  @override
  ConsumerState<FlashCaseScreen> createState() => _FlashCaseScreenState();
}

class _FlashCaseScreenState extends ConsumerState<FlashCaseScreen> {
  late bool _showHubView;
  bool _isSynthesizing = false;

  @override
  void initState() {
    super.initState();
    _showHubView = widget.initialHubView;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureActiveCase();
    });
  }

  Future<void> _ensureActiveCase() async {
    final active = await ref
        .read(activeCaseControllerProvider.notifier)
        .ensureHydrated();
    if (active == null || active.isCompleted) {
      if (mounted) {
        await ref
            .read(activeCaseControllerProvider.notifier)
            .startNewCase('');
      }
    }
  }

  Future<void> _saveSummaryNote(BuildContext context, AppStrings strings) async {
    final currentCase = ref.read(activeCaseControllerProvider).value;
    if (currentCase == null ||
        !currentCase.statements.any((s) => s.speaker == StatementSpeaker.user) ||
        _isSynthesizing) {
      return;
    }

    setState(() => _isSynthesizing = true);
    HapticFeedback.mediumImpact();

    try {
      final service = ref.read(investigatorServiceProvider);
      final locale = ref.read(localeControllerProvider);
      final profile = ref.read(profileControllerProvider).value;
      final tokens = context.tokens;

      final summary = await service.summarizeFindings(
        currentCase: currentCase,
        languageCode: locale.languageCode,
        profile: profile,
      );

      final notifier = ref.read(activeCaseControllerProvider.notifier);
      await notifier.saveFindings(summary);
      await notifier.saveConclusion(summary);

      if (!context.mounted) return;
      final router = GoRouter.maybeOf(context);
      if (router != null) {
        unawaited(router.push('/case/${currentCase.id}'));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: tokens.surface,
            content: Text(
              strings.caseSynthesizedSuccess,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: tokens.ink,
              ),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      // Keep calm without disruptive error banners
    } finally {
      if (mounted) {
        setState(() => _isSynthesizing = false);
      }
    }
  }

  Future<void> _openMoreSheet(BuildContext context, AppStrings strings) async {
    final aiConfig = ref.read(aiConfigProvider);
    final activeCase = ref.read(activeCaseControllerProvider).value;
    final hasUserMessages = activeCase != null &&
        activeCase.statements.any((s) => s.speaker == StatementSpeaker.user);
    final isPrivate = activeCase?.isPrivate ?? false;
    final engineLabel = aiConfig.isMockKey
        ? strings.engineBadgeOffline
        : (aiConfig.provider == AiEngineProvider.groq
              ? strings.engineBadgeGroq
              : strings.engineBadgeGemini);

    await showMindSheet<void>(
      context: context,
      showCloseButton: true,
      title: strings.navTalk,
      builder: (ctx) {
        final tokens = ctx.tokens;
        Widget row({
          required IconData icon,
          required String title,
          String? subtitle,
          required VoidCallback onTap,
        }) {
          return MindPressable(
            onPressed: () {
              Navigator.of(ctx).pop();
              onTap();
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              constraints: const BoxConstraints(minHeight: 56),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: tokens.surface2,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: tokens.line),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 22, color: tokens.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: LabTheme.textStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: tokens.ink,
                          ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle,
                            style: LabTheme.textStyle(
                              fontSize: 13.0,
                              color: tokens.ink2,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, size: 16, color: tokens.ink2),
                ],
              ),
            ),
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            row(
              icon: Icons.tune_rounded,
              title: strings.listeningPrefsLabel,
              onTap: () => CustomAiInstructionsSheet.show(context),
            ),
            if (activeCase != null)
              row(
                icon: isPrivate ? Icons.lock_rounded : Icons.lock_open_rounded,
                title: strings.talkPrivateToggleTitle,
                subtitle: isPrivate ? strings.privacyPrivateSessionTag : null,
                onTap: () async {
                  await ref
                      .read(activeCaseControllerProvider.notifier)
                      .toggleCasePrivacy(activeCase.id);
                  if (!context.mounted) return;
                  final nowPrivate =
                      ref.read(activeCaseControllerProvider).value?.isPrivate ??
                      !isPrivate;
                  if (nowPrivate) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(strings.talkPrivateEnabledNotice),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
            if (hasUserMessages)
              row(
                icon: Icons.fact_check_outlined,
                title: strings.saveTakeawayReportBtn,
                onTap: () => _saveSummaryNote(context, strings),
              ),
            row(
              icon: Icons.bookmark_border_rounded,
              title: strings.memoryVaultTitle,
              onTap: () => JournalMemorySheet.show(context),
            ),
            row(
              icon: Icons.bolt_outlined,
              title: strings.aiEngineTooltip,
              subtitle: engineLabel,
              onTap: () => AiEngineConfigSheet.show(context),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final caseAsync = ref.watch(activeCaseControllerProvider);
    final strings = ref.watch(appStringsProvider);
    final tokens = context.tokens;
    final aiConfig = ref.watch(aiConfigProvider);
    final profile = ref.watch(profileControllerProvider).value;
    final profileConsented =
        (profile?.shareWithAiCompanion ?? false) &&
        (profile?.allowAiPersonalization ?? false);
    final caseModel = caseAsync.value;
    final isLiveConnected =
        aiConfig.isLiveActive && profileConsented && !(caseModel?.isPrivate ?? false);

    ref.listen<AsyncValue<CaseModel?>>(activeCaseControllerProvider, (
      prev,
      next,
    ) {
      if (prev?.value != null &&
          next.value != null &&
          prev!.value!.id != next.value!.id) {
        if (_showHubView) {
          setState(() => _showHubView = false);
        }
      }
    });
    ref.listen<int>(companionHubSignalProvider, (prev, next) {
      if (prev != next && !_showHubView && mounted) {
        setState(() => _showHubView = true);
      }
    });

    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: AppBar(
        backgroundColor: tokens.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: _showHubView
            ? IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: tokens.ink),
                tooltip: strings.backBtn,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                onPressed: () => setState(() => _showHubView = false),
              )
            : null,
        titleSpacing: 12,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                strings.navTalk,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: LabTheme.textStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 19,
                  color: tokens.ink,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isLiveConnected
                    ? MindTokens.moodCalm
                    : tokens.ink2.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
        actions: [
          if (!_showHubView)
            Semantics(
              button: true,
              label: strings.talkHistoryTooltip,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(end: 2),
                child: MindPressable(
                  key: const ValueKey('talk-history-btn'),
                  semanticLabel: strings.talkHistoryTooltip,
                  borderRadius: BorderRadius.circular(tokens.chipRadius),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    setState(() => _showHubView = true);
                  },
                  child: Tooltip(
                    message: strings.talkHistoryTooltip,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: MediaQuery.sizeOf(context).width >= 355
                            ? 10
                            : 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: tokens.surface,
                        borderRadius: BorderRadius.circular(tokens.chipRadius),
                        border: Border.all(color: tokens.line),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.history_rounded,
                            size: 19,
                            color: tokens.ink,
                          ),
                          if (MediaQuery.sizeOf(context).width >= 355 &&
                              MediaQuery.textScalerOf(context).scale(14) <= 18) ...[
                            const SizedBox(width: 5),
                            Text(
                              strings.talkHistoryShortBtn,
                              style: LabTheme.textStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: tokens.ink,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (!_showHubView)
            IconButton(
              key: const ValueKey('talk-new-chat-btn'),
              icon: Icon(Icons.add_rounded, size: 23, color: tokens.ink),
              tooltip: strings.newConversationBtn,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              onPressed: () async {
                HapticFeedback.lightImpact();
                final active = ref.read(activeCaseControllerProvider).value;
                final hasUserMessages = active != null &&
                    active.statements
                        .any((s) => s.speaker == StatementSpeaker.user);
                if (active != null && !active.isCompleted && !hasUserMessages) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(strings.alreadyFreshChatNotice),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                  return;
                }
                await ref
                    .read(activeCaseControllerProvider.notifier)
                    .startNewCase('');
              },
            ),
          IconButton(
            key: const ValueKey('talk-more-btn'),
            icon: Icon(Icons.tune_rounded, size: 21, color: tokens.ink),
            tooltip: strings.listeningPrefsLabel,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: () => _openMoreSheet(context, strings),
          ),
          const SupportButton(compact: true),
          const SizedBox(width: 4),
        ],
      ),
      body: _showHubView
          ? SafeArea(
              child: AiCompanionHubView(
                onSessionSelected: () {
                  if (mounted && _showHubView) {
                    setState(() => _showHubView = false);
                  }
                },
              ),
            )
          : (caseModel != null
                ? SafeArea(child: LiveDialogueView(caseModel: caseModel))
                : SafeArea(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: tokens.primary,
                        strokeWidth: 2.5,
                      ),
                    ),
                  )),
    );
  }
}

void unawaited(Future<void>? future) {}
