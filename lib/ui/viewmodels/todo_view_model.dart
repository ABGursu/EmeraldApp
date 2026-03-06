import 'package:flutter/material.dart';

import '../../data/models/recurrence_type.dart';
import '../../data/models/todo_item_model.dart';
import '../../data/repositories/i_todo_repository.dart';
import '../../data/repositories/sql_todo_repository.dart';
import '../../utils/id_generator.dart';
import 'calendar_view_model.dart';

class TodoViewModel extends ChangeNotifier {
  TodoViewModel({ITodoRepository? repository})
      : _repository = repository ?? SqlTodoRepository();

  final ITodoRepository _repository;

  List<TodoItemModel> _items = [];
  bool _loading = false;

  List<TodoItemModel> get items => _items;
  bool get isLoading => _loading;

  List<TodoItemModel> get pendingItems =>
      _items.where((i) => i.status == TodoStatus.pending).toList();

  List<TodoItemModel> get completedItems =>
      _items.where((i) => i.status == TodoStatus.completed).toList();

  /// Pending items grouped: overdue first, then by deadline (nulls last)
  List<TodoItemModel> get sortedPendingItems {
    final pending = pendingItems;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    final overdue = <TodoItemModel>[];
    final upcoming = <TodoItemModel>[];
    final noDeadline = <TodoItemModel>[];

    for (final item in pending) {
      if (item.deadline == null) {
        noDeadline.add(item);
      } else if (item.deadline!.isBefore(todayStart)) {
        overdue.add(item);
      } else {
        upcoming.add(item);
      }
    }

    overdue.sort((a, b) => a.deadline!.compareTo(b.deadline!));
    upcoming.sort((a, b) => a.deadline!.compareTo(b.deadline!));
    noDeadline.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return [...overdue, ...upcoming, ...noDeadline];
  }

  Future<void> init() async {
    await loadItems();
  }

  Future<void> loadItems() async {
    _loading = true;
    notifyListeners();
    _items = await _repository.getAllItems();
    _loading = false;
    notifyListeners();
  }

  static const int _todoTagColor = 0xFF81D4FA; // Light Blue 200

  /// Creates or finds the "Todo" tag in the calendar system.
  Future<String> _getOrCreateTodoTag(CalendarViewModel calendarVm) async {
    for (final tag in calendarVm.tags) {
      if (tag.name.toLowerCase() == 'todo') {
        return tag.id;
      }
    }
    final tagId = await calendarVm.createTag('Todo', _todoTagColor);
    return tagId;
  }

  Future<String> addItem({
    required String title,
    String? description,
    DateTime? deadline,
    required CalendarViewModel calendarVm,
  }) async {
    final id = generateId();
    String? linkedEventId;

    if (deadline != null) {
      final tagId = await _getOrCreateTodoTag(calendarVm);
      linkedEventId = await calendarVm.createEvent(
        title: title,
        description: description,
        dateTime: deadline,
        tagId: tagId,
        recurrenceType: RecurrenceType.none,
        warnDaysBefore: 0,
      );
    }

    final item = TodoItemModel(
      id: id,
      title: title,
      description: description,
      deadline: deadline,
      status: TodoStatus.pending,
      linkedCalendarEventId: linkedEventId,
      createdAt: DateTime.now(),
    );
    await _repository.createItem(item);
    await loadItems();
    return id;
  }

  Future<void> updateItem(
    TodoItemModel item, {
    required CalendarViewModel calendarVm,
  }) async {
    TodoItemModel? existing;
    for (final i in _items) {
      if (i.id == item.id) {
        existing = i;
        break;
      }
    }

    String? linkedEventId = item.linkedCalendarEventId;

    final deadlineChanged = existing?.deadline != item.deadline;
    final titleChanged = existing?.title != item.title;
    final descChanged = existing?.description != item.description;
    final needsCalendarUpdate = deadlineChanged || titleChanged || descChanged;

    if (needsCalendarUpdate) {
      // Remove old calendar event if it exists
      if (linkedEventId != null) {
        await calendarVm.deleteEvent(linkedEventId);
        linkedEventId = null;
      }

      // Create new calendar event if deadline is set
      if (item.deadline != null && item.status == TodoStatus.pending) {
        final tagId = await _getOrCreateTodoTag(calendarVm);
        linkedEventId = await calendarVm.createEvent(
          title: item.title,
          description: item.description,
          dateTime: item.deadline!,
          tagId: tagId,
          recurrenceType: RecurrenceType.none,
          warnDaysBefore: 0,
        );
      }
    }

    final updated = item.copyWith(linkedCalendarEventId: linkedEventId);
    await _repository.updateItem(updated);
    await loadItems();
  }

  Future<void> toggleComplete(
    TodoItemModel item, {
    required CalendarViewModel calendarVm,
  }) async {
    final newStatus = item.status == TodoStatus.pending
        ? TodoStatus.completed
        : TodoStatus.pending;

    String? linkedEventId = item.linkedCalendarEventId;

    if (newStatus == TodoStatus.completed && linkedEventId != null) {
      await calendarVm.deleteEvent(linkedEventId);
      linkedEventId = null;
    } else if (newStatus == TodoStatus.pending && item.deadline != null) {
      final tagId = await _getOrCreateTodoTag(calendarVm);
      linkedEventId = await calendarVm.createEvent(
        title: item.title,
        description: item.description,
        dateTime: item.deadline!,
        tagId: tagId,
        recurrenceType: RecurrenceType.none,
        warnDaysBefore: 0,
      );
    }

    final updated = item.copyWith(
      status: newStatus,
      linkedCalendarEventId: linkedEventId,
      clearLinkedCalendarEventId: linkedEventId == null,
    );
    await _repository.updateItem(updated);
    await loadItems();
  }

  Future<void> deleteItem(
    String id, {
    required CalendarViewModel calendarVm,
  }) async {
    for (final item in _items) {
      if (item.id == id && item.linkedCalendarEventId != null) {
        await calendarVm.deleteEvent(item.linkedCalendarEventId!);
        break;
      }
    }
    await _repository.deleteItem(id);
    await loadItems();
  }
}
