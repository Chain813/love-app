import 'dart:convert';
import 'dart:math';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'sync_queue_manager.dart';
import 'package:geolocator/geolocator.dart';
import 'db_config_service.dart';
import '../core/utils/sync_merge.dart';
import 'webdav/webdav_client.dart';
import '../features/diary/models/diary.dart';

class _InvalidPairDataException implements Exception {
  const _InvalidPairDataException(this.message);

  final String message;

  @override
  String toString() => message;
}

class WebdavService {
  static const String roleUser1 = 'user1';
  static const String roleUser2 = 'user2';
  static const String _keyCurrentUser = 'current_user';
  static const String _keyRelation = 'couple_relation';
  static const String _keyRole = 'webdav_role';
  static const String _keyDeviceId = 'webdav_device_id';
  static const String _keyLocations = 'webdav_locations';
  static const String _keyLocationHistory = 'webdav_location_history';
  static const String _keyPeriodRecords = 'period_records';

  static Future<String> _getDeviceId() async {
    final box = Hive.box('user');
    final existing = box.get(_keyDeviceId) as String?;
    if (existing != null && existing.isNotEmpty) return existing;

    final deviceId =
        'webdav_device_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999999)}';
    await box.put(_keyDeviceId, deviceId);
    return deviceId;
  }

  static String? _roleDeviceId(Map<String, dynamic> relation, String role) {
    return relation['${role}_device_id'] as String?;
  }

  static bool _isRoleAvailableForDevice(
    Map<String, dynamic> relation,
    String role,
    String deviceId,
  ) {
    final boundDeviceId = _roleDeviceId(relation, role);
    return boundDeviceId == null ||
        boundDeviceId.isEmpty ||
        boundDeviceId == deviceId;
  }

  static String? _roleForDevice(
    Map<String, dynamic> relation,
    String deviceId,
  ) {
    if (_roleDeviceId(relation, roleUser1) == deviceId) return roleUser1;
    if (_roleDeviceId(relation, roleUser2) == deviceId) return roleUser2;
    return null;
  }

  static Map<String, dynamic> _pendingUser(String username, String status) {
    return {
      'objectId': 'webdav_pending',
      'username': username,
      'nickname': username,
      'invite_code': '',
      'status': status,
      'gender': 'unknown',
      'couple_id': null,
      'partner_id': null,
      'sessionToken': 'webdav_token_mock',
    };
  }

  static Map<String, dynamic> _userForRole(
    String username,
    String role,
    Map<String, dynamic> relation,
  ) {
    final isUser1 = role == roleUser1;
    final objectId = isUser1 ? relation['user1_id'] : relation['user2_id'];
    final partnerId = isUser1 ? relation['user2_id'] : relation['user1_id'];
    return {
      'objectId': objectId,
      'username': username,
      'nickname': isUser1 ? relation['user1_name'] : relation['user2_name'],
      'invite_code': '',
      'status': 'paired',
      'gender': isUser1 ? relation['user1_gender'] : relation['user2_gender'],
      'couple_id': relation['couple_id'],
      'partner_id': partnerId,
      'webdav_role': role,
      'sessionToken': 'webdav_token_mock',
    };
  }

  static Future<void> _syncCurrentUserPairing(
    Map<String, dynamic> user,
    Map<String, dynamic>? relation,
  ) async {
    final box = Hive.box('user');
    final username = (user['username'] as String?) ?? WebdavClient.username;
    if (relation == null) {
      await box.delete(_keyRelation);
      await box.delete(_keyRole);
      await box.put(_keyCurrentUser, _pendingUser(username, 'setup_required'));
      return;
    }

    final deviceId = await _getDeviceId();
    var role = box.get(_keyRole) as String?;
    final deviceRole = _roleForDevice(relation, deviceId);
    if (role == null && deviceRole != null) {
      role = deviceRole;
      await box.put(_keyRole, role);
    }

    if (role != roleUser1 && role != roleUser2) {
      await box.put(_keyRelation, relation);
      await box.put(_keyCurrentUser, _pendingUser(username, 'role_required'));
      return;
    }

    if (!_isRoleAvailableForDevice(relation, role!, deviceId)) {
      await box.delete(_keyRole);
      await box.put(_keyRelation, relation);
      await box.put(_keyCurrentUser, _pendingUser(username, 'role_required'));
      return;
    }

    final roleDeviceKey = '${role}_device_id';
    final shouldUploadClaim = (relation[roleDeviceKey] as String?) != deviceId;
    relation[roleDeviceKey] = deviceId;
    relation['updatedAt'] = DateTime.now().toIso8601String();
    if (shouldUploadClaim) {
      await WebdavClient.safeUploadWithRetry('couple_relation.json', relation);
    }
    await box.put(_keyRole, role);
    await box.put(_keyRelation, relation);
    await box.put(_keyCurrentUser, _userForRole(username, role, relation));
  }

