import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/models/exercise_definition_model.dart';
import '../../data/models/exercise_muscle_impact_model.dart';
import '../../data/models/muscle_model.dart';
import '../../data/models/routine_model.dart';
import '../../data/models/routine_item_model.dart';
import '../../data/models/sportif_goal_model.dart';
import '../../data/models/workout_session_model.dart';
import '../../data/models/workout_set_model.dart';
import '../../data/repositories/i_bio_mechanic_repository.dart';
import '../../data/repositories/sql_bio_mechanic_repository.dart';
import 'goal_contribution_entry.dart';
import '../../utils/date_formats.dart';

/// ViewModel for the Bio-Mechanic Training Management System.
class BioMechanicViewModel extends ChangeNotifier {
  BioMechanicViewModel({IBioMechanicRepository? repository})
      : _repository = repository ?? SqlBioMechanicRepository();

  final IBioMechanicRepository _repository;

  // === State ===
  bool _loading = false;
  String _preferredUnit = 'KG'; // Default to KG

  // Muscles
  List<MuscleModel> _muscles = [];

  // Distinct body parts taken from exercise definitions (Excel-driven)
  List<String> _bodyParts = [];

  // Exercise Definitions
  List<ExerciseDefinition> _exerciseDefinitions = [];
  String _exerciseSearchQuery = '';
  String? _selectedBodyPart;

  // Exercise Muscle Impacts (for current exercise being edited)
  List<ExerciseMuscleImpactModel> _currentExerciseImpacts = [];
  int? _currentExerciseId;

  // Workout Sessions
  DateTime _selectedDate = DateTime.now();
  List<WorkoutSessionModel> _sessions = [];
  WorkoutSessionModel? _currentSession;

  // Workout Sets (for current session)
  List<WorkoutSetModel> _currentSessionSets = [];
  Map<int, List<WorkoutSetModel>> _setsByExercise = {}; // exerciseId -> sets

  // Routines
  List<Routine> _routines = [];

  // Sports Goals
  List<SportifGoalModel> _goals = [];

  // Progressive Overload Data
  int? _selectedExerciseForAnalytics;
  List<ProgressiveOverloadData> _progressiveOverloadData = [];

  // === Getters ===
  bool get isLoading => _loading;
  String get preferredUnit => _preferredUnit;
  bool get isLbs => _preferredUnit == 'LBS';

  // Muscles
  List<MuscleModel> get muscles => _muscles;

  /// Distinct body-part values available for filtering exercises.
  /// Populated from exercise definitions (e.g. "Quadriceps", "Lats", ...).
  List<String> get bodyParts => _bodyParts;
  List<MuscleModel> getMusclesByGroup(String group) {
    return _muscles.where((m) => m.groupName == group).toList();
  }

  // Exercise Definitions
  List<ExerciseDefinition> get exerciseDefinitions => _exerciseDefinitions;
  String get exerciseSearchQuery => _exerciseSearchQuery;
  String? get selectedBodyPart => _selectedBodyPart;

  List<ExerciseDefinition> get filteredExerciseDefinitions {
    var filtered = _exerciseDefinitions;

    // Filter by search query
    if (_exerciseSearchQuery.isNotEmpty) {
      final query = _exerciseSearchQuery.toLowerCase();
      filtered =
          filtered.where((e) => e.name.toLowerCase().contains(query)).toList();
    }

    // Filter by body part
    if (_selectedBodyPart != null) {
      filtered =
          filtered.where((e) => e.bodyPart == _selectedBodyPart).toList();
    }

    return filtered;
  }

  // Exercise Muscle Impacts
  List<ExerciseMuscleImpactModel> get currentExerciseImpacts =>
      _currentExerciseImpacts;
  int? get currentExerciseId => _currentExerciseId;

  // Workout Sessions
  DateTime get selectedDate => _selectedDate;
  List<WorkoutSessionModel> get sessions => _sessions;
  WorkoutSessionModel? get currentSession => _currentSession;

  // Workout Sets
  List<WorkoutSetModel> get currentSessionSets => _currentSessionSets;
  List<WorkoutSetModel> getSetsForExercise(int exerciseId) {
    return _setsByExercise[exerciseId] ?? [];
  }

  // Routines
  List<Routine> get routines => _routines;

  // Sports Goals
  List<SportifGoalModel> get goals => _goals;
  List<SportifGoalModel> get activeGoals {
    return _goals.where((g) => !g.isArchived).toList();
  }

  // Progressive Overload
  int? get selectedExerciseForAnalytics => _selectedExerciseForAnalytics;
  List<ProgressiveOverloadData> get progressiveOverloadData =>
      _progressiveOverloadData;

