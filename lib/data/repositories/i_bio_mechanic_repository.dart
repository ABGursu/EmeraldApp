import '../models/exercise_definition_model.dart';
import '../models/exercise_muscle_impact_model.dart';
import '../models/muscle_model.dart';
import '../models/routine_model.dart';
import '../models/routine_item_model.dart';
import '../models/sportif_goal_model.dart';
import '../models/workout_session_model.dart';
import '../models/workout_set_model.dart';

/// Interface for the Bio-Mechanic Training Management System repository.
abstract class IBioMechanicRepository {
  // === Muscles (Reference Table) ===
  Future<List<MuscleModel>> getAllMuscles();
  Future<List<MuscleModel>> getMusclesByGroup(String groupName);
  Future<MuscleModel?> getMuscleById(int id);
  Future<MuscleModel?> getMuscleByName(String name);

  // === Exercise Definitions (Enhanced) ===
  Future<List<ExerciseDefinition>> getAllExerciseDefinitions(
      {bool includeArchived = false});
  Future<ExerciseDefinition?> getExerciseDefinitionById(int id);
  Future<ExerciseDefinition?> getExerciseDefinitionByName(String name);
  Future<int> createExerciseDefinition(ExerciseDefinition definition);
  Future<int> updateExerciseDefinition(ExerciseDefinition definition);
  Future<int> deleteExerciseDefinition(int id);
  Future<int> archiveExerciseDefinition(int id);

  // === Exercise Muscle Impact (Bio-Mechanic Engine) ===
  Future<List<ExerciseMuscleImpactModel>> getMuscleImpactsForExercise(
      int exerciseId);
  Future<void> setExerciseMuscleImpacts(
    int exerciseId,
    List<ExerciseMuscleImpactModel> impacts,
  );
  Future<void> deleteExerciseMuscleImpacts(int exerciseId);

  // === Routines ===
  Future<List<Routine>> getAllRoutines();
  Future<Routine?> getRoutineById(int id);
  Future<List<RoutineItem>> getItemsByRoutineId(int routineId);
  Future<int> createRoutine(Routine routine);
  Future<void> updateRoutine(Routine routine);
  Future<void> deleteRoutine(int id);
  Future<int> createRoutineItem(RoutineItem item);
  Future<void> updateRoutineItem(RoutineItem item);
  Future<void> deleteRoutineItem(int id);
  Future<void> reorderRoutineItems(int routineId, List<int> itemIdsInOrder);

  // === Workout Sessions ===
  Future<List<WorkoutSessionModel>> getSessionsByDate(DateTime date);
  Future<List<WorkoutSessionModel>> getSessionsByDateRange({
    required DateTime from,
    required DateTime to,
  });
  Future<WorkoutSessionModel?> getSessionById(int id);
  Future<int> createSession(WorkoutSessionModel session);
  Future<int> updateSession(WorkoutSessionModel session);
  Future<int> deleteSession(int id);

  // === Workout Sets ===
  Future<List<WorkoutSetModel>> getSetsBySession(int sessionId);
  Future<List<WorkoutSetModel>> getSetsByExercise(int exerciseId);
  Future<WorkoutSetModel?> getSetById(int id);
  Future<int> createSet(WorkoutSetModel set);
  Future<int> updateSet(WorkoutSetModel set);
  Future<int> deleteSet(int id);
  Future<int> deleteSetsBySession(int sessionId);

  // === Sportif Goals ===
  Future<List<SportifGoalModel>> getAllGoals({bool includeArchived = false});
  Future<SportifGoalModel?> getGoalById(int id);
  Future<int> createGoal(SportifGoalModel goal);
  Future<int> updateGoal(SportifGoalModel goal);
  Future<int> deleteGoal(int id);
  Future<int> archiveGoal(int id);

  // === User Preferences ===
  Future<String?> getPreference(String key);
  Future<void> setPreference(String key, String value);
  Future<String> getPreferredWeightUnit(); // Returns "KG" or "LBS"
  Future<void> setPreferredWeightUnit(String unit); // "KG" or "LBS"

  // === Complex Queries (JOIN Operations) ===
  /// Get exercise definition with all its muscle impacts
  Future<ExerciseDefinitionWithImpacts?> getExerciseWithImpacts(int exerciseId);

  /// Get all exercises that target a specific muscle (with impact scores)
  Future<List<ExerciseWithImpact>> getExercisesForMuscleWithScores(
      int muscleId);

  /// Calculate progressive overload data for an exercise
  Future<List<ProgressiveOverloadData>> getProgressiveOverloadData({
    required int exerciseId,
    required DateTime from,
    required DateTime to,
  });
}

/// Helper class for exercise with muscle impacts
class ExerciseDefinitionWithImpacts {
  final ExerciseDefinition exercise;
  final List<ExerciseMuscleImpactModel> impacts;

  ExerciseDefinitionWithImpacts({
    required this.exercise,
    required this.impacts,
  });
}

/// Helper class for exercise with impact score for a specific muscle
class ExerciseWithImpact {
  final ExerciseDefinition exercise;
  final int impactScore;

  ExerciseWithImpact({
    required this.exercise,
    required this.impactScore,
  });
}

/// Progressive overload calculation data point
class ProgressiveOverloadData {
  final DateTime date;
  final double
      effectiveScore; // Calculated: (Volume * Intensity Factor * Quality Factor)
  final double totalVolume; // Sum of (weight_kg * reps) for all sets
  final double avgRir; // Average RIR (lower = higher intensity)
  final double avgFormRating; // Average form rating

  ProgressiveOverloadData({
    required this.date,
    required this.effectiveScore,
    required this.totalVolume,
    required this.avgRir,
    required this.avgFormRating,
  });
}
