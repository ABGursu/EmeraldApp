/// Represents a training goal (e.g., "Capoeira Prep", "Marathon Training").
class SportifGoalModel {
  final int id;
  final String name;
  final String? description;
  final bool isArchived;
  final DateTime createdAt;
  final List<String> styles;
  final List<String> types;

  const SportifGoalModel({
    required this.id,
    required this.name,
    this.description,
    this.isArchived = false,
    required this.createdAt,
    this.styles = const [],
    this.types = const [],
  });

  SportifGoalModel copyWith({
    int? id,
    String? name,
    String? description,
    bool? isArchived,
    DateTime? createdAt,
    List<String>? styles,
    List<String>? types,
  }) {
    return SportifGoalModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      styles: styles ?? this.styles,
      types: types ?? this.types,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'is_archived': isArchived ? 1 : 0,
        'created_at': createdAt.millisecondsSinceEpoch,
        'styles': styles.isEmpty ? null : styles.join(','),
        'types': types.isEmpty ? null : types.join(','),
      };

  factory SportifGoalModel.fromMap(Map<String, dynamic> map) {
    final stylesStr = map['styles'] as String?;
    final typesStr = map['types'] as String?;
    return SportifGoalModel(
      id: map['id'] as int,
      name: map['name'] as String,
      description: map['description'] as String?,
      isArchived: (map['is_archived'] as int? ?? 0) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      styles: stylesStr != null && stylesStr.isNotEmpty
          ? stylesStr.split(',').map((s) => s.trim()).toList()
          : const [],
      types: typesStr != null && typesStr.isNotEmpty
          ? typesStr.split(',').map((s) => s.trim()).toList()
          : const [],
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
