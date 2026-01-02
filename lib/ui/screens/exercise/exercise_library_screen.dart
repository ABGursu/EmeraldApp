import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/exercise_definition_model.dart';
import '../../../ui/viewmodels/exercise_library_view_model.dart';
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
                                  onPressed: () => vm.setExerciseSearchQuery(''),
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (value) => vm.setExerciseSearchQuery(value),
                      ),
                    ),
                    // Body Part Filter Chips
                    if (vm.uniqueBodyParts.isNotEmpty)
                      SizedBox(
                        height: 50,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          children: [
                            FilterChip(
                              label: const Text('All'),
                              selected: vm.selectedBodyPart == null,
                              onSelected: (selected) {
                                vm.setSelectedBodyPart(null);
                              },
                            ),
                            const SizedBox(width: 8),
                            ...vm.uniqueBodyParts.map((bodyPart) {
                              final isSelected = vm.selectedBodyPart == bodyPart;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(
                                    bodyPart.split('(').first.trim(),
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    vm.setSelectedBodyPart(
                                      selected ? bodyPart : null,
                                    );
                                  },
                                ),
                              );
                            }),
                          ],
                        ),
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
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    vm.exerciseDefinitions.isEmpty
                                        ? 'Tap + to add your first exercise'
                                        : 'Try adjusting your search or filter',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(8),
                              itemCount: vm.filteredExerciseDefinitions.length,
                              itemBuilder: (context, index) {
                                final definition = vm.filteredExerciseDefinitions[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  child: ListTile(
                                    title: Text(definition.name),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (definition.defaultType != null)
                                          Text('Type: ${definition.defaultType}'),
                                        if (definition.bodyPart != null)
                                          Text('Body Part: ${definition.bodyPart}'),
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
                                            builder: (_) => ChangeNotifierProvider.value(
                                              value: vm,
                                              child: AddEditExerciseDefinitionSheet(
                                                definition: definition,
                                              ),
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
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
                  SnackBar(content: Text('Exercise "${definition.name}" deleted')),
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

