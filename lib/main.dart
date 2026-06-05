import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';
import 'config/url_strategy.dart';
import 'services/leancloud_service.dart';

void main() async {
  configureGithubPagesUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('zh_CN');
  await Hive.initFlutter();
  await LeanCloudService.initialize();
  runApp(const ChongMiApp());
}
