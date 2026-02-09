import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/bio_mechanic_view_model.dart';
import '../../../data/models/exercise_definition_model.dart';
import '../../../data/models/exercise_muscle_impact_model.dart';
import '../../../data/models/muscle_model.dart';
import '../../widgets/quick_filter_bar.dart';
import '../../../data/models/exercise_type.dart';

/// Exercise Creation Screen - Bio-Mechanic Lab for creating/editing exercises with muscle impacts.
class ExerciseCreationScreen extends StatelessWidget {
  const ExerciseCreationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise Creation'),
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
              // Body Part Filter (driven by Excel bodyPart values)
              if (vm.bodyParts.isNotEmpty)
                QuickFilterBar<String>(
                  items: vm.bodyParts,
                  selectedItem: vm.selectedBodyPart,
                  onItemSelected: (bodyPart) {
                    vm.setSelectedBodyPart(bodyPart);
                  },
                  getItemId: (bodyPart) => bodyPart,
                  getItemName: (bodyPart) => bodyPart,
                  getItemColor: null,
                ),
              // Exercise List
              Expanded(
                child: _buildExerciseList(context, vm),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateExerciseDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildExerciseList(BuildContext context, BioMechanicViewModel vm) {
    final exercises = vm.filteredExerciseDefinitions;

    if (exercises.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_gymnastics_outlined,
              size: 80,
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
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
                  ? 'Tap + to create your first exercise'
                  : 'Try adjusting your search or filter',
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
          padding: EdgeInsets.fromLTRB(8, 8, 8, 8 + bottomPadding),
          itemCount: exercises.length,
          itemBuilder: (context, index) {
            final exercise = exercises[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
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
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (exercise.defaultType != null &&
                        exercise.defaultType!.isNotEmpty)
                      Text(
                        'Type: ${exercise.defaultType}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (exercise.bodyPart != null &&
                        exercise.bodyPart!.isNotEmpty)
                      Text(
                        'Body Part: ${exercise.bodyPart}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (exercise.grip != null && exercise.grip!.isNotEmpty)
                      Text(
                        'Grip: ${exercise.grip}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (exercise.style != null && exercise.style!.isNotEmpty)
                      Text(
                        'Style: ${exercise.style}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (exercise.types.isNotEmpty)
                      Wrap(
                        spacing: 4,
                        children: exercise.types.map((type) {
                          return Chip(
                            label: Text(
                              type,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            labelStyle: const TextStyle(fontSize: 10),
                            padding: EdgeInsets.zero,
                          );
                        }).toList(),
                      ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () =>
                          _showEditExerciseDialog(context, vm, exercise),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _showDeleteDialog(context, vm, exercise),
                    ),
                  ],
                ),
                onTap: () => _showEditExerciseDialog(context, vm, exercise),
              ),
            );
          },
        );
      },
    );
  }

