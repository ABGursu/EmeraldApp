import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/tag_model.dart';
import '../../../data/system_tags.dart';
import '../../../ui/viewmodels/balance_view_model.dart';
import '../../../ui/viewmodels/shopping_view_model.dart';
import '../../widgets/color_coded_selector.dart';

/// Sheet for editing a tag (rename, change color, or delete)
class EditTagSheet extends StatefulWidget {
  const EditTagSheet({
    super.key,
    required this.tag,
  });

  final TagModel tag;

  @override
  State<EditTagSheet> createState() => _EditTagSheetState();
}

class _EditTagSheetState extends State<EditTagSheet> {
  late final TextEditingController _nameController;
  late ColorCodedItem _currentItem;
  late bool _showInBalance;
  late bool _showInShopping;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.tag.name);
    _currentItem = ColorCodedItem(
      id: widget.tag.id,
      name: widget.tag.name,
      colorValue: widget.tag.colorValue,
    );
    _showInBalance = widget.tag.showInBalance;
    _showInShopping = widget.tag.showInShopping;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BalanceViewModel>();
    final isSystem = SystemTags.isSystemTag(widget.tag);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isSystem ? 'System tag' : 'Edit Tag',
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
            if (isSystem) ...[
              Text(
                'Default tags stay on Balance and Shopping. Only the color can be changed.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tag Name',
                border: OutlineInputBorder(),
              ),
              readOnly: isSystem,
              autofocus: !isSystem,
              onChanged: isSystem
                  ? null
                  : (value) {
                      setState(() {
                        _currentItem = ColorCodedItem(
                          id: _currentItem.id,
                          name: value,
                          colorValue: _currentItem.colorValue,
                        );
                      });
                    },
            ),
            const SizedBox(height: 16),
            ColorCodedSelectorFormField(
              label: 'Color',
              items: const [], // Not needed for editing
              initialValue: _currentItem,
              onEditItem: (item, name, color) async => item, // Not used
              onDeleteItem: (item) async {}, // Not used
              onChanged: (item) {
                if (item != null) {
                  setState(() {
                    _currentItem = item;
                  });
                }
              },
              validator: (item) => null,
              onCreateNew: (name, color) async => _currentItem, // Not used
            ),
            const SizedBox(height: 8),
            if (!isSystem) ...[
              SwitchListTile(
                title: const Text('Use in Balance Sheet'),
                subtitle: const Text(
                  'Show this tag in Balance filters and when adding transactions',
                ),
                value: _showInBalance,
                onChanged: (v) => setState(() => _showInBalance = v),
              ),
              SwitchListTile(
                title: const Text('Use in Shopping List'),
                subtitle: const Text(
                  'Show this tag in Shopping filters and when adding items',
                ),
                value: _showInShopping,
                onChanged: (v) => setState(() => _showInShopping = v),
              ),
            ] else ...[
              const SwitchListTile(
                title: Text('Use in Balance Sheet'),
                subtitle: Text('Always on for default tags'),
                value: true,
                onChanged: null,
              ),
              const SwitchListTile(
                title: Text('Use in Shopping List'),
                subtitle: Text('Always on for default tags'),
                value: true,
                onChanged: null,
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!isSystem)
                  TextButton(
                    onPressed: () => _showDeleteDialog(context, vm),
                    child: Text(
                      'Delete',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                if (!isSystem) const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => _saveTag(context, vm),
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveTag(BuildContext context, BalanceViewModel vm) async {
    final isSystem = SystemTags.isSystemTag(widget.tag);
    if (!isSystem && _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tag name cannot be empty')),
      );
      return;
    }

    final updatedTag = isSystem
        ? widget.tag.copyWith(
            colorValue: _currentItem.colorValue,
            showInBalance: true,
            showInShopping: true,
          )
        : widget.tag.copyWith(
            name: _nameController.text.trim(),
            colorValue: _currentItem.colorValue,
            showInBalance: _showInBalance,
            showInShopping: _showInShopping,
          );

    await vm.updateTag(updatedTag);
    if (context.mounted) {
      await context.read<ShoppingViewModel>().loadTags();
    }
    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tag "${updatedTag.name}" updated')),
      );
    }
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    BalanceViewModel vm,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tag'),
        content: Text(
          'Are you sure you want to delete "${widget.tag.name}"? '
          'This will remove the tag from all transactions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await vm.deleteTag(widget.tag.id);
      if (context.mounted) {
        await context.read<ShoppingViewModel>().loadTags();
      }
      if (context.mounted) {
        Navigator.of(context).pop(); // Close edit sheet
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tag "${widget.tag.name}" deleted')),
        );
      }
    }
  }
}

