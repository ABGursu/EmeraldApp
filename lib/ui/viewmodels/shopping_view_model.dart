import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/shopping_item_model.dart';
import '../../data/models/shopping_priority.dart';
import '../../data/models/tag_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/i_balance_repository.dart';
import '../../data/repositories/i_shopping_repository.dart';
import '../../data/repositories/sql_balance_repository.dart';
import '../../data/repositories/sql_shopping_repository.dart';
import '../../utils/id_generator.dart';
import 'balance_view_model.dart';

class ShoppingViewModel extends ChangeNotifier {
  ShoppingViewModel({
    IShoppingRepository? repository,
    IBalanceRepository? balanceRepository,
  })  : _repository = repository ?? SqlShoppingRepository(),
        _balanceRepository = balanceRepository ?? SqlBalanceRepository();

  final IShoppingRepository _repository;
  final IBalanceRepository _balanceRepository;

  List<ShoppingItemModel> _items = [];
  List<TagModel> _tags = [];
  bool _loading = false;
  bool _autoDeleteExpense = false; // Default: false

  List<ShoppingItemModel> get items => _items;
  List<TagModel> get tags => _tags;
  bool get isLoading => _loading;
  bool get autoDeleteExpense => _autoDeleteExpense;

  /// Get unpurchased items (main list)
  List<ShoppingItemModel> get unpurchasedItems {
    return _items.where((item) => !item.isPurchased).toList()
      ..sort((a, b) {
        // Sort by priority (urgent first), then by creation date
        final priorityDiff = b.priority.value.compareTo(a.priority.value);
        if (priorityDiff != 0) return priorityDiff;
        return b.createdAt.compareTo(a.createdAt);
      });
  }

  /// Get purchased items (history section)
  List<ShoppingItemModel> get purchasedItems {
    return _items.where((item) => item.isPurchased).toList()
      ..sort((a, b) {
        // Sort by purchase date (newest first)
        final aDate = a.purchaseDate ?? DateTime(1970);
        final bDate = b.purchaseDate ?? DateTime(1970);
        return bDate.compareTo(aDate);
      });
  }

  Future<void> init() async {
    await loadItems();
    await loadTags();
    await loadSettings();
  }

  Future<void> loadItems() async {
    _loading = true;
    notifyListeners();
    _items = await _repository.getAllItems();
    _loading = false;
    notifyListeners();
  }

  Future<void> loadTags() async {
    _tags = await _balanceRepository.getAllTags();
    notifyListeners();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _autoDeleteExpense = prefs.getBool('shopping_auto_delete_expense') ?? false;
    notifyListeners();
  }

  Future<void> setAutoDeleteExpense(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('shopping_auto_delete_expense', value);
    _autoDeleteExpense = value;
    notifyListeners();
  }

  /// Gets or creates the default "Shopping" tag
  Future<String> getOrCreateShoppingTag() async {
    // Look for existing "Shopping" tag
    final shoppingTag = _tags.firstWhere(
      (tag) => tag.name.toLowerCase() == 'shopping',
      orElse: () => TagModel(
        id: '',
        name: '',
        colorValue: 0,
        createdAt: DateTime.now(),
      ),
    );

    if (shoppingTag.id.isNotEmpty) {
      return shoppingTag.id;
    }

    // Create default "Shopping" tag (Light Brown: #D2B48C = 0xFFD2B48C)
    final newTag = TagModel(
      id: generateId(),
      name: 'Shopping',
      colorValue: 0xFFD2B48C, // Light Brown
      createdAt: DateTime.now(),
    );
    final id = await _balanceRepository.createTag(newTag);
    await loadTags(); // Reload tags
    return id;
  }

  Future<String> addItem({
    required String name,
    required double estimatedPrice,
    required ShoppingPriority priority,
    int? quantity,
    String? note,
    String? tagId,
  }) async {
    // If no tag provided, use default "Shopping" tag
    final finalTagId = tagId ?? await getOrCreateShoppingTag();

    final item = ShoppingItemModel(
      id: generateId(),
      name: name,
      estimatedPrice: estimatedPrice,
      priority: priority,
      quantity: quantity,
      note: note,
      tagId: finalTagId,
      createdAt: DateTime.now(),
    );

    final id = await _repository.createItem(item);
    await loadItems();
    return id;
  }

