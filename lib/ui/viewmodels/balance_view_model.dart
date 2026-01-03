import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/tag_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/i_balance_repository.dart';
import '../../data/repositories/sql_balance_repository.dart';
import '../../utils/date_formats.dart';
import '../../utils/date_range_persistence.dart';
import '../../utils/id_generator.dart';

class BalanceViewModel extends ChangeNotifier with DateRangePersistence {
  BalanceViewModel({IBalanceRepository? repository})
      : _repository = repository ?? SqlBalanceRepository();

  final IBalanceRepository _repository;

  List<TransactionModel> _transactions = [];
  List<TagModel> _tags = [];
  bool _loading = false;
  double? _currentBudget;

  // Date range for filtering
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  bool _isRollingDate = false;

  // Tag filtering
  String? _selectedTagId;
  String _tagSearchQuery = '';

  // Cache for groupedByDate to avoid recalculation on every access
  Map<DateTime, List<TransactionModel>>? _groupedByDateCache;
  String? _cachedGroupedTagId;
  int? _cachedTransactionsHash; // Simple hash based on list length and first/last transaction IDs

  // Fiscal month settings
  int _budgetStartDay = 1; // Default to calendar month (1st)

  @override
  String get moduleName => 'balance';

  DateTime? get filterStartDate => _filterStartDate;
  DateTime? get filterEndDate => _filterEndDate;
  bool get isRollingDate => _isRollingDate;
  int get budgetStartDay => _budgetStartDay;
  String? get selectedTagId => _selectedTagId;
  String get tagSearchQuery => _tagSearchQuery;

  List<TransactionModel> get transactions => _transactions;
  List<TagModel> get tags => _tags;
  
  /// Filtered tags based on search query
  List<TagModel> get filteredTags {
    if (_tagSearchQuery.isEmpty) {
      return _tags;
    }
    final query = _tagSearchQuery.toLowerCase();
    return _tags.where((tag) => tag.name.toLowerCase().contains(query)).toList();
  }
  bool get isLoading => _loading;
  double? get currentBudget => _currentBudget;

  /// Sets the selected tag filter
  void setSelectedTag(String? tagId) {
    _selectedTagId = tagId;
    _groupedByDateCache = null; // Invalidate cache
    notifyListeners();
  }

  /// Sets the tag search query
  void setTagSearchQuery(String query) {
    _tagSearchQuery = query;
    notifyListeners();
  }

  Future<void> init() async {
    await loadTags();
    await loadDateRangeFromPrefs();
    await loadBudgetStartDay();
    await loadTransactions();
    await loadCurrentBudget();
  }

  /// Loads budget start day from SharedPreferences
  Future<void> loadBudgetStartDay() async {
    final prefs = await SharedPreferences.getInstance();
    _budgetStartDay = prefs.getInt('budget_start_day') ?? 1;
    // Clamp to valid range (1-31)
    _budgetStartDay = _budgetStartDay.clamp(1, 31);
    notifyListeners();
  }

  /// Sets the budget start day and persists it
  Future<void> setBudgetStartDay(int day) async {
    // Clamp to valid range (1-31)
    _budgetStartDay = day.clamp(1, 31);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('budget_start_day', _budgetStartDay);
    notifyListeners();
    // Reload budget to reflect new fiscal month
    await loadCurrentBudget();
  }

  /// Loads persisted date range from SharedPreferences
  Future<void> loadDateRangeFromPrefs() async {
    final range = await loadDateRange();
    _filterStartDate = range.startDate;
    _filterEndDate = range.endDate;
    _isRollingDate = range.isRollingToday;
    notifyListeners();
  }

  /// Sets the date range filter and persists it
  Future<void> setDateRange({
    required DateTime? startDate,
    required DateTime? endDate,
  }) async {
    _filterStartDate = startDate;
    _filterEndDate = endDate;
    await saveDateRange(startDate: startDate, endDate: endDate);
    
    // Reload transactions with new filter
    await loadTransactions();
  }

  /// Clears the date range filter
  Future<void> clearDateRangeFilter() async {
    _filterStartDate = null;
    _filterEndDate = null;
    _isRollingDate = false;
    // Call mixin's clearDateRange method via super-like access
    await (this as DateRangePersistence).clearDateRange();
    await loadTransactions();
  }

