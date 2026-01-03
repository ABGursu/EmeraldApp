import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/tag_model.dart';
import '../../../ui/viewmodels/balance_view_model.dart';
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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.tag.name);
    _currentItem = ColorCodedItem(
      id: widget.tag.id,
      name: widget.tag.name,
      colorValue: widget.tag.colorValue,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BalanceViewModel>();

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
                  'Edit Tag',
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
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tag Name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
              onChanged: (value) {
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
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _showDeleteDialog(context, vm),
                  child: Text(
                    'Delete',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
                const SizedBox(width: 8),
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
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tag name cannot be empty')),
      );
      return;
    }

    final updatedTag = widget.tag.copyWith(
      name: _nameController.text.trim(),
      colorValue: _currentItem.colorValue,
    );

    await vm.updateTag(updatedTag);
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
        Navigator.of(context).pop(); // Close edit sheet
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tag "${widget.tag.name}" deleted')),
        );
      }
    }
  }
}

