import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive/hive.dart';
import '../core/config/keys.dart';

enum DbType {
  leancloud,
  supabase,
  webdav,
  local,
}

class DbConfigService {
  static const String _boxName = 'db_settings';
  static const String _keyDbType = 'db_type';
  static const String defaultWebdavUrl =
      'https://love-app-webdav-proxy.chenlichong813.workers.dev/dav/';
  static const String _legacyJianguoyunWebdavUrl =
      'https://dav.jianguoyun.com/dav/';

  // LeanCloud Config Keys
  static const String _keyLcId = 'lc_id';
  static const String _keyLcKey = 'lc_key';
  static const String _keyLcUrl = 'lc_url';

  // Supabase Config Keys
  static const String _keySupaUrl = 'supa_url';
  static const String _keySupaKey = 'supa_key';

  // WebDAV Config Keys
  static const String _keyWebdavUrl = 'webdav_url';
  static const String _keyWebdavUser = 'webdav_user';
  static const String _keyWebdavPwd = 'webdav_pwd';
  static const List<String> _criticalStartupBoxNames = [
    'user',
    'settings',
  ];
  static const List<String> _deferredStartupBoxNames = [
    'diaries',
    'wishes',
    'anniversaries',
    'period_logs',
    'intimacy_logs',
    'daily_quote_cache',
    'gifts',
  ];

  static late Box _box;

  static Future<void> initialize() async {
    bool compactionStrategy(int total, int deleted) {
      // 当删除的记录数量大于 20，且废弃记录比例大于 30% 时，自动触发数据文件压缩整理
      return deleted > 20 && (deleted / total) > 0.3;
    }

    _box = await _openBox(_boxName, compactionStrategy);
    await _migrateLegacyWebdavEndpoint();

    for (final boxName in _criticalStartupBoxNames) {
      await _openBox(boxName, compactionStrategy);
    }

    if (kIsWeb) {
      unawaited(
          _openDeferredStartupBoxes(compactionStrategy).catchError((_) {}));
    } else {
      await _openDeferredStartupBoxes(compactionStrategy);
    }
  }

  static Future<void> _openDeferredStartupBoxes(
    bool Function(int total, int deleted) compactionStrategy,
  ) async {
    // Web IndexedDB can stall when many object stores are opened during first paint.
    for (final boxName in _deferredStartupBoxNames) {
      await _openBox(boxName, compactionStrategy);
    }
  }

  static Future<Box> _openBox(
    String boxName,
    bool Function(int total, int deleted) compactionStrategy,
  ) async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box(boxName);
    }
    return Hive.openBox(boxName, compactionStrategy: compactionStrategy);
  }

  static Future<void> _migrateLegacyWebdavEndpoint() async {
    final savedUrl = _box.get(_keyWebdavUrl) as String?;
    if (savedUrl == _legacyJianguoyunWebdavUrl) {
      await _box.put(_keyWebdavUrl, defaultWebdavUrl);
    }
  }

  static DbType get currentDbType {
    final typeStr = _box.get(_keyDbType, defaultValue: DbType.webdav.name);
    final type = DbType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => DbType.webdav,
    );
    if (type == DbType.supabase || type == DbType.leancloud) {
      return DbType.webdav;
    }
    return type;
  }

  static Future<void> setDbType(DbType type) async {
    final effectiveType = type == DbType.supabase || type == DbType.leancloud
        ? DbType.webdav
        : type;
    await _box.put(_keyDbType, effectiveType.name);
  }

  // --- LeanCloud Getters/Setters ---
  static String get leanCloudAppId =>
      _box.get(_keyLcId, defaultValue: AppKeys.leanCloudAppId);

  static String get leanCloudAppKey =>
      _box.get(_keyLcKey, defaultValue: AppKeys.leanCloudAppKey);

  static String get leanCloudServerUrl =>
      _box.get(_keyLcUrl, defaultValue: AppKeys.leanCloudServerUrl);

  static Future<void> saveLeanCloudConfig({
    required String appId,
    required String appKey,
    required String serverUrl,
  }) async {
    await _box.put(_keyLcId, appId);
    await _box.put(_keyLcKey, appKey);
    await _box.put(_keyLcUrl, serverUrl);
  }

  // --- Supabase Getters/Setters ---
  static String get supabaseUrl =>
      _box.get(_keySupaUrl, defaultValue: AppKeys.supabaseUrl);

  static String get supabaseAnonKey =>
      _box.get(_keySupaKey, defaultValue: AppKeys.supabaseAnonKey);

  static Future<void> saveSupabaseConfig({
    required String url,
    required String anonKey,
  }) async {
    await _box.put(_keySupaUrl, url);
    await _box.put(_keySupaKey, anonKey);
  }

  // --- WebDAV Getters/Setters ---
  static String get webdavUrl =>
      _box.get(_keyWebdavUrl, defaultValue: defaultWebdavUrl);

  static String get webdavUser => _box.get(_keyWebdavUser, defaultValue: '');

  static String get webdavPassword => _box.get(_keyWebdavPwd, defaultValue: '');

  static Future<void> saveWebdavConfig({
    required String url,
    required String user,
    required String password,
  }) async {
    await _box.put(_keyWebdavUrl, url);
    await _box.put(_keyWebdavUser, user);
    await _box.put(_keyWebdavPwd, password);
  }
}
