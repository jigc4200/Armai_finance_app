class Transaction {
  final String? id;
  final String userId;
  final double monto;
  final String tipo;
  final String categoria;
  final String? carteraId;
  final String descripcion;
  final DateTime fecha;
  final String fuente;
  final String? imagenUrl;
  final String? metaId;
  final DateTime? createdAt;

  Transaction({
    this.id,
    required this.userId,
    required this.monto,
    required this.tipo,
    required this.categoria,
    this.carteraId,
    required this.descripcion,
    required this.fecha,
    this.fuente = 'manual',
    this.imagenUrl,
    this.metaId,
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'user_id': userId,
        'monto': monto,
        'tipo': tipo,
        'categoria': categoria,
        'cartera_id': carteraId,
        'descripcion': descripcion,
        'fecha': fecha.toIso8601String(),
        'fuente': fuente,
        'imagen_url': imagenUrl,
        'meta_id': metaId,
      };

  factory Transaction.fromMap(Map<String, dynamic> map) => Transaction(
        id: map['id'] as String?,
        userId: map['user_id'] as String,
        monto: (map['monto'] as num).toDouble(),
        tipo: map['tipo'] as String,
        categoria: map['categoria'] as String,
        carteraId: map['cartera_id'] as String?,
        descripcion: map['descripcion'] as String,
        fecha: DateTime.parse(map['fecha'] as String),
        fuente: map['fuente'] as String? ?? 'manual',
        imagenUrl: map['imagen_url'] as String?,
        metaId: map['meta_id'] as String?,
        createdAt: map['created_at'] != null
            ? DateTime.parse(map['created_at'] as String)
            : null,
      );

  Transaction copyWith({
    String? id,
    String? userId,
    double? monto,
    String? tipo,
    String? categoria,
    String? carteraId,
    String? descripcion,
    DateTime? fecha,
    String? fuente,
    String? imagenUrl,
    String? metaId,
  }) =>
      Transaction(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        monto: monto ?? this.monto,
        tipo: tipo ?? this.tipo,
        categoria: categoria ?? this.categoria,
        carteraId: carteraId ?? this.carteraId,
        descripcion: descripcion ?? this.descripcion,
        fecha: fecha ?? this.fecha,
        fuente: fuente ?? this.fuente,
        imagenUrl: imagenUrl ?? this.imagenUrl,
        metaId: metaId ?? this.metaId,
      );
}
