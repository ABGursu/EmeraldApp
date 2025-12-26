class BudgetGoalModel {
  final String id;
  final String monthYear; // Format: "MM-YYYY"
  final double amount;

  const BudgetGoalModel({
    required this.id,
    required this.monthYear,
    required this.amount,
  });

  BudgetGoalModel copyWith({
    String? id,
    String? monthYear,
    double? amount,
  }) {
    return BudgetGoalModel(
      id: id ?? this.id,
      monthYear: monthYear ?? this.monthYear,
      amount: amount ?? this.amount,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'month_year': monthYear,
        'amount': amount,
      };

  factory BudgetGoalModel.fromMap(Map<String, dynamic> map) {
    return BudgetGoalModel(
      id: map['id'] as String,
      monthYear: map['month_year'] as String,
      amount: (map['amount'] as num).toDouble(),
    );
  }
}

