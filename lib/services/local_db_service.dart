import 'dart:math';
import 'package:hive/hive.dart';

class LocalDbService {
  /// 注册或登录 (本地直接成功)
  static Future<Map<String, dynamic>> registerOrLogin(
      String username, String password) async {
    final box = await Hive.openBox('user');
    
    // 检查本地是否存在此用户
    Map<String, dynamic>? user = box.get('current_user') != null
        ? Map<String, dynamic>.from(box.get('current_user') as Map)
        : null;

    if (user != null && user['username'] == username) {
      return user;
    }

    // 新建本地 mock 账号
    final inviteCode = List.generate(6, (index) => Random().nextInt(10)).join();
    user = {
      'objectId': 'local_user_${DateTime.now().millisecondsSinceEpoch}',
      'username': username,
      'nickname': username,
      'invite_code': inviteCode,
      'status': 'single',
      'gender': 'male',
      'couple_id': null,
      'partner_id': null,
      'sessionToken': 'local_token_mock',
    };

    await box.put('current_user', user);
    return user;
  }

  /// 获取当前用户（从本地缓存）
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

  /// 检查或初始化本地配对关系 (单机模式默认直接自动配对成功，模拟情侣空间)
  static Future<Map<String, dynamic>?> checkPairStatus() async {
    final user = await getCurrentUser();
    if (user == null) return null;

    final localRel = await getLocalRelation();
    if (localRel != null) {
      return localRel;
    }

    // 默认自动配对，免除单机用户配对的困扰
    final relation = {
      'objectId': 'local_relation_${DateTime.now().millisecondsSinceEpoch}',
      'couple_id': 'local_couple_space',
      'user1_id': 'local_partner_123',
      'user2_id': user['objectId'],
      'user1_name': '另一半',
      'user2_name': user['nickname'] ?? user['username'],
      'user1_gender': 'female',
      'user2_gender': user['gender'] ?? 'male',
      'heartbeat_count': 0,
      'first_met_date': DateTime.now().toString().substring(0, 10),
      'anniversary_date': DateTime.now().toString().substring(0, 10),
    };

    final box = await Hive.openBox('user');
    await box.put('couple_relation', relation);

    user['status'] = 'paired';
    user['couple_id'] = 'local_couple_space';
    user['partner_id'] = 'local_partner_123';
    await box.put('current_user', user);

    return relation;
  }

  /// 模拟邀请码配对
  static Future<void> pairWithInviteCode(String inviteCode) async {
    final user = await getCurrentUser();
    if (user == null) throw Exception('请先登录');
    
    // 本地模式下，输入任意邀请码均立即强制配对成功
    final relation = {
      'objectId': 'local_relation_${DateTime.now().millisecondsSinceEpoch}',
      'couple_id': 'local_couple_space',
      'user1_id': 'local_partner_123',
      'user2_id': user['objectId'],
      'user1_name': '另一半',
      'user2_name': user['nickname'] ?? user['username'],
      'user1_gender': 'female',
      'user2_gender': user['gender'] ?? 'male',
      'heartbeat_count': 0,
      'first_met_date': DateTime.now().toString().substring(0, 10),
      'anniversary_date': DateTime.now().toString().substring(0, 10),
    };

    final box = await Hive.openBox('user');
    await box.put('couple_relation', relation);

    user['status'] = 'paired';
    user['couple_id'] = 'local_couple_space';
    user['partner_id'] = 'local_partner_123';
    await box.put('current_user', user);
  }

  /// 更新当前用户的昵称
  static Future<void> updateNickname(String newNickname) async {
    final user = await getCurrentUser();
    if (user == null) throw Exception('请先登录');

    user['nickname'] = newNickname;
    final box = await Hive.openBox('user');
    await box.put('current_user', user);

    // 同步更新配对关系中的名字
    final relation = await getLocalRelation();
    if (relation != null) {
      if (relation['user1_id'] == user['objectId']) {
        relation['user1_name'] = newNickname;
      } else {
        relation['user2_name'] = newNickname;
      }
      await box.put('couple_relation', relation);
    }
  }

  /// 更新本地共享空间配置
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

