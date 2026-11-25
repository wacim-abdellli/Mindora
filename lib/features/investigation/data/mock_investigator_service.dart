import '../../journal/domain/journal_memory_model.dart';
import '../../journey/domain/journey_state_model.dart';
import '../../mind_trace/domain/mind_trace_model.dart';
import '../../profile/domain/psychological_profile_model.dart';
import '../domain/case_model.dart';
import '../domain/conversation_mode.dart';
import '../domain/hypothesis.dart';
import '../domain/investigator_service.dart';
import '../domain/statement.dart';

/// Simulated implementation of The Warm Investigator for offline development & testing.
///
/// Strictly adheres to Section 4 voice rules:
/// 1. Ask more than tell.
/// 2. Hypotheses, never verdicts.
/// 3. Acknowledge the feeling first.
/// 4. Plain language.
/// 5. Short turns.
/// 6. Trilingual clinical fidelity (authentic Tunisian Arabic, French, English).
class MockInvestigatorService implements InvestigatorService {
  @override
  Future<String> getNextQuestion({
    required CaseModel currentCase,
    required List<Statement> conversationHistory,
    bool includePastCaseSummaries = true,
    String? languageCode,
    PsychologicalProfileModel? profile,
    JourneyStateModel? journey,
    ConversationMode? conversationMode,
    MindTraceModel? latestTrace,
    List<MindTraceModel>? historicalTraces,
    List<JournalMemoryModel>? compressedMemories,
    String? sessionSummary,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final lang = languageCode ?? 'en';
    final mode = conversationMode ?? ConversationMode.exploreThought;
    final userTurns = conversationHistory
        .where((s) => s.speaker == StatementSpeaker.user)
        .toList();
    final count = userTurns.length;
    final latestText = userTurns.isNotEmpty
        ? userTurns.last.text.trim()
        : currentCase.incidentDescription.trim();
    final lower = latestText.toLowerCase();

    final directives = (profile?.customAiDirectives ?? '').toLowerCase();
    final prefersBrief = directives.contains('short') ||
        directives.contains('brief') ||
        directives.contains('concise') ||
        directives.contains('direct') ||
        directives.contains('bref') ||
        directives.contains('court') ||
        directives.contains('قصير') ||
        directives.contains('مختصر');

    // Context-aware spark / theme hooks before generic turn progression
    final wantsFactsVsGuesses = lower.contains('fact') && lower.contains('guess') ||
        lower.contains('concrete proof') ||
        lower.contains('الحقيقة والتخمين') ||
        lower.contains('دليل ملموس') ||
        lower.contains('faits et hypothèses') ||
        lower.contains('preuve concrète');
    final wantsAlternativeAngle = lower.contains('alternative') ||
        lower.contains('another angle') ||
        lower.contains('autre explication') ||
        lower.contains('طريقة أخرى');
    final mentionsSomatic = lower.contains('chest') ||
        lower.contains('tight') ||
        lower.contains('tension') ||
        lower.contains('breath') ||
        lower.contains('سخون') ||
        lower.contains('ضغط في بدن') ||
        lower.contains('صدري') ||
        lower.contains('poitrine') ||
        lower.contains('tension physique');
    final mentionsSleep = lower.contains('sleep') ||
        lower.contains('tired') ||
        lower.contains('exhausted') ||
        lower.contains('نوم') ||
        lower.contains('تعب') ||
        lower.contains('sommeil') ||
        lower.contains('épuis');
    final mentionsDelayOrSilence = lower.contains('reply') ||
        lower.contains('text') ||
        lower.contains('silence') ||
        lower.contains('ignore') ||
        lower.contains('سكوت') ||
        lower.contains('ما جاوب') ||
        lower.contains('répon');

    final highIntensityLead = count <= 1 &&
        latestTrace != null &&
        latestTrace.isCompleted &&
        latestTrace.moodIntensity >= 7;

    if (wantsFactsVsGuesses) {
      if (lang == 'ar') {
        return prefersBrief
            ? 'باش نفرّقو بوضوح: شنوة الحاجة اللي شفتها ولا سمعتها بالضبط، وشنوة التفسير اللي زادو مخك وحدو؟'
            : 'خلّينا نقسموها لزوز: شنوة الواقعة الملموسة اللي صارت قدامك بالضبط، وشنوة الاستنتاج اللي خاف منو مخك؟';
      } else if (lang == 'fr') {
        return prefersBrief
            ? 'Séparons simplement : quel est le fait observable exact, et qu’est-ce que votre esprit a ajouté ?'
            : 'Mettons-les côte à côte : quel fait précis a eu lieu exactement, et quelle interprétation votre esprit a-t-il comblée ensuite ?';
      }
      return prefersBrief
          ? 'What exact fact happened on camera, and what part did your mind fill in afterward?'
          : 'Let us place them side by side: what exact event happened externally, and what story or worry did your mind attach to it?';
    }

    if (wantsAlternativeAngle) {
      if (lang == 'ar') {
        return prefersBrief
            ? 'لو صاحبك عاش نفس الموقف هذا، شنوة أبسط تفسير محايد تنجم تعطيهلو؟'
            : 'سؤال بسيط يبدّل الزاوية: لو ما كانش عندك دخل شخصي في الموقف، شنوة التفسير العادي والمحايد اللي ينجم يكون صار؟';
      } else if (lang == 'fr') {
        return prefersBrief
            ? 'Si un ami vivait cela, quelle explication neutre et simple envisageriez-vous ?'
            : 'Regardons sous un angle neutre : s’il ne s’agissait pas d’un jugement sur vous, quelle autre raison ordinaire pourrait expliquer la situation ?';
      }
      return prefersBrief
          ? 'If a close friend told you this exact story, what calm explanation would you offer them first?'
          : 'Stepping back for a second: if this had nothing to do with you failing, what ordinary explanation could also fit what happened?';
    }

    if (mentionsSomatic && mode != ConversationMode.grounding) {
      if (lang == 'ar') {
        return prefersBrief
            ? 'التوتر في البدن علامة ضغط حقيقية. فين تحس بيه أكثر توا، وشنوة أول فكرة سبقت الإحساس هذا؟'
            : 'بدنك يعطي في إشارة واضحة قبل الأفكار. فين بالضبط تحس بالتوتر توا، وهل تحب نهديوه بنفس بسيط ولا نحكيو عالسبب؟';
      } else if (lang == 'fr') {
        return prefersBrief
            ? 'Cette tension corporelle compte. Où la sentez-vous le plus fort, et quelle pensée l’a précédée ?'
            : 'Votre corps envoie un signal bien réel. Où cette tension se loge-t-elle précisément en ce moment, et préférez-vous l’apaiser d’abord ou l’explorer ?';
      }
      return prefersBrief
          ? 'That physical tension is a real signal. Where do you feel it strongest, and what thought hit right before it?'
          : 'Your body reacts faster than words sometimes. Where is that tightness sitting right now, and would settling it for 10 seconds help before we continue?';
    }

    if (mode == ConversationMode.grounding) {
      if (lang == 'ar') {
        if (count <= 1) {
          return 'خلّينا ناخذو نفس هادي مع بعضنا توا. سمّيلي 3 حاجات تراهم بحذاك في البلاصة اللي إنتي فيها، وشنوة تحس تحت يديك؟';
        } else if (count == 2) {
          return 'يعطيك الصحة. ركز توا على شهيق بطيء وزفير أطول بشوية — شنوة صوت واحد هادي تسمعو في المحيط متاعك؟';
        } else if (count == 3) {
          return 'باهي برشا. كتافك كيفاش حاسين توا مقارنة ببداية الدردشة، أخف شوية ولا مزالوا مشدودين؟';
        }
        return 'توا كيفاه نبضك وتنفّسك؟ تحب نزيدو دقيقة تثبيت أخرى ولا نحكيو بهدوء على الخطوة الجاية؟';
      } else if (lang == 'fr') {
        if (count <= 1) {
          return 'Faisons une pause ensemble maintenant. Pouvez-vous nommer 3 choses visibles autour de vous et une surface solide que vous touchez ?';
        } else if (count == 2) {
          return 'Très bien. Prenez une inspiration calme puis expirez plus lentement — quel son léger entendez-vous en ce moment ?';
        } else if (count == 3) {
          return 'Parfait. Comment sentez-vous vos épaules et votre mâchoire maintenant par rapport au début ?';
        }
        return 'Où en est votre calme intérieur maintenant ? Souhaitez-vous encore un instant d’ancrage ou aborder la suite doucement ?';
      }
      if (count <= 1) {
        return 'Let us pause together and steady your breath. Name 3 objects you can see right now and one solid surface under your hands or feet.';
      } else if (count == 2) {
        return 'Good. Try one slow breath in and a slightly longer breath out — what quiet sound can you notice nearby right now?';
      } else if (count == 3) {
        return 'Take your time. Notice your shoulders and jaw: does anything feel even 10 percent softer than a minute ago?';
      }
      return 'How settled does your breathing feel now? Would you like another grounding step or to unpack one small piece calmly?';
    }

    if (mode == ConversationMode.understandEmotion) {
      if (lang == 'ar') {
        if (count <= 1) {
          return highIntensityLead
              ? 'نعرف اللي شدة اليوم كانت عالية برشا. من غير أي لوم، لو الإحساس هذا عندو بلاصة واضحة في بدنك توا، فين تحسو؟'
              : 'خلّينا نقعدو مع الشعور هذا بهدوء من غير حكم. فين تحس بيه أكثر في بدنك توا — في صدرك، في رقبتك، ولا في معدتك؟';
        } else if (count == 2) {
          return 'وإذا هذا الشعور كان ينجم يحكي بجملة قصيرة، شنوة الحاجة اللي خايف منها ولا محتاجها توا؟';
        } else if (count == 3) {
          return 'قداش تحس شدتو توا من 10، وهل تحسو هو نفسه التوتر ولا فمّا تعب ولا خيبة وراه؟';
        }
        return 'شنوة أصغر حاجة لطيفة تنجم تعملها لروحك في الساعة الجاية باش تخفف عليه شوية؟';
      } else if (lang == 'fr') {
        if (count <= 1) {
          return highIntensityLead
              ? 'Votre ressenti récent semble intense. Sans jugement, où percevez-vous cette émotion le plus nettement dans votre corps ?'
              : 'Accueillons ce ressenti sans le juger. Où se manifeste-t-il physiquement en cet instant — poitrine, gorge ou épaules ?';
        } else if (count == 2) {
          return 'Si cette émotion pouvait formuler un besoin précis en une phrase, que chercherait-elle à protéger ?';
        } else if (count == 3) {
          return 'Sur une échelle de 1 à 10 maintenant, quelle est son intensité, et y a-t-il aussi de la fatigue dessous ?';
        }
        return 'Quel petit geste doux pourriez-vous vous accorder dans l’heure qui vient pour l’alléger ?';
      }
      if (count <= 1) {
        return highIntensityLead
            ? 'Today sounds like it carried a heavy intensity. Without judging it, where in your body does that feeling sit most clearly?'
            : 'Let us sit with this emotion without judging it. Where in your body do you notice it most clearly right now?';
      } else if (count == 2) {
        return 'If that feeling had one honest sentence about what feels threatened or needed right now, what would it say?';
      } else if (count == 3) {
        return 'Where does the intensity sit from 1 to 10 now, and is there another layer under it, like exhaustion or disappointment?';
      }
      return 'What is one small, kind boundary or comfort that would make the next hour 10 percent easier on you?';
    }

    if (mode == ConversationMode.psychologicalAnalysis) {
      if (lang == 'ar') {
        if (count <= 1) {
          return mentionsDelayOrSilence
              ? 'كي يصير غموض أو سكوت، المخ يكمّل الفراغ بسرعة بتفسير وقائي. هذا يشبه موقف صارلك قبل ولا تحسو جديد؟'
              : 'خلّينا نشوفو النمط بهدوء: الموقف هذا يظهر ديما وقت اللي تحس بالضغط ولا قلة الوضوح — هل الفرضية هذي تنطبق هون؟';
        } else if (count == 2) {
          return 'وشنوّة العادة ولا ردّة الفعل اللي ديما تعملها بعد ما يظهر النمط هذا — تهرب، تراجع كل شي، ولا تلوم روحك؟';
        } else if (count == 3) {
          return mentionsSleep
              ? 'كيفاش يبدى تفكيرك في المواقف هذي وقت اللي يكون نومك ناقص ولا بدنك تاعب مقارنة بأيام الراحة؟'
              : 'إلى أي حد الفكرة التلقائية هذي تحميك مؤقتاً، وإلى أي حد تزيد في تعبك على المدى الطويل؟';
        }
        return 'لو باش نجرّبو استجابة جديدة أبسط في المرة الجاية اللي يعود فيها النمط هذا، شنوة تنجم تكون؟';
      } else if (lang == 'fr') {
        if (count <= 1) {
          return mentionsDelayOrSilence
              ? 'Face au silence, l’esprit comble parfois le vide par un scénario d’alerte. Cela rappelle-t-il un schéma déjà vécu ?'
              : 'Observons un lien possible : cette réaction revient-elle surtout quand la pression monte ou que la certitude manque ?';
        } else if (count == 2) {
          return 'Quelle habitude automatique suit souvent cette pensée — vous retirer, ruminer, ou chercher à tout contrôler ?';
        } else if (count == 3) {
          return mentionsSleep
              ? 'Voyez-vous une différence dans la force de cette pensée après une nuit courte par rapport à un jour reposé ?'
              : 'À court terme, cette réaction essaie peut-être de vous protéger — mais quel coût a-t-elle sur votre énergie ?';
        }
        return 'Quelle micro-réaction plus douce aimeriez-vous tester la prochaine fois que ce schéma se présente ?';
      }
      if (count <= 1) {
        return mentionsDelayOrSilence
            ? 'Ambiguity often triggers a protective leap to the worst assumption. Does this reaction feel familiar from past situations?'
            : 'Looking at possible connections tentatively: does this reaction tend to show up when control or clarity feels low?';
      } else if (count == 2) {
        return 'Once that thought lands, what is your usual automatic move — pulling back, replaying every detail, or blaming yourself?';
      } else if (count == 3) {
        return mentionsSleep
            ? 'How differently does your mind handle this same trigger after poor sleep versus a rested night?'
            : 'Even if this pattern tries to keep you safe in the moment, what cost does it leave you carrying afterward?';
      }
      return 'What small alternative response would feel realistic to test next time this pattern shows up?';
    }

    if (mode == ConversationMode.guidedReflection) {
      if (lang == 'ar') {
        if (count <= 1) {
          return 'خلّينا نمشيو خطوة بخطوة: أولاً، شنوة الموقف المحدد في جملة قصيرة، وشنوة أول فكرة جات في بالك وقتها؟';
        } else if (count == 2) {
          return 'ثانياً: في لحظتها، قداش كنت مقتنع بالفكرة هذي من 10، وشنوة الشعور اللي تبعها؟';
        } else if (count == 3) {
          return 'ثالثاً: لو خذينا مسافة خطوة، شنوة دليل يدعم الفكرة ودليل ثاني يناقضها ولو شوية؟';
        }
        return 'رابعاً: كيفاش تنجم تصيغ فكرة أهدأ وأقرب للواقع تحتفظ بيها كخلاصة من الجلسة هذي؟';
      } else if (lang == 'fr') {
        if (count <= 1) {
          return 'Avançons étape par étape : quelle était la situation précise au départ, et quelle première pensée est apparue ?';
        } else if (count == 2) {
          return 'Deuxième étape : sur le moment, à combien sur 10 cette pensée semblait vraie, et quelle émotion a suivi ?';
        } else if (count == 3) {
          return 'Troisième étape : avec un peu de recul, quel fait va dans ce sens et quel autre fait le nuance ?';
        }
        return 'Dernière étape : quelle phrase plus équilibrée voudriez-vous garder comme point d’appui maintenant ?';
      }
      if (count <= 1) {
        return 'Let us take this step by step: what was the concrete situation first, and what exact thought flashed across your mind?';
      } else if (count == 2) {
        return 'Step two: how believable did that thought feel from 1 to 10 in that moment, and what emotion followed?';
      } else if (count == 3) {
        return 'Step three: putting it under a calm lens, what observable fact supports it and what piece complicates or softens it?';
      }
      return 'Final step: what grounded, realistic sentence feels worth keeping as your takeaway right now?';
    }

    if (mode == ConversationMode.justTalk) {
      if (lang == 'ar') {
        if (count <= 1) {
          return 'أنا لهنا نسمع فيك بهدوء ومن غير حتى حكم. شنوة أكثر حاجة مثقّلة عليك اليوم؟';
        } else if (count == 2) {
          return 'فاهمك. عندك الحق تحس بالتعب كي يتراكم كل شي هكا. تحب تزيد تفرّغ أكثر على النقطة هذي؟';
        } else if (count == 3) {
          return 'خذ كل وقتك. شنوة أكثر جزء تحس روحك وحيد فيه في الموضوع هذا؟';
        }
        return 'شكراً على صراحتك معايا. تحب نكملو نحكيو ولا تحب نقترح عليك خطوة بسيطة للراحة؟';
      } else if (lang == 'fr') {
        if (count <= 1) {
          return 'Je suis là et je vous écoute sans jugement. Qu’est-ce qui pèse le plus lourd aujourd’hui ?';
        } else if (count == 2) {
          return 'Je vous entends. C’est compréhensible de se sentir saturé quand tout s’accumule. Voulez-vous continuer sur ce point ?';
        } else if (count == 3) {
          return 'Prenez votre temps. Quelle part de tout cela vous semble la plus difficile à porter seul ?';
        }
        return 'Merci d’avoir partagé cela. Préférez-vous continuer à parler librement ou chercher un petit répit ?';
      }
      if (count <= 1) {
        return 'I am right here with you, without judgment or rush. What feels heaviest to carry right now?';
      } else if (count == 2) {
        return 'That makes sense — carrying that much on your own gets exhausting quickly. Do you want to say more about that part?';
      } else if (count == 3) {
        return 'I am listening. Which piece of this feels hardest to explain to people around you?';
      }
      return 'Thank you for letting that out here. Would you like to keep talking it through, or take a small breather next?';
    }

    // Default: ConversationMode.exploreThought (progressive 4-stage deconstruction)
    if (lang == 'ar') {
      if (count <= 1) {
        return prefersBrief
            ? 'موقف صعيب. شنوة الحاجة الملموسة اللي صارت بالضبط قبل ما تبدا الفكرة هذي؟'
            : 'باين عليه موقف ثقيل. قبل ما نحكمو عالفكرة، شنوة الحدث الملموس اللي قدح ردة الفعل هذي بالضبط؟';
      } else if (count == 2) {
        return prefersBrief
            ? 'واضح. وقتها، شنوة أول شعور جاك وقداش كانت شدتو؟'
            : 'واضح. وقت اللي صار هكا، شنوة أول إحساس بدني أو شعوري فقت بيه، وقداش كانت شدتو؟';
      } else if (count == 3) {
        return 'كي تغزر للفكرة هذي توا: فما دليل حقيقي ملموس، ولا هو استنتاج سريع بناه مخك تحت التوتر؟';
      } else {
        return 'مفهوم. وشنوة لقيت روحك عملت بعد ما حسيت بهكا — وهل تحس الفكرة مزالت بنفس القوة توا؟';
      }
    } else if (lang == 'fr') {
      if (count <= 1) {
        return prefersBrief
            ? 'Moment pesant. Quel fait précis s’est produit juste avant cette pensée ?'
            : 'Cela semble pesant. Avant d’analyser la pensée, quel fait observable s’est produit juste avant ?';
      } else if (count == 2) {
        return prefersBrief
            ? 'Compris. Quelle émotion est apparue en premier, et avec quelle force ?'
            : 'Compris. Lorsque cela s’est produit, quelle sensation ou émotion avez-vous ressentie en premier ?';
      } else if (count == 3) {
        return 'En relisant cette pensée : repose-t-elle sur un fait observable ou sur une conclusion hâtive sous pression ?';
      } else {
        return 'Bien noté. Qu’avez-vous fait ensuite, et cette pensée garde-t-elle la même force maintenant ?';
      }
    } else {
      if (count <= 1) {
        return prefersBrief
            ? 'That sounds heavy. What exact event happened right before that thought started?'
            : 'That sounds like a heavy moment to sit with. Before we examine the thought itself, what happened right before this reaction?';
      } else if (count == 2) {
        return prefersBrief
            ? 'Got it. What emotion or body cue hit first, and how strong was it?'
            : 'Got it. When that happened, what physical sensation or emotion did you notice first, and how intense was it?';
      } else if (count == 3) {
        return 'Looking at that thought now: what concrete fact supports it, and what part might be a fast guess made under stress?';
      } else {
        return 'Understood. What did you find yourself doing next, and does the thought still feel just as loud now?';
      }
    }
  }

  @override
  Future<List<Hypothesis>> generateHypotheses({
    required CaseModel currentCase,
    String? languageCode,
    PsychologicalProfileModel? profile,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final lang = languageCode ?? 'en';

    if (lang == 'ar') {
      return const [
        Hypothesis(
          id: 'hyp-ar-1',
          title: 'استباق دفاعي وقائي',
          explanation: 'مخك ينجم يكون قفز لأسوأ سيناريو باش يحمي روحك من الصدمة أو المفاجأة.',
          whyItMightFit: 'يتطابق مع الانتقال السريع من واقعة عادية إلى استنتاج قلق وعالي الشدة.',
          whatDoesNotFit: 'ما فما حتى تصريح واضح أو مباشر من الطرف الآخر يفيد الرفض أو العداء.',
        ),
        Hypothesis(
          id: 'hyp-ar-2',
          title: 'ظروف خارجة عن النطاق',
          explanation: 'الطرف الآخر ينجم يكون لاهي، مشغول، ولا ما عندوش وقت ولا طاقة يجاوب توا.',
          whyItMightFit: 'التأخر في الرد لساعات أمر شائع وطبيعي في نسق الحياة اليومية والخدمة.',
          whatDoesNotFit: 'تحس بيه غير منطقي وقت تبدا انت على أعصابك وتستنى في رد فوري.',
        ),
        Hypothesis(
          id: 'hyp-ar-3',
          title: 'تضخيم الغموض والسكوت',
          explanation: 'السكوت ديما يشبه لصفحة بيضاء، يخلّي المخ والمخاوف القديمة ترسم عليها سيناريوهات مرعبة.',
          whyItMightFit: 'ردة فعلك الشعورية أكبر بكثير من الحدث الواقعي الملموس في حد ذاته.',
          whatDoesNotFit: 'تنجم تكون فعلاً حسيت بنوع من البرود أو التوتر الحقيقي في وقت سابق.',
        ),
      ];
    } else if (lang == 'fr') {
      return const [
        Hypothesis(
          id: 'hyp-fr-1',
          title: 'Anticipation Protectrice',
          explanation: 'Votre esprit anticipe peut-être le pire scénario pour éviter d’être pris au dépourvu.',
          whyItMightFit: 'Cela correspond au glissement rapide d’un fait neutre vers une conclusion anxiogène.',
          whatDoesNotFit: 'Il n’y a eu aucune déclaration explicite de l’autre personne indiquant un rejet.',
        ),
        Hypothesis(
          id: 'hyp-fr-2',
          title: 'Délai Circonstanciel',
          explanation: 'L’autre personne était peut-être simplement occupée, distraite ou indisponible.',
          whyItMightFit: 'Quelques heures sans répondre restent habituelles dans une journée chargée.',
          whatDoesNotFit: 'Cela semble contre-intuitif lorsque vous attendiez urgemment une réponse.',
        ),
        Hypothesis(
          id: 'hyp-fr-3',
          title: 'Amplification de l’Ambiguïté',
          explanation: 'Le silence agit comme une toile blanche sur laquelle les anxiétés passées projettent leur propre scénario.',
          whyItMightFit: 'La charge émotionnelle dépasse largement l’événement factuel observable.',
          whatDoesNotFit: 'Vous avez peut-être perçu une réelle tension relationnelle préalable.',
        ),
      ];
    }

    return const [
      Hypothesis(
        id: 'hyp-en-1',
        title: 'Protective Anticipation',
        explanation: 'Your mind might be jumping ahead to assume the worst to prevent feeling caught off guard.',
        whyItMightFit: 'It matches the quick shift from a neutral fact to a high-intensity conclusion.',
        whatDoesNotFit: 'There was no explicit statement from the other person indicating rejection.',
      ),
      Hypothesis(
        id: 'hyp-en-2',
        title: 'Circumstantial Delay',
        explanation: 'The other person may have simply been occupied, distracted, or unavailable.',
        whyItMightFit: 'Three hours without replying is common during busy workdays.',
        whatDoesNotFit: 'It feels counter-intuitive when you were urgently waiting for a reply.',
      ),
      Hypothesis(
        id: 'hyp-en-3',
        title: 'Amplified Ambiguity',
        explanation: 'Silence often acts like a blank canvas where past anxieties project their own script.',
        whyItMightFit: 'The reaction felt larger than the observable event alone.',
        whatDoesNotFit: 'You may indeed have picked up on real interpersonal friction earlier.',
      ),
    ];
  }

  @override
  Future<List<String>> generateCrossExaminationQuestions({
    required CaseModel currentCase,
    required Hypothesis hypothesis,
    String? languageCode,
    PsychologicalProfileModel? profile,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final lang = languageCode ?? 'en';

    if (lang == 'ar') {
      return [
        'شنوة الأدلة الملموسة اللي كنا نشوفوها لو كانت هذي صحيحة 100%؟',
        'صارش مرة موقف كيف هكا وكانت النتيجة عادية ولا إيجابية؟',
        'شنوة النصيحة الهادئة اللي تعطيها لصاحبك لو عاش نفس الموقف بالضبط؟',
      ];
    } else if (lang == 'fr') {
      return [
        'Quelles preuves tangibles verrait-on si cette explication était vraie à 100% ?',
        'Y a-t-il déjà eu une fois où cette situation s’est produite avec une issue neutre ou positive ?',
        'Quel conseil bienveillant donneriez-vous à un proche vivant exactement cette situation ?',
      ];
    }

    return [
      'What observable evidence would we expect to see if this explanation were 100% true?',
      'Has there ever been a time when this situation happened and the outcome was completely different?',
      'If a close friend experienced this exact scenario, what possibility would you offer them?',
    ];
  }

  @override
  Future<String> summarizeFindings({
    required CaseModel currentCase,
    String? languageCode,
    PsychologicalProfileModel? profile,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final lang = languageCode ?? 'en';

    if (lang == 'ar') {
      return 'خلاصة الجلسة المعرفية لـ ${currentCase.caseNumber}:\n\n'
          '• الوقائع الملموسة: الحدث الخارجي وقع كما هو دون دليل مباشر على نية إيذاء.\n'
          '• الافتراضات المرصودة: العقل سارع إلى سد فجوة الصمت بافتراض الرفض الشخصي.\n'
          '• نقاط عدم اليقين: النية الحقيقية للطرف الآخر تبقى غير مؤكدة ما لم يتم التحقق المباشر.';
    } else if (lang == 'fr') {
      return 'Synthèse cognitive pour la ${currentCase.caseNumber} :\n\n'
          '• Faits observés : L’événement extérieur s’est produit tel que décrit, sans preuve directe d’intention malveillante.\n'
          '• Suppositions identifiées : L’esprit a comblé le silence par l’hypothèse d’un rejet personnel.\n'
          '• Incertitudes : Les intentions réelles restent invérifiées jusqu’à clarification directe.';
    }

    return 'Cognitive Analysis Summary for ${currentCase.caseNumber}:\n\n'
        '• Observed Facts: The external event occurred as stated, without direct evidence of malicious intent.\n'
        '• Assumptions Identified: The mind filled the silence with assumed rejection.\n'
        '• Uncertainties: The true intent of the other person remains unverified until clarified.';
  }
}
