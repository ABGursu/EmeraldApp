import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/calendar_event_model.dart';
import '../../../data/models/recurrence_type.dart';
import '../../../ui/viewmodels/calendar_view_model.dart';
import '../../../utils/date_formats.dart';
import '../../widgets/color_coded_selector.dart';

class AddEditEventSheet extends StatefulWidget {
  final CalendarEventModel? event;

  const AddEditEventSheet({super.key, this.event});

  @override
  State<AddEditEventSheet> createState() => _AddEditEventSheetState();
}

class _AddEditEventSheetState extends State<AddEditEventSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _durationController;
  late TextEditingController _warnDaysController;
  late TextEditingController _alarmHoursController;

  DateTime _selectedDateTime = DateTime.now();
  RecurrenceType _selectedRecurrence = RecurrenceType.none;
  ColorCodedItem? _selectedTag;
  int? _durationMinutes;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.event?.description ?? '');
    _durationController = TextEditingController(
        text: widget.event?.durationMinutes?.toString() ?? '');
    _warnDaysController = TextEditingController(
        text: widget.event?.warnDaysBefore.toString() ?? '5');
    _alarmHoursController = TextEditingController(
        text: widget.event?.alarmBeforeHours?.toString() ?? '');
    _selectedDateTime = widget.event?.dateTime ?? DateTime.now();
    _selectedRecurrence = widget.event?.recurrenceType ?? RecurrenceType.none;

    // Initialize selected tag if editing
    if (widget.event?.tagId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final vm = context.read<CalendarViewModel>();
        final tag = vm.getTagById(widget.event!.tagId);
        if (tag != null) {
          setState(() {
            _selectedTag = ColorCodedItem(
              id: tag.id,
              name: tag.name,
              colorValue: tag.colorValue,
            );
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _warnDaysController.dispose();
    _alarmHoursController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime() async {
    if (!mounted) return;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );
      if (pickedTime != null && mounted) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CalendarViewModel>();
    final isEditing = widget.event != null;

    final tagItems = vm.tags
        .map((t) =>
            ColorCodedItem(id: t.id, name: t.name, colorValue: t.colorValue))
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
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? 'Edit Event' : 'Add New Event',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Title cannot be empty';
                    }
                    return null;
                  },
                  textCapitalization: TextCapitalization.sentences,
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Date & Time'),
                  subtitle: Text(formatDateTime(_selectedDateTime)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _selectDateTime,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _durationController,
                  decoration: const InputDecoration(
                    labelText: 'Duration (minutes, optional)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _durationMinutes =
                        value.isNotEmpty ? int.tryParse(value) : null;
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Recurrence',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                SegmentedButton<RecurrenceType>(
                  segments: RecurrenceType.values.map((type) {
                    return ButtonSegment<RecurrenceType>(
                      value: type,
                      label: Text(type.label),
                    );
                  }).toList(),
                  selected: {_selectedRecurrence},
                  onSelectionChanged: (Set<RecurrenceType> newSelection) {
                    setState(() {
                      _selectedRecurrence = newSelection.first;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _warnDaysController,
                  decoration: const InputDecoration(
                    labelText: 'Warn Days Before',
                    border: OutlineInputBorder(),
                    helperText: 'Days before event to show sticky warning',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty ||
                        int.tryParse(value) == null ||
                        int.parse(value) < 0) {
                      return 'Enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _alarmHoursController,
                  decoration: const InputDecoration(
                    labelText: 'Alarm Hours Before (optional)',
                    border: OutlineInputBorder(),
                    helperText: 'Hours before event for notification',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                ColorCodedSelectorFormField(
                  label: 'Tag (optional)',
                  items: tagItems,
                  initialValue: _selectedTag,
                  onEditItem: (item, name, color) async {
                    final tag = vm.tags.firstWhere((t) => t.id == item.id);
                    final updated = tag.copyWith(name: name, colorValue: color);
                    await vm.updateTag(updated);
                    final updatedItem = ColorCodedItem(
                      id: updated.id,
                      name: updated.name,
                      colorValue: updated.colorValue,
                    );
                    _selectedTag = updatedItem;
                    return updatedItem;
                  },
                  onDeleteItem: (item) async {
                    await vm.deleteTag(item.id);
                    if (_selectedTag?.id == item.id) {
                      _selectedTag = null;
                    }
                  },
                  onChanged: (item) => _selectedTag = item,
                  validator: (item) => null,
                  onCreateNew: (name, color) async {
                    final tagId = await vm.createTag(name, color);
                    final newItem = ColorCodedItem(
                        id: tagId, name: name, colorValue: color);
                    _selectedTag = newItem;
                    return newItem;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => _saveEvent(context, vm, isEditing),
                    child: Text(isEditing ? 'Update' : 'Add'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveEvent(
      BuildContext context, CalendarViewModel vm, bool isEditing) async {
    if (!_formKey.currentState!.validate()) return;

    final warnDaysBefore = int.parse(_warnDaysController.text);
    final alarmBeforeHours = _alarmHoursController.text.isNotEmpty
        ? int.tryParse(_alarmHoursController.text)
        : null;

    if (isEditing && widget.event != null) {
      final updatedEvent = widget.event!.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        dateTime: _selectedDateTime,
        durationMinutes: _durationMinutes,
        tagId: _selectedTag?.id,
        recurrenceType: _selectedRecurrence,
        warnDaysBefore: warnDaysBefore,
        alarmBeforeHours: alarmBeforeHours,
      );
      await vm.updateEvent(updatedEvent);
    } else {
      await vm.createEvent(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        dateTime: _selectedDateTime,
        durationMinutes: _durationMinutes,
        tagId: _selectedTag?.id,
        recurrenceType: _selectedRecurrence,
        warnDaysBefore: warnDaysBefore,
        alarmBeforeHours: alarmBeforeHours,
      );
    }

    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'Event updated' : 'Event added'),
        ),
      );
    }
  }
}
