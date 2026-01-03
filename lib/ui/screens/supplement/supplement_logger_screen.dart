import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/product_model.dart';
import '../../viewmodels/supplement_view_model.dart';

/// Screen for logging supplement consumption.
class SupplementLoggerScreen extends StatefulWidget {
  const SupplementLoggerScreen({super.key});

  @override
  State<SupplementLoggerScreen> createState() => _SupplementLoggerScreenState();
}

class _SupplementLoggerScreenState extends State<SupplementLoggerScreen> {
  ProductModel? _selectedProduct;
  double _servingsCount = 1.0;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Supplement'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.mounted) {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Consumer<SupplementViewModel>(
        builder: (context, vm, _) {
          if (vm.products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No products available',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add products in "My Products" first',
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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Selection
                Text(
                  'Select Product',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                _buildProductSelector(vm.products),

                const SizedBox(height: 24),

                // Servings Count
                Text(
                  'Servings',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                _buildServingsSelector(),

                const SizedBox(height: 24),

                // Date & Time
                Text(
                  'Date & Time',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                _buildDateTimeSelector(),

                const SizedBox(height: 32),

                // Preview (if product selected)
                if (_selectedProduct != null) _buildPreviewCard(vm),

                const SizedBox(height: 32),

                // Log Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: _selectedProduct == null || _saving
                        ? null
                        : () => _logSupplement(vm),
                    icon: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: Text(_saving ? 'Logging...' : 'Log Supplement'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductSelector(List<ProductModel> products) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: products.map((product) {
          final isSelected = _selectedProduct?.id == product.id;
          return InkWell(
            onTap: () => setState(() => _selectedProduct = product),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                    : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: TextStyle(
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        Text(
                          'Per ${product.servingUnit}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.6),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildServingsSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton.filled(
              onPressed: _servingsCount > 0.5
                  ? () => setState(() => _servingsCount -= 0.5)
                  : null,
              icon: const Icon(Icons.remove),
            ),
            const SizedBox(width: 24),
            Column(
              children: [
                Text(
                  _servingsCount.toString(),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                Text(
                  _selectedProduct != null
                      ? _selectedProduct!.servingUnit +
                          (_servingsCount != 1 ? 's' : '')
                      : 'serving(s)',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(width: 24),
            IconButton.filled(
              onPressed: () => setState(() => _servingsCount += 0.5),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeSelector() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today),
            label: Text(
              '${_selectedDate.day.toString().padLeft(2, '0')}.${_selectedDate.month.toString().padLeft(2, '0')}.${_selectedDate.year}',
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _pickTime,
            icon: const Icon(Icons.access_time),
            label: Text(
              '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewCard(SupplementViewModel vm) {
    return FutureBuilder(
      future: vm.getProductComposition(_selectedProduct!.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final composition = snapshot.data!;
        if (composition.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'This product has no ingredients defined.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.orange,
                    ),
              ),
            ),
          );
        }

        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.preview,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Preview: What You\'ll Log',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const Divider(),
                ...composition.map((comp) {
                  final ingredient = vm.ingredients.firstWhere(
                    (i) => i.id == comp.ingredientId,
                    orElse: () => throw Exception('Ingredient not found'),
                  );
                  final totalAmount = comp.amountPerServing * _servingsCount;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(ingredient.name),
                        Text(
                          '${_formatAmount(totalAmount)} ${ingredient.defaultUnit}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && mounted) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _logSupplement(SupplementViewModel vm) async {
    if (_selectedProduct == null) return;

    setState(() => _saving = true);

    final dateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    try {
      await vm.logSupplement(
        product: _selectedProduct!,
        servingsCount: _servingsCount,
        date: dateTime,
      );

      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logged ${_selectedProduct!.name}'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _saving = false);
      }
    }
  }

  String _formatAmount(double amount) {
    if (amount == amount.roundToDouble()) {
      return amount.toInt().toString();
    }
    return amount.toStringAsFixed(2);
  }
}

