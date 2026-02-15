import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/life_goal_model.dart';
import '../../viewmodels/habit_view_model.dart';
import '../../widgets/quick_filter_bar.dart';
import 'daily_logger_screen.dart';
import 'edit_goal_sheet.dart';
import 'goal_habit_manager_screen.dart';

/// Main hub screen for the Habit & Goal Logger module.
class HabitHubScreen extends StatelessWidget {
  const HabitHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Habit Logger'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer<HabitViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Quick Filter Bar for Goals
                if (vm.goals.isNotEmpty)
                  QuickFilterBar<LifeGoalModel>(
                    items: vm.goals,
                    selectedItem: vm.selectedGoalId != null
                        ? vm.goals.firstWhere(
                            (g) => g.id == vm.selectedGoalId,
                            orElse: () => vm.goals.first,
                          )
                        : null,
                    onItemSelected: (goal) {
                      vm.setSelectedGoal(goal?.id);
                    },
                    onItemLongPress: (goal) {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => ChangeNotifierProvider.value(
                          value: vm,
                          child: EditGoalSheet(goal: goal),
                        ),
                      );
                    },
                    getItemId: (goal) => goal.id,
                    getItemName: (goal) => goal.title,
                    getItemColor: null, // Goals don't have colors
                  ),
                if (vm.goals.isNotEmpty) const SizedBox(height: 16),
                // Today's Progress Card
                _buildProgressCard(context, vm),
                const SizedBox(height: 24),
                // Action Cards Grid
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
                      return GridView.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        padding: EdgeInsets.only(bottom: bottomPadding),
                    children: [
                      _buildActionCard(
                        context,
                        title: 'Daily Log',
                        subtitle: 'Track today',
                        icon: Icons.check_circle_outline,
                        color: Theme.of(context).colorScheme.primary,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DailyLoggerScreen(),
                          ),
                        ),
                      ),
                      _buildActionCard(
                        context,
                        title: 'Manage',
                        subtitle: '${vm.goals.length} goals, ${vm.habits.length} habits',
                        icon: Icons.settings_outlined,
                        color: Theme.of(context).colorScheme.secondary,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const GoalHabitManagerScreen(),
                          ),
                        ),
                      ),
                      _buildActionCard(
                        context,
                        title: 'Export',
                        subtitle: 'Download data',
                        icon: Icons.download_outlined,
                        color: Colors.teal,
                        onTap: () => _showExportDialog(context, vm),
                      ),
                      _buildActionCard(
                        context,
                        title: 'Stats',
                        subtitle: '${vm.completionPercentage.toStringAsFixed(0)}% today',
                        icon: Icons.bar_chart_outlined,
                        color: Colors.orange,
                        onTap: () => _showStatsBottomSheet(context, vm),
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

  Widget _buildProgressCard(BuildContext context, HabitViewModel vm) {
    final completed = vm.todayCompletedCount;
    final total = vm.totalHabitsCount;
    final percentage = vm.completionPercentage;

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
                  Icons.track_changes,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  "Today's Progress",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                if (vm.selectedDateRating != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getScoreColor(vm.selectedDateRating!.score),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${vm.selectedDateRating!.score}/10',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$completed / $total',
                        style:
                            Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                      ),
                      Text(
                        'habits completed',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                            ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: total > 0 ? percentage : 0,
                        strokeWidth: 8,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Center(
                        child: Text(
                          '${(percentage * 100).toInt()}%',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 8) return Colors.green;
    if (score >= 6) return Colors.lightGreen;
    if (score >= 4) return Colors.orange;
    return Colors.red;
  }

  void _showExportDialog(BuildContext context, HabitViewModel vm) {
    DateTime fromDate = DateTime.now().subtract(const Duration(days: 30));
    DateTime toDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Export Habits Data'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('From'),
                subtitle: Text(_formatDate(fromDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: fromDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => fromDate = picked);
                  }
                },
              ),
              ListTile(
                title: const Text('To'),
                subtitle: Text(_formatDate(toDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: toDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => toDate = picked);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  final path = await vm.exportHabitsData(
                    from: fromDate,
                    to: toDate,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Exported to: $path'),
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Export failed: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Export'),
            ),
          ],
        ),
      ),
    );
  }

  void _showStatsBottomSheet(BuildContext context, HabitViewModel vm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Statistics Overview',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).viewPadding.bottom),
                children: [
                  _buildStatTile(
                    context,
                    icon: Icons.flag,
                    title: 'Active Goals',
                    value: '${vm.goals.length}',
                    color: Colors.blue,
                  ),
                  _buildStatTile(
                    context,
                    icon: Icons.repeat,
                    title: 'Active Habits',
                    value: '${vm.habits.length}',
                    color: Colors.purple,
                  ),
                  _buildStatTile(
                    context,
                    icon: Icons.check_circle,
                    title: 'Completed Today',
                    value: '${vm.todayCompletedCount}/${vm.totalHabitsCount}',
                    color: Colors.green,
                  ),
                  _buildStatTile(
                    context,
                    icon: Icons.star,
                    title: "Today's Score",
                    value: vm.selectedDateRating != null
                        ? '${vm.selectedDateRating!.score}/10'
                        : 'Not rated',
                    color: Colors.orange,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        trailing: Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}

