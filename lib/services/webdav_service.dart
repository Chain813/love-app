import 'dart:convert';
import 'dart:math';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'db_config_service.dart';

class WebdavService {
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
    final credentials = base64Encode(utf8.encode('$_username:$_password'));
    return {
      'Authorization': 'Basic $credentials',
      'Content-Type': 'application/json',
    };
  }

  /// 验证 WebDAV 连接并登录
  static Future<Map<String, dynamic>> registerOrLogin(
      String username, String password) async {
    try {
      // 验证连接：发送 Propfind 请求到根目录或读取测试
      final client = http.Client();
      final req = http.Request('PROPFIND', Uri.parse(_webdavUrl))
        ..headers.addAll(_headers)
        ..headers['Depth'] = '0';
      
      final res = await client.send(req);
      if (res.statusCode != 207 && res.statusCode != 200) {
        throw Exception('WebDAV 验证失败，状态码: ${res.statusCode}，请检查配置与应用密码');
      }

      // 初始化同步目录
      await _createSyncDir();

      final box = await Hive.openBox('user');
      
      // 在 WebDAV 模式下，用配置的 WebDAV 账号作为登录标识
      var user = box.get('current_user') != null
          ? Map<String, dynamic>.from(box.get('current_user') as Map)
          : null;

      if (user == null || user['username'] != username) {
        final inviteCode = List.generate(6, (index) => Random().nextInt(10)).join();
        user = {
          'objectId': 'webdav_user_${_username.hashCode}',
          'username': username,
          'nickname': username,
          'invite_code': inviteCode,
          'status': 'paired', // WebDAV 共享同一文件夹，即为天然配对
          'gender': 'male',
          'couple_id': 'webdav_couple_${_username.hashCode}',
          'partner_id': 'webdav_partner_${_username.hashCode}',
          'sessionToken': 'webdav_token_mock',
        };
        await box.put('current_user', user);
      }

      // 尝试拉取或创建云端的 CoupleRelation
      await checkPairStatus();

      return user;
    } catch (e) {
      print("WebDAV Auth failed: $e");
      final currentCached = await getCurrentUser();
      if (currentCached != null && currentCached['username'] == username) {
        return currentCached;
      }
      throw Exception('WebDAV 登录失败：$e');
    }
  }

  /// 确保 WebDAV 同步文件夹存在
  static Future<void> _createSyncDir() async {
    try {
      final client = http.Client();
      final syncDirUrl = '$_webdavUrl/love_app_sync/';
      final req = http.Request('MKCOL', Uri.parse(syncDirUrl))
        ..headers.addAll(_headers);
      final res = await client.send(req);
      print('MKCOL love_app_sync response code: ${res.statusCode}');
    } catch (e) {
      print('MKCOL error: $e');
    }
  }

  /// 获取当前用户（本地）
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final box = await Hive.openBox('user');
    final user = box.get('current_user');
    if (user == null) return null;
    return Map<String, dynamic>.from(user as Map);
  }

  /// 获取本地保存的 Relation
  static Future<Map<String, dynamic>?> getLocalRelation() async {
    final box = await Hive.openBox('user');
    final relation = box.get('couple_relation');
    if (relation == null) return null;
    return Map<String, dynamic>.from(relation as Map);
  }

  /// 检查/同步配对关系
  static Future<Map<String, dynamic>?> checkPairStatus() async {
    final user = await getCurrentUser();
    if (user == null) return null;

    final fileUrl = '$_webdavUrl/love_app_sync/couple_relation.json';
    Map<String, dynamic>? remoteRelation;

    try {
      final res = await http.get(Uri.parse(fileUrl), headers: _headers);
      if (res.statusCode == 200) {
        remoteRelation = Map<String, dynamic>.from(jsonDecode(utf8.decode(res.bodyBytes)));
      }
    } catch (e) {
      print("WebDAV checkPairStatus fetch error: $e");
    }

    final localRel = await getLocalRelation();

    if (remoteRelation != null) {
      // 合并本地与远程的 Relation，通常取最新修改的，或者以远程为主
      final box = await Hive.openBox('user');
      await box.put('couple_relation', remoteRelation);
      return remoteRelation;
    } else {
      // 如果云端不存在且本地存在，则上传本地的到云端
      if (localRel != null) {
        await _uploadFile('couple_relation.json', localRel);
        return localRel;
      }
      
      // 双方都为空，则初始化
      final newRel = {
        'objectId': 'relation_webdav',
        'couple_id': user['couple_id'] ?? 'webdav_couple',
        'user1_id': 'user_1',
        'user2_id': 'user_2',
        'user1_name': '另一半',
        'user2_name': user['nickname'] ?? user['username'],
        'user1_gender': 'female',
        'user2_gender': user['gender'] ?? 'male',
        'heartbeat_count': 0,
        'first_met_date': '2025-05-20',
        'anniversary_date': '2025-05-20',
      };
      final box = await Hive.openBox('user');
      await box.put('couple_relation', newRel);
      await _uploadFile('couple_relation.json', newRel);
      return newRel;
    }
  }

  /// 本地邀请码配对（WebDAV 模式下直接通过配置同一个账号达成，无须手动配对）
  static Future<void> pairWithInviteCode(String inviteCode) async {
    await checkPairStatus();
  }

  /// 更新用户昵称
  static Future<void> updateNickname(String newNickname) async {
    final user = await getCurrentUser();
    if (user == null) throw Exception('请先登录');

    user['nickname'] = newNickname;
    final box = await Hive.openBox('user');
    await box.put('current_user', user);

    final relation = await getLocalRelation();
    if (relation != null) {
      relation['user2_name'] = newNickname;
      await box.put('couple_relation', relation);
      await _uploadFile('couple_relation.json', relation);
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
  }) async {
    final relation = await getLocalRelation();
    if (relation == null) throw Exception('未找到配对关系');

    relation['user1_name'] = user1Name;
    relation['user2_name'] = user2Name;
    relation['user1_gender'] = user1Gender;
    relation['user2_gender'] = user2Gender;
    relation['first_met_date'] = firstMetDate;
    relation['anniversary_date'] = anniversaryDate;

    final box = await Hive.openBox('user');
    await box.put('couple_relation', relation);
    await _uploadFile('couple_relation.json', relation);

    final user = await getCurrentUser();
    if (user != null) {
      user['nickname'] = user2Name;
      user['gender'] = user2Gender;
      await box.put('current_user', user);
    }
  }

  /// 发射爱心并云端同步递增
  static Future<int> sendHeartbeat() async {
    // 强制同步一次最新的计数
    final relation = await checkPairStatus();
    if (relation == null) return 0;

    final newCount = (relation['heartbeat_count'] ?? 0) + 1;
    relation['heartbeat_count'] = newCount;
    
    final box = await Hive.openBox('user');
    await box.put('couple_relation', relation);
    await _uploadFile('couple_relation.json', relation);
    return newCount;
  }

  static Future<void> deleteAccount() async {
    await logout();
  }

  static Future<void> logout() async {
    final box = await Hive.openBox('user');
    await box.delete('current_user');
    await box.delete('couple_relation');
  }

  // --- WebDAV 文件读写助手 ---
  static Future<void> _uploadFile(String fileName, dynamic data) async {
    try {
      final fileUrl = '$_webdavUrl/love_app_sync/$fileName';
      final bodyStr = jsonEncode(data);
      await http.put(
        Uri.parse(fileUrl),
        headers: _headers,
        body: utf8.encode(bodyStr),
      );
    } catch (e) {
      print("WebDAV upload $fileName failed: $e");
    }
  }

  static Future<dynamic> _downloadFile(String fileName) async {
    try {
      final fileUrl = '$_webdavUrl/love_app_sync/$fileName';
      final res = await http.get(Uri.parse(fileUrl), headers: _headers);
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
      List<Map<String, dynamic>> localList, List<Map<String, dynamic>> remoteList) {
    final Map<String, Map<String, dynamic>> map = {};
    for (var item in localList) {
      map[item['objectId']] = item;
    }
    for (var item in remoteList) {
      final objectId = item['objectId'];
      if (map.containsKey(objectId)) {
        final localItem = map[objectId]!;
        final localUpdate = DateTime.tryParse(localItem['updatedAt'] ?? '') ?? DateTime(2000);
        final remoteUpdate = DateTime.tryParse(item['updatedAt'] ?? '') ?? DateTime(2000);
        if (remoteUpdate.isAfter(localUpdate)) {
          map[objectId] = item;
        }
      } else {
        map[objectId] = item;
      }
    }
    return map.values.toList();
  }

  // --- 日记同步 ---
  static Future<List<Map<String, dynamic>>> fetchDiaries() async {
    final localBox = await Hive.openBox('diaries');
    final List<dynamic> localRaw = localBox.get('list') ?? [];
    final localList = List<Map<String, dynamic>>.from(
      localRaw.map((e) => Map<String, dynamic>.from(e as Map))
    );

    // 下载云端数据
    final remoteRaw = await _downloadFile('diaries.json');
    if (remoteRaw != null && remoteRaw is List) {
      final remoteList = List<Map<String, dynamic>>.from(
        remoteRaw.map((e) => Map<String, dynamic>.from(e as Map))
      );

      // 合并
      final merged = _mergeLists(localList, remoteList);
      merged.sort((a, b) => (b['date'] as String).compareTo(a['date'] as String)); // 日期倒序

      await localBox.put('list', merged);
      await _uploadFile('diaries.json', merged);
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

    final finalObjectId = objectId ?? 'webdav_diary_${DateTime.now().millisecondsSinceEpoch}';
    final body = {
      'objectId': finalObjectId,
      'couple_id': coupleId,
      'content': content,
      'mood': mood,
      'weather': weather,
      'tags': tags,
      'date': date,
      'image_url': imageUrl ?? '',
      'creator_id': user?['objectId'] ?? 'webdav_user',
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };

    final box = await Hive.openBox('diaries');
    final List<dynamic> rawList = box.get('list') ?? [];
    final List<Map<String, dynamic>> list = List<Map<String, dynamic>>.from(
      rawList.map((e) => Map<String, dynamic>.from(e as Map))
    );

    final index = list.indexWhere((item) => item['objectId'] == finalObjectId);
    if (index != -1) {
      list[index] = body;
    } else {
      list.insert(0, body);
    }
    await box.put('list', list);

    // 立即上传同步
    await _uploadFile('diaries.json', list);
  }

  static Future<void> deleteDiary(String objectId) async {
    final box = await Hive.openBox('diaries');
    final List<dynamic> rawList = box.get('list') ?? [];
    final List<Map<String, dynamic>> list = List<Map<String, dynamic>>.from(
      rawList.map((e) => Map<String, dynamic>.from(e as Map))
    );
    list.removeWhere((item) => item['objectId'] == objectId);
    await box.put('list', list);
    await _uploadFile('diaries.json', list);
  }

  // --- 心愿同步 ---
  static Future<List<Map<String, dynamic>>> fetchWishes() async {
    final localBox = await Hive.openBox('wishes');
    final List<dynamic> localRaw = localBox.get('list') ?? [];
    final localList = List<Map<String, dynamic>>.from(
      localRaw.map((e) => Map<String, dynamic>.from(e as Map))
    );

    final remoteRaw = await _downloadFile('wishes.json');
    if (remoteRaw != null && remoteRaw is List) {
      final remoteList = List<Map<String, dynamic>>.from(
        remoteRaw.map((e) => Map<String, dynamic>.from(e as Map))
      );

      final merged = _mergeLists(localList, remoteList);
      await localBox.put('list', merged);
      await _uploadFile('wishes.json', merged);
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

    final box = await Hive.openBox('wishes');
    final List<dynamic> rawList = box.get('list') ?? [];
    final List<Map<String, dynamic>> list = List<Map<String, dynamic>>.from(
      rawList.map((e) => Map<String, dynamic>.from(e as Map))
    );
    list.add(body);
    await box.put('list', list);
    await _uploadFile('wishes.json', list);
  }

  static Future<void> toggleWish(String objectId, bool completed) async {
    final box = await Hive.openBox('wishes');
    final List<dynamic> rawList = box.get('list') ?? [];
    final List<Map<String, dynamic>> list = List<Map<String, dynamic>>.from(
      rawList.map((e) => Map<String, dynamic>.from(e as Map))
    );
    final index = list.indexWhere((item) => item['objectId'] == objectId);
    if (index != -1) {
      list[index]['completed'] = completed;
      list[index]['completed_at'] = completed ? DateTime.now().toIso8601String() : '';
      list[index]['updatedAt'] = DateTime.now().toIso8601String();
    }
    await box.put('list', list);
    await _uploadFile('wishes.json', list);
  }

  static Future<void> deleteWish(String objectId) async {
    final box = await Hive.openBox('wishes');
    final List<dynamic> rawList = box.get('list') ?? [];
    final List<Map<String, dynamic>> list = List<Map<String, dynamic>>.from(
      rawList.map((e) => Map<String, dynamic>.from(e as Map))
    );
    list.removeWhere((item) => item['objectId'] == objectId);
    await box.put('list', list);
    await _uploadFile('wishes.json', list);
  }

  // --- 纪念日同步 ---
  static Future<List<Map<String, dynamic>>> fetchAnniversaries() async {
    final localBox = await Hive.openBox('anniversaries');
    final List<dynamic> localRaw = localBox.get('list') ?? [];
    final localList = List<Map<String, dynamic>>.from(
      localRaw.map((e) => Map<String, dynamic>.from(e as Map))
    );

    final remoteRaw = await _downloadFile('anniversaries.json');
    if (remoteRaw != null && remoteRaw is List) {
      final remoteList = List<Map<String, dynamic>>.from(
        remoteRaw.map((e) => Map<String, dynamic>.from(e as Map))
      );

      final merged = _mergeLists(localList, remoteList);
      merged.sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
      await localBox.put('list', merged);
      await _uploadFile('anniversaries.json', merged);
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

    final objectId = 'webdav_anniversary_${DateTime.now().millisecondsSinceEpoch}';
    final body = {
      'objectId': objectId,
      'couple_id': coupleId,
      'title': title,
      'date': date,
      'icon': icon,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };

    final box = await Hive.openBox('anniversaries');
    final List<dynamic> rawList = box.get('list') ?? [];
    final List<Map<String, dynamic>> list = List<Map<String, dynamic>>.from(
      rawList.map((e) => Map<String, dynamic>.from(e as Map))
    );
    list.add(body);
    list.sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
    await box.put('list', list);
    await _uploadFile('anniversaries.json', list);
  }

  // --- 生理期同步 ---
  static Future<List<String>> fetchPeriodLogs() async {
    final localBox = await Hive.openBox('period_logs');
    final localList = List<String>.from(localBox.get('list') ?? []);

    final remoteRaw = await _downloadFile('period_logs.json');
    if (remoteRaw != null && remoteRaw is List) {
      final remoteList = List<String>.from(remoteRaw);
      
      // 合并取并集
      final merged = Set<String>.from(localList)..addAll(remoteList);
      final mergedList = merged.toList();

      await localBox.put('list', mergedList);
      await _uploadFile('period_logs.json', mergedList);
      return mergedList;
    }
    return localList;
  }

  static Future<void> togglePeriodLog(String dateString, bool isPeriod) async {
    final box = await Hive.openBox('period_logs');
    final List<String> list = List<String>.from(box.get('list') ?? []);
    if (isPeriod) {
      if (!list.contains(dateString)) {
        list.add(dateString);
      }
    } else {
      list.remove(dateString);
    }
    await box.put('list', list);
    await _uploadFile('period_logs.json', list);
  }

  // --- 亲密记同步 ---
  static Future<List<Map<String, dynamic>>> fetchIntimacyLogs() async {
    final localBox = await Hive.openBox('intimacy_logs');
    final List<dynamic> localRaw = localBox.get('list') ?? [];
    final localList = List<Map<String, dynamic>>.from(
      localRaw.map((e) => Map<String, dynamic>.from(e as Map))
    );

    final remoteRaw = await _downloadFile('intimacy_logs.json');
    if (remoteRaw != null && remoteRaw is List) {
      final remoteList = List<Map<String, dynamic>>.from(
        remoteRaw.map((e) => Map<String, dynamic>.from(e as Map))
      );

      final merged = _mergeLists(localList, remoteList);
      merged.sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));

      await localBox.put('list', merged);
      await _uploadFile('intimacy_logs.json', merged);
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

    final finalObjectId = objectId ?? 'webdav_intimacy_${DateTime.now().millisecondsSinceEpoch}';
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

    final box = await Hive.openBox('intimacy_logs');
    final List<dynamic> rawList = box.get('list') ?? [];
    final List<Map<String, dynamic>> list = List<Map<String, dynamic>>.from(
      rawList.map((e) => Map<String, dynamic>.from(e as Map))
    );

    final index = list.indexWhere((item) => item['objectId'] == finalObjectId);
    if (index != -1) {
      list[index] = body;
    } else {
      list.insert(0, body);
    }
    await box.put('list', list);
    await _uploadFile('intimacy_logs.json', list);
  }
}
