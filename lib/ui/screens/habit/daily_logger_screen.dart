import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/habit_model.dart';
import '../../../data/models/habit_type.dart';
import '../../../data/models/life_goal_model.dart';
import '../../viewmodels/habit_view_model.dart';

/// Main screen for daily habit tracking and rating.
class DailyLoggerScreen extends StatefulWidget {
  const DailyLoggerScreen({super.key});

  @override
  State<DailyLoggerScreen> createState() => _DailyLoggerScreenState();
}

class _DailyLoggerScreenState extends State<DailyLoggerScreen> {
  final TextEditingController _noteController = TextEditingController();
  double _sliderValue = 5;
  bool _hasUnsavedRating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncRatingState();
    });
  }

  void _syncRatingState() {
    final vm = context.read<HabitViewModel>();
    if (vm.selectedDateRating != null) {
      setState(() {
        _sliderValue = vm.selectedDateRating!.score.toDouble();
        _noteController.text = vm.selectedDateRating!.note ?? '';
        _hasUnsavedRating = false;
      });
    } else {
      setState(() {
        _sliderValue = 5;
        _noteController.text = '';
        _hasUnsavedRating = false;
      });
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HabitViewModel>(
      builder: (context, vm, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Daily Log'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Column(
            children: [
              // Date Selector
              _buildDateSelector(context, vm),
              const Divider(height: 1),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Daily Score Card
                      _buildDailyScoreCard(context, vm),
                      const SizedBox(height: 24),
                      // Habits List
                      _buildHabitsSection(context, vm),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDateSelector(BuildContext context, HabitViewModel vm) {
    final isToday = _isSameDay(vm.selectedDate, DateTime.now());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              vm.setSelectedDate(
                  vm.selectedDate.subtract(const Duration(days: 1)));
              _syncRatingState();
            },
            icon: const Icon(Icons.chevron_left),
          ),
          GestureDetector(
            onTap: () => _pickDate(context, vm),
            child: Column(
              children: [
                Text(
                  isToday
                      ? 'Today'
                      : '${vm.selectedDate.day.toString().padLeft(2, '0')}.${vm.selectedDate.month.toString().padLeft(2, '0')}.${vm.selectedDate.year}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (!isToday)
                  Text(
                    _getWeekdayName(vm.selectedDate.weekday),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: isToday
                ? null
                : () {
                    vm.setSelectedDate(
                        vm.selectedDate.add(const Duration(days: 1)));
                    _syncRatingState();
                  },
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyScoreCard(BuildContext context, HabitViewModel vm) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.star,
                  color: _getScoreColor(_sliderValue.round()),
                ),
                const SizedBox(width: 8),
                Text(
                  'Daily Score',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getScoreColor(_sliderValue.round()),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_sliderValue.round()}/10',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Slider
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: _getScoreColor(_sliderValue.round()),
                thumbColor: _getScoreColor(_sliderValue.round()),
                overlayColor:
                    _getScoreColor(_sliderValue.round()).withValues(alpha: 0.2),
              ),
              child: Slider(
                value: _sliderValue,
                min: 1,
                max: 10,
                divisions: 9,
                label: _sliderValue.round().toString(),
                onChanged: (value) {
                  setState(() {
                    _sliderValue = value;
                    _hasUnsavedRating = true;
                  });
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '😢 Bad',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  'Great 😊',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Note TextField
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'How was your day?',
                border: const OutlineInputBorder(),
                suffixIcon: vm.selectedDateRating?.note != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _noteController.clear();
                          setState(() => _hasUnsavedRating = true);
                        },
                      )
                    : null,
              ),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) {
                setState(() => _hasUnsavedRating = true);
              },
            ),
            const SizedBox(height: 12),
            // Save Button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _hasUnsavedRating
                    ? () => _saveRating(vm)
                    : null,
                icon: const Icon(Icons.save),
                label: Text(vm.selectedDateRating != null
                    ? 'Update Score'
                    : 'Save Score'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitsSection(BuildContext context, HabitViewModel vm) {
    if (vm.habits.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.repeat,
                size: 48,
                color:
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 12),
              Text(
                'No habits yet',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Add habits in the Manage section',
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
      );
    }

    // Group habits by goal
    final grouped = vm.habitsGroupedByGoal;
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) {
        if (a == null && b == null) return 0;
        if (a == null) return 1;
        if (b == null) return -1;
        return a.title.compareTo(b.title);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Habits',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Spacer(),
            Text(
              '${vm.todayCompletedCount}/${vm.totalHabitsCount} done',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...sortedKeys.map((goal) {
          final habits = grouped[goal]!;
          return _buildGoalGroup(context, vm, goal, habits);
        }),
      ],
    );
  }

  Widget _buildGoalGroup(
    BuildContext context,
    HabitViewModel vm,
    LifeGoalModel? goal,
    List<HabitModel> habits,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Goal Header
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(
                goal != null ? Icons.flag : Icons.more_horiz,
                size: 16,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(width: 6),
              Text(
                goal?.title ?? 'No Goal',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
              ),
            ],
          ),
        ),
        // Habit Cards
        ...habits.map((habit) => _HabitCheckCard(
              habit: habit,
              goal: goal,
              isCompleted: vm.isHabitCompleted(habit.id),
              onToggle: () => vm.toggleHabitCompletion(habit.id),
            )),
        const SizedBox(height: 8),
      ],
    );
  }

  void _saveRating(HabitViewModel vm) {
    vm.setDailyRating(
      _sliderValue.round(),
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );
    setState(() => _hasUnsavedRating = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Score saved'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context, HabitViewModel vm) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: vm.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      vm.setSelectedDate(picked);
      _syncRatingState();
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _getWeekdayName(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[weekday - 1];
  }

  Color _getScoreColor(int score) {
    if (score >= 8) return Colors.green;
    if (score >= 6) return Colors.lightGreen;
    if (score >= 4) return Colors.orange;
    return Colors.red;
  }
}

class _HabitCheckCard extends StatelessWidget {
  final HabitModel habit;
  final LifeGoalModel? goal;
  final bool isCompleted;
  final VoidCallback onToggle;

  const _HabitCheckCard({
    required this.habit,
    this.goal,
    required this.isCompleted,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isNegative = habit.type == HabitType.negative;
    // Use reddish/orange tint for negative habits, otherwise use habit's color
    final habitColor = isNegative
        ? Colors.orange.shade600
        : Color(habit.colorValue);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCompleted
              ? habitColor
              : habitColor.withValues(alpha: 0.3),
          width: isCompleted ? 2.5 : 1.5,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              // Checkbox
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted ? habitColor : Colors.transparent,
                  border: Border.all(
                    color: habitColor,
                    width: 2,
                  ),
                ),
                child: isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : null,
              ),
              const SizedBox(width: 12),
              // Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (isNegative) ...[
                          Icon(
                            Icons.block,
                            size: 16,
                            color: Colors.orange.shade600,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            habit.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              decoration: isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: isCompleted
                                  ? Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.5)
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Status Indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? (isNegative
                          ? Colors.orange.withValues(alpha: 0.15)
                          : Colors.green.withValues(alpha: 0.15))
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isCompleted ? 'Done' : 'Tap',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isCompleted
                        ? (isNegative ? Colors.orange.shade700 : Colors.green)
                        : Colors.grey,
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

