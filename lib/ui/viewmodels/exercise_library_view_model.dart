import 'package:flutter/material.dart';

import '../../data/models/exercise_definition_model.dart';
import '../../data/models/routine_model.dart';
import '../../data/models/routine_item_model.dart';
import '../../data/repositories/i_exercise_log_repository.dart';
import '../../data/repositories/sql_exercise_log_repository.dart';

class ExerciseLibraryViewModel extends ChangeNotifier {
  ExerciseLibraryViewModel({IExerciseLogRepository? repository})
      : _repository = repository ?? SqlExerciseLogRepository();

  final IExerciseLogRepository _repository;

  List<ExerciseDefinition> _exerciseDefinitions = [];
  List<Routine> _routines = [];
  bool _loading = false;
  String _exerciseSearchQuery = '';
  String _routineSearchQuery = '';
  String? _selectedBodyPart;

  List<ExerciseDefinition> get exerciseDefinitions => _exerciseDefinitions;
  List<Routine> get routines => _routines;
  bool get isLoading => _loading;

  // Filtered getters
  List<ExerciseDefinition> get filteredExerciseDefinitions {
    var filtered = _exerciseDefinitions;

    // Filter by body part
    if (_selectedBodyPart != null && _selectedBodyPart!.isNotEmpty) {
      filtered = filtered
          .where((e) => e.bodyPart == _selectedBodyPart)
          .toList();
    }

    // Filter by search query
    if (_exerciseSearchQuery.isNotEmpty) {
      final query = _exerciseSearchQuery.toLowerCase();
      filtered = filtered
          .where((e) => e.name.toLowerCase().contains(query))
          .toList();
    }

    return filtered;
  }

  List<Routine> get filteredRoutines {
    if (_routineSearchQuery.isEmpty) {
      return _routines;
    }
    final query = _routineSearchQuery.toLowerCase();
    return _routines
        .where((r) => r.name.toLowerCase().contains(query))
        .toList();
  }

  // Unique body parts for filtering
  List<String> get uniqueBodyParts {
    final bodyParts = _exerciseDefinitions
        .where((e) => e.bodyPart != null && e.bodyPart!.isNotEmpty)
        .map((e) => e.bodyPart!)
        .toSet()
        .toList();
    bodyParts.sort();
    return bodyParts;
  }

  String? get selectedBodyPart => _selectedBodyPart;
  String get exerciseSearchQuery => _exerciseSearchQuery;
  String get routineSearchQuery => _routineSearchQuery;

  Future<void> init() async {
    await loadExerciseDefinitions();
    await loadRoutines();
  }

  // Exercise Definitions
  Future<void> loadExerciseDefinitions() async {
    _loading = true;
    notifyListeners();
    _exerciseDefinitions = await _repository.getAllExerciseDefinitions();
    _loading = false;
    notifyListeners();
  }

  Future<int> addExerciseDefinition({
    required String name,
    String? defaultType,
    String? bodyPart,
  }) async {
    // Check if exists
    final existing = await _repository.getExerciseDefinitionByName(name);
    if (existing != null) {
      return existing.id;
    }

    final definition = ExerciseDefinition(
      id: 0,
      name: name,
      defaultType: defaultType,
      bodyPart: bodyPart,
    );
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

  // Routines
  Future<void> loadRoutines() async {
    _loading = true;
    notifyListeners();
    _routines = await _repository.getAllRoutines();
    _loading = false;
    notifyListeners();
  }

  Future<int> createRoutine(String name) async {
    final routine = Routine(
      id: 0,
      name: name,
      createdAt: DateTime.now(),
    );
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

  // Routine Items
  Future<List<RoutineItem>> getRoutineItems(int routineId) async {
    return await _repository.getRoutineItemsByRoutineId(routineId);
  }

  Future<void> addRoutineItem(RoutineItem item) async {
    await _repository.createRoutineItem(item);
  }

  Future<void> updateRoutineItem(RoutineItem item) async {
    await _repository.updateRoutineItem(item);
  }

  Future<void> deleteRoutineItem(int id) async {
    await _repository.deleteRoutineItem(id);
  }

  Future<void> saveRoutineWithItems({
    required String routineName,
    required List<Map<String, dynamic>> items, // [{exerciseDefinitionId, targetSets, targetReps}]
  }) async {
    // Create routine
    final routineId = await createRoutine(routineName);

    // Create routine items
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final routineItem = RoutineItem(
        id: 0,
        routineId: routineId,
        exerciseDefinitionId: item['exerciseDefinitionId'] as int,
        targetSets: item['targetSets'] as int,
        targetReps: item['targetReps'] as int,
        orderIndex: i,
      );
      await addRoutineItem(routineItem);
    }

    await loadRoutines();
  }

  // Search and Filter
  void setExerciseSearchQuery(String query) {
    _exerciseSearchQuery = query;
    notifyListeners();
  }

  void setRoutineSearchQuery(String query) {
    _routineSearchQuery = query;
    notifyListeners();
  }

  void setSelectedBodyPart(String? bodyPart) {
    _selectedBodyPart = bodyPart;
    notifyListeners();
  }

  void clearExerciseFilters() {
    _exerciseSearchQuery = '';
    _selectedBodyPart = null;
    notifyListeners();
  }

  void clearRoutineFilters() {
    _routineSearchQuery = '';
    notifyListeners();
  }
}

