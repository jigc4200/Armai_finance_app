import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/transaction_model.dart';
import '../services/supabase_service.dart';

class TransactionRepository {
  final SupabaseClient _client;

  TransactionRepository() : _client = SupabaseService.instance.client;

  Future<List<Transaction>> getAll(String userId) async {
    final response = await _client
        .from('transactions')
        .select()
        .eq('user_id', userId)
        .order('fecha', ascending: false);
    return (response as List).map((e) => Transaction.fromMap(e)).toList();
  }

  Future<List<Transaction>> getRecent(String userId, {int limit = 30}) async {
    final response = await _client
        .from('transactions')
        .select()
        .eq('user_id', userId)
        .order('fecha', ascending: false)
        .limit(limit);
    return (response as List).map((e) => Transaction.fromMap(e)).toList();
  }

  Future<Transaction> create(Transaction transaction) async {
    final response = await _client
        .from('transactions')
        .insert(transaction.toMap())
        .select()
        .single();
    return Transaction.fromMap(response);
  }

  Future<Transaction> update(Transaction transaction) async {
    final response = await _client
        .from('transactions')
        .update(transaction.toMap())
        .eq('id', transaction.id!)
        .select()
        .single();
    return Transaction.fromMap(response);
  }

  Future<void> delete(String id) async {
    await _client.from('transactions').delete().eq('id', id);
  }
}
