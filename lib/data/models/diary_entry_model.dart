class DiaryEntryModel {
  final DateTime date; // Unique per day (only date part, time is ignored)
  final String content; // Rich Text / HTML / Markdown
  final DateTime updatedAt;

  const DiaryEntryModel({
    required this.date,
    required this.content,
    required this.updatedAt,
  });

  DiaryEntryModel copyWith({
    DateTime? date,
    String? content,
    DateTime? updatedAt,
  }) {
    return DiaryEntryModel(
      date: date ?? this.date,
      content: content ?? this.content,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'date': date.millisecondsSinceEpoch,
        'content': content,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  factory DiaryEntryModel.fromMap(Map<String, dynamic> map) {
    return DiaryEntryModel(
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      content: map['content'] as String,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  // Helper to get date without time
  DateTime get dateOnly => DateTime(date.year, date.month, date.day);
}

