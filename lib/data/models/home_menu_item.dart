import 'package:flutter/material.dart';

/// Model representing a menu item on the home screen
class HomeMenuItem {
  final String id;
  final String title;
  final IconData icon;
  final Color color;
  final bool isVisible;
  final Widget Function() buildScreen; // Function to build the target screen

  const HomeMenuItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    this.isVisible = true,
    required this.buildScreen,
  });

  HomeMenuItem copyWith({
    String? id,
    String? title,
    IconData? icon,
    Color? color,
    bool? isVisible,
    Widget Function()? buildScreen,
  }) {
    return HomeMenuItem(
      id: id ?? this.id,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isVisible: isVisible ?? this.isVisible,
      buildScreen: buildScreen ?? this.buildScreen,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'icon': icon.codePoint,
        'color': color.toARGB32(), // Using toARGB32() for explicit conversion
        'isVisible': isVisible,
      };

  factory HomeMenuItem.fromMap(
    Map<String, dynamic> map,
    Widget Function() buildScreen,
  ) {
    return HomeMenuItem(
      id: map['id'] as String,
      title: map['title'] as String,
      icon: IconData(map['icon'] as int, fontFamily: 'MaterialIcons'),
      color: Color(map['color'] as int),
      isVisible: map['isVisible'] as bool? ?? true,
      buildScreen: buildScreen,
    );
  }
}