  /// 验证 WebDAV 连接并登录
  static Future<Map<String, dynamic>> registerOrLogin(
      String username, String password) async {
    try {
      final loginUsername = username.trim();
      final loginPassword = password.trim();
      if (loginUsername.isEmpty || loginPassword.isEmpty) {
        throw Exception('请输入坚果云账号和应用授权密码');
      }

      final webdavUrl = WebdavClient.webdavUrl;
      final loginHeaders = WebdavClient.buildHeaders(loginUsername, loginPassword);

      // 验证连接：发送 Propfind 请求到根目录或读取测试
      final client = http.Client();
      try {
        final req = http.Request('PROPFIND', Uri.parse(webdavUrl))
          ..headers.addAll(loginHeaders)
          ..headers['Depth'] = '0';
        final res = await client.send(req).timeout(const Duration(seconds: 10));
        if (res.statusCode != 207 && res.statusCode != 200) {
          throw Exception(WebdavClient.connectionHelp(
            'WebDAV verification failed',
            statusCode: res.statusCode,
          ));
        }
      } catch (e) {
        if (e is Exception && e.toString().contains('无法连接坚果云 WebDAV')) {
          rethrow;
        }
        throw Exception(WebdavClient.connectionHelp(e));
      } finally {
        client.close();
      }

      await DbConfigService.saveWebdavConfig(
        url: webdavUrl,
        user: loginUsername,
        password: loginPassword,
      );

      // 初始化同步目录
      await WebdavClient.createSyncDir();

      final box = Hive.box('user');

      // 在 WebDAV 模式下，用配置的 WebDAV 账号作为登录标识
      final rawUser = box.get(_keyCurrentUser);
      final user = rawUser == null
          ? _pendingUser(loginUsername, 'setup_required')
          : Map<String, dynamic>.from(rawUser as Map);
      user['username'] = loginUsername;
      user['sessionToken'] = 'webdav_token_mock';
      await box.put(_keyCurrentUser, user);

      // 尝试拉取或创建云端的 CoupleRelation
      await checkPairStatus();

      return await getCurrentUser() ?? user;
    } catch (e) {
      print("WebDAV Auth failed: $e");
      final box = Hive.box('user');
      await box.delete(_keyCurrentUser);
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// 确保 WebDAV 同步文件夹存在
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final box = Hive.box('user');
    final user = box.get(_keyCurrentUser);
    if (user == null) return null;
    return Map<String, dynamic>.from(user as Map);
  }

  /// 获取本地保存的 Relation
  static Future<Map<String, dynamic>?> getLocalRelation() async {
    final box = Hive.box('user');
    final relation = box.get(_keyRelation);
    if (relation == null) return null;
    return Map<String, dynamic>.from(relation as Map);
  }

  static Future<String?> getWebdavRole() async {
    final role = Hive.box('user').get(_keyRole) as String?;
    return role == roleUser1 || role == roleUser2 ? role : null;
  }

  static Future<Map<String, bool>> getWebdavRoleAvailability() async {
    final relation = await checkPairStatus();
    if (relation == null) {
      return {roleUser1: true, roleUser2: true};
    }

    final deviceId = await _getDeviceId();
    return {
      roleUser1: _isRoleAvailableForDevice(relation, roleUser1, deviceId),
      roleUser2: _isRoleAvailableForDevice(relation, roleUser2, deviceId),
    };
  }

  static Future<void> selectWebdavRole(String role) async {
    if (role != roleUser1 && role != roleUser2) {
      throw Exception('请选择有效的身份');
    }

    final relation = await checkPairStatus();
    if (relation == null) {
      final box = Hive.box('user');
      await box.put(_keyRole, role);
      final user = await getCurrentUser();
      await box.put(
        _keyCurrentUser,
        _pendingUser(
            user?['username'] as String? ?? WebdavClient.username, 'setup_required'),
      );
      return;
    }

    final deviceId = await _getDeviceId();
    if (!_isRoleAvailableForDevice(relation, role, deviceId)) {
      throw Exception('这个身份已经被另一台设备占用，请选择另一个身份或联系管理员清除云端配对关系。');
    }

    relation['${role}_device_id'] = deviceId;
    relation['updatedAt'] = DateTime.now().toIso8601String();
    final uploaded =
        await WebdavClient.safeUploadWithRetry('couple_relation.json', relation);
    if (!uploaded) {
      throw Exception('身份绑定失败：无法写入云端配对文件，请检查网络和坚果云 WebDAV 权限。');
    }

    final box = Hive.box('user');
    await box.put(_keyRole, role);
    await _syncCurrentUserPairing(
      await getCurrentUser() ?? _pendingUser(WebdavClient.username, 'role_required'),
      relation,
    );
  }

  static Map<String, dynamic> _requireValidPairRelation(
    Map<String, dynamic> relation,
  ) {
    final requiredKeys = ['couple_id', 'user1_id', 'user2_id'];
    final missing = requiredKeys
        .where((key) => (relation[key] as String?)?.trim().isEmpty ?? true)
        .toList();
    if (missing.isNotEmpty) {
      throw _InvalidPairDataException(
        '云端配对数据损坏：couple_relation.json 缺少 ${missing.join(', ')}。'
        '请管理员清除云端配对关系后重新创建共享空间。',
      );
    }

    if (relation['user1_id'] == relation['user2_id']) {
      throw const _InvalidPairDataException(
        '云端配对数据损坏：user1_id 与 user2_id 不能相同。'
        '请管理员清除云端配对关系后重新创建共享空间。',
      );
    }

    relation['schema_version'] ??= 2;
    relation['heartbeat_count'] ??= 0;
    relation['user1_device_id'] ??= '';
    relation['user2_device_id'] ??= '';
    relation['updatedAt'] ??= DateTime.now().toIso8601String();

    return relation;
  }

  /// 检查/同步配对关系
  static Future<Map<String, dynamic>?> checkPairStatus() async {
    final user = await getCurrentUser();
    if (user == null) return null;

    try {
      final res = await http
          .get(WebdavClient.syncUri('love_app_sync/couple_relation.json'),
              headers: WebdavClient.headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final remoteRelation = _requireValidPairRelation(
          Map<String, dynamic>.from(jsonDecode(utf8.decode(res.bodyBytes))),
        );
        await _syncCurrentUserPairing(user, remoteRelation);
        return remoteRelation;
      }

      if (res.statusCode == 404) {
        await _syncCurrentUserPairing(user, null);
        return null;
      }

      throw Exception(WebdavClient.connectionHelp(
        'WebDAV pair data fetch failed',
        statusCode: res.statusCode,
      ));
    } catch (e) {
      print("WebDAV checkPairStatus fetch error: $e");
      if (e is _InvalidPairDataException) {
        rethrow;
      }
      if (e is Exception && e.toString().contains('无法连接坚果云 WebDAV')) {
        rethrow;
      }
      throw Exception(WebdavClient.connectionHelp(e));
    }
  }

  /// 本地邀请码配对（WebDAV 模式下直接通过配置同一个账号达成，无须手动配对）
  static Future<void> pairWithInviteCode(String inviteCode) async {
    final relation = await checkPairStatus();
    if (relation == null) {
      throw Exception(
        '服务器已连接，但未找到云端配对数据。\n'
        '解决方案：请确认双方使用同一个坚果云 WebDAV 账号，且云端 /love_app_sync/couple_relation.json 已存在；'
        '如果这是第一次使用，请先完成共享空间资料设置后再同步。',
      );
    }
  }

  /// 更新用户昵称
  static Future<void> updateNickname(String newNickname) async {
    final user = await getCurrentUser();
    if (user == null) throw Exception('请先登录');

    user['nickname'] = newNickname;
    final box = Hive.box('user');
    await box.put(_keyCurrentUser, user);

    final relation = await getLocalRelation();
    if (relation != null) {
      final role = await getWebdavRole();
      relation[role == roleUser1 ? 'user1_name' : 'user2_name'] = newNickname;
      relation['updatedAt'] = DateTime.now().toIso8601String();
      await box.put(_keyRelation, relation);
      await WebdavClient.safeUploadWithRetry('couple_relation.json', relation);
    }
  }

  /// 更新共享空间配置
  static Future<void> updateCoupleSettings({
    required String user1Name,
    required String user2Name,
    required String user1Gender,
    required String user2Gender,
    required String firstMetDate,
    required String anniversaryDate,
    String? webdavRole,
  }) async {
    final user = await getCurrentUser();
    if (user == null) throw Exception('请先登录');

    final selectedRole = webdavRole ?? await getWebdavRole() ?? roleUser2;
    if (selectedRole != roleUser1 && selectedRole != roleUser2) {
      throw Exception('请选择有效的身份');
    }
    final deviceId = await _getDeviceId();

    final relation = await getLocalRelation() ??
        {
          'objectId': 'relation_webdav',
          'couple_id': 'webdav_couple_${WebdavClient.username.hashCode}',
          'user1_id': 'webdav_user_a',
          'user2_id': 'webdav_user_b',
          'heartbeat_count': 0,
          'schema_version': 2,
          'user1_device_id': '',
          'user2_device_id': '',
        };

    relation['user1_name'] = user1Name;
    relation['user2_name'] = user2Name;
    relation['user1_gender'] = user1Gender;
    relation['user2_gender'] = user2Gender;
    relation['first_met_date'] = firstMetDate;
    relation['anniversary_date'] = anniversaryDate;
    relation['${selectedRole}_device_id'] = deviceId;
    relation['schema_version'] = 2;
    relation['updatedAt'] = DateTime.now().toIso8601String();
    _requireValidPairRelation(relation);

    final box = Hive.box('user');
    final uploaded =
        await WebdavClient.safeUploadWithRetry('couple_relation.json', relation);
    if (!uploaded) {
      throw Exception(
        '云端配对关系上传失败：已连接服务器但无法写入 /love_app_sync/couple_relation.json。'
        '请检查坚果云应用授权密码、WebDAV 空间权限和网络后重试。',
      );
    }
    await box.put(_keyRole, selectedRole);
    await box.put(_keyRelation, relation);

    await box.put(
      _keyCurrentUser,
      _userForRole(
        user['username'] as String? ?? WebdavClient.username,
        selectedRole,
        relation,
      ),
    );
  }

  /// 发射爱心并云端同步递增（ETag 乐观锁重试，防止并发丢失）
  static Future<int> sendHeartbeat() async {
    const maxRetries = 3;
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      // 每次重试前重新拉取最新云端数据
      final relation = await checkPairStatus();
      if (relation == null) return 0;

      final newCount = (relation['heartbeat_count'] ?? 0) + 1;
      relation['heartbeat_count'] = newCount;

      final box = Hive.box('user');
      await box.put(_keyRelation, relation);

      final success =
          await WebdavClient.uploadFileWithLock('couple_relation.json', relation);
      if (success) return newCount;

      // 冲突，短暂等待后重试
      if (attempt < maxRetries - 1) {
        await Future.delayed(Duration(milliseconds: 200 * (attempt + 1)));
      }
    }
    // 所有重试失败，返回当前本地计数
    final localRel = await getLocalRelation();
    return localRel?['heartbeat_count'] ?? 0;
  }

