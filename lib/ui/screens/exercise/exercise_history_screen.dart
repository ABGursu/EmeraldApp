import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/workout_session_model.dart';
import '../../../ui/viewmodels/exercise_view_model.dart';
import '../../../utils/date_formats.dart';
import 'add_session_sheet.dart';
import 'routines_screen.dart';
import 'session_detail_screen.dart';

class ExerciseHistoryScreen extends StatelessWidget {
  const ExerciseHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ExerciseViewModel>(
      builder: (context, vm, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Exercise Logger'),
            actions: [
              IconButton(
                icon: const Icon(Icons.playlist_add),
                tooltip: 'Manage Routines',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChangeNotifierProvider.value(
                        value: vm,
                        child: const RoutinesScreen(),
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.upload_file),
                onPressed: () async {
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (range != null) {
                    final path = await vm.exportSessions(
                      from: range.start,
                      to: range.end.add(const Duration(
                          hours: 23, minutes: 59, seconds: 59)), // inclusive
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Exported to $path')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
          body: vm.isLoading
              ? const Center(child: CircularProgressIndicator())
              : _SessionList(sessions: vm.sessions),
          floatingActionButton: FloatingActionButton(
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => ChangeNotifierProvider.value(
                value: vm,
                child: const AddSessionSheet(),
              ),
            ),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}

class _SessionList extends StatelessWidget {
  const _SessionList({required this.sessions});

  final List<WorkoutSessionModel> sessions;

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return const Center(child: Text('No sessions yet'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        return Card(
          child: ListTile(
            title: Text(formatDateTime(session.date)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (session.userWeight != null)
                  Text('Weight: ${session.userWeight} kg'),
                if (session.userFat != null) Text('Fat: ${session.userFat}%'),
                if (session.note != null) Text('Note: ${session.note}'),
              ],
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider.value(
                    value: context.read<ExerciseViewModel>(),
                    child: SessionDetailScreen(session: session),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

