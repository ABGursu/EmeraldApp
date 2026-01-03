import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../ui/viewmodels/shopping_view_model.dart';

class ShoppingSettingsSheet extends StatelessWidget {
  const ShoppingSettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ShoppingViewModel>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Shopping Settings',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text('Automatically delete associated expense?'),
              subtitle: const Text(
                'When enabled, deleting a shopping item will automatically '
                'delete its linked expense record without asking.',
              ),
              value: vm.autoDeleteExpense,
              onChanged: (value) => vm.setAutoDeleteExpense(value),
            ),
            const SizedBox(height: 16),
            Text(
              'When disabled (default), you will be asked to confirm '
              'whether to delete the associated expense record.',
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
    );
  }
}