  static Future<void> deleteAccount() async {
    await logout();
  }

  static Future<void> clearCloudPairingRelation() async {
    try {
      final res = await http
          .delete(WebdavClient.syncUri('love_app_sync/couple_relation.json'),
              headers: WebdavClient.headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200 &&
          res.statusCode != 204 &&
          res.statusCode != 404) {
        throw Exception(WebdavClient.connectionHelp(
          'WebDAV pair data delete failed',
          statusCode: res.statusCode,
        ));
      }

      final box = Hive.box('user');
      final user = await getCurrentUser();
      if (user != null) {
        user['status'] = 'single';
        user['couple_id'] = null;
        user['partner_id'] = null;
        await box.put(_keyCurrentUser, user);
      }
      await box.delete(_keyRelation);
      await box.delete(_keyRole);
    } catch (e) {
      if (e is Exception && e.toString().contains('无法连接坚果云 WebDAV')) {
        rethrow;
      }
      throw Exception(WebdavClient.connectionHelp(e));
    }
  }

  static Future<void> logout() async {
    final box = Hive.box('user');
    await box.delete(_keyCurrentUser);
    await box.delete(_keyRelation);
    await box.delete(_keyRole);
  }

  // --- WebDAV 文件读写助手 ---

  /// ETag 缓存 (按文件名)
  static final Map<String, String> _etags = {};

