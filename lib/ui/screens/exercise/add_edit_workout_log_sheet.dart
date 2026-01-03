import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/exercise_definition_model.dart';
import '../../../data/models/workout_log_model.dart';
import '../../../ui/viewmodels/daily_log_view_model.dart';

class AddEditWorkoutLogSheet extends StatefulWidget {
  const AddEditWorkoutLogSheet({
    super.key,
    this.log,
    this.exerciseDefinition,
  });

  final WorkoutLog? log;
  final ExerciseDefinition? exerciseDefinition;

  @override
  State<AddEditWorkoutLogSheet> createState() => _AddEditWorkoutLogSheetState();
}

class _AddEditWorkoutLogSheetState extends State<AddEditWorkoutLogSheet> {
  final TextEditingController _setsController = TextEditingController();
  final TextEditingController _repsController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _exerciseNameController = TextEditingController();
  bool _isLoadingLastLog = false;
  bool _hasPrefilledWeight = false;

  @override
  void initState() {
    super.initState();
    final exerciseName = widget.log?.exerciseName ?? widget.exerciseDefinition?.name ?? '';
    _exerciseNameController.text = exerciseName;
    
    if (widget.log != null) {
      // Edit Mode: Pre-fill with existing log data
      final log = widget.log!;
      _setsController.text = log.sets.toString();
      _repsController.text = log.reps.toString();
      _weightController.text = log.weight?.toString() ?? '';
      _noteController.text = log.note ?? '';
    } else if (widget.exerciseDefinition != null) {
      // Add Mode: Pre-fill with last log data (Smart Pre-fill)
      // Use post-frame callback to ensure context is available
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _prefillFromLastLog();
      });
    }
  }

  Future<void> _prefillFromLastLog() async {
    if (widget.exerciseDefinition == null || !mounted) return;

    setState(() => _isLoadingLastLog = true);

    final vm = context.read<DailyLogViewModel>();
    final lastLog = await vm.getLastLogDetails(widget.exerciseDefinition!.name);

    if (lastLog != null && mounted) {
      setState(() {
        _setsController.text = lastLog.sets.toString();
        _repsController.text = lastLog.reps.toString();
        if (lastLog.weight != null) {
          _weightController.text = lastLog.weight!.toString();
          _hasPrefilledWeight = true;
        }
        _noteController.text = lastLog.note ?? '';
        _isLoadingLastLog = false;
      });
    } else if (mounted) {
      setState(() => _isLoadingLastLog = false);
    }
  }

  @override
  void dispose() {
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    _noteController.dispose();
    _exerciseNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DailyLogViewModel>();
    final isEditing = widget.log != null;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
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
                  onPressed: () {
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Exercise Name (read-only)
            TextField(
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Exercise Name',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Theme.of(context).disabledColor.withValues(alpha: 0.1),
              ),
              controller: _exerciseNameController,
            ),
            const SizedBox(height: 8),
            // Sets and Reps
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _setsController,
                    decoration: InputDecoration(
                      labelText: 'Sets *',
                      border: const OutlineInputBorder(),
                      suffixText: _isLoadingLastLog ? '...' : null,
                    ),
                    keyboardType: TextInputType.number,
                    enabled: !_isLoadingLastLog,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _repsController,
                    decoration: InputDecoration(
                      labelText: 'Reps *',
                      border: const OutlineInputBorder(),
                      suffixText: _isLoadingLastLog ? '...' : null,
                    ),
                    keyboardType: TextInputType.number,
                    enabled: !_isLoadingLastLog,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Weight
            TextField(
              controller: _weightController,
              decoration: InputDecoration(
                labelText: 'Weight (kg) (Optional)',
                border: const OutlineInputBorder(),
                suffixText: _isLoadingLastLog ? '...' : null,
                helperText: _hasPrefilledWeight && _weightController.text.isNotEmpty && !isEditing
                    ? 'Last: ${_weightController.text}kg'
                    : null,
              ),
              keyboardType: TextInputType.number,
              enabled: !_isLoadingLastLog,
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
              onPressed: _isLoadingLastLog ? null : () => _saveLog(context, vm),
              child: _isLoadingLastLog
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isEditing ? 'Update' : 'Save'),
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

    if (widget.log != null) {
      // Edit Mode: Update existing log
      final updatedLog = widget.log!.copyWith(
        sets: sets,
        reps: reps,
        weight: weight,
        note: note,
      );
      await vm.updateWorkoutLog(updatedLog);
    } else if (widget.exerciseDefinition != null) {
      // Add Mode: Create new log
      // Get max order index (optimized: single loop instead of map+reduce)
      final currentLogs = vm.logs;
      int maxOrderIndex = 0;
      if (currentLogs.isNotEmpty) {
        for (final log in currentLogs) {
          if (log.orderIndex >= maxOrderIndex) {
            maxOrderIndex = log.orderIndex;
          }
        }
        maxOrderIndex += 1;
      }

      final newLog = WorkoutLog(
        id: 0,
        date: vm.selectedDate,
        exerciseName: widget.exerciseDefinition!.name,
        exerciseType: widget.exerciseDefinition!.defaultType,
        sets: sets,
        reps: reps,
        weight: weight,
        note: note,
        orderIndex: maxOrderIndex,
        isCompleted: false,
      );
      await vm.addWorkoutLog(newLog);
    }

    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }
}
