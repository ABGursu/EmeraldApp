import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/ingredient_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/product_composition_model.dart';
import '../../viewmodels/supplement_view_model.dart';

/// Screen for managing products and their compositions.
class ProductManagerScreen extends StatelessWidget {
  const ProductManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Products'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.library_books),
            tooltip: 'Ingredients Library',
            onPressed: () => _showIngredientsLibrary(context),
          ),
        ],
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
                    'No products yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add your first product',
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

          final bottomSafe = MediaQuery.of(context).viewPadding.bottom;
          return ListView.builder(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomSafe),
            itemCount: vm.products.length,
            itemBuilder: (context, index) {
              final product = vm.products[index];
              return _ProductCard(
                product: product,
                onTap: () => _showProductEditor(context, vm, product),
                onDelete: () => _confirmDelete(context, vm, product),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProductEditor(
          context,
          context.read<SupplementViewModel>(),
          null,
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
    );
  }

  void _showIngredientsLibrary(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Consumer<SupplementViewModel>(
          builder: (context, vm, _) => Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ingredients Library',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => _addIngredient(context, vm),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: vm.ingredients.length,
                  itemBuilder: (context, index) {
                    final ing = vm.ingredients[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .secondary
                            .withValues(alpha: 0.15),
                        child: Text(
                          ing.name.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ),
                      title: Text(ing.name),
                      subtitle: Text('Default unit: ${ing.defaultUnit}'),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addIngredient(BuildContext context, SupplementViewModel vm) {
    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController();
        final unitController = TextEditingController(text: 'mg');
        
        return AlertDialog(
          title: const Text('Add Ingredient'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'e.g., Vitamin C',
                ),
                textCapitalization: TextCapitalization.words,
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: unitController,
                decoration: const InputDecoration(
                  labelText: 'Default Unit',
                  hintText: 'e.g., mg, mcg, g',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  vm.addIngredient(
                    nameController.text.trim(),
                    unitController.text.trim().isEmpty
                        ? 'mg'
                        : unitController.text.trim(),
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showProductEditor(
    BuildContext context,
    SupplementViewModel vm,
    ProductModel? existing,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ProductEditorScreen(
          product: existing,
          ingredients: vm.ingredients,
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    SupplementViewModel vm,
    ProductModel product,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Delete "${product.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              vm.deleteProduct(product.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ProductCard({
    required this.product,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor:
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                child: Icon(
                  Icons.medication,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
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
              IconButton(
                icon: const Icon(Icons.delete_outline),
                color: Colors.red.withValues(alpha: 0.7),
                onPressed: onDelete,
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-screen editor for product details and composition.
class _ProductEditorScreen extends StatefulWidget {
  final ProductModel? product;
  final List<IngredientModel> ingredients;

  const _ProductEditorScreen({
    this.product,
    required this.ingredients,
  });

  @override
  State<_ProductEditorScreen> createState() => _ProductEditorScreenState();
}

class _ProductEditorScreenState extends State<_ProductEditorScreen> {
  late TextEditingController _nameController;
  late TextEditingController _servingUnitController;
  List<_CompositionEntry> _composition = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _servingUnitController =
        TextEditingController(text: widget.product?.servingUnit ?? 'Serving');
    _loadComposition();
  }

  Future<void> _loadComposition() async {
    if (widget.product != null) {
      final vm = context.read<SupplementViewModel>();
      final existing = await vm.getProductComposition(widget.product!.id);
      setState(() {
        _composition = existing.map((c) {
          final ing = widget.ingredients.firstWhere(
            (i) => i.id == c.ingredientId,
            orElse: () => IngredientModel(
                id: c.ingredientId, name: 'Unknown', defaultUnit: 'mg'),
          );
          return _CompositionEntry(
            ingredient: ing,
            amount: c.amountPerServing,
          );
        }).toList();
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _servingUnitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.product == null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? 'New Product' : 'Edit Product'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).viewPadding.bottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Details
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Product Name',
                      hintText: 'e.g., MultiVitamin',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _servingUnitController,
                    decoration: const InputDecoration(
                      labelText: 'Serving Unit',
                      hintText: 'e.g., Tablet, Capsule, Scoop',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Composition Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Composition',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      TextButton.icon(
                        onPressed: _addIngredientToComposition,
                        icon: const Icon(Icons.add),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                  const Divider(),

                  if (_composition.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      alignment: Alignment.center,
                      child: Text(
                        'No ingredients added yet.\nTap "Add" to include ingredients.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.5),
                            ),
                      ),
                    )
                  else
                    ..._composition.asMap().entries.map((entry) {
                      final index = entry.key;
                      final comp = entry.value;
                      return _CompositionRow(
                        entry: comp,
                        onAmountChanged: (amount) {
                          setState(() {
                            _composition[index] = comp.copyWith(amount: amount);
                          });
                        },
                        onDelete: () {
                          setState(() {
                            _composition.removeAt(index);
                          });
                        },
                      );
                    }),
                ],
              ),
            ),
    );
  }

  void _addIngredientToComposition() {
    // Filter out already-added ingredients
    final available = widget.ingredients
        .where((i) => !_composition.any((c) => c.ingredient.id == i.id))
        .toList();

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All ingredients already added')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Select Ingredient',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: available.length,
                itemBuilder: (context, index) {
                  final ing = available[index];
                  return ListTile(
                    title: Text(ing.name),
                    subtitle: Text(ing.defaultUnit),
                    onTap: () {
                      setState(() {
                        _composition.add(_CompositionEntry(
                          ingredient: ing,
                          amount: 0,
                        ));
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a product name')),
      );
      return;
    }

    final vm = context.read<SupplementViewModel>();
    final servingUnit = _servingUnitController.text.trim().isEmpty
        ? 'Serving'
        : _servingUnitController.text.trim();

    String productId;
    if (widget.product == null) {
      // Create new product
      productId = await vm.addProduct(name, servingUnit: servingUnit);
    } else {
      // Update existing product
      productId = widget.product!.id;
      await vm.updateProduct(
        widget.product!.copyWith(name: name, servingUnit: servingUnit),
      );
    }

    // Save composition
    final compositionModels = _composition
        .where((c) => c.amount > 0)
        .map((c) => ProductCompositionModel(
              productId: productId,
              ingredientId: c.ingredient.id,
              amountPerServing: c.amount,
            ))
        .toList();

    await vm.setProductComposition(productId, compositionModels);

    if (mounted) {
      Navigator.pop(context);
    }
  }
}

class _CompositionEntry {
  final IngredientModel ingredient;
  final double amount;

  const _CompositionEntry({
    required this.ingredient,
    required this.amount,
  });

  _CompositionEntry copyWith({double? amount}) {
    return _CompositionEntry(
      ingredient: ingredient,
      amount: amount ?? this.amount,
    );
  }
}

class _CompositionRow extends StatelessWidget {
  final _CompositionEntry entry;
  final ValueChanged<double> onAmountChanged;
  final VoidCallback onDelete;

  const _CompositionRow({
    required this.entry,
    required this.onAmountChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                entry.ingredient.name,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            Expanded(
              flex: 2,
              child: TextFormField(
                initialValue: entry.amount > 0 ? entry.amount.toString() : '',
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  border: const OutlineInputBorder(),
                  suffixText: entry.ingredient.defaultUnit,
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) {
                  final parsed = double.tryParse(value) ?? 0;
                  onAmountChanged(parsed);
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: onDelete,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}

