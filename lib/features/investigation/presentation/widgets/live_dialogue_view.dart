import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/theme/mind_tokens.dart';
import '../../../../core/safety/safety_interceptor.dart';
import '../../../../core/widgets/mind_pressable.dart';
import '../../../../core/widgets/mind_sheet.dart';
import '../../../clinician/controllers/clinician_providers.dart';
import '../../../journey/controllers/journey_controller.dart';
import '../../../mind_trace/controllers/mind_trace_controller.dart';
import '../../../profile/controllers/profile_controller.dart';
import '../../../support/presentation/contextual_support_sheet.dart';
import '../../controllers/investigation_providers.dart';
import '../../domain/case_model.dart';
import '../../domain/investigator_service.dart';
import '../../domain/statement.dart';
import 'ai_engine_config_sheet.dart';
import 'companion_context_bridge_card.dart';

/// Calm, minimalist, options-first dialogue sanctuary.
///
/// The AI autonomously adapts its posture and contextual reply options per turn,
/// sparing the user from picking clinical modes or tagging every thought bubble.
class LiveDialogueView extends ConsumerStatefulWidget {
  const LiveDialogueView({super.key, required this.caseModel});

  final CaseModel caseModel;

  @override
  ConsumerState<LiveDialogueView> createState() => _LiveDialogueViewState();
}

