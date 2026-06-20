import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction_model.dart';
import '../repositories/transaction_repository.dart';
import 'auth_provider.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository();
});

class TransactionsNotifier extends AsyncNotifier<List<Transaction>> {
  @override
  Future<List<Transaction>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return [];
    final repo = ref.watch(transactionRepositoryProvider);
    return repo.getAll(user.id);
  }

  void addOptimistic(Transaction tx) {
    final list = state.value ?? [];
    state = AsyncData([tx, ...list]);
  }
}

final transactionsProvider = AsyncNotifierProvider<TransactionsNotifier, List<Transaction>>(() {
  return TransactionsNotifier();
});

class RecentTransactionsNotifier extends AsyncNotifier<List<Transaction>> {
  @override
  Future<List<Transaction>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return [];
    final repo = ref.watch(transactionRepositoryProvider);
    return repo.getRecent(user.id);
  }

  void addOptimistic(Transaction tx) {
    final list = state.value ?? [];
    state = AsyncData([tx, ...list]);
  }
}

final recentTransactionsProvider = AsyncNotifierProvider<RecentTransactionsNotifier, List<Transaction>>(() {
  return RecentTransactionsNotifier();
});
