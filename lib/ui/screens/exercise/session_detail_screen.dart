import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/workout_entry_model.dart';
import '../../../data/models/workout_session_model.dart';
import '../../../ui/viewmodels/exercise_view_model.dart';
import '../../../utils/date_formats.dart';
import 'add_entry_sheet.dart';

class SessionDetailScreen extends StatelessWidget {
  const SessionDetailScreen({super.key, required this.session});

  final WorkoutSessionModel session;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ExerciseViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Session'),
      ),
      body: FutureBuilder<List<WorkoutEntryModel>>(
        future: vm.fetchEntries(session.id),
        builder: (context, snapshot) {
          final entries = snapshot.data ?? [];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatDateTime(session.date),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (session.userWeight != null)
                        Text('Weight: ${session.userWeight} kg'),
                      if (session.userFat != null)
                        Text('Body Fat: ${session.userFat}%'),
                      if (session.measurements != null)
                        Text('Measurements: ${session.measurements}'),
                      if (session.note != null) Text('Note: ${session.note}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Entries',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (entries.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('No entries yet'),
                )
              else
                ...entries.map((e) => _EntryTile(
                      entry: e,
                      vm: vm,
                      sessionId: session.id,
                    )),
            ],
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'add_routine',
            onPressed: () => _showRoutineSelector(context, vm, session.id),
            tooltip: 'Add Routine',
            child: const Icon(Icons.playlist_add),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'add_entry',
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => ChangeNotifierProvider.value(
                value: vm,
                child: AddEntrySheet(sessionId: session.id),
              ),
            ),
            tooltip: 'Add Exercise',
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  void _showRoutineSelector(
    BuildContext context,
    ExerciseViewModel vm,
    String sessionId,
  ) {
    if (vm.routines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No routines available. Create one first!'),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Routine',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: vm.routines.length,
                itemBuilder: (context, index) {
                  final routine = vm.routines[index];
                  return ListTile(
                    leading: const Icon(Icons.playlist_play),
                    title: Text(routine.name),
                    onTap: () async {
                      Navigator.of(context).pop();
                      await vm.addRoutineToSession(routine.id, sessionId);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Added "${routine.name}" to session'),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({
    required this.entry,
    required this.vm,
    required this.sessionId,
  });
  final WorkoutEntryModel entry;
  final ExerciseViewModel vm;
  final String sessionId;

  @override
  Widget build(BuildContext context) {
    final exercise = vm.getExerciseById(entry.exerciseId);
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color(exercise?.colorValue ?? 0xFF9E9E9E),
        ),
        title: Text(exercise?.name ?? 'Unknown'),
        subtitle: Text(entry.note ?? ''),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${entry.sets}x${entry.reps}'),
                if (entry.weight != null) Text('${entry.weight} kg'),
              ],
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _editEntry(context, vm, entry);
                } else if (value == 'delete') {
                  _deleteEntry(context, vm, entry);
                }
              },
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
            ),
          ],
        ),
      ),
    );
  }

  void _editEntry(
    BuildContext context,
    ExerciseViewModel vm,
    WorkoutEntryModel entry,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: vm,
        child: AddEntrySheet(sessionId: sessionId, entry: entry),
      ),
    );
  }

  void _deleteEntry(
    BuildContext context,
    ExerciseViewModel vm,
    WorkoutEntryModel entry,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text('Are you sure you want to delete this exercise entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await vm.deleteEntry(entry.id, sessionId);
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

