import 'package:sqflite/sqflite.dart';

import '../local_db/database_helper.dart';
import '../models/calendar_event_model.dart';
import '../models/calendar_tag_model.dart';
import '../models/diary_entry_model.dart';
import 'i_calendar_repository.dart';

class SqlCalendarRepository implements ICalendarRepository {
  final DatabaseHelper _dbHelper;

  SqlCalendarRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  // Calendar Tags
  @override
  Future<String> createTag(CalendarTagModel tag) async {
    final db = await _dbHelper.database;
    await db.insert('calendar_tags', tag.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return tag.id;
  }

  @override
  Future<int> updateTag(CalendarTagModel tag) async {
    final db = await _dbHelper.database;
    return await db.update(
      'calendar_tags',
      tag.toMap(),
      where: 'id = ?',
      whereArgs: [tag.id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<int> deleteTag(String id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'calendar_tags',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<List<CalendarTagModel>> getAllTags() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('calendar_tags');
    return List.generate(
        maps.length, (i) => CalendarTagModel.fromMap(maps[i]));
  }

  @override
  Future<CalendarTagModel?> getTagById(String id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'calendar_tags',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return CalendarTagModel.fromMap(maps.first);
    }
    return null;
  }

  // Diary Entries
  @override
  Future<void> saveDiaryEntry(DiaryEntryModel entry) async {
    final db = await _dbHelper.database;
    // Use date only (without time) as primary key
    final dateOnly = DateTime(entry.date.year, entry.date.month, entry.date.day);
    await db.insert(
      'diary_entries',
      {
        'date': dateOnly.millisecondsSinceEpoch,
        'content': entry.content,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<DiaryEntryModel?> getDiaryEntryByDate(DateTime date) async {
    final db = await _dbHelper.database;
    final dateOnly = DateTime(date.year, date.month, date.day);
    final List<Map<String, dynamic>> maps = await db.query(
      'diary_entries',
      where: 'date = ?',
      whereArgs: [dateOnly.millisecondsSinceEpoch],
    );
    if (maps.isNotEmpty) {
      return DiaryEntryModel.fromMap(maps.first);
    }
    return null;
  }

  @override
  Future<List<DiaryEntryModel>> getAllDiaryEntries() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps =
        await db.query('diary_entries', orderBy: 'date DESC');
    return List.generate(
        maps.length, (i) => DiaryEntryModel.fromMap(maps[i]));
  }

  // Calendar Events
  @override
  Future<String> createEvent(CalendarEventModel event) async {
    final db = await _dbHelper.database;
    await db.insert('calendar_events', event.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return event.id;
  }

  @override
  Future<int> updateEvent(CalendarEventModel event) async {
    final db = await _dbHelper.database;
    return await db.update(
      'calendar_events',
      event.toMap(),
      where: 'id = ?',
      whereArgs: [event.id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<int> deleteEvent(String id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'calendar_events',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<List<CalendarEventModel>> getAllEvents() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps =
        await db.query('calendar_events', orderBy: 'date_time ASC');
    return List.generate(
        maps.length, (i) => CalendarEventModel.fromMap(maps[i]));
  }

  @override
  Future<CalendarEventModel?> getEventById(String id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'calendar_events',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return CalendarEventModel.fromMap(maps.first);
    }
    return null;
  }

  @override
  Future<List<CalendarEventModel>> getEventsByDateRange(
      DateTime start, DateTime end) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'calendar_events',
      where: 'date_time >= ? AND date_time <= ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'date_time ASC',
    );
    return List.generate(
        maps.length, (i) => CalendarEventModel.fromMap(maps[i]));
  }
}

