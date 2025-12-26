import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../viewmodels/supplement_view_model.dart';

/// Screen showing today's total intake and analytics.
class SupplementAnalyticsScreen extends StatefulWidget {
  const SupplementAnalyticsScreen({super.key});

  @override
  State<SupplementAnalyticsScreen> createState() =>
      _SupplementAnalyticsScreenState();
}

class _SupplementAnalyticsScreenState extends State<SupplementAnalyticsScreen> {
  DateTime _selectedDate = DateTime.now();
  Map<String, ({double amount, String unit})>? _dayTotals;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDayTotals();
  }

  Future<void> _loadDayTotals() async {
    setState(() => _loading = true);

    final vm = context.read<SupplementViewModel>();
    final startOfDay = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final endOfDay = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      23,
      59,
      59,
      999,
    );

    final totals = await vm.getTotalIntake(from: startOfDay, to: endOfDay);

    setState(() {
      _dayTotals = totals;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Date Selector
          _buildDateSelector(),
          const Divider(height: 1),

          // Content
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _dayTotals == null || _dayTotals!.isEmpty
                    ? _buildEmptyState()
                    : _buildAnalyticsContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    final isToday = _isSameDay(_selectedDate, DateTime.now());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.subtract(const Duration(days: 1));
              });
              _loadDayTotals();
            },
            icon: const Icon(Icons.chevron_left),
          ),
          GestureDetector(
            onTap: _pickDate,
            child: Column(
              children: [
                Text(
                  isToday
                      ? 'Today'
                      : '${_selectedDate.day.toString().padLeft(2, '0')}.${_selectedDate.month.toString().padLeft(2, '0')}.${_selectedDate.year}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (!isToday)
                  Text(
                    _getWeekdayName(_selectedDate.weekday),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: isToday
                ? null
                : () {
                    setState(() {
                      _selectedDate =
                          _selectedDate.add(const Duration(days: 1));
                    });
                    _loadDayTotals();
                  },
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No data for this day',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Log some supplements to see analytics',
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

  Widget _buildAnalyticsContent() {
    // Group by unit type for display
    final byUnit = <String, List<MapEntry<String, ({double amount, String unit})>>>{};
    for (final entry in _dayTotals!.entries) {
      final unit = entry.value.unit;
      byUnit.putIfAbsent(unit, () => []).add(entry);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Card
          _buildSummaryCard(),
          const SizedBox(height: 24),

          // Chart (if enough data)
          if (_dayTotals!.length >= 3) ...[
            Text(
              'Top Ingredients',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildChart(),
            const SizedBox(height: 24),
          ],

          // Detailed List by Unit
          ...byUnit.entries.map((unitGroup) {
            return _buildUnitSection(unitGroup.key, unitGroup.value);
          }),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final totalIngredients = _dayTotals!.length;

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
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
              child: Icon(
                Icons.medication,
                size: 30,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$totalIngredients Ingredients',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    'logged on this day',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    // Get top 5 ingredients by amount (normalized)
    final entries = _dayTotals!.entries.toList()
      ..sort((a, b) => b.value.amount.compareTo(a.value.amount));
    final top5 = entries.take(5).toList();

    final colors = [
      Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.secondary,
      Colors.teal,
      Colors.orange,
      Colors.purple,
    ];

    return SizedBox(
      height: 200,
      child: Row(
        children: [
          // Pie Chart
          Expanded(
            child: PieChart(
              PieChartData(
                sections: top5.asMap().entries.map((entry) {
                  final index = entry.key;
                  final data = entry.value;
                  return PieChartSectionData(
                    color: colors[index % colors.length],
                    value: data.value.amount,
                    title: '',
                    radius: 50,
                  );
                }).toList(),
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
          // Legend
          SizedBox(
            width: 150,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: top5.asMap().entries.map((entry) {
                final index = entry.key;
                final data = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: colors[index % colors.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          data.key,
                          style: Theme.of(context).textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitSection(
    String unit,
    List<MapEntry<String, ({double amount, String unit})>> entries,
  ) {
    // Sort by amount descending
    entries.sort((a, b) => b.value.amount.compareTo(a.value.amount));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Measured in $unit',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: entries.asMap().entries.map((entry) {
              final index = entry.key;
              final data = entry.value;
              return Column(
                children: [
                  ListTile(
                    dense: true,
                    title: Text(data.key),
                    trailing: Text(
                      '${_formatAmount(data.value.amount)} $unit',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (index < entries.length - 1)
                    const Divider(height: 1, indent: 16, endIndent: 16),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _loadDayTotals();
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

  String _formatAmount(double amount) {
    if (amount == amount.roundToDouble()) {
      return amount.toInt().toString();
    }
    if (amount < 1) {
      return amount.toStringAsFixed(4);
    }
    return amount.toStringAsFixed(2);
  }
}

