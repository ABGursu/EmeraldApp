import '../local_db/database_helper.dart';
import '../models/exercise_definition_model.dart';
import '../models/routine_model.dart';
import '../models/routine_item_model.dart';
import '../models/user_stats_model.dart';
import '../models/workout_log_model.dart';
import 'i_exercise_log_repository.dart';

class SqlExerciseLogRepository implements IExerciseLogRepository {
  final DatabaseHelper _dbHelper;

  SqlExerciseLogRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  // Exercise Definition CRUD
  @override
  Future<int> createExerciseDefinition(ExerciseDefinition definition) async {
    final db = await _dbHelper.database;
    final map = definition.toMap();
    map.remove('id'); // Remove id for AUTOINCREMENT
    return await db.insert('exercise_definitions', map);
  }

  @override
  Future<int> updateExerciseDefinition(ExerciseDefinition definition) async {
    final db = await _dbHelper.database;
    return await db.update(
      'exercise_definitions',
      definition.toMap(),
      where: 'id = ?',
      whereArgs: [definition.id],
    );
  }

  @override
  Future<int> deleteExerciseDefinition(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('exercise_definitions', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<ExerciseDefinition>> getAllExerciseDefinitions() async {
    final db = await _dbHelper.database;
    final result = await db.query('exercise_definitions', orderBy: 'name ASC');
    return result.map((map) => ExerciseDefinition.fromMap(map)).toList();
  }

  @override
  Future<ExerciseDefinition?> getExerciseDefinitionByName(String name) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'exercise_definitions',
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return ExerciseDefinition.fromMap(result.first);
  }

  // Routine CRUD
  @override
  Future<int> createRoutine(Routine routine) async {
    final db = await _dbHelper.database;
    final map = routine.toMap();
    map.remove('id'); // Remove id for AUTOINCREMENT
    return await db.insert('routines', map);
  }

  @override
  Future<int> updateRoutine(Routine routine) async {
    final db = await _dbHelper.database;
    return await db.update(
      'routines',
      routine.toMap(),
      where: 'id = ?',
      whereArgs: [routine.id],
    );
  }

  @override
  Future<int> deleteRoutine(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('routines', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<Routine>> getAllRoutines() async {
    final db = await _dbHelper.database;
    final result = await db.query('routines', orderBy: 'created_at DESC');
    return result.map((map) => Routine.fromMap(map)).toList();
  }

  @override
  Future<Routine?> getRoutineById(int id) async {
    final db = await _dbHelper.database;
    final result = await db.query('routines', where: 'id = ?', whereArgs: [id], limit: 1);
    if (result.isEmpty) return null;
    return Routine.fromMap(result.first);
  }

  // Routine Item CRUD
  @override
  Future<int> createRoutineItem(RoutineItem item) async {
    final db = await _dbHelper.database;
    final map = item.toMap();
    map.remove('id'); // Remove id for AUTOINCREMENT
    return await db.insert('routine_items', map);
  }

  @override
  Future<int> updateRoutineItem(RoutineItem item) async {
    final db = await _dbHelper.database;
    return await db.update(
      'routine_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  @override
  Future<int> deleteRoutineItem(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('routine_items', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<RoutineItem>> getRoutineItemsByRoutineId(int routineId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'routine_items',
      where: 'routine_id = ?',
      whereArgs: [routineId],
      orderBy: 'order_index ASC',
    );
    return result.map((map) => RoutineItem.fromMap(map)).toList();
  }

  @override
  Future<void> deleteRoutineItemsByRoutineId(int routineId) async {
    final db = await _dbHelper.database;
    await db.delete('routine_items', where: 'routine_id = ?', whereArgs: [routineId]);
  }

  // Workout Log CRUD
  @override
  Future<int> createWorkoutLog(WorkoutLog log) async {
    final db = await _dbHelper.database;
    final map = log.toMap();
    map.remove('id'); // Remove id for AUTOINCREMENT
    return await db.insert('workout_logs', map);
  }

  @override
  Future<int> updateWorkoutLog(WorkoutLog log) async {
    final db = await _dbHelper.database;
    return await db.update(
      'workout_logs',
      log.toMap(),
      where: 'id = ?',
      whereArgs: [log.id],
    );
  }

  @override
  Future<int> deleteWorkoutLog(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('workout_logs', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<WorkoutLog>> getWorkoutLogsByDate(DateTime date) async {
    final db = await _dbHelper.database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
    final result = await db.query(
      'workout_logs',
      where: 'date >= ? AND date < ?',
      whereArgs: [
        startOfDay.millisecondsSinceEpoch,
        endOfDay.millisecondsSinceEpoch,
      ],
      orderBy: 'order_index ASC',
    );
    return result.map((map) => WorkoutLog.fromMap(map)).toList();
  }

  @override
  Future<List<WorkoutLog>> getWorkoutLogsByDateRange(
    DateTime from,
    DateTime to,
  ) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'workout_logs',
      where: 'date >= ? AND date <= ?',
      whereArgs: [
        from.millisecondsSinceEpoch,
        to.millisecondsSinceEpoch,
      ],
      orderBy: 'date DESC, order_index ASC',
    );
    return result.map((map) => WorkoutLog.fromMap(map)).toList();
  }

  @override
  Future<void> reorderWorkoutLogs(List<WorkoutLog> logs) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    for (int i = 0; i < logs.length; i++) {
      final log = logs[i].copyWith(orderIndex: i);
      batch.update(
        'workout_logs',
        {'order_index': i},
        where: 'id = ?',
        whereArgs: [log.id],
      );
    }
    await batch.commit(noResult: true);
  }

  // User Stats
  @override
  Future<UserStats> getUserStats() async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'user_stats',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );
    if (result.isEmpty) {
      return UserStats.empty();
    }
    return UserStats.fromMap(result.first);
  }

  @override
  Future<int> updateUserStats(UserStats stats) async {
    final db = await _dbHelper.database;
    return await db.update(
      'user_stats',
      stats.toMap(),
      where: 'id = ?',
      whereArgs: [stats.id],
    );
  }

  // Movement Types
  @override
  Future<List<String>> getAllMovementTypes() async {
    final db = await _dbHelper.database;
    final result = await db.query('movement_types', orderBy: 'name ASC');
    return result.map((map) => map['name'] as String).toList();
  }

  @override
  Future<void> addMovementType(String type) async {
    final db = await _dbHelper.database;
    try {
      await db.insert('movement_types', {'name': type});
    } catch (e) {
      // Ignore if already exists (UNIQUE constraint)
    }
  }

  @override
  Future<void> deleteMovementType(String type) async {
    final db = await _dbHelper.database;
    await db.delete('movement_types', where: 'name = ?', whereArgs: [type]);
  }
}
