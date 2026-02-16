import 'shopping_priority.dart';

class ShoppingItemModel {
  final String id;
  final String name;
  final double estimatedPrice;
  final double? actualPrice;
  final ShoppingPriority priority;
  final int? quantity;
  final String? note;
  final String? tagId;
  final bool isPurchased;
  final DateTime? purchaseDate;
  final String? linkedTransactionId; // ID of the expense transaction created when purchased
  final bool rentInBalanceSheet; // Reserve estimated price in Balance Sheet with yellow "Rented" tag
  final String? linkedRentTransactionId; // ID of the rent placeholder transaction
  final DateTime createdAt;

  const ShoppingItemModel({
    required this.id,
    required this.name,
    required this.estimatedPrice,
    this.actualPrice,
    required this.priority,
    this.quantity,
    this.note,
    this.tagId,
    this.isPurchased = false,
    this.purchaseDate,
    this.linkedTransactionId,
    this.rentInBalanceSheet = false,
    this.linkedRentTransactionId,
    required this.createdAt,
  });

  ShoppingItemModel copyWith({
    String? id,
    String? name,
    double? estimatedPrice,
    double? actualPrice,
    ShoppingPriority? priority,
    int? quantity,
    String? note,
    String? tagId,
    bool? isPurchased,
    DateTime? purchaseDate,
    String? linkedTransactionId,
    bool? rentInBalanceSheet,
    String? linkedRentTransactionId,
    DateTime? createdAt,
  }) {
    return ShoppingItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
      actualPrice: actualPrice ?? this.actualPrice,
      priority: priority ?? this.priority,
      quantity: quantity ?? this.quantity,
      note: note ?? this.note,
      tagId: tagId ?? this.tagId,
      isPurchased: isPurchased ?? this.isPurchased,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      linkedTransactionId: linkedTransactionId ?? this.linkedTransactionId,
      rentInBalanceSheet: rentInBalanceSheet ?? this.rentInBalanceSheet,
      linkedRentTransactionId:
          linkedRentTransactionId ?? this.linkedRentTransactionId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'estimated_price': estimatedPrice,
        'actual_price': actualPrice,
        'priority': priority.value,
        'quantity': quantity,
        'note': note,
        'tag_id': tagId,
        'is_purchased': isPurchased ? 1 : 0,
        'purchase_date': purchaseDate?.millisecondsSinceEpoch,
        'linked_transaction_id': linkedTransactionId,
        'rent_in_balance_sheet': rentInBalanceSheet ? 1 : 0,
        'linked_rent_transaction_id': linkedRentTransactionId,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory ShoppingItemModel.fromMap(Map<String, dynamic> map) {
    return ShoppingItemModel(
      id: map['id'] as String,
      name: map['name'] as String,
      estimatedPrice: (map['estimated_price'] as num).toDouble(),
      actualPrice: (map['actual_price'] as num?)?.toDouble(),
      priority: ShoppingPriority.fromValue(map['priority'] as int),
      quantity: map['quantity'] as int?,
      note: map['note'] as String?,
      tagId: map['tag_id'] as String?,
      isPurchased: (map['is_purchased'] as int) == 1,
      purchaseDate: map['purchase_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['purchase_date'] as int)
          : null,
      linkedTransactionId: map['linked_transaction_id'] as String?,
      rentInBalanceSheet: (map['rent_in_balance_sheet'] as int? ?? 0) == 1,
      linkedRentTransactionId:
          map['linked_rent_transaction_id'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  /// Calculates the variance between actual and estimated price
  double? get variance {
    if (actualPrice == null) return null;
    return actualPrice! - estimatedPrice;
  }

  /// Returns true if over budget (actual > estimated)
  bool get isOverBudget {
    if (actualPrice == null) return false;
    return actualPrice! > estimatedPrice;
  }

  /// Returns true if under budget (actual < estimated)
  bool get isUnderBudget {
    if (actualPrice == null) return false;
    return actualPrice! < estimatedPrice;
  }
}

