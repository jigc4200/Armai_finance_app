import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ai_insight_model.dart';
import '../services/supabase_service.dart';

class AiInsightRepository {
  final SupabaseClient _client;

  AiInsightRepository() : _client = SupabaseService.instance.client;

  Future<AiInsight?> getActive(String userId) async {
    try {
      final response = await _client
          .from('ai_insights')
          .select()
          .eq('user_id', userId)
          .eq('activa', true)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (response == null) return null;
      return AiInsight.fromMap(response);
    } catch (e) {
      // Graceful catch: if table does not exist or database is unavailable, return null
      debugPrint('AiInsightRepository.getActive: $e');
      return null;
    }
  }

  Future<void> create(AiInsight insight) async {
    try {
      await _client.from('ai_insights').insert(insight.toMap());
    } catch (e) {
      debugPrint('AiInsightRepository.create: $e');
    }
  }

  Future<void> deactivateAll(String userId) async {
    try {
      await _client
          .from('ai_insights')
          .update({'activa': false})
          .eq('user_id', userId);
    } catch (e) {
      debugPrint('AiInsightRepository.deactivateAll: $e');
    }
  }
}
