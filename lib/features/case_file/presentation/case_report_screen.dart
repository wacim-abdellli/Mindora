import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/router/app_router.dart';
import '../../../app/theme/mind_tokens.dart';
import '../../../core/safety/crisis_keywords.dart';
import '../../../core/safety/safety_interceptor.dart';
import '../../../core/safety/support_button.dart';
import '../../../core/widgets/label_badge.dart';
import '../../investigation/controllers/investigation_providers.dart';
import '../../investigation/domain/case_model.dart';
import '../../investigation/domain/statement.dart';
import '../domain/clarity_anchor_model.dart';
import 'clinical_export_preview_sheet.dart';
import 'widgets/clarity_anchor_card.dart';

/// The official Case File in Report View: Vercel Luxury Dark & Minimalist Precision.
///
/// Trilingual support (authentic Tunisian Arabic, French, English) with full RTL awareness.
class CaseReportScreen extends ConsumerStatefulWidget {
  const CaseReportScreen({super.key, required this.caseId});

  final String caseId;

  @override
  ConsumerState<CaseReportScreen> createState() => _CaseReportScreenState();
}

class _CaseReportScreenState extends ConsumerState<CaseReportScreen> {
  CaseModel? _case;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCase();
  }

  Future<void> _loadCase() async {
    final repo = ref.read(caseRepositoryProvider);
    final found = await repo.getCaseById(widget.caseId);
    if (mounted) {
      setState(() {
        _case = found;
        _isLoading = false;
      });
    }
  }

  void _editConclusionDialog(bool isDark, AppStrings strings) {
    if (_case == null) return;
    final controller = TextEditingController(text: _case!.userConclusion ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.tokens.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ctx.tokens.cardRadius),
          side: BorderSide(color: ctx.tokens.line, width: 1),
        ),
        title: Text(
          strings.editVerdictTitle,
          style: TextStyle(
            color: ctx.tokens.ink,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        content: TextField(
          controller: controller,
          maxLines: 4,
          style: TextStyle(color: ctx.tokens.ink, fontSize: 13),
          decoration: InputDecoration(
            hintText: strings.yourUpdatedTakeaway,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(strings.cancelBtn, style: TextStyle(color: ctx.tokens.ink2)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: ctx.tokens.ink,
              foregroundColor: ctx.tokens.bg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ctx.tokens.buttonRadius),
              ),
            ),
            onPressed: () async {
              HapticFeedback.lightImpact();
              final newConclusion = controller.text.trim();

              // Layer 1 crisis pre-scan: Intercept Level 2 phrases immediately
              if (CrisisKeywords.evaluateText(newConclusion) == 2) {
                if (ctx.mounted) Navigator.of(ctx).pop();
                SafetyInterceptor.showCrisisPauseDialog(context);
                return;
              }

              final updated = _case!.copyWith(
                userConclusion: newConclusion,
                updatedAt: DateTime.now(),
              );
              await ref.read(caseRepositoryProvider).saveCase(updated);
              setState(() => _case = updated);
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: Text(strings.saveVerdictBtn, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.5)),
          ),
        ],
      ),
    );
  }

  Future<void> _togglePrivacy(CaseModel c) async {
    HapticFeedback.lightImpact();
    await ref.read(caseRepositoryProvider).toggleCasePrivacy(c.id);
    await _loadCase();
  }

  void _openSessionBriefExport(CaseModel c, AppStrings strings) {
    if (c.isPrivate) {
      HapticFeedback.heavyImpact();
      showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            backgroundColor: ctx.tokens.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ctx.tokens.cardRadius),
              side: BorderSide(color: ctx.tokens.line, width: 1),
            ),
            title: Row(
              children: [
                Icon(Icons.lock_rounded, size: 18, color: ctx.tokens.safety),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    strings.privacyShieldTitle,
                    style: TextStyle(
                      color: ctx.tokens.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              strings.caseIsPrivateCannotExport,
              style: TextStyle(fontSize: 12.5, color: ctx.tokens.ink2, height: 1.4),
            ),
            actions: [
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: ctx.tokens.ink,
                  foregroundColor: ctx.tokens.bg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ctx.tokens.buttonRadius),
                  ),
                ),
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(strings.closeBtn, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
              ),
            ],
          );
        },
      );
      return;
    }

    ClinicalExportPreviewSheet.show(context, [c]);
  }

  void _deleteCase(bool isDark, AppStrings strings) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.tokens.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ctx.tokens.cardRadius),
          side: BorderSide(color: ctx.tokens.line, width: 1),
        ),
        title: Text(
          strings.deleteCaseFileTitle,
          style: TextStyle(
            color: ctx.tokens.ink,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        content: Text(
          strings.deleteCaseWarning,
          style: TextStyle(fontSize: 12.5, color: ctx.tokens.ink2, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(strings.cancelBtn, style: TextStyle(color: ctx.tokens.ink2)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: ctx.tokens.safety,
              foregroundColor: ctx.tokens.bg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ctx.tokens.buttonRadius),
              ),
            ),
            onPressed: () async {
              HapticFeedback.heavyImpact();
              await ref.read(caseRepositoryProvider).deleteCase(widget.caseId);
              ref.invalidate(savedCasesProvider);
              final currentActive = ref.read(activeCaseControllerProvider).value;
              if (currentActive?.id == widget.caseId) {
                ref.invalidate(activeCaseControllerProvider);
              }
              if (ctx.mounted) {
                Navigator.of(ctx).pop();
              }
              if (mounted) {
                final router = GoRouter.maybeOf(context);
                if (router != null && router.canPop()) {
                  router.pop();
                } else {
                  context.go(AppRouter.home);
                }
              }
            },
            child: Text(
              strings.deletePermanentlyBtn,
              style: TextStyle(
                color: ctx.tokens.bg,
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final strings = ref.watch(appStringsProvider);
    final tokens = context.tokens;

    final bg = tokens.bg;
    final surfaceColor = tokens.surface;
    final borderColor = tokens.line;
    final textPrimary = tokens.ink;
    final textSecondary = tokens.ink2;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: bg,
        body: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_case == null) {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(title: Text(strings.caseReportTitle)),
        body: Center(child: Text(strings.caseNotFound)),
      );
    }

    final c = _case!;
    final chain = c.chain;
    final clarityAnchor = ClarityAnchorModel.fromCase(c);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          strings.formatSessionNumber(c.caseNumber),
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: 0.5, color: textPrimary),
        ),
        actions: [
          const SupportButton(),
          IconButton(
            icon: Icon(
              c.isPrivate ? Icons.lock_rounded : Icons.lock_open_outlined,
              size: 18,
              color: c.isPrivate ? tokens.safety : textSecondary,
            ),
            tooltip: strings.togglePrivacyTooltip,
            onPressed: () => _togglePrivacy(c),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 18),
            tooltip: strings.exportSessionBriefTitle,
            onPressed: () => _openSessionBriefExport(c, strings),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            tooltip: strings.deleteCase,
            onPressed: () => _deleteCase(isDark, strings),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Case Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(context.tokens.cardRadius),
                  border: Border.all(color: borderColor, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: tokens.surface2,
                            borderRadius: BorderRadius.circular(tokens.chipRadius),
                          ),
                          child: Text(
                            strings.formatSessionNumber(c.caseNumber),
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: strings.isArabic ? 0 : 0.5,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => _togglePrivacy(c),
                          borderRadius: BorderRadius.circular(tokens.chipRadius),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              minWidth: 48,
                              minHeight: 48,
                            ),
                            child: Center(
                              widthFactor: 1.0,
                              heightFactor: 1.0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: c.isPrivate
                                      ? tokens.safetySoft
                                      : tokens.surface2,
                                  borderRadius: BorderRadius.circular(tokens.chipRadius),
                                  border: Border.all(
                                    color: c.isPrivate
                                        ? tokens.safety.withValues(alpha: 0.35)
                                        : borderColor,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      c.isPrivate ? Icons.lock_rounded : Icons.lock_open_outlined,
                                      size: 11,
                                      color: c.isPrivate
                                          ? context.tokens.safety
                                          : textSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        c.isPrivate ? strings.casePrivateBadge : strings.caseShareableBadge,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: c.isPrivate
                                              ? context.tokens.safety
                                              : textSecondary,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: strings.isArabic ? 0 : 0.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Text(
                          '${c.createdAt.day}/${c.createdAt.month}/${c.createdAt.year}',
                          style: TextStyle(
                            fontSize: 11,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      c.title,
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17, letterSpacing: -0.3, color: textPrimary),
                    ),
                    if (chain != null && chain.emotion.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: tokens.safetySoft,
                          borderRadius: BorderRadius.circular(tokens.chipRadius),
                          border: Border.all(
                            color: tokens.safety.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Text(
                          strings.emotionTag(chain.emotion, chain.emotionIntensity),
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                            color: tokens.safety,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 18),

              if (clarityAnchor != null) ...[
                ClarityAnchorCard(anchor: clarityAnchor, strings: strings),
                const SizedBox(height: 18),
              ],

              // Section 1: The Incident
              _reportSectionHeader(strings.incidentNarrativeHeader, textSecondary),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(tokens.cardRadius),
                  border: Border.all(color: borderColor, width: 1),
                ),
                child: Text(
                  c.incidentDescription.isNotEmpty ? c.incidentDescription : strings.noNarrativeRecorded,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Section 2: Forensic Chain & Evidence
              if (chain != null) ...[
                _reportSectionHeader(strings.observableChainHeader, textSecondary),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(tokens.cardRadius),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: Column(
                    children: [
                      _chainRow(strings.triggerTitle, chain.trigger, Icons.location_on_outlined, isDark, textPrimary, textSecondary),
                      Divider(height: 18, color: borderColor),
                      _chainRow(
                        strings.thoughtTitle,
                        chain.thought,
                        Icons.psychology_outlined,
                        isDark,
                        textPrimary,
                        textSecondary,
                        badge: LabelBadge(label: chain.thoughtLabel, compact: true),
                      ),
                      Divider(height: 18, color: borderColor),
                      _chainRow(strings.behaviorTitle, chain.behavior, Icons.directions_walk_outlined, isDark, textPrimary, textSecondary),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],

              // Section 3: Alternative Hypotheses
              if (c.hypotheses.isNotEmpty) ...[
                _reportSectionHeader(strings.hypothesesExaminedHeader, textSecondary),
                ...c.hypotheses.map(
                  (h) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(tokens.cardRadius),
                      border: Border.all(color: borderColor, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(h.title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: textPrimary)),
                        const SizedBox(height: 4),
                        Text(h.explanation, style: TextStyle(fontSize: 12, color: textSecondary, height: 1.35)),
                        const SizedBox(height: 8),
                        Text(
                          '• ${strings.whyItFitsPrefix} ${h.whyItMightFit}',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: MindTokens.moodAnxious,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '• ${strings.whatDoesNotFitPrefix} ${h.whatDoesNotFit}',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: MindTokens.moodRestless,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
              ],

              // Section 3b: Findings Summary (synthesized insights)
              if (c.findingsSummary != null && c.findingsSummary!.trim().isNotEmpty) ...[
                _reportSectionHeader(
                  strings.isArabic
                      ? 'خلاصة الملاحظات'
                      : (strings.isFrench ? 'SYNTHÈSE DES OBSERVATIONS' : 'KEY FINDINGS SUMMARY'),
                  textSecondary,
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(tokens.cardRadius),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: Text(
                    c.findingsSummary!.trim(),
                    style: TextStyle(color: textPrimary, fontSize: 13, height: 1.45),
                  ),
                ),
                const SizedBox(height: 18),
              ],

              // Section 3c: Session Dialogue Excerpt (important when chain/hypotheses are empty)
              if (c.statements.isNotEmpty) ...[
                _reportSectionHeader(
                  strings.isArabic
                      ? 'مقتطفات الحوار التأملي'
                      : (strings.isFrench ? 'EXTRAITS DU DIALOGUE' : 'SESSION DIALOGUE'),
                  textSecondary,
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(tokens.cardRadius),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: c.statements.take(12).map((st) {
                      final isUser = st.speaker == StatementSpeaker.user;
                      final speakerLabel = isUser
                          ? (strings.isArabic ? 'أنت' : (strings.isFrench ? 'VOUS' : 'YOU'))
                          : (strings.isArabic
                              ? 'الرفيق'
                              : (strings.isFrench ? 'COMPAGNON' : 'COMPANION'));
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  speakerLabel,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                    color: isUser ? tokens.m1 : tokens.ink,
                                  ),
                                ),
                                if (st.label != null) ...[
                                  const SizedBox(width: 8),
                                  LabelBadge(label: st.label!, compact: true),
                                ],
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              st.text,
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 12.5,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 18),
              ],

              // Section 4: My Conclusion
              _reportSectionHeader(strings.groundedVerdictHeader, textSecondary),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: tokens.selectedTint,
                  borderRadius: BorderRadius.circular(tokens.cardRadius),
                  border: Border.all(
                    color: tokens.m1.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.anchor_rounded, size: 14, color: tokens.m1),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  strings.finalTakeawayUserHeader,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: strings.isArabic ? 0 : 0.6,
                                    color: tokens.m1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () => _editConclusionDialog(isDark, strings),
                          borderRadius: BorderRadius.circular(tokens.chipRadius),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              minWidth: 48,
                              minHeight: 48,
                            ),
                            child: Center(
                              widthFactor: 1.0,
                              heightFactor: 1.0,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  strings.editBtn,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                    color: tokens.m1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      c.userConclusion?.isNotEmpty == true ? c.userConclusion! : strings.noConclusionYet,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13.5,
                        height: 1.45,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: context.tokens.ink,
                    foregroundColor: context.tokens.bg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(context.tokens.buttonRadius),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    final router = GoRouter.maybeOf(context);
                    if (router != null && router.canPop()) {
                      router.pop();
                    } else {
                      context.go(AppRouter.home);
                    }
                  },
                  child: Text(
                    strings.navHome.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.5),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reportSectionHeader(String title, Color textSecondary) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 8, start: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: textSecondary,
        ),
      ),
    );
  }

  Widget _chainRow(
    String label,
    String content,
    IconData icon,
    bool isDark,
    Color textPrimary,
    Color textSecondary, {
    Widget? badge,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: textSecondary),
        const SizedBox(width: 10),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            content.isNotEmpty ? content : '—',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: textPrimary,
            ),
          ),
        ),
        if (badge != null) ...[
          const SizedBox(width: 8),
          badge,
        ],
      ],
    );
  }
}
