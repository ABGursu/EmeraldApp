/// Represents a daily satisfaction rating and note.
class DailyRatingModel {
  final DateTime date;
  final int score;
  final String? note;

  const DailyRatingModel({
    required this.date,
    required this.score,
    this.note,
  });

  DailyRatingModel copyWith({
    DateTime? date,
    int? score,
    String? note,
  }) {
    return DailyRatingModel(
      date: date ?? this.date,
      score: score ?? this.score,
      note: note ?? this.note,
    );
  }

  /// Normalizes date to midnight for consistent storage.
  static DateTime normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  Map<String, dynamic> toMap() => {
        'date': normalizeDate(date).millisecondsSinceEpoch,
        'score': score,
        'note': note,
      };

  factory DailyRatingModel.fromMap(Map<String, dynamic> map) {
    return DailyRatingModel(
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      score: map['score'] as int,
      note: map['note'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DailyRatingModel &&
        normalizeDate(other.date) == normalizeDate(date);
  }

  @override
  int get hashCode => normalizeDate(date).hashCode;

  @override
  String toString() =>
      'DailyRatingModel(date: $date, score: $score, note: $note)';
}

