import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/exercise_definition_model.dart';
import '../../../ui/viewmodels/exercise_library_view_model.dart';
import '../../widgets/quick_filter_bar.dart';
import 'add_edit_exercise_definition_sheet.dart';

class ExerciseLibraryScreen extends StatelessWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ExerciseLibraryViewModel>(
      builder: (context, vm, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Exercise Library'),
          ),
          body: vm.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search exercises...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: vm.exerciseSearchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () =>
                                      vm.setExerciseSearchQuery(''),
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (value) => vm.setExerciseSearchQuery(value),
                      ),
                    ),
                    // Body Part Filter Bar
                    if (vm.uniqueBodyParts.isNotEmpty)
                      QuickFilterBar<String>(
                        items: vm.uniqueBodyParts,
                        selectedItem: vm.selectedBodyPart,
                        onItemSelected: (bodyPart) {
                          vm.setSelectedBodyPart(bodyPart);
                        },
                        onItemLongPress: (bodyPart) {
                          _showEditBodyPartDialog(context, bodyPart, vm);
                        },
                        getItemId: (bodyPart) => bodyPart,
                        getItemName: (bodyPart) =>
                            bodyPart.split('(').first.trim(),
                        getItemColor: null, // Body parts don't have colors
                      ),
                    // Exercise List
                    Expanded(
                      child: vm.filteredExerciseDefinitions.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.fitness_center,
                                    size: 64,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    vm.exerciseDefinitions.isEmpty
                                        ? 'No exercises yet'
                                        : 'No exercises found',
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    vm.exerciseDefinitions.isEmpty
                                        ? 'Tap + to add your first exercise'
                                        : 'Try adjusting your search or filter',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(8),
                              itemCount: vm.filteredExerciseDefinitions.length,
                              itemBuilder: (context, index) {
                                final definition =
                                    vm.filteredExerciseDefinitions[index];
                                return Card(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: ListTile(
                                    title: Text(definition.name),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (definition.defaultType != null)
                                          Text(
                                              'Type: ${definition.defaultType}'),
                                        if (definition.bodyPart != null)
                                          Text(
                                              'Body Part: ${definition.bodyPart}'),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit),
                                          onPressed: () => showModalBottomSheet(
                                            context: context,
                                            isScrollControlled: true,
                                            builder: (_) =>
                                                ChangeNotifierProvider.value(
                                              value: vm,
                                              child:
                                                  AddEditExerciseDefinitionSheet(
                                                definition: definition,
                                              ),
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: Colors.red),
                                          onPressed: () => _showDeleteDialog(
                                            context,
                                            vm,
                                            definition,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
          floatingActionButton: FloatingActionButton(
            heroTag: 'library_add_exercise',
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => ChangeNotifierProvider.value(
                value: vm,
                child: const AddEditExerciseDefinitionSheet(),
              ),
            ),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    ExerciseLibraryViewModel vm,
    ExerciseDefinition definition,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Exercise'),
        content: Text('Are you sure you want to delete "${definition.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await vm.deleteExerciseDefinition(definition.id);
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Exercise "${definition.name}" deleted')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  static Future<void> _showEditBodyPartDialog(
    BuildContext context,
    String bodyPart,
    ExerciseLibraryViewModel vm,
  ) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: bodyPart);
        return AlertDialog(
          title: const Text('Edit Body Part'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Body Part Name',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
            textCapitalization: TextCapitalization.words,
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (!context.mounted) return;
                final newName = controller.text.trim();
                if (newName.isNotEmpty && newName != bodyPart) {
                  Navigator.pop(context, {'old': bodyPart, 'new': newName});
                } else {
                  Navigator.pop(context);
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      final oldName = result['old']!;
      final newName = result['new']!;

      // Update all exercises that use this body part
      await _updateBodyPartInAllExercises(vm, oldName, newName);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Body part "$oldName" updated to "$newName" in all exercises')),
        );
      }
    }
  }

  static Future<void> _updateBodyPartInAllExercises(
    ExerciseLibraryViewModel vm,
    String oldBodyPart,
    String newBodyPart,
  ) async {
    for (final def in vm.exerciseDefinitions) {
      if (def.bodyPart != null && def.bodyPart!.contains(oldBodyPart)) {
        final parts = def.bodyPart!.split(',').map((s) => s.trim()).toList();
        final updatedParts =
            parts.map((p) => p == oldBodyPart ? newBodyPart : p).toList();
        final updatedBodyPart = updatedParts.join(',');

        final updated = def.copyWith(bodyPart: updatedBodyPart);
        await vm.updateExerciseDefinition(updated);
      }
    }
  }
}
