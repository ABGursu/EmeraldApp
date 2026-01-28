import '../../data/models/workout_session_model.dart';
import '../../data/models/exercise_definition_model.dart';

/// Lightweight DTO used for Sportif Goal analytics:
/// which exercises in which sessions contributed to a goal.
class GoalContributionEntry {
  final WorkoutSessionModel session;
  final List<ExerciseDefinition> exercises;

  GoalContributionEntry({
    required this.session,
    required this.exercises,
  });
}
