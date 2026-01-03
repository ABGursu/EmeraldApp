/// Priority levels for shopping items
enum ShoppingPriority {
  low(1, 'Low'),
  medium(2, 'Medium'),
  high(3, 'High'),
  urgent(4, 'Urgent');

  final int value;
  final String label;

  const ShoppingPriority(this.value, this.label);

  static ShoppingPriority fromValue(int value) {
    return ShoppingPriority.values.firstWhere(
      (p) => p.value == value,
      orElse: () => ShoppingPriority.medium,
    );
  }
}

