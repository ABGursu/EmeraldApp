import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/shopping_item_model.dart';
import '../../../data/models/shopping_priority.dart';
import '../../../data/models/tag_model.dart';
import '../../../ui/viewmodels/balance_view_model.dart';
import '../../../ui/viewmodels/shopping_view_model.dart';
import '../../widgets/color_coded_selector.dart';

class AddEditShoppingItemSheet extends StatefulWidget {
  const AddEditShoppingItemSheet({super.key, this.item});

  final ShoppingItemModel? item;

  @override
  State<AddEditShoppingItemSheet> createState() =>
      _AddEditShoppingItemSheetState();
}

class _AddEditShoppingItemSheetState extends State<AddEditShoppingItemSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _estimatedPriceController;
  late final TextEditingController _quantityController;
  late final TextEditingController _noteController;
  late ShoppingPriority _selectedPriority;
  ColorCodedItem? _selectedTag;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.name ?? '');
    _estimatedPriceController = TextEditingController(
      text: widget.item?.estimatedPrice.toStringAsFixed(2) ?? '',
    );
    _quantityController = TextEditingController(
      text: widget.item?.quantity?.toString() ?? '',
    );
    _noteController = TextEditingController(text: widget.item?.note ?? '');
    _selectedPriority = widget.item?.priority ?? ShoppingPriority.medium;

    // Initialize tag selection
    if (widget.item?.tagId != null) {
      final vm = context.read<ShoppingViewModel>();
      final tag = vm.tags.firstWhere(
        (t) => t.id == widget.item!.tagId,
        orElse: () => TagModel(
          id: '',
          name: '',
          colorValue: 0,
          createdAt: DateTime.now(),
        ),
      );
      if (tag.id.isNotEmpty) {
        _selectedTag = ColorCodedItem(
          id: tag.id,
          name: tag.name,
          colorValue: tag.colorValue,
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _estimatedPriceController.dispose();
    _quantityController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ShoppingViewModel>();
    final isEditing = widget.item != null;
    final tagItems = vm.tags
        .map((t) => ColorCodedItem(
              id: t.id,
              name: t.name,
              colorValue: t.colorValue,
            ))
        .toList();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing ? 'Edit Item' : 'Add Item',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Item Name *',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: !isEditing,
                  validator: (v) =>
                      v?.isEmpty ?? true ? 'Item name is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _estimatedPriceController,
                  decoration: const InputDecoration(
                    labelText: 'Estimated Price *',
                    border: OutlineInputBorder(),
                    prefixText: '\$ ',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    final value = double.tryParse(v ?? '');
                    if (value == null || value <= 0) {
                      return 'Enter a valid price';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Priority Selection
                Text(
                  'Priority *',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<ShoppingPriority>(
                  segments: ShoppingPriority.values.map((priority) {
                    return ButtonSegment<ShoppingPriority>(
                      value: priority,
                      label: Text(priority.label),
                      icon: _getPriorityIcon(priority),
                    );
                  }).toList(),
                  selected: {_selectedPriority},
                  onSelectionChanged: (Set<ShoppingPriority> selection) {
                    setState(() => _selectedPriority = selection.first);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _quantityController,
                  decoration: const InputDecoration(
                    labelText: 'Quantity (optional)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v != null && v.isNotEmpty) {
                      final value = int.tryParse(v);
                      if (value == null || value <= 0) {
                        return 'Enter a valid quantity';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                ColorCodedSelectorFormField(
                  label: 'Tag (optional)',
                  items: tagItems,
                  initialValue: _selectedTag,
                  onEditItem: (item, name, color) async => item, // Not used
                  onDeleteItem: (item) async {}, // Not used
                  onChanged: (item) => _selectedTag = item,
                  validator: (item) => null,
                  onCreateNew: (name, color) async {
                    // Create new tag via BalanceViewModel
                    final balanceVm = context.read<BalanceViewModel>();
                    final tagId = await balanceVm.addTag(name, color);
                    await vm.loadTags(); // Reload tags in shopping view model
                    return ColorCodedItem(
                      id: tagId,
                      name: name,
                      colorValue: color,
                    );
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => _saveItem(context, vm, isEditing),
                    child: Text(isEditing ? 'Update' : 'Add'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Icon _getPriorityIcon(ShoppingPriority priority) {
    switch (priority) {
      case ShoppingPriority.urgent:
        return const Icon(Icons.priority_high, size: 18);
      case ShoppingPriority.high:
        return const Icon(Icons.arrow_upward, size: 18);
      case ShoppingPriority.medium:
        return const Icon(Icons.remove, size: 18);
      case ShoppingPriority.low:
        return const Icon(Icons.arrow_downward, size: 18);
    }
  }

  Future<void> _saveItem(
    BuildContext context,
    ShoppingViewModel vm,
    bool isEditing,
  ) async {
    if (!_formKey.currentState!.validate()) return;

    final estimatedPrice = double.parse(_estimatedPriceController.text);
    final quantity = _quantityController.text.isNotEmpty
        ? int.tryParse(_quantityController.text)
        : null;

    if (isEditing && widget.item != null) {
      final updatedItem = widget.item!.copyWith(
        name: _nameController.text.trim(),
        estimatedPrice: estimatedPrice,
        priority: _selectedPriority,
        quantity: quantity,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        tagId: _selectedTag?.id,
      );
      await vm.updateItem(updatedItem);
    } else {
      await vm.addItem(
        name: _nameController.text.trim(),
        estimatedPrice: estimatedPrice,
        priority: _selectedPriority,
        quantity: quantity,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        tagId: _selectedTag?.id,
      );
    }

    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'Item updated' : 'Item added'),
        ),
      );
    }
  }
}

