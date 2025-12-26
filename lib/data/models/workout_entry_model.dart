class WorkoutEntryModel {
  final String id;
  final String sessionId;
  final String exerciseId;
  final int sets;
  final int reps;
  final double? weight;
  final String? note;

  const WorkoutEntryModel({
    required this.id,
    required this.sessionId,
    required this.exerciseId,
    required this.sets,
    required this.reps,
    this.weight,
    this.note,
  });

  WorkoutEntryModel copyWith({
    String? id,
    String? sessionId,
    String? exerciseId,
    int? sets,
    int? reps,
    double? weight,
    String? note,
  }) {
    return WorkoutEntryModel(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      exerciseId: exerciseId ?? this.exerciseId,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'session_id': sessionId,
        'exercise_id': exerciseId,
        'sets': sets,
        'reps': reps,
        'weight': weight,
        'note': note,
      };

  factory WorkoutEntryModel.fromMap(Map<String, dynamic> map) {
    return WorkoutEntryModel(
      id: map['id'] as String,
      sessionId: map['session_id'] as String,
      exerciseId: map['exercise_id'] as String,
      sets: map['sets'] as int,
      reps: map['reps'] as int,
      weight: (map['weight'] as num?)?.toDouble(),
      note: map['note'] as String?,
    );
  }
}

