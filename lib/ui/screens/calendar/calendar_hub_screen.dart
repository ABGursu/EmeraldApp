import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/calendar_tag_model.dart';
import '../../../ui/viewmodels/calendar_view_model.dart';
import 'all_events_list_screen.dart';
import 'calendar_view_screen.dart';
import 'daily_view_screen.dart';

class CalendarHubScreen extends StatefulWidget {
  const CalendarHubScreen({super.key});

  @override
  State<CalendarHubScreen> createState() => _CalendarHubScreenState();
}

class _CalendarHubScreenState extends State<CalendarHubScreen> {
  int _currentIndex = 0;
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    // Ensure events are loaded when screen is first displayed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasInitialized) {
        final vm = context.read<CalendarViewModel>();
        if (vm.events.isEmpty && !vm.isLoading) {
          vm.init();
        }
        _hasInitialized = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CalendarViewModel>(
      builder: (context, vm, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Calendar & Diary'),
            actions: [
              IconButton(
                icon: const Icon(Icons.label),
                tooltip: 'Manage Tags',
                onPressed: () {
                  _showTagManager(context, vm);
                },
              ),
              IconButton(
                icon: const Icon(Icons.event),
                tooltip: 'All Events',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AllEventsListScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          body: IndexedStack(
            index: _currentIndex,
            children: const [
              DailyViewScreen(),
              CalendarViewScreen(),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.today),
                label: 'Daily',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_month),
                label: 'Calendar',
              ),
            ],
          ),
        );
      },
    );
  }

  void _showTagManager(BuildContext context, CalendarViewModel vm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: vm,
        child: const _CalendarTagManagerSheet(),
      ),
    );
  }
}

class _CalendarTagManagerSheet extends StatelessWidget {
  const _CalendarTagManagerSheet();

  @override
  Widget build(BuildContext context) {
    return Consumer<CalendarViewModel>(
      builder: (context, vm, _) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Calendar Tags',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (vm.tags.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No tags yet. Create one when adding an event.'),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: vm.tags.length,
                    itemBuilder: (context, index) {
                      final tag = vm.tags[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Color(tag.colorValue),
                          radius: 12,
                        ),
                        title: Text(tag.name),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showEditTagDialog(context, vm, tag),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _showDeleteTagDialog(context, vm, tag),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Create New Tag'),
                    onPressed: () => _showCreateTagDialog(context, vm),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCreateTagDialog(BuildContext context, CalendarViewModel vm) async {
    String? tagName;
    int selectedColor = Colors.blue.toARGB32();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        final nameController = TextEditingController();
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Create Tag'),
            content: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Tag Name',
                        border: OutlineInputBorder(),
                      ),
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      onChanged: (value) => tagName = value,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Select Color',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        Colors.blue,
                        Colors.red,
                        Colors.green,
                        Colors.orange,
                        Colors.purple,
                        Colors.teal,
                        Colors.pink,
                        Colors.amber,
                      ].map((color) {
                        return GestureDetector(
                          onTap: () => setState(() => selectedColor = color.toARGB32()),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selectedColor == color.toARGB32()
                                    ? Colors.black
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  if (nameController.text.trim().isNotEmpty) {
                    tagName = nameController.text.trim();
                    Navigator.pop(context, true);
                  }
                },
                child: const Text('Create'),
              ),
            ],
          ),
        );
      },
    );

    if (result == true && tagName != null && tagName!.isNotEmpty) {
      await vm.createTag(tagName!, selectedColor);
      if (context.mounted) {
        Navigator.pop(context); // Close tag manager
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tag "$tagName" created')),
        );
      }
    }
  }

  void _showEditTagDialog(
    BuildContext context,
    CalendarViewModel vm,
    CalendarTagModel tag,
  ) async {
    String? tagName;
    int selectedColor = tag.colorValue;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        final nameController = TextEditingController(text: tag.name);
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Edit Tag'),
            content: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Tag Name',
                        border: OutlineInputBorder(),
                      ),
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      onChanged: (value) => tagName = value,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Select Color',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        Colors.blue,
                        Colors.red,
                        Colors.green,
                        Colors.orange,
                        Colors.purple,
                        Colors.teal,
                        Colors.pink,
                        Colors.amber,
                      ].map((color) {
                        return GestureDetector(
                          onTap: () => setState(() => selectedColor = color.toARGB32()),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selectedColor == color.toARGB32()
                                    ? Colors.black
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  if (nameController.text.trim().isNotEmpty) {
                    tagName = nameController.text.trim();
                    Navigator.pop(context, true);
                  }
                },
                child: const Text('Update'),
              ),
            ],
          ),
        );
      },
    );

    if (result == true && tagName != null && tagName!.isNotEmpty) {
      final updated = tag.copyWith(
        name: tagName!,
        colorValue: selectedColor,
      );
      await vm.updateTag(updated);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tag "$tagName" updated')),
        );
      }
    }
  }

  void _showDeleteTagDialog(
    BuildContext context,
    CalendarViewModel vm,
    CalendarTagModel tag,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tag'),
        content: Text('Are you sure you want to delete "${tag.name}"? Events using this tag will have their tag removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await vm.deleteTag(tag.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Tag "${tag.name}" deleted')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

