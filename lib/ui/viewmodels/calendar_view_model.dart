import 'package:flutter/material.dart';

import '../../data/models/calendar_event_model.dart';
import '../../data/models/calendar_tag_model.dart';
import '../../data/models/diary_entry_model.dart';
import '../../data/models/recurrence_type.dart';
import '../../data/repositories/i_calendar_repository.dart';
import '../../data/repositories/sql_calendar_repository.dart';
import '../../utils/id_generator.dart';

class CalendarViewModel extends ChangeNotifier {
  CalendarViewModel({ICalendarRepository? repository})
      : _repository = repository ?? SqlCalendarRepository();

  final ICalendarRepository _repository;

  List<CalendarEventModel> _events = [];
  List<CalendarTagModel> _tags = [];
  DiaryEntryModel? _currentDiaryEntry;
  DateTime _selectedDate = DateTime.now();
  bool _loading = false;

  List<CalendarEventModel> get events => _events;
  List<CalendarTagModel> get tags => _tags;
  DiaryEntryModel? get currentDiaryEntry => _currentDiaryEntry;
  DateTime get selectedDate => _selectedDate;
  bool get isLoading => _loading;

  /// Get all currently "sticky/active" events
  List<CalendarEventModel> get stickyEvents {
    final now = DateTime.now();
    return _events.where((event) => event.isSticky(now)).toList()
      ..sort((a, b) {
        final aNext = a.getNextOccurrence(now);
        final bNext = b.getNextOccurrence(now);
        return aNext.compareTo(bNext);
      });
  }

  /// Get events for a specific date (considering recurrence)
  List<CalendarEventModel> getEventsForDate(DateTime date) {
    // Normalize input date to midnight for comparison
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    return _events.where((event) {
      // For non-recurring events, check if the event date matches
      if (event.recurrenceType == RecurrenceType.none) {
        final eventDateOnly = DateTime(
          event.dateTime.year,
          event.dateTime.month,
          event.dateTime.day,
        );
        return eventDateOnly.isAtSameMomentAs(dateOnly);
      }
      
      // For recurring events, check if the event occurs on this date
      final eventDateOnly = DateTime(
        event.dateTime.year,
        event.dateTime.month,
        event.dateTime.day,
      );
      
      // Check if the requested date matches the recurrence pattern
      switch (event.recurrenceType) {
        case RecurrenceType.weekly:
          // Check if the date is on the same weekday and is >= event date
          if (dateOnly.weekday == eventDateOnly.weekday &&
              (dateOnly.isAfter(eventDateOnly) || dateOnly.isAtSameMomentAs(eventDateOnly))) {
            // Check if it's a multiple of 7 days from the event date
            final daysDiff = dateOnly.difference(eventDateOnly).inDays;
            return daysDiff >= 0 && daysDiff % 7 == 0;
          }
          return false;
        case RecurrenceType.monthly:
          // Check if the date is on the same day of month and is >= event date
          if (dateOnly.day == eventDateOnly.day &&
              (dateOnly.isAfter(eventDateOnly) || dateOnly.isAtSameMomentAs(eventDateOnly))) {
            // Check if it's in a later month
            final monthsDiff = (dateOnly.year - eventDateOnly.year) * 12 +
                (dateOnly.month - eventDateOnly.month);
            return monthsDiff >= 0;
          }
          return false;
        case RecurrenceType.yearly:
          // Check if the date is on the same month and day and is >= event date
          if (dateOnly.month == eventDateOnly.month &&
              dateOnly.day == eventDateOnly.day &&
              (dateOnly.isAfter(eventDateOnly) || dateOnly.isAtSameMomentAs(eventDateOnly))) {
            // Check if it's in a later year
            final yearsDiff = dateOnly.year - eventDateOnly.year;
            return yearsDiff >= 0;
          }
          return false;
        case RecurrenceType.none:
          // Already handled above
          return false;
      }
    }).toList();
  }

