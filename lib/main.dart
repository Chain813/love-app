import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';
import 'core/theme/app_theme.dart';
import 'core/config/url_strategy.dart';
import 'core/di/service_locator.dart';
import 'services/leancloud_service.dart';
import 'package:provider/provider.dart';
import 'providers/user_provider.dart';
import 'providers/diary_provider.dart';
import 'services/sync_queue_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureGithubPagesUrlStrategy();
  await initializeDateFormatting('zh_CN');
  await Hive.initFlutter();
  await LeanCloudService.initialize();
  await initServiceLocator();
  SyncQueueManager().init();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()..loadUser()),
        ChangeNotifierProvider(create: (_) => DiaryProvider()..fetchInitial()),
      ],
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        builder: (context, child) => const ChongMiApp(),
      ),
    ),
  );
}
