import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../ui/viewmodels/daily_log_view_model.dart';
import '../../../ui/viewmodels/exercise_library_view_model.dart';

class LoadRoutineSheet extends StatelessWidget {
  const LoadRoutineSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final libraryVm = context.watch<ExerciseLibraryViewModel>();
    final dailyVm = context.watch<DailyLogViewModel>();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Load Routine',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (libraryVm.routines.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text('No routines available. Create one first!'),
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: libraryVm.routines.length,
                itemBuilder: (context, index) {
                  final routine = libraryVm.routines[index];
                  return ListTile(
                    leading: const Icon(Icons.playlist_play),
                    title: Text(
                      routine.name,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                    subtitle: Text(
                      'Created: ${routine.createdAt.day}.${routine.createdAt.month}.${routine.createdAt.year}',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    onTap: () async {
                      Navigator.of(context).pop();
                      await dailyVm.loadRoutine(routine.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Routine "${routine.name}" loaded'),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
