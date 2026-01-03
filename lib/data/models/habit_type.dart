/// Enum representing the type of habit.
/// - [positive]: A habit to build/do (e.g., "Study 30 mins")
/// - [negative]: A habit to avoid/quit (e.g., "Avoid social media")
enum HabitType {
  positive,
  negative;

  /// Converts enum to string for database storage.
  String toDbString() {
    switch (this) {
      case HabitType.positive:
        return 'positive';
      case HabitType.negative:
        return 'negative';
    }
  }

  /// Creates enum from database string.
  static HabitType fromDbString(String value) {
    switch (value) {
      case 'positive':
        return HabitType.positive;
      case 'negative':
        return HabitType.negative;
      default:
        return HabitType.positive; // Default fallback
    }
  }
}

