import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/transaction_model.dart';
import '../../../ui/viewmodels/balance_view_model.dart';
import '../../../utils/date_formats.dart';
import '../../widgets/color_coded_selector.dart';
import 'add_transaction_sheet.dart';
import 'pie_chart_sheet.dart';

class BalanceScreen extends StatelessWidget {
  const BalanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BalanceViewModel>(
      builder: (context, vm, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Balance Sheet'),
            actions: [
              IconButton(
                icon: const Icon(Icons.pie_chart),
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => const PieChartSheet(),
                ),
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
                    final path = await vm.exportTransactions(
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
              : Column(
                  children: [
                    _CurrentBalanceCard(balance: vm.currentBalance),
                    _BudgetOverviewCard(vm: vm),
                    Expanded(
                      child: _TransactionList(
                        grouped: vm.groupedByDate,
                        tags: vm.tags
                            .map((t) => ColorCodedItem(
                                  id: t.id,
                                  name: t.name,
                                  colorValue: t.colorValue,
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => ChangeNotifierProvider.value(
                value: vm,
                child: const AddTransactionSheet(),
              ),
            ),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}

class _BudgetOverviewCard extends StatelessWidget {
  const _BudgetOverviewCard({required this.vm});

  final BalanceViewModel vm;

  Color _getProgressColor(double percentage) {
    if (percentage <= 0.5) return Colors.green;
    if (percentage <= 0.79) return Colors.orange;
    if (percentage <= 1.0) return Colors.red;
    return Colors.red.shade900; // Dark red for over budget
  }

  @override
  Widget build(BuildContext context) {
    final totalExpenses = vm.currentMonthTotalExpenses;
    final budget = vm.currentBudget;
    final percentage = vm.budgetPercentage;
    final hasBudget = budget != null && budget > 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Monthly Budget',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () => _showEditBudgetDialog(context, vm, budget),
                tooltip: 'Edit Budget',
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (!hasBudget)
            Text(
              'No budget set for this month',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
            )
          else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${totalExpenses.toStringAsFixed(2)} / ${budget.toStringAsFixed(2)} TL',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  '${(percentage * 100).toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: _getProgressColor(percentage),
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor(percentage)),
              ),
            ),
            if (percentage > 1.0) ...[
              const SizedBox(height: 4),
              Text(
                'Over budget by ${((percentage - 1.0) * budget).toStringAsFixed(2)} TL',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.red.shade900,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  void _showEditBudgetDialog(
    BuildContext context,
    BalanceViewModel vm,
    double? currentBudget,
  ) {
    final controller = TextEditingController(
      text: currentBudget?.toStringAsFixed(2) ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Monthly Budget'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Budget Amount (TL)',
            border: OutlineInputBorder(),
            prefixText: '₺ ',
          ),
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final value = double.tryParse(controller.text);
              if (value != null && value > 0) {
                await vm.setBudget(value);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid positive amount'),
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _CurrentBalanceCard extends StatelessWidget {
  const _CurrentBalanceCard({required this.balance});

  final double balance;

  @override
  Widget build(BuildContext context) {
    final isPositive = balance >= 0;
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPositive
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
              : Theme.of(context).colorScheme.error.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Balance',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            balance.toStringAsFixed(2),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: isPositive
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

class _TransactionList extends StatelessWidget {
  const _TransactionList({
    required this.grouped,
    required this.tags,
  });

  final Map<DateTime, List<TransactionModel>> grouped;
  final List<ColorCodedItem> tags;

  @override
  Widget build(BuildContext context) {
    if (grouped.isEmpty) {
      return const Center(child: Text('No transactions yet'));
    }
    return ListView(
      padding: const EdgeInsets.all(12),
      children: grouped.entries.map((entry) {
        final date = entry.key;
        final transactions = entry.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                formatDate(date),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Card(
              child: Column(
                children: transactions
                    .map((tx) => _TransactionTile(
                          transaction: tx,
                          tagName: tags
                                  .firstWhere(
                                    (t) => t.id == tx.tagId,
                                    orElse: () => const ColorCodedItem(
                                        id: '', name: 'Untagged', colorValue: 0),
                                  )
                                  .name,
                          colorValue: tags
                              .firstWhere(
                                (t) => t.id == tx.tagId,
                                orElse: () => const ColorCodedItem(
                                    id: '', name: 'Untagged', colorValue: 0xFF9E9E9E),
                              )
                              .colorValue,
                          tags: tags,
                        ))
                    .toList(),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.transaction,
    required this.tagName,
    required this.colorValue,
    required this.tags,
  });

  final TransactionModel transaction;
  final String tagName;
  final int colorValue;
  final List<ColorCodedItem> tags;

  @override
  Widget build(BuildContext context) {
    final vm = context.read<BalanceViewModel>();
    final isExpense = transaction.amount < 0;
    return ListTile(
      leading: CircleAvatar(backgroundColor: Color(colorValue)),
      title: Text(tagName),
      subtitle: Text(transaction.note ?? ''),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isExpense ? '-' : '+'}${transaction.amount.abs().toStringAsFixed(2)}',
                style: TextStyle(
                  color: isExpense
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(formatDateTime(transaction.date)),
            ],
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                _editTransaction(context, vm, transaction);
              } else if (value == 'delete') {
                _deleteTransaction(context, vm, transaction);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _editTransaction(
    BuildContext context,
    BalanceViewModel vm,
    TransactionModel transaction,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: vm,
        child: AddTransactionSheet(transaction: transaction),
      ),
    );
  }

  void _deleteTransaction(
    BuildContext context,
    BalanceViewModel vm,
    TransactionModel transaction,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: Text(
          'Are you sure you want to delete this ${transaction.amount < 0 ? 'expense' : 'income'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await vm.deleteTransaction(transaction.id);
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

