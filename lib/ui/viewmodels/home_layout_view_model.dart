import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../data/models/home_menu_item.dart';
import '../screens/balance/balance_screen.dart';
import '../screens/bio_mechanic/bio_mechanic_hub_screen.dart';
import '../screens/supplement/supplement_hub_screen.dart';
import '../screens/habit/habit_hub_screen.dart';
import '../screens/shopping/shopping_list_screen.dart';
import '../screens/calendar/calendar_hub_screen.dart';
import '../screens/backup/backup_settings_screen.dart';
import '../screens/home/home_layout_settings_screen.dart';

class HomeLayoutViewModel extends ChangeNotifier {
  List<HomeMenuItem> _menuItems = [];
  bool _isInitialized = false;

  List<HomeMenuItem> get menuItems => _menuItems;
  bool get isInitialized => _isInitialized;

  // Default menu items configuration
  static List<HomeMenuItem> getDefaultMenuItems() {
    return [
      HomeMenuItem(
        id: 'balance',
        title: 'Balance Sheet',
        icon: Icons.account_balance_wallet,
        color: const Color(0xFF00E5FF),
        buildScreen: () => const BalanceScreen(),
      ),
      HomeMenuItem(
        id: 'exercise',
        title: 'Exercise Logger',
        icon: Icons.fitness_center,
        color: const Color(0xFF00E5FF),
        buildScreen: () => const BioMechanicHubScreen(),
      ),
      HomeMenuItem(
        id: 'supplement',
        title: 'Supplement Logger',
        icon: Icons.medication_outlined,
        color: const Color(0xFF00E5FF),
        buildScreen: () => const SupplementHubScreen(),
      ),
      HomeMenuItem(
        id: 'habit',
        title: 'Habit Logger',
        icon: Icons.track_changes,
        color: const Color(0xFF00E5FF),
        buildScreen: () => const HabitHubScreen(),
      ),
      HomeMenuItem(
        id: 'shopping',
        title: 'Shopping List',
        icon: Icons.shopping_cart_outlined,
        color: const Color(0xFF00E5FF),
        buildScreen: () => const ShoppingListScreen(),
      ),
      HomeMenuItem(
        id: 'calendar',
        title: 'Calendar & Diary',
        icon: Icons.calendar_today,
        color: const Color(0xFF00E5FF),
        buildScreen: () => const CalendarHubScreen(),
      ),
      HomeMenuItem(
        id: 'backup',
        title: 'Backup & Restore',
        icon: Icons.backup,
        color: const Color(0xFF00E5FF),
        buildScreen: () => const BackupSettingsScreen(),
      ),
      HomeMenuItem(
        id: 'settings',
        title: 'Settings',
        icon: Icons.settings,
        color: const Color(0xFF00E5FF),
        isVisible: true, // Settings should always be visible (failsafe)
        buildScreen: () => const HomeLayoutSettingsScreen(),
      ),
    ];
  }

  /// Initialize the view model by loading saved preferences or using defaults
  Future<void> init() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    final defaultItems = getDefaultMenuItems();

    // Load saved order
    final savedOrderJson = prefs.getString('home_menu_order');
    List<String> savedOrder = [];
    if (savedOrderJson != null) {
      try {
        savedOrder = List<String>.from(jsonDecode(savedOrderJson));
      } catch (e) {
        // If parsing fails, use default order
        savedOrder = defaultItems.map((item) => item.id).toList();
      }
    } else {
      savedOrder = defaultItems.map((item) => item.id).toList();
    }

    // Load saved visibility
    final savedVisibilityJson = prefs.getString('home_menu_visibility');
    List<String> hiddenIds = [];
    if (savedVisibilityJson != null) {
      try {
        hiddenIds = List<String>.from(jsonDecode(savedVisibilityJson));
      } catch (e) {
        // If parsing fails, assume all visible
        hiddenIds = [];
      }
    }

    // Reconstruct menu items in saved order with saved visibility
    final Map<String, HomeMenuItem> itemsMap = {
      for (var item in defaultItems) item.id: item
    };

    _menuItems = savedOrder
        .map((id) {
          final item = itemsMap[id];
          if (item != null) {
            // Apply saved visibility (but ensure settings is always visible)
            final isVisible = id == 'settings' ? true : !hiddenIds.contains(id);
            return item.copyWith(isVisible: isVisible);
          }
          return null;
        })
        .whereType<HomeMenuItem>()
        .toList();

    // Add any new items that weren't in saved order (for future compatibility)
    for (var defaultItem in defaultItems) {
      if (!savedOrder.contains(defaultItem.id)) {
        final isVisible = defaultItem.id == 'settings'
            ? true
            : !hiddenIds.contains(defaultItem.id);
        _menuItems.add(defaultItem.copyWith(isVisible: isVisible));
      }
    }

    _isInitialized = true;
    notifyListeners();
  }

  /// Get visible menu items in current order
  List<HomeMenuItem> getVisibleItems() {
    return _menuItems.where((item) => item.isVisible).toList();
  }

  /// Move an item from oldIndex to newIndex
  Future<void> moveItem(int oldIndex, int newIndex) async {
    if (oldIndex < 0 ||
        oldIndex >= _menuItems.length ||
        newIndex < 0 ||
        newIndex >= _menuItems.length) {
      return;
    }

    final item = _menuItems.removeAt(oldIndex);
    _menuItems.insert(newIndex, item);

    await _saveOrder();
    notifyListeners();
  }

  /// Toggle visibility of an item (but never hide settings)
  Future<void> toggleVisibility(String id) async {
    if (id == 'settings') {
      // Settings should always be visible (failsafe)
      return;
    }

    final index = _menuItems.indexWhere((item) => item.id == id);
    if (index == -1) return;

    _menuItems[index] = _menuItems[index].copyWith(
      isVisible: !_menuItems[index].isVisible,
    );

    await _saveVisibility();
    notifyListeners();
  }

  /// Reset to default order and visibility
  Future<void> resetToDefault() async {
    _menuItems = getDefaultMenuItems();
    await _saveOrder();
    await _saveVisibility();
    notifyListeners();
  }

  /// Save the current order to SharedPreferences
  Future<void> _saveOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final order = _menuItems.map((item) => item.id).toList();
    await prefs.setString('home_menu_order', jsonEncode(order));
  }

  /// Save the current visibility to SharedPreferences
  Future<void> _saveVisibility() async {
    final prefs = await SharedPreferences.getInstance();
    final hiddenIds =
        _menuItems.where((item) => !item.isVisible).map((item) => item.id).toList();
    await prefs.setString('home_menu_visibility', jsonEncode(hiddenIds));
  }
}

