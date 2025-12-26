/// Represents a logged supplement consumption (header).
class SupplementLogModel {
  final String id;
  final DateTime date;
  final String productNameSnapshot;
  final double servingsCount;

  const SupplementLogModel({
    required this.id,
    required this.date,
    required this.productNameSnapshot,
    required this.servingsCount,
  });

  SupplementLogModel copyWith({
    String? id,
    DateTime? date,
    String? productNameSnapshot,
    double? servingsCount,
  }) {
    return SupplementLogModel(
      id: id ?? this.id,
      date: date ?? this.date,
      productNameSnapshot: productNameSnapshot ?? this.productNameSnapshot,
      servingsCount: servingsCount ?? this.servingsCount,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date.millisecondsSinceEpoch,
        'product_name_snapshot': productNameSnapshot,
        'servings_count': servingsCount,
      };

  factory SupplementLogModel.fromMap(Map<String, dynamic> map) {
    return SupplementLogModel(
      id: map['id'] as String,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      productNameSnapshot: map['product_name_snapshot'] as String,
      servingsCount: (map['servings_count'] as num).toDouble(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SupplementLogModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'SupplementLogModel(id: $id, date: $date, product: $productNameSnapshot, servings: $servingsCount)';
}

