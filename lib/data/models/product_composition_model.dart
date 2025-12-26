/// Represents a single ingredient entry within a product's current composition.
/// This is the "live" recipe that can be edited.
class ProductCompositionModel {
  final String productId;
  final String ingredientId;
  final double amountPerServing;

  const ProductCompositionModel({
    required this.productId,
    required this.ingredientId,
    required this.amountPerServing,
  });

  ProductCompositionModel copyWith({
    String? productId,
    String? ingredientId,
    double? amountPerServing,
  }) {
    return ProductCompositionModel(
      productId: productId ?? this.productId,
      ingredientId: ingredientId ?? this.ingredientId,
      amountPerServing: amountPerServing ?? this.amountPerServing,
    );
  }

  Map<String, dynamic> toMap() => {
        'product_id': productId,
        'ingredient_id': ingredientId,
        'amount_per_serving': amountPerServing,
      };

  factory ProductCompositionModel.fromMap(Map<String, dynamic> map) {
    return ProductCompositionModel(
      productId: map['product_id'] as String,
      ingredientId: map['ingredient_id'] as String,
      amountPerServing: (map['amount_per_serving'] as num).toDouble(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductCompositionModel &&
        other.productId == productId &&
        other.ingredientId == ingredientId;
  }

  @override
  int get hashCode => Object.hash(productId, ingredientId);
}

