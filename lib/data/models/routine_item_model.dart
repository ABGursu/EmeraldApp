class RoutineItem {
  final int id;
  final int routineId;
  final int exerciseDefinitionId;
  final int targetSets;
  final int targetReps;
  final int orderIndex;
  final String? note;

  const RoutineItem({
    required this.id,
    required this.routineId,
    required this.exerciseDefinitionId,
    required this.targetSets,
    required this.targetReps,
    required this.orderIndex,
    this.note,
  });

  RoutineItem copyWith({
    int? id,
    int? routineId,
    int? exerciseDefinitionId,
    int? targetSets,
    int? targetReps,
    int? orderIndex,
    String? note,
  }) {
    return RoutineItem(
      id: id ?? this.id,
      routineId: routineId ?? this.routineId,
      exerciseDefinitionId: exerciseDefinitionId ?? this.exerciseDefinitionId,
      targetSets: targetSets ?? this.targetSets,
      targetReps: targetReps ?? this.targetReps,
      orderIndex: orderIndex ?? this.orderIndex,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'routine_id': routineId,
        'exercise_definition_id': exerciseDefinitionId,
        'target_sets': targetSets,
        'target_reps': targetReps,
        'order_index': orderIndex,
        'note': note,
      };

  factory RoutineItem.fromMap(Map<String, dynamic> map) {
    return RoutineItem(
      id: map['id'] as int,
      routineId: map['routine_id'] as int,
      exerciseDefinitionId: map['exercise_definition_id'] as int,
      targetSets: map['target_sets'] as int,
      targetReps: map['target_reps'] as int,
      orderIndex: map['order_index'] as int,
      note: map['note'] as String?,
    );
  }
}

