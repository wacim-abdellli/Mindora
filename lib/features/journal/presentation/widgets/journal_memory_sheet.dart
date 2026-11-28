import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/localization/app_strings.dart';
import '../../../../app/theme/mind_tokens.dart';
import '../../../../core/widgets/bouncing_widget.dart';
import '../../controllers/journal_memory_controller.dart';
import '../../domain/journal_memory_model.dart';

/// Bottom sheet displaying compressed journal memories with full user transparency and control.
///
/// Section 8 & Step 3.2:
/// - Shows what information has been retained from self-observation entries.
/// - Shows source observation count and time window.
/// - Allows the user to confirm, dismiss (reject), or delete any memory item.
/// - Strictly 0 emojis in UI (Vercel Luxury Dark aesthetic).
class JournalMemorySheet extends ConsumerWidget {
  const JournalMemorySheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const JournalMemorySheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final strings = ref.watch(appStringsProvider);

    final bg = tokens.surface;
    final surface = tokens.surface;
    final border = tokens.line;
    final textPrimary = tokens.ink;
    final textSecondary = tokens.ink2;
    final accent = tokens.m1;

    final memoriesAsync = ref.watch(journalMemoryControllerProvider);
    final memories = memoriesAsync.value ?? [];

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border.all(color: border, width: 1),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 4, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.memoryVaultTitle,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      strings.isArabic
                          ? 'سياق ملخص ومحفوظ محلياً فقط على جهازك'
                          : (strings.isFrench
                              ? 'Contexte condensé généré localement sur votre appareil'
                              : 'Compact context synthesized locally on-device'),
                      style: TextStyle(
                        fontSize: 12.5,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  tooltip: strings.closeBtn,
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: textSecondary,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Informational Banner
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: tokens.surface2,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: border, width: 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined, size: 16, color: accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    strings.isArabic
                        ? 'تساعد هذه الملخصات المساعد الذكي على فهم مسارك دون قراءة نصوصك الحرة كاملة. يمكنك تأكيد أو رفض أي ملخص.'
                        : (strings.isFrench
                            ? 'Ces résumés aident le compagnon IA à suivre votre parcours sans envoyer vos textes complets. Vous gardez le contrôle pour confirmer ou ignorer chaque élément.'
                            : 'These summaries help the AI Companion understand your trajectory without transmitting raw journal texts. You have full sovereignty to affirm or dismiss any item.'),
                    style: TextStyle(fontSize: 12.5, height: 1.4, color: textSecondary),
                  ),
                ),
              ],
            ),
          ),

          // Memory Items List
          Expanded(
            child: memories.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome_outlined, size: 36, color: textSecondary),
                          const SizedBox(height: 12),
                          Text(
                            strings.isArabic
                                ? 'لا توجد ذاكرة مضغوطة بعد'
                                : (strings.isFrench
                                    ? 'Aucun résumé en mémoire pour le moment'
                                    : 'No compressed memories yet'),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            strings.isArabic
                                ? 'سيتم استخلاص الأنماط المتكررة بعد تسجيل أكثر من أثر يومي.'
                                : (strings.isFrench
                                    ? 'Les thèmes récurrents seront synthétisés au fil de vos bilans quotidiens.'
                                    : 'Recurring themes and context will be synthesized as you log daily check-ins.'),
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12.5, color: textSecondary),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: memories.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = memories[index];
                      return _buildMemoryCard(
                        context: context,
                        ref: ref,
                        item: item,
                        surface: surface,
                        border: border,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        accent: accent,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryCard({
    required BuildContext context,
    required WidgetRef ref,
    required JournalMemoryModel item,
    required Color surface,
    required Color border,
    required Color textPrimary,
    required Color textSecondary,
    required Color accent,
  }) {
    final strings = ref.watch(appStringsProvider);
    final tokens = context.tokens;
    final statusColor = item.isConfirmed
        ? tokens.m1
        : (item.isRejected ? tokens.safety : textSecondary);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: item.isRejected ? border.withValues(alpha: 0.4) : border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: tokens.surface2,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.category.localized(strings),
                  style: TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.confirmationStatus.localized(strings),
                  style: TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.summary,
            style: TextStyle(
              fontSize: 13.0,
              height: 1.4,
              fontWeight: FontWeight.w600,
              color: item.isRejected ? textSecondary : textPrimary,
              decoration: item.isRejected ? TextDecoration.lineThrough : null,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.history_toggle_off_rounded, size: 14, color: textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  strings.memoryObservationsSummary(
                    item.observationCount,
                    item.sourceEntryIds.length,
                  ),
                  style: TextStyle(fontSize: 12.0, color: textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Actions
              if (!item.isConfirmed)
                BouncingWidget(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ref.read(journalMemoryControllerProvider.notifier).confirmMemory(item.id);
                  },
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Text(
                          strings.confirmAction,
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: accent),
                        ),
                      ),
                    ),
                  ),
                ),
              if (!item.isRejected)
                BouncingWidget(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ref.read(journalMemoryControllerProvider.notifier).rejectMemory(item.id);
                  },
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Text(
                          strings.dismissAction,
                          style: TextStyle(fontSize: 12.5, color: textSecondary),
                        ),
                      ),
                    ),
                  ),
                ),
              IconButton(
                tooltip: strings.deleteEntryBtn,
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                color: textSecondary,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  ref.read(journalMemoryControllerProvider.notifier).deleteMemory(item.id);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
