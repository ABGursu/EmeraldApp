/// Priority levels for shopping items
enum ShoppingPriority {
  future(1, 'Future'),
  low(2, 'Low'),
  mid(3, 'Mid'),
  high(4, 'High'),
  asap(5, 'ASAP!');

  final int value;
  final String label;

  const ShoppingPriority(this.value, this.label);

  static ShoppingPriority fromValue(int value) {
    return ShoppingPriority.values.firstWhere(
      (p) => p.value == value,
      orElse: () => ShoppingPriority.mid,
    );
  }
}

