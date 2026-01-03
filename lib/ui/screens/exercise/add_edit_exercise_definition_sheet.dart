import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/exercise_definition_model.dart';
import '../../../ui/viewmodels/exercise_library_view_model.dart';

class AddEditExerciseDefinitionSheet extends StatefulWidget {
  const AddEditExerciseDefinitionSheet({super.key, this.definition});

  final ExerciseDefinition? definition;

  @override
  State<AddEditExerciseDefinitionSheet> createState() =>
      _AddEditExerciseDefinitionSheetState();
}

class _AddEditExerciseDefinitionSheetState
    extends State<AddEditExerciseDefinitionSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  Set<String> _selectedBodyParts = {};

  @override
  void initState() {
    super.initState();
    if (widget.definition != null) {
      final def = widget.definition!;
      _nameController.text = def.name;
      _typeController.text = def.defaultType ?? '';
      // Parse comma-separated body parts
      if (def.bodyPart != null && def.bodyPart!.isNotEmpty) {
        _selectedBodyParts = def.bodyPart!.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toSet();
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ExerciseLibraryViewModel>();
    final isEditing = widget.definition != null;

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
                  isEditing ? 'Edit Exercise' : 'Add Exercise',
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
                labelText: 'Exercise Name *',
                hintText: 'e.g., Squat, Bench Press',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _typeController,
              decoration: const InputDecoration(
                labelText: 'Default Type (Optional)',
                hintText: 'e.g., Dumbbell, Cable, BW',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            _buildBodyPartSelector(vm),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _saveDefinition(context, vm),
              child: Text(isEditing ? 'Update' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveDefinition(
    BuildContext context,
    ExerciseLibraryViewModel vm,
  ) async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exercise name is required')),
      );
      return;
    }

    final type = _typeController.text.trim().isEmpty
        ? null
        : _typeController.text.trim();
    final bodyPart = _selectedBodyParts.isEmpty
        ? null
        : _selectedBodyParts.join(',');

    if (widget.definition != null) {
      // Update existing
      final updated = widget.definition!.copyWith(
        defaultType: type,
        bodyPart: bodyPart,
      );
      await vm.updateExerciseDefinition(updated);
    } else {
      // Create new
      await vm.addExerciseDefinition(
        name: _nameController.text.trim(),
        defaultType: type,
        bodyPart: bodyPart,
      );
    }

    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  Widget _buildBodyPartSelector(ExerciseLibraryViewModel vm) {
    // Get all unique body parts from existing exercises
    final allBodyParts = <String>{};
    for (final def in vm.exerciseDefinitions) {
      if (def.bodyPart != null && def.bodyPart!.isNotEmpty) {
        // Split comma-separated values
        final parts = def.bodyPart!.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty);
        allBodyParts.addAll(parts);
      }
    }
    final sortedBodyParts = allBodyParts.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Body Parts (Optional) - Select multiple for compound exercises',
                style: Theme.of(context).textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              iconSize: 20,
              tooltip: 'Add new body part',
              onPressed: () => _showAddBodyPartDialog(context, sortedBodyParts),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(maxHeight: 200),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: sortedBodyParts.length,
            itemBuilder: (context, index) {
              final bodyPart = sortedBodyParts[index];
              final isSelected = _selectedBodyParts.contains(bodyPart);
              return ListTile(
                dense: true,
                leading: Checkbox(
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedBodyParts.add(bodyPart);
                      } else {
                        _selectedBodyParts.remove(bodyPart);
                      }
                    });
                  },
                ),
                title: Text(bodyPart),
                trailing: IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: () => _showEditBodyPartDialog(context, bodyPart, sortedBodyParts),
                ),
              );
            },
          ),
        ),
        if (_selectedBodyParts.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _selectedBodyParts.map((part) {
              return Chip(
                label: Text(part),
                onDeleted: () {
                  setState(() {
                    _selectedBodyParts.remove(part);
                  });
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Future<void> _showAddBodyPartDialog(BuildContext context, List<String> existingBodyParts) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Add New Body Part'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Body Part Name',
              hintText: 'e.g., Quadriceps, Glutes',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
            textCapitalization: TextCapitalization.words,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  Navigator.pop(context, name);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _selectedBodyParts.add(result);
      });
    }
  }

  Future<void> _showEditBodyPartDialog(
    BuildContext context,
    String oldBodyPart,
    List<String> existingBodyParts,
  ) async {
    // Get ViewModel before async gap
    final vm = context.read<ExerciseLibraryViewModel>();
    
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: oldBodyPart);
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
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty && name != oldBodyPart) {
                  Navigator.pop(context, {'old': oldBodyPart, 'new': name});
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

    if (result != null && mounted) {
      final oldName = result['old']!;
      final newName = result['new']!;
      
      // Update all exercises that use this body part
      await _updateBodyPartInAllExercises(vm, oldName, newName);
      
      if (mounted) {
        setState(() {
          if (_selectedBodyParts.contains(oldName)) {
            _selectedBodyParts.remove(oldName);
            _selectedBodyParts.add(newName);
          }
        });
      }
    }
  }

  Future<void> _updateBodyPartInAllExercises(
    ExerciseLibraryViewModel vm,
    String oldBodyPart,
    String newBodyPart,
  ) async {
    for (final def in vm.exerciseDefinitions) {
      if (def.bodyPart != null && def.bodyPart!.contains(oldBodyPart)) {
        final parts = def.bodyPart!.split(',').map((s) => s.trim()).toList();
        final updatedParts = parts.map((p) => p == oldBodyPart ? newBodyPart : p).toList();
        final updatedBodyPart = updatedParts.join(',');
        
        final updated = def.copyWith(bodyPart: updatedBodyPart);
        await vm.updateExerciseDefinition(updated);
      }
    }
  }
}

