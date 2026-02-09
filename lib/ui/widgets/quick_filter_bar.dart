import 'package:flutter/material.dart';

/// A reusable horizontal scrollable filter bar with ChoiceChips
/// Supports filtering by category (tags, goals, body parts) with long-press edit
class QuickFilterBar<T> extends StatelessWidget {
  const QuickFilterBar({
    super.key,
    required this.items,
    required this.selectedItem,
    required this.onItemSelected,
    this.onItemLongPress,
    this.getItemId,
    this.getItemName,
    this.getItemColor,
    this.showAllOption = true,
    this.allOptionLabel = 'All',
  });

  /// List of items to display as chips
  final List<T> items;

  /// Currently selected item (null means "All")
  final T? selectedItem;

  /// Callback when a chip is tapped
  final void Function(T?) onItemSelected;

  /// Callback when a chip is long-pressed (for editing)
  final void Function(T)? onItemLongPress;

  /// Function to extract ID from item (for comparison)
  final String Function(T)? getItemId;

  /// Function to extract display name from item
  final String Function(T)? getItemName;

  /// Function to extract color from item (optional)
  final int? Function(T)? getItemColor;

  /// Whether to show "All" option as first chip
  final bool showAllOption;

  /// Label for "All" option
  final String allOptionLabel;

  @override
  Widget build(BuildContext context) {
    final itemCount = items.length + (showAllOption ? 1 : 0);
    
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          // "All" option is first if enabled
          if (showAllOption && index == 0) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(
                  allOptionLabel,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                selected: selectedItem == null,
                onSelected: (selected) {
                  if (selected) {
                    onItemSelected(null);
                  }
                },
              ),
            );
          }
          
          // Regular items
          final itemIndex = showAllOption ? index - 1 : index;
          final item = items[itemIndex];
          final isSelected = _isItemSelected(item);
          final itemName = getItemName?.call(item) ?? item.toString();
          final colorValue = getItemColor?.call(item);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onLongPress: onItemLongPress != null
                  ? () => onItemLongPress!(item)
                  : null,
              child: ChoiceChip(
                label: Text(
                  itemName,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                selected: isSelected,
                onSelected: (selected) {
                  onItemSelected(selected ? item : null);
                },
                avatar: colorValue != null
                    ? CircleAvatar(
                        backgroundColor: Color(colorValue),
                        radius: 8,
                      )
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }

  bool _isItemSelected(T item) {
    if (selectedItem == null) return false;
    if (getItemId != null) {
      return getItemId!(item) == getItemId!(selectedItem as T);
    }
    return item == selectedItem;
  }
}

