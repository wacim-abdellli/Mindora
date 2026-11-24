import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/theme/lab_theme.dart';
import '../../../app/theme/mind_tokens.dart';
import '../../../core/widgets/fingerprint_thread_signature.dart';
import '../../../core/widgets/mind_pressable.dart';
import '../../case_file/domain/clarity_anchor_model.dart';
import '../../case_file/presentation/widgets/clarity_anchor_card.dart';
import '../controllers/investigation_providers.dart';
import '../domain/case_model.dart';
import '../domain/conversation_mode.dart';
import 'widgets/mode_chooser_sheet.dart';

/// The Landing Screen and Hub for the AI Companion.
///
/// Features (Build Session 05):
/// - Poetic introduction & identity banner
/// - Mode Selection Grid (6 modes with localized descriptions)
/// - Socratic suggested conversation starters
/// - Start New Conversation action
/// - Recent Conversation History list (Resume, Rename, Delete, Clear All)
/// - Luxury Vercel Dark & Master Burgundy aesthetics
/// - Strictly 0 emojis
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
              hintText: 'Enter title...',
              filled: true,
              fillColor: dialogTokens.surface2,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(dialogTokens.buttonRadius),
                borderSide: BorderSide(color: dialogTokens.line),
              ),
            ),
            style: TextStyle(
              fontSize: 13,
              color: dialogTokens.ink,
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

  void _showDeleteDialog(BuildContext context, CaseModel caseModel) {
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
            strings.deleteConversationTitle,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: dialogTokens.ink,
            ),
          ),
          content: Text(
            strings.deleteConversationConfirm,
            style: TextStyle(
              fontSize: 13,
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
                    .deleteCase(caseModel.id);
                if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
              },
              child: Text(strings.deletePermanentlyBtn),
            ),
          ],
        );
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
              fontSize: 13,
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

  Color _accentForMode(ConversationMode mode) {
    switch (mode) {
      case ConversationMode.exploreThought:
        return MindTokens.moodRestless;
      case ConversationMode.understandEmotion:
        return MindTokens.moodFrustrated;
      case ConversationMode.psychologicalAnalysis:
        return MindTokens.moodAnxious;
      case ConversationMode.guidedReflection:
        return MindTokens.moodCalm;
      case ConversationMode.justTalk:
        return MindTokens.moodHeavy;
      case ConversationMode.grounding:
        return MindTokens.moodCalm;
    }
  }

  Future<void> _startConversation([String? initialPrompt]) async {
    HapticFeedback.mediumImpact();
    final controller = ref.read(activeCaseControllerProvider.notifier);
    final activeMode = ref.read(currentConversationModeProvider);
    await controller.startNewCase(initialPrompt ?? '', mode: activeMode);
    widget.onSessionSelected?.call();
    if (initialPrompt != null && initialPrompt.trim().isNotEmpty) {
      unawaited(controller.requestAiReply());
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final strings = ref.watch(appStringsProvider);
    final selectedMode = ref.watch(currentConversationModeProvider);
    final savedCasesAsync = ref.watch(savedCasesProvider);

    final surfaceColor = tokens.surface;
    final borderColor = tokens.line;
    final textPrimary = tokens.ink;
    final textSecondary = tokens.ink2;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Poetic Hero Introduction
          _buildHeroHeader(isDark, strings, textPrimary, textSecondary),

          const SizedBox(height: 20),

          // 2. Mode Selection Section
          Row(
            children: [
              Text(
                strings.selectConversationMode.toUpperCase(),
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: context.tokens.ink,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: context.tokens.surface2,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor),
                ),
                child: Text(
                  '6 MODES',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Mode Cards Grid
          ...ConversationMode.values.map((mode) {
            final isSelected = mode == selectedMode;
            final modeTitle = localizedModeName(mode, strings);
            final modeDesc = localizedModeDesc(mode, strings);
            final modeColor = _accentForMode(mode);

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: MindPressable(
                semanticLabel: modeTitle,
                borderRadius: BorderRadius.circular(tokens.cardRadius),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  ref
                      .read(currentConversationModeProvider.notifier)
                      .setMode(mode);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? modeColor.withValues(alpha: isDark ? 0.11 : 0.08)
                        : surfaceColor,
                    borderRadius: BorderRadius.circular(tokens.cardRadius),
                    border: Border.all(
                      color: isSelected ? modeColor : borderColor,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(tokens.cardRadius - 1),
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(17, 14, 14, 14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(9),
                                decoration: BoxDecoration(
                                  color: modeColor.withValues(
                                      alpha: isSelected ? 0.20 : (isDark ? 0.10 : 0.08)),
                                  borderRadius: BorderRadius.circular(tokens.buttonRadius),
                                  border: Border.all(
                                    color: modeColor.withValues(
                                        alpha: isSelected ? 0.45 : 0.22),
                                  ),
                                ),
                                child: Icon(
                                  iconForConversationMode(mode),
                                  size: 18,
                                  color: modeColor,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            modeTitle,
                                            style: TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w700,
                                              color: isSelected ? modeColor : textPrimary,
                                            ),
                                          ),
                                        ),
                                        if (isSelected)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: modeColor.withValues(alpha: 0.16),
                                              borderRadius: BorderRadius.circular(tokens.chipRadius),
                                            ),
                                            child: Text(
                                              'ACTIVE',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 0.5,
                                                color: modeColor,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      modeDesc,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        height: 1.4,
                                        color: isSelected
                                            ? textPrimary.withValues(alpha: 0.90)
                                            : textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        PositionedDirectional(
                          start: 0,
                          top: 0,
                          bottom: 0,
                          width: isSelected ? 3.5 : 2.5,
                          child: ColoredBox(
                            color: isSelected
                                ? modeColor
                                : modeColor.withValues(alpha: isDark ? 0.35 : 0.25),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 14),

          // 3. Suggested Conversation Starters
          Text(
            strings.suggestedStartersTitle.toUpperCase(),
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: _accentForMode(selectedMode),
            ),
          ),
          const SizedBox(height: 8),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: strings.localizedStartersForMode(selectedMode.name).map((starter) {
              final selectedModeColor = _accentForMode(selectedMode);
              return MindPressable(
                semanticLabel: starter,
                borderRadius: BorderRadius.circular(tokens.chipRadius),
                onPressed: () => _startConversation(starter),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: tokens.surface2,
                    borderRadius: BorderRadius.circular(tokens.chipRadius),
                    border: Border.all(
                      color: isDark ? borderColor : tokens.line,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: selectedModeColor,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          starter,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // 4. Primary CTA: Start New Conversation
          MindPressable(
            semanticLabel: strings.newConversationBtn,
            borderRadius: BorderRadius.circular(tokens.buttonRadius),
            onPressed: () => _startConversation(),
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
                  Icon(
                    Icons.add_rounded,
                    size: 18,
                    color: tokens.bg,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    strings.newConversationBtn.toUpperCase(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: tokens.bg,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 26),

          // 4b. Pocket Clarity Anchors (only when distilled sessions exist)
          savedCasesAsync.maybeWhen(
            data: (cases) {
              final anchors = ClarityAnchorModel.fromCases(cases).take(4).toList();
              if (anchors.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.pocketAnchorsSectionTitle.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: strings.isArabic ? 0 : 0.8,
                        color: tokens.ink,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 0; i < anchors.length; i++) ...[
                            if (i > 0) const SizedBox(width: 10),
                            SizedBox(
                              width: 280,
                              child: ClarityAnchorCard(
                                anchor: anchors[i],
                                strings: strings,
                                compact: true,
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  final router = GoRouter.maybeOf(context);
                                  if (router != null) {
                                    router.push('/case/${anchors[i].caseId}');
                                  } else {
                                    final target = cases.firstWhere(
                                      (c) => c.id == anchors[i].caseId,
                                    );
                                    ref
                                        .read(
                                          activeCaseControllerProvider.notifier,
                                        )
                                        .resumeCase(target);
                                    widget.onSessionSelected?.call();
                                  }
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),

          // 5. Recent Conversations List
          Row(
            children: [
              Text(
                strings.recentConversationsTitle.toUpperCase(),
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: tokens.ink,
                ),
              ),
              const Spacer(),
              savedCasesAsync.maybeWhen(
                data: (cases) => cases.isNotEmpty
                    ? TextButton(
                        onPressed: () => _showClearAllDialog(context),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          strings.clearAllConversationsBtn,
                          style: TextStyle(
                            fontSize: 11.5,
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
                style: TextStyle(fontSize: 11, color: textSecondary),
              ),
            ),
            data: (cases) {
              if (cases.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(context.tokens.cardRadius),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.history_toggle_off_rounded, size: 20, color: textSecondary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          strings.noRecentConversations,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
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
                    child: Container(
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(context.tokens.cardRadius),
                        border: Border.all(color: borderColor),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          ref
                              .read(activeCaseControllerProvider.notifier)
                              .resumeCase(c);
                          widget.onSessionSelected?.call();
                        },
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: context.tokens.cardTint,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: context.tokens.ink.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Icon(
                            iconForConversationMode(c.conversationMode),
                            size: 16,
                            color: tokens.ink,
                          ),
                        ),
                        title: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: tokens.surface2,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                strings.formatSessionNumber(c.caseNumber),
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                c.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  localizedModeName(c.conversationMode, strings),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: tokens.ink,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text('•', style: TextStyle(fontSize: 11.5, color: textSecondary)),
                              const SizedBox(width: 6),
                              Text(
                                '${c.statements.length} exchanges',
                                style: TextStyle(fontSize: 11.5, color: textSecondary),
                              ),
                            ],
                          ),
                        ),
                        trailing: PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert_rounded, size: 18, color: textSecondary),
                          color: tokens.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(color: tokens.line),
                          ),
                          onSelected: (val) {
                            if (val == 'resume') {
                              ref
                                  .read(activeCaseControllerProvider.notifier)
                                  .resumeCase(c);
                            } else if (val == 'rename') {
                              _showRenameDialog(context, c);
                            } else if (val == 'delete') {
                              _showDeleteDialog(context, c);
                            }
                          },
                          itemBuilder: (ctx) => [
                            PopupMenuItem(
                              value: 'resume',
                              child: Text(strings.resumeConversationBtn, style: const TextStyle(fontSize: 13)),
                            ),
                            PopupMenuItem(
                              value: 'rename',
                              child: Text(strings.renameConversationTitle, style: const TextStyle(fontSize: 13)),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text(
                                strings.deleteConversationTitle,
                                style: TextStyle(fontSize: 13, color: tokens.safety),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(
    bool isDark,
    AppStrings strings,
    Color textPrimary,
    Color textSecondary,
  ) {
    final tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(tokens.cardRadius),
        border: Border.all(color: tokens.line, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FingerprintThreadSignature(size: 20, animated: false),
              const SizedBox(width: 8),
              Text(
                strings.aiCompanionTitle.toUpperCase(),
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: tokens.ink,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: tokens.cardTint,
                  borderRadius: BorderRadius.circular(tokens.chipRadius),
                  border: Border.all(color: tokens.ink.withValues(alpha: 0.35)),
                ),
                child: Text(
                  'CONFIDENTIAL & OFFLINE-FIRST',
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: tokens.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '“${strings.aiCompanionIntro}”',
            style: LabTheme.textStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.38,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            strings.aiCompanionSupporting,
            style: TextStyle(
              fontSize: 11.5,
              height: 1.45,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
