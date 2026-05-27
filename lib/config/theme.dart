import 'package:flutter/material.dart';

/// 主题类型枚举
enum AppThemeType {
  pink,   // 温馨粉（默认）
  blue,   // 清新蓝
  green,  // 自然绿
  orange, // 活力橙
  purple, // 优雅紫
}

/// 主题配置 - 参考"不背单词"风格
class AppTheme {
  // 主题色映射
  static const Map<AppThemeType, Color> primaryColors = {
    AppThemeType.pink: Color(0xFFFF6B9D),
    AppThemeType.blue: Color(0xFF5AC8FA),
    AppThemeType.green: Color(0xFF34C759),
    AppThemeType.orange: Color(0xFFFF9500),
    AppThemeType.purple: Color(0xFFAF52DE),
  };

  // 主题名称
  static const Map<AppThemeType, String> themeNames = {
    AppThemeType.pink: '温馨粉',
    AppThemeType.blue: '清新蓝',
    AppThemeType.green: '自然绿',
    AppThemeType.orange: '活力橙',
    AppThemeType.purple: '优雅紫',
  };

  // 中性色
  static const Color backgroundColor = Color(0xFFF2F2F7);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color primaryTextColor = Color(0xFF1C1C1E);
  static const Color secondaryTextColor = Color(0xFF8E8E93);
  static const Color dividerColor = Color(0xFFC6C6C8);

  // 获取主题
  static ThemeData getTheme(AppThemeType type) {
    final primaryColor = primaryColors[type]!;

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        surface: cardColor,
        onPrimary: Colors.white,
        onSurface: primaryTextColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        foregroundColor: primaryTextColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: primaryTextColor,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 14,
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 14,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: secondaryTextColor,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
