import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/theme/mind_tokens.dart';
import '../../../../core/widgets/mind_toast.dart';
import '../../../insights/data/pattern_awareness_service.dart';
import '../../../profile/controllers/profile_controller.dart';
import '../../../support/presentation/contextual_support_sheet.dart';
import '../../controllers/observatory_controllers.dart';
import '../../domain/symptom_entry.dart';
import '../../domain/symptom_report.dart';

class SymptomAssessmentSheet extends ConsumerStatefulWidget {
  const SymptomAssessmentSheet({
    super.key,
    required this.selectedSymptoms,
  });

  final List<SymptomEntry> selectedSymptoms;

  static Future<void> show(
    BuildContext context, {
    required List<SymptomEntry> selectedSymptoms,
  }) {
    if (selectedSymptoms.isEmpty) return Future.value();
    HapticFeedback.lightImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SymptomAssessmentSheet(selectedSymptoms: selectedSymptoms),
    );
  }

  @override
  ConsumerState<SymptomAssessmentSheet> createState() =>
      _SymptomAssessmentSheetState();
}

class _SymptomAssessmentSheetState extends ConsumerState<SymptomAssessmentSheet> {
  int _step = 0; // 0: Intensity & Context, 1: Adaptive Follow-up, 2: Immediate Analysis
  double _intensity = 6.0;
  String? _selectedSomatic;
  String? _selectedContext;
  String? _userAdaptiveAnswer;
  final _customAnswerController = TextEditingController();

  bool _isAnalyzing = false;
  String? _aiAnalysis;
  String? _stabilizingStrategy;

  @override
  void dispose() {
    _customAnswerController.dispose();
    super.dispose();
  }

  Future<void> _runAnalysis() async {
    setState(() => _isAnalyzing = true);
    final strings = ref.read(appStringsProvider);
    final profile = ref.read(profileControllerProvider).value;
    final baseline = ref.read(personalBaselineProvider);
    final aiService = ref.read(observatoryAiServiceProvider);

    final result = await aiService.analyzeSymptoms(
      selectedSymptoms: widget.selectedSymptoms,
      intensity: _intensity.round(),
      contextTrigger: _selectedContext,
      somaticLocation: _selectedSomatic,
      userAdaptiveAnswer: _userAdaptiveAnswer ?? _customAnswerController.text.trim(),
      baseline: baseline,
      profile: profile,
      languageCode: strings.languageCode,
    );

    if (mounted) {
      setState(() {
        _isAnalyzing = false;
        _aiAnalysis = result.analysis;
        _stabilizingStrategy = result.stabilizingStrategy;
        _step = 2;
      });
      HapticFeedback.mediumImpact();
    }
  }

