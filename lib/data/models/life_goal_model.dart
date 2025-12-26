/// Represents a life goal that habits can be linked to.
class LifeGoalModel {
  final String id;
  final String title;
  final String? description;
  final bool isArchived;

  const LifeGoalModel({
    required this.id,
    required this.title,
    this.description,
    this.isArchived = false,
  });

  LifeGoalModel copyWith({
    String? id,
    String? title,
    String? description,
    bool? isArchived,
  }) {
    return LifeGoalModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'is_archived': isArchived ? 1 : 0,
      };

  factory LifeGoalModel.fromMap(Map<String, dynamic> map) {
    return LifeGoalModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      isArchived: (map['is_archived'] as int? ?? 0) == 1,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LifeGoalModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'LifeGoalModel(id: $id, title: $title, archived: $isArchived)';
}

