import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/supplement_view_model.dart';
import 'product_manager_screen.dart';
import 'supplement_logger_screen.dart';
import 'supplement_analytics_screen.dart';

/// Main hub screen for the Supplement & Prehab Logger module.
class SupplementHubScreen extends StatelessWidget {
  const SupplementHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supplement Logger'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Export to Text',
            onPressed: () => _showExportDialog(context),
          ),
        ],
      ),
      body: Consumer<SupplementViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Today's Quick Stats Card
                _buildTodaysStatsCard(context, vm),
                const SizedBox(height: 24),
                // Action Cards
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
                            title: 'Log Supplement',
                            subtitle: 'Record intake',
                            icon: Icons.add_circle_outline,
                            color: Theme.of(context).colorScheme.primary,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SupplementLoggerScreen(),
                              ),
                            ),
                          ),
                          _buildActionCard(
                            context,
                            title: 'My Products',
                            subtitle: '${vm.products.length} products',
                            icon: Icons.inventory_2_outlined,
                            color: Theme.of(context).colorScheme.secondary,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ProductManagerScreen(),
                              ),
                            ),
                          ),
                          _buildActionCard(
                            context,
                            title: 'Analytics',
                            subtitle: "Today's totals",
                            icon: Icons.analytics_outlined,
                            color: Colors.teal,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const SupplementAnalyticsScreen(),
                              ),
                            ),
                          ),
                          _buildActionCard(
                            context,
                            title: 'History',
                            subtitle: '${vm.logs.length} entries',
                            icon: Icons.history,
                            color: Colors.orange,
                            onTap: () => _showHistoryBottomSheet(context, vm),
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

  Widget _buildTodaysStatsCard(BuildContext context, SupplementViewModel vm) {
    final totals = vm.todaysTotals;
    final topIngredients = totals.entries.take(5).toList();

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
                  Icons.medication_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  "Today's Intake",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (topIngredients.isEmpty)
              Text(
                'No supplements logged today',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
              )
            else
              ...topIngredients.map((entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          '${_formatAmount(entry.value.amount)} ${entry.value.unit}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                    ),
                  )),
            if (totals.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '+${totals.length - 5} more ingredients',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                      ),
                ),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHistoryBottomSheet(BuildContext context, SupplementViewModel vm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
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
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Supplement History',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: vm.logs.isEmpty
                  ? Center(
                      child: Text(
                        'No supplements logged yet',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: vm.logs.length,
                      itemBuilder: (context, index) {
                        final log = vm.logs[index];
                        return _buildLogTile(context, log, vm);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogTile(
    BuildContext context,
    dynamic log,
    SupplementViewModel vm,
  ) {
    return Dismissible(
      key: Key(log.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Log'),
            content: const Text('Are you sure you want to delete this entry?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child:
                    const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => vm.deleteLog(log.id),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
          child: Icon(
            Icons.medication,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(log.productNameSnapshot),
        subtitle: Text(
          '${log.servingsCount} serving(s) • ${_formatDate(log.date)}',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: () => _showLogDetails(context, log, vm),
        ),
      ),
    );
  }

  void _showLogDetails(
    BuildContext context,
    dynamic log,
    SupplementViewModel vm,
  ) async {
    final details = await vm.getLogDetails(log.id);
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(log.productNameSnapshot),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${log.servingsCount} serving(s) • ${_formatDate(log.date)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Divider(),
              const Text(
                'Ingredients (Snapshot):',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...details.map((d) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(d.ingredientName),
                        Text('${_formatAmount(d.amountTotal)} ${d.unit}'),
                      ],
                    ),
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount == amount.roundToDouble()) {
      return amount.toInt().toString();
    }
    return amount.toStringAsFixed(2);
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showExportDialog(BuildContext mainContext) {
    final vm = mainContext.read<SupplementViewModel>();

    showDialog(
      context: mainContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Export Supplement Logs'),
        content: const Text(
          'Select a date range to export your supplement history to a text file.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();

              // Use main context for date picker
              if (!mainContext.mounted) return;

              // Show date range picker
              final range = await showDateRangePicker(
                context: mainContext,
                firstDate: DateTime(2000),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                initialDateRange: vm.logs.isNotEmpty
                    ? DateTimeRange(
                        start: vm.logs.last.date,
                        end: vm.logs.first.date,
                      )
                    : null,
              );

              if (range == null) return;

              // Check context again after date picker
              if (!mainContext.mounted) return;

              // Show loading indicator
              showDialog(
                context: mainContext,
                barrierDismissible: false,
                builder: (loadingContext) => const Center(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Exporting...'),
                        ],
                      ),
                    ),
                  ),
                ),
              );

              try {
                final path = await vm.exportLogs(
                  from: range.start,
                  to: range.end.add(const Duration(
                    hours: 23,
                    minutes: 59,
                    seconds: 59,
                  )), // inclusive end
                );

                if (!mainContext.mounted) return;
                Navigator.of(mainContext).pop(); // Close loading dialog

                if (mainContext.mounted) {
                  ScaffoldMessenger.of(mainContext).showSnackBar(
                    SnackBar(
                      content: Text('Export successful!\nFile: $path'),
                      duration: const Duration(seconds: 5),
                      action: SnackBarAction(
                        label: 'OK',
                        onPressed: () {},
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (!mainContext.mounted) return;
                Navigator.of(mainContext).pop(); // Close loading dialog

                if (mainContext.mounted) {
                  String errorMessage = 'Export failed: ';
                  if (e.toString().contains('Permission') ||
                      e.toString().contains('permission') ||
                      e.toString().contains('denied')) {
                    errorMessage +=
                        'Storage permission is required. Please enable it in settings.';
                  } else if (e.toString().contains('No such file') ||
                      e.toString().contains('Directory')) {
                    errorMessage +=
                        'Could not create directory. Using fallback directory.';
                  } else {
                    errorMessage += e.toString();
                  }

                  ScaffoldMessenger.of(mainContext).showSnackBar(
                    SnackBar(
                      content: Text(errorMessage),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 6),
                      action: SnackBarAction(
                        label: 'OK',
                        onPressed: () {},
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text('Select Range & Export'),
          ),
        ],
      ),
    );
  }
}
