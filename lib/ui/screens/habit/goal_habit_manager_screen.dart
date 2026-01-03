import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/life_goal_model.dart';
import '../../../data/models/habit_model.dart';
import '../../../data/models/habit_type.dart';
import '../../viewmodels/habit_view_model.dart';

/// Screen for managing goals and habits.
class GoalHabitManagerScreen extends StatefulWidget {
  const GoalHabitManagerScreen({super.key});

  @override
  State<GoalHabitManagerScreen> createState() => _GoalHabitManagerScreenState();
}

class _GoalHabitManagerScreenState extends State<GoalHabitManagerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Goals & Habits'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.flag), text: 'Goals'),
            Tab(icon: Icon(Icons.repeat), text: 'Habits'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _GoalsTab(),
          _HabitsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            _showGoalDialog(context, null);
          } else {
            _showHabitDialog(context, null);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showGoalDialog(BuildContext context, LifeGoalModel? existing) {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final descController =
        TextEditingController(text: existing?.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? 'New Goal' : 'Edit Goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'e.g., Learn Japanese',
              ),
              textCapitalization: TextCapitalization.sentences,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'Why is this goal important?',
              ),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
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
              if (titleController.text.trim().isEmpty) return;

              final vm = context.read<HabitViewModel>();
              if (existing == null) {
                vm.addGoal(
                  titleController.text.trim(),
                  description: descController.text.trim().isEmpty
                      ? null
                      : descController.text.trim(),
                );
              } else {
                vm.updateGoal(existing.copyWith(
                  title: titleController.text.trim(),
                  description: descController.text.trim().isEmpty
                      ? null
                      : descController.text.trim(),
                ));
              }
              Navigator.pop(context);
            },
            child: Text(existing == null ? 'Create' : 'Save'),
          ),
        ],
      ),
    );
  }

  void _showHabitDialog(BuildContext context, HabitModel? existing) {
    showDialog(
      context: context,
      builder: (context) => _HabitEditDialog(existing: existing),
    );
  }
}

class _GoalsTab extends StatelessWidget {
  const _GoalsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<HabitViewModel>(
      builder: (context, vm, _) {
        if (vm.goals.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.flag_outlined,
                  size: 80,
                  color:
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No goals yet',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap + to add your first goal',
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

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: vm.goals.length,
          itemBuilder: (context, index) {
            final goal = vm.goals[index];
            final habitCount =
                vm.habits.where((h) => h.goalId == goal.id).length;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                  child: Icon(
                    Icons.flag,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                title: Text(
                  goal.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  goal.description ?? '$habitCount habit(s) linked',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showGoalDialog(context, goal);
                    } else if (value == 'delete') {
                      _confirmDeleteGoal(context, vm, goal);
                    }
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showGoalDialog(BuildContext context, LifeGoalModel goal) {
    final titleController = TextEditingController(text: goal.title);
    final descController = TextEditingController(text: goal.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
              ),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
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
              if (titleController.text.trim().isEmpty) return;

              context.read<HabitViewModel>().updateGoal(goal.copyWith(
                    title: titleController.text.trim(),
                    description: descController.text.trim().isEmpty
                        ? null
                        : descController.text.trim(),
                  ));
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteGoal(
    BuildContext context,
    HabitViewModel vm,
    LifeGoalModel goal,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Goal'),
        content: Text(
          'Delete "${goal.title}"?\n\nHabits linked to this goal will be unlinked (not deleted).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              vm.deleteGoal(goal.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _HabitsTab extends StatelessWidget {
  const _HabitsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<HabitViewModel>(
      builder: (context, vm, _) {
        if (vm.habits.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.repeat,
                  size: 80,
                  color:
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No habits yet',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap + to add your first habit',
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

        // Group habits by goal
        final grouped = vm.habitsGroupedByGoal;
        final sortedKeys = grouped.keys.toList()
          ..sort((a, b) {
            if (a == null && b == null) return 0;
            if (a == null) return 1;
            if (b == null) return -1;
            return a.title.compareTo(b.title);
          });

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedKeys.length,
          itemBuilder: (context, index) {
            final goal = sortedKeys[index];
            final habits = grouped[goal]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Goal Header
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        goal != null ? Icons.flag : Icons.help_outline,
                        size: 20,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        goal?.title ?? 'No Goal Assigned',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                      ),
                    ],
                  ),
                ),
                // Habits
                ...habits.map((habit) => _HabitCard(
                      habit: habit,
                      goal: goal,
                    )),
                const SizedBox(height: 8),
              ],
            );
          },
        );
      },
    );
  }
}

class _HabitCard extends StatelessWidget {
  final HabitModel habit;
  final LifeGoalModel? goal;

