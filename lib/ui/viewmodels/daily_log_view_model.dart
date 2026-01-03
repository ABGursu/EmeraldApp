import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/models/exercise_definition_model.dart';
import '../../data/models/user_stats_model.dart';
import '../../data/models/workout_log_model.dart';
import '../../data/repositories/i_exercise_log_repository.dart';
import '../../data/repositories/sql_exercise_log_repository.dart';
import '../../utils/date_formats.dart';
import '../../utils/date_range_persistence.dart';
import '../providers/date_provider.dart';

class DailyLogViewModel extends ChangeNotifier with DateRangePersistence {
  DailyLogViewModel({
    IExerciseLogRepository? repository,
    DateProvider? dateProvider,
  })  : _repository = repository ?? SqlExerciseLogRepository(),
        _dateProvider = dateProvider;

  final IExerciseLogRepository _repository;
  final DateProvider? _dateProvider;

  List<WorkoutLog> _logs = [];
  UserStats? _userStats;
  bool _loading = false;

  // Date range for history/export views
  DateTime? _historyStartDate;
  DateTime? _historyEndDate;
  bool _isRollingDate = false;

  @override
  String get moduleName => 'exercise';

  DateTime get selectedDate => _dateProvider?.selectedDate ?? DateTime.now();
  DateTime? get historyStartDate => _historyStartDate;
  DateTime? get historyEndDate => _historyEndDate;
  bool get isRollingDate => _isRollingDate;
  List<WorkoutLog> get logs => _logs;
  UserStats? get userStats => _userStats;
  bool get isLoading => _loading;

  Future<void> init() async {
    // Listen to date changes
    _dateProvider?.addListener(_onDateChanged);
    await loadUserStats();
    await loadDateRangeFromPrefs();
    await loadLogsForDate(selectedDate);
  }

  /// Loads persisted date range from SharedPreferences
  Future<void> loadDateRangeFromPrefs() async {
    final range = await loadDateRange();
    _historyStartDate = range.startDate;
    _historyEndDate = range.endDate;
    _isRollingDate = range.isRollingToday;
    notifyListeners();
  }

  /// Sets the date range for history/export and persists it
  Future<void> setHistoryDateRange({
    required DateTime? startDate,
    required DateTime? endDate,
  }) async {
    _historyStartDate = startDate;
    _historyEndDate = endDate;
    await saveDateRange(startDate: startDate, endDate: endDate);
    notifyListeners();
  }

  /// Clears the history date range
  Future<void> clearHistoryDateRange() async {
    _historyStartDate = null;
    _historyEndDate = null;
    _isRollingDate = false;
    await clearDateRange();
    notifyListeners();
  }

  @override
  void dispose() {
    _dateProvider?.removeListener(_onDateChanged);
    super.dispose();
  }

  void _onDateChanged() {
    loadLogsForDate(selectedDate);
  }

  // Date Navigation (delegates to DateProvider)
  Future<void> setSelectedDate(DateTime date) async {
    _dateProvider?.setSelectedDate(date);
    await loadLogsForDate(date);
  }

  Future<void> goToPreviousDay() async {
    _dateProvider?.goToPreviousDay();
    await loadLogsForDate(selectedDate);
  }

  Future<void> goToNextDay() async {
    _dateProvider?.goToNextDay();
    await loadLogsForDate(selectedDate);
  }

  // Workout Logs
  Future<void> loadLogsForDate(DateTime date) async {
    _loading = true;
    notifyListeners();
    _logs = await _repository.getWorkoutLogsByDate(date);
    _loading = false;
    notifyListeners();
  }

  Future<int> addWorkoutLogFromDefinition(ExerciseDefinition definition) async {
    // Get max order index (optimized: single loop instead of map+reduce)
    int maxOrderIndex = 0;
    if (_logs.isNotEmpty) {
      for (final log in _logs) {
        if (log.orderIndex >= maxOrderIndex) {
          maxOrderIndex = log.orderIndex;
        }
      }
      maxOrderIndex += 1;
    }

    final log = WorkoutLog(
      id: 0,
      date: selectedDate,
      exerciseName: definition.name,
      exerciseType: definition.defaultType,
      sets: 0, // Empty set, user will fill
      reps: 0,
      orderIndex: maxOrderIndex,
      isCompleted: false,
    );
    final id = await _repository.createWorkoutLog(log);
    await loadLogsForDate(selectedDate);
    return id;
  }

