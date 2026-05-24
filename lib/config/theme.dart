import 'package:flutter/material.dart';

class AppTheme {
  static const String light = 'light';
  static const String dark = 'dark';
  static const String pink = 'pink';

  static ThemeData getTheme(String themeName) {
    switch (themeName) {
      case dark:
        return _darkTheme;
      case pink:
        return _pinkTheme;
      case light:
      default:
        return _lightTheme;
    }
  }

  static final ThemeData _lightTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.pink,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.pink,
      brightness: Brightness.light,
    ),
    useMaterial3: true,
  );

  static final ThemeData _darkTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.pink,
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF121212),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.pink,
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
  );

  static final ThemeData _pinkTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.pink,
    scaffoldBackgroundColor: const Color(0xFFFFF0F5),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFFF69B4),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFFF69B4),
      brightness: Brightness.light,
    ),
    useMaterial3: true,
  );
}
