import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/bio_mechanic_view_model.dart';
import '../../../data/models/workout_session_model.dart';
import '../../../data/models/workout_set_model.dart';
import '../../../data/models/exercise_definition_model.dart';
import '../../../utils/date_formats.dart';

/// Daily Logger Screen - Session Manager for workout sessions.
class DailyLoggerScreen extends StatelessWidget {
  const DailyLoggerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Logger'),
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

          return Column(
            children: [
              // Date Selector
              _buildDateSelector(context, vm),
              const Divider(height: 1),
              // Sessions List
              Expanded(
                child: _buildSessionsList(context, vm),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSessionChoice(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDateSelector(BuildContext context, BioMechanicViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () async {
              final newDate = vm.selectedDate.subtract(const Duration(days: 1));
              await vm.setSelectedDate(newDate);
            },
          ),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: vm.selectedDate,
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
                  formatDate(vm.selectedDate),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (vm.selectedDate.year == DateTime.now().year &&
                    vm.selectedDate.month == DateTime.now().month &&
                    vm.selectedDate.day == DateTime.now().day)
                  Text(
                    'Today',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: vm.selectedDate
                    .isBefore(DateTime.now().add(const Duration(days: 1)))
                ? () async {
                    final newDate =
                        vm.selectedDate.add(const Duration(days: 1));
                    await vm.setSelectedDate(newDate);
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsList(BuildContext context, BioMechanicViewModel vm) {
    final sessions = vm.sessions;

    if (sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_outlined,
              size: 80,
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No sessions for this day',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to add a workout session',
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

    return Builder(
      builder: (context) {
        final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
        return ListView.builder(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPadding),
          itemCount: sessions.length,
          itemBuilder: (context, index) {
            final session = sessions[index];
            return _SessionCard(session: session, vm: vm);
          },
        );
      },
    );
  }

  /// Choose between an empty workout or starting from a routine.
  void _showAddSessionChoice(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Empty workout'),
              subtitle:
                  const Text('Create a new session with title and goal tags'),
              onTap: () {
                Navigator.pop(ctx);
                _showAddSessionDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.list_alt),
              title: const Text('Start from routine'),
              subtitle:
                  const Text('Create a session for today from a saved routine'),
              onTap: () {
                Navigator.pop(ctx);
                _showStartFromRoutineDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Select a routine and create a session for the selected day.
  void _showStartFromRoutineDialog(BuildContext context) {
    final vm = context.read<BioMechanicViewModel>();
    final routines = vm.routines;
    if (routines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please create at least one routine first on the Routines screen.',
          ),
        ),
      );
      return;
    }
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Start from routine'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: routines.length,
            itemBuilder: (_, i) {
              final r = routines[i];
              return ListTile(
                title: Text(r.name),
                onTap: () async {
                  Navigator.pop(ctx);
                  try {
                    await vm.createSessionFromRoutine(routineId: r.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Workout created for "${r.name}"'),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showAddSessionDialog(BuildContext context) {
    final vm = context.read<BioMechanicViewModel>();
    final titleController = TextEditingController();
    DateTime? selectedTime;
    List<String> selectedGoalTags = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Workout Session'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Session Title (Optional)',
                    border: OutlineInputBorder(),
                    hintText: 'e.g., Morning Cardio, Leg Day',
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: const Text('Start Time'),
                  subtitle: Text(
                    selectedTime != null
                        ? formatDateTime(selectedTime!)
                        : 'Not set',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (time != null) {
                        setState(() {
                          selectedTime = DateTime(
                            vm.selectedDate.year,
                            vm.selectedDate.month,
                            vm.selectedDate.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(height: 8),
                // Goal Tags Selection
                Text(
                  'Goal Tags',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: vm.goals.map((goal) {
                    final isSelected = selectedGoalTags.contains(goal.name);
                    return FilterChip(
                      label: Text(goal.name),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            selectedGoalTags.add(goal.name);
                          } else {
                            selectedGoalTags.remove(goal.name);
                          }
                        });
                      },
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
              onPressed: () async {
                final session = WorkoutSessionModel(
                  id: 0, // Will be set by repository
                  date: vm.selectedDate,
                  startTime: selectedTime,
                  title: titleController.text.trim().isNotEmpty
                      ? titleController.text.trim()
                      : null,
                  durationMinutes: null,
                  rating: null,
                  goalTags: selectedGoalTags,
                  createdAt: DateTime.now(),
                );
                await vm.createSession(session);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  static void _showEditSessionDialog(
    BuildContext context,
    BioMechanicViewModel vm,
    WorkoutSessionModel session,
  ) {
    final titleController = TextEditingController(text: session.title ?? '');
    DateTime? selectedTime = session.startTime;
    List<String> selectedGoalTags = List.from(session.goalTags);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Workout Session'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Session Title (Optional)',
                    border: OutlineInputBorder(),
                    hintText: 'e.g., Morning Cardio, Leg Day',
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: const Text('Start Time'),
                  subtitle: Text(
                    selectedTime != null
                        ? formatDateTime(selectedTime!)
                        : 'Not set',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: selectedTime != null
                            ? TimeOfDay.fromDateTime(selectedTime!)
                            : TimeOfDay.now(),
                      );
                      if (time != null) {
                        setState(() {
                          selectedTime = DateTime(
                            session.date.year,
                            session.date.month,
                            session.date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Goal Tags',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: vm.goals.map((goal) {
                    final isSelected = selectedGoalTags.contains(goal.name);
                    return FilterChip(
                      label: Text(goal.name),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            selectedGoalTags.add(goal.name);
                          } else {
                            selectedGoalTags.remove(goal.name);
                          }
                        });
                      },
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
              onPressed: () async {
                final updated = session.copyWith(
                  title: titleController.text.trim().isNotEmpty
                      ? titleController.text.trim()
                      : null,
                  startTime: selectedTime,
                  goalTags: selectedGoalTags,
                );
                await vm.updateSession(updated);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  static void _showDeleteSessionDialog(
    BuildContext context,
    BioMechanicViewModel vm,
    WorkoutSessionModel session,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Session'),
        content: Text(
          'Are you sure you want to delete "${session.title ?? 'Workout Session'}"?\n\nAll sets in this session will also be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Store for undo
              final deletedSession = session;
              final sessionDate = session.date;
              await vm.deleteSession(session.id);
              if (context.mounted) {
                Navigator.pop(context);
                // Show undo snackbar
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Session "${deletedSession.title ?? 'Workout Session'}" deleted',
                    ),
                    action: SnackBarAction(
                      label: 'UNDO',
                      onPressed: () async {
                        await vm.createSession(deletedSession);
                        await vm.setSelectedDate(sessionDate);
                      },
                    ),
                    duration: const Duration(seconds: 5),
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.session,
    required this.vm,
  });

  final WorkoutSessionModel session;
  final BioMechanicViewModel vm;

  Color _getRatingColor(int? rating) {
    if (rating == null) return Colors.grey;
    if (rating >= 8) return Colors.green;
    if (rating >= 6) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () async {
          await vm.loadSession(session.id);
          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => _SessionDetailScreen(sessionId: session.id),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      session.title ?? 'Workout Session',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  if (session.rating != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getRatingColor(session.rating),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${session.rating}/10',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  PopupMenuButton(
                    icon: const Icon(Icons.more_vert),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) async {
                      if (value == 'edit') {
                        DailyLoggerScreen._showEditSessionDialog(
                            context, vm, session);
                      } else if (value == 'delete') {
                        DailyLoggerScreen._showDeleteSessionDialog(
                            context, vm, session);
                      }
                    },
                  ),
                ],
              ),
              if (session.startTime != null) ...[
                const SizedBox(height: 4),
                Text(
                  formatDateTime(session.startTime!),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              if (session.goalTags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  children: session.goalTags.map((tag) {
                    return Chip(
                      label: Text(tag),
                      labelStyle: const TextStyle(fontSize: 10),
                      padding: EdgeInsets.zero,
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionDetailScreen extends StatelessWidget {
  const _SessionDetailScreen({required this.sessionId});

  final int sessionId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<BioMechanicViewModel>(
        builder: (context, vm, _) {
          final session = vm.currentSession;
          if (session == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final sets = vm.currentSessionSets;
          if (sets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.fitness_center_outlined,
                    size: 80,
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No exercises in this session',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add exercises and sets to track your workout',
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

          // Group sets by exercise
          final setsByExercise = <int, List<WorkoutSetModel>>{};
          for (final set in sets) {
            setsByExercise.putIfAbsent(set.exerciseId, () => []).add(set);
          }

          return Builder(
            builder: (context) {
              final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
              return ListView.builder(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPadding),
                itemCount: setsByExercise.length,
                itemBuilder: (context, index) {
                  final exerciseId = setsByExercise.keys.elementAt(index);
                  final exerciseSets = setsByExercise[exerciseId]!;
                  exerciseSets
                      .sort((a, b) => a.setNumber.compareTo(b.setNumber));

                  // Get exercise name
                  final exercise = vm.exerciseDefinitions
                      .firstWhere((e) => e.id == exerciseId,
                          orElse: () => ExerciseDefinition(
                                id: exerciseId,
                                name: 'Unknown Exercise',
                              ));

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.15),
                        child: Icon(
                          Icons.fitness_center,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      title: Text(
                        exercise.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text('${exerciseSets.length} set(s)'),
                      children: exerciseSets.map((set) {
                        return ListTile(
                          leading: Text(
                            'Set ${set.setNumber}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          title: Text(
                            '${set.reps} reps',
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (set.weightKg != null)
                                Text(
                                  '${vm.convertWeightForDisplay(set.weightKg!)} ${vm.weightUnitSuffix}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              if (set.rir != null)
                                Text(
                                  'RIR: ${set.rir}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              if (set.formRating != null)
                                Text(
                                  'Form: ${set.formRating}/10',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              if (set.note != null && set.note!.isNotEmpty)
                                Text(
                                  'Note: ${set.note}',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                            ],
                          ),
                          trailing: PopupMenuButton(
                            icon: const Icon(Icons.more_vert),
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 20),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete,
                                        size: 20, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Delete',
                                        style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (value) async {
                              if (value == 'edit') {
                                _showEditSetDialog(context, vm, set);
                              } else if (value == 'delete') {
                                _showDeleteSetDialog(context, vm, set);
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddExerciseDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  static void _showAddExerciseDialog(BuildContext context) {
    final vm = context.read<BioMechanicViewModel>();
    final session = vm.currentSession;
    if (session == null) return;

    int? selectedExerciseId;
    final weightController = TextEditingController();
    final repsController = TextEditingController(text: '10');
    final rirController = TextEditingController();
    final formRatingController = TextEditingController();
    final noteController = TextEditingController();
    final searchController = TextEditingController();
    String searchQuery = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Exercise & Set'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Exercise Selection
                Text(
                  'Select Exercise',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search exercises...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() => searchQuery = value.toLowerCase());
                  },
                ),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: Consumer<BioMechanicViewModel>(
                    builder: (context, vm, _) {
                      final exercises = vm.exerciseDefinitions
                          .where((e) =>
                              searchQuery.isEmpty ||
                              e.name.toLowerCase().contains(searchQuery))
                          .toList();

                      if (exercises.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No exercises found'),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: exercises.length,
                        itemBuilder: (context, index) {
                          final exercise = exercises[index];
                          final isSelected = selectedExerciseId == exercise.id;
                          return ListTile(
                            leading: Icon(
                              isSelected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.outline,
                            ),
                            title: Text(
                              exercise.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: exercise.bodyPart != null
                                ? Text(
                                    exercise.bodyPart!,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : null,
                            selected: isSelected,
                            onTap: () {
                              setState(() => selectedExerciseId = exercise.id);
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                // Set Information
                Text(
                  'Set Information',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: weightController,
                  decoration: InputDecoration(
                    labelText: 'Weight (${vm.weightUnitSuffix})',
                    border: const OutlineInputBorder(),
                    hintText: 'Optional',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: repsController,
                  decoration: const InputDecoration(
                    labelText: 'Reps',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: rirController,
                  decoration: const InputDecoration(
                    labelText: 'RIR (Reps In Reserve, Optional)',
                    border: OutlineInputBorder(),
                    hintText: 'Optional',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: formRatingController,
                  decoration: const InputDecoration(
                    labelText: 'Form Rating (1-10, Optional)',
                    border: OutlineInputBorder(),
                    hintText: 'Optional',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Note (Optional)',
                    border: OutlineInputBorder(),
                    hintText: 'Optional',
                  ),
                  maxLines: 2,
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
              onPressed: selectedExerciseId == null
                  ? null
                  : () async {
                      final weight = weightController.text.trim().isNotEmpty
                          ? double.tryParse(weightController.text.trim())
                          : null;
                      final reps =
                          int.tryParse(repsController.text.trim()) ?? 10;
                      final rir = rirController.text.trim().isNotEmpty
                          ? double.tryParse(rirController.text.trim())
                          : null;
                      final formRating =
                          formRatingController.text.trim().isNotEmpty
                              ? int.tryParse(formRatingController.text.trim())
                              : null;
                      final note = noteController.text.trim().isNotEmpty
                          ? noteController.text.trim()
                          : null;

                      // Get next set number for this exercise
                      final nextSetNumber =
                          vm.getNextSetNumber(selectedExerciseId!);

                      final set = WorkoutSetModel(
                        id: 0, // Will be set by repository
                        sessionId: session.id,
                        exerciseId: selectedExerciseId!,
                        setNumber: nextSetNumber,
                        weightKg: weight != null
                            ? vm.convertWeightForStorage(
                                weight, vm.preferredUnit)
                            : null,
                        reps: reps,
                        rir: rir,
                        formRating: formRating,
                        note: note,
                      );

                      await vm.createSet(set);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Set added to ${vm.exerciseDefinitions.firstWhere((e) => e.id == selectedExerciseId).name}',
                            ),
                          ),
                        );
                      }
                    },
              child: const Text('Add Set'),
            ),
          ],
        ),
      ),
    );
  }

  static void _showEditSetDialog(
    BuildContext context,
    BioMechanicViewModel vm,
    WorkoutSetModel set,
  ) {
    final weightController = TextEditingController(
      text: set.weightKg != null
          ? vm.convertWeightForDisplay(set.weightKg!).toString()
          : '',
    );
    final repsController = TextEditingController(text: set.reps.toString());
    final rirController = TextEditingController(
      text: set.rir != null ? set.rir.toString() : '',
    );
    final formRatingController = TextEditingController(
      text: set.formRating != null ? set.formRating.toString() : '',
    );
    final noteController = TextEditingController(text: set.note ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Set'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: weightController,
                decoration: InputDecoration(
                  labelText: 'Weight (${vm.weightUnitSuffix})',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: repsController,
                decoration: const InputDecoration(
                  labelText: 'Reps',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: rirController,
                decoration: const InputDecoration(
                  labelText: 'RIR (Reps In Reserve, Optional)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: formRatingController,
                decoration: const InputDecoration(
                  labelText: 'Form Rating (1-10, Optional)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'Note (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
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
            onPressed: () async {
              final weight = weightController.text.trim().isNotEmpty
                  ? double.tryParse(weightController.text.trim())
                  : null;
              final reps = int.tryParse(repsController.text.trim()) ?? set.reps;
              final rir = rirController.text.trim().isNotEmpty
                  ? double.tryParse(rirController.text.trim())
                  : null;
              final formRating = formRatingController.text.trim().isNotEmpty
                  ? int.tryParse(formRatingController.text.trim())
                  : null;
              final note = noteController.text.trim().isNotEmpty
                  ? noteController.text.trim()
                  : null;

              final updated = set.copyWith(
                weightKg: weight != null
                    ? vm.convertWeightForStorage(weight, vm.preferredUnit)
                    : set.weightKg,
                reps: reps,
                rir: rir,
                formRating: formRating,
                note: note,
              );
              await vm.updateSet(updated);
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  static void _showDeleteSetDialog(
    BuildContext context,
    BioMechanicViewModel vm,
    WorkoutSetModel set,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Set'),
        content: const Text('Are you sure you want to delete this set?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Store for undo
              final deletedSet = set;
              await vm.deleteSet(set.id);
              if (context.mounted) {
                Navigator.pop(context);
                // Show undo snackbar
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Set deleted'),
                    action: SnackBarAction(
                      label: 'UNDO',
                      onPressed: () async {
                        await vm.createSet(deletedSet);
                      },
                    ),
                    duration: const Duration(seconds: 5),
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
