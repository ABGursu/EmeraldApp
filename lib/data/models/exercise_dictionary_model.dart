class ExerciseDictionaryModel {
  final String id;
  final String name;
  final String? muscleGroup;
  final int colorValue;
  final DateTime createdAt;

  const ExerciseDictionaryModel({
    required this.id,
    required this.name,
    this.muscleGroup,
    required this.colorValue,
    required this.createdAt,
  });

  ExerciseDictionaryModel copyWith({
    String? id,
    String? name,
    String? muscleGroup,
    int? colorValue,
    DateTime? createdAt,
  }) {
    return ExerciseDictionaryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'muscle_group': muscleGroup,
        'color_value': colorValue,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory ExerciseDictionaryModel.fromMap(Map<String, dynamic> map) {
    return ExerciseDictionaryModel(
      id: map['id'] as String,
      name: map['name'] as String,
      muscleGroup: map['muscle_group'] as String?,
      colorValue: map['color_value'] as int,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }
}

