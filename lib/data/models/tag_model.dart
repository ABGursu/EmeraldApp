class TagModel {
  final String id;
  final String name;
  final int colorValue;
  final DateTime createdAt;
  /// When true, tag appears in Balance Sheet filters and transaction tag picker.
  final bool showInBalance;
  /// When true, tag appears in Shopping List filters and item tag picker.
  final bool showInShopping;

  const TagModel({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.createdAt,
    this.showInBalance = true,
    this.showInShopping = true,
  });

  TagModel copyWith({
    String? id,
    String? name,
    int? colorValue,
    DateTime? createdAt,
    bool? showInBalance,
    bool? showInShopping,
  }) {
    return TagModel(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt ?? this.createdAt,
      showInBalance: showInBalance ?? this.showInBalance,
      showInShopping: showInShopping ?? this.showInShopping,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'color_value': colorValue,
        'created_at': createdAt.millisecondsSinceEpoch,
        'show_in_balance': showInBalance ? 1 : 0,
        'show_in_shopping': showInShopping ? 1 : 0,
      };

  factory TagModel.fromMap(Map<String, dynamic> map) {
    return TagModel(
      id: map['id'] as String,
      name: map['name'] as String,
      colorValue: map['color_value'] as int,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      showInBalance: (map['show_in_balance'] as int? ?? 1) == 1,
      showInShopping: (map['show_in_shopping'] as int? ?? 1) == 1,
    );
  }
}
