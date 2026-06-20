class UserProfile {
  final String id;
  final String email;
  final int nivel;
  final int xp;
  final DateTime? createdAt;

  UserProfile({
    required this.id,
    required this.email,
    this.nivel = 1,
    this.xp = 0,
    this.createdAt,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
    id: map['id'] as String,
    email: map['email'] as String,
    nivel: map['nivel'] as int? ?? 1,
    xp: map['xp'] as int? ?? 0,
    createdAt: map['created_at'] != null
        ? DateTime.parse(map['created_at'] as String)
        : null,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'email': email,
    'nivel': nivel,
    'xp': xp,
  };

  String get rango {
    if (nivel >= 20) return 'Magnate';
    if (nivel >= 15) return 'Estratega';
    if (nivel >= 10) return 'Constructor de Patrimonio';
    if (nivel >= 8) return 'Optimizador';
    if (nivel >= 5) return 'Administrador';
    if (nivel >= 3) return 'Rastreador';
    return 'Gastador Novato';
  }

  int get xpParaSiguienteNivel {
    if (nivel < 3) return 500;
    if (nivel < 5) return 1500;
    if (nivel < 8) return 4000;
    if (nivel < 10) return 8000;
    if (nivel < 15) return 20000;
    if (nivel < 20) return 50000;
    return 100000;
  }

  double get progresoXp {
    final max = xpParaSiguienteNivel;
    if (max == 0) return 0.0;
    return (xp / max).clamp(0.0, 1.0);
  }
}
