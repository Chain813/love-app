import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:chongmi/core/config/theme.dart';
import 'package:chongmi/features/settings/providers/theme_provider.dart';
import 'package:chongmi/features/auth/providers/auth_provider.dart';
import 'package:chongmi/features/auth/screens/login_screen.dart';

void main() {
  setUpAll(() async {
    Hive.init('./test_hive');
  });

  testWidgets('Login screen should render', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: MaterialApp(
          theme: AppTheme.getTheme(AppThemeType.pink),
          home: const LoginScreen(),
        ),
      ),
    );

    // 等待动画
    await tester.pump(const Duration(seconds: 2));

    // 应该看到副标题
    expect(find.text('记录恋爱的点点滴滴'), findsOneWidget);
    // 应该看到品牌名
    expect(find.text('虫米'), findsOneWidget);
  });
}
