/// Represents a workout session (container for sets performed on a specific day/time).
class WorkoutSessionModel {
  final int id;
  final DateTime date;
  final DateTime? startTime;
  final String? title;
  final int? durationMinutes;
  final int? rating; // 1-10 scale
  final List<String> goalTags; // e.g., ["Hypertrophy Phase", "Capoeira Prep"]
  final DateTime createdAt;

  const WorkoutSessionModel({
    required this.id,
    required this.date,
    this.startTime,
    this.title,
    this.durationMinutes,
    this.rating,
    this.goalTags = const [],
    required this.createdAt,
  }) : assert(rating == null || (rating >= 1 && rating <= 10),
            'Rating must be between 1 and 10 if provided');

  WorkoutSessionModel copyWith({
    int? id,
    DateTime? date,
    DateTime? startTime,
    String? title,
    int? durationMinutes,
    int? rating,
    List<String>? goalTags,
    DateTime? createdAt,
  }) {
    return WorkoutSessionModel(
      id: id ?? this.id,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      title: title ?? this.title,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      rating: rating ?? this.rating,
      goalTags: goalTags ?? this.goalTags,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date.millisecondsSinceEpoch,
        'start_time': startTime?.millisecondsSinceEpoch,
        'title': title,
        'duration_minutes': durationMinutes,
        'rating': rating,
        'goal_tags': goalTags.isEmpty ? null : goalTags.join(','),
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory WorkoutSessionModel.fromMap(Map<String, dynamic> map) {
    final goalTagsStr = map['goal_tags'] as String?;
    return WorkoutSessionModel(
      id: map['id'] as int,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      startTime: map['start_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['start_time'] as int)
          : null,
      title: map['title'] as String?,
      durationMinutes: map['duration_minutes'] as int?,
      rating: map['rating'] as int?,
      goalTags: goalTagsStr != null && goalTagsStr.isNotEmpty
          ? goalTagsStr.split(',').map((s) => s.trim()).toList()
          : [],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  /// Helper to get date without time component
  DateTime get dateOnly => DateTime(date.year, date.month, date.day);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkoutSessionModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'WorkoutSessionModel(id: $id, date: $date, title: $title, rating: $rating)';
}

