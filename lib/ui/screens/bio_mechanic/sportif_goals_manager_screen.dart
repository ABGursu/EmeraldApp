import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/bio_mechanic_view_model.dart';
import '../../../data/models/sportif_goal_model.dart';

/// Screen for managing Sportif Goals (training goals).
class SportifGoalsManagerScreen extends StatelessWidget {
  const SportifGoalsManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sportif Goals'),
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

          return Builder(
            builder: (context) {
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
                      subtitle: goal.description != null &&
                              goal.description!.isNotEmpty
                          ? Text(
                              goal.description!,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            )
                          : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () =>
                                _showEditGoalDialog(context, vm, goal),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () =>
                                _showDeleteDialog(context, vm, goal),
                          ),
                        ],
                      ),
                    ),
                  );
                },
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Sportif Goal'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              if (nameController.text.trim().isNotEmpty) {
                final goal = SportifGoalModel(
                  id: 0, // Will be set by repository
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim().isNotEmpty
                      ? descriptionController.text.trim()
                      : null,
                  isArchived: false,
                  createdAt: DateTime.now(),
                );
                await vm.createGoal(goal);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Sportif Goal'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              if (nameController.text.trim().isNotEmpty) {
                final updated = goal.copyWith(
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim().isNotEmpty
                      ? descriptionController.text.trim()
                      : null,
                );
                await vm.updateGoal(updated);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    BioMechanicViewModel vm,
    SportifGoalModel goal,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Goal'),
        content: Text('Are you sure you want to delete "${goal.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Store for undo
              final deletedGoal = goal;
              await vm.deleteGoal(goal.id);
              if (context.mounted) {
                Navigator.pop(context);
                // Show undo snackbar
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
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
