class RoutineModel {
  final String id;
  final String name;
  final DateTime createdAt;

  const RoutineModel({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  RoutineModel copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
  }) {
    return RoutineModel(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory RoutineModel.fromMap(Map<String, dynamic> map) {
    return RoutineModel(
      id: map['id'] as String,
      name: map['name'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }
}

