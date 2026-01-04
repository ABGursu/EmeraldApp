import 'package:flutter/material.dart';

import '../../data/models/exercise_definition_model.dart';
import '../../data/models/exercise_muscle_impact_model.dart';
import '../../data/models/muscle_model.dart';
import '../../data/models/sportif_goal_model.dart';
import '../../data/models/workout_session_model.dart';
import '../../data/models/workout_set_model.dart';
import '../../data/repositories/i_bio_mechanic_repository.dart';
import '../../data/repositories/sql_bio_mechanic_repository.dart';

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
  List<String> _muscleGroups = [];

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

  // Sportif Goals
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
  List<String> get muscleGroups => _muscleGroups;
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
      filtered = filtered
          .where((e) => e.name.toLowerCase().contains(query))
          .toList();
    }

    // Filter by body part
    if (_selectedBodyPart != null) {
      filtered = filtered
          .where((e) => e.bodyPart == _selectedBodyPart)
          .toList();
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

  // Sportif Goals
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
    _muscleGroups = _muscles.map((m) => m.groupName).toSet().toList()..sort();
    notifyListeners();
  }

  // === Exercise Definitions ===
  Future<void> loadExerciseDefinitions({bool includeArchived = false}) async {
    _exerciseDefinitions =
        await _repository.getAllExerciseDefinitions(includeArchived: includeArchived);
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
    await _repository.setExerciseMuscleImpacts(exerciseId, _currentExerciseImpacts);
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
      _setsByExercise[exerciseId]!.sort((a, b) => a.setNumber.compareTo(b.setNumber));
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
    return _currentSessionSets
        .where((s) => s.exerciseId == exerciseId)
        .toList()
      ..sort((a, b) => a.setNumber.compareTo(b.setNumber));
  }

  /// Get next set number for an exercise in the current session
  int getNextSetNumber(int exerciseId) {
    final sets = getSetsForExerciseInSession(exerciseId);
    if (sets.isEmpty) return 1;
    return sets.map((s) => s.setNumber).reduce((a, b) => a > b ? a : b) + 1;
  }

  // === Sportif Goals ===
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

  /// Get exercise definition with muscle impacts
  Future<ExerciseDefinitionWithImpacts?> getExerciseWithImpacts(int exerciseId) async {
    return await _repository.getExerciseWithImpacts(exerciseId);
  }

  /// Get exercises that target a specific muscle
  Future<List<ExerciseWithImpact>> getExercisesForMuscle(int muscleId) async {
    return await _repository.getExercisesForMuscleWithScores(muscleId);
  }
}