  /// Gets the current fiscal month range
  /// Returns (start, end) dates for the current fiscal period
  ({DateTime start, DateTime end}) getCurrentFiscalMonth() {
    final today = DateTime.now();
    DateTime fiscalMonthStart;
    DateTime fiscalMonthEnd;

    if (today.day >= _budgetStartDay) {
      // Current period started this month
      fiscalMonthStart = DateTime(today.year, today.month, _budgetStartDay);
      // End is the day before start day of next month
      fiscalMonthEnd = DateTime(today.year, today.month + 1, _budgetStartDay)
          .subtract(const Duration(days: 1));
    } else {
      // Current period started last month
      fiscalMonthStart = DateTime(today.year, today.month - 1, _budgetStartDay);
      // End is the day before start day of this month
      fiscalMonthEnd = DateTime(today.year, today.month, _budgetStartDay)
          .subtract(const Duration(days: 1));
    }

    // Set end time to end of day
    fiscalMonthEnd = DateTime(
      fiscalMonthEnd.year,
      fiscalMonthEnd.month,
      fiscalMonthEnd.day,
      23,
      59,
      59,
    );

    return (start: fiscalMonthStart, end: fiscalMonthEnd);
  }

  /// Gets a string representation of the current fiscal period
  String getCurrentFiscalPeriodText() {
    final fiscal = getCurrentFiscalMonth();
    final startStr = formatDate(fiscal.start);
    final endStr = formatDate(fiscal.end);
    return '$startStr - $endStr';
  }

  /// Gets the fiscal month key for budget storage
  /// Format: "MM-YYYY" based on the fiscal month start
  String _getCurrentFiscalMonthYear() {
    final fiscal = getCurrentFiscalMonth();
    return '${fiscal.start.month.toString().padLeft(2, '0')}-${fiscal.start.year}';
  }

  Future<void> loadCurrentBudget() async {
    final monthYear = _getCurrentFiscalMonthYear();
    _currentBudget = await _repository.getBudget(monthYear);
    notifyListeners();
  }

  Future<void> setBudget(double amount) async {
    final monthYear = _getCurrentFiscalMonthYear();
    await _repository.setBudget(monthYear, amount);
    await loadCurrentBudget();
  }

  double get currentMonthTotalExpenses {
    final fiscal = getCurrentFiscalMonth();
    
    return _transactions
        .where((tx) => tx.amount < 0 && 
                      tx.date.isAfter(fiscal.start.subtract(const Duration(days: 1))) && 
                      tx.date.isBefore(fiscal.end.add(const Duration(days: 1))))
        .fold<double>(0.0, (sum, tx) => sum + tx.amount.abs());
  }

  double get budgetPercentage {
    if (_currentBudget == null || _currentBudget == 0) return 0.0;
    return (currentMonthTotalExpenses / _currentBudget!).clamp(0.0, 2.0);
  }

  Future<void> loadTags() async {
    _tags = await _repository.getAllTags();
    notifyListeners();
  }

