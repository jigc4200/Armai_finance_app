import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction_model.dart';
import '../repositories/transaction_repository.dart';
import '../services/offline_cache_service.dart';
import 'auth_provider.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository();
});

class TransactionsNotifier extends AsyncNotifier<List<Transaction>> {
  static const _cacheBucket = 'transactions.all';

  @override
  Future<List<Transaction>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return [];

    final cache = OfflineCacheService.instance;
    final cached = await cache.readList(user.id, _cacheBucket);
    final cachedTransactions = cached?.map(Transaction.fromMap).toList();
    if (cachedTransactions != null) {
      state = AsyncData(cachedTransactions);
    }

    final repo = ref.watch(transactionRepositoryProvider);
    try {
      final fresh = await repo.getAll(user.id);
      await cache.saveList(
        user.id,
        _cacheBucket,
        fresh.map((tx) => tx.toMap()).toList(),
      );
      return fresh;
    } catch (error, stackTrace) {
      if (cachedTransactions != null) return cachedTransactions;
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  void addOptimistic(Transaction tx) {
    final list = state.value ?? [];
    state = AsyncData([tx, ...list]);
  }
}

final transactionsProvider =
    AsyncNotifierProvider<TransactionsNotifier, List<Transaction>>(() {
      return TransactionsNotifier();
    });

class RecentTransactionsNotifier extends AsyncNotifier<List<Transaction>> {
  static const _cacheBucket = 'transactions.recent';

  @override
  Future<List<Transaction>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return [];

    final cache = OfflineCacheService.instance;
    final cached = await cache.readList(user.id, _cacheBucket);
    final cachedTransactions = cached?.map(Transaction.fromMap).toList();
    if (cachedTransactions != null) {
      state = AsyncData(cachedTransactions);
    }

    final repo = ref.watch(transactionRepositoryProvider);
    try {
      final fresh = await repo.getRecent(user.id);
      await cache.saveList(
        user.id,
        _cacheBucket,
        fresh.map((tx) => tx.toMap()).toList(),
      );
      return fresh;
    } catch (error, stackTrace) {
      if (cachedTransactions != null) return cachedTransactions;
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  void addOptimistic(Transaction tx) {
    final list = state.value ?? [];
    state = AsyncData([tx, ...list]);
  }
}

final recentTransactionsProvider =
    AsyncNotifierProvider<RecentTransactionsNotifier, List<Transaction>>(() {
      return RecentTransactionsNotifier();
    });
