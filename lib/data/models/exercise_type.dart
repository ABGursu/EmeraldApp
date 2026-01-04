/// Exercise type constants for the Bio-Mechanic Training System.
class ExerciseType {
  static const String strength = 'Strength';
  static const String explosivePower = 'Explosive Power';
  static const String isolation = 'Isolation';
  static const String balance = 'Balance';
  static const String unilateral = 'Unilateral';
  static const String functional = 'Functional';
  static const String flexibility = 'Flexibility';
  static const String mobility = 'Mobility';
  static const String cardiovascular = 'Cardiovascular';

  /// All available exercise types
  static const List<String> all = [
    strength,
    explosivePower,
    isolation,
    balance,
    unilateral,
    functional,
    flexibility,
    mobility,
    cardiovascular,
  ];

  /// Parse JSON string array to `List<String>`
  static List<String> fromJsonString(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) return [];
    try {
      // Simple JSON array parsing: ["Strength", "Balance"] -> ["Strength", "Balance"]
      final cleaned = jsonString
          .replaceAll('[', '')
          .replaceAll(']', '')
          .replaceAll('"', '')
          .replaceAll(' ', '');
      if (cleaned.isEmpty) return [];
      return cleaned.split(',').where((s) => s.isNotEmpty).toList();
    } catch (e) {
      return [];
    }
  }

  /// Convert `List<String>` to JSON string array
  static String toJsonString(List<String> types) {
    if (types.isEmpty) return '[]';
    return '["${types.join('","')}"]';
  }
}
