import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/bio_mechanic_view_model.dart';
import '../../../data/models/sportif_goal_model.dart';
import '../../../utils/date_formats.dart';
import '../../viewmodels/goal_contribution_entry.dart';

/// Screen for managing Sports Goals (training goals).
class SportifGoalsManagerScreen extends StatelessWidget {
  const SportifGoalsManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sports Goals'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer<BioMechanicViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final goals = vm.activeGoals;

          if (goals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.flag_outlined,
                    size: 80,
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No goals yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create a training goal to get started',
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

          final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

          return ListView.builder(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPadding),
            itemCount: goals.length,
            itemBuilder: (context, index) {
              final goal = goals[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.15),
                    child: Icon(
                      Icons.flag,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  title: Text(
                    goal.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (goal.description != null &&
                          goal.description!.isNotEmpty)
                        Text(
                          goal.description!,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      if (goal.styles.isNotEmpty || goal.types.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            ...goal.styles.map(
                              (s) => Chip(
                                label: Text(
                                  s,
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ),
                            ),
                            ...goal.types.map(
                              (t) => Chip(
                                label: Text(
                                  t,
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.insights),
                        tooltip: 'View daily contributions',
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => SportifGoalDetailScreen(goal: goal),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showEditGoalDialog(context, vm, goal),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _showDeleteDialog(context, vm, goal),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateGoalDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateGoalDialog(BuildContext context) {
    final vm = context.read<BioMechanicViewModel>();
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    // Collect available styles and types from exercise definitions
    final definitions = vm.exerciseDefinitions;
    final availableStyles = definitions
        .map((e) => e.style)
        .whereType<String>()
        .where((s) => s.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final availableTypes = definitions
        .expand((e) => e.types)
        .where((t) => t.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    final selectedStyles = <String>[];
    final selectedTypes = <String>[];

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Create Sports Goal'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Goal Name',
                        border: OutlineInputBorder(),
                        hintText: 'e.g., Capoeira Prep, Marathon Training',
                      ),
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 16),
                    if (availableStyles.isNotEmpty) ...[
                      Text(
                        'Linked Exercise Styles',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: availableStyles.map((style) {
                          final isSelected = selectedStyles.contains(style);
                          return FilterChip(
                            label: Text(
                              style,
                              style: const TextStyle(fontSize: 11),
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  selectedStyles.add(style);
                                } else {
                                  selectedStyles.remove(style);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (availableTypes.isNotEmpty) ...[
                      Text(
                        'Linked Exercise Types',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: availableTypes.map((type) {
                          final isSelected = selectedTypes.contains(type);
                          return FilterChip(
                            label: Text(
                              type,
                              style: const TextStyle(fontSize: 11),
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  selectedTypes.add(type);
                                } else {
                                  selectedTypes.remove(type);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) return;
                    final goal = SportifGoalModel(
                      id: 0, // Will be set by repository
                      name: nameController.text.trim(),
                      description: descriptionController.text.trim().isNotEmpty
                          ? descriptionController.text.trim()
                          : null,
                      isArchived: false,
                      createdAt: DateTime.now(),
                      styles: selectedStyles,
                      types: selectedTypes,
                    );
                    await vm.createGoal(goal);
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditGoalDialog(
    BuildContext context,
    BioMechanicViewModel vm,
    SportifGoalModel goal,
  ) {
    final nameController = TextEditingController(text: goal.name);
    final descriptionController =
        TextEditingController(text: goal.description ?? '');

    // Collect available styles and types from exercise definitions
    final definitions = vm.exerciseDefinitions;
    final availableStyles = definitions
        .map((e) => e.style)
        .whereType<String>()
        .where((s) => s.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final availableTypes = definitions
        .expand((e) => e.types)
        .where((t) => t.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    final selectedStyles = List<String>.from(goal.styles);
    final selectedTypes = List<String>.from(goal.types);

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Sports Goal'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Goal Name',
                        border: OutlineInputBorder(),
                      ),
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 16),
                    if (availableStyles.isNotEmpty) ...[
                      Text(
                        'Linked Exercise Styles',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: availableStyles.map((style) {
                          final isSelected = selectedStyles.contains(style);
                          return FilterChip(
                            label: Text(
                              style,
                              style: const TextStyle(fontSize: 11),
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  selectedStyles.add(style);
                                } else {
                                  selectedStyles.remove(style);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (availableTypes.isNotEmpty) ...[
                      Text(
                        'Linked Exercise Types',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: availableTypes.map((type) {
                          final isSelected = selectedTypes.contains(type);
                          return FilterChip(
                            label: Text(
                              type,
                              style: const TextStyle(fontSize: 11),
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  selectedTypes.add(type);
                                } else {
                                  selectedTypes.remove(type);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) return;
                    final updated = goal.copyWith(
                      name: nameController.text.trim(),
                      description: descriptionController.text.trim().isNotEmpty
                          ? descriptionController.text.trim()
                          : null,
                      styles: selectedStyles,
                      types: selectedTypes,
                    );
                    await vm.updateGoal(updated);
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    BioMechanicViewModel vm,
    SportifGoalModel goal,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Goal'),
          content: Text('Are you sure you want to delete "${goal.name}"?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final deletedGoal = goal;
                await vm.deleteGoal(goal.id);
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Goal "${deletedGoal.name}" deleted'),
                    action: SnackBarAction(
                      label: 'UNDO',
                      onPressed: () async {
                        await vm.createGoal(deletedGoal);
                      },
                    ),
                    duration: const Duration(seconds: 5),
                  ),
                );
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}

class SportifGoalDetailScreen extends StatefulWidget {
  const SportifGoalDetailScreen({super.key, required this.goal});

  final SportifGoalModel goal;

  @override
  State<SportifGoalDetailScreen> createState() =>
      _SportifGoalDetailScreenState();
}

class _SportifGoalDetailScreenState extends State<SportifGoalDetailScreen> {
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _loading = false;
  Map<DateTime, List<GoalContributionEntry>> _contributions = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.goal.name),
      ),
      body: Consumer<BioMechanicViewModel>(
        builder: (context, vm, _) {
          return Column(
            children: [
              _buildDateRangeSelector(context),
              const Divider(height: 1),
              if (widget.goal.styles.isEmpty && widget.goal.types.isEmpty)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'This goal has no linked exercise styles or types yet.\n\nEdit the goal to attach styles/types so we can track which exercises contribute to it.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.7),
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                )
              else if (_fromDate == null || _toDate == null)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Select a date range to see which exercises contributed to this goal.',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                )
              else if (_loading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                Expanded(
                  child: _buildContributionList(context),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDateRangeSelector(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('From'),
              subtitle:
                  Text(_fromDate != null ? formatDate(_fromDate!) : 'Select'),
              onTap: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate:
                      _fromDate ?? now.subtract(const Duration(days: 30)),
                  firstDate: DateTime(2000),
                  lastDate: _toDate ?? now.add(const Duration(days: 365)),
                );
                if (picked != null) {
                  setState(() => _fromDate = picked);
                  if (_toDate != null) {
                    await _loadContributions();
                  }
                }
              },
            ),
          ),
          Expanded(
            child: ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('To'),
              subtitle: Text(_toDate != null ? formatDate(_toDate!) : 'Select'),
              onTap: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _toDate ?? now,
                  firstDate: _fromDate ?? DateTime(2000),
                  lastDate: now.add(const Duration(days: 365)),
                );
                if (picked != null) {
                  setState(() => _toDate = picked);
                  if (_fromDate != null) {
                    await _loadContributions();
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContributionList(BuildContext context) {
    if (_contributions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No contributing exercises found for this goal in the selected period.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final dates = _contributions.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // Newest first
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPadding),
      itemCount: dates.length,
      itemBuilder: (context, index) {
        final date = dates[index];
        final entries = _contributions[date]!;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatDate(date),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                ...entries.map((entry) {
                  final session = entry.session;
                  final title = session.title ?? 'Workout Session';
                  final timeStr = session.startTime != null
                      ? ' at ${formatDateTime(session.startTime!)}'
                      : '';

                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$title$timeStr',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: entry.exercises.map((ex) {
                            final meta = <String>[];
                            if (ex.style != null && ex.style!.isNotEmpty) {
                              meta.add(ex.style!);
                            }
                            if (ex.types.isNotEmpty) {
                              meta.addAll(ex.types);
                            }
                            final subtitle =
                                meta.isNotEmpty ? ' (${meta.join(', ')})' : '';
                            return Chip(
                              label: Text(
                                '${ex.name}$subtitle',
                                style: const TextStyle(fontSize: 11),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadContributions() async {
    if (_fromDate == null || _toDate == null) return;
    final vm = context.read<BioMechanicViewModel>();

    setState(() {
      _loading = true;
    });

    try {
      final data = await vm.getGoalDailyExerciseContributions(
        goal: widget.goal,
        from: _fromDate!,
        to: _toDate!,
      );
      if (!mounted) return;
      setState(() {
        _contributions = data;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _contributions = {};
        _loading = false;
      });
    }
  }
}
