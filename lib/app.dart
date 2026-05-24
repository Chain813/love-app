import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'providers/theme_provider.dart';

class ChongMiApp extends StatelessWidget {
  const ChongMiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: '虫米',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.getTheme(themeProvider.currentTheme),
            home: const Scaffold(
              body: Center(
                child: Text('虫米 - 情侣恋爱记录'),
              ),
            ),
          );
        },
      ),
    );
  }
}
