import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class ParsedReceipt {
  final double? monto;
  final String? fecha;
  final String? comercio;
  final String? categoria;
  final String tipo;

  ParsedReceipt({
    this.monto,
    this.fecha,
    this.comercio,
    this.categoria,
    this.tipo = 'gasto',
  });

  factory ParsedReceipt.fromJson(Map<String, dynamic> json) => ParsedReceipt(
    monto: (json['monto'] as num?)?.toDouble(),
    fecha: json['fecha'] as String?,
    comercio: json['comercio'] as String?,
    categoria: json['categoria'] as String?,
    tipo: json['tipo'] as String? ?? 'gasto',
  );
}

class ReceiptParserService {
  final SupabaseClient _client;

  ReceiptParserService() : _client = SupabaseService.instance.client;

  Future<ParsedReceipt> parseText(String rawText) async {
    try {
      final response = await _client.functions.invoke(
        'parse-receipt',
        body: {'rawText': rawText},
      );

      if (response.data != null) {
        return ParsedReceipt.fromJson(response.data as Map<String, dynamic>);
      }
    } catch (_) {}

    return ParsedReceipt();
  }
}
