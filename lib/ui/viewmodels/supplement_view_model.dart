import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/models/ingredient_model.dart';
import '../../data/models/product_model.dart';
import '../../data/models/product_composition_model.dart';
import '../../data/models/supplement_log_model.dart';
import '../../data/models/supplement_log_detail_model.dart';
import '../../data/repositories/i_supplement_repository.dart';
import '../../data/repositories/sql_supplement_repository.dart';
import '../../utils/date_formats.dart';
import '../../utils/date_range_persistence.dart';
import '../../utils/id_generator.dart';

/// ViewModel for the Supplement & Prehab Logger module.
class SupplementViewModel extends ChangeNotifier with DateRangePersistence {
  SupplementViewModel({ISupplementRepository? repository})
      : _repository = repository ?? SqlSupplementRepository();

  final ISupplementRepository _repository;

  // === State ===
  List<IngredientModel> _ingredients = [];
  List<ProductModel> _products = [];
  List<SupplementLogModel> _logs = [];
  Map<String, ({double amount, String unit})> _todaysTotals = {};
  bool _loading = false;

  // Date range for history/export views
  DateTime? _historyStartDate;
  DateTime? _historyEndDate;
  bool _isRollingDate = false;

  @override
  String get moduleName => 'supplement';

  DateTime? get historyStartDate => _historyStartDate;
  DateTime? get historyEndDate => _historyEndDate;
  bool get isRollingDate => _isRollingDate;

  // === Getters ===
  List<IngredientModel> get ingredients => _ingredients;
  List<ProductModel> get products => _products;
  List<SupplementLogModel> get logs => _logs;
  Map<String, ({double amount, String unit})> get todaysTotals => _todaysTotals;
  bool get isLoading => _loading;

  /// Initialize the ViewModel by loading all data.
  Future<void> init() async {
    _loading = true;
    notifyListeners();

    await loadDateRangeFromPrefs();
    await Future.wait([
      loadIngredients(),
      loadProducts(),
      loadLogs(),
      loadTodaysTotals(),
    ]);

    _loading = false;
    notifyListeners();
  }

  /// Loads persisted date range from SharedPreferences
  Future<void> loadDateRangeFromPrefs() async {
    final range = await loadDateRange();
    _historyStartDate = range.startDate;
    _historyEndDate = range.endDate;
    _isRollingDate = range.isRollingToday;
    
    // Apply date range to logs if set
    if (_historyStartDate != null && _historyEndDate != null) {
      await loadLogs(from: _historyStartDate, to: _historyEndDate);
    }
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
    
    // Reload logs with new date range
    await loadLogs(from: startDate, to: endDate);
  }

  /// Clears the history date range
  Future<void> clearHistoryDateRange() async {
    _historyStartDate = null;
    _historyEndDate = null;
    _isRollingDate = false;
    await clearDateRange();
    await loadLogs(); // Load all logs
    notifyListeners();
  }

  // === Ingredients ===
  Future<void> loadIngredients() async {
    _ingredients = await _repository.getAllIngredients();
    notifyListeners();
  }

  Future<String> addIngredient(String name, String unit) async {
    final ingredient = IngredientModel(
      id: generateId(),
      name: name,
      defaultUnit: unit,
    );
    final id = await _repository.createIngredient(ingredient);
    await loadIngredients();
    return id;
  }

  Future<void> updateIngredient(IngredientModel ingredient) async {
    await _repository.updateIngredient(ingredient);
    await loadIngredients();
  }

  Future<void> deleteIngredient(String id) async {
    await _repository.deleteIngredient(id);
    await loadIngredients();
  }

  // === Products ===
  Future<void> loadProducts({bool includeArchived = false}) async {
    _products = await _repository.getAllProducts(includeArchived: includeArchived);
    notifyListeners();
  }

  Future<String> addProduct(String name, {String servingUnit = 'Serving'}) async {
    final product = ProductModel(
      id: generateId(),
      name: name,
      servingUnit: servingUnit,
    );
    final id = await _repository.createProduct(product);
    await loadProducts();
    return id;
  }

  Future<void> updateProduct(ProductModel product) async {
    await _repository.updateProduct(product);
    await loadProducts();
  }

  Future<void> deleteProduct(String id) async {
    await _repository.deleteProduct(id);
    await loadProducts();
  }

  Future<void> archiveProduct(String id) async {
    await _repository.archiveProduct(id);
    await loadProducts();
  }

  Future<List<ProductCompositionModel>> getProductComposition(String productId) async {
    return _repository.getProductComposition(productId);
  }

