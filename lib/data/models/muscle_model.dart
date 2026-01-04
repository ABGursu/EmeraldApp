/// Represents an anatomical muscle in the reference database.
class MuscleModel {
  final int id;
  final String name;
  final String groupName;

  const MuscleModel({
    required this.id,
    required this.name,
    required this.groupName,
  });

  MuscleModel copyWith({
    int? id,
    String? name,
    String? groupName,
  }) {
    return MuscleModel(
      id: id ?? this.id,
      name: name ?? this.name,
      groupName: groupName ?? this.groupName,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'group_name': groupName,
      };

  factory MuscleModel.fromMap(Map<String, dynamic> map) {
    return MuscleModel(
      id: map['id'] as int,
      name: map['name'] as String,
      groupName: map['group_name'] as String,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MuscleModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'MuscleModel(id: $id, name: $name, group: $groupName)';
}

