import '../local_db/database_helper.dart';
import '../models/ingredient_model.dart';
import '../models/product_model.dart';
import '../models/product_composition_model.dart';
import '../models/supplement_log_model.dart';
import '../models/supplement_log_detail_model.dart';
import '../repositories/i_supplement_repository.dart';
import '../../utils/id_generator.dart';

class SqlSupplementRepository implements ISupplementRepository {
  final DatabaseHelper _dbHelper;

  SqlSupplementRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  // === Ingredients Library ===
  @override
  Future<List<IngredientModel>> getAllIngredients() async {
    final db = await _dbHelper.database;
    final result = await db.query('ingredients_library', orderBy: 'name ASC');
    return result.map(IngredientModel.fromMap).toList();
  }

  @override
  Future<IngredientModel?> getIngredientById(String id) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'ingredients_library',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return IngredientModel.fromMap(result.first);
  }

  @override
  Future<String> createIngredient(IngredientModel ingredient) async {
    final db = await _dbHelper.database;
    final id = ingredient.id.isNotEmpty ? ingredient.id : generateId();
    await db.insert('ingredients_library', ingredient.copyWith(id: id).toMap());
    return id;
  }

  @override
  Future<int> updateIngredient(IngredientModel ingredient) async {
    final db = await _dbHelper.database;
    return db.update(
      'ingredients_library',
      ingredient.toMap(),
      where: 'id = ?',
      whereArgs: [ingredient.id],
    );
  }

  @override
  Future<int> deleteIngredient(String id) async {
    final db = await _dbHelper.database;
    return db.delete('ingredients_library', where: 'id = ?', whereArgs: [id]);
  }

  // === Products ===
  @override
  Future<List<ProductModel>> getAllProducts({
    bool includeArchived = false,
  }) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'my_products',
      where: includeArchived ? null : 'is_archived = 0',
      orderBy: 'name ASC',
    );
    return result.map(ProductModel.fromMap).toList();
  }

  @override
  Future<ProductModel?> getProductById(String id) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'my_products',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return ProductModel.fromMap(result.first);
  }

  @override
  Future<String> createProduct(ProductModel product) async {
    final db = await _dbHelper.database;
    final id = product.id.isNotEmpty ? product.id : generateId();
    await db.insert('my_products', product.copyWith(id: id).toMap());
    return id;
  }

  @override
  Future<int> updateProduct(ProductModel product) async {
    final db = await _dbHelper.database;
    return db.update(
      'my_products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  @override
  Future<int> deleteProduct(String id) async {
    final db = await _dbHelper.database;
    // Also delete composition entries
    await db.delete('product_composition',
        where: 'product_id = ?', whereArgs: [id]);
    return db.delete('my_products', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<int> archiveProduct(String id) async {
    final db = await _dbHelper.database;
    return db.update(
      'my_products',
      {'is_archived': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // === Product Composition ===
  @override
  Future<List<ProductCompositionModel>> getProductComposition(
      String productId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'product_composition',
      where: 'product_id = ?',
      whereArgs: [productId],
    );
    return result.map(ProductCompositionModel.fromMap).toList();
  }

  @override
  Future<void> setProductComposition(
    String productId,
    List<ProductCompositionModel> composition,
  ) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      // Clear existing composition
      await txn.delete(
        'product_composition',
        where: 'product_id = ?',
        whereArgs: [productId],
      );
      // Insert new composition
      for (final entry in composition) {
        await txn.insert('product_composition', entry.toMap());
      }
    });
  }

  // === Supplement Logs ===
  @override
  Future<List<SupplementLogModel>> getLogs({
    DateTime? from,
    DateTime? to,
  }) async {
    final db = await _dbHelper.database;
    String? where;
    List<dynamic>? whereArgs;

    if (from != null && to != null) {
      where = 'date >= ? AND date <= ?';
      whereArgs = [from.millisecondsSinceEpoch, to.millisecondsSinceEpoch];
    } else if (from != null) {
      where = 'date >= ?';
      whereArgs = [from.millisecondsSinceEpoch];
    } else if (to != null) {
      where = 'date <= ?';
      whereArgs = [to.millisecondsSinceEpoch];
    }

    final result = await db.query(
      'supplement_logs',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'date DESC',
    );
    return result.map(SupplementLogModel.fromMap).toList();
  }

  @override
  Future<SupplementLogModel?> getLogById(String id) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'supplement_logs',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return SupplementLogModel.fromMap(result.first);
  }

  @override
  Future<String> createLog(
    SupplementLogModel log,
    List<SupplementLogDetailModel> details,
  ) async {
    final db = await _dbHelper.database;
    final id = log.id.isNotEmpty ? log.id : generateId();

    await db.transaction((txn) async {
      // Insert log header
      await txn.insert('supplement_logs', log.copyWith(id: id).toMap());
      // Insert snapshot details (immutable history)
      for (final detail in details) {
        await txn.insert(
            'supplement_log_details', detail.copyWith(logId: id).toMap());
      }
    });

    return id;
  }

  @override
  Future<int> deleteLog(String id) async {
    final db = await _dbHelper.database;
    // Details are deleted via CASCADE
    return db.delete('supplement_logs', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<SupplementLogDetailModel>> getLogDetails(String logId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'supplement_log_details',
      where: 'log_id = ?',
      whereArgs: [logId],
    );
    return result.map(SupplementLogDetailModel.fromMap).toList();
  }

  // === Analytics ===
  @override
  Future<Map<String, ({double amount, String unit})>> getTotalIntake({
    required DateTime from,
    required DateTime to,
  }) async {
    final db = await _dbHelper.database;

    // Get all log IDs in the date range
    final logs = await db.query(
      'supplement_logs',
      columns: ['id'],
      where: 'date >= ? AND date <= ?',
      whereArgs: [from.millisecondsSinceEpoch, to.millisecondsSinceEpoch],
    );

    if (logs.isEmpty) return {};

    final logIds = logs.map((l) => l['id'] as String).toList();
    final placeholders = List.filled(logIds.length, '?').join(',');

    // Sum up all ingredient amounts
    final result = await db.rawQuery('''
      SELECT ingredient_name, unit, SUM(amount_total) as total
      FROM supplement_log_details
      WHERE log_id IN ($placeholders)
      GROUP BY ingredient_name, unit
      ORDER BY ingredient_name ASC
    ''', logIds);

    final Map<String, ({double amount, String unit})> totals = {};
    for (final row in result) {
      final name = row['ingredient_name'] as String;
      final unit = row['unit'] as String;
      final total = (row['total'] as num).toDouble();
      totals[name] = (amount: total, unit: unit);
    }

    return totals;
  }
}

