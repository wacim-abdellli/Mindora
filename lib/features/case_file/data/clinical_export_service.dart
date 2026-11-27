import '../../insights/data/pattern_awareness_service.dart';
import '../../insights/domain/personal_baseline_model.dart';
import '../../investigation/domain/case_model.dart';
import '../../mind_trace/domain/affect_taxonomy.dart';
import '../../mind_trace/domain/mind_trace_model.dart';
import '../../../app/localization/app_strings.dart';

/// Clinical Session Brief generator formatting cognitive deconstructions for clinician review.
///
/// Section 12: "The app should help a person arrive at therapy better prepared.
/// Working concept: the Session Brief, a summary of selected cases and patterns
/// the user brings to a professional."
class ClinicalExportService {
  /// Generates a structured clinical session brief from selected cases and optional
  /// mood/baseline tracking summaries.
  ///
  /// Any case marked `isPrivate == true` is strictly filtered out.
  static String generateSessionBrief({
    required List<CaseModel> cases,
    required AppStrings strings,
    String recipientOrNote = '',
    PersonalBaseline? baseline,
    WeeklySummaryReport? weeklySummary,
    List<MindTraceModel>? traces,
  }) {
    // Strictly filter out private shielded cases AND private traces (Principle 2)
    final shareableCases = cases.where((c) => !c.isPrivate).toList();
    final traceList = (traces ?? const <MindTraceModel>[])
        .where((t) => !t.isPrivate)
        .toList(growable: false);
    final hasBaselineData = baseline != null && baseline.totalRecordedDays > 0;
    final hasWeeklyData =
        weeklySummary != null && weeklySummary.totalEntriesThisWeek > 0;
    final hasTrackingData =
        hasBaselineData || hasWeeklyData || traceList.isNotEmpty;

    if (shareableCases.isEmpty && !hasTrackingData) {
      return strings.isArabic
          ? 'لا توجد جلسات قابلة للمشاركة. جميع الجلسات المحددة موسومة بدرع السرية (خاصة).'
          : (strings.isFrench
                ? 'Aucune session partageable. Toutes les sessions sélectionnées sont confidentielles.'
                : 'No shareable sessions found. All selected sessions are shielded as private.');
    }

    final buffer = StringBuffer();
    final isAr = strings.isArabic;
    final isFr = strings.isFrench;

    // Header & Confidentiality banner
    buffer.writeln(
      '======================================================================',
    );
    buffer.writeln(
      isAr
          ? 'Mindora — ملخص الجلسات السريري (SESSION BRIEF)'
          : (isFr
                ? 'Mindora — BILAN DE SESSIONS CLINIQUES (SESSION BRIEF)'
                : 'Mindora — CLINICAL SESSION BRIEF'),
    );
    buffer.writeln(
      isAr
          ? 'تقرير معرفي صادر بمبادرة شخصية من المستعمل لمناقشته مع المعالج'
          : (isFr
                ? 'Document cognitif généré à l’initiative exclusive du patient'
                : 'Confidential Patient-Initiated Cognitive Summary for Clinical Collaboration'),
    );
    buffer.writeln(
      '======================================================================\n',
    );

    // Clinical Notice & Mandatory Principles (Principles 4 & Forbidden terms compliance)
    buffer.writeln(
      isAr
          ? '[إشعار وتنبيه سريري]'
          : (isFr
                ? '[AVIS ET MENTIONS CLINIQUES]'
                : '[CLINICAL NOTICE & DISCLAIMER]'),
    );
    if (isAr) {
      buffer.writeln(
        '• تم تصميم Mindora كأداة للتأمل الفكري الذاتي مستوحاة من مبادئ العلاج السلوكي المعرفي (CBT).',
      );
      buffer.writeln(
        '• التطبيق لا يقدم علاجاً طبياً، تشخيصاً نفسياً، أو علاجاً سريرياً بديلاً عن الطبيب المختص.',
      );
      buffer.writeln(
        '• الفرضيات المولدة بواسطة الذكاء الاصطناعي هي نماذج فكرية استكشافية للتأمل وليست استنتاجات طبية سريرية.',
      );
      buffer.writeln(
        '• المحفزات، الأفكار التلقائية، والخلاصات الواردة تمثل تقارير ذاتية دقيقة سجلها المستعمل بكلماته الشخصية.',
      );
      buffer.writeln(
        '• النظام لا يتنبأ بالانتكاس النفسي ولا يقيم شخصية المستعمل.',
      );
    } else if (isFr) {
      buffer.writeln(
        '• Mindora est un outil d’auto-réflexion cognitive inspiré des approches TCC.',
      );
      buffer.writeln(
        '• L’application ne fournit aucun traitement médical, diagnostic psychiatrique ni psychothérapie.',
      );
      buffer.writeln(
        '• Les hypothèses générées par l’IA sont des modèles cognitifs exploratoires de réflexion, et NON des conclusions cliniques.',
      );
      buffer.writeln(
        '• Les stimuli, pensées automatiques et conclusions reflètent l’auto-évaluation authentique de l’utilisateur.',
      );
      buffer.writeln(
        '• L’application ne prédit jamais de rechute et ne porte aucun jugement sur la personne.',
      );
    } else {
      buffer.writeln(
        '• Mindora is a cognitive self-reflection instrument inspired by CBT principles.',
      );
      buffer.writeln(
        '• The application does NOT provide psychiatric treatment, medical diagnoses, or formal psychotherapy.',
      );
      buffer.writeln(
        '• AI-assisted hypotheses are exploratory cognitive possibilities for patient self-reflection, NOT clinical findings or diagnoses.',
      );
      buffer.writeln(
        '• Patient narrative, observable triggers, automatic thoughts, and conclusions represent authentic patient self-reports.',
      );
      buffer.writeln(
        '• Mindora never predicts relapse or judges psychological character.',
      );
    }

    buffer.writeln(
      '\n----------------------------------------------------------------------',
    );
    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    buffer.writeln(
      isAr
          ? 'تاريخ التصدير: $dateStr | عدد الجلسات المرفقة: ${shareableCases.length}'
          : (isFr
                ? 'Date d’export : $dateStr | Nombre de sessions : ${shareableCases.length}'
                : 'Export Date: $dateStr | Sessions Included: ${shareableCases.length}'),
    );
    if (recipientOrNote.trim().isNotEmpty) {
      buffer.writeln(
        isAr
            ? 'المعالج المستهدف / ملاحظة: ${recipientOrNote.trim()}'
            : (isFr
                  ? 'Praticien / Note de séance : ${recipientOrNote.trim()}'
                  : 'Clinician / Session Note: ${recipientOrNote.trim()}'),
      );
    }
    buffer.writeln(
      '----------------------------------------------------------------------\n',
    );

    if (hasTrackingData) {
      buffer.writeln(
        isAr
            ? '[المرجع الشخصي واتجاهات المزاج والأعراض]'
            : (isFr
                  ? '[LIGNE DE BASE PERSONNELLE & TENDANCES DE SUIVI]'
                  : '[PERSONAL BASELINE & WEEKLY TRACKING SUMMARY]'),
      );
      if (hasBaselineData) {
        buffer.writeln(
          isAr
              ? '• أيام الملاحظة المسجلة: ${baseline.totalRecordedDays}'
              : (isFr
                    ? '• Jours d’observation enregistrés : ${baseline.totalRecordedDays}'
                    : '• Recorded observation days: ${baseline.totalRecordedDays}'),
        );
        if (baseline.averageMoodIntensity != null) {
          buffer.writeln(
            isAr
                ? '• متوسط شدة المزاج: ${baseline.averageMoodIntensity!.toStringAsFixed(1)}/10'
                : (isFr
                      ? '• Intensité moyenne de l’humeur : ${baseline.averageMoodIntensity!.toStringAsFixed(1)}/10'
                      : '• Average mood intensity: ${baseline.averageMoodIntensity!.toStringAsFixed(1)}/10'),
          );
        }
        if (baseline.averageSleepHours != null) {
          buffer.writeln(
            isAr
                ? '• متوسط النوم المبلغ عنه ذاتياً: ${baseline.averageSleepHours!.toStringAsFixed(1)} س'
                : (isFr
                      ? '• Sommeil moyen déclaré : ${baseline.averageSleepHours!.toStringAsFixed(1)} h'
                      : '• Self-reported average sleep: ${baseline.averageSleepHours!.toStringAsFixed(1)} hrs'),
          );
        }
        if (baseline.commonEmotions.isNotEmpty) {
          final formattedEmotions = baseline.commonEmotions
              .take(5)
              .map((e) => AffectTaxonomy.localizedLabel(e, strings))
              .join(', ');
          buffer.writeln(
            '• ${isAr ? "المشاعر المتكررة" : (isFr ? "Émotions fréquentes" : "Recurring emotions")}: $formattedEmotions',
          );
        }
        if (baseline.emotionFrequencyMap.isNotEmpty) {
          final nuancedSummary = baseline.emotionFrequencyMap.entries
              .where((e) => !AffectTaxonomy.isCoreMood(e.key))
              .take(5)
              .map(
                (e) =>
                    '${AffectTaxonomy.localizedLabel(e.key, strings)} (${e.value})',
              )
              .join(', ');
          if (nuancedSummary.isNotEmpty) {
            buffer.writeln(
              '• ${strings.recurringFeelingsLabel}: $nuancedSummary',
            );
          }
        }
        if (baseline.diurnalIntensityAverages.isNotEmpty) {
          String bucketName(DayTimeBucket b) => switch (b) {
            DayTimeBucket.morning => strings.morningBucketLabel,
            DayTimeBucket.afternoon => strings.afternoonBucketLabel,
            DayTimeBucket.evening => strings.eveningBucketLabel,
            DayTimeBucket.night => strings.nightBucketLabel,
          };
          final diurnalParts = DayTimeBucket.values
              .where(baseline.diurnalIntensityAverages.containsKey)
              .map(
                (b) =>
                    '${bucketName(b)} ${baseline.diurnalIntensityAverages[b]!.toStringAsFixed(1)}/10',
              )
              .join(' | ');
          if (diurnalParts.isNotEmpty) {
            buffer.writeln('• ${strings.diurnalRhythmLabel}: $diurnalParts');
          }
        }
        if (baseline.averageIntraDaySwing != null &&
            baseline.multiEntryDaysCount > 0) {
          buffer.writeln(
            '• ${strings.intraDayShiftAvgLabel}: ±${baseline.averageIntraDaySwing!.toStringAsFixed(1)}/10 (${baseline.multiEntryDaysCount}d)',
          );
        }
        if (baseline.recurringTriggers.isNotEmpty) {
          buffer.writeln(
            '• ${isAr ? "المحفزات المتكررة" : (isFr ? "Déclencheurs fréquents" : "Recurring triggers")}: ${baseline.recurringTriggers.take(4).join(', ')}',
          );
        }
      }
      if (hasWeeklyData) {
        buffer.writeln(
          isAr
              ? '• التغيرات الأسبوعية (${weeklySummary.weekRange}): ${weeklySummary.whatChangedSummary}'
              : (isFr
                    ? '• Évolution hebdomadaire (${weeklySummary.weekRange}) : ${weeklySummary.whatChangedSummary}'
                    : '• Weekly shifts (${weeklySummary.weekRange}): ${weeklySummary.whatChangedSummary}'),
        );
        buffer.writeln('• ${weeklySummary.sleepTrend}');
        if (weeklySummary.topSymptoms.isNotEmpty) {
          buffer.writeln(
            '• ${isAr ? "الأعراض المسجلة" : (isFr ? "Ressentis notés" : "Noted symptoms")}: ${weeklySummary.topSymptoms.join(', ')}',
          );
        }
        if (weeklySummary.suggestedTherapyTopics.isNotEmpty) {
          buffer.writeln(
            isAr
                ? '• محاور مقترحة للنقاش العلاجي:'
                : (isFr
                      ? '• Thèmes suggérés pour la séance :'
                      : '• Suggested discussion themes for session:'),
          );
          for (final topic in weeklySummary.suggestedTherapyTopics) {
            buffer.writeln('   - $topic');
          }
        }
      } else if (traceList.isNotEmpty) {
        final avgIntensity =
            traceList.fold<int>(0, (s, t) => s + t.moodIntensity) /
            traceList.length;
        buffer.writeln(
          isAr
              ? '• إجمالي التسجيلات المشمولة: ${traceList.length} (متوسط الشدة: ${avgIntensity.toStringAsFixed(1)}/10)'
              : (isFr
                    ? '• Total des entrées incluses : ${traceList.length} (intensité moyenne : ${avgIntensity.toStringAsFixed(1)}/10)'
                    : '• Total traces included: ${traceList.length} (avg intensity: ${avgIntensity.toStringAsFixed(1)}/10)'),
        );
      }
      buffer.writeln(
        '----------------------------------------------------------------------\n',
      );
    }

    // Chronological Sessions Deconstruction
    for (int i = 0; i < shareableCases.length; i++) {
      final c = shareableCases[i];
      final sessionDate =
          '${c.createdAt.day.toString().padLeft(2, '0')}/${c.createdAt.month.toString().padLeft(2, '0')}/${c.createdAt.year}';

      buffer.writeln(
        '======================================================================',
      );
      buffer.writeln(
        '${strings.formatSessionNumber(c.caseNumber)} — "${c.title}"',
      );
      buffer.writeln(
        '${isAr ? "التاريخ" : (isFr ? "Date" : "Recorded")}: $sessionDate | ${isAr ? "الحالة" : (isFr ? "Statut" : "Status")}: ${c.isCompleted ? (isAr ? "مكتملة" : (isFr ? "Complétée" : "Completed")) : (isAr ? "قيد التفكيك" : (isFr ? "En cours" : "In Progress"))}',
      );

      if (c.chain != null && c.chain!.emotion.isNotEmpty) {
        buffer.writeln(
          '${isAr ? "الحالة العاطفية والشدة" : (isFr ? "Affect somatique & intensité" : "Self-Reported Affect & Intensity")}: ${c.chain!.emotion} (${c.chain!.emotionIntensity}/10)',
        );
      }
      buffer.writeln(
        '----------------------------------------------------------------------',
      );

      // 1. Activating Catalyst
      buffer.writeln(
        isAr
            ? '1. المحفز اللحظي (Activating Catalyst):'
            : (isFr ? '1. STIMULUS DÉCLENCHEUR :' : '1. ACTIVATING CATALYST:'),
      );
      buffer.writeln(
        c.incidentDescription.isNotEmpty
            ? '"${c.incidentDescription}"'
            : (isAr
                  ? 'لم يُسجل محفز نصي.'
                  : (isFr
                        ? 'Aucun récit enregistré.'
                        : 'No narrative logged.')),
      );
      buffer.writeln();

      // 2. Observable Chain
      if (c.chain != null) {
        buffer.writeln(
          isAr
              ? '2. سلسلة الاستجابة المعرفية والسلوكية:'
              : (isFr
                    ? '2. CHAÎNE COGNITIVE & COMPORTEMENTALE :'
                    : '2. COGNITIVE & BEHAVIORAL CHAIN:'),
        );
        buffer.writeln(
          '   • ${isAr ? "المحفز الملاحظ" : (isFr ? "Déclencheur observable" : "Observable Trigger")}: ${c.chain!.trigger}',
        );
        buffer.writeln(
          '   • ${isAr ? "الفكرة التلقائية" : (isFr ? "Pensée automatique" : "Automatic Thought")}: "${c.chain!.thought}" [${isAr ? "التصنيف الإبستيمي" : (isFr ? "Catégorie" : "Epistemic Label")}: ${c.chain!.thoughtLabel.name.toUpperCase()}]',
        );
        buffer.writeln(
          '   • ${isAr ? "دافع السلوك / رد الفعل" : (isFr ? "Impulsion comportementale" : "Behavioral Impulse / Action")}: ${c.chain!.behavior}',
        );
        buffer.writeln();
      }

      // 3. AI Exploratory Hypotheses (Clearly Labeled)
      if (c.hypotheses.isNotEmpty) {
        buffer.writeln(
          isAr
              ? '3. النماذج التفسيرية الاستكشافية (مساعدة الذكاء الاصطناعي - للتأمل فقط):'
              : (isFr
                    ? '3. HYPOTHÈSES COGNITIVES EXPLORATOIRES (Assistance IA - Réflexion uniquement) :'
                    : '3. EXPLORATORY COGNITIVE HYPOTHESES (AI-Assisted - For Patient Reflection Only):'),
        );
        for (final h in c.hypotheses) {
          buffer.writeln('   • [${h.title}]: ${h.explanation}');
          if (h.whyItMightFit.isNotEmpty) {
            buffer.writeln(
              '     - ${isAr ? "نقاط التوافق" : (isFr ? "Pourquoi cela correspond" : "Supporting indicators")}: ${h.whyItMightFit}',
            );
          }
          if (h.whatDoesNotFit.isNotEmpty) {
            buffer.writeln(
              '     - ${isAr ? "نقاط عدم التوافق" : (isFr ? "Ce qui ne correspond pas" : "Counter indicators")}: ${h.whatDoesNotFit}',
            );
          }
        }
        buffer.writeln();
      }

      // 3b. AI Reflection Summary (Strictly separated from patient's own words)
      if (c.findingsSummary != null &&
          c.findingsSummary!.trim().isNotEmpty &&
          c.findingsSummary!.trim() != (c.userConclusion ?? '').trim()) {
        buffer.writeln(
          isAr
              ? '3ب. ملخص الذكاء الاصطناعي للمحادثة (غير تشخيصي):'
              : (isFr
                    ? '3b. SYNTHÈSE GÉNÉRÉE PAR L’IA (Non diagnostique) :'
                    : '3b. AI-GENERATED REFLECTION SUMMARY (Non-Diagnostic):'),
        );
        buffer.writeln(c.findingsSummary!.trim());
        buffer.writeln();
      }

      // 4. Patient's Grounded Conclusion (Patient-authored only)
      buffer.writeln(
        isAr
            ? '4. خلاصة المستعمل بكلماته الشخصية:'
            : (isFr
                  ? '4. CONCLUSION PERSONNELLE DU PATIENT (Mots du patient) :'
                  : '4. PATIENT’S OWN WRITTEN TAKEAWAY (Patient-Authored Only):'),
      );
      buffer.writeln(
        c.userConclusion != null && c.userConclusion!.isNotEmpty
            ? '"${c.userConclusion}"'
            : (isAr
                  ? 'لم تُحدد خلاصة نهائية بعد.'
                  : (isFr
                        ? 'Aucune conclusion formulée pour le moment.'
                        : 'No conclusion anchored yet.')),
      );
      buffer.writeln(
        '======================================================================\n',
      );
    }

    buffer.writeln(
      isAr
          ? '--- نهاية ملخص الجلسات السريري • Mindora ---'
          : (isFr
                ? '--- FIN DU BILAN DE SESSIONS CLINIQUES • Mindora ---'
                : '--- END OF CLINICAL SESSION BRIEF • Mindora ---'),
    );

    return buffer.toString();
  }
}