  void _showCreateExerciseDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const _ExerciseEditScreen(),
      ),
    );
  }

  void _showEditExerciseDialog(
    BuildContext context,
    BioMechanicViewModel vm,
    ExerciseDefinition exercise,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ExerciseEditScreen(exercise: exercise),
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    BioMechanicViewModel vm,
    ExerciseDefinition exercise,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Exercise'),
        content: Text(
          'Are you sure you want to delete "${exercise.name}"?',
          overflow: TextOverflow.ellipsis,
          maxLines: 5,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Store for undo
              final deletedExercise = exercise;
              await vm.deleteExerciseDefinition(exercise.id);
              if (context.mounted) {
                Navigator.pop(context);
                // Show undo snackbar
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Exercise "${deletedExercise.name}" deleted'),
                    action: SnackBarAction(
                      label: 'UNDO',
                      onPressed: () async {
                        await vm.createExerciseDefinition(deletedExercise);
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

class _ExerciseEditScreen extends StatefulWidget {
  const _ExerciseEditScreen({this.exercise});

  final ExerciseDefinition? exercise;

  @override
  State<_ExerciseEditScreen> createState() => _ExerciseEditScreenState();
}

class _ExerciseEditScreenState extends State<_ExerciseEditScreen> {
  late TextEditingController _nameController;
  late TextEditingController _gripController;
  late TextEditingController _styleController;
  List<String> _selectedTypes = [];
  List<ExerciseMuscleImpactModel> _muscleImpacts = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.exercise?.name ?? '',
    );
    _gripController = TextEditingController(
      text: widget.exercise?.grip ?? '',
    );
    _styleController = TextEditingController(
      text: widget.exercise?.style ?? '',
    );
    _selectedTypes = widget.exercise?.types ?? [];
    _loadMuscleImpacts();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _gripController.dispose();
    _styleController.dispose();
    super.dispose();
  }

  Future<void> _loadMuscleImpacts() async {
    if (widget.exercise != null) {
      setState(() => _loading = true);
      final vm = context.read<BioMechanicViewModel>();
      await vm.loadExerciseImpacts(widget.exercise!.id);
      setState(() {
        _muscleImpacts = vm.currentExerciseImpacts;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BioMechanicViewModel>();

    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.exercise == null ? 'Create Exercise' : 'Edit Exercise'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Exercise Name
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Exercise Name',
                      border: OutlineInputBorder(),
                      hintText: 'e.g., Squat, Bench Press',
                    ),
                    textCapitalization: TextCapitalization.words,
                    autofocus: widget.exercise == null,
                  ),
                  const SizedBox(height: 16),
                  // Grip (optional)
                  TextField(
                    controller: _gripController,
                    decoration: const InputDecoration(
                      labelText: 'Grip (optional)',
                      border: OutlineInputBorder(),
                      hintText: 'e.g., Supinated, Neutral, Wide',
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),
                  // Style (optional)
                  TextField(
                    controller: _styleController,
                    decoration: const InputDecoration(
                      labelText: 'Style / Stance (optional)',
                      border: OutlineInputBorder(),
                      hintText: 'e.g., Close stance, Paused, Tempo 3-1-1',
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 24),
                  // Exercise Types
                  Text(
                    'Exercise Types',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ExerciseType.all.map((type) {
                      final isSelected = _selectedTypes.contains(type);
                      return FilterChip(
                        label: Text(
                          type,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedTypes.add(type);
                            } else {
                              _selectedTypes.remove(type);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  // Muscle Impact Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'Muscle Impact (Bio-Mechanic)',
                          style: Theme.of(context).textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Add Muscle'),
                        onPressed: () => _showAddMuscleDialog(context, vm),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_muscleImpacts.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'No muscle impacts defined. Add muscles to track which muscles this exercise targets.',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                        ),
                      ),
                    )
                  else
                    ..._muscleImpacts.map((impact) {
                      final muscle = vm.muscles.firstWhere(
                        (m) => m.id == impact.muscleId,
                        orElse: () => MuscleModel(
                          id: impact.muscleId,
                          name: 'Unknown',
                          groupName: 'Unknown',
                        ),
                      );
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.15),
                            child: Text(
                              '${impact.impactScore}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            muscle.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            muscle.groupName,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                tooltip: 'Edit impact score',
                                onPressed: () => _showEditMuscleImpactDialog(
                                  context,
                                  vm,
                                  impact,
                                  muscle.name,
                                  setState,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _muscleImpacts.removeWhere(
                                      (i) =>
                                          i.muscleId == impact.muscleId &&
                                          i.exerciseId == impact.exerciseId,
                                    );
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _saveExercise(context, vm),
        child: const Icon(Icons.save),
      ),
    );
  }

  void _showEditMuscleImpactDialog(
    BuildContext context,
    BioMechanicViewModel vm,
    ExerciseMuscleImpactModel impact,
    String muscleName,
    void Function(void Function()) updateParentState,
  ) {
    int selectedScore = impact.impactScore;
    final screenWidth = MediaQuery.of(context).size.width;
    final maxW = (screenWidth * 0.9).clamp(280.0, 360.0);

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(
              'Edit impact: $muscleName',
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
            contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            content: SizedBox(
              width: maxW,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Impact Score: $selectedScore',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Slider(
                    value: selectedScore.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: '$selectedScore',
                    onChanged: (value) {
                      setDialogState(() => selectedScore = value.toInt());
                    },
                  ),
                  Text(
                    '1 = Minimal impact, 10 = Primary target',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  updateParentState(() {
                    final idx = _muscleImpacts.indexWhere(
                      (i) =>
                          i.muscleId == impact.muscleId &&
                          i.exerciseId == impact.exerciseId,
                    );
                    if (idx >= 0) {
                      _muscleImpacts[idx] = impact.copyWith(
                        impactScore: selectedScore,
                      );
                    }
                  });
                  Navigator.pop(dialogContext);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddMuscleDialog(BuildContext context, BioMechanicViewModel vm) {
    int? selectedMuscleId;
    int selectedScore = 5;
    final screenWidth = MediaQuery.of(context).size.width;
    final maxW = (screenWidth * 0.9).clamp(280.0, 360.0);

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add Muscle Impact'),
            contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            content: SizedBox(
              width: maxW,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                  maxWidth: maxW,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Muscle Selection
                      DropdownButtonFormField<int>(
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Muscle',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        initialValue: selectedMuscleId,
                        hint: const Text('Select muscle', overflow: TextOverflow.ellipsis),
                        items: vm.muscles.map((muscle) {
                          return DropdownMenuItem<int>(
                            value: muscle.id,
                            child: Text(
                              '${muscle.name} (${muscle.groupName})',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => selectedMuscleId = value);
                        },
                      ),
                    const SizedBox(height: 16),
                    // Impact Score
                    Text(
                      'Impact Score: $selectedScore',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Slider(
                      value: selectedScore.toDouble(),
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: '$selectedScore',
                      onChanged: (value) {
                        setState(() => selectedScore = value.toInt());
                      },
                    ),
                      Text(
                        '1 = Minimal impact, 10 = Primary target',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: selectedMuscleId == null
                    ? null
                    : () {
                        final exerciseId = widget.exercise?.id ?? 0;
                        final impact = ExerciseMuscleImpactModel(
                          exerciseId: exerciseId,
                          muscleId: selectedMuscleId!,
                          impactScore: selectedScore,
                        );
                        setState(() {
                          final existingIndex = _muscleImpacts.indexWhere(
                            (i) => i.muscleId == selectedMuscleId,
                          );
                          if (existingIndex >= 0) {
                            _muscleImpacts[existingIndex] = impact;
                          } else {
                            _muscleImpacts.add(impact);
                          }
                        });
                        Navigator.pop(dialogContext);
                      },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _saveExercise(
      BuildContext context, BioMechanicViewModel vm) async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an exercise name')),
      );
      return;
    }

    final exercise = ExerciseDefinition(
      id: widget.exercise?.id ?? 0,
      name: _nameController.text.trim(),
      defaultType: widget.exercise?.defaultType,
      bodyPart: widget.exercise?.bodyPart,
      grip: _gripController.text.trim().isEmpty
          ? null
          : _gripController.text.trim(),
      style: _styleController.text.trim().isEmpty
          ? null
          : _styleController.text.trim(),
      types: _selectedTypes,
      isArchived: widget.exercise?.isArchived ?? false,
    );

    int exerciseId;
    if (widget.exercise == null) {
      exerciseId = await vm.createExerciseDefinition(exercise);
    } else {
      await vm.updateExerciseDefinition(exercise);
      exerciseId = exercise.id;
    }

    // Save muscle impacts
    if (_muscleImpacts.isNotEmpty) {
      // Update exercise IDs for new exercises
      final updatedImpacts = _muscleImpacts.map((impact) {
        return impact.copyWith(exerciseId: exerciseId);
      }).toList();
      vm.setExerciseImpacts(updatedImpacts);
      await vm.saveExerciseImpacts(exerciseId);
    }

    if (context.mounted) {
      Navigator.pop(context);
    }
  }
}
