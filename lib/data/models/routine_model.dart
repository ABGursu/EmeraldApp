class Routine {
  final int id;
  final String name;
  final DateTime createdAt;

  const Routine({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  Routine copyWith({
    int? id,
    String? name,
    DateTime? createdAt,
  }) {
    return Routine(
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

  factory Routine.fromMap(Map<String, dynamic> map) {
    return Routine(
      id: map['id'] as int,
      name: map['name'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }
}

