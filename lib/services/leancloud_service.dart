import 'dart:convert';
import 'dart:math';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import '../config/constants.dart';

/// LeanCloud / TDS 服务层 - 真实 REST API 实现
class LeanCloudService {
  static const String _baseUrl = AppConstants.leanCloudServerUrl;
  static const String _appId = AppConstants.leanCloudAppId;
  static const String _appKey = AppConstants.leanCloudAppKey;

  static Map<String, String> get _headers => {
        'X-LC-Id': _appId,
        'X-LC-Key': _appKey,
        'Content-Type': 'application/json',
      };

  static Map<String, String> _authenticatedHeaders(String sessionToken) {
    return {
      ..._headers,
      'X-LC-Session': sessionToken,
    };
  }

  static Future<void> initialize() async {
    // REST API client doesn't need SDK level configuration
  }

  /// 注册或登录
  static Future<Map<String, dynamic>> registerOrLogin(
      String username, String password) async {
    try {
      // 1. 查询用户是否存在
      final queryUrl = Uri.parse('$_baseUrl/1.1/users?where=${Uri.encodeComponent('{"username":"$username"}')}');
      final queryResponse = await http.get(queryUrl, headers: _headers);

      if (queryResponse.statusCode == 200) {
        final queryData = jsonDecode(queryResponse.body);
        final List results = queryData['results'] ?? [];

        if (results.isNotEmpty) {
          // 用户存在，直接登录
          final loginUrl = Uri.parse('$_baseUrl/1.1/login');
          final loginResponse = await http.post(
            loginUrl,
            headers: _headers,
            body: jsonEncode({
              'username': username,
              'password': password,
            }),
          );

          if (loginResponse.statusCode == 200) {
            final userData = jsonDecode(loginResponse.body);
            await _saveUserToLocal(userData);
            return userData;
          } else {
            final errorData = jsonDecode(loginResponse.body);
            throw Exception(errorData['error'] ?? '登录失败，请检查密码');
          }
        } else {
          // 用户不存在，注册新账号
          final registerUrl = Uri.parse('$_baseUrl/1.1/users');
          
          // 循环生成不重复的唯一邀请码
          String inviteCode = _generateInviteCode();
          bool isUnique = false;
          int attempts = 0;
          while (!isUnique && attempts < 10) {
            try {
              isUnique = await _isInviteCodeUnique(inviteCode);
              if (!isUnique) {
                inviteCode = _generateInviteCode();
              }
            } catch (e) {
              print('检查邀请码唯一性时出错: $e');
              inviteCode = _generateInviteCode();
            }
            attempts++;
          }

          if (!isUnique) {
            throw Exception('生成唯一邀请码失败，请检查网络后重试');
          }

          final registerBody = {
            'username': username,
            'password': password,
            'nickname': username,
            'invite_code': inviteCode,
            'status': 'single',
            'gender': 'male', // 默认性别男，在初始化页面修改
          };

          final registerResponse = await http.post(
            registerUrl,
            headers: _headers,
            body: jsonEncode(registerBody),
          );

          if (registerResponse.statusCode == 201) {
            final userData = jsonDecode(registerResponse.body);
            final Map<String, dynamic> finalUser = {
              ...registerBody,
              ...userData,
            };
            await _saveUserToLocal(finalUser);
            return finalUser;
          } else {
            final errorData = jsonDecode(registerResponse.body);
            throw Exception(errorData['error'] ?? '注册失败，请重试');
          }
        }
      } else {
        throw Exception('网络连接异常：${queryResponse.statusCode}');
      }
    } catch (e) {
      print("TDS Network failed. Check local cache: $e");
      // Check if we already have a cached current_user with this name to preserve it
      final currentCached = await getCurrentUser();
      if (currentCached != null && currentCached['username'] == username) {
        return currentCached;
      }
      
      // If we don't have it cached, throw the error instead of silently registering offline
      throw Exception('无法连接至云端服务，请检查网络或确认数据库是否可用：$e');
    }
  }

