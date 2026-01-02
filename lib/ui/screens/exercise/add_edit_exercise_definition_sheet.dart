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
  final TextEditingController _bodyPartController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.definition != null) {
      final def = widget.definition!;
      _nameController.text = def.name;
      _typeController.text = def.defaultType ?? '';
      _bodyPartController.text = def.bodyPart ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _bodyPartController.dispose();
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
              enabled: !isEditing, // Name cannot be changed when editing
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
            TextField(
              controller: _bodyPartController,
              decoration: const InputDecoration(
                labelText: 'Body Part (Optional)',
                hintText: 'e.g., Chest, Legs, Back',
                border: OutlineInputBorder(),
              ),
            ),
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
    final bodyPart = _bodyPartController.text.trim().isEmpty
        ? null
        : _bodyPartController.text.trim();

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
}

