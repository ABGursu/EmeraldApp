import '../models/shopping_item_model.dart';

abstract class IShoppingRepository {
  Future<String> createItem(ShoppingItemModel item);
  Future<int> updateItem(ShoppingItemModel item);
  Future<int> deleteItem(String id);
  Future<List<ShoppingItemModel>> getAllItems();
  Future<ShoppingItemModel?> getItemById(String id);
}

