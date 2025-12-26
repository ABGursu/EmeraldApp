class WorkoutSessionModel {
  final String id;
  final DateTime date;
  final double? userWeight;
  final double? userFat;
  final String? measurements;
  final String? note;

  const WorkoutSessionModel({
    required this.id,
    required this.date,
    this.userWeight,
    this.userFat,
    this.measurements,
    this.note,
  });

  WorkoutSessionModel copyWith({
    String? id,
    DateTime? date,
    double? userWeight,
    double? userFat,
    String? measurements,
    String? note,
  }) {
    return WorkoutSessionModel(
      id: id ?? this.id,
      date: date ?? this.date,
      userWeight: userWeight ?? this.userWeight,
      userFat: userFat ?? this.userFat,
      measurements: measurements ?? this.measurements,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date.millisecondsSinceEpoch,
        'user_weight': userWeight,
        'user_fat': userFat,
        'measurements': measurements,
        'note': note,
      };

  factory WorkoutSessionModel.fromMap(Map<String, dynamic> map) {
    return WorkoutSessionModel(
      id: map['id'] as String,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      userWeight: (map['user_weight'] as num?)?.toDouble(),
      userFat: (map['user_fat'] as num?)?.toDouble(),
      measurements: map['measurements'] as String?,
      note: map['note'] as String?,
    );
  }
}

