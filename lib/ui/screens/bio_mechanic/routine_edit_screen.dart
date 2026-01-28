import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/routine_model.dart';
import '../../../data/models/routine_item_model.dart';
import '../../../data/models/exercise_definition_model.dart';
import '../../viewmodels/bio_mechanic_view_model.dart';

/// Routine editor: name and exercise list (target sets/reps).
class RoutineEditScreen extends StatefulWidget {
  final Routine routine;

  const RoutineEditScreen({super.key, required this.routine});

  @override
  State<RoutineEditScreen> createState() => _RoutineEditScreenState();
}

class _RoutineEditScreenState extends State<RoutineEditScreen> {
  late TextEditingController _nameController;
  List<RoutineItem> _items = [];
  bool _loadingItems = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.routine.name);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadingItems) {
      _loadingItems = false;
      _loadItems();
    }
  }

  Future<void> _loadItems() async {
    final vm = context.read<BioMechanicViewModel>();
    final items = await vm.getRoutineItems(widget.routine.id);
    if (mounted) {
      setState(() => _items = items);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Routine'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _maybePop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveName,
          ),
        ],
      ),
      body: Consumer<BioMechanicViewModel>(
        builder: (context, vm, _) {
          if (_loadingItems && _items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Routine name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Exercises',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (_items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No exercises yet. Use the + button below to add.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                    ),
                  )
                else
                  ..._items.map((item) {
                    final exList = vm.exerciseDefinitions
                        .where((e) => e.id == item.exerciseDefinitionId);
                    final name = exList.isEmpty
                        ? 'Exercise #${item.exerciseDefinitionId}'
                        : exList.first.name;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(name),
                        subtitle: Text(
                            '${item.targetSets} set x ${item.targetReps} tekrar'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _deleteItem(vm, item),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddItemDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _saveName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final vm = context.read<BioMechanicViewModel>();
    await vm.updateRoutine(widget.routine.copyWith(name: name));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Routine name saved')),
      );
    }
  }

  void _deleteItem(BioMechanicViewModel vm, RoutineItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove exercise'),
        content: const Text(
          'Remove this exercise from the routine?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await vm.deleteRoutineItem(item.id);
      await _loadItems();
    }
  }

  Future<void> _showAddItemDialog(BuildContext context) async {
    final vm = context.read<BioMechanicViewModel>();
    ExerciseDefinition? chosen;
    final setsController = TextEditingController(text: '3');
    final repsController = TextEditingController(text: '10');

    if (!context.mounted) return;
    chosen = await showDialog<ExerciseDefinition>(
      context: context,
      builder: (ctx) {
        final list = vm.filteredExerciseDefinitions;
        return AlertDialog(
          title: const Text('Select exercise'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: list.length,
              itemBuilder: (_, i) {
                final ex = list[i];
                return ListTile(
                  title: Text(ex.name),
                  onTap: () => Navigator.pop(ctx, ex),
                );
              },
            ),
          ),
        );
      },
    );
    if (chosen == null || !mounted) return;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Target sets / reps'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(chosen!.name),
            const SizedBox(height: 16),
            TextField(
              controller: setsController,
              decoration: const InputDecoration(
                labelText: 'Number of sets',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: repsController,
              decoration: const InputDecoration(
                labelText: 'Target reps',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final sets = int.tryParse(setsController.text) ?? 3;
              final reps = int.tryParse(repsController.text) ?? 10;
              if (sets > 0 && reps > 0) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );

    if (saved == true) {
      final sets = int.tryParse(setsController.text) ?? 3;
      final reps = int.tryParse(repsController.text) ?? 10;
      await vm.createRoutineItem(RoutineItem(
        id: 0,
        routineId: widget.routine.id,
        exerciseDefinitionId: chosen.id,
        targetSets: sets,
        targetReps: reps,
        orderIndex: _items.length,
        note: null,
      ));
      await _loadItems();
    }
  }

  void _maybePop() {
    if (_nameController.text.trim() != widget.routine.name) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Unsaved changes'),
          content: const Text(
            'The routine name has changed. Leave without saving?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('No'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('Yes, leave'),
            ),
          ],
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }
}
