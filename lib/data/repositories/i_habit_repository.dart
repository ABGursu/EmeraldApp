import '../models/life_goal_model.dart';
import '../models/habit_model.dart';
import '../models/habit_log_model.dart';
import '../models/daily_rating_model.dart';

/// Interface for the Habit & Goal module repository.
abstract class IHabitRepository {
  // === Life Goals ===
  Future<List<LifeGoalModel>> getAllGoals({bool includeArchived = false});
  Future<LifeGoalModel?> getGoalById(String id);
  Future<String> createGoal(LifeGoalModel goal);
  Future<int> updateGoal(LifeGoalModel goal);
  Future<int> deleteGoal(String id);
  Future<int> archiveGoal(String id);

  // === Habits ===
  Future<List<HabitModel>> getAllHabits({bool includeArchived = false});
  Future<List<HabitModel>> getHabitsByGoal(String goalId);
  Future<HabitModel?> getHabitById(String id);
  Future<String> createHabit(HabitModel habit);
  Future<int> updateHabit(HabitModel habit);
  Future<int> deleteHabit(String id);
  Future<int> archiveHabit(String id);

  // === Habit Logs ===
  Future<List<HabitLogModel>> getLogsForDate(DateTime date);
  Future<List<HabitLogModel>> getLogsForHabit(String habitId,
      {DateTime? from, DateTime? to});
  Future<void> setHabitCompletion(
      String habitId, DateTime date, bool isCompleted);
  Future<bool> isHabitCompleted(String habitId, DateTime date);

  // === Daily Ratings ===
  Future<DailyRatingModel?> getRatingForDate(DateTime date);
  Future<List<DailyRatingModel>> getRatingsInRange(DateTime from, DateTime to);
  Future<void> setDailyRating(DailyRatingModel rating);
  Future<int> deleteDailyRating(DateTime date);

  // === Export Data ===
  Future<List<({DateTime date, DailyRatingModel? rating, List<({HabitModel habit, LifeGoalModel? goal, bool completed})> habits})>> 
      getExportData({required DateTime from, required DateTime to});
}

