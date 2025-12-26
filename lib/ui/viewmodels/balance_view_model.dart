import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/models/tag_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/i_balance_repository.dart';
import '../../data/repositories/sql_balance_repository.dart';
import '../../utils/date_formats.dart';
import '../../utils/id_generator.dart';

class BalanceViewModel extends ChangeNotifier {
  BalanceViewModel({IBalanceRepository? repository})
      : _repository = repository ?? SqlBalanceRepository();

  final IBalanceRepository _repository;

  List<TransactionModel> _transactions = [];
  List<TagModel> _tags = [];
  bool _loading = false;
  double? _currentBudget;

  List<TransactionModel> get transactions => _transactions;
  List<TagModel> get tags => _tags;
  bool get isLoading => _loading;
  double? get currentBudget => _currentBudget;

  Future<void> init() async {
    await loadTags();
    await loadTransactions();
    await loadCurrentBudget();
  }

  String _getCurrentMonthYear() {
    final now = DateTime.now();
    return '${now.month.toString().padLeft(2, '0')}-${now.year}';
  }

  Future<void> loadCurrentBudget() async {
    final monthYear = _getCurrentMonthYear();
    _currentBudget = await _repository.getBudget(monthYear);
    notifyListeners();
  }

  Future<void> setBudget(double amount) async {
    final monthYear = _getCurrentMonthYear();
    await _repository.setBudget(monthYear, amount);
    await loadCurrentBudget();
  }

  double get currentMonthTotalExpenses {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    
    return _transactions
        .where((tx) => tx.amount < 0 && 
                      tx.date.isAfter(monthStart.subtract(const Duration(days: 1))) && 
                      tx.date.isBefore(monthEnd.add(const Duration(days: 1))))
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
    _transactions = await _repository.getTransactions();
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

  Future<void> addTransaction({
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
    final Map<DateTime, List<TransactionModel>> grouped = {};
    for (final tx in _transactions) {
      final key = DateTime(tx.date.year, tx.date.month, tx.date.day);
      grouped.putIfAbsent(key, () => []).add(tx);
    }
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // newest first
    return {for (final k in sortedKeys) k: grouped[k]!};
  }

  Map<TagModel, double> currentMonthExpensesByTag() {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    return expensesByTagInRange(monthStart, now);
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
          '${formatDateTime(tx.date)}: $tagName ${tx.amount.toStringAsFixed(2)}');
    }

    final directory = await _getExportDir();
    final fileName =
        'transactions_${from.millisecondsSinceEpoch}_${to.millisecondsSinceEpoch}.txt';
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(buffer.toString());
    return file.path;
  }
}