  Future<void> setProductComposition(
    String productId,
    List<ProductCompositionModel> composition,
  ) async {
    await _repository.setProductComposition(productId, composition);
  }

  // === Logs ===
  Future<void> loadLogs({DateTime? from, DateTime? to}) async {
    _logs = await _repository.getLogs(from: from, to: to);
    notifyListeners();
  }

  /// Logs a supplement consumption with full snapshot of current composition.
  /// This is the critical method that ensures "Immutable History".
  Future<String> logSupplement({
    required ProductModel product,
    required double servingsCount,
    required DateTime date,
  }) async {
    // Get current composition
    final composition = await _repository.getProductComposition(product.id);

    // Create log header
    final log = SupplementLogModel(
      id: generateId(),
      date: date,
      productNameSnapshot: product.name,
      servingsCount: servingsCount,
    );

    // Create snapshot details - FLATTEN the data for immutability
    final details = <SupplementLogDetailModel>[];
    for (final comp in composition) {
      final ingredient = _ingredients.firstWhere(
        (i) => i.id == comp.ingredientId,
        orElse: () => IngredientModel(
          id: comp.ingredientId,
          name: 'Unknown',
          defaultUnit: 'unit',
        ),
      );

      details.add(SupplementLogDetailModel(
        logId: log.id,
        ingredientName: ingredient.name,
        amountTotal: comp.amountPerServing * servingsCount,
        unit: ingredient.defaultUnit,
      ));
    }

    final id = await _repository.createLog(log, details);
    await loadLogs();
    await loadTodaysTotals();
    return id;
  }

  Future<void> deleteLog(String id) async {
    await _repository.deleteLog(id);
    await loadLogs();
    await loadTodaysTotals();
  }

  Future<List<SupplementLogDetailModel>> getLogDetails(String logId) async {
    return _repository.getLogDetails(logId);
  }

  // === Analytics ===
  Future<void> loadTodaysTotals() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

    _todaysTotals = await _repository.getTotalIntake(
      from: startOfDay,
      to: endOfDay,
    );
    notifyListeners();
  }

  Future<Map<String, ({double amount, String unit})>> getTotalIntake({
    required DateTime from,
    required DateTime to,
  }) async {
    return _repository.getTotalIntake(from: from, to: to);
  }

  /// Group logs by date for display.
  Map<DateTime, List<SupplementLogModel>> get groupedByDate {
    final Map<DateTime, List<SupplementLogModel>> grouped = {};
    for (final log in _logs) {
      final key = DateTime(log.date.year, log.date.month, log.date.day);
      grouped.putIfAbsent(key, () => []).add(log);
    }
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // Newest first
    return {for (final k in sortedKeys) k: grouped[k]!};
  }

  // === Export ===
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

  Future<String> exportLogs({
    required DateTime from,
    required DateTime to,
  }) async {
    final buffer = StringBuffer();

    // Get all unique dates in the range
    final logsInRange = await _repository.getLogs(from: from, to: to);
    if (logsInRange.isEmpty) {
      buffer.writeln('No supplements logged in this period.');
    } else {
      // Group logs by date
      final Set<DateTime> uniqueDates = {};
      for (final log in logsInRange) {
        final dateKey = DateTime(log.date.year, log.date.month, log.date.day);
        uniqueDates.add(dateKey);
      }
      
      // Sort dates (oldest first - chronological order)
      final sortedDates = uniqueDates.toList()..sort((a, b) => a.compareTo(b));
      
      // Calculate daily totals for each date
      for (final date in sortedDates) {
        final startOfDay = DateTime(date.year, date.month, date.day);
        final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
        
        final dailyTotals = await getTotalIntake(from: startOfDay, to: endOfDay);
        
        buffer.writeln('${formatDate(date)}:');
        
        if (dailyTotals.isEmpty) {
          buffer.writeln('  No supplements logged.');
        } else {
          // Sort ingredients alphabetically
          final sortedIngredients = dailyTotals.keys.toList()..sort();
          
          for (final ingredientName in sortedIngredients) {
            final data = dailyTotals[ingredientName]!;
            buffer.writeln('  - $ingredientName: ${_formatAmount(data.amount)} ${data.unit}');
          }
        }
        buffer.writeln();
      }
    }

    // Write to file
    final directory = await _getExportDir();
    final fromStr = formatDateForFilename(from);
    final toStr = formatDateForFilename(to);
    final fileName = 'supplements_$fromStr-$toStr.txt';
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(buffer.toString());
    return file.path;
  }

  String _formatAmount(double amount) {
    if (amount == amount.roundToDouble()) {
      return amount.toInt().toString();
    }
    return amount.toStringAsFixed(2);
  }
}