  /// 普通上传（无并发保护）
  /// 带 ETag 乐观锁的上传，返回 true 表示成功，false 表示冲突需重试
  static List<Map<String, dynamic>> _recordsFromRawList(dynamic raw) {
    if (raw is! List) return [];

    final records = <Map<String, dynamic>>[];
    for (final item in raw) {
      if (item is Map) {
        records.add(Map<String, dynamic>.from(item));
      }
    }
    return records;
  }

  static List<Map<String, dynamic>> _periodRecordsFromRaw(dynamic raw) {
    if (raw is! List) return [];

    final records = <Map<String, dynamic>>[];
    for (final item in raw) {
      if (item is String && item.isNotEmpty) {
        records.add({
          'objectId': item,
          'date': item,
          'updatedAt': DateTime.fromMillisecondsSinceEpoch(0).toIso8601String(),
        });
      } else if (item is Map) {
        final record = Map<String, dynamic>.from(item);
        final date =
            record['date']?.toString() ?? record['objectId']?.toString();
        if (date == null || date.isEmpty) continue;
        record['objectId'] ??= date;
        record['date'] ??= date;
        record['updatedAt'] ??=
            DateTime.fromMillisecondsSinceEpoch(0).toIso8601String();
        records.add(record);
      }
    }
    return records;
  }

  static List<Map<String, dynamic>> _loadPeriodRecords(Box box) {
    final storedRecords = _periodRecordsFromRaw(box.get(_keyPeriodRecords));
    if (storedRecords.isNotEmpty) return storedRecords;
    return _periodRecordsFromRaw(box.get('list'));
  }

  static List<String> _periodDatesFromRecords(
    Iterable<Map<String, dynamic>> records,
  ) {
    final dates = SyncMerge.visibleRecords(records)
        .map((record) => record['date']?.toString() ?? '')
        .where((date) => date.isNotEmpty)
        .toSet()
        .toList();
    dates.sort();
    return dates;
  }

  static Future<void> _storePeriodRecords(
    Box box,
    List<Map<String, dynamic>> records,
  ) async {
    await box.put(_keyPeriodRecords, records);
    await box.put('list', _periodDatesFromRecords(records));
  }

  static List<Map<String, dynamic>> _loadCachedLocations() {
    return _recordsFromRawList(Hive.box('user').get(_keyLocations));
  }

