class TransactionModel {
  final String id;
  final double amount;
  final DateTime date;
  final String? tagId;
  final String? note;

  const TransactionModel({
    required this.id,
    required this.amount,
    required this.date,
    this.tagId,
    this.note,
  });

  TransactionModel copyWith({
    String? id,
    double? amount,
    DateTime? date,
    String? tagId,
    String? note,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      tagId: tagId ?? this.tagId,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'amount': amount,
        'date': date.millisecondsSinceEpoch,
        'tag_id': tagId,
        'note': note,
      };

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      tagId: map['tag_id'] as String?,
      note: map['note'] as String?,
    );
  }
}

