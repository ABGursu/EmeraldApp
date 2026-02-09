import '../local_db/database_helper.dart';
import '../models/shopping_item_model.dart';
import 'i_shopping_repository.dart';

class SqlShoppingRepository implements IShoppingRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  Future<String> createItem(ShoppingItemModel item) async {
    final db = await _dbHelper.database;
    await db.insert('shopping_items', item.toMap());
    return item.id;
  }

  @override
  Future<int> updateItem(ShoppingItemModel item) async {
    final db = await _dbHelper.database;
    return await db.update(
      'shopping_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  @override
  Future<int> deleteItem(String id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'shopping_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<List<ShoppingItemModel>> getAllItems() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'shopping_items',
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => ShoppingItemModel.fromMap(map)).toList();
  }

  @override
  Future<ShoppingItemModel?> getItemById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'shopping_items',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return ShoppingItemModel.fromMap(maps.first);
  }

  @override
  Future<void> resetAll() async {
    final db = await _dbHelper.database;
    await db.delete('shopping_items');
  }
}

