import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/models/life_goal_model.dart';
import '../../data/models/habit_model.dart';
import '../../data/models/habit_log_model.dart';
import '../../data/models/daily_rating_model.dart';
import '../../data/repositories/i_habit_repository.dart';
import '../../data/repositories/sql_habit_repository.dart';
import '../../utils/id_generator.dart';
import '../providers/date_provider.dart';

/// ViewModel for the Habit & Goal Logger module.
class HabitViewModel extends ChangeNotifier {
  HabitViewModel({
    IHabitRepository? repository,
    DateProvider? dateProvider,
  })  : _repository = repository ?? SqlHabitRepository(),
        _dateProvider = dateProvider;

  final IHabitRepository _repository;
  final DateProvider? _dateProvider;

  // === State ===
  List<LifeGoalModel> _goals = [];
  List<HabitModel> _habits = [];
  Map<String, bool> _todayCompletions = {};
  DailyRatingModel? _selectedDateRating;
  bool _loading = false;

  // === Getters ===
  List<LifeGoalModel> get goals => _goals;
  List<HabitModel> get habits => _habits;
  Map<String, bool> get completions => _todayCompletions;
  DailyRatingModel? get selectedDateRating => _selectedDateRating;
  DateTime get selectedDate {
    final date = _dateProvider?.selectedDate ?? DateTime.now();
    return HabitLogModel.normalizeDate(date);
  }

  bool get isLoading => _loading;

  /// Initialize the ViewModel by loading all data.
  Future<void> init() async {
    // Listen to date changes
    _dateProvider?.addListener(_onDateChanged);
    _loading = true;
    notifyListeners();

    await Future.wait([
      loadGoals(),
      loadHabits(),
    ]);
    await loadDataForSelectedDate();

    _loading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _dateProvider?.removeListener(_onDateChanged);
    super.dispose();
  }

  void _onDateChanged() {
    loadDataForSelectedDate();
  }

  // === Date Selection ===
  void setSelectedDate(DateTime date) {
    _dateProvider?.setSelectedDate(date);
    loadDataForSelectedDate();
  }

  Future<void> loadDataForSelectedDate() async {
    final date = selectedDate;
    await Future.wait([
      _loadCompletionsForDate(date),
      _loadRatingForDate(date),
    ]);
    notifyListeners();
  }

  // === Goals ===
  Future<void> loadGoals({bool includeArchived = false}) async {
    _goals = await _repository.getAllGoals(includeArchived: includeArchived);
    notifyListeners();
  }

  Future<String> addGoal(String title, {String? description}) async {
    final goal = LifeGoalModel(
      id: generateId(),
      title: title,
      description: description,
    );
    final id = await _repository.createGoal(goal);
    await loadGoals();
    return id;
  }

  Future<void> updateGoal(LifeGoalModel goal) async {
    await _repository.updateGoal(goal);
    await loadGoals();
  }

  Future<void> deleteGoal(String id) async {
    await _repository.deleteGoal(id);
    await loadGoals();
  }

  Future<void> archiveGoal(String id) async {
    await _repository.archiveGoal(id);
    await loadGoals();
  }

  // === Habits ===
  Future<void> loadHabits({bool includeArchived = false}) async {
    _habits = await _repository.getAllHabits(includeArchived: includeArchived);
    notifyListeners();
  }

  Future<String> addHabit(
    String title, {
    String? goalId,
    required int colorValue,
  }) async {
    final habit = HabitModel(
      id: generateId(),
      goalId: goalId,
      title: title,
      colorValue: colorValue,
    );
    final id = await _repository.createHabit(habit);
    await loadHabits();
    return id;
  }

  Future<void> updateHabit(HabitModel habit) async {
    await _repository.updateHabit(habit);
    await loadHabits();
  }

  Future<void> deleteHabit(String id) async {
    await _repository.deleteHabit(id);
    await loadHabits();
  }

  Future<void> archiveHabit(String id) async {
    await _repository.archiveHabit(id);
    await loadHabits();
  }

