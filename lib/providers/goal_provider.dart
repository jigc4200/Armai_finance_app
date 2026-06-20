import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/goal_model.dart';
import '../repositories/goal_repository.dart';
import 'auth_provider.dart';

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  return GoalRepository();
});

class GoalsNotifier extends AsyncNotifier<List<Goal>> {
  @override
  Future<List<Goal>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return [];
    final repo = ref.watch(goalRepositoryProvider);
    return repo.getAll(user.id);
  }

  void updateGoalOptimistically(String goalId, double amountDelta, bool isIncome) {
    final list = state.value;
    if (list == null) return;

    final newList = list.map((g) {
      if (g.id == goalId) {
        final double sign = isIncome ? 1.0 : -1.0;
        final newMontoActual = (g.montoActual + amountDelta * sign).clamp(0.0, double.infinity);
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
