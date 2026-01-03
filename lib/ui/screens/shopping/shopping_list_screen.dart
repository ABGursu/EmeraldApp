import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/shopping_item_model.dart';
import '../../../data/models/shopping_priority.dart';
import '../../../data/models/tag_model.dart';
import '../../../ui/viewmodels/balance_view_model.dart';
import '../../../ui/viewmodels/shopping_view_model.dart';
import 'add_edit_shopping_item_sheet.dart';
import 'mark_purchased_dialog.dart';
import 'shopping_settings_sheet.dart';

class ShoppingListScreen extends StatelessWidget {
  const ShoppingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ShoppingViewModel>(
      builder: (context, vm, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Shopping List'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                tooltip: 'Settings',
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => ChangeNotifierProvider.value(
                    value: vm,
                    child: const ShoppingSettingsSheet(),
                  ),
                ),
              ),
            ],
          ),
          body: vm.isLoading
              ? const Center(child: CircularProgressIndicator())
              : _ShoppingListContent(vm: vm),
          floatingActionButton: FloatingActionButton(
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => ChangeNotifierProvider.value(
                value: vm,
                child: const AddEditShoppingItemSheet(),
              ),
            ),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}

class _ShoppingListContent extends StatelessWidget {
  const _ShoppingListContent({required this.vm});

  final ShoppingViewModel vm;

  @override
  Widget build(BuildContext context) {
    final unpurchased = vm.unpurchasedItems;
    final purchased = vm.purchasedItems;

    if (unpurchased.isEmpty && purchased.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No items yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to add your first shopping item',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Unpurchased Items Section
        if (unpurchased.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'To Buy (${unpurchased.length})',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: unpurchased.length > purchased.length ? 2 : 1,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: unpurchased.length,
              itemBuilder: (context, index) {
                final item = unpurchased[index];
                return _ShoppingItemTile(
                  item: item,
                  vm: vm,
                  isPurchased: false,
                );
              },
            ),
          ),
        ],
        // Purchased Items Section (Collapsible)
        if (purchased.isNotEmpty) ...[
          const Divider(height: 1),
          ExpansionTile(
            title: Text(
              'Purchased (${purchased.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            initiallyExpanded: false,
            children: [
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: purchased.length,
                itemBuilder: (context, index) {
                  final item = purchased[index];
                  return _ShoppingItemTile(
                    item: item,
                    vm: vm,
                    isPurchased: true,
                  );
                },
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ShoppingItemTile extends StatelessWidget {
  const _ShoppingItemTile({
    required this.item,
    required this.vm,
    required this.isPurchased,
  });

  final ShoppingItemModel item;
  final ShoppingViewModel vm;
  final bool isPurchased;

  @override
  Widget build(BuildContext context) {
    final balanceVm = context.read<BalanceViewModel>();
    final tag = vm.tags.firstWhere(
      (t) => t.id == item.tagId,
      orElse: () => TagModel(
        id: '',
        name: 'Shopping',
        colorValue: 0xFFD2B48C,
        createdAt: DateTime.now(),
      ),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: _buildPriorityIndicator(item.priority),
        title: Text(
          item.name,
          style: TextStyle(
            decoration: isPurchased ? TextDecoration.lineThrough : null,
            color: isPurchased
                ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)
                : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isPurchased && item.actualPrice != null) ...[
              Row(
                children: [
                  Text(
                    item.actualPrice!.toStringAsFixed(2),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(width: 8),
                  _buildVarianceIndicator(item),
                ],
              ),
            ] else ...[
              Text('Est: ${item.estimatedPrice.toStringAsFixed(2)}'),
            ],
            if (item.quantity != null) Text('Qty: ${item.quantity}'),
            if (item.note != null && item.note!.isNotEmpty)
              Text(
                item.note!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tag Chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Color(tag.colorValue).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Color(tag.colorValue).withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Text(
                tag.name,
                style: TextStyle(
                  fontSize: 10,
                  color: Color(tag.colorValue),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Checkbox or Edit button
            if (!isPurchased)
              Checkbox(
                value: false,
                onChanged: (checked) => _showMarkPurchasedDialog(
                  context,
                  item,
                  vm,
                  balanceVm,
                ),
              )
            else
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () => _showEditPurchasedDialog(
                  context,
                  item,
                  vm,
                  balanceVm,
                ),
              ),
            // Note icon
            if (item.note != null && item.note!.isNotEmpty)
              Icon(
                Icons.note,
                size: 16,
                color: Theme.of(context).colorScheme.secondary,
              ),
          ],
        ),
        onLongPress: () => _showItemOptions(context, item, vm, balanceVm),
      ),
    );
  }

  Widget _buildPriorityIndicator(ShoppingPriority priority) {
    Color color;
    IconData icon;
    switch (priority) {
      case ShoppingPriority.asap:
        color = Colors.red;
        icon = Icons.priority_high;
        break;
      case ShoppingPriority.high:
        color = Colors.orange;
        icon = Icons.arrow_upward;
        break;
      case ShoppingPriority.mid:
        color = Colors.blue;
        icon = Icons.remove;
        break;
      case ShoppingPriority.low:
        color = Colors.grey;
        icon = Icons.arrow_downward;
        break;
      case ShoppingPriority.future:
        color = Colors.grey.shade600;
        icon = Icons.schedule;
        break;
    }

    return CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.2),
      radius: 16,
      child: Icon(icon, size: 16, color: color),
    );
  }

  Widget _buildVarianceIndicator(ShoppingItemModel item) {
    if (item.actualPrice == null || item.variance == null) {
      return const SizedBox.shrink();
    }

    final variance = item.variance!;
    final isOver = item.isOverBudget;
    final isUnder = item.isUnderBudget;

    if (!isOver && !isUnder) {
      return const SizedBox.shrink(); // Exact match, no indicator
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isOver
            ? Colors.red.withValues(alpha: 0.15)
            : Colors.green.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${isOver ? '+' : '-'}${variance.abs().toStringAsFixed(0)}',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isOver ? Colors.red.shade700 : Colors.green.shade700,
        ),
      ),
    );
  }

  void _showMarkPurchasedDialog(
    BuildContext context,
    ShoppingItemModel item,
    ShoppingViewModel vm,
    BalanceViewModel balanceVm,
  ) {
    showDialog(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: balanceVm,
        child: ChangeNotifierProvider.value(
          value: vm,
          child: MarkPurchasedDialog(item: item),
        ),
      ),
    );
  }