  Future<int> addWorkoutLog(WorkoutLog log) async {
    final id = await _repository.createWorkoutLog(log);
    await loadLogsForDate(selectedDate);
    return id;
  }

  Future<void> updateWorkoutLog(WorkoutLog log) async {
    await _repository.updateWorkoutLog(log);
    await loadLogsForDate(selectedDate);
  }

  Future<void> deleteWorkoutLog(int id) async {
    await _repository.deleteWorkoutLog(id);
    await loadLogsForDate(selectedDate);
  }

  Future<void> toggleWorkoutLogCompletion(int id) async {
    final log = _logs.firstWhere((l) => l.id == id);
    final updated = log.copyWith(isCompleted: !log.isCompleted);
    await updateWorkoutLog(updated);
  }

  // Reordering
  Future<void> reorderLogs(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = _logs.removeAt(oldIndex);
    _logs.insert(newIndex, item);

    // Update order indices for all logs (batch update)
    final updatedLogs = <WorkoutLog>[];
    for (int i = 0; i < _logs.length; i++) {
      updatedLogs.add(_logs[i].copyWith(orderIndex: i));
    }
    
    // Use batch update method from repository
    await _repository.reorderWorkoutLogs(updatedLogs);
    
    // Update local state
    _logs = updatedLogs;
    notifyListeners();
  }

  // Load Routine
  Future<void> loadRoutine(int routineId) async {
    final routine = await _repository.getRoutineById(routineId);
    if (routine == null) return;

    final items = await _repository.getRoutineItemsByRoutineId(routineId);
    final date = selectedDate;

    // Get max order index for the date (optimized: single loop instead of map+reduce)
    int maxOrderIndex = 0;
    if (_logs.isNotEmpty) {
      for (final log in _logs) {
        if (log.orderIndex >= maxOrderIndex) {
          maxOrderIndex = log.orderIndex;
        }
      }
      maxOrderIndex += 1;
    }

    // Get exercise definitions for items
    final exerciseDefs = await _repository.getAllExerciseDefinitions();
    final defMap = {for (var def in exerciseDefs) def.id: def};

    // Create workout logs from routine items
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final definition = defMap[item.exerciseDefinitionId];
      if (definition == null) continue;

      final log = WorkoutLog(
        id: 0,
        date: date,
        exerciseName: definition.name, // Copy from definition
        exerciseType: definition.defaultType, // Copy from definition
        sets: item.targetSets,
        reps: item.targetReps,
        orderIndex: maxOrderIndex + i,
        isCompleted: false,
      );
      await _repository.createWorkoutLog(log);
    }

    await loadLogsForDate(date);
  }

  // User Stats
  Future<void> loadUserStats() async {
    _userStats = await _repository.getUserStats();
    notifyListeners();
  }

  Future<void> updateUserStats({
    double? weight,
    double? fat,
    String? measurements,
    String? style,
  }) async {
    final currentStats = _userStats ?? UserStats.empty();
    final updatedStats = currentStats.copyWith(
      weight: weight,
      fat: fat,
      measurements: measurements,
      style: style,
      updatedAt: DateTime.now(),
    );
    await _repository.updateUserStats(updatedStats);
    await loadUserStats();
  }

  // Get last log details for an exercise (for Smart Pre-fill)
  Future<WorkoutLog?> getLastLogDetails(String exerciseName) async {
    return await _repository.getLastLogForExercise(exerciseName);
  }

  // Export
  Future<String> exportLogs({
    required DateTime from,
    required DateTime to,
  }) async {
    final directory = await _getExportDir();
    final logs = await _repository.getWorkoutLogsByDateRange(from, to);
    final buffer = StringBuffer();
    for (final log in logs) {
      buffer.writeln(log.toLogString());
    }

    final fromStr = formatDateForFilename(from);
    final toStr = formatDateForFilename(to);
    final fileName = 'workout_logs_$fromStr-$toStr.txt';
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
}