  Future<void> _saveReportAndClose() async {
    HapticFeedback.mediumImpact();
    final now = DateTime.now();
    final report = SymptomReport(
      id: 'rep_${now.millisecondsSinceEpoch}',
      symptomIds: widget.selectedSymptoms.map((s) => s.id).toList(),
      intensity: _intensity.round(),
      somaticLocation: _selectedSomatic,
      contextTrigger: _selectedContext,
      adaptiveAiQuestion: ref.read(observatoryAiServiceProvider).generateAdaptiveFollowUpQuestion(
            selectedSymptoms: widget.selectedSymptoms,
            profile: ref.read(profileControllerProvider).value,
            languageCode: ref.read(appStringsProvider).languageCode,
          ),
      userAdaptiveAnswer: _userAdaptiveAnswer ?? _customAnswerController.text.trim(),
      aiAnalysis: _aiAnalysis,
      stabilizingStrategy: _stabilizingStrategy,
      createdAt: now,
    );

    await ref.read(symptomReportsControllerProvider.notifier).recordReport(report);
    ref.read(selectedSymptomIdsProvider.notifier).clear();

    if (mounted) {
      final strings = ref.read(appStringsProvider);
      Navigator.of(context).pop();
      showMindToast(context, strings.symptomLoggedToast);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final strings = ref.watch(appStringsProvider);
    final isAr = strings.isArabic;

    final bg = tokens.surface;
    final surfaceColor = tokens.surface2;
    final borderColor = tokens.line;
    final textPrimary = tokens.ink;
    final textSecondary = tokens.ink2;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(tokens.sheetRadius)),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                decoration: BoxDecoration(
                  color: tokens.lineStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.assessment_outlined, size: 16, color: tokens.m1),
                      const SizedBox(width: 8),
                      Text(
                        isAr
                            ? 'تقييم تجارب الأعراض (${widget.selectedSymptoms.length})'
                            : (strings.isFrench
                                ? 'Évaluation des ressentis (${widget.selectedSymptoms.length})'
                                : 'Symptom assessment (${widget.selectedSymptoms.length})'),
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    tooltip: strings.closeBtn,
                    icon: Icon(Icons.close_rounded, size: 18, color: textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: _buildCurrentStep(
                  strings,
                  tokens,
                  textPrimary,
                  textSecondary,
                  surfaceColor,
                  borderColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep(
    AppStrings strings,
    MindTokens tokens,
    Color textPrimary,
    Color textSecondary,
    Color surfaceColor,
    Color borderColor,
  ) {
    if (_isAnalyzing) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            CircularProgressIndicator(strokeWidth: 2, color: tokens.m1),
            const SizedBox(height: 16),
            Text(
              strings.isArabic
                  ? 'جاري استخلاص النمط التأملي...'
                  : (strings.isFrench
                      ? 'Formulation de la synthèse réflexive...'
                      : 'Formulating reflective synthesis...'),
              style: TextStyle(fontSize: 13, color: textSecondary, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    if (_step == 0) {
      return _buildIntensityAndContextStep(
        strings,
        tokens,
        textPrimary,
        textSecondary,
        surfaceColor,
        borderColor,
      );
    } else if (_step == 1) {
      return _buildAdaptiveFollowUpStep(
        strings,
        tokens,
        textPrimary,
        textSecondary,
        surfaceColor,
        borderColor,
      );
    } else {
      return _buildAnalysisResultStep(
        strings,
        tokens,
        textPrimary,
        textSecondary,
        surfaceColor,
        borderColor,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Step 0: Intensity & Context
  // ---------------------------------------------------------------------------
  Widget _buildIntensityAndContextStep(
    AppStrings strings,
    MindTokens tokens,
    Color textPrimary,
    Color textSecondary,
    Color surfaceColor,
    Color borderColor,
  ) {
    final isAr = strings.isArabic;
    final symptomChips = widget.selectedSymptoms.map((s) => s.title(strings)).join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          symptomChips,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textPrimary),
        ),
        const SizedBox(height: 16),

        // Intensity Slider
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isAr
                  ? 'شدة التجربة الحالية:'
                  : (strings.isFrench
                      ? 'Intensité actuelle :'
                      : 'Current Intensity:'),
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: textSecondary),
            ),
            Text(
              '${_intensity.round()}/10',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textPrimary),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: tokens.m1,
            inactiveTrackColor: tokens.line,
            thumbColor: tokens.ink,
            overlayColor: tokens.m1.withValues(alpha: 0.15),
          ),
          child: Slider(
            value: _intensity,
            min: 1,
            max: 10,
            divisions: 9,
            onChanged: (val) => setState(() => _intensity = val),
          ),
        ),
        const SizedBox(height: 16),

        // Somatic manifestation
        Text(
          isAr
              ? 'هل يتركز هذا الإحساس في موضع جسدي معين؟'
              : (strings.isFrench
                  ? 'Une manifestation corporelle particulière ?'
                  : 'Any prominent somatic manifestation?'),
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: textSecondary),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            (
              id: 'chest',
              label: isAr
                  ? 'ضيق في الصدر/التنفس'
                  : (strings.isFrench
                      ? 'Oppression thoracique / souffle court'
                      : 'Chest / Breath tightness')
            ),
            (
              id: 'jaw_neck',
              label: isAr
                  ? 'شد في الفك/الرقبة'
                  : (strings.isFrench
                      ? 'Raideur mâchoire / nuque'
                      : 'Jaw / Neck stiffness')
            ),
            (
              id: 'stomach',
              label: isAr
                  ? 'انقباض في المعدة'
                  : (strings.isFrench ? 'Nœud à l’estomac' : 'Stomach knots')
            ),
            (
              id: 'fatigue',
              label: isAr
                  ? 'ثقل وإرهاق عام'
                  : (strings.isFrench ? 'Lourdeur diffuse' : 'Diffuse heaviness')
            ),
            (
              id: 'none',
              label: isAr
                  ? 'لا يوجد تركيز جسدي بارز'
                  : (strings.isFrench
                      ? 'Aucun point corporel notable'
                      : 'No notable somatic focus')
            ),
          ].map((item) {
            final isSelected = _selectedSomatic == item.id;
            return ChoiceChip(
              label: Text(item.label),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedSomatic = item.id),
              labelStyle: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? textPrimary : textSecondary,
              ),
              backgroundColor: surfaceColor,
              selectedColor: tokens.selectedTintFor(tokens.m1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(tokens.chipRadius),
                side: BorderSide(color: isSelected ? tokens.m1 : borderColor),
              ),
              showCheckmark: false,
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Context trigger
        Text(
          isAr
              ? 'السياق المحفز أو المصاحب:'
              : (strings.isFrench
                  ? 'Contexte ou déclencheur associé :'
                  : 'Contextual catalyst or environment:'),
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: textSecondary),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            (
              id: 'work_study',
              label: isAr
                  ? 'ضغط عمل / دراسة'
                  : (strings.isFrench
                      ? 'Pression travail / études'
                      : 'Work / Academic pressure')
            ),
            (
              id: 'interpersonal',
              label: isAr
                  ? 'موقف أو حوار مع شخص'
                  : (strings.isFrench
                      ? 'Interaction interpersonnelle'
                      : 'Interpersonal interaction')
            ),
            (
              id: 'sleep_deficit',
              label: isAr
                  ? 'قلة نوم أو إرهاق'
                  : (strings.isFrench ? 'Manque de sommeil' : 'Sleep deficit')
            ),
            (
              id: 'solitude',
              label: isAr
                  ? 'وحدة وهدوء مفاجئ'
                  : (strings.isFrench ? 'Solitude / Calme' : 'Solitude / Quiet space')
            ),
            (
              id: 'unclear',
              label: isAr
                  ? 'تسلل تدريجي بدون سبب'
                  : (strings.isFrench
                      ? 'Apparu progressivement / Flou'
                      : 'Emerged gradually / Unclear')
            ),
          ].map((item) {
            final isSelected = _selectedContext == item.id;
            return ChoiceChip(
              label: Text(item.label),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedContext = item.id),
              labelStyle: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? textPrimary : textSecondary,
              ),
              backgroundColor: surfaceColor,
              selectedColor: tokens.selectedTintFor(tokens.m1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(tokens.chipRadius),
                side: BorderSide(color: isSelected ? tokens.m1 : borderColor),
              ),
              showCheckmark: false,
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton(
            onPressed: () => setState(() => _step = 1),
            style: FilledButton.styleFrom(
              backgroundColor: tokens.ink,
              foregroundColor: tokens.bg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(tokens.buttonRadius)),
            ),
            child: Text(
              isAr
                  ? 'متابعة الاستكشاف'
                  : (strings.isFrench
                      ? 'Poursuivre l’exploration'
                      : 'Continue Exploration'),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Step 1: Adaptive Socratic Inquiry
  // ---------------------------------------------------------------------------
  Widget _buildAdaptiveFollowUpStep(
    AppStrings strings,
    MindTokens tokens,
    Color textPrimary,
    Color textSecondary,
    Color surfaceColor,
    Color borderColor,
  ) {
    final isAr = strings.isArabic;
    final profile = ref.read(profileControllerProvider).value;
    final aiQuestion = ref.read(observatoryAiServiceProvider).generateAdaptiveFollowUpQuestion(
          selectedSymptoms: widget.selectedSymptoms,
          profile: profile,
          languageCode: strings.languageCode,
        );

    final suggestedOptions = isAr
        ? [
            'صحيح، نحس بتسارع وبطء في نفس الوقت',
            'أكثر تركيز على المستقبل وتوقع المشاكل',
            'إرهاق جسدي فقط، الأفكار هادية',
            'واحل في التفاصيل ومش قادر نبدى',
          ]
        : [
            'Yes, feels both physically slow and mentally hurried',
            'Mostly focused on anticipating future hurdles',
            'Purely physical fatigue; thoughts are quiet',
            'Overwhelmed by small details, unable to initiate',
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(tokens.rowRadius),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.psychology_outlined, size: 20, color: tokens.m1),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  aiQuestion,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Text(
          isAr
              ? 'خيارات سريعة (Options-First):'
              : (strings.isFrench
                  ? 'Réponses suggérées :'
                  : 'Suggested responses (Options-First):'),
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: textSecondary),
        ),
        const SizedBox(height: 8),
        ...suggestedOptions.map((opt) {
          final isSelected = _userAdaptiveAnswer == opt;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(tokens.rowRadius),
              onTap: () => setState(() => _userAdaptiveAnswer = opt),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? tokens.selectedTintFor(tokens.m1)
                      : surfaceColor,
                  borderRadius: BorderRadius.circular(tokens.rowRadius),
                  border: Border.all(
                    color: isSelected ? tokens.m1 : borderColor,
                  ),
                ),
                child: Text(
                  opt,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: textPrimary,
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 12),

        // Optional custom addition
        TextField(
          controller: _customAnswerController,
          style: TextStyle(color: textPrimary, fontSize: 12.5),
          decoration: InputDecoration(
            hintText: isAr
                ? 'أو عبّر بكلماتك باختصار (اختياري)...'
                : (strings.isFrench
                    ? 'Ou ajoutez une courte note (optionnel)...'
                    : 'Or add a brief note (optional)...'),
            hintStyle: TextStyle(color: tokens.ink3, fontSize: 12.5),
            filled: true,
            fillColor: tokens.surface2,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(tokens.inputRadius),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(tokens.inputRadius),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(tokens.inputRadius),
              borderSide: BorderSide(color: tokens.focusRing, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _step = 0),
                style: OutlinedButton.styleFrom(
                  foregroundColor: textSecondary,
                  side: BorderSide(color: borderColor),
                  minimumSize: const Size(48, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(tokens.buttonRadius)),
                ),
                child: Text(isAr ? 'رجوع' : (strings.isFrench ? 'Retour' : 'Back')),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: _runAnalysis,
                style: FilledButton.styleFrom(
                  backgroundColor: tokens.ink,
                  foregroundColor: tokens.bg,
                  minimumSize: const Size(48, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(tokens.buttonRadius)),
                ),
                child: Text(
                  isAr
                      ? 'استخلاص التحليل الفوري'
                      : (strings.isFrench
                          ? 'Générer l’analyse immédiate'
                          : 'Generate Immediate Analysis'),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Step 2: Immediate AI Analysis Result
  // ---------------------------------------------------------------------------
  Widget _buildAnalysisResultStep(
    AppStrings strings,
    MindTokens tokens,
    Color textPrimary,
    Color textSecondary,
    Color surfaceColor,
    Color borderColor,
  ) {
    final isAr = strings.isArabic;
    final baseline = ref.watch(personalBaselineProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Immediate Analysis Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(tokens.cardRadius),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.insights_outlined, size: 16, color: tokens.m1),
                  const SizedBox(width: 8),
                  Text(
                    isAr
                        ? 'التحليل التأملي الفوري'
                        : (strings.isFrench
                            ? 'Synthèse réflexive immédiate'
                            : 'Immediate reflective synthesis'),
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _aiAnalysis ?? '',
                style: TextStyle(fontSize: 12.5, color: textPrimary, height: 1.45),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Stabilizing Micro-Action Recommendation
        if (_stabilizingStrategy != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: tokens.cardTintFor(tokens.m1),
              borderRadius: BorderRadius.circular(tokens.cardRadius),
              border: Border.all(color: tokens.m1.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        isAr
                            ? 'استراتيجية التثبيت الموصى بها:'
                            : (strings.isFrench
                                ? 'Stratégie d’apaisement recommandée :'
                                : 'Recommended stabilizing strategy:'),
                        style: TextStyle(
                          fontSize: 12.0,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                          color: tokens.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        Navigator.of(context).pop();
                        ContextualSupportSheet.show(
                          context,
                          initialChoice: _intensity >= 7 ? SupportChoice.settle : SupportChoice.action,
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          isAr
                              ? 'فتح الدعم الفوري →'
                              : (strings.isFrench
                                  ? 'Ouvrir l’aide →'
                                  : 'Open support →'),
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: tokens.ink,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _stabilizingStrategy!,
                  style: TextStyle(fontSize: 12, color: textPrimary, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Personal Baseline Integration
        if (baseline.hasEstablishedBaseline)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(tokens.rowRadius),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Icon(Icons.tune_outlined, size: 16, color: tokens.m1),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isAr
                        ? 'المرجع الشخصي: ${baseline.totalRecordedDays} أيام ملاحظة'
                        : (strings.isFrench
                            ? 'Référence personnelle : ${baseline.totalRecordedDays} jours calibrés'
                            : 'Personal Baseline: ${baseline.totalRecordedDays} calibrated days'),
                    style: TextStyle(fontSize: 12.5, color: textSecondary),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),

        // Action buttons
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton(
            onPressed: _saveReportAndClose,
            style: FilledButton.styleFrom(
              backgroundColor: tokens.ink,
              foregroundColor: tokens.bg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(tokens.buttonRadius)),
            ),
            child: Text(
              isAr
                  ? 'توثيق التقرير في أرشيف المرصد'
                  : (strings.isFrench
                      ? 'Enregistrer dans l’Observatoire'
                      : 'Log to Observatory Timeline'),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }
}