  /// Get habits grouped by their goal.
  Map<LifeGoalModel?, List<HabitModel>> get habitsGroupedByGoal {
    final Map<LifeGoalModel?, List<HabitModel>> grouped = {};
    final goalsMap = {for (final g in _goals) g.id: g};

    for (final habit in _habits) {
      final goal = habit.goalId != null ? goalsMap[habit.goalId] : null;
      grouped.putIfAbsent(goal, () => []).add(habit);
    }

    return grouped;
  }

  // === Habit Logs ===
  Future<void> _loadCompletionsForDate(DateTime date) async {
    final logs = await _repository.getLogsForDate(date);
    _todayCompletions = {
      for (final log in logs) log.habitId: log.isCompleted,
    };
  }

  bool isHabitCompleted(String habitId) {
    return _todayCompletions[habitId] ?? false;
  }

  /// Toggles habit completion for the selected date.
  /// Immediately updates UI via notifyListeners().
  Future<void> toggleHabitCompletion(String habitId) async {
    final currentStatus = _todayCompletions[habitId] ?? false;
    final newStatus = !currentStatus;

    // Optimistically update UI
    _todayCompletions[habitId] = newStatus;
    notifyListeners();

    // Persist to database
    await _repository.setHabitCompletion(habitId, selectedDate, newStatus);
  }

  /// Sets habit completion explicitly.
  Future<void> setHabitCompletion(String habitId, bool isCompleted) async {
    // Optimistically update UI
    _todayCompletions[habitId] = isCompleted;
    notifyListeners();

    // Persist to database
    await _repository.setHabitCompletion(habitId, selectedDate, isCompleted);
  }

  // === Daily Ratings ===
  Future<void> _loadRatingForDate(DateTime date) async {
    _selectedDateRating = await _repository.getRatingForDate(date);
  }

  Future<void> setDailyRating(int score, {String? note}) async {
    final rating = DailyRatingModel(
      date: selectedDate,
      score: score,
      note: note,
    );

    await _repository.setDailyRating(rating);
    _selectedDateRating = rating;
    notifyListeners();
  }

  Future<void> deleteDailyRating() async {
    await _repository.deleteDailyRating(selectedDate);
    _selectedDateRating = null;
    notifyListeners();
  }

  // === Statistics ===
  int get todayCompletedCount {
    return _todayCompletions.values.where((v) => v).length;
  }

  int get totalHabitsCount => _habits.length;

  double get completionPercentage {
    if (_habits.isEmpty) return 0;
    return todayCompletedCount / _habits.length;
  }

  /// Get goal by ID for display purposes.
  LifeGoalModel? getGoalById(String? goalId) {
    if (goalId == null) return null;
    return _goals.firstWhere(
      (g) => g.id == goalId,
      orElse: () => const LifeGoalModel(id: '', title: 'Unknown'),
    );
  }

  // === Export ===
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

  Future<String> exportHabitsData({
    required DateTime from,
    required DateTime to,
  }) async {
    final data = await _repository.getExportData(from: from, to: to);
    final buffer = StringBuffer();

    for (final dayData in data) {
      final dateStr = _formatDate(dayData.date);
      final scoreStr = dayData.rating != null
          ? 'Score: ${dayData.rating!.score}/10'
          : 'Score: -';

      for (final habitData in dayData.habits) {
        final goalName = habitData.goal?.title ?? 'No Goal';
        final status = habitData.completed ? 'DONE' : 'NOT DONE';
        buffer.writeln(
            '$dateStr | $scoreStr | ${habitData.habit.title} ($goalName): $status');
      }

      // Add daily note if present
      if (dayData.rating?.note != null && dayData.rating!.note!.isNotEmpty) {
        buffer.writeln('$dateStr | Note: ${dayData.rating!.note}');
      }

      buffer.writeln();
    }

    final directory = await _getExportDir();
    final fileName =
        'habits_${from.millisecondsSinceEpoch}_${to.millisecondsSinceEpoch}.txt';
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(buffer.toString());
    return file.path;
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

