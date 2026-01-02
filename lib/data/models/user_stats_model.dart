class UserStats {
  final int id;
  final double? weight;
  final double? fat;
  final String? measurements;
  final String? style;
  final DateTime updatedAt;

  const UserStats({
    required this.id,
    this.weight,
    this.fat,
    this.measurements,
    this.style,
    required this.updatedAt,
  });

  UserStats copyWith({
    int? id,
    double? weight,
    double? fat,
    String? measurements,
    String? style,
    DateTime? updatedAt,
  }) {
    return UserStats(
      id: id ?? this.id,
      weight: weight ?? this.weight,
      fat: fat ?? this.fat,
      measurements: measurements ?? this.measurements,
      style: style ?? this.style,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'weight': weight,
        'fat': fat,
        'measurements': measurements,
        'style': style,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  factory UserStats.fromMap(Map<String, dynamic> map) {
    return UserStats(
      id: map['id'] as int,
      weight: (map['weight'] as num?)?.toDouble(),
      fat: (map['fat'] as num?)?.toDouble(),
      measurements: map['measurements'] as String?,
      style: map['style'] as String?,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  static UserStats empty() {
    return UserStats(
      id: 1,
      updatedAt: DateTime.now(),
    );
  }
}

