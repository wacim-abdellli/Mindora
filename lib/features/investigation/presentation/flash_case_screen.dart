import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/theme/lab_theme.dart';
import '../../../app/theme/mind_tokens.dart';
import '../../../core/safety/support_button.dart';
import '../../../core/widgets/mind_pressable.dart';
import '../../../core/widgets/mind_sheet.dart';
import '../../journal/presentation/widgets/journal_memory_sheet.dart';
import '../controllers/investigation_providers.dart';
import '../domain/case_model.dart';
import '../domain/statement.dart';
import 'ai_companion_hub_view.dart';
import 'widgets/ai_engine_config_sheet.dart';
import 'widgets/custom_ai_instructions_sheet.dart';
import 'widgets/live_dialogue_view.dart';
import 'widgets/mode_chooser_sheet.dart';

/// Calm single-bar `Talk` tab:
/// - 1 clean 56dp AppBar (`Talk`, `[Saved (N)]`, `[+]`, `[...] More`, `[Help]`)
/// - Secondary settings (listening style, instructions, memories, AI engine)
///   tucked inside the `More` sheet so chat fills the screen even at 320px 2.0x.
class FlashCaseScreen extends ConsumerStatefulWidget {
  const FlashCaseScreen({super.key, this.initialHubView = false});

  final bool initialHubView;

  @override
  ConsumerState<FlashCaseScreen> createState() => _FlashCaseScreenState();
}

class _FlashCaseScreenState extends ConsumerState<FlashCaseScreen> {
  late bool _showHubView = widget.initialHubView;

  @override
  void initState() {
    super.initState();
    _ensureActiveCase();
  }

  @override
  void didUpdateWidget(covariant FlashCaseScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialHubView && !oldWidget.initialHubView && !_showHubView) {
      setState(() => _showHubView = true);
    }
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

  Future<void> _openMoreSheet(BuildContext context, AppStrings strings) async {
    final activeMode = ref.read(currentConversationModeProvider);
    final aiConfig = ref.read(aiConfigProvider);
    final engineLabel = !aiConfig.isLiveActive
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
                  Icon(Icons.chevron_right_rounded, color: tokens.ink2),
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
            row(
              icon: Icons.forum_outlined,
              title: strings.modesAndHistoryTooltip,
              onTap: () async {
                await ModeChooserSheet.show(
                  context,
                  activeMode: activeMode,
                  onModeSelected: (picked) {
                    if (mounted) {
                      ref
                          .read(currentConversationModeProvider.notifier)
                          .setMode(picked);
                      ref
                          .read(activeCaseControllerProvider.notifier)
                          .setConversationMode(picked);
                    }
                  },
                );
              },
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
    final savedCases = ref.watch(savedCasesProvider).value ?? [];
    final strings = ref.watch(appStringsProvider);
    final tokens = context.tokens;

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

    final caseModel = caseAsync.value;

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
        title: Text(
          strings.navTalk,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: LabTheme.textStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: tokens.ink,
          ),
        ),
        actions: [
          if (!_showHubView)
            MindPressable(
              onPressed: () {
                HapticFeedback.selectionClick();
                setState(() => _showHubView = true);
              },
              semanticLabel: strings.talkSavedPill(savedCases.length),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                constraints: const BoxConstraints(minHeight: 48, maxWidth: 96),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: tokens.surface2,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: tokens.line),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      strings.talkSavedPill(savedCases.length),
                      maxLines: 1,
                      style: LabTheme.textStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: tokens.ink,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (!_showHubView)
            IconButton(
              icon: Icon(Icons.add_rounded, size: 22, color: tokens.ink),
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
                final activeMode = ref.read(currentConversationModeProvider);
                await ref
                    .read(activeCaseControllerProvider.notifier)
                    .startNewCase('', mode: activeMode);
              },
            ),
          IconButton(
            icon: Icon(Icons.more_horiz_rounded, size: 22, color: tokens.ink),
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
