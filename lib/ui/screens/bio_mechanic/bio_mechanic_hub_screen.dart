import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/bio_mechanic_view_model.dart';
import 'daily_logger_screen.dart';
import 'exercise_creation_screen.dart';
import 'progressive_overload_screen.dart';
import 'sportif_goals_manager_screen.dart';

/// Main Hub Screen for the Bio-Mechanic Training Management System.
class BioMechanicHubScreen extends StatelessWidget {
  const BioMechanicHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise Logger'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Unit selector (KG/LBS)
          Consumer<BioMechanicViewModel>(
            builder: (context, vm, _) {
              return PopupMenuButton<String>(
                icon: Text(
                  vm.preferredUnit,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                tooltip: 'Weight Unit',
                onSelected: (unit) async {
                  await vm.setPreferredUnit(unit);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'KG',
                    child: Text('Kilograms (KG)'),
                  ),
                  const PopupMenuItem(
                    value: 'LBS',
                    child: Text('Pounds (LBS)'),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<BioMechanicViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Welcome/Stats Card
                _buildStatsCard(context, vm),
                const SizedBox(height: 24),
                // Action Cards Grid (2x2)
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final bottomPadding =
                          MediaQuery.of(context).viewPadding.bottom;
                      return GridView.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        padding: EdgeInsets.only(bottom: bottomPadding),
                        children: [
                          _buildActionCard(
                            context,
                            title: 'Sportif Goals',
                            icon: Icons.flag,
                            color: Theme.of(context).colorScheme.primary,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const SportifGoalsManagerScreen(),
                              ),
                            ),
                          ),
                          _buildActionCard(
                            context,
                            title: 'Daily Logger',
                            icon: Icons.calendar_today,
                            color: Theme.of(context).colorScheme.secondary,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const DailyLoggerScreen(),
                              ),
                            ),
                          ),
                          _buildActionCard(
                            context,
                            title: 'Exercise Creation',
                            icon: Icons.science,
                            color: Colors.teal,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ExerciseCreationScreen(),
                              ),
                            ),
                          ),
                          _buildActionCard(
                            context,
                            title: 'Progressive Overload',
                            icon: Icons.trending_up,
                            color: Colors.orange,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const ProgressiveOverloadScreen(),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context, BioMechanicViewModel vm) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
              Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.fitness_center,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Bio-Mechanic Training',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  context,
                  label: 'Exercises',
                  value: '${vm.exerciseDefinitions.length}',
                  icon: Icons.sports_gymnastics,
                ),
                _buildStatItem(
                  context,
                  label: 'Sessions',
                  value: '${vm.sessions.length}',
                  icon: Icons.event,
                ),
                _buildStatItem(
                  context,
                  label: 'Goals',
                  value: '${vm.goals.length}',
                  icon: Icons.flag,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
