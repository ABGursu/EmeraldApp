import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/calendar_event_model.dart';
import '../../../data/models/recurrence_type.dart';
import '../../../ui/viewmodels/calendar_view_model.dart';
import '../../../utils/date_formats.dart';
import 'add_edit_event_sheet.dart';

class AllEventsListScreen extends StatelessWidget {
  const AllEventsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Events'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer<CalendarViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (vm.events.isEmpty) {
            return const Center(
              child: Text('No events yet. Tap + to add one.'),
            );
          }

          final bottomSafe = MediaQuery.of(context).viewPadding.bottom;
          return ListView.builder(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomSafe),
            itemCount: vm.events.length,
            itemBuilder: (context, index) {
              final event = vm.events[index];
              return _EventCard(event: event, vm: vm);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => ChangeNotifierProvider.value(
            value: context.read<CalendarViewModel>(),
            child: const AddEditEventSheet(),
          ),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final CalendarEventModel event;
  final CalendarViewModel vm;

  const _EventCard({required this.event, required this.vm});

  @override
  Widget build(BuildContext context) {
    final tag = vm.getTagById(event.tagId);
    final nextOccurrence = event.getNextOccurrence(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
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
            Text('Next: ${formatDateTime(nextOccurrence)}'),
            if (event.description != null && event.description!.isNotEmpty)
              Text(
                event.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            Row(
              children: [
                Chip(
                  label: Text(event.recurrenceType.label),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 4),
                if (tag != null)
                  Chip(
                    label: Text(tag.name),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    backgroundColor:
                        Color(tag.colorValue).withValues(alpha: 0.2),
                  ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => ChangeNotifierProvider.value(
                  value: vm,
                  child: AddEditEventSheet(event: event),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDelete(context),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: Text('Are you sure you want to delete "${event.title}"?'),
        actions: [
          TextButton(
            onPressed: () {
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (context.mounted) {
                Navigator.pop(context);
              }
              await vm.deleteEvent(event.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${event.title} deleted')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
