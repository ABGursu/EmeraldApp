import 'package:sqflite/sqflite.dart';

import '../local_db/database_helper.dart';
import '../models/exercise_definition_model.dart';
import '../models/exercise_muscle_impact_model.dart';
import '../models/muscle_model.dart';
import '../models/routine_model.dart';
import '../models/routine_item_model.dart';
import '../models/sportif_goal_model.dart';
import '../models/workout_session_model.dart';
import '../models/workout_set_model.dart';
import 'i_bio_mechanic_repository.dart';

class SqlBioMechanicRepository implements IBioMechanicRepository {
  final DatabaseHelper _dbHelper;

  SqlBioMechanicRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  // === Muscles (Reference Table) ===
  @override
  Future<List<MuscleModel>> getAllMuscles() async {
    final db = await _dbHelper.database;
    final result =
        await db.query('muscles', orderBy: 'group_name ASC, name ASC');
    return result.map((map) => MuscleModel.fromMap(map)).toList();
  }

  @override
  Future<List<MuscleModel>> getMusclesByGroup(String groupName) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'muscles',
      where: 'group_name = ?',
      whereArgs: [groupName],
      orderBy: 'name ASC',
    );
    return result.map((map) => MuscleModel.fromMap(map)).toList();
  }

  @override
  Future<MuscleModel?> getMuscleById(int id) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'muscles',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return MuscleModel.fromMap(result.first);
  }

  @override
  Future<MuscleModel?> getMuscleByName(String name) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'muscles',
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return MuscleModel.fromMap(result.first);
  }

  // === Exercise Definitions (Enhanced) ===
  @override
  Future<List<ExerciseDefinition>> getAllExerciseDefinitions(
      {bool includeArchived = false}) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'exercise_definitions',
      where: includeArchived ? null : 'is_archived = 0',
      orderBy: 'name ASC',
    );
    return result.map((map) => ExerciseDefinition.fromMap(map)).toList();
  }

  @override
  Future<ExerciseDefinition?> getExerciseDefinitionById(int id) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'exercise_definitions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return ExerciseDefinition.fromMap(result.first);
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
    return await db
        .delete('exercise_definitions', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<int> archiveExerciseDefinition(int id) async {
    final db = await _dbHelper.database;
    return await db.update(
      'exercise_definitions',
      {'is_archived': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // === Exercise Muscle Impact (Bio-Mechanic Engine) ===
  @override
  Future<List<ExerciseMuscleImpactModel>> getMuscleImpactsForExercise(
      int exerciseId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'exercise_muscle_impact',
      where: 'exercise_id = ?',
      whereArgs: [exerciseId],
      orderBy: 'impact_score DESC',
    );
    return result.map((map) => ExerciseMuscleImpactModel.fromMap(map)).toList();
  }

  @override
  Future<void> setExerciseMuscleImpacts(
    int exerciseId,
    List<ExerciseMuscleImpactModel> impacts,
  ) async {
    final db = await _dbHelper.database;
    final batch = db.batch();

    // Delete existing impacts
    batch.delete(
      'exercise_muscle_impact',
      where: 'exercise_id = ?',
      whereArgs: [exerciseId],
    );

    // Insert new impacts
    for (final impact in impacts) {
      batch.insert('exercise_muscle_impact', impact.toMap());
    }

    await batch.commit(noResult: true);
  }

  @override
  Future<void> deleteExerciseMuscleImpacts(int exerciseId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'exercise_muscle_impact',
      where: 'exercise_id = ?',
      whereArgs: [exerciseId],
    );
  }

  // === Routines ===
  @override
  Future<List<Routine>> getAllRoutines() async {
    final db = await _dbHelper.database;
    final result = await db.query('routines', orderBy: 'created_at DESC');
    return result.map((map) => Routine.fromMap(map)).toList();
  }

  @override
  Future<Routine?> getRoutineById(int id) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'routines',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return Routine.fromMap(result.first);
  }

  @override
  Future<List<RoutineItem>> getItemsByRoutineId(int routineId) async {
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
  Future<int> createRoutine(Routine routine) async {
    final db = await _dbHelper.database;
    final map = routine.toMap();
    map.remove('id');
    return await db.insert('routines', map);
  }

  @override
  Future<void> updateRoutine(Routine routine) async {
    final db = await _dbHelper.database;
    await db.update(
      'routines',
      routine.toMap(),
      where: 'id = ?',
      whereArgs: [routine.id],
    );
  }

  @override
  Future<void> deleteRoutine(int id) async {
    final db = await _dbHelper.database;
    await db.delete('routines', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<int> createRoutineItem(RoutineItem item) async {
    final db = await _dbHelper.database;
    final map = item.toMap();
    map.remove('id');
    return await db.insert('routine_items', map);
  }

  @override
  Future<void> updateRoutineItem(RoutineItem item) async {
    final db = await _dbHelper.database;
    await db.update(
      'routine_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  @override
  Future<void> deleteRoutineItem(int id) async {
    final db = await _dbHelper.database;
    await db.delete('routine_items', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> reorderRoutineItems(
      int routineId, List<int> itemIdsInOrder) async {
    final db = await _dbHelper.database;
    for (var i = 0; i < itemIdsInOrder.length; i++) {
      await db.update(
        'routine_items',
        {'order_index': i},
        where: 'id = ? AND routine_id = ?',
        whereArgs: [itemIdsInOrder[i], routineId],
      );
    }
  }

  // === Workout Sessions ===
  @override
  Future<List<WorkoutSessionModel>> getSessionsByDate(DateTime date) async {
    final db = await _dbHelper.database;
    final dateOnly = DateTime(date.year, date.month, date.day);
    final startOfDay = dateOnly.millisecondsSinceEpoch;
    final endOfDay =
        dateOnly.add(const Duration(days: 1)).millisecondsSinceEpoch - 1;

    final result = await db.query(
      'workout_sessions',
      where: 'date >= ? AND date < ?',
      whereArgs: [startOfDay, endOfDay],
      orderBy: 'start_time ASC, created_at ASC',
    );
    return result.map((map) => WorkoutSessionModel.fromMap(map)).toList();
  }

  @override
  Future<List<WorkoutSessionModel>> getSessionsByDateRange({
    required DateTime from,
    required DateTime to,
  }) async {
    final db = await _dbHelper.database;
    final fromMs = from.millisecondsSinceEpoch;
    final toMs = to.millisecondsSinceEpoch;

    final result = await db.query(
      'workout_sessions',
      where: 'date >= ? AND date <= ?',
      whereArgs: [fromMs, toMs],
      orderBy: 'date DESC, start_time ASC',
    );
    return result.map((map) => WorkoutSessionModel.fromMap(map)).toList();
  }

  @override
  Future<WorkoutSessionModel?> getSessionById(int id) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'workout_sessions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return WorkoutSessionModel.fromMap(result.first);
  }

  @override
  Future<int> createSession(WorkoutSessionModel session) async {
    final db = await _dbHelper.database;
    final map = session.toMap();
    map.remove('id'); // Remove id for AUTOINCREMENT
    return await db.insert('workout_sessions', map);
  }

  @override
  Future<int> updateSession(WorkoutSessionModel session) async {
    final db = await _dbHelper.database;
    return await db.update(
      'workout_sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  @override
  Future<int> deleteSession(int id) async {
    final db = await _dbHelper.database;
    // CASCADE delete will handle workout_logs
    return await db
        .delete('workout_sessions', where: 'id = ?', whereArgs: [id]);
  }

  // === Workout Sets ===
  @override
  Future<List<WorkoutSetModel>> getSetsBySession(int sessionId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'workout_logs',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'exercise_id ASC, set_number ASC',
    );
    return result.map((map) => WorkoutSetModel.fromMap(map)).toList();
  }

  @override
  Future<List<WorkoutSetModel>> getSetsByExercise(int exerciseId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'workout_logs',
      where: 'exercise_id = ?',
      whereArgs: [exerciseId],
      orderBy: 'session_id DESC, set_number ASC',
    );
    return result.map((map) => WorkoutSetModel.fromMap(map)).toList();
  }

  @override
  Future<WorkoutSetModel?> getSetById(int id) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'workout_logs',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return WorkoutSetModel.fromMap(result.first);
  }

  @override
  Future<int> createSet(WorkoutSetModel set) async {
    final db = await _dbHelper.database;
    final map = set.toMap();
    map.remove('id'); // Remove id for AUTOINCREMENT
    return await db.insert('workout_logs', map);
  }

  @override
  Future<int> updateSet(WorkoutSetModel set) async {
    final db = await _dbHelper.database;
    return await db.update(
      'workout_logs',
      set.toMap(),
      where: 'id = ?',
      whereArgs: [set.id],
    );
  }

  @override
  Future<int> deleteSet(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('workout_logs', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<int> deleteSetsBySession(int sessionId) async {
    final db = await _dbHelper.database;
    return await db.delete('workout_logs',
        where: 'session_id = ?', whereArgs: [sessionId]);
  }

  // === Sportif Goals ===
  @override
  Future<List<SportifGoalModel>> getAllGoals(
      {bool includeArchived = false}) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'sportif_goals',
      where: includeArchived ? null : 'is_archived = 0',
      orderBy: 'name ASC',
    );
    return result.map((map) => SportifGoalModel.fromMap(map)).toList();
  }

  @override
  Future<SportifGoalModel?> getGoalById(int id) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'sportif_goals',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return SportifGoalModel.fromMap(result.first);
  }

  @override
  Future<int> createGoal(SportifGoalModel goal) async {
    final db = await _dbHelper.database;
    final map = goal.toMap();
    map.remove('id'); // Remove id for AUTOINCREMENT
    return await db.insert('sportif_goals', map);
  }

  @override
  Future<int> updateGoal(SportifGoalModel goal) async {
    final db = await _dbHelper.database;
    return await db.update(
      'sportif_goals',
      goal.toMap(),
      where: 'id = ?',
      whereArgs: [goal.id],
    );
  }

  @override
  Future<int> deleteGoal(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('sportif_goals', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<int> archiveGoal(int id) async {
    final db = await _dbHelper.database;
    return await db.update(
      'sportif_goals',
      {'is_archived': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // === User Preferences ===
  @override
  Future<String?> getPreference(String key) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'user_preferences',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return result.first['value'] as String;
  }

  @override
  Future<void> setPreference(String key, String value) async {
    final db = await _dbHelper.database;
    await db.insert(
      'user_preferences',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<String> getPreferredWeightUnit() async {
    final unit = await getPreference('preferred_weight_unit');
    return unit ?? 'KG'; // Default to KG
  }

  @override
  Future<void> setPreferredWeightUnit(String unit) async {
    if (unit != 'KG' && unit != 'LBS') {
      throw ArgumentError('Unit must be "KG" or "LBS"');
    }
    await setPreference('preferred_weight_unit', unit);
  }

  // === Complex Queries (JOIN Operations) ===
  @override
  Future<ExerciseDefinitionWithImpacts?> getExerciseWithImpacts(
      int exerciseId) async {
    // Get exercise definition
    final exercise = await getExerciseDefinitionById(exerciseId);
    if (exercise == null) return null;

    // Get muscle impacts
    final impacts = await getMuscleImpactsForExercise(exerciseId);

    return ExerciseDefinitionWithImpacts(
      exercise: exercise,
      impacts: impacts,
    );
  }

  @override
  Future<List<ExerciseWithImpact>> getExercisesForMuscleWithScores(
      int muscleId) async {
    final db = await _dbHelper.database;

    final result = await db.rawQuery('''
      SELECT 
        e.id,
        e.name,
        e.default_type,
        e.body_part,
        e.grip,
        e.style,
        e.types,
        e.is_archived,
        emi.impact_score
      FROM exercise_definitions e
      INNER JOIN exercise_muscle_impact emi ON e.id = emi.exercise_id
      WHERE emi.muscle_id = ? AND e.is_archived = 0
      ORDER BY emi.impact_score DESC, e.name ASC
    ''', [muscleId]);

    return result.map((map) {
      final exercise = ExerciseDefinition.fromMap({
        'id': map['id'],
        'name': map['name'],
        'default_type': map['default_type'],
        'body_part': map['body_part'],
        'grip': map['grip'],
        'style': map['style'],
        'types': map['types'],
        'is_archived': map['is_archived'],
      });
      return ExerciseWithImpact(
        exercise: exercise,
        impactScore: map['impact_score'] as int,
      );
    }).toList();
  }

  @override
  Future<List<ProgressiveOverloadData>> getProgressiveOverloadData({
    required int exerciseId,
    required DateTime from,
    required DateTime to,
  }) async {
    final db = await _dbHelper.database;

    // Get all sets for this exercise in the date range
    final result = await db.rawQuery('''
      SELECT 
        ws.date,
        SUM(wl.weight_kg * wl.reps) as total_volume,
        AVG(wl.rir) as avg_rir,
        AVG(wl.form_rating) as avg_form_rating
      FROM workout_logs wl
      INNER JOIN workout_sessions ws ON wl.session_id = ws.id
      WHERE wl.exercise_id = ? 
        AND ws.date >= ? 
        AND ws.date <= ?
      GROUP BY ws.date
      ORDER BY ws.date ASC
    ''', [
      exerciseId,
      from.millisecondsSinceEpoch,
      to.millisecondsSinceEpoch,
    ]);

    return result.map((map) {
      final date = DateTime.fromMillisecondsSinceEpoch(map['date'] as int);
      final totalVolume = (map['total_volume'] as num?)?.toDouble() ?? 0.0;
      final avgRir = (map['avg_rir'] as num?)?.toDouble();
      final avgFormRating = (map['avg_form_rating'] as num?)?.toDouble();

      // Calculate Effective Score
      // Formula: Volume * Intensity Factor * Quality Factor
      // Intensity Factor: Lower RIR = Higher intensity (inverse relationship)
      // Quality Factor: Higher form rating = Better quality
      double intensityFactor = 1.0;
      if (avgRir != null) {
        // RIR 0 = max intensity (factor 1.0), RIR 10 = low intensity (factor 0.5)
        intensityFactor = 1.0 - (avgRir / 20.0); // Scale: 0.5 to 1.0
        intensityFactor = intensityFactor.clamp(0.5, 1.0);
      }

      double qualityFactor = 1.0;
      if (avgFormRating != null) {
        // Form rating 10 = perfect (factor 1.0), Form rating 1 = poor (factor 0.7)
        qualityFactor = 0.7 + (avgFormRating / 10.0 * 0.3); // Scale: 0.7 to 1.0
        qualityFactor = qualityFactor.clamp(0.7, 1.0);
      }

      final effectiveScore = totalVolume * intensityFactor * qualityFactor;

      return ProgressiveOverloadData(
        date: date,
        effectiveScore: effectiveScore,
        totalVolume: totalVolume,
        avgRir: avgRir ?? 0.0,
        avgFormRating: avgFormRating ?? 0.0,
      );
    }).toList();
  }
}
