import 'exercise_type.dart';

class ExerciseDefinition {
  final int id;
  final String name;
  final String? defaultType;
  final String? bodyPart;
  final List<String> types; // Multi-select exercise types
  final bool isArchived;

  const ExerciseDefinition({
    required this.id,
    required this.name,
    this.defaultType,
    this.bodyPart,
    this.types = const [],
    this.isArchived = false,
  });

  ExerciseDefinition copyWith({
    int? id,
    String? name,
    String? defaultType,
    String? bodyPart,
    List<String>? types,
    bool? isArchived,
  }) {
    return ExerciseDefinition(
      id: id ?? this.id,
      name: name ?? this.name,
      defaultType: defaultType ?? this.defaultType,
      bodyPart: bodyPart ?? this.bodyPart,
      types: types ?? this.types,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'default_type': defaultType,
        'body_part': bodyPart,
        'types': types.isEmpty ? null : ExerciseType.toJsonString(types),
        'is_archived': isArchived ? 1 : 0,
      };

  factory ExerciseDefinition.fromMap(Map<String, dynamic> map) {
    return ExerciseDefinition(
      id: map['id'] as int,
      name: map['name'] as String,
      defaultType: map['default_type'] as String?,
      bodyPart: map['body_part'] as String?,
      types: ExerciseType.fromJsonString(map['types'] as String?),
      isArchived: (map['is_archived'] as int? ?? 0) == 1,
    );
  }
}

