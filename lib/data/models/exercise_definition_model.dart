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

  /// Style: from Excel, how the exercise is performed (e.g. "Close Stance", "Paused"). Not used for Sports Goals.
  final String? style;

  /// Types: in-app tags (e.g. Strength, Balance). Sports Goals use only types to link and track contributing exercises.
  final List<String> types;

  final bool isArchived;

  /// True if this row was inserted by app seed (Excel prefilled). False for user-created. Used so upgrades only remove pre-installed data.
  final bool isPreinstalled;

  const ExerciseDefinition({
    required this.id,
    required this.name,
    this.defaultType,
    this.bodyPart,
    this.grip,
    this.style,
    this.types = const [],
    this.isArchived = false,
    this.isPreinstalled = false,
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
    bool? isPreinstalled,
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
      isPreinstalled: isPreinstalled ?? this.isPreinstalled,
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
        'is_preinstalled': isPreinstalled ? 1 : 0,
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
      isPreinstalled: (map['is_preinstalled'] as int? ?? 0) == 1,
    );
  }
}

