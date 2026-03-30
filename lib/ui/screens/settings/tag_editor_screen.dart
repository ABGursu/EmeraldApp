import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/tag_model.dart';
import '../../../data/system_tags.dart';
import '../../viewmodels/balance_view_model.dart';
import '../../viewmodels/shopping_view_model.dart';
import '../balance/edit_tag_sheet.dart';

/// Lists all tags for quick edits (name, color, Balance/Shopping visibility).
class TagEditorScreen extends StatelessWidget {
  const TagEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tag Editor'),
        centerTitle: true,
      ),
      body: Consumer<BalanceViewModel>(
        builder: (context, balanceVm, _) {
          final tags = List<TagModel>.from(balanceVm.tags)
            ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

          if (tags.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No tags yet. Create tags from Balance Sheet or Shopping List.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            );
          }

          final bottom = MediaQuery.of(context).viewPadding.bottom;
          return ListView.builder(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
            itemCount: tags.length,
            itemBuilder: (context, index) {
              final tag = tags[index];
              final isSystem = SystemTags.isSystemTag(tag);
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color(tag.colorValue),
                    radius: 18,
                  ),
                  title: Text(
                    tag.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    isSystem
                        ? 'System tag · color only · always Balance & Shopping'
                        : '${tag.showInBalance ? "Balance" : "—"} · ${tag.showInShopping ? "Shopping" : "—"}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.65),
                        ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final shoppingVm = context.read<ShoppingViewModel>();
                    await showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => ChangeNotifierProvider.value(
                        value: balanceVm,
                        child: EditTagSheet(tag: tag),
                      ),
                    );
                    await balanceVm.loadTags();
                    await shoppingVm.loadTags();
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
