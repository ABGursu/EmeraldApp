import '../models/tab_inspector_item_model.dart';

abstract class ITabInspectorRepository {
  Future<String> create(TabInspectorItem item);
  Future<int> update(TabInspectorItem item);
  Future<int> delete(String id);
  Future<List<TabInspectorItem>> getAll();
  Future<TabInspectorItem?> getById(String id);
}
