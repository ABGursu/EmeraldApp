import 'recurrence_type.dart';

class CalendarEventModel {
  final String id;
  final String title;
  final String? description;
  final DateTime dateTime; // Exact date and time
  final int? durationMinutes; // Optional duration in minutes
  final String? tagId; // Link to CalendarTag
  final RecurrenceType recurrenceType;
  final int warnDaysBefore; // Days before event to show sticky warning
  final int? alarmBeforeHours; // Optional: hours before event for notification
  final DateTime createdAt;

  const CalendarEventModel({
    required this.id,
    required this.title,
    this.description,
    required this.dateTime,
    this.durationMinutes,
    this.tagId,
    required this.recurrenceType,
    required this.warnDaysBefore,
    this.alarmBeforeHours,
    required this.createdAt,
  });

  CalendarEventModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dateTime,
    int? durationMinutes,
    String? tagId,
    RecurrenceType? recurrenceType,
    int? warnDaysBefore,
    int? alarmBeforeHours,
    DateTime? createdAt,
    bool clearDescription = false,
    bool clearDurationMinutes = false,
    bool clearTagId = false,
    bool clearAlarmBeforeHours = false,
  }) {
    return CalendarEventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: clearDescription ? null : (description ?? this.description),
      dateTime: dateTime ?? this.dateTime,
      durationMinutes:
          clearDurationMinutes ? null : (durationMinutes ?? this.durationMinutes),
      tagId: clearTagId ? null : (tagId ?? this.tagId),
      recurrenceType: recurrenceType ?? this.recurrenceType,
      warnDaysBefore: warnDaysBefore ?? this.warnDaysBefore,
      alarmBeforeHours: clearAlarmBeforeHours
          ? null
          : (alarmBeforeHours ?? this.alarmBeforeHours),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'date_time': dateTime.millisecondsSinceEpoch,
        'duration_minutes': durationMinutes,
        'tag_id': tagId,
        'recurrence_type': recurrenceType.index,
        'warn_days_before': warnDaysBefore,
        'alarm_before_hours': alarmBeforeHours,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory CalendarEventModel.fromMap(Map<String, dynamic> map) {
    return CalendarEventModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      dateTime: DateTime.fromMillisecondsSinceEpoch(map['date_time'] as int),
      durationMinutes: map['duration_minutes'] as int?,
      tagId: map['tag_id'] as String?,
      recurrenceType: RecurrenceType.values[map['recurrence_type'] as int],
      warnDaysBefore: map['warn_days_before'] as int,
      alarmBeforeHours: map['alarm_before_hours'] as int?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  /// Calculates the next occurrence of this event based on recurrence type
  DateTime getNextOccurrence(DateTime fromDate) {
    switch (recurrenceType) {
      case RecurrenceType.none:
        return dateTime;
      case RecurrenceType.weekly:
        DateTime next = dateTime;
        while (next.isBefore(fromDate) || next.isAtSameMomentAs(fromDate)) {
          next = next.add(const Duration(days: 7));
        }
        return next;
      case RecurrenceType.monthly:
        DateTime next = dateTime;
        while (next.isBefore(fromDate) || next.isAtSameMomentAs(fromDate)) {
          next = DateTime(next.year, next.month + 1, next.day, next.hour, next.minute);
        }
        return next;
      case RecurrenceType.yearly:
        DateTime next = dateTime;
        while (next.isBefore(fromDate) || next.isAtSameMomentAs(fromDate)) {
          next = DateTime(next.year + 1, next.month, next.day, next.hour, next.minute);
        }
        return next;
    }
  }

  /// Checks if the event is currently "sticky/active" based on warnDaysBefore
  bool isSticky(DateTime currentTime) {
    final nextOccurrence = getNextOccurrence(currentTime);
    final warningStart = nextOccurrence.subtract(Duration(days: warnDaysBefore));
    return (currentTime.isAfter(warningStart) || currentTime.isAtSameMomentAs(warningStart)) &&
        currentTime.isBefore(nextOccurrence);
  }

  /// Gets the time remaining until the next occurrence
  Duration getTimeRemaining(DateTime currentTime) {
    final nextOccurrence = getNextOccurrence(currentTime);
    return nextOccurrence.difference(currentTime);
  }
}