  static Future<List<Map<String, dynamic>>> _loadMergedLocations() async {
    final localList = _loadCachedLocations();
    final remoteRaw = await WebdavClient.downloadFile('locations.json');
    if (remoteRaw is List) {
      final remoteList = _recordsFromRawList(remoteRaw);
      final merged = SyncMerge.mergeRecords(localList, remoteList);
      await Hive.box('user').put(_keyLocations, merged);
      return merged;
    }
    return localList;
  }

  static Map<String, dynamic> _locationRecordForUser(
    Map<String, dynamic> user,
    double latitude,
    double longitude,
    String timestamp,
  ) {
    return {
      'objectId': user['objectId']?.toString() ?? WebdavClient.username,
      'username': user['username']?.toString() ?? WebdavClient.username,
      'nickname': user['nickname']?.toString() ?? user['username']?.toString(),
      'couple_id': user['couple_id'],
      'latitude': latitude,
      'longitude': longitude,
      'location_updated_at': timestamp,
      'updatedAt': timestamp,
    };
  }

  // --- 图片上传/删除 ---

  /// 上传图片到 WebDAV images 目录，返回文件名
  // --- 日记同步 ---
  static Future<List<Diary>> fetchDiaries({int limit = 20, int offset = 0}) async {
    final localBox = Hive.box('diaries');
    final List<dynamic> localRaw = localBox.get('list') ?? [];
    final localList = List<Map<String, dynamic>>.from(
        localRaw.map((e) => Map<String, dynamic>.from(e as Map)));

    // 下载云端数据
    final remoteRaw = await WebdavClient.downloadFile('diaries.json');
    if (remoteRaw != null && remoteRaw is List) {
      final remoteList = List<Map<String, dynamic>>.from(
          remoteRaw.map((e) => Map<String, dynamic>.from(e as Map)));

      // 合并
      final merged = SyncMerge.mergeRecords(localList, remoteList);
      final visible = SyncMerge.visibleRecords(merged);
      visible.sort((a, b) =>
          (b['date'] as String).compareTo(a['date'] as String)); // 日期倒序

      await localBox.put('list', merged);
      return visible.skip(offset).take(limit).map((e) => Diary.fromJson(e)).toList();
    }

    final visibleLocal = SyncMerge.visibleRecords(localList);
    visibleLocal.sort((a, b) =>
          (b['date'] as String).compareTo(a['date'] as String));
    return visibleLocal.skip(offset).take(limit).map((e) => Diary.fromJson(e)).toList();
  }

