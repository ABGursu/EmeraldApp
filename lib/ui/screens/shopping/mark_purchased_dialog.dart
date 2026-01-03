import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/shopping_item_model.dart';
import '../../../ui/viewmodels/balance_view_model.dart';
import '../../../ui/viewmodels/shopping_view_model.dart';
import '../../../utils/date_formats.dart';

class MarkPurchasedDialog extends StatefulWidget {
  const MarkPurchasedDialog({
    super.key,
    required this.item,
    this.isEditing = false,
  });

  final ShoppingItemModel item;
  final bool isEditing;

  @override
  State<MarkPurchasedDialog> createState() => _MarkPurchasedDialogState();
}

class _MarkPurchasedDialogState extends State<MarkPurchasedDialog> {
  late final TextEditingController _actualPriceController;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _actualPriceController = TextEditingController(
      text: widget.item.actualPrice?.toStringAsFixed(2) ??
          widget.item.estimatedPrice.toStringAsFixed(2),
    );
    _selectedDate = widget.item.purchaseDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _actualPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ShoppingViewModel>();
    final balanceVm = context.watch<BalanceViewModel>();

    return AlertDialog(
      title: Text(widget.isEditing ? 'Edit Purchase' : 'Mark as Purchased'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.item.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _actualPriceController,
              decoration: const InputDecoration(
                labelText: 'Actual Price *',
                border: OutlineInputBorder(),
                prefixText: 'TL ',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              validator: (v) {
                final value = double.tryParse(v ?? '');
                if (value == null || value <= 0) {
                  return 'Enter a valid price';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Purchase Date *'),
              subtitle: Text(formatDateTime(_selectedDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _pickDate(context),
            ),
            if (!widget.isEditing) ...[
              const SizedBox(height: 8),
              Text(
                'Estimated: ${widget.item.estimatedPrice.toStringAsFixed(2)} TL',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => _savePurchase(context, vm, balanceVm),
          child: Text(widget.isEditing ? 'Update' : 'Mark Purchased'),
        ),
      ],
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _savePurchase(
    BuildContext context,
    ShoppingViewModel vm,
    BalanceViewModel balanceVm,
  ) async {
    final actualPrice = double.tryParse(_actualPriceController.text);
    if (actualPrice == null || actualPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid price')),
      );
      return;
    }

    if (widget.isEditing) {
      await vm.updatePurchasedItem(
        item: widget.item,
        newActualPrice: actualPrice,
        newPurchaseDate: _selectedDate,
        balanceVm: balanceVm,
      );
    } else {
      await vm.markAsPurchased(
        item: widget.item,
        actualPrice: actualPrice,
        purchaseDate: _selectedDate,
        balanceVm: balanceVm,
      );
    }

    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing
                ? 'Purchase updated'
                : 'Item marked as purchased',
          ),
        ),
      );
    }
  }
}

