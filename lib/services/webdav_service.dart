import 'dart:convert';
import 'dart:math';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'db_config_service.dart';

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

  static String get _webdavUrl {
    var url = DbConfigService.webdavUrl.trim();
    if (!url.endsWith('/')) {
      url += '/';
    }
    return url;
  }

  static String get _username => DbConfigService.webdavUser.trim();
  static String get _password => DbConfigService.webdavPassword.trim();

  static Map<String, String> get _headers {
    return _buildHeaders(_username, _password);
  }

  static Map<String, String> _buildHeaders(String username, String password) {
    final credentials = base64Encode(utf8.encode('$username:$password'));
    return {
      'Authorization': 'Basic $credentials',
      'Content-Type': 'application/json',
    };
  }

  static String _connectionHelp(Object error, {int? statusCode}) {
    final checks = <String>[
      '无法连接坚果云 WebDAV，已自动检查：',
      if (statusCode != null) '1. 服务器返回状态码：$statusCode',
      if (statusCode == null) '1. 未收到服务器有效响应：$error',
      '2. 请确认网络可以访问 https://dav.jianguoyun.com/dav/',
      '3. 请确认账号填写的是坚果云登录邮箱。',
      '4. 请确认密码是“第三方应用管理”里生成的应用授权密码，不是坚果云登录密码。',
      '5. 如果开启了代理、VPN 或公司网络限制，请切换网络后重试。',
    ];

    if (statusCode == 401 || statusCode == 403) {
      checks.add('判断：账号或应用授权密码不正确，或该账号没有 WebDAV 权限。');
    } else if (statusCode == 404) {
      checks.add('判断：WebDAV 地址不正确，请使用 https://dav.jianguoyun.com/dav/。');
    } else if (statusCode != null && statusCode >= 500) {
      checks.add('判断：坚果云服务端暂时不可用，请稍后重试。');
    }

    return checks.join('\n');
  }

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
    final username = (user['username'] as String?) ?? _username;
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
      await _safeUploadWithRetry('couple_relation.json', relation);
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

      final webdavUrl = _webdavUrl;
      final loginHeaders = _buildHeaders(loginUsername, loginPassword);

      // 验证连接：发送 Propfind 请求到根目录或读取测试
      final client = http.Client();
      try {
        final req = http.Request('PROPFIND', Uri.parse(webdavUrl))
          ..headers.addAll(loginHeaders)
          ..headers['Depth'] = '0';
        final res = await client.send(req).timeout(const Duration(seconds: 10));
        if (res.statusCode != 207 && res.statusCode != 200) {
          throw Exception(_connectionHelp(
            'WebDAV verification failed',
            statusCode: res.statusCode,
          ));
        }
      } catch (e) {
        if (e is Exception && e.toString().contains('无法连接坚果云 WebDAV')) {
          rethrow;
        }
        throw Exception(_connectionHelp(e));
      } finally {
        client.close();
      }

      await DbConfigService.saveWebdavConfig(
        url: webdavUrl,
        user: loginUsername,
        password: loginPassword,
      );

      // 初始化同步目录
      await _createSyncDir();

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
  static Future<void> _createSyncDir() async {
    final client = http.Client();
    try {
      final syncDirUrl = '$_webdavUrl/love_app_sync/';
      final req = http.Request('MKCOL', Uri.parse(syncDirUrl))
        ..headers.addAll(_headers);
      final res = await client.send(req).timeout(const Duration(seconds: 10));
      // 405 = 目录已存在，201 = 创建成功，均视为正常
      if (res.statusCode != 201 && res.statusCode != 405) {
        throw Exception(_connectionHelp(
          'WebDAV sync directory creation failed',
          statusCode: res.statusCode,
        ));
      }
    } catch (e) {
      if (e is Exception && e.toString().contains('无法连接坚果云 WebDAV')) {
        rethrow;
      }
      throw Exception(_connectionHelp(e));
    } finally {
      client.close();
    }
  }

  /// 获取当前用户（本地）
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
            user?['username'] as String? ?? _username, 'setup_required'),
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
        await _safeUploadWithRetry('couple_relation.json', relation);
    if (!uploaded) {
      throw Exception('身份绑定失败：无法写入云端配对文件，请检查网络和坚果云 WebDAV 权限。');
    }

    final box = Hive.box('user');
    await box.put(_keyRole, role);
    await _syncCurrentUserPairing(
      await getCurrentUser() ?? _pendingUser(_username, 'role_required'),
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

    final fileUrl = '$_webdavUrl/love_app_sync/couple_relation.json';

    try {
      final res = await http
          .get(Uri.parse(fileUrl), headers: _headers)
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

      throw Exception(_connectionHelp(
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
      throw Exception(_connectionHelp(e));
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
      await _safeUploadWithRetry('couple_relation.json', relation);
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
          'couple_id': 'webdav_couple_${_username.hashCode}',
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
        await _safeUploadWithRetry('couple_relation.json', relation);
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
        user['username'] as String? ?? _username,
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
          await _uploadFileWithLock('couple_relation.json', relation);
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
    final fileUrl = '$_webdavUrl/love_app_sync/couple_relation.json';
    try {
      final res = await http
          .delete(Uri.parse(fileUrl), headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200 &&
          res.statusCode != 204 &&
          res.statusCode != 404) {
        throw Exception(_connectionHelp(
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
      throw Exception(_connectionHelp(e));
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
  static Future<bool> _uploadFileWithLock(String fileName, dynamic data) async {
    try {
      final fileUrl = '$_webdavUrl/love_app_sync/$fileName';
      final bodyStr = jsonEncode(data);
      final headers = Map<String, String>.from(_headers);
      final cachedEtag = _etags[fileName];
      if (cachedEtag != null) {
        headers['If-Match'] = cachedEtag;
      }
      final res = await http
          .put(
            Uri.parse(fileUrl),
            headers: headers,
            body: utf8.encode(bodyStr),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 412) return false; // ETag 不匹配，冲突
      if (res.statusCode < 200 || res.statusCode >= 300) {
        print(
          "WebDAV uploadWithLock $fileName failed: HTTP ${res.statusCode}",
        );
        return false;
      }
      final etag = res.headers['etag'];
      if (etag != null) _etags[fileName] = etag;
      return true;
    } catch (e) {
      print("WebDAV uploadWithLock $fileName failed: $e");
      return false;
    }
  }

  /// 带冲突重试的安全上传（读→合并→写，最多重试 1 次）
  static Future<bool> _safeUploadWithRetry(
      String fileName, dynamic data) async {
    final success = await _uploadFileWithLock(fileName, data);
    if (success) return true;

    // 冲突：重新下载远端数据，合并后再试一次
    final remote = await _downloadFile(fileName);
    if (remote is List) {
      final localList = data is List
          ? List<Map<String, dynamic>>.from(data)
          : <Map<String, dynamic>>[];
      final remoteList = List<Map<String, dynamic>>.from(remote);
      final merged = _mergeLists(localList, remoteList);
      return _uploadFileWithLock(fileName, merged);
    } else if (remote is Map<String, dynamic> && data is Map<String, dynamic>) {
      final merged = <String, dynamic>{}
        ..addAll(remote)
        ..addAll(data);
      return _uploadFileWithLock(fileName, merged);
    }
    return false;
  }

  static Future<dynamic> _downloadFile(String fileName) async {
    try {
      final fileUrl = '$_webdavUrl/love_app_sync/$fileName';
      final res = await http
          .get(Uri.parse(fileUrl), headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        return jsonDecode(utf8.decode(res.bodyBytes));
      }
    } catch (e) {
      print("WebDAV download $fileName failed: $e");
    }
    return null;
  }

  /// 列表合并去重新算法：按 objectId 合并，若重复取 updatedAt 较晚者
  static List<Map<String, dynamic>> _mergeLists(
      List<Map<String, dynamic>> localList,
      List<Map<String, dynamic>> remoteList) {
    final Map<String, Map<String, dynamic>> map = {};
    for (var item in localList) {
      map[item['objectId']] = item;
    }
    for (var item in remoteList) {
      final objectId = item['objectId'];
      if (map.containsKey(objectId)) {
        final localItem = map[objectId]!;
        final localUpdate =
            DateTime.tryParse(localItem['updatedAt'] ?? '') ?? DateTime(2000);
        final remoteUpdate =
            DateTime.tryParse(item['updatedAt'] ?? '') ?? DateTime(2000);
        if (remoteUpdate.isAfter(localUpdate)) {
          map[objectId] = item;
        }
      } else {
        map[objectId] = item;
      }
    }
    return map.values.toList();
  }

  // --- 图片上传/删除 ---

  /// 上传图片到 WebDAV images 目录，返回文件名
  static Future<String?> _uploadImageBytes(
      String fileName, List<int> bytes) async {
    try {
      final fileUrl = '$_webdavUrl/love_app_sync/images/$fileName';
      await http
          .put(
            Uri.parse(fileUrl),
            headers: _headers,
            body: bytes,
          )
          .timeout(const Duration(seconds: 15));
      return fileName;
    } catch (e) {
      print('WebDAV upload image $fileName failed: $e');
      return null;
    }
  }

  /// 删除 WebDAV 上的图片文件
  static Future<void> _deleteImageFile(String fileName) async {
    try {
      final fileUrl = '$_webdavUrl/love_app_sync/images/$fileName';
      await http
          .delete(Uri.parse(fileUrl), headers: _headers)
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      print('WebDAV delete image $fileName failed: $e');
    }
  }

  // --- 日记同步 ---
  static Future<List<Map<String, dynamic>>> fetchDiaries() async {
    final localBox = Hive.box('diaries');
    final List<dynamic> localRaw = localBox.get('list') ?? [];
    final localList = List<Map<String, dynamic>>.from(
        localRaw.map((e) => Map<String, dynamic>.from(e as Map)));

    // 下载云端数据
    final remoteRaw = await _downloadFile('diaries.json');
    if (remoteRaw != null && remoteRaw is List) {
      final remoteList = List<Map<String, dynamic>>.from(
          remoteRaw.map((e) => Map<String, dynamic>.from(e as Map)));

      // 合并
      final merged = _mergeLists(localList, remoteList);
      merged.sort((a, b) =>
          (b['date'] as String).compareTo(a['date'] as String)); // 日期倒序

      await localBox.put('list', merged);
      return merged;
    }

    return localList;
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
          final fileName = 'img_${finalObjectId}.$ext';
          final uploaded = await _uploadImageBytes(fileName, bytes);
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
      'couple_id': coupleId,
      'content': content,
      'mood': mood,
      'weather': weather,
      'tags': tags,
      'date': date,
      'image_url': finalImageUrl,
      'creator_id': user?['objectId'] ?? 'webdav_user',
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };

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
    await _safeUploadWithRetry('diaries.json', list);
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
        await _deleteImageFile(img);
      }
    }

    list.removeWhere((item) => item['objectId'] == objectId);
    await box.put('list', list);
    await _safeUploadWithRetry('diaries.json', list);
  }

  // --- 心愿同步 ---
  static Future<List<Map<String, dynamic>>> fetchWishes() async {
    final localBox = Hive.box('wishes');
    final List<dynamic> localRaw = localBox.get('list') ?? [];
    final localList = List<Map<String, dynamic>>.from(
        localRaw.map((e) => Map<String, dynamic>.from(e as Map)));

    final remoteRaw = await _downloadFile('wishes.json');
    if (remoteRaw != null && remoteRaw is List) {
      final remoteList = List<Map<String, dynamic>>.from(
          remoteRaw.map((e) => Map<String, dynamic>.from(e as Map)));

      final merged = _mergeLists(localList, remoteList);
      await localBox.put('list', merged);
      return merged;
    }
    return localList;
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
    await _safeUploadWithRetry('wishes.json', list);
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
    await _safeUploadWithRetry('wishes.json', list);
  }

  static Future<void> deleteWish(String objectId) async {
    final box = Hive.box('wishes');
    final List<dynamic> rawList = box.get('list') ?? [];
    final List<Map<String, dynamic>> list = List<Map<String, dynamic>>.from(
        rawList.map((e) => Map<String, dynamic>.from(e as Map)));
    list.removeWhere((item) => item['objectId'] == objectId);
    await box.put('list', list);
    await _safeUploadWithRetry('wishes.json', list);
  }

  // --- 纪念日同步 ---
  static Future<List<Map<String, dynamic>>> fetchAnniversaries() async {
    final localBox = Hive.box('anniversaries');
    final List<dynamic> localRaw = localBox.get('list') ?? [];
    final localList = List<Map<String, dynamic>>.from(
        localRaw.map((e) => Map<String, dynamic>.from(e as Map)));

    final remoteRaw = await _downloadFile('anniversaries.json');
    if (remoteRaw != null && remoteRaw is List) {
      final remoteList = List<Map<String, dynamic>>.from(
          remoteRaw.map((e) => Map<String, dynamic>.from(e as Map)));

      final merged = _mergeLists(localList, remoteList);
      merged
          .sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
      await localBox.put('list', merged);
      return merged;
    }
    return localList;
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
    await _safeUploadWithRetry('anniversaries.json', list);
  }

  // --- 生理期同步 ---
  static Future<List<String>> fetchPeriodLogs() async {
    final localBox = Hive.box('period_logs');
    final localList = List<String>.from(localBox.get('list') ?? []);

    final remoteRaw = await _downloadFile('period_logs.json');
    if (remoteRaw != null && remoteRaw is List) {
      final remoteList = List<String>.from(remoteRaw);

      // 合并取并集
      final merged = Set<String>.from(localList)..addAll(remoteList);
      final mergedList = merged.toList();

      await localBox.put('list', mergedList);
      return mergedList;
    }
    return localList;
  }

  static Future<void> togglePeriodLog(String dateString, bool isPeriod) async {
    final box = Hive.box('period_logs');
    final List<String> list = List<String>.from(box.get('list') ?? []);
    if (isPeriod) {
      if (!list.contains(dateString)) {
        list.add(dateString);
      }
    } else {
      list.remove(dateString);
    }
    await box.put('list', list);
    await _safeUploadWithRetry('period_logs.json', list);
  }

  // --- 亲密记同步 ---
  static Future<List<Map<String, dynamic>>> fetchIntimacyLogs() async {
    final localBox = Hive.box('intimacy_logs');
    final List<dynamic> localRaw = localBox.get('list') ?? [];
    final localList = List<Map<String, dynamic>>.from(
        localRaw.map((e) => Map<String, dynamic>.from(e as Map)));

    final remoteRaw = await _downloadFile('intimacy_logs.json');
    if (remoteRaw != null && remoteRaw is List) {
      final remoteList = List<Map<String, dynamic>>.from(
          remoteRaw.map((e) => Map<String, dynamic>.from(e as Map)));

      final merged = _mergeLists(localList, remoteList);
      merged
          .sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));

      await localBox.put('list', merged);
      return merged;
    }
    return localList;
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
    await _safeUploadWithRetry('intimacy_logs.json', list);
  }
}
