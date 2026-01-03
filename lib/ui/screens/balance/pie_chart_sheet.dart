import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../../ui/viewmodels/balance_view_model.dart';
import '../../../utils/date_formats.dart';

class PieChartSheet extends StatefulWidget {
  const PieChartSheet({super.key});

  @override
  State<PieChartSheet> createState() => _PieChartSheetState();
}

class _PieChartSheetState extends State<PieChartSheet> {
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _useCustomRange = false;

  @override
  void initState() {
    super.initState();
    // Initialize with fiscal month - will be set in build when ViewModel is available
    _fromDate = null;
    _toDate = null;
  }

  /// Initializes dates from fiscal month (called when ViewModel is available)
  void _initializeFromFiscalMonth(BalanceViewModel vm) {
    if (!_useCustomRange && (_fromDate == null || _toDate == null)) {
      final fiscal = vm.getCurrentFiscalMonth();
      _fromDate = fiscal.start;
      _toDate = fiscal.end;
    }
  }

  Future<void> _pickDateRange(BalanceViewModel vm) async {
    // Ensure dates are initialized from fiscal month if not set
    if (_fromDate == null || _toDate == null) {
      final fiscal = vm.getCurrentFiscalMonth();
      _fromDate = fiscal.start;
      _toDate = fiscal.end;
    }

    final range = await showDateRangePicker(
      context: context,
      initialDateRange: _fromDate != null && _toDate != null
          ? DateTimeRange(start: _fromDate!, end: _toDate!)
          : null,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (range != null && mounted) {
      setState(() {
        _fromDate = range.start;
        _toDate = range.end.add(const Duration(hours: 23, minutes: 59, seconds: 59));
        _useCustomRange = true;
      });
    }
  }

  Future<void> _exportChart() async {
    final vm = context.read<BalanceViewModel>();
    if (_fromDate == null || _toDate == null) return;

    final data = vm.expensesByTagInRange(_fromDate!, _toDate!);
    final total = data.values.fold<double>(0, (p, e) => p + e);

    final buffer = StringBuffer();
    buffer.writeln('Expenses by Tag Chart Export');
    buffer.writeln('Date Range: ${formatDate(_fromDate!)} - ${formatDate(_toDate!)}');
    buffer.writeln('Total Expenses: ${total.toStringAsFixed(2)}');
    buffer.writeln('');
    buffer.writeln('Breakdown:');
    for (final entry in data.entries) {
      final percent = total == 0 ? 0 : (entry.value / total) * 100;
      buffer.writeln('${entry.key.name}: ${entry.value.toStringAsFixed(2)} (${percent.toStringAsFixed(1)}%)');
    }

    final directory = await _getExportDir();
    final fileName =
        'chart_expenses_${_fromDate!.millisecondsSinceEpoch}_${_toDate!.millisecondsSinceEpoch}.txt';
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(buffer.toString());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chart exported to $fileName')),
      );
    }
  }

  void _resetToCurrentFiscalMonth(BalanceViewModel vm) {
    final fiscal = vm.getCurrentFiscalMonth();
    setState(() {
      _fromDate = fiscal.start;
      _toDate = fiscal.end;
      _useCustomRange = false;
    });
  }

  Future<Directory> _getExportDir() async {
    // Prefer a stable, human-readable path: /storage/emulated/0/Documents/EmeraldApp
    // Fallback to app-specific external, then internal documents.
    const preferredPath = '/storage/emulated/0/Documents/EmeraldApp';
    Directory dir = Directory(preferredPath);
    try {
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    } catch (_) {
      final externalDir = await getExternalStorageDirectory();
      final base = externalDir ?? await getApplicationDocumentsDirectory();
      dir = Directory('${base.path}/Documents/EmeraldApp');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BalanceViewModel>();
    
    // Initialize from fiscal month if not set
    _initializeFromFiscalMonth(vm);
    
    // Use custom range if set, otherwise use fiscal month
    final data = _fromDate != null && _toDate != null
        ? vm.expensesByTagInRange(_fromDate!, _toDate!)
        : vm.currentMonthExpensesByTag();
    final total = data.values.fold<double>(0, (p, e) => p + e);

    // Display range text - show fiscal period if not custom
    final rangeText = _useCustomRange && _fromDate != null && _toDate != null
        ? '${formatDate(_fromDate!)} - ${formatDate(_toDate!)}'
        : vm.getCurrentFiscalPeriodText();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Expenses by Tag',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        if (!_useCustomRange && _fromDate != null && _toDate != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Period: ${vm.getCurrentFiscalPeriodText()}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.date_range),
                      label: Text(rangeText),
                      onPressed: () => _pickDateRange(vm),
                    ),
                  ),
                  if (_useCustomRange) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Reset to current fiscal period',
                      onPressed: () => _resetToCurrentFiscalMonth(vm),
                    ),
                  ],
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.download),
                    tooltip: 'Export chart data',
                    onPressed: data.isEmpty ? null : _exportChart,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (data.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'No expenses in selected range',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 240,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 32,
                      sections: data.entries.map((e) {
                        final percent = total == 0 ? 0 : (e.value / total) * 100;
                        return PieChartSectionData(
                          value: e.value,
                          color: Color(e.key.colorValue),
                          title: '${percent.toStringAsFixed(1)}%',
                          titleStyle: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              if (data.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: data.entries.map((e) {
                    final percent = total == 0 ? 0 : (e.value / total) * 100;
                    return Chip(
                      avatar: CircleAvatar(
                        backgroundColor: Color(e.key.colorValue),
                      ),
                      label: Text('${e.key.name} - ${percent.toStringAsFixed(1)}%'),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Text(
                  'Total: ${total.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

