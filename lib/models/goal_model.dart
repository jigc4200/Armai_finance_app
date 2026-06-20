class Goal {
  final String? id;
  final String userId;
  final String nombre;
  final double montoObjetivo;
  final double montoActual;
  final DateTime fechaObjetivo;
  final bool completada;
  final DateTime? createdAt;

  Goal({
    this.id,
    required this.userId,
    required this.nombre,
    required this.montoObjetivo,
    this.montoActual = 0,
    required this.fechaObjetivo,
    this.completada = false,
    this.createdAt,
  });

  double get progreso =>
      montoObjetivo > 0 ? (montoActual / montoObjetivo).clamp(0, 1) : 0;

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'user_id': userId,
        'nombre': nombre,
        'monto_objetivo': montoObjetivo,
        'monto_actual': montoActual,
        'fecha_objetivo': fechaObjetivo.toIso8601String(),
        'completada': completada,
      };

  factory Goal.fromMap(Map<String, dynamic> map) => Goal(
        id: map['id'] as String?,
        userId: map['user_id'] as String,
        nombre: map['nombre'] as String,
        montoObjetivo: (map['monto_objetivo'] as num).toDouble(),
        montoActual: (map['monto_actual'] as num?)?.toDouble() ?? 0,
        fechaObjetivo: DateTime.parse(map['fecha_objetivo'] as String),
        completada: map['completada'] as bool? ?? false,
        createdAt: map['created_at'] != null
            ? DateTime.parse(map['created_at'] as String)
            : null,
      );

  Goal copyWith({
    String? id,
    String? userId,
    String? nombre,
    double? montoObjetivo,
    double? montoActual,
    DateTime? fechaObjetivo,
    bool? completada,
    DateTime? createdAt,
  }) => Goal(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    nombre: nombre ?? this.nombre,
    montoObjetivo: montoObjetivo ?? this.montoObjetivo,
    montoActual: montoActual ?? this.montoActual,
    fechaObjetivo: fechaObjetivo ?? this.fechaObjetivo,
    completada: completada ?? this.completada,
    createdAt: createdAt ?? this.createdAt,
  );
}
