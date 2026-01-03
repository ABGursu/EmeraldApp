import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../ui/viewmodels/exercise_library_view_model.dart';

class CreateRoutineSheet extends StatefulWidget {
  const CreateRoutineSheet({super.key});

  @override
  State<CreateRoutineSheet> createState() => _CreateRoutineSheetState();
}

class _CreateRoutineSheetState extends State<CreateRoutineSheet> {
  final TextEditingController _nameController = TextEditingController();
  final List<Map<String, dynamic>> _selectedExercises = [];
  final Map<int, TextEditingController> _setsControllers = {};
  final Map<int, TextEditingController> _repsControllers = {};

  @override
  void dispose() {
    _nameController.dispose();
    for (final controller in _setsControllers.values) {
      controller.dispose();
    }
    for (final controller in _repsControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ExerciseLibraryViewModel>();

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Create Routine',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Routine Name *',
                hintText: 'e.g., Push Day A',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            const Text('Select Exercises:'),
            const SizedBox(height: 8),
            Expanded(
              child: vm.exerciseDefinitions.isEmpty
                  ? const Center(
                      child: Text(
                          'No exercises available. Add some in the Library tab.'),
                    )
                  : ListView.builder(
                      itemCount: vm.exerciseDefinitions.length,
                      itemBuilder: (context, index) {
                        final def = vm.exerciseDefinitions[index];
                        final isSelected = _selectedExercises
                            .any((e) => e['exerciseDefinitionId'] == def.id);

                        return CheckboxListTile(
                          title: Text(def.name),
                          subtitle: def.defaultType != null
                              ? Text('Type: ${def.defaultType}')
                              : null,
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedExercises.add({
                                  'exerciseDefinitionId': def.id,
                                  'targetSets': 3,
                                  'targetReps': 10,
                                });
                                _setsControllers[def.id] =
                                    TextEditingController(text: '3');
                                _repsControllers[def.id] =
                                    TextEditingController(text: '10');
                              } else {
                                _selectedExercises.removeWhere(
                                    (e) => e['exerciseDefinitionId'] == def.id);
                                _setsControllers[def.id]?.dispose();
                                _repsControllers[def.id]?.dispose();
                                _setsControllers.remove(def.id);
                                _repsControllers.remove(def.id);
                              }
                            });
                          },
                        );
                      },
                    ),
            ),
            if (_selectedExercises.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Set Target Sets & Reps:'),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: _selectedExercises.length,
                  itemBuilder: (context, index) {
                    final item = _selectedExercises[index];
                    final defId = item['exerciseDefinitionId'] as int;
                    final def =
                        vm.exerciseDefinitions.firstWhere((d) => d.id == defId);

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              def.name,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _setsControllers[defId],
                                    decoration: const InputDecoration(
                                      labelText: 'Sets',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) {
                                      item['targetSets'] =
                                          int.tryParse(value) ?? 3;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _repsControllers[defId],
                                    decoration: const InputDecoration(
                                      labelText: 'Reps',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) {
                                      item['targetReps'] =
                                          int.tryParse(value) ?? 10;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _selectedExercises.isEmpty
                  ? null
                  : () => _saveRoutine(context, vm),
              child: const Text('Create Routine'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveRoutine(
    BuildContext context,
    ExerciseLibraryViewModel vm,
  ) async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Routine name is required')),
      );
      return;
    }

    await vm.saveRoutineWithItems(
      routineName: _nameController.text.trim(),
      items: _selectedExercises,
    );

    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Routine "${_nameController.text.trim()}" created'),
        ),
      );
    }
  }
}
