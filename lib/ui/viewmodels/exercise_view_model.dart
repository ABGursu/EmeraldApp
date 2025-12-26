import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/models/exercise_dictionary_model.dart';
import '../../data/models/routine_item_model.dart';
import '../../data/models/routine_model.dart';
import '../../data/models/workout_entry_model.dart';
import '../../data/models/workout_session_model.dart';
import '../../data/repositories/i_workout_repository.dart';
import '../../data/repositories/sql_workout_repository.dart';
import '../../utils/date_formats.dart';
import '../../utils/id_generator.dart';

class ExerciseViewModel extends ChangeNotifier {
  ExerciseViewModel({IWorkoutRepository? repository})
      : _repository = repository ?? SqlWorkoutRepository();

  final IWorkoutRepository _repository;

  List<WorkoutSessionModel> _sessions = [];
  List<ExerciseDictionaryModel> _exercises = [];
  List<RoutineModel> _routines = [];
  final Map<String, List<WorkoutEntryModel>> _entriesBySession = {};
  final Map<String, List<RoutineItemModel>> _itemsByRoutine = {};
  bool _loading = false;

  List<WorkoutSessionModel> get sessions => _sessions;
  List<ExerciseDictionaryModel> get exercises => _exercises;
  List<RoutineModel> get routines => _routines;
  bool get isLoading => _loading;

  Future<void> init() async {
    await loadExercises();
    await loadSessions();
    await loadRoutines();
  }

  Future<void> loadSessions() async {
    _loading = true;
    notifyListeners();
    _sessions = await _repository.getSessions();
    _sessions.sort((a, b) => b.date.compareTo(a.date));
    _loading = false;
    notifyListeners();
  }

  Future<void> loadExercises() async {
    _exercises = await _repository.getAllExercises();
    notifyListeners();
  }

  Future<String> addExerciseType(String name, int colorValue) async {
    final exercise = ExerciseDictionaryModel(
      id: generateId(),
      name: name,
      muscleGroup: null,
      colorValue: colorValue,
      createdAt: DateTime.now(),
    );
    final id = await _repository.createExercise(exercise);
    await loadExercises();
    return id;
  }

  Future<void> addSession({
    required DateTime date,
    double? weight,
    double? fat,
    String? measurements,
    String? note,
  }) async {
    final session = WorkoutSessionModel(
      id: generateId(),
      date: date,
      userWeight: weight,
      userFat: fat,
      measurements: measurements,
      note: note,
    );
    await _repository.createSession(session);
    await loadSessions();
  }

  Future<void> addEntry({
    required String sessionId,
    required String exerciseId,
    required int sets,
    required int reps,
    double? weight,
    String? note,
  }) async {
    final entry = WorkoutEntryModel(
      id: generateId(),
      sessionId: sessionId,
      exerciseId: exerciseId,
      sets: sets,
      reps: reps,
      weight: weight,
      note: note,
    );
    await _repository.createEntry(entry);
    _entriesBySession.remove(sessionId);
    await fetchEntries(sessionId);
  }

  Future<void> updateEntry(WorkoutEntryModel entry) async {
    await _repository.updateEntry(entry);
    _entriesBySession.remove(entry.sessionId);
    await fetchEntries(entry.sessionId);
  }

  Future<void> deleteEntry(String id, String sessionId) async {
    await _repository.deleteEntry(id);
    _entriesBySession.remove(sessionId);
    await fetchEntries(sessionId);
  }

  Future<List<WorkoutEntryModel>> fetchEntries(String sessionId) async {
    if (_entriesBySession.containsKey(sessionId)) {
      return _entriesBySession[sessionId]!;
    }
    final entries = await _repository.getEntriesBySession(sessionId);
    entries.sort((a, b) => b.id.compareTo(a.id));
    _entriesBySession[sessionId] = entries;
    notifyListeners();
    return entries;
  }

  ExerciseDictionaryModel? getExerciseById(String id) {
    return _exercises.firstWhere(
      (e) => e.id == id,
      orElse: () => ExerciseDictionaryModel(
        id: '',
        name: 'Unknown',
        muscleGroup: null,
        colorValue: 0xFF9E9E9E,
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<String> exportSessions({
    required DateTime from,
    required DateTime to,
  }) async {
    final directory = await _getExportDir();
    final buffer = StringBuffer();
    for (final session in _sessions) {
      if (session.date.isBefore(from) || session.date.isAfter(to)) continue;
      final entries = await fetchEntries(session.id);
      for (final entry in entries) {
        final exercise = getExerciseById(entry.exerciseId);
        buffer.writeln(
            '${formatDateTime(session.date)}, ${exercise?.name ?? 'Unknown'} ${entry.sets}x${entry.reps}');
      }
    }

    final fileName =
        'workouts_${from.millisecondsSinceEpoch}_${to.millisecondsSinceEpoch}.txt';
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(buffer.toString());
    return file.path;
  }

  Future<Directory> _getExportDir() async {
    // Prefer a stable, human-readable path: /storage/emulated/0/Documents/EmeraldApp
    // Fallback to app-specific external, then internal documents.
    const preferredPath = '/storage/emulated/0/Documents/EmeraldApp';
    Directory dir = Directory(preferredPath);
    try {
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    } catch (_) {
      final externalDir = await getExternalStorageDirectory();
      final base = externalDir ?? await getApplicationDocumentsDirectory();
      dir = Directory('${base.path}/Documents/EmeraldApp');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    }
  }

  Future<void> loadRoutines() async {
    _routines = await _repository.getAllRoutines();
    notifyListeners();
  }

  Future<String> addRoutine(String name) async {
    final routine = RoutineModel(
      id: generateId(),
      name: name,
      createdAt: DateTime.now(),
    );
    final id = await _repository.createRoutine(routine);
    await loadRoutines();
    return id;
  }

  Future<void> updateRoutine(RoutineModel routine) async {
    await _repository.updateRoutine(routine);
    await loadRoutines();
  }

  Future<void> deleteRoutine(String id) async {
    await _repository.deleteRoutine(id);
    await loadRoutines();
  }

  Future<List<RoutineItemModel>> fetchRoutineItems(String routineId) async {
    if (_itemsByRoutine.containsKey(routineId)) {
      return _itemsByRoutine[routineId]!;
    }
    final items = await _repository.getItemsByRoutine(routineId);
    _itemsByRoutine[routineId] = items;
    notifyListeners();
    return items;
  }

  Future<void> addRoutineItem({
    required String routineId,
    required String exerciseId,
    required int sets,
    required int reps,
    double? weight,
    String? note,
  }) async {
    final item = RoutineItemModel(
      id: generateId(),
      routineId: routineId,
      exerciseId: exerciseId,
      sets: sets,
      reps: reps,
      weight: weight,
      note: note,
    );
    await _repository.createRoutineItem(item);
    _itemsByRoutine.remove(routineId);
    await fetchRoutineItems(routineId);
  }

  Future<void> deleteRoutineItem(String id, String routineId) async {
    await _repository.deleteRoutineItem(id);
    _itemsByRoutine.remove(routineId);
    await fetchRoutineItems(routineId);
  }

  Future<void> addRoutineToSession(String routineId, String sessionId) async {
    final items = await fetchRoutineItems(routineId);
    for (final item in items) {
      await addEntry(
        sessionId: sessionId,
        exerciseId: item.exerciseId,
        sets: item.sets,
        reps: item.reps,
        weight: item.weight,
        note: item.note,
      );
    }
  }
}

