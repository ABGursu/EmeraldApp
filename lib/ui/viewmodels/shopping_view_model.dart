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

  /// Deletes all shopping items. Use for "start from scratch".
  Future<void> resetAll() async {
    await _repository.resetAll();
    _items = [];
    notifyListeners();
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

  /// Gets or creates the light yellow "Rented" tag for Balance Sheet rent placeholders
  static const int _rentedTagColor = 0xFFFFE082; // Amber 200 - light yellow

  Future<String> getOrCreateRentedTag() async {
    final rentedTag = _tags.firstWhere(
      (tag) => tag.name.toLowerCase() == 'rented',
      orElse: () => TagModel(
        id: '',
        name: '',
        colorValue: 0,
        createdAt: DateTime.now(),
      ),
    );

    if (rentedTag.id.isNotEmpty) {
      // Update to lighter color if it had the old darker one
      if (rentedTag.colorValue != _rentedTagColor) {
        await _balanceRepository.updateTag(
          rentedTag.copyWith(colorValue: _rentedTagColor),
        );
        await loadTags();
      }
      return rentedTag.id;
    }

    // Light yellow tag: #FFE082 (Amber 200)
    final newTag = TagModel(
      id: generateId(),
      name: 'Rented',
      colorValue: _rentedTagColor,
      createdAt: DateTime.now(),
    );
    final id = await _balanceRepository.createTag(newTag);
    await loadTags();
    return id;
  }

  Future<String> addItem({
    required String name,
    required double estimatedPrice,
    required ShoppingPriority priority,
    int? quantity,
    String? note,
    String? tagId,
    bool rentInBalanceSheet = false,
    BalanceViewModel? balanceVm,
  }) async {
    // If no tag provided, use default "Shopping" tag
    final finalTagId = tagId ?? await getOrCreateShoppingTag();

    var item = ShoppingItemModel(
      id: generateId(),
      name: name,
      estimatedPrice: estimatedPrice,
      priority: priority,
      quantity: quantity,
      note: note,
      tagId: finalTagId,
      rentInBalanceSheet: rentInBalanceSheet,
      createdAt: DateTime.now(),
    );

    await _repository.createItem(item);

    // Create rent transaction in Balance Sheet if option is enabled
    if (rentInBalanceSheet && balanceVm != null) {
      final rentAmount = estimatedPrice * (quantity ?? 1);
      final rentTagId = await getOrCreateRentedTag();
      final txId = await balanceVm.addTransaction(
        amount: rentAmount,
        isExpense: true,
        date: DateTime.now(),
        tagId: rentTagId,
        note: 'Rented by $name',
      );
      item = item.copyWith(linkedRentTransactionId: txId);
      await _repository.updateItem(item);
    }

    await loadItems();
    return item.id;
  }

  Future<void> updateItem(
    ShoppingItemModel item, {
    BalanceViewModel? balanceVm,
  }) async {
    ShoppingItemModel? existing;
    for (final i in _items) {
      if (i.id == item.id) {
        existing = i;
        break;
      }
    }
    if (existing != null && balanceVm != null) {
      // Rent was on, now off: remove rent transaction
      if (existing.rentInBalanceSheet && !item.rentInBalanceSheet) {
        if (existing.linkedRentTransactionId != null) {
          await balanceVm.deleteTransaction(existing.linkedRentTransactionId!);
        }
        item = item.copyWith(linkedRentTransactionId: null);
      }
      // Rent was off, now on: create rent transaction
      else if (!existing.rentInBalanceSheet && item.rentInBalanceSheet) {
        final rentAmount = item.estimatedPrice * (item.quantity ?? 1);
        final rentTagId = await getOrCreateRentedTag();
        final txId = await balanceVm.addTransaction(
          amount: rentAmount,
          isExpense: true,
          date: DateTime.now(),
          tagId: rentTagId,
          note: 'Rented by ${item.name}',
        );
        item = item.copyWith(linkedRentTransactionId: txId);
      }
      // Rent still on but price/name/quantity changed: update rent transaction
      else if (item.rentInBalanceSheet &&
          item.linkedRentTransactionId != null &&
          (existing.estimatedPrice != item.estimatedPrice ||
              existing.quantity != item.quantity ||
              existing.name != item.name)) {
        final rentAmount = item.estimatedPrice * (item.quantity ?? 1);
        await balanceVm.deleteTransaction(item.linkedRentTransactionId!);
        final rentTagId = await getOrCreateRentedTag();
        final txId = await balanceVm.addTransaction(
          amount: rentAmount,
          isExpense: true,
          date: DateTime.now(),
          tagId: rentTagId,
          note: 'Rented by ${item.name}',
        );
        item = item.copyWith(linkedRentTransactionId: txId);
      }
    }

    await _repository.updateItem(item);
    await loadItems();
  }

  Future<void> deleteItem(String id, {BalanceViewModel? balanceVm}) async {
    final item = _items.firstWhere((i) => i.id == id);
    final hasLinkedTransaction = item.linkedTransactionId != null;
    final hasRentTransaction = item.linkedRentTransactionId != null;

    // Remove rent transaction (always - rent is placeholder, not actual purchase)
    if (hasRentTransaction && balanceVm != null) {
      await balanceVm.deleteTransaction(item.linkedRentTransactionId!);
    }

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
    // Remove rent transaction if it exists (rent is replaced by actual purchase)
    if (item.linkedRentTransactionId != null) {
      await balanceVm.deleteTransaction(item.linkedRentTransactionId!);
    }

    // Create expense transaction and get its ID
    final transactionId = await balanceVm.addTransaction(
      amount: actualPrice,
      isExpense: true,
      date: purchaseDate,
      tagId: item.tagId ?? await getOrCreateShoppingTag(),
      note: 'Shopping: ${item.name}',
    );

    // Update shopping item (clear rent fields)
    final updatedItem = item.copyWith(
      isPurchased: true,
      actualPrice: actualPrice,
      purchaseDate: purchaseDate,
      linkedTransactionId: transactionId,
      linkedRentTransactionId: null,
    );

    await _repository.updateItem(updatedItem);
    await loadItems();
  }

  /// Unpurchases an item (reverses the purchase)
  Future<void> unpurchaseItem({
    required ShoppingItemModel item,
    required BalanceViewModel balanceVm,
  }) async {
    // Store transaction ID before clearing it (for deletion after FK is cleared)
    final transactionIdToDelete = item.linkedTransactionId;

    // IMPORTANT: First update shopping item to clear linked_transaction_id
    // This must happen BEFORE deleting the transaction to avoid foreign key constraint violation
    final updatedItem = item.copyWith(
      isPurchased: false,
      actualPrice: null,
      purchaseDate: null,
      linkedTransactionId: null,
    );

    await _repository.updateItem(updatedItem);

    // Now safe to delete the transaction (FK constraint is cleared)
    if (transactionIdToDelete != null) {
      await balanceVm.deleteTransaction(transactionIdToDelete);
    }

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
