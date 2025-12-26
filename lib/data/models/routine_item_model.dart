class RoutineItemModel {
  final String id;
  final String routineId;
  final String exerciseId;
  final int sets;
  final int reps;
  final double? weight;
  final String? note;

  const RoutineItemModel({
    required this.id,
    required this.routineId,
    required this.exerciseId,
    required this.sets,
    required this.reps,
    this.weight,
    this.note,
  });

  RoutineItemModel copyWith({
    String? id,
    String? routineId,
    String? exerciseId,
    int? sets,
    int? reps,
    double? weight,
    String? note,
  }) {
    return RoutineItemModel(
      id: id ?? this.id,
      routineId: routineId ?? this.routineId,
      exerciseId: exerciseId ?? this.exerciseId,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'routine_id': routineId,
        'exercise_id': exerciseId,
        'sets': sets,
        'reps': reps,
        'weight': weight,
        'note': note,
      };

  factory RoutineItemModel.fromMap(Map<String, dynamic> map) {
    return RoutineItemModel(
      id: map['id'] as String,
      routineId: map['routine_id'] as String,
      exerciseId: map['exercise_id'] as String,
      sets: map['sets'] as int,
      reps: map['reps'] as int,
      weight: (map['weight'] as num?)?.toDouble(),
      note: map['note'] as String?,
    );
  }
}

