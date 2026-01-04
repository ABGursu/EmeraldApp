import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/home_menu_item.dart';
import '../../../ui/viewmodels/home_layout_view_model.dart';

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

          return SafeArea(
            child: ReorderableListView(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewPadding.bottom + 16,
              ),
              onReorder: (oldIndex, newIndex) {
                // Adjust index for ReorderableListView
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
              )
            : null,
        // Make the entire tile draggable
        isThreeLine: isSettings,
      ),
    );
  }
}