  static Future<void> saveDiary({
    String? objectId,
    required String content,
    required String mood,
    required String weather,
    required List<String> tags,
    required String date,
    String? imageUrl,
  }) async {
    final user = await getCurrentUser();
    final coupleId = user?['couple_id'] ?? 'webdav_couple';

    final finalObjectId =
        objectId ?? 'webdav_diary_${DateTime.now().millisecondsSinceEpoch}';

    // 处理图片：base64 data URI → 上传为独立文件，日记只存文件名
    String finalImageUrl = '';
    if (imageUrl != null && imageUrl.isNotEmpty) {
      if (imageUrl.startsWith('data:')) {
        // 新图片：提取 base64，上传为独立文件
        final parts = imageUrl.split(',');
        if (parts.length == 2) {
          final bytes = base64Decode(parts[1]);
          final ext = imageUrl.contains('image/png') ? 'png' : 'jpg';
          final fileName = 'img_$finalObjectId.$ext';
          final uploaded = await WebdavClient.uploadImageBytes(fileName, bytes);
          if (uploaded != null) {
            finalImageUrl = fileName;
          }
        }
      } else {
        // 已经是文件名格式（编辑已有日记），保持不变
        finalImageUrl = imageUrl;
      }
    }

      final body = {
        'objectId': finalObjectId,
        'content': content,
        'mood': mood,
        'weather': weather,
        'tags': tags,
        'date': date,
        'imageUrl': finalImageUrl,
        'couple_id': coupleId,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      try {
        final success = await WebdavClient.safeUploadWithRetry('diaries.json', [body]);
        if (!success) {
          throw Exception('WebDAV saveDiary returned false');
        }
      } catch (e) {
        print("WebDAV saveDiary fallback: $e");
        SyncQueueManager().enqueueTask('saveDiary', body);
      }

      final box = Hive.box('diaries');
    final List<dynamic> rawList = box.get('list') ?? [];
    final List<Map<String, dynamic>> list = List<Map<String, dynamic>>.from(
        rawList.map((e) => Map<String, dynamic>.from(e as Map)));

    final index = list.indexWhere((item) => item['objectId'] == finalObjectId);
    if (index != -1) {
      list[index] = body;
    } else {
      list.insert(0, body);
    }
    await box.put('list', list);

    // 立即上传同步
    await WebdavClient.safeUploadWithRetry('diaries.json', list);
  }

  static Future<void> deleteDiary(String objectId) async {
    final box = Hive.box('diaries');
    final List<dynamic> rawList = box.get('list') ?? [];
    final List<Map<String, dynamic>> list = List<Map<String, dynamic>>.from(
        rawList.map((e) => Map<String, dynamic>.from(e as Map)));

    // 找到要删除的日记，删除关联的图片文件
    final target = list.cast<Map<String, dynamic>?>().firstWhere(
          (item) => item?['objectId'] == objectId,
          orElse: () => null,
        );
    if (target != null) {
      final img = target['image_url'] as String? ?? '';
      if (img.isNotEmpty && !img.startsWith('data:')) {
        await WebdavClient.deleteImageFile(img);
      }
    }

    final tombstone = SyncMerge.tombstoneFor(objectId);
    final index = list.indexWhere((item) => item['objectId'] == objectId);
    if (index != -1) {
      list[index] = tombstone;
    } else {
      list.add(tombstone);
    }
    await box.put('list', list);
    try {
      await WebdavClient.safeUploadWithRetry('diaries.json', list);
    } catch (e) {
      print("WebDAV deleteDiary fallback: $e");
      SyncQueueManager().enqueueTask('deleteDiary', {'objectId': objectId});
    }
  }

  // --- 心愿同步 ---
  static Future<List<Map<String, dynamic>>> fetchWishes() async {
    final localBox = Hive.box('wishes');
    final List<dynamic> localRaw = localBox.get('list') ?? [];
    final localList = List<Map<String, dynamic>>.from(
        localRaw.map((e) => Map<String, dynamic>.from(e as Map)));

    final remoteRaw = await WebdavClient.downloadFile('wishes.json');
    if (remoteRaw != null && remoteRaw is List) {
      final remoteList = List<Map<String, dynamic>>.from(
          remoteRaw.map((e) => Map<String, dynamic>.from(e as Map)));

      final merged = SyncMerge.mergeRecords(localList, remoteList);
      await localBox.put('list', merged);
      return SyncMerge.visibleRecords(merged);
    }
    return SyncMerge.visibleRecords(localList);
  }

  static Future<void> saveWish({
    required String title,
    bool completed = false,
  }) async {
    final user = await getCurrentUser();
    final coupleId = user?['couple_id'] ?? 'webdav_couple';

    final objectId = 'webdav_wish_${DateTime.now().millisecondsSinceEpoch}';
    final body = {
      'objectId': objectId,
      'couple_id': coupleId,
      'title': title,
      'completed': completed,
      'completed_at': completed ? DateTime.now().toIso8601String() : '',
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };

    final box = Hive.box('wishes');
    final List<dynamic> rawList = box.get('list') ?? [];
    final List<Map<String, dynamic>> list = List<Map<String, dynamic>>.from(
        rawList.map((e) => Map<String, dynamic>.from(e as Map)));
    list.add(body);
    await box.put('list', list);
    await WebdavClient.safeUploadWithRetry('wishes.json', list);
  }

  static Future<void> toggleWish(String objectId, bool completed) async {
    final box = Hive.box('wishes');
    final List<dynamic> rawList = box.get('list') ?? [];
    final List<Map<String, dynamic>> list = List<Map<String, dynamic>>.from(
        rawList.map((e) => Map<String, dynamic>.from(e as Map)));
    final index = list.indexWhere((item) => item['objectId'] == objectId);
    if (index != -1) {
      list[index]['completed'] = completed;
      list[index]['completed_at'] =
          completed ? DateTime.now().toIso8601String() : '';
      list[index]['updatedAt'] = DateTime.now().toIso8601String();
    }
    await box.put('list', list);
    await WebdavClient.safeUploadWithRetry('wishes.json', list);
  }

  static Future<void> deleteWish(String objectId) async {
    final box = Hive.box('wishes');
    final List<dynamic> rawList = box.get('list') ?? [];
    final List<Map<String, dynamic>> list = List<Map<String, dynamic>>.from(
        rawList.map((e) => Map<String, dynamic>.from(e as Map)));
    final tombstone = SyncMerge.tombstoneFor(objectId);
    final index = list.indexWhere((item) => item['objectId'] == objectId);
    if (index != -1) {
      list[index] = tombstone;
    } else {
      list.add(tombstone);
    }
    await box.put('list', list);
    await WebdavClient.safeUploadWithRetry('wishes.json', list);
  }

  // --- 纪念日同步 ---
  static Future<List<Map<String, dynamic>>> fetchAnniversaries() async {
    final localBox = Hive.box('anniversaries');
    final List<dynamic> localRaw = localBox.get('list') ?? [];
    final localList = List<Map<String, dynamic>>.from(
        localRaw.map((e) => Map<String, dynamic>.from(e as Map)));

    final remoteRaw = await WebdavClient.downloadFile('anniversaries.json');
    if (remoteRaw != null && remoteRaw is List) {
      final remoteList = List<Map<String, dynamic>>.from(
          remoteRaw.map((e) => Map<String, dynamic>.from(e as Map)));

      final merged = SyncMerge.mergeRecords(localList, remoteList);
      final visible = SyncMerge.visibleRecords(merged);
      visible
          .sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
      await localBox.put('list', merged);
      return visible;
    }
    return SyncMerge.visibleRecords(localList);
  }

  static Future<void> saveAnniversary({
    required String title,
    required String date,
    required String icon,
  }) async {
    final user = await getCurrentUser();
    final coupleId = user?['couple_id'] ?? 'webdav_couple';

    final objectId =
        'webdav_anniversary_${DateTime.now().millisecondsSinceEpoch}';
    final body = {
      'objectId': objectId,
      'couple_id': coupleId,
      'title': title,
      'date': date,
      'icon': icon,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };

    final box = Hive.box('anniversaries');
    final List<dynamic> rawList = box.get('list') ?? [];
    final List<Map<String, dynamic>> list = List<Map<String, dynamic>>.from(
        rawList.map((e) => Map<String, dynamic>.from(e as Map)));
    list.add(body);
    list.sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
    await box.put('list', list);
    await WebdavClient.safeUploadWithRetry('anniversaries.json', list);
  }

  // --- 生理期同步 ---
  static Future<List<String>> fetchPeriodLogs() async {
    final localBox = Hive.box('period_logs');
    final localRecords = _loadPeriodRecords(localBox);

    final remoteRaw = await WebdavClient.downloadFile('period_logs.json');
    if (remoteRaw != null && remoteRaw is List) {
      final remoteRecords = _periodRecordsFromRaw(remoteRaw);
      final merged = SyncMerge.mergeRecords(localRecords, remoteRecords);

      // 合并取并集
      await _storePeriodRecords(localBox, merged);
      return _periodDatesFromRecords(merged);
    }
    return _periodDatesFromRecords(localRecords);
  }

  static Future<void> togglePeriodLog(String dateString, bool isPeriod) async {
    final box = Hive.box('period_logs');
    final list = _loadPeriodRecords(box);
    final timestamp = DateTime.now().toIso8601String();
    final activeRecord = {
      'objectId': dateString,
      'date': dateString,
      'deleted': false,
      'updatedAt': timestamp,
    };
    final tombstone = {
      ...SyncMerge.tombstoneFor(dateString, deletedAt: DateTime.now()),
      'date': dateString,
    };
    final record = isPeriod ? activeRecord : tombstone;
    final index = list.indexWhere((item) => item['objectId'] == dateString);
    if (isPeriod) {
      if (index != -1) {
        list[index] = record;
      } else {
        list.add(record);
      }
    } else if (index != -1) {
      list[index] = record;
    } else {
      list.add(record);
    }
    await _storePeriodRecords(box, list);
    await WebdavClient.safeUploadWithRetry('period_logs.json', list);
  }

  // --- 亲密记同步 ---
  static Future<List<Map<String, dynamic>>> fetchIntimacyLogs() async {
    final localBox = Hive.box('intimacy_logs');
    final List<dynamic> localRaw = localBox.get('list') ?? [];
    final localList = List<Map<String, dynamic>>.from(
        localRaw.map((e) => Map<String, dynamic>.from(e as Map)));

    final remoteRaw = await WebdavClient.downloadFile('intimacy_logs.json');
    if (remoteRaw != null && remoteRaw is List) {
      final remoteList = List<Map<String, dynamic>>.from(
          remoteRaw.map((e) => Map<String, dynamic>.from(e as Map)));

      final merged = SyncMerge.mergeRecords(localList, remoteList);
      final visible = SyncMerge.visibleRecords(merged);
      visible
          .sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));

      await localBox.put('list', merged);
      return visible;
    }
    return SyncMerge.visibleRecords(localList);
  }

  static Future<void> saveIntimacyLog({
    String? objectId,
    required String date,
    required String mood,
    required double rating,
    required String note,
  }) async {
    final user = await getCurrentUser();
    final coupleId = user?['couple_id'] ?? 'webdav_couple';

    final finalObjectId =
        objectId ?? 'webdav_intimacy_${DateTime.now().millisecondsSinceEpoch}';
    final body = {
      'objectId': finalObjectId,
      'couple_id': coupleId,
      'date': date,
      'mood': mood,
      'rating': rating,
      'note': note,
      'creator_id': user?['objectId'] ?? 'webdav_user',
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };

    final box = Hive.box('intimacy_logs');
    final List<dynamic> rawList = box.get('list') ?? [];
    final List<Map<String, dynamic>> list = List<Map<String, dynamic>>.from(
        rawList.map((e) => Map<String, dynamic>.from(e as Map)));

    final index = list.indexWhere((item) => item['objectId'] == finalObjectId);
    if (index != -1) {
      list[index] = body;
    } else {
      list.insert(0, body);
    }
    await box.put('list', list);
    await WebdavClient.safeUploadWithRetry('intimacy_logs.json', list);
  }

  // --- 瀹氫綅鍚屾 ---
  static Future<void> updateLocation(double latitude, double longitude) async {
    final user = await getCurrentUser();
    if (user == null) return;

    final timestamp = DateTime.now().toIso8601String();
    user['latitude'] = latitude;
    user['longitude'] = longitude;
    user['location_updated_at'] = timestamp;
    await Hive.box('user').put(_keyCurrentUser, user);

    final locationRecord = _locationRecordForUser(
      user,
      latitude,
      longitude,
      timestamp,
    );
    final merged = SyncMerge.mergeRecords(
      _loadCachedLocations(),
      [locationRecord],
    );
    final latest = SyncMerge.mergeRecords(
      merged,
      await _loadMergedLocations(),
    );

    await Hive.box('user').put(_keyLocations, latest);
    await WebdavClient.safeUploadWithRetry('locations.json', latest);

    // 同步更新历史轨迹记录
    try {
      await updateLocationHistory(latitude, longitude);
    } catch (e) {
      print('更新历史轨迹失败: $e');
    }
  }

  static Future<Map<String, dynamic>?> fetchPartnerLocation(
      String partnerId) async {
    final locations = await _loadMergedLocations();
    final visible = SyncMerge.visibleRecords(locations);
    return visible.cast<Map<String, dynamic>?>().firstWhere(
          (item) => item?['objectId']?.toString() == partnerId,
          orElse: () => null,
        );
  }

  static Future<List<Map<String, dynamic>>> fetchAllLocations() async {
    final locations = SyncMerge.visibleRecords(await _loadMergedLocations())
        .where((item) => item['latitude'] != null && item['longitude'] != null)
        .toList();
    locations.sort((a, b) => (b['location_updated_at']?.toString() ?? '')
        .compareTo(a['location_updated_at']?.toString() ?? ''));
    return locations;
  }

  static List<Map<String, dynamic>> _loadCachedLocationHistory() {
    return _recordsFromRawList(Hive.box('user').get(_keyLocationHistory));
  }

  static Future<List<Map<String, dynamic>>> _loadMergedLocationHistory() async {
    final localList = _loadCachedLocationHistory();
    final remoteRaw = await WebdavClient.downloadFile('location_history.json');
    if (remoteRaw is List) {
      final remoteList = _recordsFromRawList(remoteRaw);
      final merged = SyncMerge.mergeRecords(localList, remoteList);
      await Hive.box('user').put(_keyLocationHistory, merged);
      return merged;
    }
    return localList;
  }

  static Future<void> updateLocationHistory(double latitude, double longitude) async {
    final user = await getCurrentUser();
    if (user == null) return;

    final userId = user['objectId']?.toString() ?? WebdavClient.username;
    final timestamp = DateTime.now().toIso8601String();

    final historyList = await _loadMergedLocationHistory();

    final myHistory = historyList
        .where((item) => item['userId'] == userId && item['latitude'] != null && item['longitude'] != null)
        .toList();
    
    myHistory.sort((a, b) => (a['start_time']?.toString() ?? '')
        .compareTo(b['start_time']?.toString() ?? ''));

    Map<String, dynamic>? lastRecord = myHistory.isNotEmpty ? myHistory.last : null;

    bool isWithin50m = false;
    if (lastRecord != null) {
      final lastLat = lastRecord['latitude'] as double?;
      final lastLng = lastRecord['longitude'] as double?;
      if (lastLat != null && lastLng != null) {
        final distance = Geolocator.distanceBetween(lastLat, lastLng, latitude, longitude);
        if (distance < 50) {
          isWithin50m = true;
        }
      }
    }

    if (isWithin50m && lastRecord != null) {
      final updatedRecord = Map<String, dynamic>.from(lastRecord);
      updatedRecord['end_time'] = timestamp;
      updatedRecord['updatedAt'] = timestamp;

      final idx = historyList.indexWhere((item) => item['objectId'] == lastRecord['objectId']);
      if (idx != -1) {
        historyList[idx] = updatedRecord;
      }
    } else {
      final newRecordId = '${userId}_${DateTime.now().millisecondsSinceEpoch}';
      final newRecord = {
        'objectId': newRecordId,
        'userId': userId,
        'latitude': latitude,
        'longitude': longitude,
        'start_time': timestamp,
        'end_time': timestamp,
        'updatedAt': timestamp,
      };
      historyList.add(newRecord);
    }

    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    final filteredHistory = historyList.where((item) {
      final itemTimeStr = item['end_time']?.toString() ?? item['updatedAt']?.toString() ?? '';
      final itemTime = DateTime.tryParse(itemTimeStr);
      if (itemTime == null) return false;
      return itemTime.isAfter(sevenDaysAgo);
    }).toList();

    filteredHistory.sort((a, b) => (a['start_time']?.toString() ?? '')
        .compareTo(b['start_time']?.toString() ?? ''));
    final finalizedHistory = filteredHistory.length > 500 
        ? filteredHistory.sublist(filteredHistory.length - 500)
        : filteredHistory;

    await Hive.box('user').put(_keyLocationHistory, finalizedHistory);
    await WebdavClient.safeUploadWithRetry('location_history.json', finalizedHistory);
  }

  static Future<List<Map<String, dynamic>>> fetchLocationHistory() async {
    final history = await _loadMergedLocationHistory();
    final visible = SyncMerge.visibleRecords(history);
    visible.sort((a, b) => (a['start_time']?.toString() ?? '')
        .compareTo(b['start_time']?.toString() ?? ''));
    return visible;
  }
}
