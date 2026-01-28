import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/routine_model.dart';
import '../../viewmodels/bio_mechanic_view_model.dart';
import 'daily_logger_screen.dart';
import 'routine_edit_screen.dart';

/// Routines list: shows routines, creates new ones, edit/delete and "Start from routine".
class RoutinesListScreen extends StatelessWidget {
  const RoutinesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Routines'),
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
          final routines = vm.routines;
          if (routines.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.list_alt,
                    size: 64,
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No routines yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Use the + button below to create a routine',
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: routines.length,
            itemBuilder: (context, index) {
              final routine = routines[index];
              return _RoutineTile(
                routine: routine,
                onTap: () => _openRoutineEdit(context, routine),
                onStartFromRoutine: () =>
                    _startFromRoutine(context, vm, routine),
                onDelete: () => _confirmDeleteRoutine(context, vm, routine),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewRoutineDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _openRoutineEdit(BuildContext context, Routine routine) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RoutineEditScreen(routine: routine),
      ),
    );
  }

  Future<void> _startFromRoutine(
    BuildContext context,
    BioMechanicViewModel vm,
    Routine routine,
  ) async {
    try {
      await vm.createSessionFromRoutine(
        routineId: routine.id,
        date: DateTime.now(),
      );
      if (context.mounted) {
        Navigator.of(context).pop(); // back from RoutinesList
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const DailyLoggerScreen(),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  void _confirmDeleteRoutine(
    BuildContext context,
    BioMechanicViewModel vm,
    Routine routine,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete routine'),
        content: Text('Delete "${routine.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await vm.deleteRoutine(routine.id);
              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showNewRoutineDialog(BuildContext context) {
    final vm = context.read<BioMechanicViewModel>();
    final nameController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New routine'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Routine name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              final id = await vm.createRoutine(Routine(
                id: 0,
                name: name,
                createdAt: DateTime.now(),
              ));
              if (context.mounted) {
                Navigator.pop(ctx);
                final created = await vm.getRoutineById(id);
                if (created != null && context.mounted) {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => RoutineEditScreen(routine: created),
                    ),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _RoutineTile extends StatelessWidget {
  final Routine routine;
  final VoidCallback onTap;
  final VoidCallback onStartFromRoutine;
  final VoidCallback onDelete;

  const _RoutineTile({
    required this.routine,
    required this.onTap,
    required this.onStartFromRoutine,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(routine.name),
        subtitle: const Text('Tap to edit'),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') onTap();
            if (value == 'start') onStartFromRoutine();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(
                value: 'start', child: Text('Start from routine')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
