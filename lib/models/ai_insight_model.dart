class AiInsight {
  final String? id;
  final String userId;
  final String tipoTarjeta;
  final String titulo;
  final String mensajeCorto;
  final String accionTexto;
  final String icono;
  final bool activa;
  final DateTime? createdAt;

  AiInsight({
    this.id,
    required this.userId,
    required this.tipoTarjeta,
    required this.titulo,
    required this.mensajeCorto,
    required this.accionTexto,
    required this.icono,
    this.activa = true,
    this.createdAt,
  });

  factory AiInsight.fromMap(Map<String, dynamic> map) {
    return AiInsight(
      id: map['id'] as String?,
      userId: map['user_id'] as String? ?? '',
      tipoTarjeta: map['tipo_tarjeta'] as String? ?? '',
      titulo: map['titulo'] as String? ?? '',
      mensajeCorto: map['mensaje_corto'] as String? ?? '',
      accionTexto: map['accion_texto'] as String? ?? 'Revisar progreso',
      icono: map['icono'] as String? ?? 'psychology',
      activa: map['activa'] as bool? ?? true,
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'tipo_tarjeta': tipoTarjeta,
      'titulo': titulo,
      'mensaje_corto': mensajeCorto,
      'accion_texto': accionTexto,
      'icono': icono,
      'activa': activa,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}
