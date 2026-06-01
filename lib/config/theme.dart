import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';

/// 主题类型枚举
enum AppThemeType {
  pink,   // 温馨粉（默认）
  blue,   // 清新蓝
  green,  // 自然绿
  orange, // 活力橙
  purple, // 优雅紫
}

/// 主题配置 - 高级视觉设计系统
class AppTheme {
  // 主题色映射
  static const Map<AppThemeType, Color> primaryColors = {
    AppThemeType.pink: Color(0xFFFF6B9D),
    AppThemeType.blue: Color(0xFF5AC8FA),
    AppThemeType.green: Color(0xFF34C759),
    AppThemeType.orange: Color(0xFFFF9500),
    AppThemeType.purple: Color(0xFFAF52DE),
  };

  // 渐变色对 — 用于 Dashboard、按钮、装饰条等
  static const Map<AppThemeType, List<Color>> gradientColors = {
    AppThemeType.pink: [Color(0xFFFF6B9D), Color(0xFFFF8EB3)],
    AppThemeType.blue: [Color(0xFF5AC8FA), Color(0xFF7DD3FC)],
    AppThemeType.green: [Color(0xFF34C759), Color(0xFF6EE7A0)],
    AppThemeType.orange: [Color(0xFFFF9500), Color(0xFFFBBF24)],
    AppThemeType.purple: [Color(0xFFAF52DE), Color(0xFFC084FC)],
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

  // 获取主题渐变
  static LinearGradient getGradient(AppThemeType type, {AlignmentGeometry begin = Alignment.topLeft, AlignmentGeometry end = Alignment.bottomRight}) {
    final colors = gradientColors[type]!;
    return LinearGradient(begin: begin, end: end, colors: colors);
  }

  // 获取主题
  static ThemeData getTheme(AppThemeType type) {
    final primaryColor = primaryColors[type]!;
    final gradient = gradientColors[type]!;

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        primaryContainer: gradient[1],
        surface: cardColor,
        onPrimary: Colors.white,
        onSurface: primaryTextColor,
        outline: dividerColor,
        shadow: const Color(0x0D000000),
      ),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white.withOpacity(0.85),
        foregroundColor: primaryTextColor,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        titleTextStyle: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: primaryTextColor,
          letterSpacing: 0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: primaryColor.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 14,
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor.withOpacity(0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 14,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF2F2F7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
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
        elevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: 4,
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        surfaceTintColor: Colors.transparent,
      ),
      // 全平台统一使用 iOS 风格页面转场
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
