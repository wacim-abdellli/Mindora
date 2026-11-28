import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/theme/mind_tokens.dart';
import '../../../journey/controllers/journey_controller.dart';

class CustomPerspectiveSheet extends ConsumerStatefulWidget {
  const CustomPerspectiveSheet({super.key});

  static Future<void> show(BuildContext context) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CustomPerspectiveSheet(),
    );
  }

  @override
  ConsumerState<CustomPerspectiveSheet> createState() => _CustomPerspectiveSheetState();
}

class _CustomPerspectiveSheetState extends ConsumerState<CustomPerspectiveSheet> {
  int _step = 0; // 0: Fact, 1: Interpretation, 2: Grounded Alternatives
  String? _selectedFact;
  String? _selectedAssumption;
  String? _selectedAlternative;

  final List<({String en, String fr, String ar})> _commonFacts = const [
    (en: 'Unanswered message or silence', fr: 'Message sans réponse ou silence temporaire', ar: 'رسالة لم يُرد عليها أو صمت مؤقت'),
    (en: 'Critical feedback received on task', fr: 'Retours critiques reçus sur un travail', ar: 'ملاحظات أو تعديلات على عمل'),
    (en: 'Sudden cancellation of plans', fr: 'Annulation soudaine d’un projet ou rendez-vous', ar: 'إلغاء موعد أو لقاء فجأة'),
    (en: 'Woke up with heavy somatic fatigue', fr: 'Réveil avec une forte fatigue physique', ar: 'استيقاظ بإرهاق وثقل بدني'),
    (en: 'Mistake made during a meeting', fr: 'Erreur commise lors d’une réunion', ar: 'هفوة أو تردد أثناء اجتماع'),
  ];

  final List<({String en, String fr, String ar})> _commonAssumptions = const [
    (en: 'They are annoyed and rejecting me', fr: 'Ils sont contrariés et me rejettent', ar: 'إنهم متضايقون مني ويتجاهلونني'),
    (en: 'My work is substandard and I will fail', fr: 'Mon travail est mauvais et je vais échouer', ar: 'عملي فاشل ولن أستطيع النجاح'),
    (en: 'The entire day will be completely lost', fr: 'Toute ma journée est perdue d’avance', ar: 'النهار بأكمله ضاع ولن أنجز شيئاً'),
    (en: 'I am always falling behind everyone else', fr: 'Je suis toujours en retard sur les autres', ar: 'أنا متأخر دائماً عن الآخرين'),
    (en: 'People are quietly judging my presence', fr: 'Les autres me jugent silencieusement', ar: 'الجميع يراقبونني ويحكمون عليّ سلبياً'),
  ];

  final List<({String en, String fr, String ar})> _groundedAlternatives = const [
    (
      en: 'Their delay reflects their own busy day, not a verdict on me.',
      fr: 'Leur délai reflète leur propre journée chargée, pas un jugement sur moi.',
      ar: 'تأخرهم يعكس انشغالهم بظروفهم الخاصة، وليس تقييماً لي.',
    ),
    (
      en: 'Feedback is normal iteration; it proves the work is valued and refinable.',
      fr: 'Les retours font partie du processus normal et prouvent que le travail compte.',
      ar: 'الملاحظات جزء طبيعي من التطوير وتؤكد أن العمل يستحق التحسين.',
    ),
    (
      en: 'Morning stamina fluctuates; pacing gently preserves energy for later.',
      fr: 'L’énergie varie naturellement ; ralentir préserve mes ressources pour plus tard.',
      ar: 'الطاقة تتقلب طبيعياً؛ خفض النسق بهدوء يحفظ التوازن لبقية اليوم.',
    ),
    (
      en: 'One uncomfortable moment does not define my capability or value.',
      fr: 'Un moment délicat ne définit ni ma compétence ni ma valeur.',
      ar: 'موقف واحد مربك لا يلغي كفاءتي ولا يحدد قيمتي.',
    ),
    (
      en: 'I do not have to believe every automatic thought my mind generates.',
      fr: 'Je n’ai pas à croire chaque pensée automatique produite par mon esprit.',
      ar: 'لست مجبراً على تصديق كل فكرة تلقائية يقفز إليها ذهني.',
    ),
  ];