class _LiveDialogueViewState extends ConsumerState<LiveDialogueView> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isInvestigatorTyping = false;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final reduceMotion = MediaQuery.disableAnimationsOf(context);
      final target = _scrollController.position.maxScrollExtent;
      if (reduceMotion) {
        _scrollController.jumpTo(target);
      } else {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _sendMessage([String? quickText]) async {
    final text = (quickText ?? _textController.text).trim();
    if (text.isEmpty ||
        _isInvestigatorTyping ||
        ref.read(companionReplyPendingProvider)) {
      return;
    }

    final activeCase =
        ref.read(activeCaseControllerProvider).value ?? widget.caseModel;
    if (activeCase.isPausedForSafety) return;

    if (quickText == null) {
      _textController.clear();
    }

    HapticFeedback.lightImpact();
    if (mounted) {
      setState(() => _isInvestigatorTyping = true);
    }
    _scrollToBottom();

    try {
      final notifier = ref.read(activeCaseControllerProvider.notifier);
      final journey = ref.read(journeyControllerProvider).value;
      final traces = ref.read(mindTraceControllerProvider).value ?? [];
      final todayTrace = ref.read(todayTraceProvider);

      final proceeded = await notifier.sendMessageAndGenerateReply(
        text,
        latestTrace: todayTrace,
        historicalTraces: traces,
        journey: journey,
        onLevel2Crisis: () async {
          if (mounted) {
            SafetyInterceptor.showCrisisPauseDialog(context);
          }
        },
      );

      if (mounted && proceeded) {
        HapticFeedback.selectionClick();
      }
    } finally {
      if (mounted) {
        setState(() => _isInvestigatorTyping = false);
        _scrollToBottom();
      }
    }
  }

  Future<void> _openMessageActions(
    Statement statement,
    AppStrings strings,
  ) async {
    HapticFeedback.selectionClick();
    await showMindSheet<void>(
      context: context,
      showCloseButton: true,
      title: strings.navTalk,
      builder: (ctx) {
        final tokens = ctx.tokens;
        Widget item({
          required IconData icon,
          required String label,
          required VoidCallback onTap,
        }) {
          return MindPressable(
            onPressed: () {
              Navigator.of(ctx).pop();
              onTap();
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              constraints: const BoxConstraints(minHeight: 52),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: tokens.surface2,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: tokens.line),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: tokens.ink),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: tokens.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            item(
              icon: Icons.bookmark_add_outlined,
              label: strings.talkKeepInsightAction,
              onTap: () async {
                await ref
                    .read(activeCaseControllerProvider.notifier)
                    .bookmarkTakeaway(statement.text);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(strings.takeawayBookmarkedLabel),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            item(
              icon: Icons.copy_rounded,
              label: strings.talkCopyAction,
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: statement.text));
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(strings.talkCopiedNotice),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final strings = ref.watch(appStringsProvider);
    final aiConfig = ref.watch(aiConfigProvider);
    final profile = ref.watch(profileControllerProvider).value;
    final activeCase =
        ref.watch(activeCaseControllerProvider).value ?? widget.caseModel;

    final statements = activeCase.statements;
    final hasUserMessages = statements.any(
      (s) => s.speaker == StatementSpeaker.user,
    );
    final isLive = aiConfig.isLiveActive;
    final profileConsented =
        (profile?.shareWithAiCompanion ?? false) &&
        (profile?.allowAiPersonalization ?? false);
    final showTypingIndicator =
        _isInvestigatorTyping || ref.watch(companionReplyPendingProvider);
    final runtimeNotice = ref.watch(aiRuntimeNoticeProvider);

    var lastAiIndex = -1;
    for (var i = statements.length - 1; i >= 0; i--) {
      if (statements[i].speaker == StatementSpeaker.investigator) {
        lastAiIndex = i;
        break;
      }
    }

    return Column(
      children: [
        if (runtimeNotice != AiFallbackReason.none)
          _buildRuntimeNoticeBanner(
            tokens: tokens,
            strings: strings,
            reason: runtimeNotice,
          ),
        Expanded(
          child: !hasUserMessages
              ? _buildCalmWelcomeCanvas(
                  tokens: tokens,
                  strings: strings,
                  activeCase: activeCase,
                  isLive: isLive,
                  profileConsented: profileConsented,
                )
              : ListView.builder(
                  controller: _scrollController,
                  cacheExtent: 500,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  itemCount:
                      statements.length + (showTypingIndicator ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == statements.length && showTypingIndicator) {
                      return _CalmTypingIndicator(
                        tokens: tokens,
                        label: strings.investigatorTyping,
                      );
                    }
                    final stmt = statements[index];
                    return _buildEditorialMessage(
                      statement: stmt,
                      tokens: tokens,
                      strings: strings,
                      isLatestAiTurn:
                          index == lastAiIndex &&
                          !showTypingIndicator &&
                          activeCase.offeredCalmExercise != null &&
                          activeCase.offeredCalmExercise != 'none',
                    );
                  },
                ),
        ),
        if (hasUserMessages &&
            !showTypingIndicator &&
            activeCase.suggestedReplies.isNotEmpty &&
            !activeCase.isPausedForSafety)
          _buildDynamicOptionsBar(
            tokens: tokens,
            options: activeCase.suggestedReplies,
          ),
        _buildBottomInputBar(tokens: tokens, strings: strings),
      ],
    );
  }

  Widget _buildRuntimeNoticeBanner({
    required MindTokens tokens,
    required AppStrings strings,
    required AiFallbackReason reason,
  }) {
    final msg = switch (reason) {
      AiFallbackReason.dailyLimitReached => strings.aiNoticeDailyLimit,
      AiFallbackReason.offlineOrNetwork => strings.aiNoticeOfflineFallback,
      AiFallbackReason.apiError => strings.aiNoticeApiErrorFallback,
      AiFallbackReason.none => '',
    };
    if (msg.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: tokens.safetySoft,
        border: Border(bottom: BorderSide(color: tokens.line)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: tokens.safety),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              msg,
              style: TextStyle(
                fontSize: 12,
                color: tokens.ink,
                height: 1.35,
              ),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            onPressed: () => AiEngineConfigSheet.show(context),
            child: Text(
              strings.aiEngineSettingsAction,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: tokens.ink,
              ),
            ),
          ),
          IconButton(
            tooltip: strings.closeBtn,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            icon: Icon(Icons.close_rounded, size: 16, color: tokens.ink2),
            onPressed: () => ref.read(aiRuntimeNoticeProvider.notifier).clear(),
          ),
        ],
      ),
    );
  }

  Widget _buildCalmWelcomeCanvas({
    required MindTokens tokens,
    required AppStrings strings,
    required CaseModel activeCase,
    required bool isLive,
    required bool profileConsented,
  }) {
    final todayTrace = ref.watch(todayTraceProvider);
    final focusPlan = ref.watch(postVisitFocusControllerProvider).value;
    final hasBridge = todayTrace != null ||
        (focusPlan != null &&
            !focusPlan.isDismissed &&
            (focusPlan.focusItems.any((i) => !i.isCompleted) ||
                focusPlan.observationCue.trim().isNotEmpty));

    final privacyLine = activeCase.isPrivate
        ? strings.privacyPrivateSessionTag
        : (isLive
              ? (profileConsented
                    ? strings.privacyCloudConsentedTag
                    : strings.privacyConsentPausedTag)
              : strings.privacyLocalTag);

    final doorways = [
      strings.talkDoorwaySpinning,
      strings.talkDoorwayHeavyDay,
      strings.talkDoorwayJustSit,
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: MindTokens.moodCalm.withValues(alpha: 0.16),
                border: Border.all(
                  color: MindTokens.moodCalm.withValues(alpha: 0.45),
                ),
              ),
              child: Icon(
                Icons.spa_outlined,
                size: 22,
                color: tokens.ink,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            strings.talkWelcomeHeadline,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: tokens.ink,
              height: 1.3,
              letterSpacing: strings.isArabic ? 0 : -0.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${strings.talkWelcomeSub} · $privacyLine',
            style: TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: tokens.ink2,
            ),
          ),
          if (hasBridge) ...[
            const SizedBox(height: 18),
            CompanionContextBridgeCard(
              todayTrace: todayTrace,
              focusPlan: focusPlan,
              strings: strings,
              onStartPrompt: (prompt) => _sendMessage(prompt),
              onOpenSettleSupport: () => ContextualSupportSheet.show(
                context,
                initialChoice: SupportChoice.settle,
              ),
            ),
          ],
          const SizedBox(height: 20),
          for (final doorway in doorways)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: MindPressable(
                semanticLabel: doorway,
                borderRadius: BorderRadius.circular(18),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _sendMessage(doorway);
                },
                child: Container(
                  constraints: const BoxConstraints(minHeight: 54),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: tokens.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: tokens.line),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          doorway,
                          style: TextStyle(
                            fontSize: 14.5,
                            height: 1.38,
                            fontWeight: FontWeight.w600,
                            color: tokens.ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: tokens.ink2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEditorialMessage({
    required Statement statement,
    required MindTokens tokens,
    required AppStrings strings,
    required bool isLatestAiTurn,
  }) {
    final isUser = statement.speaker == StatementSpeaker.user;
    final maxBubbleWidth = math.min(
      MediaQuery.sizeOf(context).width * 0.84,
      520.0,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onLongPress: () => _openMessageActions(statement, strings),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxBubbleWidth),
              child: Container(
                padding: isUser
                    ? const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
                    : const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isUser ? tokens.surface2 : tokens.surface,
                  borderRadius: BorderRadius.circular(isUser ? 20 : 18),
                  border: Border.all(color: tokens.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isUser) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: MindTokens.moodCalm,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              strings.talkConsultSpeaker,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: tokens.ink2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      statement.text,
                      style: TextStyle(
                        fontSize: isUser ? 15.0 : 15.5,
                        height: 1.55,
                        color: tokens.ink,
                        fontWeight: isUser ? FontWeight.w500 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (!isUser && isLatestAiTurn) ...[
            const SizedBox(height: 10),
            MindPressable(
              key: const ValueKey('talk-inline-calm-offer'),
              semanticLabel: strings.talkCalmBreathOfferBtn,
              borderRadius: BorderRadius.circular(16),
              onPressed: () {
                HapticFeedback.selectionClick();
                ContextualSupportSheet.show(
                  context,
                  initialChoice: SupportChoice.settle,
                );
              },
              child: Container(
                constraints: BoxConstraints(
                  minHeight: 48,
                  maxWidth: maxBubbleWidth,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: tokens.cardTint,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: MindTokens.moodCalm.withValues(alpha: 0.45),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.air_rounded, size: 17, color: tokens.ink),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        strings.talkCalmBreathOfferBtn,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: tokens.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: tokens.ink2,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDynamicOptionsBar({
    required MindTokens tokens,
    required List<String> options,
  }) {
    final visibleOptions = options.take(3).toList(growable: false);
    final maxOptionWidth = MediaQuery.sizeOf(context).width - 32;
    return Container(
      key: const ValueKey('talk-dynamic-options-bar'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      decoration: BoxDecoration(
        color: tokens.bg,
        border: Border(top: BorderSide(color: tokens.line, width: 0.8)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var i = 0; i < visibleOptions.length; i++)
            MindPressable(
              key: ValueKey('talk-dynamic-option-$i'),
              semanticLabel: visibleOptions[i],
              borderRadius: BorderRadius.circular(20),
              onPressed: _isInvestigatorTyping
                  ? null
                  : () => _sendMessage(visibleOptions[i]),
              child: Container(
                constraints: BoxConstraints(
                  minHeight: 48,
                  maxWidth: maxOptionWidth,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: tokens.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: tokens.line),
                ),
                child: Text(
                  visibleOptions[i],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.0,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                    color: tokens.ink,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomInputBar({
    required MindTokens tokens,
    required AppStrings strings,
  }) {
    final activeCase =
        ref.watch(activeCaseControllerProvider).value ?? widget.caseModel;
    final isPaused = activeCase.isPausedForSafety;
    final isReplying =
        _isInvestigatorTyping || ref.watch(companionReplyPendingProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border(top: BorderSide(color: tokens.line, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              enabled: !isPaused && !isReplying,
              minLines: 1,
              maxLines: 3,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => isPaused ? null : _sendMessage(),
              style: TextStyle(fontSize: 15, color: tokens.ink),
              decoration: InputDecoration(
                hintText: isPaused
                    ? (strings.isArabic
                        ? 'تم إيقاف الجلسة مؤقتاً لسلامتك'
                        : (strings.isFrench
                            ? 'Session mise en pause par sécurité'
                            : 'Session paused for safety'))
                    : strings.talkComposerHint,
                hintMaxLines: 1,
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: isPaused ? tokens.safety : tokens.ink2,
                ),
                filled: true,
                fillColor: tokens.surface2,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 13,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: tokens.line, width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: tokens.line, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: tokens.ink, width: 1.2),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          MindPressable(
            semanticLabel: isPaused
                ? (strings.isArabic
                    ? 'تم إيقاف الجلسة مؤقتاً لسلامتك'
                    : (strings.isFrench
                        ? 'Session mise en pause par sécurité'
                        : 'Session paused for safety'))
                : (strings.isArabic
                    ? 'إرسال الرسالة'
                    : (strings.isFrench
                        ? 'Envoyer le message'
                        : 'Send message')),
            enabled: !isPaused && !isReplying,
            borderRadius: BorderRadius.circular(24),
            onPressed: isPaused || isReplying ? null : () => _sendMessage(),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isPaused || isReplying ? tokens.line : tokens.ink,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                isPaused ? Icons.lock_outline_rounded : Icons.arrow_upward_rounded,
                size: 20,
                color: isPaused || isReplying ? tokens.ink2 : tokens.bg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalmTypingIndicator extends StatefulWidget {
  const _CalmTypingIndicator({required this.tokens, required this.label});

  final MindTokens tokens;
  final String label;

  @override
  State<_CalmTypingIndicator> createState() => _CalmTypingIndicatorState();
}

class _CalmTypingIndicatorState extends State<_CalmTypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final pulse = reduceMotion
                  ? 0.75
                  : (0.4 + (_controller.value * 0.6));
              return Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.tokens.ink.withValues(alpha: pulse),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: widget.tokens.ink2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
