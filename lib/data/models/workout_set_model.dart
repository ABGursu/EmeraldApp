/// Represents a single set within a workout session.
/// This replaces the old WorkoutLog model which aggregated sets.
class WorkoutSetModel {
  final int id;
  final int sessionId;
  final int exerciseId;
  final int setNumber;
  final double? weightKg; // Always stored in KG
  final int reps;
  final double? rir; // Reps In Reserve (optional)
  final int? formRating; // 1-10 scale (optional)
  final String? note;

  const WorkoutSetModel({
    required this.id,
    required this.sessionId,
    required this.exerciseId,
    required this.setNumber,
    this.weightKg,
    required this.reps,
    this.rir,
    this.formRating,
    this.note,
  }) : assert(formRating == null || (formRating >= 1 && formRating <= 10),
            'Form rating must be between 1 and 10 if provided');

  WorkoutSetModel copyWith({
    int? id,
    int? sessionId,
    int? exerciseId,
    int? setNumber,
    double? weightKg,
    int? reps,
    double? rir,
    int? formRating,
    String? note,
  }) {
    return WorkoutSetModel(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      exerciseId: exerciseId ?? this.exerciseId,
      setNumber: setNumber ?? this.setNumber,
      weightKg: weightKg ?? this.weightKg,
      reps: reps ?? this.reps,
      rir: rir ?? this.rir,
      formRating: formRating ?? this.formRating,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'session_id': sessionId,
        'exercise_id': exerciseId,
        'set_number': setNumber,
        'weight_kg': weightKg,
        'reps': reps,
        'rir': rir,
        'form_rating': formRating,
        'note': note,
      };

  factory WorkoutSetModel.fromMap(Map<String, dynamic> map) {
    return WorkoutSetModel(
      id: map['id'] as int,
      sessionId: map['session_id'] as int,
      exerciseId: map['exercise_id'] as int,
      setNumber: map['set_number'] as int,
      weightKg: (map['weight_kg'] as num?)?.toDouble(),
      reps: map['reps'] as int,
      rir: (map['rir'] as num?)?.toDouble(),
      formRating: map['form_rating'] as int?,
      note: map['note'] as String?,
    );
  }

  /// Calculate volume for this set (weight * reps)
  double get volume => (weightKg ?? 0.0) * reps;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkoutSetModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'WorkoutSetModel(id: $id, sessionId: $sessionId, exerciseId: $exerciseId, set: $setNumber, weight: $weightKg kg, reps: $reps)';
}