  const _HabitCard({
    required this.habit,
    this.goal,
  });

  @override
  Widget build(BuildContext context) {
    final isNegative = habit.type == HabitType.negative;
    // Use reddish/orange tint for negative habits, otherwise use habit's color
    final habitColor = isNegative
        ? Colors.orange.shade600
        : Color(habit.colorValue);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: habitColor.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: habitColor.withValues(alpha: 0.2),
          child: Icon(
            isNegative ? Icons.block : Icons.repeat,
            color: habitColor,
          ),
        ),
        title: Row(
          children: [
            if (isNegative) ...[
              Icon(
                Icons.block,
                size: 16,
                color: Colors.orange.shade600,
              ),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: Text(
                habit.title,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'edit') {
              showDialog(
                context: context,
                builder: (context) => _HabitEditDialog(existing: habit),
              );
            } else if (value == 'delete') {
              _confirmDelete(context);
            }
          },
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Habit'),
        content: Text('Delete "${habit.title}"? All logs for this habit will also be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<HabitViewModel>().deleteHabit(habit.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _HabitEditDialog extends StatefulWidget {
  final HabitModel? existing;

  const _HabitEditDialog({this.existing});

  @override
  State<_HabitEditDialog> createState() => _HabitEditDialogState();
}

class _HabitEditDialogState extends State<_HabitEditDialog> {
  late TextEditingController _titleController;
  String? _selectedGoalId;
  int _selectedColor = 0xFF2196F3; // Blue default
  HabitType _selectedType = HabitType.positive;

  final List<int> _colorOptions = [
    0xFF2196F3, // Blue
    0xFF4CAF50, // Green
    0xFFF44336, // Red
    0xFFFF9800, // Orange
    0xFF9C27B0, // Purple
    0xFF00BCD4, // Cyan
    0xFFE91E63, // Pink
    0xFF795548, // Brown
    0xFF607D8B, // Blue Grey
    0xFF009688, // Teal
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existing?.title ?? '');
    _selectedGoalId = widget.existing?.goalId;
    _selectedColor = widget.existing?.colorValue ?? 0xFF2196F3;
    _selectedType = widget.existing?.type ?? HabitType.positive;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HabitViewModel>();
    final isNew = widget.existing == null;

    return AlertDialog(
      title: Text(isNew ? 'New Habit' : 'Edit Habit'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Habit Title',
                hintText: 'e.g., Study Kanji 15 mins',
              ),
              textCapitalization: TextCapitalization.sentences,
              autofocus: isNew,
            ),
            const SizedBox(height: 16),
            // Habit Type Selection
            Text(
              'Habit Type',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            SegmentedButton<HabitType>(
              segments: const [
                ButtonSegment<HabitType>(
                  value: HabitType.positive,
                  label: Text('Build (Positive)'),
                  icon: Icon(Icons.add_circle_outline),
                ),
                ButtonSegment<HabitType>(
                  value: HabitType.negative,
                  label: Text('Quit (Negative)'),
                  icon: Icon(Icons.remove_circle_outline),
                ),
              ],
              selected: {_selectedType},
              onSelectionChanged: (Set<HabitType> selection) {
                setState(() => _selectedType = selection.first);
              },
            ),
            const SizedBox(height: 16),
            // Goal Dropdown
            DropdownButtonFormField<String?>(
              initialValue: _selectedGoalId,
              decoration: const InputDecoration(
                labelText: 'Link to Goal (optional)',
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('No Goal'),
                ),
                ...vm.goals.map((goal) => DropdownMenuItem(
                      value: goal.id,
                      child: Text(goal.title),
                    )),
              ],
              onChanged: (value) {
                setState(() => _selectedGoalId = value);
              },
            ),
            const SizedBox(height: 16),
            // Color Picker
            Text(
              'Color',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _colorOptions.map((color) {
                final isSelected = _selectedColor == color;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Color(color),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Color(color).withValues(alpha: 0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              )
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_titleController.text.trim().isEmpty) return;

            if (widget.existing == null) {
              vm.addHabit(
                _titleController.text.trim(),
                goalId: _selectedGoalId,
                colorValue: _selectedColor,
                type: _selectedType,
              );
            } else {
              vm.updateHabit(widget.existing!.copyWith(
                title: _titleController.text.trim(),
                goalId: _selectedGoalId,
                clearGoalId: _selectedGoalId == null,
                colorValue: _selectedColor,
                type: _selectedType,
              ));
            }
            Navigator.pop(context);
          },
          child: Text(isNew ? 'Create' : 'Save'),
        ),
      ],
    );
  }
}


