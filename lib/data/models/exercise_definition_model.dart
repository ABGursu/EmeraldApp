class ExerciseDefinition {
  final int id;
  final String name;
  final String? defaultType;
  final String? bodyPart;

  const ExerciseDefinition({
    required this.id,
    required this.name,
    this.defaultType,
    this.bodyPart,
  });

  ExerciseDefinition copyWith({
    int? id,
    String? name,
    String? defaultType,
    String? bodyPart,
  }) {
    return ExerciseDefinition(
      id: id ?? this.id,
      name: name ?? this.name,
      defaultType: defaultType ?? this.defaultType,
      bodyPart: bodyPart ?? this.bodyPart,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'default_type': defaultType,
        'body_part': bodyPart,
      };

  factory ExerciseDefinition.fromMap(Map<String, dynamic> map) {
    return ExerciseDefinition(
      id: map['id'] as int,
      name: map['name'] as String,
      defaultType: map['default_type'] as String?,
      bodyPart: map['body_part'] as String?,
    );
  }
}

