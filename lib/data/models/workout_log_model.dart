import '../../utils/date_formats.dart';

class WorkoutLog {
  final int id;
  final DateTime date;
  final String exerciseName;
  final String? exerciseType;
  final int sets;
  final int reps;
  final double? weight;
  final String? note;
  final int orderIndex;
  final bool isCompleted;

  const WorkoutLog({
    required this.id,
    required this.date,
    required this.exerciseName,
    this.exerciseType,
    required this.sets,
    required this.reps,
    this.weight,
    this.note,
    required this.orderIndex,
    this.isCompleted = false,
  });

  WorkoutLog copyWith({
    int? id,
    DateTime? date,
    String? exerciseName,
    String? exerciseType,
    int? sets,
    int? reps,
    double? weight,
    String? note,
    int? orderIndex,
    bool? isCompleted,
  }) {
    return WorkoutLog(
      id: id ?? this.id,
      date: date ?? this.date,
      exerciseName: exerciseName ?? this.exerciseName,
      exerciseType: exerciseType ?? this.exerciseType,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      note: note ?? this.note,
      orderIndex: orderIndex ?? this.orderIndex,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date.millisecondsSinceEpoch,
        'exercise_name': exerciseName,
        'exercise_type': exerciseType,
        'sets': sets,
        'reps': reps,
        'weight': weight,
        'note': note,
        'order_index': orderIndex,
        'is_completed': isCompleted ? 1 : 0,
      };

  factory WorkoutLog.fromMap(Map<String, dynamic> map) {
    return WorkoutLog(
      id: map['id'] as int,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      exerciseName: map['exercise_name'] as String,
      exerciseType: map['exercise_type'] as String?,
      sets: map['sets'] as int,
      reps: map['reps'] as int,
      weight: (map['weight'] as num?)?.toDouble(),
      note: map['note'] as String?,
      orderIndex: map['order_index'] as int,
      isCompleted: (map['is_completed'] as int) == 1,
    );
  }

  /// Custom text output: "[dd.MM.yyyy], [Name] [Sets]x[Reps] [Weight]"
  String toLogString() {
    final dateStr = formatDate(date);
    final weightStr = weight != null ? ' ${weight}kg' : '';
    return '$dateStr, $exerciseName ${sets}x$reps$weightStr';
  }
}
