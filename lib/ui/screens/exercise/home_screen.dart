import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/exercise_definition_model.dart';
import '../../../data/models/user_stats_model.dart';
import '../../../data/models/workout_log_model.dart';
import '../../../ui/providers/date_provider.dart';
import '../../../ui/viewmodels/daily_log_view_model.dart';
import '../../../ui/viewmodels/exercise_library_view_model.dart';
import '../../../utils/date_formats.dart';
import 'add_edit_workout_log_sheet.dart';
import 'load_routine_sheet.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DailyLogViewModel>(
      builder: (context, vm, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Daily Log'),
            actions: [
              IconButton(
                icon: const Icon(Icons.upload_file),
                onPressed: () async {
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (range != null && context.mounted) {
                    final path = await vm.exportLogs(
                      from: range.start,
                      to: range.end.add(const Duration(
                          hours: 23, minutes: 59, seconds: 59)),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Exported to $path')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // Header: Date Navigation & User Stats
              _DateHeader(vm: vm),
              const Divider(),
              // Workout Logs List
              Expanded(
                child: vm.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _WorkoutLogsList(logs: vm.logs, vm: vm),
              ),
            ],
          ),
          floatingActionButton: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton(
                heroTag: 'home_load_routine',
                onPressed: () => showModalBottomSheet(
                  context: context,
                  builder: (_) => ChangeNotifierProvider.value(
                    value: context.read<ExerciseLibraryViewModel>(),
                    child: ChangeNotifierProvider.value(
                      value: vm,
                      child: const LoadRoutineSheet(),
                    ),
                  ),
                ),
                tooltip: 'Load Routine',
                child: const Icon(Icons.playlist_play),
              ),
              const SizedBox(height: 8),
              FloatingActionButton(
                heroTag: 'home_add_exercise',
                onPressed: () => _showAddExerciseDialog(context, vm),
                tooltip: 'Add Exercise',
                child: const Icon(Icons.add),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddExerciseDialog(BuildContext context, DailyLogViewModel vm) {
    final libraryVm = context.read<ExerciseLibraryViewModel>();
    showDialog(
      context: context,
      builder: (context) => _ExerciseSelectorDialog(
        definitions: libraryVm.exerciseDefinitions,
        onSelect: (definition) {
          Navigator.of(context).pop();
          // Show the Add/Edit sheet with the selected exercise
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => ChangeNotifierProvider.value(
              value: vm,
              child: AddEditWorkoutLogSheet(exerciseDefinition: definition),
            ),
          );
        },
      ),
    );
  }
}

class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.vm});

  final DailyLogViewModel vm;

  @override
  Widget build(BuildContext context) {
    final dateProvider = context.watch<DateProvider>();
    final date = vm.selectedDate;
    final stats = vm.userStats;
    final isToday = dateProvider.isToday;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Date Navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => vm.goToPreviousDay(),
              ),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    await vm.setSelectedDate(picked);
                  }
                },
                child: Column(
                  children: [
                    Text(
                      formatDate(date),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (isToday)
                      Text(
                        'Today',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: date.isBefore(DateTime.now().add(const Duration(days: 1)))
                    ? () => vm.goToNextDay()
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // User Stats Summary
          if (stats != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (stats.weight != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Chip(
                      label: Text('${stats.weight} kg'),
                      avatar: const Icon(Icons.monitor_weight, size: 16),
                    ),
                  ),
                if (stats.fat != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Chip(
                      label: Text('${stats.fat}% fat'),
                      avatar: const Icon(Icons.percent, size: 16),
                    ),
                  ),
                if (stats.style != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Chip(
                      label: Text(stats.style!),
                      avatar: const Icon(Icons.style, size: 16),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showEditStatsDialog(context, vm),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _showEditStatsDialog(BuildContext context, DailyLogViewModel vm) {
    final stats = vm.userStats ?? UserStats.empty();
    
    showDialog(
      context: context,
      builder: (context) {
        final weightController =
            TextEditingController(text: stats.weight?.toString() ?? '');
        final fatController =
            TextEditingController(text: stats.fat?.toString() ?? '');
        final measurementsController =
            TextEditingController(text: stats.measurements ?? '');
        final styleController = TextEditingController(text: stats.style ?? '');
        
        return AlertDialog(
          title: const Text('Edit User Stats'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: weightController,
                  decoration: const InputDecoration(
                    labelText: 'Weight (kg)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: fatController,
                  decoration: const InputDecoration(
                    labelText: 'Body Fat (%)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: measurementsController,
                  decoration: const InputDecoration(
                    labelText: 'Measurements',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: styleController,
                  decoration: const InputDecoration(
                    labelText: 'Style',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await vm.updateUserStats(
                  weight: weightController.text.isNotEmpty
                      ? double.tryParse(weightController.text)
                      : null,
                  fat: fatController.text.isNotEmpty
                      ? double.tryParse(fatController.text)
                      : null,
                  measurements: measurementsController.text.isNotEmpty
                      ? measurementsController.text
                      : null,
                  style: styleController.text.isNotEmpty
                      ? styleController.text
                      : null,
                );
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}

class _WorkoutLogsList extends StatelessWidget {
  const _WorkoutLogsList({required this.logs, required this.vm});

  final List<WorkoutLog> logs;
  final DailyLogViewModel vm;

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No exercises for this day',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: logs.length,
      onReorder: (oldIndex, newIndex) {
        vm.reorderLogs(oldIndex, newIndex);
      },
      itemBuilder: (context, index) {
        final log = logs[index];
        return _WorkoutLogCard(
          key: ValueKey(log.id),
          log: log,
          vm: vm,
        );
      },
    );
  }
}

class _WorkoutLogCard extends StatelessWidget {
  const _WorkoutLogCard({required this.log, required this.vm, super.key});

  final WorkoutLog log;
  final DailyLogViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Dismissible(
        key: ValueKey(log.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          color: Colors.red,
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        confirmDismiss: (direction) async {
          return await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Exercise'),
                  content: const Text('Are you sure you want to delete this exercise?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ) ??
              false;
        },
        onDismissed: (direction) {
          vm.deleteWorkoutLog(log.id);
        },
        child: ListTile(
          leading: Checkbox(
            value: log.isCompleted,
            onChanged: (value) => vm.toggleWorkoutLogCompletion(log.id),
          ),
          title: Text(
            log.exerciseName,
            style: TextStyle(
              decoration: log.isCompleted ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (log.exerciseType != null) Text('Type: ${log.exerciseType}'),
              Text('${log.sets}x${log.reps}'),
              if (log.weight != null) Text('Weight: ${log.weight} kg'),
              if (log.note != null) Text('Note: ${log.note}'),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => ChangeNotifierProvider.value(
                value: vm,
                child: AddEditWorkoutLogSheet(log: log),
              ),
            ),
          ),
          onTap: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => ChangeNotifierProvider.value(
              value: vm,
              child: AddEditWorkoutLogSheet(log: log),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExerciseSelectorDialog extends StatefulWidget {
  const _ExerciseSelectorDialog({
    required this.definitions,
    required this.onSelect,
  });

  final List<ExerciseDefinition> definitions;
  final Function(ExerciseDefinition) onSelect;

  @override
  State<_ExerciseSelectorDialog> createState() => _ExerciseSelectorDialogState();
}

class _ExerciseSelectorDialogState extends State<_ExerciseSelectorDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<ExerciseDefinition> _filteredDefinitions = [];

  @override
  void initState() {
    super.initState();
    _filteredDefinitions = widget.definitions;
    _searchController.addListener(_filterDefinitions);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterDefinitions);
    _searchController.dispose();
    super.dispose();
  }

  void _filterDefinitions() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredDefinitions = widget.definitions;
      } else {
        _filteredDefinitions = widget.definitions
            .where((def) =>
                def.name.toLowerCase().contains(query) ||
                (def.defaultType != null &&
                    def.defaultType!.toLowerCase().contains(query)))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Exercise'),
      content: SizedBox(
        width: double.maxFinite,
        child: widget.definitions.isEmpty
            ? const Center(
                child: Text('No exercises available. Add some in the Library tab.'))
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search exercises...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: _filteredDefinitions.isEmpty
                        ? Center(
                            child: Text(
                              'No exercises found matching "${_searchController.text}"',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: _filteredDefinitions.length,
                            itemBuilder: (context, index) {
                              final def = _filteredDefinitions[index];
                              return ListTile(
                                title: Text(def.name),
                                subtitle: def.defaultType != null
                                    ? Text('Type: ${def.defaultType}')
                                    : null,
                                onTap: () => widget.onSelect(def),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

