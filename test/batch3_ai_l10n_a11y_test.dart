import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_forensics/app/localization/app_strings.dart';
import 'package:mind_forensics/app/localization/locale_controller.dart';
import 'package:mind_forensics/app/theme/lab_theme.dart';
import 'package:mind_forensics/core/security/daily_usage_limiter.dart';
import 'package:mind_forensics/core/security/secure_key_manager.dart';
import 'package:mind_forensics/core/widgets/mind_pill.dart';
import 'package:mind_forensics/features/insights/data/pattern_awareness_service.dart';
import 'package:mind_forensics/features/insights/domain/personal_baseline_model.dart';
import 'package:mind_forensics/features/investigation/controllers/investigation_providers.dart';
import 'package:mind_forensics/features/investigation/data/direct_gemini_investigator_service.dart';
import 'package:mind_forensics/features/investigation/data/direct_groq_investigator_service.dart';
import 'package:mind_forensics/features/investigation/domain/case_model.dart';
import 'package:mind_forensics/features/investigation/domain/case_stage.dart';
import 'package:mind_forensics/features/investigation/domain/investigator_service.dart';
import 'package:mind_forensics/features/investigation/domain/statement.dart';
import 'package:mind_forensics/features/investigation/presentation/widgets/ai_engine_config_sheet.dart';
import 'package:mind_forensics/features/investigation/presentation/widgets/live_dialogue_view.dart';
import 'package:mind_forensics/features/journal/controllers/journal_memory_controller.dart';
import 'package:mind_forensics/features/journal/domain/journal_memory_model.dart';
import 'package:mind_forensics/features/journal/presentation/widgets/journal_memory_sheet.dart';
import 'package:mind_forensics/features/mind_trace/domain/mind_trace_model.dart';
import 'package:mind_forensics/features/observatory/domain/symptom_entry.dart';
import 'package:mind_forensics/features/profile/domain/condition_type.dart';
import 'package:mind_forensics/features/profile/domain/psychological_profile_model.dart';
import 'package:mind_forensics/features/profile/domain/symptom_catalog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeHttpHeaders implements HttpHeaders {
  final Map<String, String> values = {};

  @override
  ContentType? contentType;

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    values[name] = value.toString();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeUtf8Response implements HttpClientResponse {
  _FakeUtf8Response({required this.statusCode, required String body})
      : _bytes = utf8.encode(body);

  @override
  final int statusCode;
  final List<int> _bytes;

  @override
  Stream<S> transform<S>(StreamTransformer<List<int>, S> streamTransformer) =>
      Stream<List<int>>.fromIterable([_bytes]).transform(streamTransformer);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpClientRequest implements HttpClientRequest {
  _FakeHttpClientRequest({
    required this.headers,
    required this.onComplete,
  });

  @override
  final _FakeHttpHeaders headers;
  final HttpClientResponse Function(String writtenBody) onComplete;
  final StringBuffer _body = StringBuffer();

  @override
  void write(Object? object) {
    _body.write(object);
  }

  @override
  Future<HttpClientResponse> close() async => onComplete(_body.toString());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpClient implements HttpClient {
  _FakeHttpClient({
    required this.statusCode,
    required this.responseBody,
    this.throwSocketError = false,
  });

  final int statusCode;
  final String responseBody;
  final bool throwSocketError;
  Uri? capturedUri;

  @override
  Duration? connectionTimeout;

  @override
  Future<HttpClientRequest> postUrl(Uri url) async {
    capturedUri = url;
    if (throwSocketError) {
      throw const SocketException('Simulated offline state');
    }
    return _FakeHttpClientRequest(
      headers: _FakeHttpHeaders(),
      onComplete: (_) => _FakeUtf8Response(
        statusCode: statusCode,
        body: responseBody,
      ),
    );
  }

  @override
  void close({bool force = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  CaseModel buildCase({List<Statement> statements = const []}) {
    final now = DateTime(2026, 11, 14, 10);
    return CaseModel(
      id: 'case_b3_1',
      caseNumber: 'SESSION 01',
      title: 'Evening rumination',
      createdAt: now,
      updatedAt: now,
      currentStage: CaseStage.incident,
      incidentDescription: 'Tightness before sleep.',
      statements: statements,
      isPrivate: false,
    );
  }

  PsychologicalProfileModel buildConsentedProfile({String lang = 'fr'}) =>
      PsychologicalProfileModel(
        preferredLanguage: lang,
        shareWithAiCompanion: true,
        allowAiPersonalization: true,
        updatedAt: DateTime(2026, 11, 14, 10),
      );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    SecureKeyManager.resetStaticCache();
    await DailyUsageLimiter.resetForTesting();
  });

  group('Batch 3 Slice 3A — AI Models, Fallback Reporting & Config Sheet', () {
    test('DirectGeminiInvestigatorService defaults to gemini-2.5-flash and reports offline/API fallback', () async {
      expect(DirectGeminiInvestigatorService.defaultModel, equals('gemini-2.5-flash'));

      final offlineReasons = <AiFallbackReason>[];
      final offlineClient = _FakeHttpClient(
        statusCode: 500,
        responseBody: '',
        throwSocketError: true,
      );
      final offlineService = DirectGeminiInvestigatorService(
        apiKey: 'gemini_test_key',
        clientFactory: () => offlineClient,
        onFallback: offlineReasons.add,
      );

      final offlineReply = await offlineService.getNextQuestion(
        currentCase: buildCase(),
        conversationHistory: const [],
        profile: buildConsentedProfile(lang: 'fr'),
      );
      expect(offlineReply, isNotEmpty);
      expect(offlineClient.capturedUri?.toString(), contains('gemini-2.5-flash'));
      expect(offlineReasons, contains(AiFallbackReason.offlineOrNetwork));

      final apiReasons = <AiFallbackReason>[];
      final errorService = DirectGeminiInvestigatorService(
        apiKey: 'gemini_test_key',
        clientFactory: () => _FakeHttpClient(
          statusCode: 500,
          responseBody: '{"error":"internal"}',
        ),
        onFallback: apiReasons.add,
      );
      await errorService.getNextQuestion(
        currentCase: buildCase(),
        conversationHistory: const [],
        profile: buildConsentedProfile(lang: 'en'),
      );
      expect(apiReasons, contains(AiFallbackReason.apiError));
    });

    test('Quota exhaustion invokes dailyLimitReached and returns localized mock reply', () async {
      for (int i = 0; i < DailyUsageLimiter.maxDailyRequests; i++) {
        await DailyUsageLimiter.recordRequest();
      }

      final geminiReasons = <AiFallbackReason>[];
      final geminiService = DirectGeminiInvestigatorService(
        apiKey: 'gemini_quota_test',
        onFallback: geminiReasons.add,
      );
      final geminiReply = await geminiService.getNextQuestion(
        currentCase: buildCase(),
        conversationHistory: const [],
        profile: buildConsentedProfile(lang: 'fr'),
      );
      expect(geminiReasons, contains(AiFallbackReason.dailyLimitReached));
      expect(geminiReply, isNot(contains('Daily AI query limit reached')));

      final groqReasons = <AiFallbackReason>[];
      final groqService = DirectGroqInvestigatorService(
        apiKey: 'gsk_quota_test',
        onFallback: groqReasons.add,
      );
      final groqReply = await groqService.getNextQuestion(
        currentCase: buildCase(),
        conversationHistory: const [],
        profile: buildConsentedProfile(lang: 'ar'),
      );
      expect(groqReasons, contains(AiFallbackReason.dailyLimitReached));
      expect(groqReply, isNot(contains('Daily AI query limit reached')));
    });

    testWidgets('AiEngineConfigSheet stages provider switch locally until Save and persists proxy URL',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Hydrate initial config
      container.read(aiConfigProvider);
      await tester.pumpAndSettle();
      final initialProvider = container.read(aiConfigProvider).provider;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: buildMindTheme(Brightness.light),
            home: const Scaffold(
              body: SingleChildScrollView(
                child: AiEngineConfigSheet(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch chip away from initial provider without clicking Save yet
      final otherChipText = initialProvider == AiEngineProvider.groq
          ? 'Google Gemini'
          : 'Groq (Free Llama)';
      await tester.tap(find.text(otherChipText));
      await tester.pumpAndSettle();
      expect(container.read(aiConfigProvider).provider, initialProvider);

      // Select Groq, enter key & proxy, then Save & Activate
      await tester.tap(find.text('Groq (Free Llama)'));
      await tester.pumpAndSettle();

      final fields = find.byType(TextField);
      expect(fields, findsNWidgets(2));
      await tester.enterText(fields.at(0), 'gsk_live_saved_key');
      await tester.enterText(fields.at(1), 'https://proxy.example.org/groq');
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('SAVE & ACTIVATE'));
      await tester.tap(find.text('SAVE & ACTIVATE'));
      await tester.pumpAndSettle();

      final savedConfig = container.read(aiConfigProvider);
      expect(savedConfig.provider, AiEngineProvider.groq);
      expect(savedConfig.groqApiKey, equals('gsk_live_saved_key'));
      expect(savedConfig.proxyUrl, equals('https://proxy.example.org/groq'));
      expect(savedConfig.isLiveActive, isTrue);
    });

    testWidgets('LiveDialogueView renders dismissible fallback banner when aiRuntimeNoticeProvider is set',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: buildMindTheme(Brightness.light),
            home: Scaffold(
              body: LiveDialogueView(caseModel: buildCase()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      container
          .read(aiRuntimeNoticeProvider.notifier)
          .report(AiFallbackReason.dailyLimitReached);
      await tester.pumpAndSettle();

      const enStrings = AppStrings('en');
      expect(find.text(enStrings.aiNoticeDailyLimit), findsOneWidget);
      expect(find.text(enStrings.aiEngineSettingsAction), findsNothing);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      expect(container.read(aiRuntimeNoticeProvider), AiFallbackReason.none);
      expect(find.text(enStrings.aiNoticeDailyLimit), findsNothing);
    });
  });

  group('Batch 3 Slice 3C — French & Arabic Trilingual Parity', () {
    test('PatternAwarenessService localizes divergences & weekly topics in French and Arabic', () {
      final now = DateTime.now();
      const baseline = PersonalBaseline(
        totalRecordedDays: 14,
        hasSufficientData: true,
        averageSleepHours: 8.0,
        averageEnergyLevel: 4.0,
        averageMoodIntensity: 5.0,
        commonEmotions: ['calm'],
        recurringSymptoms: ['Headache'],
        recurringTriggers: ['Deadline pressure'],
        sleepObservationCount: 10,
        energyObservationCount: 10,
        moodObservationCount: 10,
        windowStartDate: null,
        windowEndDate: null,
      );

      final recentTraces = [
        MindTraceModel(
          id: 't1',
          date: now.subtract(const Duration(hours: 10)),
          createdAt: now,
          updatedAt: now,
          sleepHours: 4.5,
          energyLevel: 8,
          moodIntensity: 7,
          racingThoughts: 8,
        ),
        MindTraceModel(
          id: 't2',
          date: now.subtract(const Duration(days: 1)),
          createdAt: now,
          updatedAt: now,
          sleepHours: 5.0,
          energyLevel: 7,
          moodIntensity: 6,
          racingThoughts: 7,
        ),
      ];

      final frDivs = PatternAwarenessService.detectDivergences(
        traces: recentTraces,
        baseline: baseline,
        strings: const AppStrings('fr'),
      );
      expect(frDivs, isNotEmpty);
      expect(frDivs.first.title, contains('Écart'));
      expect(frDivs.first.timeWindow, equals('3 à 4 derniers jours'));

      final arDivs = PatternAwarenessService.detectDivergences(
        traces: recentTraces,
        baseline: baseline,
        strings: const AppStrings('ar'),
      );
      expect(arDivs, isNotEmpty);
      expect(arDivs.first.title, contains('تبدّل'));

      final frReport = WeeklySummaryReport.generate(
        traces: recentTraces,
        baseline: baseline,
        strings: const AppStrings('fr'),
      );
      expect(
        frReport.suggestedTherapyTopics.any((t) => t.contains('sommeil') || t.contains('déclencheurs')),
        isTrue,
      );

      final arReport = WeeklySummaryReport.generate(
        traces: recentTraces,
        baseline: baseline,
        strings: const AppStrings('ar'),
      );
      expect(
        arReport.suggestedTherapyTopics.any((t) => t.contains('النوم') || t.contains('المحفّزات')),
        isTrue,
      );
    });

    test('ExperienceCategory, SymptomDomain, SymptomCategory, MemoryModel & Auth errors localize cleanly', () {
      const fr = AppStrings('fr');
      const ar = AppStrings('ar');

      expect(ExperienceCategory.mood.localizedTitle(fr), contains('humeur'));
      expect(ExperienceCategory.mood.localizedTitle(ar), contains('بالمزاج'));

      expect(SymptomDomain.cognitive.localized(fr), contains('Cognition'));
      expect(SymptomDomain.cognitive.localized(ar), contains('الإدراك'));

      expect(SymptomCategory.emotional.localized(fr), contains('émotionnelles'));
      expect(SymptomCategory.emotional.localized(ar), contains('انفعالية'));

      expect(JournalMemoryCategory.recurringTheme.localized(fr), equals('Thème récurrent'));
      expect(JournalMemoryCategory.recurringTheme.localized(ar), equals('موضوع متكرّر'));

      expect(fr.localizeAuthError('Invalid email or password.'), contains('incorrect'));
      expect(ar.localizeAuthError('Invalid email or password.'), contains('غير صحيحة'));
    });
  });

  group('Batch 3 Slice 3D — 48dp Accessible Tap Targets', () {
    testWidgets('MindPill meets Android & iOS tap target guidelines', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          MaterialApp(
            theme: buildMindTheme(Brightness.light),
            home: Scaffold(
              body: Center(
                child: MindPill(
                  label: 'Steady',
                  isSelected: true,
                  onTap: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      } finally {
        handle.dispose();
      }
    });

    testWidgets('JournalMemorySheet Confirm/Dismiss/Delete actions meet 48dp guidelines in French',
        (tester) async {
      final handle = tester.ensureSemantics();
      try {
        final now = DateTime(2026, 11, 14);
        final item = JournalMemoryModel(
          id: 'mem_1',
          category: JournalMemoryCategory.recurringTheme,
          summary: 'Mornings feel clearer after a quiet walk.',
          sourceEntryIds: const ['e1', 'e2'],
          observationCount: 2,
          firstObservedDate: now,
          lastObservedDate: now,
          createdAt: now,
          updatedAt: now,
        );

        final container = ProviderContainer(
          overrides: [
            journalMemoryControllerProvider.overrideWith(
              () => _StaticMemoryNotifier([item]),
            ),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: buildMindTheme(Brightness.light),
              home: const Scaffold(
                body: JournalMemorySheet(),
              ),
            ),
          ),
        );
        await container.read(localeControllerProvider.notifier).setLanguage(AppLanguage.french);
        await tester.pumpAndSettle();

        expect(find.text('Thème récurrent'), findsOneWidget);
        expect(find.text('Confirmer'), findsOneWidget);
        expect(find.text('Ignorer'), findsOneWidget);

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      } finally {
        handle.dispose();
      }
    });
  });
}

class _StaticMemoryNotifier extends JournalMemoryNotifier {
  _StaticMemoryNotifier(this._items);
  final List<JournalMemoryModel> _items;

  @override
  Future<List<JournalMemoryModel>> build() async => _items;
}
