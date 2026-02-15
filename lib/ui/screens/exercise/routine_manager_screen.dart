import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/routine_model.dart';
import '../../../ui/viewmodels/exercise_library_view_model.dart';
import 'create_routine_sheet.dart';

class RoutineManagerScreen extends StatelessWidget {
  const RoutineManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ExerciseLibraryViewModel>(
      builder: (context, vm, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Routines'),
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
                            hintText: 'Search routines...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: vm.routineSearchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () => vm.setRoutineSearchQuery(''),
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (value) => vm.setRoutineSearchQuery(value),
                      ),
                    ),
                    // Routine List
                    Expanded(
                      child: vm.filteredRoutines.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.playlist_play,
                                    size: 64,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    vm.routines.isEmpty
                                        ? 'No routines yet'
                                        : 'No routines found',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    vm.routines.isEmpty
                                        ? 'Tap + to create your first routine'
                                        : 'Try adjusting your search',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.fromLTRB(8, 8, 8, 8 + MediaQuery.of(context).viewPadding.bottom),
                              itemCount: vm.filteredRoutines.length,
                              itemBuilder: (context, index) {
                                final routine = vm.filteredRoutines[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  child: ListTile(
                                    leading: const Icon(Icons.playlist_play),
                                    title: Text(
                                      routine.name,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                    ),
                                    subtitle: Text(
                                      'Created: ${routine.createdAt.day}.${routine.createdAt.month}.${routine.createdAt.year}',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _showDeleteDialog(
                                        context,
                                        vm,
                                        routine,
                                      ),
                                    ),
                                    onTap: () => _showRoutineDetails(context, vm, routine),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
          floatingActionButton: FloatingActionButton(
            heroTag: 'routines_add_routine',
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => ChangeNotifierProvider.value(
                value: vm,
                child: const CreateRoutineSheet(),
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
    Routine routine,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Routine'),
        content: Text('Are you sure you want to delete "${routine.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await vm.deleteRoutine(routine.id);
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Routine "${routine.name}" deleted')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showRoutineDetails(
    BuildContext context,
    ExerciseLibraryViewModel vm,
    Routine routine,
  ) async {
    final items = await vm.getRoutineItems(routine.id);
    final definitions = vm.exerciseDefinitions;
    final defMap = {for (var def in definitions) def.id: def};

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            routine.name,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: items.isEmpty
                ? const Text('No exercises in this routine')
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final def = defMap[item.exerciseDefinitionId];
                      return ListTile(
                        leading: Text('${index + 1}.'),
                        title: Text(
                          def?.name ?? 'Unknown',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                        subtitle: Text(
                          '${item.targetSets}x${item.targetReps}',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }
}