  /// Get events that have a warning window active for a specific date
  List<CalendarEventModel> getWarningEventsForDate(DateTime date) {
    // Normalize input date to midnight for comparison
    final dateOnly = DateTime(date.year, date.month, date.day);
    return _events.where((event) {
      // Get the next occurrence from the start of the day
      final nextOccurrence = event.getNextOccurrence(dateOnly);
      final nextOccurrenceDateOnly = DateTime(
        nextOccurrence.year,
        nextOccurrence.month,
        nextOccurrence.day,
      );
      
      // Calculate warning start date (normalized to midnight)
      final warningStart = nextOccurrenceDateOnly.subtract(Duration(days: event.warnDaysBefore));
      final warningStartDateOnly = DateTime(
        warningStart.year,
        warningStart.month,
        warningStart.day,
      );
      
      // Check if the current date is within the warning window
      return (dateOnly.isAfter(warningStartDateOnly) || dateOnly.isAtSameMomentAs(warningStartDateOnly)) &&
          dateOnly.isBefore(nextOccurrenceDateOnly);
    }).toList();
  }

  Future<void> init() async {
    _loading = true;
    notifyListeners();
    await loadTags();
    await loadEvents();
    await loadDiaryEntry(_selectedDate);
    _loading = false;
    notifyListeners();
  }

  Future<void> loadEvents() async {
    _events = await _repository.getAllEvents();
    notifyListeners();
  }

  Future<void> loadTags() async {
    _tags = await _repository.getAllTags();
    notifyListeners();
  }

  Future<void> loadDiaryEntry(DateTime date) async {
    _currentDiaryEntry = await _repository.getDiaryEntryByDate(date);
    notifyListeners();
  }

  Future<void> setSelectedDate(DateTime date) async {
    _selectedDate = date;
    await loadDiaryEntry(date);
    notifyListeners();
  }

  Future<void> saveDiaryEntry(String content) async {
    final entry = DiaryEntryModel(
      date: _selectedDate,
      content: content,
      updatedAt: DateTime.now(),
    );
    await _repository.saveDiaryEntry(entry);
    _currentDiaryEntry = entry;
    notifyListeners();
  }

  // Calendar Tags
  Future<String> createTag(String name, int colorValue) async {
    final tag = CalendarTagModel(
      id: generateId(),
      name: name,
      colorValue: colorValue,
      createdAt: DateTime.now(),
    );
    final id = await _repository.createTag(tag);
    await loadTags();
    return id;
  }

  Future<void> updateTag(CalendarTagModel tag) async {
    await _repository.updateTag(tag);
    await loadTags();
  }

  Future<void> deleteTag(String id) async {
    await _repository.deleteTag(id);
    await loadTags();
  }

  // Calendar Events
  Future<String> createEvent({
    required String title,
    String? description,
    required DateTime dateTime,
    int? durationMinutes,
    String? tagId,
    required RecurrenceType recurrenceType,
    required int warnDaysBefore,
    int? alarmBeforeHours,
  }) async {
    final event = CalendarEventModel(
      id: generateId(),
      title: title,
      description: description,
      dateTime: dateTime,
      durationMinutes: durationMinutes,
      tagId: tagId,
      recurrenceType: recurrenceType,
      warnDaysBefore: warnDaysBefore,
      alarmBeforeHours: alarmBeforeHours,
      createdAt: DateTime.now(),
    );
    final id = await _repository.createEvent(event);
    await loadEvents();
    return id;
  }

  Future<void> updateEvent(CalendarEventModel event) async {
    await _repository.updateEvent(event);
    await loadEvents();
  }

  Future<void> deleteEvent(String id) async {
    await _repository.deleteEvent(id);
    await loadEvents();
  }

  CalendarTagModel? getTagById(String? tagId) {
    if (tagId == null) return null;
    try {
      return _tags.firstWhere((tag) => tag.id == tagId);
    } catch (e) {
      return null;
    }
  }
}