  Future<void> loadTransactions() async {
    _loading = true;
    notifyListeners();
    
    // Load all transactions first
    final allTransactions = await _repository.getTransactions();
    
    // Apply date range filter if set
    if (_filterStartDate != null && _filterEndDate != null) {
      final endOfDay = DateTime(
        _filterEndDate!.year,
        _filterEndDate!.month,
        _filterEndDate!.day,
        23,
        59,
        59,
      );
      _transactions = allTransactions.where((tx) {
        return tx.date.isAfter(_filterStartDate!.subtract(const Duration(days: 1))) &&
               tx.date.isBefore(endOfDay.add(const Duration(days: 1)));
      }).toList();
    } else {
      _transactions = allTransactions;
    }
    
    _groupedByDateCache = null; // Invalidate cache when transactions change
    _loading = false;
    notifyListeners();
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
      // Fallback chain
      final externalDir = await getExternalStorageDirectory();
      final base = externalDir ?? await getApplicationDocumentsDirectory();
      dir = Directory('${base.path}/Documents/EmeraldApp');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    }
  }

  Future<String> addTag(String name, int colorValue) async {
    final tag = TagModel(
      id: generateId(),
      name: name,
      colorValue: colorValue,
      createdAt: DateTime.now(),
    );
    final id = await _repository.createTag(tag);
    await loadTags();
    return id;
  }

  Future<void> updateTag(TagModel tag) async {
    await _repository.updateTag(tag);
    await loadTags();
  }

  Future<void> deleteTag(String id) async {
    await _repository.deleteTag(id);
    await loadTags();
  }

  Future<String> addTransaction({
    required double amount,
    required bool isExpense,
    required DateTime date,
    required String? tagId,
    String? note,
  }) async {
    final tx = TransactionModel(
      id: generateId(),
      amount: isExpense ? -amount.abs() : amount.abs(),
      date: date,
      tagId: tagId,
      note: note,
    );
    await _repository.createTransaction(tx);
    await loadTransactions();
    return tx.id;
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    await _repository.updateTransaction(transaction);
    await loadTransactions();
  }

  Future<void> deleteTransaction(String id) async {
    await _repository.deleteTransaction(id);
    await loadTransactions();
  }

  double get currentBalance {
    return _transactions.fold<double>(0.0, (sum, tx) => sum + tx.amount);
  }

  Map<DateTime, List<TransactionModel>> get groupedByDate {
    // Calculate simple hash for cache validation
    final currentHash = _transactions.isEmpty
        ? 0
        : (_transactions.length.hashCode ^
            _transactions.first.id.hashCode ^
            _transactions.last.id.hashCode);
    
    // Check if cache is still valid
    if (_groupedByDateCache != null &&
        _cachedGroupedTagId == _selectedTagId &&
        _cachedTransactionsHash == currentHash) {
      return _groupedByDateCache!;
    }

    // Apply tag filter if set
    final filteredTransactions = _selectedTagId != null
        ? _transactions.where((tx) => tx.tagId == _selectedTagId).toList()
        : _transactions;

    final Map<DateTime, List<TransactionModel>> grouped = {};
    for (final tx in filteredTransactions) {
      final key = DateTime(tx.date.year, tx.date.month, tx.date.day);
      grouped.putIfAbsent(key, () => []).add(tx);
    }
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // newest first
    
    // Update cache
    _groupedByDateCache = {for (final k in sortedKeys) k: grouped[k]!};
    _cachedGroupedTagId = _selectedTagId;
    _cachedTransactionsHash = currentHash;
    
    return _groupedByDateCache!;
  }

  Map<TagModel, double> currentMonthExpensesByTag() {
    final fiscal = getCurrentFiscalMonth();
    return expensesByTagInRange(fiscal.start, fiscal.end);
  }

  Map<TagModel, double> expensesByTagInRange(DateTime from, DateTime to) {
    final Map<String, double> totals = {};
    for (final tx in _transactions) {
      if (tx.date.isBefore(from) || tx.date.isAfter(to) || tx.amount >= 0) continue;
      totals.update(tx.tagId ?? 'untagged', (value) => value + tx.amount,
          ifAbsent: () => tx.amount);
    }
    final Map<TagModel, double> result = {};
    totals.forEach((tagId, total) {
      final tag = _tags.firstWhere(
        (t) => t.id == tagId,
        orElse: () => TagModel(
          id: 'untagged',
          name: 'Untagged',
          colorValue: 0xFF9E9E9E,
          createdAt: DateTime.now(),
        ),
      );
      result[tag] = total.abs();
    });
    return result;
  }

  Future<String> exportTransactions({
    required DateTime from,
    required DateTime to,
  }) async {
    final buffer = StringBuffer();
    for (final tx in _transactions) {
      if (tx.date.isBefore(from) || tx.date.isAfter(to)) continue;
      final tagName =
          _tags.firstWhere((t) => t.id == tx.tagId, orElse: () => TagModel(id: '', name: 'Untagged', colorValue: 0, createdAt: DateTime.now())).name;
      buffer.writeln(
          '${formatDateTime(tx.date)}: $tagName ${tx.amount.toStringAsFixed(2)} TL');
    }

    final directory = await _getExportDir();
    final fromStr = formatDateForFilename(from);
    final toStr = formatDateForFilename(to);
    final fileName = 'transactions_$fromStr-$toStr.txt';
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(buffer.toString());
    return file.path;
  }
}

