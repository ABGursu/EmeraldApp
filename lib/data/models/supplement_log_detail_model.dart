/// Represents a snapshot of an ingredient at the moment of logging.
/// This ensures historical data integrity even if product compositions change.
class SupplementLogDetailModel {
  final String logId;
  final String ingredientName;
  final double amountTotal;
  final String unit;

  const SupplementLogDetailModel({
    required this.logId,
    required this.ingredientName,
    required this.amountTotal,
    required this.unit,
  });

  SupplementLogDetailModel copyWith({
    String? logId,
    String? ingredientName,
    double? amountTotal,
    String? unit,
  }) {
    return SupplementLogDetailModel(
      logId: logId ?? this.logId,
      ingredientName: ingredientName ?? this.ingredientName,
      amountTotal: amountTotal ?? this.amountTotal,
      unit: unit ?? this.unit,
    );
  }

  Map<String, dynamic> toMap() => {
        'log_id': logId,
        'ingredient_name': ingredientName,
        'amount_total': amountTotal,
        'unit': unit,
      };

  factory SupplementLogDetailModel.fromMap(Map<String, dynamic> map) {
    return SupplementLogDetailModel(
      logId: map['log_id'] as String,
      ingredientName: map['ingredient_name'] as String,
      amountTotal: (map['amount_total'] as num).toDouble(),
      unit: map['unit'] as String,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SupplementLogDetailModel &&
        other.logId == logId &&
        other.ingredientName == ingredientName;
  }

  @override
  int get hashCode => Object.hash(logId, ingredientName);
}

