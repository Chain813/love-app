import 'package:flutter/material.dart';
import '../config/theme.dart';

class ThemeProvider extends ChangeNotifier {
  String _currentTheme = AppTheme.light;

  String get currentTheme => _currentTheme;

  void setTheme(String theme) {
    if (_currentTheme != theme) {
      _currentTheme = theme;
      notifyListeners();
    }
  }
}
