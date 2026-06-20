import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/goal_model.dart';
import '../repositories/goal_repository.dart';
import '../services/offline_cache_service.dart';
import 'auth_provider.dart';

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  return GoalRepository();
});

class GoalsNotifier extends AsyncNotifier<List<Goal>> {
  static const _cacheBucket = 'goals';

  @override
  Future<List<Goal>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return [];

    final cache = OfflineCacheService.instance;
    final cached = await cache.readList(user.id, _cacheBucket);
    final cachedGoals = cached?.map(Goal.fromMap).toList();
    if (cachedGoals != null) {
      state = AsyncData(cachedGoals);
    }

    final repo = ref.watch(goalRepositoryProvider);
    try {
      final fresh = await repo.getAll(user.id);
      await cache.saveList(
        user.id,
        _cacheBucket,
        fresh.map((goal) => goal.toMap()).toList(),
      );
      return fresh;
    } catch (error, stackTrace) {
      if (cachedGoals != null) return cachedGoals;
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  void updateGoalOptimistically(
    String goalId,
    double amountDelta,
    bool isIncome,
  ) {
    final list = state.value;
    if (list == null) return;

    final newList = list.map((g) {
      if (g.id == goalId) {
        final double sign = isIncome ? 1.0 : -1.0;
        final newMontoActual = (g.montoActual + amountDelta * sign).clamp(
          0.0,
          double.infinity,
        );
        return g.copyWith(
          montoActual: newMontoActual,
          completada: newMontoActual >= g.montoObjetivo,
        );
      }
      return g;
    }).toList();

    state = AsyncData(newList);
  }
}

final goalsProvider = AsyncNotifierProvider<GoalsNotifier, List<Goal>>(() {
  return GoalsNotifier();
});
