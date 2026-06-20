import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/ai_insight_model.dart';

class AgentResponse {
  final String respuesta;
  final AiInsight? insight;

  AgentResponse({required this.respuesta, this.insight});

  factory AgentResponse.fromJson(Map<String, dynamic> json, String userId) {
    final rawInsight = json['insight'];
    AiInsight? insightObj;
    if (rawInsight != null && rawInsight is Map<String, dynamic>) {
      insightObj = AiInsight.fromMap({...rawInsight, 'user_id': userId});
    }
    return AgentResponse(
      respuesta: json['respuesta'] as String? ?? 'No response received',
      insight: insightObj,
    );
  }
}

class AgentService {
  final SupabaseClient _client;

  AgentService() : _client = SupabaseService.instance.client;

  Future<AgentResponse> chat({
    required String mensaje,
    String modo = 'conversacional',
    Map<String, dynamic>? simulacion,
  }) async {
    final body = <String, dynamic>{'mensaje': mensaje, 'modo': modo};
    if (simulacion != null) {
      body['simulacion'] = simulacion;
    }

    final response = await _client.functions.invoke('agente', body: body);

    final userId = _client.auth.currentUser?.id ?? '';
    return AgentResponse.fromJson(
      response.data as Map<String, dynamic>,
      userId,
    );
  }
}
