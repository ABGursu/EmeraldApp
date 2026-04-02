import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/models/tab_inspector_item_model.dart';
import '../../viewmodels/tab_inspector_view_model.dart';
import 'add_tab_item_sheet.dart';

class TabInspectorScreen extends StatelessWidget {
  const TabInspectorScreen({super.key});

  Future<void> _openLink(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid link')),
        );
      }
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open link')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TabInspectorViewModel>(
      builder: (context, vm, _) {
        final open = vm.openItems;
        final done = vm.doneItems;
        final mq = MediaQuery.of(context);
        // Use max so gesture / 3-button nav bar is respected when one of the insets is 0.
        final bottomSafe = math.max(
          mq.padding.bottom,
          mq.viewPadding.bottom,
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text('Tab Inspector'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: vm.isLoading && vm.items.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                            child: Text(
                              'To review (${open.length})',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: open.isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.search,
                                          size: 64,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withValues(alpha: 0.35),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'No tabs to review',
                                          style: Theme.of(context).textTheme.titleMedium,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Tap + to save a link. A preview loads in the background.',
                                          textAlign: TextAlign.center,
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.65),
                                              ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ReorderableListView.builder(
                                    padding: EdgeInsets.fromLTRB(16, 0, 16, 8 + bottomSafe),
                                    itemCount: open.length,
                                    onReorder: vm.reorderOpenItems,
                                    itemBuilder: (context, index) {
                                      final item = open[index];
                                      return _TabCard(
                                        key: ValueKey(item.id),
                                        item: item,
                                        reorderableIndex: index,
                                        onOpen: () => _openLink(context, item.url),
                                        onDoneChanged: (v) => vm.setDone(item.id, v ?? false),
                                        onDelete: () => vm.deleteItem(item.id),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                    if (done.isNotEmpty)
                      SafeArea(
                        top: false,
                        left: false,
                        right: false,
                        child: Material(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.4),
                          child: ExpansionTile(
                            initiallyExpanded: false,
                            title: Text(
                              'Reviewed (${done.length})',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            children: [
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                // Bottom safe inset is applied by SafeArea; keep inner spacing only.
                                padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                                itemCount: done.length,
                                itemBuilder: (context, index) {
                                  final item = done[index];
                                  return _TabCard(
                                    key: ValueKey(item.id),
                                    item: item,
                                    onOpen: () => _openLink(context, item.url),
                                    onDoneChanged: (v) =>
                                        vm.setDone(item.id, v ?? false),
                                    onDelete: () => vm.deleteItem(item.id),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              final result = await showModalBottomSheet<({String title, String url})>(
                context: context,
                isScrollControlled: true,
                builder: (_) => const AddTabItemSheet(),
              );
              if (result == null || !context.mounted) return;
              final ok = await vm.addLink(
                titleInput: result.title,
                urlInput: result.url,
              );
              if (context.mounted && !ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('That does not look like a valid http(s) URL'),
                  ),
                );
              }
            },
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}

class _TabCard extends StatelessWidget {
  const _TabCard({
    super.key,
    required this.item,
    required this.onOpen,
    required this.onDoneChanged,
    required this.onDelete,
    this.reorderableIndex,
  });

  final TabInspectorItem item;
  final VoidCallback onOpen;
  final ValueChanged<bool?> onDoneChanged;
  final VoidCallback onDelete;
  /// When set, shows a drag handle for [ReorderableListView].
  final int? reorderableIndex;

  static const double _thumbW = 88;
  static const double _thumbH = 56;

  @override
  Widget build(BuildContext context) {
    final preview = item.previewImageUrl;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (reorderableIndex != null) ...[
                ReorderableDragStartListener(
                  index: reorderableIndex!,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(
                      Icons.drag_handle,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                ),
              ],
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: _thumbW,
                  height: _thumbH,
                  child: preview != null && preview.isNotEmpty
                      ? InkWell(
                          onTap: onOpen,
                          child: Image.network(
                            preview,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholder(context),
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      : _placeholder(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: onOpen,
                      child: Text(
                        item.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              decoration:
                                  item.isDone ? TextDecoration.lineThrough : null,
                              color: item.isDone
                                  ? Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.5)
                                  : null,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.url,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.55),
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Checkbox(
                value: item.isDone,
                onChanged: onDoneChanged,
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20),
                onSelected: (value) {
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.link,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35),
          size: 28,
        ),
      ),
    );
  }
}
