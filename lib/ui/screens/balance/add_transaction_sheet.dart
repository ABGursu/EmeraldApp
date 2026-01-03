import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/transaction_model.dart';
import '../../../ui/viewmodels/balance_view_model.dart';
import '../../widgets/color_coded_selector.dart';
import '../../../utils/date_formats.dart';

class AddTransactionSheet extends StatefulWidget {
  const AddTransactionSheet({super.key, this.transaction});

  final TransactionModel? transaction;

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isExpense = true;
  ColorCodedItem? _selectedTag;

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      final tx = widget.transaction!;
      _amountController.text = tx.amount.abs().toStringAsFixed(2);
      _isExpense = tx.amount < 0;
      _selectedDate = tx.date;
      _noteController.text = tx.note ?? '';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (!mounted) return;
    if (picked != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );
      if (!mounted) return;
      if (time != null) {
        setState(() {
          _selectedDate =
              DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BalanceViewModel>();
    final items = vm.tags
        .map((t) => ColorCodedItem(id: t.id, name: t.name, colorValue: t.colorValue))
        .toList();
    
    // Initialize tag selection if editing (only once)
    if (widget.transaction != null && _selectedTag == null && items.isNotEmpty) {
      final tx = widget.transaction!;
      if (tx.tagId != null) {
        _selectedTag = items.firstWhere(
          (t) => t.id == tx.tagId,
          orElse: () => const ColorCodedItem(id: '', name: '', colorValue: 0),
        );
      }
    }

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.transaction == null ? 'Add Transaction' : 'Edit Transaction',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<bool>(
                  initialValue: _isExpense,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: true, child: Text('Expense (-)')),
                    DropdownMenuItem(value: false, child: Text('Income (+)')),
                  ],
                  onChanged: (v) => setState(() => _isExpense = v ?? true),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    border: OutlineInputBorder(),
                    prefixText: 'TL ',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final value = double.tryParse(v ?? '');
                    if (value == null || value <= 0) {
                      return 'Enter a positive amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                ColorCodedSelectorFormField(
                  label: 'Tag',
                  items: items,
                  initialValue: _selectedTag,
                  onEditItem: (item, name, color) async {
                    final tag = vm.tags.firstWhere((t) => t.id == item.id);
                    final updated = tag.copyWith(name: name, colorValue: color);
                    await vm.updateTag(updated);
                    final updatedItem = ColorCodedItem(
                      id: updated.id,
                      name: updated.name,
                      colorValue: updated.colorValue,
                    );
                    _selectedTag = updatedItem;
                    return updatedItem;
                  },
                  onDeleteItem: (item) async {
                    await vm.deleteTag(item.id);
                    if (_selectedTag?.id == item.id) {
                      _selectedTag = null;
                    }
                  },
                  onChanged: (item) => _selectedTag = item,
                  validator: (item) => item == null ? 'Select a tag' : null,
                  onCreateNew: (name, color) async {
                    final id = await vm.addTag(name, color);
                    final newItem = ColorCodedItem(id: id, name: name, colorValue: color);
                    _selectedTag = newItem;
                    return newItem;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Date: ${formatDateTime(_selectedDate)}'),
                  trailing: TextButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Pick'),
                    onPressed: _pickDate,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('Save'),
                    onPressed: () async {
                      if (_formKey.currentState?.validate() != true) return;
                      final amount = double.parse(_amountController.text);
                      final tagId = _selectedTag?.id ?? widget.transaction?.tagId;
                      
                      if (widget.transaction != null) {
                        // Update existing transaction
                        await vm.updateTransaction(
                          widget.transaction!.copyWith(
                            amount: _isExpense ? -amount.abs() : amount.abs(),
                            date: _selectedDate,
                            tagId: tagId,
                            note: _noteController.text.trim().isEmpty
                                ? null
                                : _noteController.text.trim(),
                          ),
                        );
                      } else {
                        // Create new transaction
                        await vm.addTransaction(
                          amount: amount,
                          isExpense: _isExpense,
                          date: _selectedDate,
                          tagId: tagId,
                          note: _noteController.text.trim().isEmpty
                              ? null
                              : _noteController.text.trim(),
                        );
                      }
                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