    final user = await getCurrentUser();
    if (user != null) {
      final isUser1 = relation['user1_id'] == user['objectId'];
      user['gender'] = isUser1 ? user1Gender : user2Gender;
      user['nickname'] = isUser1 ? user1Name : user2Name;
      await box.put('current_user', user);
    }
  }

  /// 发射爱心本地递增计数
  static Future<int> sendHeartbeat() async {
    final relation = await getLocalRelation();
    if (relation == null) return 0;

    final newCount = (relation['heartbeat_count'] ?? 0) + 1;
    relation['heartbeat_count'] = newCount;
    final box = await Hive.openBox('user');
    await box.put('couple_relation', relation);
    return newCount;
  }

  /// 本地注销
  static Future<void> deleteAccount() async {
    await logout();
  }

  /// 本地退出登录
  static Future<void> logout() async {
    final box = await Hive.openBox('user');
    await box.delete('current_user');
    await box.delete('couple_relation');
  }

  // --- 本地日记操作 ---
  static Future<List<Map<String, dynamic>>> fetchDiaries() async {
    final box = await Hive.openBox('diaries');
    final cached = box.get('list');
    if (cached != null) {
      return List<Map<String, dynamic>>.from(
        (cached as List).map((e) => Map<String, dynamic>.from(e as Map))
      );
    }
    return [];
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
    final coupleId = user?['couple_id'] ?? 'local_couple_space';

    final finalObjectId = objectId ?? 'local_diary_${DateTime.now().millisecondsSinceEpoch}';
    final body = {
      'objectId': finalObjectId,
      'couple_id': coupleId,
      'content': content,
      'mood': mood,
      'weather': weather,
      'tags': tags,
      'date': date,
      'image_url': imageUrl ?? '',
      'creator_id': user?['objectId'] ?? 'local_user',
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
  }

  static Future<void> deleteDiary(String objectId) async {
    final box = await Hive.openBox('diaries');
    final List<dynamic> rawList = box.get('list') ?? [];
    final List<Map<String, dynamic>> list = List<Map<String, dynamic>>.from(
      rawList.map((e) => Map<String, dynamic>.from(e as Map))
    );
    list.removeWhere((item) => item['objectId'] == objectId);
    await box.put('list', list);
  }

  // --- 本地心愿操作 ---
  static Future<List<Map<String, dynamic>>> fetchWishes() async {
    final box = await Hive.openBox('wishes');
    final cached = box.get('list');
    if (cached != null) {
      return List<Map<String, dynamic>>.from(
        (cached as List).map((e) => Map<String, dynamic>.from(e as Map))
      );
    }
    return [];
  }

  static Future<void> saveWish({
    required String title,
    bool completed = false,
  }) async {
    final user = await getCurrentUser();
    final coupleId = user?['couple_id'] ?? 'local_couple_space';

    final objectId = 'local_wish_${DateTime.now().millisecondsSinceEpoch}';
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
    }
    await box.put('list', list);
  }

  static Future<void> deleteWish(String objectId) async {
    final box = await Hive.openBox('wishes');
    final List<dynamic> rawList = box.get('list') ?? [];
    final List<Map<String, dynamic>> list = List<Map<String, dynamic>>.from(
      rawList.map((e) => Map<String, dynamic>.from(e as Map))
    );
    list.removeWhere((item) => item['objectId'] == objectId);
    await box.put('list', list);
  }

  // --- 本地纪念日操作 ---
  static Future<List<Map<String, dynamic>>> fetchAnniversaries() async {
    final box = await Hive.openBox('anniversaries');
    final cached = box.get('list');
    if (cached != null) {
      return List<Map<String, dynamic>>.from(
        (cached as List).map((e) => Map<String, dynamic>.from(e as Map))
      );
    }
    return [];
  }

  static Future<void> saveAnniversary({
    required String title,
    required String date,
    required String icon,
  }) async {
    final user = await getCurrentUser();
    final coupleId = user?['couple_id'] ?? 'local_couple_space';

    final objectId = 'local_anniversary_${DateTime.now().millisecondsSinceEpoch}';
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
  }

  // --- 本地生理期操作 ---
  static Future<List<String>> fetchPeriodLogs() async {
    final box = await Hive.openBox('period_logs');
    final cached = box.get('list');
    if (cached != null) {
      return List<String>.from(cached as List);
    }
    return [];
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
  }

  // --- 本地亲密记操作 ---
  static Future<List<Map<String, dynamic>>> fetchIntimacyLogs() async {
    final box = await Hive.openBox('intimacy_logs');
    final cached = box.get('list');
    if (cached != null) {
      return List<Map<String, dynamic>>.from(
        (cached as List).map((e) => Map<String, dynamic>.from(e as Map))
      );
    }
    return [];
  }

  static Future<void> saveIntimacyLog({
    String? objectId,
    required String date,
    required String mood,
    required double rating,
    required String note,
  }) async {
    final user = await getCurrentUser();
    final coupleId = user?['couple_id'] ?? 'local_couple_space';

    final finalObjectId = objectId ?? 'local_intimacy_${DateTime.now().millisecondsSinceEpoch}';
    final body = {
      'objectId': finalObjectId,
      'couple_id': coupleId,
      'date': date,
      'mood': mood,
      'rating': rating,
      'note': note,
      'creator_id': user?['objectId'] ?? 'local_user',
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
  }
}
