import 'package:flutter/material.dart';

class DateProvider extends ChangeNotifier with WidgetsBindingObserver {
  DateTime _selectedDate = DateTime.now();

  DateTime get selectedDate => _selectedDate;

  DateProvider() {
    WidgetsBinding.instance.addObserver(this);
    _checkAndUpdateDate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAndUpdateDate();
    }
  }

  /// Checks if the day has changed and updates selectedDate if needed
  void _checkAndUpdateDate() {
    final now = DateTime.now();
    final currentDay = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);

    // If day has changed, reset to today
    if (currentDay != selectedDay) {
      _selectedDate = now;
      notifyListeners();
    }
  }

  /// Manually set date (for navigation)
  void setSelectedDate(DateTime date) {
    final now = DateTime.now();
    final currentDay = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(date.year, date.month, date.day);

    // Only allow setting past dates or today
    if (selectedDay.isAfter(currentDay)) {
      return;
    }

    _selectedDate = date;
    notifyListeners();
  }

  /// Go to previous day
  void goToPreviousDay() {
    final newDate = _selectedDate.subtract(const Duration(days: 1));
    setSelectedDate(newDate);
  }

  /// Go to next day (only if not in future)
  void goToNextDay() {
    final now = DateTime.now();
    final currentDay = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);

    if (selectedDay.isBefore(currentDay)) {
      final newDate = _selectedDate.add(const Duration(days: 1));
      setSelectedDate(newDate);
    }
  }

  /// Reset to today (force reset)
  void resetToToday() {
    _selectedDate = DateTime.now();
    notifyListeners();
  }

  /// Check if selected date is today
  bool get isToday {
    final now = DateTime.now();
    final currentDay = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    return currentDay == selectedDay;
  }
}

