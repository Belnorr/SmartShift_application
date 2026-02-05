// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';

class AppThemeData {
  final Color primary;
  final Color surface;
  final Color text;
  final Color muted;

  // ✅ ADD THIS
  final Color primarySoft;

  const AppThemeData({
    required this.primary,
    required this.surface,
    required this.text,
    required this.muted,

    // ✅ ADD THIS
    required this.primarySoft,
  });
}

class AppTheme extends InheritedWidget {
  final AppThemeData data;

  const AppTheme({
    super.key,
    required this.data,
    required super.child,
  });

  static AppThemeData of(BuildContext context) {
    final theme = context.dependOnInheritedWidgetOfExactType<AppTheme>();
    if (theme == null) {
      // Fallback so your app doesn't crash if you forget to wrap AppTheme at root
      const primary = Color.fromARGB(255, 24, 37, 78);

      return const AppThemeData(
        primary: Color.fromARGB(255, 75, 89, 134),
        surface: Color(0xFFF7F7FB),
        text: Color.fromARGB(255, 12, 12, 26),
        muted: Color(0xFF6B7280),
        primarySoft: Color.fromARGB(31, 92, 129, 231), // ~12% opacity of primary
      );
    }
    return theme.data;
  }

  @override
  bool updateShouldNotify(AppTheme oldWidget) => oldWidget.data != data;
}

/// Optional convenience so you can do: final ss = context.ss;
extension AppThemeContextX on BuildContext {
  AppThemeData get ss => AppTheme.of(this);
}