  Future<void> _saveAsDiscovery() async {
    final fact = _selectedFact ?? '';
    final assumption = _selectedAssumption ?? '';
    final alternative = _selectedAlternative ?? '';

    if (alternative.isEmpty) return;

    HapticFeedback.mediumImpact();
    await ref.read(journeyControllerProvider.notifier).addCustomDiscovery(
      title: alternative,
      notes: 'Fact: $fact\nInterpretation: $assumption\nGrounded Reframe: $alternative',
      category: 'Perspective Reframe',
    );

    if (mounted) {
      final tokens = context.tokens;
      Navigator.of(context).pop();
      final s = ref.read(appStringsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: tokens.surface,
          content: Text(
            s.isArabic
                ? 'تم حفظ زاوية النظر البديلة في سجل الاكتشافات'
                : (s.isFrench
                    ? 'Perspective alternative enregistrée dans vos découvertes'
                    : 'Alternative perspective saved to Personal Discoveries'),
            style: TextStyle(fontSize: 12, color: tokens.ink),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final strings = ref.watch(appStringsProvider);
    final isAr = strings.isArabic;

    final surface = tokens.surface;
    final border = tokens.line;
    final textPrimary = tokens.ink;
    final textSecondary = tokens.ink2;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(tokens.sheetRadius)),
        border: Border(top: BorderSide(color: border, width: 1.5)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: tokens.lineStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header with Steps Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isAr
                      ? 'تفكيك زوايا النظر'
                      : (strings.isFrench
                          ? 'DÉCONSTRUCTION DE PERSPECTIVE'
                          : 'PERSPECTIVE DECONSTRUCTION'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: tokens.surface2,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: border),
                  ),
                  child: Text(
                    '${_step + 1} / 3',
                    style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w700, color: textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Step 0: Fact
            if (_step == 0) ...[
              Text(
                isAr
                    ? '1. ما هي الواقعة الملموسة؟'
                    : (strings.isFrench
                        ? '1. Quel est le fait observable ?'
                        : '1. What is the observable fact?'),
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                isAr
                    ? 'ما حدث بالعين المجردة بدون أي أحكام أو تأويلات ذهنية.'
                    : (strings.isFrench
                        ? 'L’événement brut tel qu’une caméra l’enregistrerait, sans hypothèse.'
                        : 'The plain event as a video camera would record it, free of assumptions.'),
                style: TextStyle(fontSize: 12, color: textSecondary),
              ),
              const SizedBox(height: 14),
              ..._commonFacts.map((f) {
                final label = isAr ? f.ar : (strings.isFrench ? f.fr : f.en);
                final isSelected = _selectedFact == label;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(tokens.rowRadius),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedFact = label;
                        _step = 1;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? tokens.selectedTintFor(tokens.m1) : tokens.surface2,
                        borderRadius: BorderRadius.circular(tokens.rowRadius),
                        border: Border.all(
                          color: isSelected ? tokens.m1 : border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.fact_check_outlined,
                            size: 16,
                            color: isSelected ? textPrimary : textSecondary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: textPrimary,
                              ),
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios_rounded, size: 12, color: textSecondary),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],

            // Step 1: Assumption
            if (_step == 1) ...[
              Text(
                isAr
                    ? '2. ما الذي افترضه ذهنك؟'
                    : (strings.isFrench
                        ? '2. Quel scénario votre esprit a-t-il supposé ?'
                        : '2. What story did your mind assume?'),
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                isAr
                    ? 'التفسير التلقائي الفوري أو السيناريو المخيف الذي قفز إلى تفكيرك.'
                    : (strings.isFrench
                        ? 'Le récit automatique ou l’interprétation immédiate qui a surgi.'
                        : 'The automatic narrative or alarmist storyline your mind attached.'),
                style: TextStyle(fontSize: 12, color: textSecondary),
              ),
              const SizedBox(height: 14),
              ..._commonAssumptions.map((a) {
                final label = isAr ? a.ar : (strings.isFrench ? a.fr : a.en);
                final isSelected = _selectedAssumption == label;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(tokens.rowRadius),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedAssumption = label;
                        _step = 2;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? tokens.selectedTintFor(tokens.m1) : tokens.surface2,
                        borderRadius: BorderRadius.circular(tokens.rowRadius),
                        border: Border.all(
                          color: isSelected ? tokens.m1 : border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.psychology_outlined,
                            size: 16,
                            color: isSelected ? textPrimary : textSecondary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: textPrimary,
                              ),
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios_rounded, size: 12, color: textSecondary),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],

            // Step 2: Grounded Alternative
            if (_step == 2) ...[
              Text(
                isAr
                    ? '3. زاوية نظر واقعية بديلة'
                    : (strings.isFrench
                        ? '3. Explication alternative ancrée'
                        : '3. Grounded alternative explanation'),
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                isAr
                    ? 'اختر التفسير الأكثر هدوءاً وواقعية، واحفظه في اكتشافاتك.'
                    : (strings.isFrench
                        ? 'Choisissez une perspective réaliste et apaisante à enregistrer.'
                        : 'Select a grounded perspective to restore balance and anchor your ease.'),
                style: TextStyle(fontSize: 12, color: textSecondary),
              ),
              const SizedBox(height: 14),
              ..._groundedAlternatives.map((alt) {
                final label = isAr ? alt.ar : (strings.isFrench ? alt.fr : alt.en);
                final isSelected = _selectedAlternative == label;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(tokens.rowRadius),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedAlternative = label);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? tokens.selectedTintFor(tokens.m1) : tokens.surface2,
                        borderRadius: BorderRadius.circular(tokens.rowRadius),
                        border: Border.all(
                          color: isSelected ? tokens.m1 : border,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                            size: 16,
                            color: isSelected ? tokens.m1 : textSecondary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
              if (_selectedAlternative != null)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.bookmark_add_outlined, size: 16),
                    label: Text(
                      isAr
                          ? 'حفظ في الاكتشافات الشخصية'
                          : (strings.isFrench
                              ? 'Enregistrer la découverte'
                              : 'Save as Personal Discovery'),
                    ),
                    onPressed: _saveAsDiscovery,
                    style: FilledButton.styleFrom(
                      backgroundColor: tokens.ink,
                      foregroundColor: tokens.bg,
                      minimumSize: const Size.fromHeight(48),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(tokens.buttonRadius)),
                    ),
                  ),
                ),
            ],

            const SizedBox(height: 12),
            if (_step > 0)
              Center(
                child: TextButton(
                  onPressed: () => setState(() => _step--),
                  child: Text(
                    isAr
                        ? 'الرجوع للخطوة السابقة'
                        : (strings.isFrench
                            ? 'Étape précédente'
                            : 'Back to previous step'),
                    style: TextStyle(fontSize: 12.5, color: textSecondary),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

