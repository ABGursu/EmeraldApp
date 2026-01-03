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
    final dateOnly = DateTime(date.year, date.month, date.day);
    final nextDay = dateOnly.add(const Duration(days: 1));
    
    return _events.where((event) {
      final nextOccurrence = event.getNextOccurrence(dateOnly);
      return (nextOccurrence.isAfter(dateOnly) || nextOccurrence.isAtSameMomentAs(dateOnly)) &&
          nextOccurrence.isBefore(nextDay);
    }).toList();
  }

  /// Get events that have a warning window active for a specific date
  List<CalendarEventModel> getWarningEventsForDate(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    return _events.where((event) {
      final nextOccurrence = event.getNextOccurrence(dateOnly);
      final warningStart = nextOccurrence.subtract(Duration(days: event.warnDaysBefore));
      return (dateOnly.isAfter(warningStart) || dateOnly.isAtSameMomentAs(warningStart)) &&
          dateOnly.isBefore(nextOccurrence);
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

