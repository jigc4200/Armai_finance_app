import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ai_insight_model.dart';
import '../repositories/ai_insight_repository.dart';
import '../services/offline_cache_service.dart';
import 'auth_provider.dart';

final aiInsightRepositoryProvider = Provider<AiInsightRepository>((ref) {
  return AiInsightRepository();
});

class ActiveAiInsightNotifier extends AsyncNotifier<AiInsight?> {
  static const _cacheBucket = 'ai_insight.active';

  @override
  Future<AiInsight?> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return null;

    final cache = OfflineCacheService.instance;
    final cached = await cache.readMap(user.id, _cacheBucket);
    final cachedInsight = cached == null ? null : AiInsight.fromMap(cached);
    if (cachedInsight != null) {
      state = AsyncData(cachedInsight);
    }

    final repo = ref.watch(aiInsightRepositoryProvider);
    try {
      final fresh = await repo.getActive(user.id);
      if (fresh == null) {
        await cache.remove(user.id, _cacheBucket);
      } else {
        await cache.saveMap(user.id, _cacheBucket, fresh.toMap());
      }
      return fresh;
    } catch (error, stackTrace) {
      if (cachedInsight != null) return cachedInsight;
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  void updateInsight(AiInsight? insight) {
    state = AsyncData(insight);
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final cache = OfflineCacheService.instance;
    if (insight == null) {
      cache.remove(user.id, _cacheBucket);
    } else {
      cache.saveMap(user.id, _cacheBucket, insight.toMap());
    }
  }

  Future<void> dismissInsight() async {
    final previousState = state.value;
    state = const AsyncLoading();
    final user = ref.read(currentUserProvider);
    if (user != null) {
      final repo = ref.read(aiInsightRepositoryProvider);
      await repo.deactivateAll(user.id);
      await OfflineCacheService.instance.remove(user.id, _cacheBucket);
      state = const AsyncData(null);
    } else {
      state = AsyncData(previousState);
    }
  }
}

final activeAiInsightProvider =
    AsyncNotifierProvider<ActiveAiInsightNotifier, AiInsight?>(() {
      return ActiveAiInsightNotifier();
    });
