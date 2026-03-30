import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/home_menu_item.dart';
import '../../../ui/viewmodels/home_layout_view_model.dart';
import '../settings/tag_editor_screen.dart';

class HomeLayoutSettingsScreen extends StatelessWidget {
  const HomeLayoutSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Layout Settings'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset to Default',
            onPressed: () => _showResetDialog(context),
          ),
        ],
      ),
      body: Consumer<HomeLayoutViewModel>(
        builder: (context, vm, child) {
          if (!vm.isInitialized) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = vm.menuItems;

          if (items.isEmpty) {
            return const Center(
              child: Text('No menu items available'),
            );
          }

          final bottomInset = MediaQuery.of(context).viewPadding.bottom;

          return SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ReorderableListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    onReorder: (oldIndex, newIndex) {
                      if (newIndex > oldIndex) {
                        newIndex -= 1;
                      }
                      vm.moveItem(oldIndex, newIndex);
                    },
                    children: items.map((item) {
                      return _MenuItemTile(
                        key: ValueKey(item.id),
                        item: item,
                        onToggleVisibility: () => vm.toggleVisibility(item.id),
                      );
                    }).toList(),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
                  child: Card(
                    child: ListTile(
                      leading: Icon(
                        Icons.label_outline,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: const Text('Tag Editor'),
                      subtitle: Text(
                        'Rename, colors, and Balance / Shopping visibility',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.65),
                            ),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const TagEditorScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Default'),
        content: const Text(
          'This will reset the home menu to its default order and make all items visible. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<HomeLayoutViewModel>().resetToDefault();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Home layout reset to default'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

class _MenuItemTile extends StatelessWidget {
  final HomeMenuItem item;
  final VoidCallback onToggleVisibility;

  const _MenuItemTile({
    required this.item,
    required this.onToggleVisibility,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isSettings = item.id == 'settings';

    return Card(
      key: key,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          Icons.drag_handle,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        title: Row(
          children: [
            Icon(
              item.icon,
              color: item.color,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: item.isVisible
                      ? null
                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSettings)
              Icon(
                Icons.lock,
                size: 20,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              )
            else
              Switch(
                value: item.isVisible,
                onChanged: (_) => onToggleVisibility(),
              ),
          ],
        ),
        subtitle: isSettings
            ? Text(
                'Always visible (cannot be hidden)',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              )
            : null,
        // Make the entire tile draggable
        isThreeLine: isSettings,
      ),
    );
  }
}

