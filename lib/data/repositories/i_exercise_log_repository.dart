import '../models/exercise_definition_model.dart';
import '../models/routine_model.dart';
import '../models/routine_item_model.dart';
import '../models/user_stats_model.dart';
import '../models/workout_log_model.dart';

abstract class IExerciseLogRepository {
  // Exercise Definition CRUD
  Future<int> createExerciseDefinition(ExerciseDefinition definition);
  Future<int> updateExerciseDefinition(ExerciseDefinition definition);
  Future<int> deleteExerciseDefinition(int id);
  Future<List<ExerciseDefinition>> getAllExerciseDefinitions();
  Future<ExerciseDefinition?> getExerciseDefinitionByName(String name);

  // Routine CRUD
  Future<int> createRoutine(Routine routine);
  Future<int> updateRoutine(Routine routine);
  Future<int> deleteRoutine(int id);
  Future<List<Routine>> getAllRoutines();
  Future<Routine?> getRoutineById(int id);

  // Routine Item CRUD
  Future<int> createRoutineItem(RoutineItem item);
  Future<int> updateRoutineItem(RoutineItem item);
  Future<int> deleteRoutineItem(int id);
  Future<List<RoutineItem>> getRoutineItemsByRoutineId(int routineId);
  Future<void> deleteRoutineItemsByRoutineId(int routineId);

  // Workout Log CRUD
  Future<int> createWorkoutLog(WorkoutLog log);
  Future<int> updateWorkoutLog(WorkoutLog log);
  Future<int> deleteWorkoutLog(int id);
  Future<List<WorkoutLog>> getWorkoutLogsByDate(DateTime date);
  Future<List<WorkoutLog>> getWorkoutLogsByDateRange(
    DateTime from,
    DateTime to,
  );
  Future<void> reorderWorkoutLogs(List<WorkoutLog> logs);
  Future<WorkoutLog?> getLastLogForExercise(String exerciseName);

  // User Stats
  Future<UserStats> getUserStats();
  Future<int> updateUserStats(UserStats stats);

  // Movement Types
  Future<List<String>> getAllMovementTypes();
  Future<void> addMovementType(String type);
  Future<void> deleteMovementType(String type);
}
