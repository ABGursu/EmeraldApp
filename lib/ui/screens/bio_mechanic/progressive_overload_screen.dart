import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/bio_mechanic_view_model.dart';
import '../../../utils/date_formats.dart';

/// Progressive Overload Analytics Dashboard - Shows effective score trends over time.
class ProgressiveOverloadScreen extends StatefulWidget {
  const ProgressiveOverloadScreen({super.key});

  @override
  State<ProgressiveOverloadScreen> createState() =>
      _ProgressiveOverloadScreenState();
}

class _ProgressiveOverloadScreenState extends State<ProgressiveOverloadScreen> {
  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _toDate = DateTime.now();
  int? _selectedExerciseId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progressive Overload'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer<BioMechanicViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Exercise Selector
              _buildExerciseSelector(context, vm),
              const Divider(height: 1),
              // Date Range Selector
              _buildDateRangeSelector(context, vm),
              const Divider(height: 1),
              // Chart
              Expanded(
                child: _buildChart(context, vm),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildExerciseSelector(
    BuildContext context,
    BioMechanicViewModel vm,
  ) {
    final exercises = vm.exerciseDefinitions;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Exercise',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            decoration: const InputDecoration(
              labelText: 'Exercise',
              border: OutlineInputBorder(),
            ),
            initialValue: _selectedExerciseId,
            items: exercises.map((exercise) {
              return DropdownMenuItem(
                value: exercise.id,
                child: Text(exercise.name),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedExerciseId = value);
              if (value != null) {
                _loadData(vm, value);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeSelector(
    BuildContext context,
    BioMechanicViewModel vm,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('From'),
              subtitle: Text(formatDate(_fromDate)),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _fromDate,
                  firstDate: DateTime(2000),
                  lastDate: _toDate,
                );
                if (picked != null) {
                  if (!mounted) return;
                  setState(() => _fromDate = picked);
                  if (_selectedExerciseId != null) {
                    _loadData(vm, _selectedExerciseId!);
                  }
                }
              },
            ),
          ),
          Expanded(
            child: ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('To'),
              subtitle: Text(formatDate(_toDate)),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _toDate,
                  firstDate: _fromDate,
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  if (!mounted) return;
                  setState(() => _toDate = picked);
                  if (_selectedExerciseId != null) {
                    _loadData(vm, _selectedExerciseId!);
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(BuildContext context, BioMechanicViewModel vm) {
    final data = vm.progressiveOverloadData;

    if (_selectedExerciseId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.trending_up_outlined,
              size: 80,
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Select an exercise to view progress',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    if (data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart_outlined,
              size: 80,
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No data for this period',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Complete workouts to see your progress',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
            ),
          ],
        ),
      );
    }

    // Determine color based on trend
    final isPositive = vm.isProgressiveOverloadPositive;
    final lineColor = isPositive ? Colors.green : Colors.red;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Trend Indicator
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Trend',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isPositive
                                  ? Icons.trending_up
                                  : Icons.trending_down,
                              color: lineColor,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                isPositive ? 'Improving' : 'Declining',
                                style: TextStyle(
                                  color: lineColor,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Current Score',
                          style: Theme.of(context).textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          data.last.effectiveScore.toStringAsFixed(1),
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: lineColor,
                                  ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Line Chart
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < data.length) {
                          final date = data[value.toInt()].date;
                          return Text(
                            '${date.day}/${date.month}',
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: data.asMap().entries.map((entry) {
                      return FlSpot(
                        entry.key.toDouble(),
                        entry.value.effectiveScore,
                      );
                    }).toList(),
                    isCurved: true,
                    color: lineColor,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: lineColor.withValues(alpha: 0.1),
                    ),
                  ),
                ],
                minY: 0,
                maxY: data
                        .map((d) => d.effectiveScore)
                        .reduce((a, b) => a > b ? a : b) *
                    1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _loadData(BioMechanicViewModel vm, int exerciseId) {
    vm.loadProgressiveOverloadData(
      exerciseId: exerciseId,
      from: _fromDate,
      to: _toDate,
    );
  }
}
