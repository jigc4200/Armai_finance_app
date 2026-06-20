import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ai_insight_model.dart';
import '../repositories/ai_insight_repository.dart';
import 'auth_provider.dart';

final aiInsightRepositoryProvider = Provider<AiInsightRepository>((ref) {
  return AiInsightRepository();
});

class ActiveAiInsightNotifier extends AsyncNotifier<AiInsight?> {
  @override
  Future<AiInsight?> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return null;
    final repo = ref.watch(aiInsightRepositoryProvider);
    return repo.getActive(user.id);
  }

  void updateInsight(AiInsight? insight) {
    state = AsyncData(insight);
  }

  Future<void> dismissInsight() async {
    final previousState = state.value;
    state = const AsyncLoading();
    final user = ref.read(currentUserProvider);
    if (user != null) {
      final repo = ref.read(aiInsightRepositoryProvider);
      await repo.deactivateAll(user.id);
      state = const AsyncData(null);
    } else {
      state = AsyncData(previousState);
    }
  }
}

final activeAiInsightProvider = AsyncNotifierProvider<ActiveAiInsightNotifier, AiInsight?>(() {
  return ActiveAiInsightNotifier();
});
