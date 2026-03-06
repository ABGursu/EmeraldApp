import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/todo_item_model.dart';
import '../../../utils/date_formats.dart';
import '../../viewmodels/calendar_view_model.dart';
import '../../viewmodels/todo_view_model.dart';

class AddEditTodoSheet extends StatefulWidget {
  const AddEditTodoSheet({super.key, this.item});

  final TodoItemModel? item;

  @override
  State<AddEditTodoSheet> createState() => _AddEditTodoSheetState();
}

class _AddEditTodoSheetState extends State<AddEditTodoSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  DateTime? _deadline;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.item?.description ?? '');
    _deadline = widget.item?.deadline;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.item != null;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing ? 'Edit Todo' : 'Add Todo',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        if (context.mounted) Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: !isEditing,
                  validator: (v) =>
                      v?.trim().isEmpty ?? true ? 'Title is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                // Deadline picker
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.event,
                    color: _deadline != null
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  title: Text(
                    _deadline != null
                        ? 'Deadline: ${formatDate(_deadline!)}'
                        : 'Set Deadline (optional)',
                  ),
                  subtitle: _deadline != null
                      ? Text(
                          _formatTimeOfDay(_deadline!),
                          style: Theme.of(context).textTheme.bodySmall,
                        )
                      : null,
                  trailing: _deadline != null
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => _deadline = null),
                        )
                      : null,
                  onTap: () => _pickDeadline(context),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => _saveItem(context, isEditing),
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

  String _formatTimeOfDay(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _pickDeadline(BuildContext context) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !context.mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: _deadline != null
          ? TimeOfDay.fromDateTime(_deadline!)
          : const TimeOfDay(hour: 23, minute: 59),
    );
    if (!context.mounted) return;

    setState(() {
      if (time != null) {
        _deadline =
            DateTime(date.year, date.month, date.day, time.hour, time.minute);
      } else {
        _deadline = DateTime(date.year, date.month, date.day, 23, 59);
      }
    });
  }

  Future<void> _saveItem(BuildContext context, bool isEditing) async {
    if (!_formKey.currentState!.validate()) return;

    final vm = context.read<TodoViewModel>();
    final calendarVm = context.read<CalendarViewModel>();

    if (isEditing && widget.item != null) {
      final updated = widget.item!.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        deadline: _deadline,
        clearDescription: _descriptionController.text.trim().isEmpty,
        clearDeadline: _deadline == null,
      );
      await vm.updateItem(updated, calendarVm: calendarVm);
    } else {
      await vm.addItem(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        deadline: _deadline,
        calendarVm: calendarVm,
      );
    }

    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'Todo updated' : 'Todo added'),
        ),
      );
    }
  }
}
