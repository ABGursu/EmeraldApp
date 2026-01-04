/// Represents a training goal (e.g., "Capoeira Prep", "Marathon Training").
class SportifGoalModel {
  final int id;
  final String name;
  final String? description;
  final bool isArchived;
  final DateTime createdAt;

  const SportifGoalModel({
    required this.id,
    required this.name,
    this.description,
    this.isArchived = false,
    required this.createdAt,
  });

  SportifGoalModel copyWith({
    int? id,
    String? name,
    String? description,
    bool? isArchived,
    DateTime? createdAt,
  }) {
    return SportifGoalModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'is_archived': isArchived ? 1 : 0,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory SportifGoalModel.fromMap(Map<String, dynamic> map) {
    return SportifGoalModel(
      id: map['id'] as int,
      name: map['name'] as String,
      description: map['description'] as String?,
      isArchived: (map['is_archived'] as int? ?? 0) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SportifGoalModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'SportifGoalModel(id: $id, name: $name, archived: $isArchived)';
}

