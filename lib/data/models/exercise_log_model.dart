import '../../utils/date_formats.dart';

class ExerciseLog {
  final int id;
  final DateTime date;
  final String? movementType;
  final String movementName;
  final int sets;
  final int reps;
  final double? weight;
  final String? workoutNotes;

  const ExerciseLog({
    required this.id,
    required this.date,
    this.movementType,
    required this.movementName,
    required this.sets,
    required this.reps,
    this.weight,
    this.workoutNotes,
  });

  ExerciseLog copyWith({
    int? id,
    DateTime? date,
    String? movementType,
    String? movementName,
    int? sets,
    int? reps,
    double? weight,
    String? workoutNotes,
  }) {
    return ExerciseLog(
      id: id ?? this.id,
      date: date ?? this.date,
      movementType: movementType ?? this.movementType,
      movementName: movementName ?? this.movementName,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      workoutNotes: workoutNotes ?? this.workoutNotes,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date.millisecondsSinceEpoch,
        'movement_type': movementType,
        'movement_name': movementName,
        'sets': sets,
        'reps': reps,
        'weight': weight,
        'workout_notes': workoutNotes,
      };

  factory ExerciseLog.fromMap(Map<String, dynamic> map) {
    return ExerciseLog(
      id: map['id'] as int,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      movementType: map['movement_type'] as String?,
      movementName: map['movement_name'] as String,
      sets: map['sets'] as int,
      reps: map['reps'] as int,
      weight: (map['weight'] as num?)?.toDouble(),
      workoutNotes: map['workout_notes'] as String?,
    );
  }

  /// Custom text output: "[dd.MM.yyyy HH:mm], [Movement Type] [Movement Name] [Sets]x[Reps] [Weight]"
  String toLogString() {
    final dateStr = formatDateTime(date);
    final typeStr = movementType != null ? '$movementType ' : '';
    final weightStr = weight != null ? ' ${weight}kg' : '';
    return '$dateStr, $typeStr$movementName ${sets}x$reps$weightStr';
  }
}