  Future<void> updateItem(ShoppingItemModel item) async {
    await _repository.updateItem(item);
    await loadItems();
  }

  Future<void> deleteItem(String id, {BalanceViewModel? balanceVm}) async {
    final item = _items.firstWhere((i) => i.id == id);
    final hasLinkedTransaction = item.linkedTransactionId != null;

    // Handle linked expense deletion based on settings
    if (hasLinkedTransaction && balanceVm != null) {
      if (_autoDeleteExpense) {
        // Auto-delete: remove expense immediately
        await balanceVm.deleteTransaction(item.linkedTransactionId!);
      }
      // If not auto-delete, UI will handle the confirmation dialog
    }

    await _repository.deleteItem(id);
    await loadItems();
  }

  /// Marks an item as purchased and creates the expense transaction
  Future<void> markAsPurchased({
    required ShoppingItemModel item,
    required double actualPrice,
    required DateTime purchaseDate,
    required BalanceViewModel balanceVm,
  }) async {
    // Create expense transaction and get its ID
    final transactionId = await balanceVm.addTransaction(
      amount: actualPrice,
      isExpense: true,
      date: purchaseDate,
      tagId: item.tagId ?? await getOrCreateShoppingTag(),
      note: 'Shopping: ${item.name}',
    );

    // Update shopping item
    final updatedItem = item.copyWith(
      isPurchased: true,
      actualPrice: actualPrice,
      purchaseDate: purchaseDate,
      linkedTransactionId: transactionId,
    );

    await _repository.updateItem(updatedItem);
    await loadItems();
  }

  /// Unpurchases an item (reverses the purchase)
  Future<void> unpurchaseItem({
    required ShoppingItemModel item,
    required BalanceViewModel balanceVm,
  }) async {
    // Delete the linked transaction if it exists
    if (item.linkedTransactionId != null) {
      await balanceVm.deleteTransaction(item.linkedTransactionId!);
    }

    // Update shopping item
    final updatedItem = item.copyWith(
      isPurchased: false,
      actualPrice: null,
      purchaseDate: null,
      linkedTransactionId: null,
    );

    await _repository.updateItem(updatedItem);
    await loadItems();
  }

  /// Updates a purchased item's price and date (updates the linked transaction)
  Future<void> updatePurchasedItem({
    required ShoppingItemModel item,
    required double newActualPrice,
    required DateTime newPurchaseDate,
    required BalanceViewModel balanceVm,
  }) async {
    // Update the linked transaction if it exists
    if (item.linkedTransactionId != null) {
      final existingTx = balanceVm.transactions.firstWhere(
        (tx) => tx.id == item.linkedTransactionId,
        orElse: () => TransactionModel(
          id: item.linkedTransactionId!,
          amount: -item.actualPrice!,
          date: item.purchaseDate!,
          tagId: item.tagId,
          note: 'Shopping: ${item.name}',
        ),
      );

      final updatedTx = existingTx.copyWith(
        amount: -newActualPrice.abs(),
        date: newPurchaseDate,
      );

      await balanceVm.updateTransaction(updatedTx);
    } else {
      // If no transaction exists, create one
      final transactionId = await balanceVm.addTransaction(
        amount: newActualPrice,
        isExpense: true,
        date: newPurchaseDate,
        tagId: item.tagId ?? await getOrCreateShoppingTag(),
        note: 'Shopping: ${item.name}',
      );

      final updatedItem = item.copyWith(
        actualPrice: newActualPrice,
        purchaseDate: newPurchaseDate,
        linkedTransactionId: transactionId,
      );

      await _repository.updateItem(updatedItem);
      await loadItems();
      return;
    }

    // Update shopping item
    final updatedItem = item.copyWith(
      actualPrice: newActualPrice,
      purchaseDate: newPurchaseDate,
    );

    await _repository.updateItem(updatedItem);
    await loadItems();
  }
}

