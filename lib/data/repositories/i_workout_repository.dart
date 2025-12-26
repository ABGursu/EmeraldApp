import '../models/exercise_dictionary_model.dart';
import '../models/routine_item_model.dart';
import '../models/routine_model.dart';
import '../models/workout_entry_model.dart';
import '../models/workout_session_model.dart';

abstract class IWorkoutRepository {
  Future<String> createExercise(ExerciseDictionaryModel exercise);
  Future<int> updateExercise(ExerciseDictionaryModel exercise);
  Future<int> deleteExercise(String id);
  Future<List<ExerciseDictionaryModel>> getAllExercises();

  Future<String> createSession(WorkoutSessionModel session);
  Future<int> updateSession(WorkoutSessionModel session);
  Future<int> deleteSession(String id);
  Future<List<WorkoutSessionModel>> getSessions();

  Future<String> createEntry(WorkoutEntryModel entry);
  Future<int> updateEntry(WorkoutEntryModel entry);
  Future<int> deleteEntry(String id);
  Future<List<WorkoutEntryModel>> getEntriesBySession(String sessionId);

  Future<String> createRoutine(RoutineModel routine);
  Future<int> updateRoutine(RoutineModel routine);
  Future<int> deleteRoutine(String id);
  Future<List<RoutineModel>> getAllRoutines();

  Future<String> createRoutineItem(RoutineItemModel item);
  Future<int> updateRoutineItem(RoutineItemModel item);
  Future<int> deleteRoutineItem(String id);
  Future<List<RoutineItemModel>> getItemsByRoutine(String routineId);
}