  // === Unit Conversion ===
  /// Convert KG to display unit (KG or LBS)
  double convertWeightForDisplay(double weightKg) {
    if (_preferredUnit == 'LBS') {
      return weightKg * 2.20462;
    }
    return weightKg;
  }

  /// Convert display unit (KG or LBS) to KG for storage
  double convertWeightForStorage(double weight, String fromUnit) {
    if (fromUnit == 'LBS') {
      return weight / 2.20462;
    }
    return weight;
  }

  /// Get weight unit suffix ("kg" or "lbs")
  String get weightUnitSuffix => _preferredUnit == 'LBS' ? 'lbs' : 'kg';

  /// Set preferred weight unit
  Future<void> setPreferredUnit(String unit) async {
    if (unit != 'KG' && unit != 'LBS') {
      throw ArgumentError('Unit must be "KG" or "LBS"');
    }
    _preferredUnit = unit;
    await _repository.setPreferredWeightUnit(unit);
    notifyListeners();
  }

  // === Initialization ===
  Future<void> init() async {
    _loading = true;
    notifyListeners();

    try {
      // Load preferred unit
      _preferredUnit = await _repository.getPreferredWeightUnit();

      // Load all data
      await Future.wait([
        loadMuscles(),
        loadExerciseDefinitions(),
        loadRoutines(),
        loadGoals(),
        loadSessionsForDate(_selectedDate),
      ]);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // === Muscles ===
  Future<void> loadMuscles() async {
    _muscles = await _repository.getAllMuscles();
    notifyListeners();
  }

  // === Exercise Definitions ===
  Future<void> loadExerciseDefinitions({bool includeArchived = false}) async {
    _exerciseDefinitions = await _repository.getAllExerciseDefinitions(
        includeArchived: includeArchived);

    // Refresh available body-part filters based on current definitions.
    _bodyParts = _exerciseDefinitions
        .map((e) => e.bodyPart)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort();

    notifyListeners();
  }

  void setExerciseSearchQuery(String query) {
    _exerciseSearchQuery = query;
    notifyListeners();
  }

  void setSelectedBodyPart(String? bodyPart) {
    _selectedBodyPart = bodyPart;
    notifyListeners();
  }

  Future<int> createExerciseDefinition(ExerciseDefinition definition) async {
    final id = await _repository.createExerciseDefinition(definition);
    await loadExerciseDefinitions();
    return id;
  }

  Future<void> updateExerciseDefinition(ExerciseDefinition definition) async {
    await _repository.updateExerciseDefinition(definition);
    await loadExerciseDefinitions();
  }

  Future<void> deleteExerciseDefinition(int id) async {
    await _repository.deleteExerciseDefinition(id);
    await loadExerciseDefinitions();
  }

  /// Remove duplicate exercises (same name as Excel), re-seed from Excel. Result: 153 exercises from Excel. User-created exercises with names not in Excel are kept.
  Future<void> resetExercisesToExcelOnly() async {
    await _repository.resetExercisesToExcelOnly();
    await loadExerciseDefinitions();
    notifyListeners();
  }

  Future<void> archiveExerciseDefinition(int id) async {
    await _repository.archiveExerciseDefinition(id);
    await loadExerciseDefinitions();
  }

  // === Exercise Muscle Impacts ===
  Future<void> loadExerciseImpacts(int exerciseId) async {
    _currentExerciseId = exerciseId;
    _currentExerciseImpacts =
        await _repository.getMuscleImpactsForExercise(exerciseId);
    notifyListeners();
  }

  void setExerciseImpacts(List<ExerciseMuscleImpactModel> impacts) {
    _currentExerciseImpacts = impacts;
    notifyListeners();
  }

  Future<void> saveExerciseImpacts(int exerciseId) async {
    await _repository.setExerciseMuscleImpacts(
        exerciseId, _currentExerciseImpacts);
    await loadExerciseImpacts(exerciseId);
  }

  void clearExerciseImpacts() {
    _currentExerciseId = null;
    _currentExerciseImpacts = [];
    notifyListeners();
  }

  // === Workout Sessions ===
  Future<void> setSelectedDate(DateTime date) async {
    _selectedDate = date;
    await loadSessionsForDate(date);
  }

  Future<void> loadSessionsForDate(DateTime date) async {
    _sessions = await _repository.getSessionsByDate(date);
    notifyListeners();
  }

  Future<void> loadSessionsByDateRange({
    required DateTime from,
    required DateTime to,
  }) async {
    _sessions = await _repository.getSessionsByDateRange(from: from, to: to);
    notifyListeners();
  }

  Future<int> createSession(WorkoutSessionModel session) async {
    final id = await _repository.createSession(session);
    await loadSessionsForDate(session.date);
    return id;
  }

  Future<void> updateSession(WorkoutSessionModel session) async {
    await _repository.updateSession(session);
    await loadSessionsForDate(session.date);
  }

  Future<void> deleteSession(int id) async {
    final session = await _repository.getSessionById(id);
    if (session != null) {
      await _repository.deleteSession(id);
      await loadSessionsForDate(session.date);
    }
  }

  Future<void> loadSession(int sessionId) async {
    _currentSession = await _repository.getSessionById(sessionId);
    if (_currentSession != null) {
      await loadSetsForSession(sessionId);
    }
    notifyListeners();
  }

  void clearCurrentSession() {
    _currentSession = null;
    _currentSessionSets = [];
    _setsByExercise = {};
    notifyListeners();
  }

  // === Workout Sets ===
  Future<void> loadSetsForSession(int sessionId) async {
    _currentSessionSets = await _repository.getSetsBySession(sessionId);

    // Group sets by exercise
    _setsByExercise = {};
    for (final set in _currentSessionSets) {
      _setsByExercise.putIfAbsent(set.exerciseId, () => []).add(set);
    }

    // Sort sets within each exercise by set_number
    for (final exerciseId in _setsByExercise.keys) {
      _setsByExercise[exerciseId]!
          .sort((a, b) => a.setNumber.compareTo(b.setNumber));
    }

    notifyListeners();
  }

  Future<int> createSet(WorkoutSetModel set) async {
    final id = await _repository.createSet(set);
    if (_currentSession != null) {
      await loadSetsForSession(_currentSession!.id);
    }
    return id;
  }

  Future<void> updateSet(WorkoutSetModel set) async {
    await _repository.updateSet(set);
    if (_currentSession != null) {
      await loadSetsForSession(_currentSession!.id);
    }
  }

  Future<void> deleteSet(int setId) async {
    await _repository.deleteSet(setId);
    if (_currentSession != null) {
      await loadSetsForSession(_currentSession!.id);
    }
  }

  /// Get all sets for an exercise within the current session
  List<WorkoutSetModel> getSetsForExerciseInSession(int exerciseId) {
    if (_currentSession == null) return [];
    return _currentSessionSets.where((s) => s.exerciseId == exerciseId).toList()
      ..sort((a, b) => a.setNumber.compareTo(b.setNumber));
  }

  /// Get next set number for an exercise in the current session
  int getNextSetNumber(int exerciseId) {
    final sets = getSetsForExerciseInSession(exerciseId);
    if (sets.isEmpty) return 1;
    return sets.map((s) => s.setNumber).reduce((a, b) => a > b ? a : b) + 1;
  }

  // === Routines ===
  Future<void> loadRoutines() async {
    _routines = await _repository.getAllRoutines();
    notifyListeners();
  }

  Future<Routine?> getRoutineById(int id) async {
    return await _repository.getRoutineById(id);
  }

  Future<List<RoutineItem>> getRoutineItems(int routineId) async {
    return await _repository.getItemsByRoutineId(routineId);
  }

  Future<int> createRoutine(Routine routine) async {
    final id = await _repository.createRoutine(routine);
    await loadRoutines();
    return id;
  }

  Future<void> updateRoutine(Routine routine) async {
    await _repository.updateRoutine(routine);
    await loadRoutines();
  }

  Future<void> deleteRoutine(int id) async {
    await _repository.deleteRoutine(id);
    await loadRoutines();
  }

  Future<int> createRoutineItem(RoutineItem item) async {
    final id = await _repository.createRoutineItem(item);
    return id;
  }

  Future<void> updateRoutineItem(RoutineItem item) async {
    await _repository.updateRoutineItem(item);
  }

  Future<void> deleteRoutineItem(int id) async {
    await _repository.deleteRoutineItem(id);
  }

  /// Creates a workout session from a routine.
  /// [date] if null uses selectedDate (e.g. from Daily Logger).
  Future<int> createSessionFromRoutine({
    required int routineId,
    String? titleOverride,
    DateTime? date,
  }) async {
    final routine = await _repository.getRoutineById(routineId);
    if (routine == null) {
      throw StateError('Routine not found: $routineId');
    }
    final sessionDate = date ?? _selectedDate;
    final session = WorkoutSessionModel(
      id: 0,
      date: sessionDate,
      startTime: null,
      title: titleOverride ?? routine.name,
      durationMinutes: null,
      rating: null,
      goalTags: const [],
      routineId: routineId,
      createdAt: DateTime.now(),
    );
    final id = await _repository.createSession(session);
    await loadSessionsForDate(sessionDate);
    return id;
  }

  // === Sports Goals ===
  Future<void> loadGoals({bool includeArchived = false}) async {
    _goals = await _repository.getAllGoals(includeArchived: includeArchived);
    notifyListeners();
  }

  Future<int> createGoal(SportifGoalModel goal) async {
    final id = await _repository.createGoal(goal);
    await loadGoals();
    return id;
  }

  Future<void> updateGoal(SportifGoalModel goal) async {
    await _repository.updateGoal(goal);
    await loadGoals();
  }

  Future<void> deleteGoal(int id) async {
    await _repository.deleteGoal(id);
    await loadGoals();
  }

  Future<void> archiveGoal(int id) async {
    await _repository.archiveGoal(id);
    await loadGoals();
  }

  /// Returns, for a given goal and date range, which sessions and exercises
  /// contributed to that goal on each day.
  ///
  /// A session contributes if:
  /// - The session's goalTags contains the goal's name, AND
  /// - At least one exercise in that session matches the goal's linked styles
  ///   or types.
  ///
  /// The result is a map keyed by date-only (00:00) with a list of
  /// (session, exercises) entries.
  Future<Map<DateTime, List<GoalContributionEntry>>>
      getGoalDailyExerciseContributions({
    required SportifGoalModel goal,
    required DateTime from,
    required DateTime to,
  }) async {
    // Ensure we have exercise definitions loaded
    if (_exerciseDefinitions.isEmpty) {
      await loadExerciseDefinitions();
    }

    // Normalize filters
    final styleSet = goal.styles
        .map((s) => s.toLowerCase().trim())
        .where((s) => s.isNotEmpty)
        .toSet();
    final typeSet = goal.types
        .map((t) => t.toLowerCase().trim())
        .where((t) => t.isNotEmpty)
        .toSet();

    if (styleSet.isEmpty && typeSet.isEmpty) {
      return {};
    }

    // Get all sessions in range
    final sessions =
        await _repository.getSessionsByDateRange(from: from, to: to);

    // Filter sessions tagged with this goal by name
    final taggedSessions =
        sessions.where((s) => s.goalTags.contains(goal.name)).toList();

    if (taggedSessions.isEmpty) {
      return {};
    }

    final Map<DateTime, List<GoalContributionEntry>> result = {};

    for (final session in taggedSessions) {
      // Get all sets for this session
      final sets = await _repository.getSetsBySession(session.id);
      if (sets.isEmpty) continue;

      // Unique exercise IDs in this session
      final exerciseIds = sets.map((s) => s.exerciseId).toSet();

      // Map IDs to definitions
      final List<ExerciseDefinition> contributingExercises = [];
      for (final id in exerciseIds) {
        final ex = _exerciseDefinitions.firstWhere(
          (e) => e.id == id,
          orElse: () => ExerciseDefinition(
            id: id,
            name: 'Unknown Exercise',
          ),
        );

        final style = ex.style?.toLowerCase().trim();
        final typesLower = ex.types.map((t) => t.toLowerCase().trim()).toSet();

        final matchesStyle =
            style != null && style.isNotEmpty && styleSet.contains(style);
        final matchesType =
            typeSet.isNotEmpty && typesLower.any((t) => typeSet.contains(t));

        if (matchesStyle || matchesType) {
          contributingExercises.add(ex);
        }
      }

      if (contributingExercises.isEmpty) continue;

      final dayKey =
          DateTime(session.date.year, session.date.month, session.date.day);
      final entry = GoalContributionEntry(
        session: session,
        exercises: contributingExercises,
      );
      result.putIfAbsent(dayKey, () => []).add(entry);
    }

    return result;
  }

  // === Progressive Overload Analytics ===
  Future<void> loadProgressiveOverloadData({
    required int exerciseId,
    required DateTime from,
    required DateTime to,
  }) async {
    _selectedExerciseForAnalytics = exerciseId;
    _progressiveOverloadData = await _repository.getProgressiveOverloadData(
      exerciseId: exerciseId,
      from: from,
      to: to,
    );
    notifyListeners();
  }

  /// Calculate trend (positive = improving, negative = declining)
  double? get progressiveOverloadTrend {
    if (_progressiveOverloadData.length < 2) return null;

    final first = _progressiveOverloadData.first.effectiveScore;
    final last = _progressiveOverloadData.last.effectiveScore;

    return last - first;
  }

  /// Check if trend is positive (green) or negative/neutral (red)
  bool get isProgressiveOverloadPositive {
    final trend = progressiveOverloadTrend;
    if (trend == null) return false;
    return trend > 0;
  }

  // === Export (Daily Logger) ===
  Future<String> exportDailyLogger({
    required DateTime from,
    required DateTime to,
  }) async {
    // Load all sessions in range
    final sessionsInRange =
        await _repository.getSessionsByDateRange(from: from, to: to);

    final buffer = StringBuffer();

    if (sessionsInRange.isEmpty) {
      buffer.writeln('No workout sessions in this period.');
    } else {
      // Group sessions by date (day)
      final Map<DateTime, List<WorkoutSessionModel>> sessionsByDate = {};
      for (final session in sessionsInRange) {
        final d = session.date;
        final key = DateTime(d.year, d.month, d.day);
        sessionsByDate.putIfAbsent(key, () => []).add(session);
      }

      final sortedDates = sessionsByDate.keys.toList()
        ..sort((a, b) => a.compareTo(b));

      for (final day in sortedDates) {
        buffer.writeln(formatDate(day));
        buffer.writeln('----------------------------------------');

        final daySessions = sessionsByDate[day]!;
        // Sort by start time then createdAt (already in repository order, but be explicit)
        daySessions.sort((a, b) {
          final at =
              a.startTime ?? DateTime(a.date.year, a.date.month, a.date.day);
          final bt =
              b.startTime ?? DateTime(b.date.year, b.date.month, b.date.day);
          return at.compareTo(bt);
        });

        for (final session in daySessions) {
          final title = session.title ?? 'Workout Session';
          final timeStr = session.startTime != null
              ? ' at ${formatDateTime(session.startTime!)}'
              : '';
          final tagsStr = session.goalTags.isNotEmpty
              ? ' [Tags: ${session.goalTags.join(', ')}]'
              : '';

          buffer.writeln('$title$timeStr$tagsStr');

          // Load sets for this session
          final sets = await _repository.getSetsBySession(session.id);
          if (sets.isEmpty) {
            buffer.writeln('  (No sets logged)');
          } else {
            // Group by exerciseId
            final Map<int, List<WorkoutSetModel>> setsByExercise = {};
            for (final set in sets) {
              setsByExercise.putIfAbsent(set.exerciseId, () => []).add(set);
            }

            for (final entry in setsByExercise.entries) {
              final exerciseId = entry.key;
              final exerciseSets = entry.value
                ..sort((a, b) => a.setNumber.compareTo(b.setNumber));

              final exercise = _exerciseDefinitions.firstWhere(
                (e) => e.id == exerciseId,
                orElse: () => ExerciseDefinition(
                  id: exerciseId,
                  name: 'Unknown Exercise',
                ),
              );

              buffer.writeln('  ${exercise.name}');

              for (final set in exerciseSets) {
                final weightStr = set.weightKg != null
                    ? ' @ ${convertWeightForDisplay(set.weightKg!).toStringAsFixed(1)} $weightUnitSuffix'
                    : '';
                final rirStr = set.rir != null ? ' | RIR: ${set.rir}' : '';
                final formStr = set.formRating != null
                    ? ' | Form: ${set.formRating}/10'
                    : '';
                final noteStr = set.note != null && set.note!.isNotEmpty
                    ? ' | Note: ${set.note}'
                    : '';

                buffer.writeln(
                    '    Set ${set.setNumber}: ${set.reps} reps$weightStr$rirStr$formStr$noteStr');
              }
            }
          }

          buffer.writeln();
        }
      }
    }

    final directory = await _getExportDir();
    final fromStr = formatDateForFilename(from);
    final toStr = formatDateForFilename(to);
    final fileName = 'bio_mechanic_daily_logger_$fromStr-$toStr.txt';
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(buffer.toString());
    return file.path;
  }

  Future<Directory> _getExportDir() async {
    const preferredPath = '/storage/emulated/0/Documents/EmeraldApp';
    Directory dir = Directory(preferredPath);
    try {
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      // Test write access
      final testFile = File('${dir.path}/.test_write');
      try {
        await testFile.writeAsString('test');
        await testFile.delete();
      } catch (e) {
        // If write fails, fallback to app directory
        throw Exception('Write permission denied for preferred path: $e');
      }
      return dir;
    } catch (e) {
      // Fallback to app-specific directory (always accessible)
      final externalDir = await getExternalStorageDirectory();
      final base = externalDir ?? await getApplicationDocumentsDirectory();
      dir = Directory('${base.path}/Documents/EmeraldApp');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    }
  }

  /// Get exercise definition with muscle impacts
  Future<ExerciseDefinitionWithImpacts?> getExerciseWithImpacts(
      int exerciseId) async {
    return await _repository.getExerciseWithImpacts(exerciseId);
  }

}
