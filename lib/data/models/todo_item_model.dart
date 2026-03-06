enum TodoStatus {
  pending,
  completed,
}

extension TodoStatusExtension on TodoStatus {
  String get label {
    switch (this) {
      case TodoStatus.pending:
        return 'Pending';
      case TodoStatus.completed:
        return 'Completed';
    }
  }

  int get value {
    switch (this) {
      case TodoStatus.pending:
        return 0;
      case TodoStatus.completed:
        return 1;
    }
  }

  static TodoStatus fromValue(int value) {
    switch (value) {
      case 1:
        return TodoStatus.completed;
      default:
        return TodoStatus.pending;
    }
  }
}

class TodoItemModel {
  final String id;
  final String title;
  final String? description;
  final DateTime? deadline;
  final TodoStatus status;
  final String? linkedCalendarEventId;
  final DateTime createdAt;

  const TodoItemModel({
    required this.id,
    required this.title,
    this.description,
    this.deadline,
    this.status = TodoStatus.pending,
    this.linkedCalendarEventId,
    required this.createdAt,
  });

  TodoItemModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? deadline,
    TodoStatus? status,
    String? linkedCalendarEventId,
    DateTime? createdAt,
    bool clearDescription = false,
    bool clearDeadline = false,
    bool clearLinkedCalendarEventId = false,
  }) {
    return TodoItemModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description:
          clearDescription ? null : (description ?? this.description),
      deadline: clearDeadline ? null : (deadline ?? this.deadline),
      status: status ?? this.status,
      linkedCalendarEventId: clearLinkedCalendarEventId
          ? null
          : (linkedCalendarEventId ?? this.linkedCalendarEventId),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'deadline': deadline?.millisecondsSinceEpoch,
        'status': status.value,
        'linked_calendar_event_id': linkedCalendarEventId,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory TodoItemModel.fromMap(Map<String, dynamic> map) {
    return TodoItemModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      deadline: map['deadline'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['deadline'] as int)
          : null,
      status: TodoStatusExtension.fromValue(map['status'] as int? ?? 0),
      linkedCalendarEventId: map['linked_calendar_event_id'] as String?,
      createdAt:
          DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }
}
