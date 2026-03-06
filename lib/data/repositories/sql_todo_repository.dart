import '../local_db/database_helper.dart';
import '../models/todo_item_model.dart';
import 'i_todo_repository.dart';

class SqlTodoRepository implements ITodoRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  Future<String> createItem(TodoItemModel item) async {
    final db = await _dbHelper.database;
    await db.insert('todo_items', item.toMap());
    return item.id;
  }

  @override
  Future<int> updateItem(TodoItemModel item) async {
    final db = await _dbHelper.database;
    return await db.update(
      'todo_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  @override
  Future<int> deleteItem(String id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'todo_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<List<TodoItemModel>> getAllItems() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'todo_items',
      orderBy: 'deadline ASC, created_at DESC',
    );
    return maps.map((map) => TodoItemModel.fromMap(map)).toList();
  }

  @override
  Future<TodoItemModel?> getItemById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'todo_items',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return TodoItemModel.fromMap(maps.first);
  }

  @override
  Future<void> resetAll() async {
    final db = await _dbHelper.database;
    await db.delete('todo_items');
  }
}
