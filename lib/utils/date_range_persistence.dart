import 'package:shared_preferences/shared_preferences.dart';

/// Mixin for persisting date ranges with smart "rolling today" logic
/// 
/// If the end date is set to "today", it will automatically extend
/// to the current day when loading. Fixed past ranges remain unchanged.
mixin DateRangePersistence {
  /// Module name for SharedPreferences keys (e.g., 'balance', 'exercise', 'supplement')
  String get moduleName;

  /// Loads the persisted date range
  /// Returns (startDate, endDate, isRollingToday)
  Future<({DateTime? startDate, DateTime? endDate, bool isRollingToday})>
      loadDateRange() async {
    final prefs = await SharedPreferences.getInstance();
    final startMillis = prefs.getInt('${moduleName}_start_date');
    final endMillis = prefs.getInt('${moduleName}_end_date');
    final isRollingToday = prefs.getBool('${moduleName}_is_rolling_today') ?? false;

    DateTime? startDate;
    DateTime? endDate;

    if (startMillis != null) {
      startDate = DateTime.fromMillisecondsSinceEpoch(startMillis);
    }

    if (isRollingToday) {
      // If it was a rolling date, set end date to today
      endDate = DateTime.now();
    } else if (endMillis != null) {
      // Otherwise, use the saved end date
      endDate = DateTime.fromMillisecondsSinceEpoch(endMillis);
    }

    return (
      startDate: startDate,
      endDate: endDate,
      isRollingToday: isRollingToday,
    );
  }

  /// Saves the date range to SharedPreferences
  /// Automatically detects if endDate is "today" and marks it as rolling
  Future<void> saveDateRange({
    required DateTime? startDate,
    required DateTime? endDate,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (startDate == null || endDate == null) {
      // Clear preferences if dates are null
      await prefs.remove('${moduleName}_start_date');
      await prefs.remove('${moduleName}_end_date');
      await prefs.remove('${moduleName}_is_rolling_today');
      return;
    }

    // Check if end date is "today" (same day, ignoring time)
    final now = DateTime.now();
    final isRollingToday = endDate.year == now.year &&
        endDate.month == now.month &&
        endDate.day == now.day;

    // Save dates
    await prefs.setInt(
      '${moduleName}_start_date',
      startDate.millisecondsSinceEpoch,
    );

    if (isRollingToday) {
      // Don't save end date if it's rolling - it will always be "today"
      await prefs.remove('${moduleName}_end_date');
    } else {
      // Save fixed end date
      await prefs.setInt(
        '${moduleName}_end_date',
        endDate.millisecondsSinceEpoch,
      );
    }

    // Save rolling flag
    await prefs.setBool('${moduleName}_is_rolling_today', isRollingToday);
  }

  /// Clears the persisted date range
  Future<void> clearDateRange() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${moduleName}_start_date');
    await prefs.remove('${moduleName}_end_date');
    await prefs.remove('${moduleName}_is_rolling_today');
  }
}

/// Helper extension to check if two dates are on the same day
extension DateTimeExtension on DateTime {
  bool isSameDayAs(DateTime other) {
    return year == other.year &&
        month == other.month &&
        day == other.day;
  }
}

