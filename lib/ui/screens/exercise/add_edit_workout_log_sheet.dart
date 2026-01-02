import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/workout_log_model.dart';
import '../../../ui/viewmodels/daily_log_view_model.dart';

class AddEditWorkoutLogSheet extends StatefulWidget {
  const AddEditWorkoutLogSheet({super.key, this.log});

  final WorkoutLog? log;

  @override
  State<AddEditWorkoutLogSheet> createState() => _AddEditWorkoutLogSheetState();
}

class _AddEditWorkoutLogSheetState extends State<AddEditWorkoutLogSheet> {
  final TextEditingController _setsController = TextEditingController();
  final TextEditingController _repsController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.log != null) {
      final log = widget.log!;
      _setsController.text = log.sets.toString();
      _repsController.text = log.reps.toString();
      _weightController.text = log.weight?.toString() ?? '';
      _noteController.text = log.note ?? '';
    }
  }

  @override
  void dispose() {
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DailyLogViewModel>();
    final isEditing = widget.log != null;

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
            // Exercise Name (read-only if editing)
            if (widget.log != null)
              TextField(
                enabled: false,
                decoration: InputDecoration(
                  labelText: 'Exercise Name',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Theme.of(context).disabledColor.withValues(alpha: 0.1),
                ),
                controller: TextEditingController(text: widget.log!.exerciseName),
              ),
            if (widget.log != null) const SizedBox(height: 8),
            // Sets and Reps
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _setsController,
                    decoration: const InputDecoration(
                      labelText: 'Sets *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _repsController,
                    decoration: const InputDecoration(
                      labelText: 'Reps *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Weight
            TextField(
              controller: _weightController,
              decoration: const InputDecoration(
                labelText: 'Weight (kg) (Optional)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            // Note
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            // Save Button
            ElevatedButton(
              onPressed: () => _saveLog(context, vm),
              child: Text(isEditing ? 'Update' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveLog(
    BuildContext context,
    DailyLogViewModel vm,
  ) async {
    if (widget.log == null) {
      Navigator.of(context).pop();
      return;
    }

    final sets = int.tryParse(_setsController.text);
    final reps = int.tryParse(_repsController.text);
    if (sets == null || sets < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Valid sets value is required')),
      );
      return;
    }
    if (reps == null || reps < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Valid reps value is required')),
      );
      return;
    }

    final weight = _weightController.text.isNotEmpty
        ? double.tryParse(_weightController.text)
        : null;

    final note = _noteController.text.isNotEmpty ? _noteController.text : null;

    // Update existing log
    final updatedLog = widget.log!.copyWith(
      sets: sets,
      reps: reps,
      weight: weight,
      note: note,
    );
    await vm.updateWorkoutLog(updatedLog);

    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }
}
