import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/portfolio_model.dart';
import '../services/supabase_service.dart';

class PortfolioRepository {
  final SupabaseClient _client;

  PortfolioRepository() : _client = SupabaseService.instance.client;

  Future<List<Portfolio>> getAll(String userId) async {
    final response = await _client
        .from('portfolios')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (response as List).map((e) => Portfolio.fromMap(e)).toList();
  }

  Future<Portfolio> create(Portfolio portfolio) async {
    final response = await _client
        .from('portfolios')
        .insert(portfolio.toMap())
        .select()
        .single();
    return Portfolio.fromMap(response);
  }

  Future<Portfolio> update(Portfolio portfolio) async {
    final response = await _client
        .from('portfolios')
        .update(portfolio.toMap())
        .eq('id', portfolio.id!)
        .select()
        .single();
    return Portfolio.fromMap(response);
  }

  Future<void> delete(String id) async {
    await _client.from('portfolios').delete().eq('id', id);
  }
}
