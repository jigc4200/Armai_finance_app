import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/portfolio_model.dart';
import '../repositories/portfolio_repository.dart';
import '../services/offline_cache_service.dart';
import 'auth_provider.dart';

final portfolioRepositoryProvider = Provider<PortfolioRepository>((ref) {
  return PortfolioRepository();
});

class PortfoliosNotifier extends AsyncNotifier<List<Portfolio>> {
  static const _cacheBucket = 'portfolios';

  @override
  Future<List<Portfolio>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return [];

    final cache = OfflineCacheService.instance;
    final cached = await cache.readList(user.id, _cacheBucket);
    final cachedPortfolios = cached?.map(Portfolio.fromMap).toList();
    if (cachedPortfolios != null) {
      state = AsyncData(cachedPortfolios);
    }

    final repo = ref.watch(portfolioRepositoryProvider);
    try {
      final fresh = await repo.getAll(user.id);
      await cache.saveList(
        user.id,
        _cacheBucket,
        fresh.map((portfolio) => portfolio.toMap()).toList(),
      );
      return fresh;
    } catch (error, stackTrace) {
      if (cachedPortfolios != null) return cachedPortfolios;
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}

final portfoliosProvider =
    AsyncNotifierProvider<PortfoliosNotifier, List<Portfolio>>(() {
      return PortfoliosNotifier();
    });
