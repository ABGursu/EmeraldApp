import 'package:flutter/material.dart';

import '../../data/models/tag_model.dart';

class TagFilterDropdown extends StatelessWidget {
  const TagFilterDropdown({
    super.key,
    required this.tags,
    required this.selectedTagIds,
    required this.onSelectionChanged,
    this.onTagLongPress,
    this.label = 'Tags',
  });

  final List<TagModel> tags;
  final Set<String> selectedTagIds;
  final ValueChanged<Set<String>> onSelectionChanged;
  final ValueChanged<TagModel>? onTagLongPress;
  final String label;

  @override
  Widget build(BuildContext context) {
    final summary = selectedTagIds.isEmpty
        ? 'All'
        : '${selectedTagIds.length} selected';

    return OutlinedButton(
      onPressed: () async {
        final result = await showModalBottomSheet<Set<String>>(
          context: context,
          isScrollControlled: true,
          builder: (context) => _TagFilterSheet(
            tags: tags,
            initialSelectedTagIds: selectedTagIds,
            onTagLongPress: onTagLongPress,
            label: label,
          ),
        );
        if (result != null) {
          onSelectionChanged(result);
        }
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_alt_outlined),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label: $summary',
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(Icons.arrow_drop_down),
        ],
      ),
    );
  }
}

class _TagFilterSheet extends StatefulWidget {
  const _TagFilterSheet({
    required this.tags,
    required this.initialSelectedTagIds,
    required this.onTagLongPress,
    required this.label,
  });

  final List<TagModel> tags;
  final Set<String> initialSelectedTagIds;
  final ValueChanged<TagModel>? onTagLongPress;
  final String label;

  @override
  State<_TagFilterSheet> createState() => _TagFilterSheetState();
}

class _TagFilterSheetState extends State<_TagFilterSheet> {
  late Set<String> _selectedTagIds;

  @override
  void initState() {
    super.initState();
    _selectedTagIds = Set<String>.from(widget.initialSelectedTagIds);
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.of(context).viewPadding.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomSafe),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${widget.label} Filter',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(_selectedTagIds),
                  child: const Text('Done'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: _selectedTagIds.isEmpty,
              onChanged: (_) {
                setState(() {
                  _selectedTagIds.clear();
                });
              },
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('All'),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: SingleChildScrollView(
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 3.2,
                  ),
                  itemCount: widget.tags.length,
                  itemBuilder: (context, index) {
                    final tag = widget.tags[index];
                    final isSelected = _selectedTagIds.contains(tag.id);
                    final tagColor = Color(tag.colorValue);
                    return InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onLongPress: widget.onTagLongPress == null
                          ? null
                          : () {
                              Navigator.of(context).pop(_selectedTagIds);
                              widget.onTagLongPress!(tag);
                            },
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedTagIds.remove(tag.id);
                          } else {
                            _selectedTagIds.add(tag.id);
                          }
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.outlineVariant,
                          ),
                          // Tint the whole button with tag color while keeping text readable.
                          color: tagColor.withValues(
                            alpha: isSelected ? 0.28 : 0.16,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: [
                            Checkbox(
                              value: isSelected,
                              onChanged: (_) {
                                setState(() {
                                  if (isSelected) {
                                    _selectedTagIds.remove(tag.id);
                                  } else {
                                    _selectedTagIds.add(tag.id);
                                  }
                                });
                              },
                            ),
                            Expanded(
                              child: Text(
                                tag.name,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white
                                          : Colors.black87,
                                      fontWeight: FontWeight.w600,
                                    ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