  /// 获取当前用户（从本地缓存）
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final box = await Hive.openBox('user');
    final user = box.get('current_user');
    if (user == null) return null;
    return Map<String, dynamic>.from(user as Map);
  }

  /// 保存用户信息到本地
  static Future<void> _saveUserToLocal(Map<String, dynamic> user) async {
    final box = await Hive.openBox('user');
    await box.put('current_user', user);
  }

  /// 获取本地保存的 Relation
  static Future<Map<String, dynamic>?> getLocalRelation() async {
    final box = await Hive.openBox('user');
    final relation = box.get('couple_relation');
    if (relation == null) return null;
    return Map<String, dynamic>.from(relation as Map);
  }

  /// 检查配对状态
  static Future<Map<String, dynamic>?> checkPairStatus() async {
    final user = await getCurrentUser();
    if (user == null) return null;

    final userId = user['objectId'];
    final query = '{"\$or":[{"user1_id":"$userId"},{"user2_id":"$userId"}]}';
    final url = Uri.parse('$_baseUrl/1.1/classes/CoupleRelation?where=${Uri.encodeComponent(query)}');

    try {
      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List results = data['results'] ?? [];
        if (results.isNotEmpty) {
          final relation = results.first;
          final box = await Hive.openBox('user');
          await box.put('couple_relation', relation);

          // 更新本地用户状态为已配对
          user['status'] = 'paired';
          user['couple_id'] = relation['couple_id'];
          user['partner_id'] = relation['user1_id'] == userId ? relation['user2_id'] : relation['user1_id'];
          await _saveUserToLocal(user);

          return relation;
        }
      }
    } catch (e) {
      print("checkPairStatus offline fallback: $e");
    }

    // Offline fallback
    final localRel = await getLocalRelation();
    if (localRel != null) {
      return localRel;
    }

    if (user['status'] == 'paired' && user['couple_id'] != null) {
      final relation = {
        'objectId': 'relation_offline_123',
        'couple_id': user['couple_id'],
        'user1_id': user['partner_id'] ?? 'offline_partner',
        'user2_id': userId,
        'user1_name': '小红',
        'user2_name': user['nickname'] ?? user['username'],
        'user1_gender': 'female',
        'user2_gender': user['gender'] ?? 'male',
        'heartbeat_count': 0,
        'first_met_date': '2025-05-20',
        'anniversary_date': '2025-05-20',
      };
      final box = await Hive.openBox('user');
      await box.put('couple_relation', relation);
      return relation;
    }

    return null;
  }

  /// 通过邀请码配对
  static Future<void> pairWithInviteCode(String inviteCode) async {
    final currentUser = await getCurrentUser();
    if (currentUser == null) throw Exception('请先登录');

    final currentUserId = currentUser['objectId'];
    final currentUserNickname = currentUser['nickname'] ?? currentUser['username'];

    try {
      // 1. 查询持有此邀请码的另一位用户
      final queryUrl = Uri.parse('$_baseUrl/1.1/users?where=${Uri.encodeComponent('{"invite_code":"$inviteCode"}')}');
      final response = await http.get(queryUrl, headers: _headers);

      if (response.statusCode != 200) {
        throw Exception('网络查询失败：${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      final List results = data['results'] ?? [];
      if (results.isEmpty) {
        throw Exception('邀请码无效，请确认对方邀请码是否正确');
      }

      final partnerUser = results.first;
      final partnerId = partnerUser['objectId'];
      final partnerNickname = partnerUser['nickname'] ?? partnerUser['username'];

      if (partnerId == currentUserId) {
        throw Exception('不能与自己配对哦！');
      }

      // 2. 检查是否已经被别人配对
      final checkUrl = Uri.parse('$_baseUrl/1.1/classes/CoupleRelation?where=${Uri.encodeComponent('{"\$or":[{"user1_id":"$partnerId"},{"user2_id":"$partnerId"},{"user1_id":"$currentUserId"},{"user2_id":"$currentUserId"}]}')}');
      final checkResponse = await http.get(checkUrl, headers: _headers);
      if (checkResponse.statusCode == 200) {
        final checkData = jsonDecode(checkResponse.body);
        final List relations = checkData['results'] ?? [];
        if (relations.isNotEmpty) {
          throw Exception('您或对方已经处于配对状态了');
        }
      }

      // 3. 创建 CoupleRelation 配对关系
      final coupleId = 'couple_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
      final relationBody = {
        'user1_id': partnerId,
        'user2_id': currentUserId,
        'user1_name': partnerNickname,
        'user2_name': currentUserNickname,
        'user1_gender': partnerUser['gender'] ?? 'female',
        'user2_gender': currentUser['gender'] ?? 'male',
        'couple_id': coupleId,
        'heartbeat_count': 0,
        'first_met_date': '',
        'anniversary_date': '',
      };

      final createRelationUrl = Uri.parse('$_baseUrl/1.1/classes/CoupleRelation');
      final createResponse = await http.post(
        createRelationUrl,
        headers: _headers,
        body: jsonEncode(relationBody),
      );

      if (createResponse.statusCode == 201) {
        // 成功配对
        await checkPairStatus();
      } else {
        final errorData = jsonDecode(createResponse.body);
        throw Exception(errorData['error'] ?? '创建关系失败');
      }
    } catch (e) {
      print("pairWithInviteCode error: $e");
      rethrow;
    }
  }

  /// 更新当前用户的昵称
  static Future<void> updateNickname(String newNickname) async {
    final user = await getCurrentUser();
    if (user == null) throw Exception('请先登录');

    final userId = user['objectId'];
    final sessionToken = user['sessionToken'] ?? '';

    // 1. 更新本地缓存
    user['nickname'] = newNickname;
    await _saveUserToLocal(user);

    // 2. 更新云端数据库
    try {
      final url = Uri.parse('$_baseUrl/1.1/users/$userId');
      final headers = sessionToken.isNotEmpty
          ? _authenticatedHeaders(sessionToken)
          : _headers;
      
      await http.put(
        url,
        headers: headers,
        body: jsonEncode({
          'nickname': newNickname,
        }),
      );
    } catch (e) {
      print("updateNickname cloud failure, using local cache: $e");
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
    if (relation == null) throw Exception('未找到配对关系，无法更新');

    final objectId = relation['objectId'];
    final url = Uri.parse('$_baseUrl/1.1/classes/CoupleRelation/$objectId');

    final updateBody = {
      'user1_name': user1Name,
      'user2_name': user2Name,
      'user1_gender': user1Gender,
      'user2_gender': user2Gender,
      'first_met_date': firstMetDate,
      'anniversary_date': anniversaryDate,
    };

    final currentUser = await getCurrentUser();

    try {
      final response = await http.put(
        url,
        headers: _headers,
        body: jsonEncode(updateBody),
      );

      if (response.statusCode == 200) {
        if (currentUser != null) {
          final currentUserId = currentUser['objectId'];
          final currentGender = relation['user1_id'] == currentUserId ? user1Gender : user2Gender;
          final currentNickname = relation['user1_id'] == currentUserId ? user1Name : user2Name;
          
          currentUser['gender'] = currentGender;
          currentUser['nickname'] = currentNickname;
          await _saveUserToLocal(currentUser);

          // 更新本地用户表在云端的字段
          final userUrl = Uri.parse('$_baseUrl/1.1/users/$currentUserId');
          await http.put(
            userUrl,
            headers: _headers,
            body: jsonEncode({
              'gender': currentGender,
              'nickname': currentNickname,
            }),
          );
        }
      } else {
        print("Cloud update failed with status: ${response.statusCode}");
      }
    } catch (e) {
      print("updateCoupleSettings offline fallback: $e");
    }

    // Save locally to preserve changes
    relation['user1_name'] = user1Name;
    relation['user2_name'] = user2Name;
    relation['user1_gender'] = user1Gender;
    relation['user2_gender'] = user2Gender;
    relation['first_met_date'] = firstMetDate;
    relation['anniversary_date'] = anniversaryDate;

    final box = await Hive.openBox('user');
    await box.put('couple_relation', relation);

    if (currentUser != null) {
      final currentUserId = currentUser['objectId'];
      final currentGender = relation['user1_id'] == currentUserId ? user1Gender : user2Gender;
      final currentNickname = relation['user1_id'] == currentUserId ? user1Name : user2Name;
      
      currentUser['gender'] = currentGender;
      currentUser['nickname'] = currentNickname;
      await _saveUserToLocal(currentUser);
    }
  }

  /// 发射爱心，云端递增计数
  static Future<int> sendHeartbeat() async {
    final relation = await getLocalRelation();
    if (relation == null) return 0;

    final objectId = relation['objectId'];
    final url = Uri.parse('$_baseUrl/1.1/classes/CoupleRelation/$objectId');

    final body = {
      'heartbeat_count': {
        '__op': 'Increment',
        'amount': 1,
      }
    };

    try {
      final response = await http.put(
        url,
        headers: _headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final updatedRelation = jsonDecode(response.body);
        final newCount = updatedRelation['heartbeat_count'] ?? ((relation['heartbeat_count'] ?? 0) + 1);
        
        relation['heartbeat_count'] = newCount;
        final box = await Hive.openBox('user');
        await box.put('couple_relation', relation);
        return newCount;
      }
    } catch (e) {
      print("sendHeartbeat offline fallback: $e");
    }

    // Local increment
    final newCount = (relation['heartbeat_count'] ?? 0) + 1;
    relation['heartbeat_count'] = newCount;
    final box = await Hive.openBox('user');
    await box.put('couple_relation', relation);
    return newCount;
  }

  /// 注销账号
  static Future<void> deleteAccount() async {
    final user = await getCurrentUser();
    if (user != null) {
      try {
        final userId = user['objectId'];
        final sessionToken = user['sessionToken'] ?? '';
        final url = Uri.parse('$_baseUrl/1.1/users/$userId');
        await http.delete(url, headers: _authenticatedHeaders(sessionToken));
      } catch (e) {
        print("deleteAccount cloud failure: $e");
      }
    }
    await logout();
  }

  /// 退出登录
  static Future<void> logout() async {
    final box = await Hive.openBox('user');
    await box.delete('current_user');
    await box.delete('couple_relation');
  }

  /// ----------------------------------------
  /// 日记模块云同步
  /// ----------------------------------------

  static Future<List<Map<String, dynamic>>> fetchDiaries() async {
    try {
      final user = await getCurrentUser();
      if (user == null || user['couple_id'] == null) return [];

      final coupleId = user['couple_id'];
      final url = Uri.parse('$_baseUrl/1.1/classes/Diary?where=${Uri.encodeComponent('{"couple_id":"$coupleId"}')}&order=-date');

      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List results = data['results'] ?? [];
        final list = List<Map<String, dynamic>>.from(results);
        
        final box = await Hive.openBox('diaries');
        await box.put('list', list);
        return list;
      }
    } catch (e) {
      print("fetchDiaries offline fallback: $e");
    }

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
    if (user == null || user['couple_id'] == null) throw Exception('未登录');

    final coupleId = user['couple_id'];
    final finalObjectId = objectId ?? 'offline_diary_${DateTime.now().millisecondsSinceEpoch}';
    final body = {
      'objectId': finalObjectId,
      'couple_id': coupleId,
      'content': content,
      'mood': mood,
      'weather': weather,
      'tags': tags,
      'date': date,
      'image_url': imageUrl ?? '',
      'creator_id': user['objectId'],
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };

    try {
      if (objectId != null) {
        final url = Uri.parse('$_baseUrl/1.1/classes/Diary/$objectId');
        await http.put(url, headers: _headers, body: jsonEncode(body));
      } else {
        final url = Uri.parse('$_baseUrl/1.1/classes/Diary');
        await http.post(url, headers: _headers, body: jsonEncode(body));
      }
    } catch (e) {
      print("saveDiary offline fallback: $e");
    }

    // Save to local cache
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
    try {
      final url = Uri.parse('$_baseUrl/1.1/classes/Diary/$objectId');
      await http.delete(url, headers: _headers);
    } catch (e) {
      print("deleteDiary offline fallback: $e");
    }

    final box = await Hive.openBox('diaries');
    final List<dynamic> rawList = box.get('list') ?? [];
    final List<Map<String, dynamic>> list = List<Map<String, dynamic>>.from(
      rawList.map((e) => Map<String, dynamic>.from(e as Map))
    );
    list.removeWhere((item) => item['objectId'] == objectId);
    await box.put('list', list);
  }

  /// ----------------------------------------
  /// 心愿模块云同步
  /// ----------------------------------------

  static Future<List<Map<String, dynamic>>> fetchWishes() async {
    try {
      final user = await getCurrentUser();
      if (user == null || user['couple_id'] == null) return [];

      final coupleId = user['couple_id'];
      final url = Uri.parse('$_baseUrl/1.1/classes/Wish?where=${Uri.encodeComponent('{"couple_id":"$coupleId"}')}&order=createdAt');

      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List results = data['results'] ?? [];
        final list = List<Map<String, dynamic>>.from(results);
        
        final box = await Hive.openBox('wishes');
        await box.put('list', list);
        return list;
      }
    } catch (e) {
      print("fetchWishes offline fallback: $e");
    }

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
    if (user == null || user['couple_id'] == null) throw Exception('未登录');

    final coupleId = user['couple_id'];
    final objectId = 'offline_wish_${DateTime.now().millisecondsSinceEpoch}';
    final body = {
      'objectId': objectId,
      'couple_id': coupleId,
      'title': title,
      'completed': completed,
      'completed_at': completed ? DateTime.now().toIso8601String() : '',
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };

    try {
      final url = Uri.parse('$_baseUrl/1.1/classes/Wish');
      await http.post(url, headers: _headers, body: jsonEncode(body));
    } catch (e) {
      print("saveWish offline fallback: $e");
    }

    final box = await Hive.openBox('wishes');
    final List<dynamic> rawList = box.get('list') ?? [];
    final List<Map<String, dynamic>> list = List<Map<String, dynamic>>.from(
      rawList.map((e) => Map<String, dynamic>.from(e as Map))
    );
    list.add(body);
    await box.put('list', list);
  }

  static Future<void> toggleWish(String objectId, bool completed) async {
    try {
      final url = Uri.parse('$_baseUrl/1.1/classes/Wish/$objectId');
      final body = {
        'completed': completed,
        'completed_at': completed ? DateTime.now().toIso8601String() : '',
      };
      await http.put(url, headers: _headers, body: jsonEncode(body));
    } catch (e) {
      print("toggleWish offline fallback: $e");
    }

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
    try {
      final url = Uri.parse('$_baseUrl/1.1/classes/Wish/$objectId');
      await http.delete(url, headers: _headers);
    } catch (e) {
      print("deleteWish offline fallback: $e");
    }

    final box = await Hive.openBox('wishes');
    final List<dynamic> rawList = box.get('list') ?? [];
    final List<Map<String, dynamic>> list = List<Map<String, dynamic>>.from(
      rawList.map((e) => Map<String, dynamic>.from(e as Map))
    );
    list.removeWhere((item) => item['objectId'] == objectId);
    await box.put('list', list);
  }

  /// ----------------------------------------
  /// 纪念日模块云同步
  /// ----------------------------------------

  static Future<List<Map<String, dynamic>>> fetchAnniversaries() async {
    try {
      final user = await getCurrentUser();
      if (user == null || user['couple_id'] == null) return [];

      final coupleId = user['couple_id'];
      final url = Uri.parse('$_baseUrl/1.1/classes/Anniversary?where=${Uri.encodeComponent('{"couple_id":"$coupleId"}')}&order=date');

      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List results = data['results'] ?? [];
        final list = List<Map<String, dynamic>>.from(results);
        
        final box = await Hive.openBox('anniversaries');
        await box.put('list', list);
        return list;
      }
    } catch (e) {
      print("fetchAnniversaries offline fallback: $e");
    }

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
    if (user == null || user['couple_id'] == null) throw Exception('未登录');

    final coupleId = user['couple_id'];
    final objectId = 'offline_anniversary_${DateTime.now().millisecondsSinceEpoch}';
    final body = {
      'objectId': objectId,
      'couple_id': coupleId,
      'title': title,
      'date': date,
      'icon': icon,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };

    try {
      final url = Uri.parse('$_baseUrl/1.1/classes/Anniversary');
      await http.post(url, headers: _headers, body: jsonEncode(body));
    } catch (e) {
      print("saveAnniversary offline fallback: $e");
    }

    final box = await Hive.openBox('anniversaries');
    final List<dynamic> rawList = box.get('list') ?? [];
    final List<Map<String, dynamic>> list = List<Map<String, dynamic>>.from(
      rawList.map((e) => Map<String, dynamic>.from(e as Map))
    );
    list.add(body);
    list.sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
    await box.put('list', list);
  }

  /// ----------------------------------------
  /// 生理期与亲密记（爱爱记录）云端管理
  /// ----------------------------------------

  static Future<List<String>> fetchPeriodLogs() async {
    try {
      final user = await getCurrentUser();
      if (user == null || user['couple_id'] == null) return [];

      final coupleId = user['couple_id'];
      final url = Uri.parse('$_baseUrl/1.1/classes/PeriodLog?where=${Uri.encodeComponent('{"couple_id":"$coupleId"}')}&limit=500');

      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List results = data['results'] ?? [];
        final list = results.map((e) => e['date'] as String).toList();
        
        final box = await Hive.openBox('period_logs');
        await box.put('list', list);
        return list;
      }
    } catch (e) {
      print("fetchPeriodLogs offline fallback: $e");
    }

    final box = await Hive.openBox('period_logs');
    final cached = box.get('list');
    if (cached != null) {
      return List<String>.from(cached as List);
    }
    return [];
  }

  static Future<void> togglePeriodLog(String dateString, bool isPeriod) async {
    final user = await getCurrentUser();
    if (user == null || user['couple_id'] == null) throw Exception('未登录');
    final coupleId = user['couple_id'];

    try {
      if (isPeriod) {
        // 1. 检查是否已存在
        final query = '{"couple_id":"$coupleId","date":"$dateString"}';
        final checkUrl = Uri.parse('$_baseUrl/1.1/classes/PeriodLog?where=${Uri.encodeComponent(query)}');
        final checkRes = await http.get(checkUrl, headers: _headers);
        if (checkRes.statusCode == 200) {
          final checkData = jsonDecode(checkRes.body);
          final List results = checkData['results'] ?? [];
          if (results.isEmpty) {
            final url = Uri.parse('$_baseUrl/1.1/classes/PeriodLog');
            await http.post(
              url,
              headers: _headers,
              body: jsonEncode({
                'couple_id': coupleId,
                'date': dateString,
              }),
            );
          }
        }
      } else {
        // 删除记录
        final query = '{"couple_id":"$coupleId","date":"$dateString"}';
        final queryUrl = Uri.parse('$_baseUrl/1.1/classes/PeriodLog?where=${Uri.encodeComponent(query)}');
        final queryRes = await http.get(queryUrl, headers: _headers);
        if (queryRes.statusCode == 200) {
          final queryData = jsonDecode(queryRes.body);
          final List results = queryData['results'] ?? [];
          if (results.isNotEmpty) {
            final objectId = results.first['objectId'];
            final deleteUrl = Uri.parse('$_baseUrl/1.1/classes/PeriodLog/$objectId');
            await http.delete(deleteUrl, headers: _headers);
          }
        }
      }
    } catch (e) {
      print("togglePeriodLog offline fallback: $e");
    }

    // Cache locally
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

  static Future<List<Map<String, dynamic>>> fetchIntimacyLogs() async {
    try {
      final user = await getCurrentUser();
      if (user == null || user['couple_id'] == null) return [];

      final coupleId = user['couple_id'];
      final url = Uri.parse('$_baseUrl/1.1/classes/IntimacyLog?where=${Uri.encodeComponent('{"couple_id":"$coupleId"}')}&order=-date');

      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List results = data['results'] ?? [];
        final list = List<Map<String, dynamic>>.from(results);
        
        final box = await Hive.openBox('intimacy_logs');
        await box.put('list', list);
        return list;
      }
    } catch (e) {
      print("fetchIntimacyLogs offline fallback: $e");
    }

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
    if (user == null || user['couple_id'] == null) throw Exception('未登录');
    final coupleId = user['couple_id'];

    final finalObjectId = objectId ?? 'offline_intimacy_${DateTime.now().millisecondsSinceEpoch}';
    final body = {
      'objectId': finalObjectId,
      'couple_id': coupleId,
      'date': date,
      'mood': mood,
      'rating': rating,
      'note': note,
      'creator_id': user['objectId'],
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };

    try {
      if (objectId != null) {
        final url = Uri.parse('$_baseUrl/1.1/classes/IntimacyLog/$objectId');
        await http.put(url, headers: _headers, body: jsonEncode(body));
      } else {
        final url = Uri.parse('$_baseUrl/1.1/classes/IntimacyLog');
        await http.post(url, headers: _headers, body: jsonEncode(body));
      }
    } catch (e) {
      print("saveIntimacyLog offline fallback: $e");
    }

    // Cache locally
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

  /// ----------------------------------------
  /// 辅助生成器
  /// ----------------------------------------

  static String _generateInviteCode() {
    final random = Random();
    return List.generate(6, (index) => random.nextInt(10)).join();
  }

  static Future<bool> _isInviteCodeUnique(String inviteCode) async {
    final queryUrl = Uri.parse('$_baseUrl/1.1/users?where=${Uri.encodeComponent('{"invite_code":"$inviteCode"}')}');
    final response = await http.get(queryUrl, headers: _headers);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List results = data['results'] ?? [];
      return results.isEmpty;
    }
    throw Exception('校验邀请码唯一性失败，状态码: ${response.statusCode}');
  }
}
