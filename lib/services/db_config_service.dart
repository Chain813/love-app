import 'package:hive/hive.dart';
import '../config/keys.dart';

enum DbType {
  leancloud,
  supabase,
  webdav,
  local,
}

class DbConfigService {
  static const String _boxName = 'db_settings';
  static const String _keyDbType = 'db_type';

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

  static late Box _box;

  static Future<void> initialize() async {
    bool compactionStrategy(int total, int deleted) {
      // 当删除的记录数量大于 20，且废弃记录比例大于 30% 时，自动触发数据文件压缩整理
      return deleted > 20 && (deleted / total) > 0.3;
    }

    _box = await Hive.openBox(_boxName, compactionStrategy: compactionStrategy);

    // 预打开应用常用的数据 Box 提升后续读写性能（减少磁盘 I/O 阻塞时间）
    await Future.wait([
      Hive.openBox('user', compactionStrategy: compactionStrategy),
      Hive.openBox('diaries', compactionStrategy: compactionStrategy),
      Hive.openBox('wishes', compactionStrategy: compactionStrategy),
      Hive.openBox('anniversaries', compactionStrategy: compactionStrategy),
      Hive.openBox('period_logs', compactionStrategy: compactionStrategy),
      Hive.openBox('intimacy_logs', compactionStrategy: compactionStrategy),
    ]);
  }

  static DbType get currentDbType {
    final typeStr = _box.get(_keyDbType, defaultValue: DbType.supabase.name);
    return DbType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => DbType.supabase,
    );
  }

  static Future<void> setDbType(DbType type) async {
    await _box.put(_keyDbType, type.name);
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
      _box.get(_keyWebdavUrl, defaultValue: 'https://dav.jianguoyun.com/dav/');

  static String get webdavUser =>
      _box.get(_keyWebdavUser, defaultValue: '');

  static String get webdavPassword =>
      _box.get(_keyWebdavPwd, defaultValue: '');

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
