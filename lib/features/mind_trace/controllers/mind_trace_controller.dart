import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/locale_controller.dart';
import '../../../core/security/secure_key_manager.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../clinic_sync/controllers/clinic_sync_providers.dart';
import '../../investigation/controllers/investigation_providers.dart';
import '../../journal/controllers/journal_memory_controller.dart';
import '../../journey/controllers/journey_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import '../data/local_mind_trace_repository.dart';
import '../data/mind_trace_ai_service.dart';
import '../domain/mind_trace_model.dart';
import '../domain/trace_milestone.dart';

final mindTraceRepositoryProvider = Provider<MindTraceRepository>((ref) {
  final userId = ref.watch(authControllerProvider.select((s) => s.user?.id));
  final keyManager = ref.watch(secureKeyManagerProvider);
  return LocalMindTraceRepository(
    userId: userId,
    keyManager: keyManager,
  );
});

final mindTraceAiServiceProvider = Provider<MindTraceAiService>((ref) {
  final aiConfig = ref.watch(aiConfigProvider);
  return MindTraceAiService(
    apiKey: aiConfig.apiKey,
  );
});

class MindTraceNotifier extends AsyncNotifier<List<MindTraceModel>> {
  @override
  Future<List<MindTraceModel>> build() async {
    final userId = ref.watch(authControllerProvider.select((s) => s.user?.id));
    final keyManager = ref.watch(secureKeyManagerProvider);
    final repo = LocalMindTraceRepository(
      userId: userId,
      keyManager: keyManager,
    );
    return repo.getAllTraces();
  }

  Future<void> recordCheckIn(
    MindTraceModel trace, {
    bool generateAi = true,
  }) async {
    final repo = ref.read(mindTraceRepositoryProvider);
    var toSave = trace;

    // Optional: generate AI reflection if enabled and not already provided
    if (generateAi && (toSave.aiReflection == null || toSave.aiReflection!.isEmpty)) {
      final aiService = ref.read(mindTraceAiServiceProvider);
      final profile = ref.read(profileControllerProvider).value;
      final locale = ref.read(localeControllerProvider);
      final journeyState = ref.read(journeyControllerProvider).value;

      final currentList = state.value ?? [];
      final reflection = await aiService.generateDailyReflection(
        currentTrace: toSave,
        history: currentList,
        profile: profile,
        languageCode: locale.languageCode,
        availableActivities: journeyState?.activities,
      );

      toSave = toSave.copyWith(
        aiReflection: reflection,
        updatedAt: DateTime.now(),
      );
    }

    await repo.saveTrace(toSave);
    final fresh = await repo.getAllTraces();
    state = AsyncValue.data(fresh);
    ref.read(journalMemoryControllerProvider.notifier).recalculateMemories(traces: fresh);
    unawaited(
      ref
          .read(clinicAutoSyncCoordinatorProvider)
          .syncActivePatient(tracesOverride: fresh),
    );
  }

  Future<void> updateCheckIn(MindTraceModel trace) async {
    final repo = ref.read(mindTraceRepositoryProvider);
    await repo.saveTrace(trace.copyWith(updatedAt: DateTime.now()));
    final fresh = await repo.getAllTraces();
    state = AsyncValue.data(fresh);
    ref.read(journalMemoryControllerProvider.notifier).recalculateMemories(traces: fresh);
    unawaited(
      ref
          .read(clinicAutoSyncCoordinatorProvider)
          .syncActivePatient(tracesOverride: fresh),
    );
  }

  Future<void> toggleTracePrivacy(String id) async {
    final currentList = state.value ?? await future;
    final idx = currentList.indexWhere((t) => t.id == id);
    if (idx < 0) return;
    final target = currentList[idx];
    await updateCheckIn(target.copyWith(isPrivate: !target.isPrivate));
  }

  Future<void> deleteCheckIn(String id) async {
    final repo = ref.read(mindTraceRepositoryProvider);
    await repo.deleteTrace(id);
    final fresh = await repo.getAllTraces();
    state = AsyncValue.data(fresh);
    ref.read(journalMemoryControllerProvider.notifier).handleEntryDeleted('trace:$id');
    unawaited(
      ref
          .read(clinicAutoSyncCoordinatorProvider)
          .syncActivePatient(tracesOverride: fresh),
    );
  }

  Future<void> clearAllTraces() async {
    final repo = ref.read(mindTraceRepositoryProvider);
    await repo.clearAllTraces();
    state = const AsyncValue.data([]);
    // Correct bulk deletion: clears trace memories by recompressing with an empty trace list,
    // reloading and preserving valid case-derived memories.
    await ref
        .read(journalMemoryControllerProvider.notifier)
        .recalculateMemories(traces: const []);
  }
}

final mindTraceControllerProvider =
    AsyncNotifierProvider<MindTraceNotifier, List<MindTraceModel>>(
  MindTraceNotifier.new,
);

extension MindTraceListX on List<MindTraceModel> {
  List<MindTraceModel> tracesForDate(String dateKey) {
    final matching = where((t) => t.dateKey == dateKey).toList()
      ..sort((a, b) {
        final byTs = a.effectiveTimestamp.compareTo(b.effectiveTimestamp);
        if (byTs != 0) return byTs;
        return a.updatedAt.compareTo(b.updatedAt);
      });
    return matching;
  }

  List<MindTraceModel> get todayTraces {
    if (isEmpty) return const [];
    final now = DateTime.now();
    final todayKey =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return tracesForDate(todayKey);
  }

  MindTraceModel? get todayTrace {
    final today = todayTraces;
    return today.isNotEmpty ? today.last : null;
  }
}

/// Chronological intra-day moments recorded today (oldest -> newest).
final todayTracesProvider = Provider<List<MindTraceModel>>((ref) {
  final now = DateTime.now();
  final todayKey =
      '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

  return ref.watch(mindTraceControllerProvider.select((asyncVal) {
    final traces = asyncVal.value;
    if (traces == null || traces.isEmpty) return const [];
    return traces.tracesForDate(todayKey);
  }));
});

/// Computed provider for today's active/latest trace (if recorded).
/// Uses .select to prevent redundant invalidation cycles during build.
final todayTraceProvider = Provider<MindTraceModel?>((ref) {
  final today = ref.watch(todayTracesProvider);
  return today.isNotEmpty ? today.last : null;
});

/// Signal counter prompting [TrackScreen] to enter New Moment compose mode
/// even when the indexed shell branch is already mounted.
class TrackNewMomentSignalNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void trigger() => state = state + 1;
}

final trackNewMomentSignalProvider =
    NotifierProvider<TrackNewMomentSignalNotifier, int>(
  TrackNewMomentSignalNotifier.new,
);

/// Computed provider for unlocked milestones.
/// Uses .select to prevent redundant invalidation cycles during build.
final unlockedMilestonesProvider = Provider<List<TraceMilestone>>((ref) {
  final traceInfo = ref.watch(mindTraceControllerProvider.select((asyncTraces) {
    final traces = asyncTraces.value ?? [];
    final reflectionsCount = traces
        .where((t) => t.journalText != null && t.journalText!.trim().isNotEmpty)
        .length;
    return (count: traces.length, reflections: reflectionsCount);
  }));

  return TraceMilestone.allMilestones
      .where((m) => m.isUnlocked(traceInfo.count, traceInfo.reflections))
      .toList();
});
