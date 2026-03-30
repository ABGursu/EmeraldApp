import '../local_db/database_helper.dart';
import '../models/tab_inspector_item_model.dart';
import 'i_tab_inspector_repository.dart';

class SqlTabInspectorRepository implements ITabInspectorRepository {
  SqlTabInspectorRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _dbHelper;

  @override
  Future<String> create(TabInspectorItem item) async {
    final db = await _dbHelper.database;
    var row = item;
    if (!item.isDone) {
      final r = await db.rawQuery(
        'SELECT MIN(sort_order) AS m FROM tab_inspector_items WHERE is_done = 0',
      );
      final m = r.first['m'] as int?;
      final nextOrder = m != null ? m - 1 : 0;
      row = item.copyWith(sortOrder: nextOrder);
    }
    await db.insert('tab_inspector_items', row.toMap());
    return row.id;
  }

  @override
  Future<int> update(TabInspectorItem item) async {
    final db = await _dbHelper.database;
    return db.update(
      'tab_inspector_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  @override
  Future<int> delete(String id) async {
    final db = await _dbHelper.database;
    return db.delete(
      'tab_inspector_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<List<TabInspectorItem>> getAll() async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'tab_inspector_items',
      orderBy: 'is_done ASC, sort_order ASC, created_at DESC',
    );
    return rows.map(TabInspectorItem.fromMap).toList();
  }

  @override
  Future<TabInspectorItem?> getById(String id) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'tab_inspector_items',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return TabInspectorItem.fromMap(rows.first);
  }
}
