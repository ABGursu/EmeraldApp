/// Represents an ingredient in the library (master list).
class IngredientModel {
  final String id;
  final String name;
  final String defaultUnit;

  const IngredientModel({
    required this.id,
    required this.name,
    required this.defaultUnit,
  });

  IngredientModel copyWith({
    String? id,
    String? name,
    String? defaultUnit,
  }) {
    return IngredientModel(
      id: id ?? this.id,
      name: name ?? this.name,
      defaultUnit: defaultUnit ?? this.defaultUnit,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'default_unit': defaultUnit,
      };

  factory IngredientModel.fromMap(Map<String, dynamic> map) {
    return IngredientModel(
      id: map['id'] as String,
      name: map['name'] as String,
      defaultUnit: map['default_unit'] as String,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is IngredientModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'IngredientModel(id: $id, name: $name, unit: $defaultUnit)';
}

