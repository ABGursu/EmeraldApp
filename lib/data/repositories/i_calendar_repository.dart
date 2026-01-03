import '../models/calendar_event_model.dart';
import '../models/calendar_tag_model.dart';
import '../models/diary_entry_model.dart';

abstract class ICalendarRepository {
  // Calendar Tags
  Future<String> createTag(CalendarTagModel tag);
  Future<int> updateTag(CalendarTagModel tag);
  Future<int> deleteTag(String id);
  Future<List<CalendarTagModel>> getAllTags();
  Future<CalendarTagModel?> getTagById(String id);

  // Diary Entries
  Future<void> saveDiaryEntry(DiaryEntryModel entry);
  Future<DiaryEntryModel?> getDiaryEntryByDate(DateTime date);
  Future<List<DiaryEntryModel>> getAllDiaryEntries();

  // Calendar Events
  Future<String> createEvent(CalendarEventModel event);
  Future<int> updateEvent(CalendarEventModel event);
  Future<int> deleteEvent(String id);
  Future<List<CalendarEventModel>> getAllEvents();
  Future<CalendarEventModel?> getEventById(String id);
  Future<List<CalendarEventModel>> getEventsByDateRange(DateTime start, DateTime end);
}

