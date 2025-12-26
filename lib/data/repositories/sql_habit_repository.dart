import '../local_db/database_helper.dart';
import '../models/life_goal_model.dart';
import '../models/habit_model.dart';
import '../models/habit_log_model.dart';
import '../models/daily_rating_model.dart';
import '../repositories/i_habit_repository.dart';
import '../../utils/id_generator.dart';

class SqlHabitRepository implements IHabitRepository {
  final DatabaseHelper _dbHelper;

  SqlHabitRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  // === Life Goals ===
  @override
  Future<List<LifeGoalModel>> getAllGoals({bool includeArchived = false}) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'life_goals',
      where: includeArchived ? null : 'is_archived = 0',
      orderBy: 'title ASC',
    );
    return result.map(LifeGoalModel.fromMap).toList();
  }

  @override
  Future<LifeGoalModel?> getGoalById(String id) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'life_goals',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return LifeGoalModel.fromMap(result.first);
  }

  @override
  Future<String> createGoal(LifeGoalModel goal) async {
    final db = await _dbHelper.database;
    final id = goal.id.isNotEmpty ? goal.id : generateId();
    await db.insert('life_goals', goal.copyWith(id: id).toMap());
    return id;
  }

  @override
  Future<int> updateGoal(LifeGoalModel goal) async {
    final db = await _dbHelper.database;
    return db.update(
      'life_goals',
      goal.toMap(),
      where: 'id = ?',
      whereArgs: [goal.id],
    );
  }

  @override
  Future<int> deleteGoal(String id) async {
    final db = await _dbHelper.database;
    return db.delete('life_goals', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<int> archiveGoal(String id) async {
    final db = await _dbHelper.database;
    return db.update(
      'life_goals',
      {'is_archived': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // === Habits ===
  @override
  Future<List<HabitModel>> getAllHabits({bool includeArchived = false}) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'habits',
      where: includeArchived ? null : 'is_archived = 0',
      orderBy: 'title ASC',
    );
    return result.map(HabitModel.fromMap).toList();
  }

  @override
  Future<List<HabitModel>> getHabitsByGoal(String goalId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'habits',
      where: 'goal_id = ? AND is_archived = 0',
      whereArgs: [goalId],
      orderBy: 'title ASC',
    );
    return result.map(HabitModel.fromMap).toList();
  }

  @override
  Future<HabitModel?> getHabitById(String id) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'habits',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return HabitModel.fromMap(result.first);
  }

  @override
  Future<String> createHabit(HabitModel habit) async {
    final db = await _dbHelper.database;
    final id = habit.id.isNotEmpty ? habit.id : generateId();
    await db.insert('habits', habit.copyWith(id: id).toMap());
    return id;
  }

  @override
  Future<int> updateHabit(HabitModel habit) async {
    final db = await _dbHelper.database;
    return db.update(
      'habits',
      habit.toMap(),
      where: 'id = ?',
      whereArgs: [habit.id],
    );
  }

  @override
  Future<int> deleteHabit(String id) async {
    final db = await _dbHelper.database;
    // Also delete related logs
    await db.delete('habit_logs', where: 'habit_id = ?', whereArgs: [id]);
    return db.delete('habits', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<int> archiveHabit(String id) async {
    final db = await _dbHelper.database;
    return db.update(
      'habits',
      {'is_archived': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // === Habit Logs ===
  @override
  Future<List<HabitLogModel>> getLogsForDate(DateTime date) async {
    final db = await _dbHelper.database;
    final normalized = HabitLogModel.normalizeDate(date);
    final result = await db.query(
      'habit_logs',
      where: 'date = ?',
      whereArgs: [normalized.millisecondsSinceEpoch],
    );
    return result.map(HabitLogModel.fromMap).toList();
  }

  @override
  Future<List<HabitLogModel>> getLogsForHabit(
    String habitId, {
    DateTime? from,
    DateTime? to,
  }) async {
    final db = await _dbHelper.database;
    String where = 'habit_id = ?';
    List<dynamic> whereArgs = [habitId];

    if (from != null) {
      final normalizedFrom = HabitLogModel.normalizeDate(from);
      where += ' AND date >= ?';
      whereArgs.add(normalizedFrom.millisecondsSinceEpoch);
    }
    if (to != null) {
      final normalizedTo = HabitLogModel.normalizeDate(to);
      where += ' AND date <= ?';
      whereArgs.add(normalizedTo.millisecondsSinceEpoch);
    }

    final result = await db.query(
      'habit_logs',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'date DESC',
    );
    return result.map(HabitLogModel.fromMap).toList();
  }

  @override
  Future<void> setHabitCompletion(
    String habitId,
    DateTime date,
    bool isCompleted,
  ) async {
    final db = await _dbHelper.database;
    final normalized = HabitLogModel.normalizeDate(date);
    final timestamp = normalized.millisecondsSinceEpoch;

    // Check if entry exists
    final existing = await db.query(
      'habit_logs',
      where: 'date = ? AND habit_id = ?',
      whereArgs: [timestamp, habitId],
      limit: 1,
    );

    if (existing.isEmpty) {
      // Create new entry
      await db.insert('habit_logs', {
        'date': timestamp,
        'habit_id': habitId,
        'is_completed': isCompleted ? 1 : 0,
      });
    } else {
      // Update existing entry
      await db.update(
        'habit_logs',
        {'is_completed': isCompleted ? 1 : 0},
        where: 'date = ? AND habit_id = ?',
        whereArgs: [timestamp, habitId],
      );
    }
  }

  @override
  Future<bool> isHabitCompleted(String habitId, DateTime date) async {
    final db = await _dbHelper.database;
    final normalized = HabitLogModel.normalizeDate(date);
    final result = await db.query(
      'habit_logs',
      where: 'date = ? AND habit_id = ?',
      whereArgs: [normalized.millisecondsSinceEpoch, habitId],
      limit: 1,
    );
    if (result.isEmpty) return false;
    return (result.first['is_completed'] as int? ?? 0) == 1;
  }

  // === Daily Ratings ===
  @override
  Future<DailyRatingModel?> getRatingForDate(DateTime date) async {
    final db = await _dbHelper.database;
    final normalized = DailyRatingModel.normalizeDate(date);
    final result = await db.query(
      'daily_ratings',
      where: 'date = ?',
      whereArgs: [normalized.millisecondsSinceEpoch],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return DailyRatingModel.fromMap(result.first);
  }

  @override
  Future<List<DailyRatingModel>> getRatingsInRange(
    DateTime from,
    DateTime to,
  ) async {
    final db = await _dbHelper.database;
    final normalizedFrom = DailyRatingModel.normalizeDate(from);
    final normalizedTo = DailyRatingModel.normalizeDate(to);

    final result = await db.query(
      'daily_ratings',
      where: 'date >= ? AND date <= ?',
      whereArgs: [
        normalizedFrom.millisecondsSinceEpoch,
        normalizedTo.millisecondsSinceEpoch,
      ],
      orderBy: 'date DESC',
    );
    return result.map(DailyRatingModel.fromMap).toList();
  }

  @override
  Future<void> setDailyRating(DailyRatingModel rating) async {
    final db = await _dbHelper.database;
    final normalized = DailyRatingModel.normalizeDate(rating.date);
    final timestamp = normalized.millisecondsSinceEpoch;

    // Check if entry exists
    final existing = await db.query(
      'daily_ratings',
      where: 'date = ?',
      whereArgs: [timestamp],
      limit: 1,
    );

    if (existing.isEmpty) {
      // Create new entry
      await db.insert('daily_ratings', rating.copyWith(date: normalized).toMap());
    } else {
      // Update existing entry
      await db.update(
        'daily_ratings',
        {
          'score': rating.score,
          'note': rating.note,
        },
        where: 'date = ?',
        whereArgs: [timestamp],
      );
    }
  }

  @override
  Future<int> deleteDailyRating(DateTime date) async {
    final db = await _dbHelper.database;
    final normalized = DailyRatingModel.normalizeDate(date);
    return db.delete(
      'daily_ratings',
      where: 'date = ?',
      whereArgs: [normalized.millisecondsSinceEpoch],
    );
  }

  // === Export Data ===
  @override
  Future<List<({DateTime date, DailyRatingModel? rating, List<({HabitModel habit, LifeGoalModel? goal, bool completed})> habits})>> 
      getExportData({required DateTime from, required DateTime to}) async {
    
    final habits = await getAllHabits();
    final goals = await getAllGoals(includeArchived: true);
    final goalsMap = {for (final g in goals) g.id: g};

    final result = <({DateTime date, DailyRatingModel? rating, List<({HabitModel habit, LifeGoalModel? goal, bool completed})> habits})>[];

    // Iterate through each day in range
    var current = DailyRatingModel.normalizeDate(from);
    final end = DailyRatingModel.normalizeDate(to);

    while (!current.isAfter(end)) {
      final rating = await getRatingForDate(current);
      final logsForDate = await getLogsForDate(current);
      final completedIds = {
        for (final log in logsForDate)
          if (log.isCompleted) log.habitId
      };

      final habitData = <({HabitModel habit, LifeGoalModel? goal, bool completed})>[];
      for (final habit in habits) {
        habitData.add((
          habit: habit,
          goal: habit.goalId != null ? goalsMap[habit.goalId] : null,
          completed: completedIds.contains(habit.id),
        ));
      }

      result.add((
        date: current,
        rating: rating,
        habits: habitData,
      ));

      current = current.add(const Duration(days: 1));
    }

    return result;
  }
}