  void _showEditPurchasedDialog(
    BuildContext context,
    ShoppingItemModel item,
    ShoppingViewModel vm,
    BalanceViewModel balanceVm,
  ) {
    showDialog(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: balanceVm,
        child: ChangeNotifierProvider.value(
          value: vm,
          child: MarkPurchasedDialog(item: item, isEditing: true),
        ),
      ),
    );
  }

  void _showItemOptions(
    BuildContext context,
    ShoppingItemModel item,
    ShoppingViewModel vm,
    BalanceViewModel balanceVm,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => ChangeNotifierProvider.value(
                    value: vm,
                    child: AddEditShoppingItemSheet(item: item),
                  ),
                );
              },
            ),
            if (item.isPurchased)
              ListTile(
                leading: const Icon(Icons.undo),
                title: const Text('Unpurchase'),
                onTap: () async {
                  Navigator.pop(context);
                  await vm.unpurchaseItem(item: item, balanceVm: balanceVm);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Item unpurchased')),
                    );
                  }
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                await _showDeleteConfirmation(context, item, vm, balanceVm);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    ShoppingItemModel item,
    ShoppingViewModel vm,
    BalanceViewModel balanceVm,
  ) async {
    final hasLinkedTransaction = item.linkedTransactionId != null;
    final shouldDeleteExpense = hasLinkedTransaction && !vm.autoDeleteExpense;

    if (shouldDeleteExpense) {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Item'),
          content: const Text(
            'Do you want to delete the associated expense record as well?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes'),
            ),
          ],
        ),
      );

      if (confirmed == true && context.mounted) {
        // Delete the expense
        await balanceVm.deleteTransaction(item.linkedTransactionId!);
      }
    }

    if (context.mounted) {
      await vm.deleteItem(item.id, balanceVm: balanceVm);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Item "${item.name}" deleted')),
        );
      }
    }
  }
}

