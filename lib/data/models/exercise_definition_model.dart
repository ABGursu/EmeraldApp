import 'exercise_type.dart';

class ExerciseDefinition {
  final int id;
  final String name;

  /// Legacy/default equipment/type info (e.g. BW, Dumbbell, Barbell)
  final String? defaultType;

  /// High-level body part label (e.g. "Chest", "Leg", "Core")
  final String? bodyPart;

  /// Optional grip description from Excel (e.g. "Supinated", "Neutral", "Wide")
  final String? grip;

  /// Optional style/stance description from Excel (e.g. "Close Stance", "Paused")
  final String? style;

  /// Multi-select exercise type tags (Strength, Balance, etc.)
  final List<String> types;

  final bool isArchived;

  const ExerciseDefinition({
    required this.id,
    required this.name,
    this.defaultType,
    this.bodyPart,
    this.grip,
    this.style,
    this.types = const [],
    this.isArchived = false,
  });

  ExerciseDefinition copyWith({
    int? id,
    String? name,
    String? defaultType,
    String? bodyPart,
    String? grip,
    String? style,
    List<String>? types,
    bool? isArchived,
  }) {
    return ExerciseDefinition(
      id: id ?? this.id,
      name: name ?? this.name,
      defaultType: defaultType ?? this.defaultType,
      bodyPart: bodyPart ?? this.bodyPart,
      grip: grip ?? this.grip,
      style: style ?? this.style,
      types: types ?? this.types,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'default_type': defaultType,
        'body_part': bodyPart,
        'grip': grip,
        'style': style,
        'types': types.isEmpty ? null : ExerciseType.toJsonString(types),
        'is_archived': isArchived ? 1 : 0,
      };

  factory ExerciseDefinition.fromMap(Map<String, dynamic> map) {
    return ExerciseDefinition(
      id: map['id'] as int,
      name: map['name'] as String,
      defaultType: map['default_type'] as String?,
      bodyPart: map['body_part'] as String?,
      grip: map['grip'] as String?,
      style: map['style'] as String?,
      types: ExerciseType.fromJsonString(map['types'] as String?),
      isArchived: (map['is_archived'] as int? ?? 0) == 1,
    );
  }
}

