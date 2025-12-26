import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/routine_item_model.dart';
import '../../../data/models/routine_model.dart';
import '../../../ui/viewmodels/exercise_view_model.dart';
import '../../widgets/color_coded_selector.dart';

class CreateRoutineSheet extends StatefulWidget {
  const CreateRoutineSheet({super.key, this.routine});

  final RoutineModel? routine;

  @override
  State<CreateRoutineSheet> createState() => _CreateRoutineSheetState();
}

class _CreateRoutineSheetState extends State<CreateRoutineSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _saving = false;
  List<RoutineItemModel> _items = [];
  bool _loadingItems = false;

  @override
  void initState() {
    super.initState();
    if (widget.routine != null) {
      _nameController.text = widget.routine!.name;
      _loadItems();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    if (widget.routine == null) return;
    setState(() => _loadingItems = true);
    final vm = context.read<ExerciseViewModel>();
    final items = await vm.fetchRoutineItems(widget.routine!.id);
    setState(() {
      _items = items;
      _loadingItems = false;
    });
  }

  Future<void> _addItem() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<ExerciseViewModel>(),
        child: _AddRoutineItemSheet(),
      ),
    );

    if (!mounted) return;

    if (result != null && widget.routine != null) {
      final vm = context.read<ExerciseViewModel>();
      await vm.addRoutineItem(
        routineId: widget.routine!.id,
        exerciseId: result['exerciseId'] as String,
        sets: result['sets'] as int,
        reps: result['reps'] as int,
        weight: result['weight'] as double?,
        note: result['note'] as String?,
      );
      await _loadItems();
    } else if (result != null) {
      setState(() {
        _items.add(RoutineItemModel(
          id: '',
          routineId: '',
          exerciseId: result['exerciseId'] as String,
          sets: result['sets'] as int,
          reps: result['reps'] as int,
          weight: result['weight'] as double?,
          note: result['note'] as String?,
        ));
      });
    }
  }

  Future<void> _deleteItem(RoutineItemModel item, int index) async {
    if (widget.routine != null && item.id.isNotEmpty) {
      final vm = context.read<ExerciseViewModel>();
      await vm.deleteRoutineItem(item.id, widget.routine!.id);
      await _loadItems();
    } else {
      setState(() {
        _items.removeAt(index);
      });
    }
  }

  Future<void> _save() async {
    if (_formKey.currentState?.validate() != true) return;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one exercise to the routine')),
      );
      return;
    }

    setState(() => _saving = true);
    final vm = context.read<ExerciseViewModel>();

    try {
      if (widget.routine != null) {
        // Update existing routine
        await vm.updateRoutine(
          widget.routine!.copyWith(name: _nameController.text.trim()),
        );
      } else {
        // Create new routine
        final routineId = await vm.addRoutine(_nameController.text.trim());
        // Add all items
        for (final item in _items) {
          await vm.addRoutineItem(
            routineId: routineId,
            exerciseId: item.exerciseId,
            sets: item.sets,
            reps: item.reps,
            weight: item.weight,
            note: item.note,
          );
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ExerciseViewModel>();

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
                      widget.routine == null ? 'Create Routine' : 'Edit Routine',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Routine Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v?.trim().isEmpty ?? true ? 'Enter routine name' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Exercises',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add Exercise'),
                      onPressed: _addItem,
                    ),
                  ],
                ),
                if (_loadingItems)
                  const Center(child: CircularProgressIndicator())
                else if (_items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: Text('No exercises added yet')),
                  )
                else
                  ..._items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final exercise = vm.getExerciseById(item.exerciseId);
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Color(exercise?.colorValue ?? 0xFF9E9E9E),
                        ),
                        title: Text(exercise?.name ?? 'Unknown'),
                        subtitle: Text(
                          '${item.sets}x${item.reps}${item.weight != null ? ' @ ${item.weight}kg' : ''}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteItem(item, index),
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: _saving
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(_saving ? 'Saving...' : 'Save Routine'),
                    onPressed: _saving ? null : _save,
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

class _AddRoutineItemSheet extends StatefulWidget {
  @override
  State<_AddRoutineItemSheet> createState() => _AddRoutineItemSheetState();
}

class _AddRoutineItemSheetState extends State<_AddRoutineItemSheet> {
  final _formKey = GlobalKey<FormState>();
  final _setsController = TextEditingController(text: '3');
  final _repsController = TextEditingController(text: '10');
  final _weightController = TextEditingController();
  final _noteController = TextEditingController();
  ColorCodedItem? _selectedExercise;

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
                      'Add Exercise to Routine',
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
                    label: const Text('Add'),
                    onPressed: () {
                      if (_formKey.currentState?.validate() != true) return;
                      Navigator.of(context).pop({
                        'exerciseId': _selectedExercise!.id,
                        'sets': int.parse(_setsController.text),
                        'reps': int.parse(_repsController.text),
                        'weight': double.tryParse(_weightController.text),
                        'note': _noteController.text.trim().isEmpty
                            ? null
                            : _noteController.text.trim(),
                      });
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

