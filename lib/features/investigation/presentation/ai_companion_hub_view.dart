import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/theme/lab_theme.dart';
import '../../../app/theme/mind_tokens.dart';
import '../../../core/widgets/mind_pressable.dart';
import '../../../core/widgets/mind_undo_banner.dart';
import '../controllers/investigation_providers.dart';
import '../domain/case_model.dart';

/// Calm Past Consultations view opened from Talk's `[History]` button.
///
/// Deliberately avoids clinical mode grids and button clutter so users simply
/// start a fresh consultation, revisit a past note, lock it private, or delete safely.
class AiCompanionHubView extends ConsumerStatefulWidget {
  const AiCompanionHubView({super.key, this.onSessionSelected});

  final VoidCallback? onSessionSelected;

  @override
  ConsumerState<AiCompanionHubView> createState() => _AiCompanionHubViewState();
}

class _AiCompanionHubViewState extends ConsumerState<AiCompanionHubView> {
  void _showRenameDialog(BuildContext context, CaseModel caseModel) {
    final controller = TextEditingController(text: caseModel.title);
    final strings = ref.read(appStringsProvider);

    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        final dialogTokens = dialogCtx.tokens;
        return AlertDialog(
          backgroundColor: dialogTokens.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(dialogTokens.cardRadius),
            side: BorderSide(color: dialogTokens.line),
          ),
          title: Text(
            strings.renameConversationTitle,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: dialogTokens.ink,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: strings.renameConversationTitle,
              filled: true,
              fillColor: dialogTokens.surface2,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(dialogTokens.buttonRadius),
                borderSide: BorderSide(color: dialogTokens.line),
              ),
            ),
            style: TextStyle(fontSize: 14, color: dialogTokens.ink),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text(
                strings.cancelBtn,
                style: TextStyle(color: dialogTokens.ink2),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: dialogTokens.ink,
                foregroundColor: dialogTokens.bg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(dialogTokens.buttonRadius),
                ),
              ),
              onPressed: () async {
                final newTitle = controller.text.trim();
                if (newTitle.isNotEmpty) {
                  await ref
                      .read(activeCaseControllerProvider.notifier)
                      .renameCase(caseModel.id, newTitle);
                }
                if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
              },
              child: Text(strings.saveVerdictBtn),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    CaseModel caseModel,
  ) async {
    final strings = ref.read(appStringsProvider);
    final repo = ref.read(caseRepositoryProvider);
    HapticFeedback.mediumImpact();
    await ref
        .read(activeCaseControllerProvider.notifier)
        .deleteCase(caseModel.id);
    if (!context.mounted) return;
    showMindUndoBanner(
      context,
      message: strings.talkDeletedUndo,
      undoLabel: strings.undoBtn,
      onUndo: () async {
        await repo.saveCase(caseModel);
        ref.invalidate(savedCasesProvider);
      },
    );
  }

  void _showClearAllDialog(BuildContext context) {
    final strings = ref.read(appStringsProvider);

    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        final dialogTokens = dialogCtx.tokens;
        return AlertDialog(
          backgroundColor: dialogTokens.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(dialogTokens.cardRadius),
            side: BorderSide(color: dialogTokens.line),
          ),
          title: Text(
            strings.clearAllConversationsBtn,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: dialogTokens.ink,
            ),
          ),
          content: Text(
            strings.clearAllConversationsConfirm,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: dialogTokens.ink2,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text(
                strings.cancelBtn,
                style: TextStyle(color: dialogTokens.ink2),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: dialogTokens.safety,
                foregroundColor: dialogTokens.bg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(dialogTokens.buttonRadius),
                ),
              ),
              onPressed: () async {
                await ref
                    .read(activeCaseControllerProvider.notifier)
                    .deleteAllCases();
                if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
              },
              child: Text(strings.deletePermanentlyBtn),
            ),
          ],
        );
      },
    );
  }

  Future<void> _startFreshTalk() async {
    HapticFeedback.lightImpact();
    await ref.read(activeCaseControllerProvider.notifier).startNewCase('');
    widget.onSessionSelected?.call();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final strings = ref.watch(appStringsProvider);
    final savedCasesAsync = ref.watch(savedCasesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: tokens.surface,
              borderRadius: BorderRadius.circular(tokens.cardRadius),
              border: Border.all(color: tokens.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.talkHistoryTooltip,
                  style: LabTheme.textStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: tokens.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  strings.talkWelcomeSub,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    color: tokens.ink2,
                  ),
                ),
                const SizedBox(height: 14),
                MindPressable(
                  key: const ValueKey('hub-new-talk-btn'),
                  semanticLabel: strings.newConversationBtn,
                  borderRadius: BorderRadius.circular(tokens.buttonRadius),
                  onPressed: _startFreshTalk,
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      color: tokens.ink,
                      borderRadius: BorderRadius.circular(tokens.buttonRadius),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_rounded, size: 18, color: tokens.bg),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            strings.newConversationBtn,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: tokens.bg,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          Row(
            children: [
              Expanded(
                child: Text(
                  strings.recentConversationsTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: tokens.ink,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              savedCasesAsync.maybeWhen(
                data: (cases) => cases.isNotEmpty
                    ? TextButton(
                        onPressed: () => _showClearAllDialog(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: const Size(48, 48),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          strings.clearAllConversationsBtn,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: tokens.safety,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 10),

          savedCasesAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (err, _) => Center(
              child: Text(
                'Error loading conversations: $err',
                style: TextStyle(fontSize: 12, color: tokens.ink2),
              ),
            ),
            data: (cases) {
              if (cases.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: tokens.surface,
                    borderRadius: BorderRadius.circular(tokens.cardRadius),
                    border: Border.all(color: tokens.line),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.history_toggle_off_rounded,
                        size: 20,
                        color: tokens.ink2,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          strings.noRecentConversations,
                          style: TextStyle(fontSize: 13, color: tokens.ink2),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: cases.map((c) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: MindPressable(
                      semanticLabel: c.title,
                      borderRadius: BorderRadius.circular(tokens.cardRadius),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        ref
                            .read(activeCaseControllerProvider.notifier)
                            .resumeCase(c);
                        widget.onSessionSelected?.call();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: tokens.surface,
                          borderRadius: BorderRadius.circular(
                            tokens.cardRadius,
                          ),
                          border: Border.all(color: tokens.line),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: tokens.surface2,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: tokens.line),
                              ),
                              child: Icon(
                                c.isPrivate
                                    ? Icons.lock_outline_rounded
                                    : Icons.chat_bubble_outline_rounded,
                                size: 17,
                                color: tokens.ink2,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                      color: tokens.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 2,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        strings.formatSessionNumber(
                                          c.caseNumber,
                                        ),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: tokens.ink2,
                                        ),
                                      ),
                                      if (c.isPrivate)
                                        Text(
                                          strings.privacyPrivateSessionTag,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: tokens.ink2,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: Icon(
                                Icons.more_vert_rounded,
                                size: 19,
                                color: tokens.ink2,
                              ),
                              color: tokens.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(color: tokens.line),
                              ),
                              onSelected: (val) async {
                                if (val == 'resume') {
                                  ref
                                      .read(activeCaseControllerProvider.notifier)
                                      .resumeCase(c);
                                  widget.onSessionSelected?.call();
                                } else if (val == 'privacy') {
                                  await ref
                                      .read(activeCaseControllerProvider.notifier)
                                      .toggleCasePrivacy(c.id);
                                } else if (val == 'rename') {
                                  _showRenameDialog(context, c);
                                } else if (val == 'delete') {
                                  await _showDeleteDialog(context, c);
                                }
                              },
                              itemBuilder: (ctx) => [
                                PopupMenuItem(
                                  value: 'resume',
                                  child: Text(
                                    strings.resumeConversationBtn,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'privacy',
                                  child: Text(
                                    strings.talkPrivateToggleTitle,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'rename',
                                  child: Text(
                                    strings.renameConversationTitle,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text(
                                    strings.deleteConversationTitle,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: tokens.safety,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}
