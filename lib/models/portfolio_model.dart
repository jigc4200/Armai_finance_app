class Portfolio {
  final String? id;
  final String userId;
  final String nombre;
  final String tipo;
  final double totalInvertido;
  final double totalRetorno;
  final double roiCalculado;
  final bool activa;
  final DateTime? createdAt;

  Portfolio({
    this.id,
    required this.userId,
    required this.nombre,
    required this.tipo,
    this.totalInvertido = 0,
    this.totalRetorno = 0,
    this.roiCalculado = 0,
    this.activa = true,
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'user_id': userId,
    'nombre': nombre,
    'tipo': tipo,
    'total_invertido': totalInvertido,
    'total_retorno': totalRetorno,
    'roi_calculado': roiCalculado,
    'activa': activa,
  };

  factory Portfolio.fromMap(Map<String, dynamic> map) => Portfolio(
    id: map['id'] as String?,
    userId: map['user_id'] as String,
    nombre: map['nombre'] as String,
    tipo: map['tipo'] as String,
    totalInvertido: (map['total_invertido'] as num?)?.toDouble() ?? 0,
    totalRetorno: (map['total_retorno'] as num?)?.toDouble() ?? 0,
    roiCalculado: (map['roi_calculado'] as num?)?.toDouble() ?? 0,
    activa: map['activa'] as bool? ?? true,
    createdAt: map['created_at'] != null
        ? DateTime.parse(map['created_at'] as String)
        : null,
  );

  Portfolio copyWith({
    double? totalInvertido,
    double? totalRetorno,
    double? roiCalculado,
    bool? activa,
  }) => Portfolio(
    id: id,
    userId: userId,
    nombre: nombre,
    tipo: tipo,
    totalInvertido: totalInvertido ?? this.totalInvertido,
    totalRetorno: totalRetorno ?? this.totalRetorno,
    roiCalculado: roiCalculado ?? this.roiCalculado,
    activa: activa ?? this.activa,
  );
}
