class CalendarTagModel {
  final String id;
  final String name;
  final int colorValue; // Hex color as integer
  final DateTime createdAt;

  const CalendarTagModel({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.createdAt,
  });

  CalendarTagModel copyWith({
    String? id,
    String? name,
    int? colorValue,
    DateTime? createdAt,
  }) {
    return CalendarTagModel(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'color_value': colorValue,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory CalendarTagModel.fromMap(Map<String, dynamic> map) {
    return CalendarTagModel(
      id: map['id'] as String,
      name: map['name'] as String,
      colorValue: map['color_value'] as int,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }
}

