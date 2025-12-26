import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/workout_entry_model.dart';
import '../../../ui/viewmodels/exercise_view_model.dart';
import '../../widgets/color_coded_selector.dart';

class AddEntrySheet extends StatefulWidget {
  const AddEntrySheet({super.key, required this.sessionId, this.entry});

  final String sessionId;
  final WorkoutEntryModel? entry;

  @override
  State<AddEntrySheet> createState() => _AddEntrySheetState();
}

class _AddEntrySheetState extends State<AddEntrySheet> {
  final _formKey = GlobalKey<FormState>();
  final _setsController = TextEditingController(text: '3');
  final _repsController = TextEditingController(text: '10');
  final _weightController = TextEditingController();
  final _noteController = TextEditingController();
  ColorCodedItem? _selectedExercise;

  @override
  void initState() {
    super.initState();
    if (widget.entry != null) {
      final entry = widget.entry!;
      _setsController.text = entry.sets.toString();
      _repsController.text = entry.reps.toString();
      if (entry.weight != null) {
        _weightController.text = entry.weight.toString();
      }
      _noteController.text = entry.note ?? '';
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
    final vm = context.watch<ExerciseViewModel>();
    final items = vm.exercises
        .map((e) => ColorCodedItem(
              id: e.id,
              name: e.name,
              colorValue: e.colorValue,
            ))
        .toList();
    
    // Initialize exercise selection if editing (only once)
    if (widget.entry != null && _selectedExercise == null && items.isNotEmpty) {
      _selectedExercise = items.firstWhere(
        (e) => e.id == widget.entry!.exerciseId,
        orElse: () => const ColorCodedItem(id: '', name: '', colorValue: 0),
      );
    }

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.entry == null ? 'Add Exercise Entry' : 'Edit Exercise Entry',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ColorCodedSelectorFormField(
                  label: 'Exercise Type',
                  items: items,
                  initialValue: _selectedExercise,
                  onChanged: (item) => _selectedExercise = item,
                  validator: (item) => item == null ? 'Select exercise' : null,
                  onCreateNew: (name, color) async {
                    final id = await vm.addExerciseType(name, color);
                    final newItem =
                        ColorCodedItem(id: id, name: name, colorValue: color);
                    _selectedExercise = newItem;
                    return newItem;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _setsController,
                        decoration: const InputDecoration(
                          labelText: 'Sets',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          final value = int.tryParse(v ?? '');
                          if (value == null || value <= 0) {
                            return 'Sets?';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _repsController,
                        decoration: const InputDecoration(
                          labelText: 'Reps',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          final value = int.tryParse(v ?? '');
                          if (value == null || value <= 0) {
                            return 'Reps?';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _weightController,
                  decoration: const InputDecoration(
                    labelText: 'Weight (kg, optional)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('Save Entry'),
                    onPressed: () async {
                      if (_formKey.currentState?.validate() != true) return;
                      final sets = int.parse(_setsController.text);
                      final reps = int.parse(_repsController.text);
                      final weight = double.tryParse(_weightController.text);
                      final exerciseId = _selectedExercise?.id ?? widget.entry?.exerciseId;
                      
                      if (exerciseId == null) return;

                      if (widget.entry != null) {
                        // Update existing entry
                        await vm.updateEntry(
                          widget.entry!.copyWith(
                            exerciseId: exerciseId,
                            sets: sets,
                            reps: reps,
                            weight: weight,
                            note: _noteController.text.trim().isEmpty
                                ? null
                                : _noteController.text.trim(),
                          ),
                        );
                      } else {
                        // Create new entry
                        await vm.addEntry(
                          sessionId: widget.sessionId,
                          exerciseId: exerciseId,
                          sets: sets,
                          reps: reps,
                          weight: weight,
                          note: _noteController.text.trim().isEmpty
                              ? null
                              : _noteController.text.trim(),
                        );
                      }
                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

