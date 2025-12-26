/// Represents a habit completion log entry for a specific date.
class HabitLogModel {
  final DateTime date;
  final String habitId;
  final bool isCompleted;

  const HabitLogModel({
    required this.date,
    required this.habitId,
    required this.isCompleted,
  });

  HabitLogModel copyWith({
    DateTime? date,
    String? habitId,
    bool? isCompleted,
  }) {
    return HabitLogModel(
      date: date ?? this.date,
      habitId: habitId ?? this.habitId,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  /// Normalizes date to midnight for consistent storage.
  static DateTime normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  Map<String, dynamic> toMap() => {
        'date': normalizeDate(date).millisecondsSinceEpoch,
        'habit_id': habitId,
        'is_completed': isCompleted ? 1 : 0,
      };

  factory HabitLogModel.fromMap(Map<String, dynamic> map) {
    return HabitLogModel(
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      habitId: map['habit_id'] as String,
      isCompleted: (map['is_completed'] as int? ?? 0) == 1,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HabitLogModel &&
        normalizeDate(other.date) == normalizeDate(date) &&
        other.habitId == habitId;
  }

  @override
  int get hashCode => Object.hash(normalizeDate(date), habitId);

  @override
  String toString() =>
      'HabitLogModel(date: $date, habitId: $habitId, completed: $isCompleted)';
}

