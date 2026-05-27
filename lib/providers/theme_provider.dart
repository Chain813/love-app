import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../config/theme.dart';

/// 主题状态管理 Provider
class ThemeProvider extends ChangeNotifier {
  static const String _themeBox = 'settings';
  static const String _themeKey = 'theme_type';

  AppThemeType _currentTheme = AppThemeType.pink;

  AppThemeType get currentTheme => _currentTheme;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final box = await Hive.openBox(_themeBox);
      final themeIndex = box.get(_themeKey, defaultValue: 0) as int;
      if (themeIndex >= 0 && themeIndex < AppThemeType.values.length) {
        _currentTheme = AppThemeType.values[themeIndex];
        notifyListeners();
      }
    } catch (e) {
      // 默认使用粉色主题
      _currentTheme = AppThemeType.pink;
    }
  }

  Future<void> setTheme(AppThemeType theme) async {
    if (_currentTheme == theme) return;
    _currentTheme = theme;
    notifyListeners();

    try {
      final box = await Hive.openBox(_themeBox);
      await box.put(_themeKey, theme.index);
    } catch (e) {
      // 静默处理存储错误
    }
  }
}
