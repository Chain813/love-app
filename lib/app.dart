import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import './core/config/theme.dart';
import './core/di/service_locator.dart';
import './core/router/router.dart';
import './features/settings/providers/theme_provider.dart';
import './features/auth/providers/auth_provider.dart';
import './features/location/providers/location_provider.dart';

class ChongMiApp extends StatefulWidget {
  const ChongMiApp({super.key});

  @override
  State<ChongMiApp> createState() => _ChongMiAppState();
}

class _ChongMiAppState extends State<ChongMiApp> {
  late final ThemeProvider _themeProvider;
  late final AuthProvider _authProvider;
  late final LocationProvider _locationProvider;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _themeProvider = sl<ThemeProvider>();
    _authProvider = sl<AuthProvider>()..checkLoginStatus();
    _locationProvider = sl<LocationProvider>()..checkPermission();
    _router = createRouter(_authProvider);
  }

  @override
  void dispose() {
    _router.dispose();
    _themeProvider.dispose();
    _authProvider.dispose();
    _locationProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _themeProvider),
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider.value(value: _locationProvider),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp.router(
            title: '虫米',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.getTheme(themeProvider.currentTheme),
            routerConfig: _router,
          );
        },
      ),
    );
  }
}
