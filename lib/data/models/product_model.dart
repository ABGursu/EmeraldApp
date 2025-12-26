/// Represents a supplement product in the user's inventory.
class ProductModel {
  final String id;
  final String name;
  final String servingUnit;
  final bool isArchived;

  const ProductModel({
    required this.id,
    required this.name,
    this.servingUnit = 'Serving',
    this.isArchived = false,
  });

  ProductModel copyWith({
    String? id,
    String? name,
    String? servingUnit,
    bool? isArchived,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      servingUnit: servingUnit ?? this.servingUnit,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'serving_unit': servingUnit,
        'is_archived': isArchived ? 1 : 0,
      };

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] as String,
      name: map['name'] as String,
      servingUnit: map['serving_unit'] as String? ?? 'Serving',
      isArchived: (map['is_archived'] as int? ?? 0) == 1,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ProductModel(id: $id, name: $name, unit: $servingUnit, archived: $isArchived)';
}

