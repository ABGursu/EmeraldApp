import '../models/todo_item_model.dart';

abstract class ITodoRepository {
  Future<String> createItem(TodoItemModel item);
  Future<int> updateItem(TodoItemModel item);
  Future<int> deleteItem(String id);
  Future<List<TodoItemModel>> getAllItems();
  Future<TodoItemModel?> getItemById(String id);
  Future<void> resetAll();
}
