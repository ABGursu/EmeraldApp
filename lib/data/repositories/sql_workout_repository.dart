import '../../utils/id_generator.dart';
import '../local_db/database_helper.dart';
import '../models/exercise_dictionary_model.dart';
import '../models/routine_item_model.dart';
import '../models/routine_model.dart';
import '../models/workout_entry_model.dart';
import '../models/workout_session_model.dart';
import '../repositories/i_workout_repository.dart';

class SqlWorkoutRepository implements IWorkoutRepository {
  final DatabaseHelper _dbHelper;

  SqlWorkoutRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  @override
  Future<String> createExercise(ExerciseDictionaryModel exercise) async {
    final db = await _dbHelper.database;
    final id = exercise.id.isNotEmpty ? exercise.id : generateId();
    await db.insert('exercise_dictionary', exercise.copyWith(id: id).toMap());
    return id;
  }

  @override
  Future<int> updateExercise(ExerciseDictionaryModel exercise) async {
    final db = await _dbHelper.database;
    return db.update(
      'exercise_dictionary',
      exercise.toMap(),
      where: 'id = ?',
      whereArgs: [exercise.id],
    );
  }

  @override
  Future<int> deleteExercise(String id) async {
    final db = await _dbHelper.database;
    return db.delete('exercise_dictionary', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<ExerciseDictionaryModel>> getAllExercises() async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'exercise_dictionary',
      orderBy: 'created_at DESC',
    );
    return result.map(ExerciseDictionaryModel.fromMap).toList();
  }

  @override
  Future<String> createSession(WorkoutSessionModel session) async {
    final db = await _dbHelper.database;
    final id = session.id.isNotEmpty ? session.id : generateId();
    await db.insert('workout_sessions', session.copyWith(id: id).toMap());
    return id;
  }

  @override
  Future<int> updateSession(WorkoutSessionModel session) async {
    final db = await _dbHelper.database;
    return db.update(
      'workout_sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  @override
  Future<int> deleteSession(String id) async {
    final db = await _dbHelper.database;
    return db.delete('workout_sessions', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<WorkoutSessionModel>> getSessions() async {
    final db = await _dbHelper.database;
    final result = await db.query('workout_sessions', orderBy: 'date DESC');
    return result.map(WorkoutSessionModel.fromMap).toList();
  }

  @override
  Future<String> createEntry(WorkoutEntryModel entry) async {
    final db = await _dbHelper.database;
    final id = entry.id.isNotEmpty ? entry.id : generateId();
    await db.insert('workout_entries', entry.copyWith(id: id).toMap());
    return id;
  }

  @override
  Future<int> updateEntry(WorkoutEntryModel entry) async {
    final db = await _dbHelper.database;
    return db.update(
      'workout_entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  @override
  Future<int> deleteEntry(String id) async {
    final db = await _dbHelper.database;
    return db.delete('workout_entries', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<WorkoutEntryModel>> getEntriesBySession(String sessionId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'workout_entries',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'id DESC',
    );
    return result.map(WorkoutEntryModel.fromMap).toList();
  }

  @override
  Future<String> createRoutine(RoutineModel routine) async {
    final db = await _dbHelper.database;
    final id = routine.id.isNotEmpty ? routine.id : generateId();
    await db.insert('routines', routine.copyWith(id: id).toMap());
    return id;
  }

  @override
  Future<int> updateRoutine(RoutineModel routine) async {
    final db = await _dbHelper.database;
    return db.update(
      'routines',
      routine.toMap(),
      where: 'id = ?',
      whereArgs: [routine.id],
    );
  }

  @override
  Future<int> deleteRoutine(String id) async {
    final db = await _dbHelper.database;
    return db.delete('routines', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<RoutineModel>> getAllRoutines() async {
    final db = await _dbHelper.database;
    final result = await db.query('routines', orderBy: 'created_at DESC');
    return result.map(RoutineModel.fromMap).toList();
  }

  @override
  Future<String> createRoutineItem(RoutineItemModel item) async {
    final db = await _dbHelper.database;
    final id = item.id.isNotEmpty ? item.id : generateId();
    await db.insert('routine_items', item.copyWith(id: id).toMap());
    return id;
  }

  @override
  Future<int> updateRoutineItem(RoutineItemModel item) async {
    final db = await _dbHelper.database;
    return db.update(
      'routine_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  @override
  Future<int> deleteRoutineItem(String id) async {
    final db = await _dbHelper.database;
    return db.delete('routine_items', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<RoutineItemModel>> getItemsByRoutine(String routineId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'routine_items',
      where: 'routine_id = ?',
      whereArgs: [routineId],
      orderBy: 'id ASC',
    );
    return result.map(RoutineItemModel.fromMap).toList();
  }
}
