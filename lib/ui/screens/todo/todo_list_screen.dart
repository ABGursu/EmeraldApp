import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/todo_item_model.dart';
import '../../../utils/date_formats.dart';
import '../../viewmodels/calendar_view_model.dart';
import '../../viewmodels/todo_view_model.dart';
import 'add_edit_todo_sheet.dart';

class TodoListScreen extends StatelessWidget {
  const TodoListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TodoViewModel>(
      builder: (context, vm, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Todo List'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: vm.isLoading
              ? const Center(child: CircularProgressIndicator())
              : _TodoListContent(vm: vm),
          floatingActionButton: FloatingActionButton(
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => ChangeNotifierProvider.value(
                value: vm,
                child: ChangeNotifierProvider.value(
                  value: context.read<CalendarViewModel>(),
                  child: const AddEditTodoSheet(),
                ),
              ),
            ),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}

class _TodoListContent extends StatelessWidget {
  const _TodoListContent({required this.vm});

  final TodoViewModel vm;

  @override
  Widget build(BuildContext context) {
    final pending = vm.sortedPendingItems;
    final completed = vm.completedItems;

    if (pending.isEmpty && completed.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.checklist_outlined,
              size: 80,
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No todos yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to add your first todo',
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

    return Column(
      children: [
        if (pending.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Pending (${pending.length})',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
          Expanded(
            flex: pending.length > completed.length ? 2 : 1,
            child: ListView.builder(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomSafe),
              itemCount: pending.length,
              itemBuilder: (context, index) {
                return _TodoItemTile(item: pending[index], vm: vm);
              },
            ),
          ),
        ],
        if (completed.isNotEmpty) ...[
          const Divider(height: 1),
          ExpansionTile(
            title: Text(
              'Completed (${completed.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            initiallyExpanded: false,
            children: [
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomSafe),
                itemCount: completed.length,
                itemBuilder: (context, index) {
                  return _TodoItemTile(
                    item: completed[index],
                    vm: vm,
                    isCompleted: true,
                  );
                },
              ),
            ],
          ),
        ],
        SizedBox(height: bottomSafe),
      ],
    );
  }
}

class _TodoItemTile extends StatelessWidget {
  const _TodoItemTile({
    required this.item,
    required this.vm,
    this.isCompleted = false,
  });

  final TodoItemModel item;
  final TodoViewModel vm;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    final calendarVm = context.read<CalendarViewModel>();
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final isOverdue = item.deadline != null &&
        item.deadline!.isBefore(todayStart) &&
        !isCompleted;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isOverdue
            ? BorderSide(
                color: Theme.of(context).colorScheme.error.withValues(alpha: 0.6),
                width: 1.5,
              )
            : BorderSide.none,
      ),
      child: ListTile(
        leading: _buildLeading(context),
        title: Text(
          item.title,
          style: TextStyle(
            decoration: isCompleted ? TextDecoration.lineThrough : null,
            color: isCompleted
                ? Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5)
                : null,
            fontWeight: isOverdue ? FontWeight.bold : null,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.description != null && item.description!.isNotEmpty)
              Text(
                item.description!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            if (item.deadline != null)
              Row(
                children: [
                  Icon(
                    isOverdue ? Icons.warning_amber_rounded : Icons.event,
                    size: 14,
                    color: isOverdue
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      _formatDeadline(item.deadline!, now),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isOverdue
                                ? Theme.of(context).colorScheme.error
                                : null,
                            fontWeight:
                                isOverdue ? FontWeight.w600 : null,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: isCompleted,
              onChanged: (_) =>
                  vm.toggleComplete(item, calendarVm: calendarVm),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20),
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditSheet(context, item, vm);
                } else if (value == 'delete') {
                  _showDeleteConfirmation(context, item, vm, calendarVm);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 18),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        onLongPress: () => _showEditSheet(context, item, vm),
      ),
    );
  }

  Widget _buildLeading(BuildContext context) {
    if (isCompleted) {
      return CircleAvatar(
        backgroundColor: Colors.green.withValues(alpha: 0.2),
        radius: 16,
        child: const Icon(Icons.check, size: 16, color: Colors.green),
      );
    }

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final isOverdue = item.deadline != null && item.deadline!.isBefore(todayStart);

    if (isOverdue) {
      return CircleAvatar(
        backgroundColor:
            Theme.of(context).colorScheme.error.withValues(alpha: 0.2),
        radius: 16,
        child: Icon(Icons.warning_amber_rounded,
            size: 16, color: Theme.of(context).colorScheme.error),
      );
    }

    return CircleAvatar(
      backgroundColor:
          Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
      radius: 16,
      child: Icon(Icons.radio_button_unchecked,
          size: 16, color: Theme.of(context).colorScheme.primary),
    );
  }

  String _formatDeadline(DateTime deadline, DateTime now) {
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));
    final deadlineDate =
        DateTime(deadline.year, deadline.month, deadline.day);

    if (deadlineDate.isAtSameMomentAs(todayStart)) {
      return 'Today ${_timeStr(deadline)}';
    } else if (deadlineDate.isAtSameMomentAs(tomorrowStart)) {
      return 'Tomorrow ${_timeStr(deadline)}';
    } else if (deadline.isBefore(todayStart)) {
      final daysAgo = todayStart.difference(deadlineDate).inDays;
      return 'Overdue by $daysAgo day${daysAgo > 1 ? 's' : ''} (${formatDate(deadline)})';
    } else {
      final daysLeft = deadlineDate.difference(todayStart).inDays;
      return 'In $daysLeft day${daysLeft > 1 ? 's' : ''} (${formatDate(deadline)})';
    }
  }

  String _timeStr(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _showEditSheet(
      BuildContext context, TodoItemModel item, TodoViewModel vm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: vm,
        child: ChangeNotifierProvider.value(
          value: context.read<CalendarViewModel>(),
          child: AddEditTodoSheet(item: item),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    TodoItemModel item,
    TodoViewModel vm,
    CalendarViewModel calendarVm,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Todo'),
        content: Text('Delete "${item.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await vm.deleteItem(item.id, calendarVm: calendarVm);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child:
                const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
