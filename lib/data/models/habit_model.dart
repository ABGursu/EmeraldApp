import 'habit_type.dart';

/// Represents a habit that can be linked to a life goal.
class HabitModel {
  final String id;
  final String? goalId;
  final String title;
  final int colorValue;
  final bool isArchived;
  final HabitType type;

  const HabitModel({
    required this.id,
    this.goalId,
    required this.title,
    required this.colorValue,
    this.isArchived = false,
    this.type = HabitType.positive,
  });

  HabitModel copyWith({
    String? id,
    String? goalId,
    bool clearGoalId = false,
    String? title,
    int? colorValue,
    bool? isArchived,
    HabitType? type,
  }) {
    return HabitModel(
      id: id ?? this.id,
      goalId: clearGoalId ? null : (goalId ?? this.goalId),
      title: title ?? this.title,
      colorValue: colorValue ?? this.colorValue,
      isArchived: isArchived ?? this.isArchived,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'goal_id': goalId,
        'title': title,
        'color_value': colorValue,
        'is_archived': isArchived ? 1 : 0,
        'type': type.toDbString(),
      };

  factory HabitModel.fromMap(Map<String, dynamic> map) {
    return HabitModel(
      id: map['id'] as String,
      goalId: map['goal_id'] as String?,
      title: map['title'] as String,
      colorValue: map['color_value'] as int,
      isArchived: (map['is_archived'] as int? ?? 0) == 1,
      type: map['type'] != null
          ? HabitType.fromDbString(map['type'] as String)
          : HabitType.positive, // Default for backward compatibility
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HabitModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'HabitModel(id: $id, title: $title, goalId: $goalId, color: $colorValue, type: ${type.toDbString()})';
}

