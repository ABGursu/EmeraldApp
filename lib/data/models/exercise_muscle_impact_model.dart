/// Represents the impact relationship between an exercise and a specific muscle.
/// This is the core of the Bio-Mechanic Engine.
class ExerciseMuscleImpactModel {
  final int exerciseId;
  final int muscleId;
  final int impactScore; // 1-10 scale

  const ExerciseMuscleImpactModel({
    required this.exerciseId,
    required this.muscleId,
    required this.impactScore,
  }) : assert(impactScore >= 1 && impactScore <= 10,
            'Impact score must be between 1 and 10');

  ExerciseMuscleImpactModel copyWith({
    int? exerciseId,
    int? muscleId,
    int? impactScore,
  }) {
    return ExerciseMuscleImpactModel(
      exerciseId: exerciseId ?? this.exerciseId,
      muscleId: muscleId ?? this.muscleId,
      impactScore: impactScore ?? this.impactScore,
    );
  }

  Map<String, dynamic> toMap() => {
        'exercise_id': exerciseId,
        'muscle_id': muscleId,
        'impact_score': impactScore,
      };

  factory ExerciseMuscleImpactModel.fromMap(Map<String, dynamic> map) {
    return ExerciseMuscleImpactModel(
      exerciseId: map['exercise_id'] as int,
      muscleId: map['muscle_id'] as int,
      impactScore: map['impact_score'] as int,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExerciseMuscleImpactModel &&
        other.exerciseId == exerciseId &&
        other.muscleId == muscleId;
  }

  @override
  int get hashCode => Object.hash(exerciseId, muscleId);

  @override
  String toString() =>
      'ExerciseMuscleImpactModel(exerciseId: $exerciseId, muscleId: $muscleId, score: $impactScore)';
}

