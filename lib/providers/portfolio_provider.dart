import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/portfolio_model.dart';
import '../repositories/portfolio_repository.dart';
import 'auth_provider.dart';

final portfolioRepositoryProvider = Provider<PortfolioRepository>((ref) {
  return PortfolioRepository();
});

final portfoliosProvider = FutureProvider<List<Portfolio>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  final repo = ref.watch(portfolioRepositoryProvider);
  return repo.getAll(user.id);
});
