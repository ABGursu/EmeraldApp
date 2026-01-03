import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/calendar_event_model.dart';
import '../../../ui/viewmodels/calendar_view_model.dart';
import '../../../utils/date_formats.dart';

class DailyViewScreen extends StatefulWidget {
  const DailyViewScreen({super.key});

  @override
  State<DailyViewScreen> createState() => _DailyViewScreenState();
}

class _DailyViewScreenState extends State<DailyViewScreen> {
  final TextEditingController _diaryController = TextEditingController();
  bool _isEditing = false;

  @override
  void dispose() {
    _diaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CalendarViewModel>(
      builder: (context, vm, _) {
        // Load diary content when selected date changes
        if (!_isEditing && vm.currentDiaryEntry != null) {
          _diaryController.text = vm.currentDiaryEntry!.content;
        } else if (!_isEditing && vm.currentDiaryEntry == null) {
          _diaryController.clear();
        }

        return Column(
          children: [
            // Sticky Header Section
            _buildStickyHeader(vm),

            // Divider
            const Divider(height: 1),

            // Diary Editor Section
            Expanded(
              child: _buildDiaryEditor(vm),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStickyHeader(CalendarViewModel vm) {
    // Get events for the SELECTED date, not today
    final selectedDate = vm.selectedDate;
    final eventsForDate = vm.getEventsForDate(selectedDate);
    final warningEvents = vm.getWarningEventsForDate(selectedDate);
    
    // Combine events on the date and warning events (avoid duplicates)
    final allRelevantEvents = <CalendarEventModel>[];
    final eventIds = <String>{};
    
    // Add events that occur on the selected date
    for (final event in eventsForDate) {
      if (!eventIds.contains(event.id)) {
        allRelevantEvents.add(event);
        eventIds.add(event.id);
      }
    }
    
    // Add warning events (events with active warning window for selected date)
    for (final event in warningEvents) {
      if (!eventIds.contains(event.id)) {
        allRelevantEvents.add(event);
        eventIds.add(event.id);
      }
    }
    
    // Sort by next occurrence
    allRelevantEvents.sort((a, b) {
      final aNext = a.getNextOccurrence(selectedDate);
      final bNext = b.getNextOccurrence(selectedDate);
      return aNext.compareTo(bNext);
    });

    if (allRelevantEvents.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Text(
          'No events for ${formatDate(selectedDate)}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.event,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Events for ${formatDate(selectedDate)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...allRelevantEvents.map((event) => _buildStickyEventCard(vm, event, selectedDate)),
        ],
      ),
    );
  }

  Widget _buildStickyEventCard(CalendarViewModel vm, CalendarEventModel event, DateTime selectedDate) {
    final tag = vm.getTagById(event.tagId);
    final nextOccurrence = event.getNextOccurrence(selectedDate);
    
    // Check if event occurs on the selected date
    final selectedDateOnly = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final nextOccurrenceDateOnly = DateTime(nextOccurrence.year, nextOccurrence.month, nextOccurrence.day);
    final isOnSelectedDate = selectedDateOnly.isAtSameMomentAs(nextOccurrenceDateOnly);
    
    String timeText;
    if (isOnSelectedDate) {
      // Event occurs on selected date - show the time
      timeText = formatDateTime(nextOccurrence);
    } else {
      // Event is in the future - show time remaining
      final timeRemaining = nextOccurrence.difference(selectedDate);
      if (timeRemaining.inDays > 0) {
        timeText =
            'in ${timeRemaining.inDays} day${timeRemaining.inDays > 1 ? 's' : ''}';
      } else if (timeRemaining.inHours > 0) {
        timeText =
            'in ${timeRemaining.inHours} hour${timeRemaining.inHours > 1 ? 's' : ''}';
      } else {
        timeText =
            'in ${timeRemaining.inMinutes} minute${timeRemaining.inMinutes > 1 ? 's' : ''}';
      }
      timeText += ' • ${formatDateTime(nextOccurrence)}';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: tag != null
          ? Color(tag.colorValue).withValues(alpha: 0.1)
          : Theme.of(context).cardColor,
      child: ListTile(
        leading: tag != null
            ? Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Color(tag.colorValue),
                  shape: BoxShape.circle,
                ),
              )
            : null,
        title: Text(event.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(timeText),
            if (event.description != null && event.description!.isNotEmpty)
              Text(
                event.description!,
                style: const TextStyle(fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: tag != null
            ? Text(
                tag.name,
                style: TextStyle(
                  color: Color(tag.colorValue),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildDiaryEditor(CalendarViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date selector and save button
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  formatDate(vm.selectedDate),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: vm.selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    await vm.setSelectedDate(picked);
                  }
                },
              ),
              if (_isEditing)
                IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: () async {
                    await vm.saveDiaryEntry(_diaryController.text);
                    setState(() => _isEditing = false);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Diary entry saved')),
                      );
                    }
                  },
                ),
              if (!_isEditing)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => setState(() => _isEditing = true),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Text editor
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _diaryController,
              enabled: _isEditing,
              maxLines: null,
              expands: true,
              decoration: const InputDecoration(
                hintText: 'Write your diary entry for this day...',
                border: InputBorder.none,
              ),
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) {
                if (!_isEditing) {
                  setState(() => _isEditing = true);
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}
