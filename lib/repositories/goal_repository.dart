import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/goal_model.dart';
import '../services/supabase_service.dart';

class GoalRepository {
  final SupabaseClient _client;

  GoalRepository() : _client = SupabaseService.instance.client;

  Future<List<Goal>> getAll(String userId) async {
    final response = await _client
        .from('goals')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (response as List).map((e) => Goal.fromMap(e)).toList();
  }

  Future<Goal> create(Goal goal) async {
    final response = await _client
        .from('goals')
        .insert(goal.toMap())
        .select()
        .single();
    return Goal.fromMap(response);
  }

  Future<Goal> update(Goal goal) async {
    final response = await _client
        .from('goals')
        .update(goal.toMap())
        .eq('id', goal.id!)
        .select()
        .single();
    return Goal.fromMap(response);
  }

  Future<void> delete(String id) async {
    await _client
        .from('transactions')
        .update({'meta_id': null})
        .eq('meta_id', id);
    await _client.from('goals').delete().eq('id', id);
  }
}
