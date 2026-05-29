import 'dart:convert';
import 'dart:math';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'db_config_service.dart';

class SupabaseService {
  static String get _baseUrl => DbConfigService.supabaseUrl;
  static String get _anonKey => DbConfigService.supabaseAnonKey;

  static Map<String, String> get _headers => {
        'apikey': _anonKey,
        'Content-Type': 'application/json',
        'Prefer': 'return=representation',
      };

  static Map<String, String> _authHeaders(String sessionToken) {
    return {
      ..._headers,
      'Authorization': 'Bearer $sessionToken',
    };
  }

  /// 注册或登录
  static Future<Map<String, dynamic>> registerOrLogin(
      String username, String password) async {
    final sanitizedEmail = '${username.trim().toLowerCase()}@chongmi.com';
    
    try {
      // 1. 查询用户 Profile 是否已存在
      final profileUrl = Uri.parse('$_baseUrl/rest/v1/Profile?username=eq.${Uri.encodeComponent(username.trim())}');
      final profileRes = await http.get(profileUrl, headers: _headers);
      
      bool userExists = false;
      Map<String, dynamic>? existingProfile;
      if (profileRes.statusCode == 200) {
        final List profiles = jsonDecode(profileRes.body);
        if (profiles.isNotEmpty) {
          userExists = true;
          existingProfile = Map<String, dynamic>.from(profiles.first);
        }
      }

      if (userExists && existingProfile != null) {
        // 2. 用户存在，直接登录
        final loginUrl = Uri.parse('$_baseUrl/auth/v1/token?grant_type=password');
        final loginRes = await http.post(
          loginUrl,
          headers: _headers,
          body: jsonEncode({
            'email': sanitizedEmail,
            'password': password,
          }),
        );

        if (loginRes.statusCode == 200) {
          final loginData = jsonDecode(loginRes.body);
          final sessionToken = loginData['access_token'];
          
          final Map<String, dynamic> finalUser = {
            'objectId': existingProfile['objectId'],
            'username': username,
            'nickname': existingProfile['nickname'] ?? username,
            'invite_code': existingProfile['invite_code'],
            'status': existingProfile['status'] ?? 'single',
            'gender': existingProfile['gender'] ?? 'male',
            'couple_id': existingProfile['couple_id'],
            'partner_id': existingProfile['partner_id'],
            'sessionToken': sessionToken,
          };

          await _saveUserToLocal(finalUser);
          return finalUser;
        } else {
          final errorData = jsonDecode(loginRes.body);
          throw Exception(errorData['error_description'] ?? errorData['msg'] ?? '登录失败，请检查密码');
        }
      } else {
        // 3. 用户不存在，注册新账号
        final signupUrl = Uri.parse('$_baseUrl/auth/v1/signup');
        
        // 循环生成唯一的邀请码
        String inviteCode = _generateInviteCode();
        bool isUnique = false;
        int attempts = 0;
        while (!isUnique && attempts < 10) {
          isUnique = await _isInviteCodeUnique(inviteCode);
          if (!isUnique) {
            inviteCode = _generateInviteCode();
          }
          attempts++;
        }

        final signupRes = await http.post(
          signupUrl,
          headers: _headers,
          body: jsonEncode({
            'email': sanitizedEmail,
            'password': password,
          }),
        );

        if (signupRes.statusCode == 200 || signupRes.statusCode == 201) {
          final signupData = jsonDecode(signupRes.body);
          final userId = signupData['user']?['id'] ?? signupData['id'];
          final sessionToken = signupData['access_token'] ?? '';

          if (userId == null) {
            throw Exception('注册响应异常，未获取到用户ID');
          }

          // 4. 创建 Profile 表记录
          final profileBody = {
            'objectId': userId,
            'username': username,
            'nickname': username,
            'invite_code': inviteCode,
            'status': 'single',
            'gender': 'male',
          };

          final createProfileUrl = Uri.parse('$_baseUrl/rest/v1/Profile');
          await http.post(
            createProfileUrl,
            headers: _headers,
            body: jsonEncode(profileBody),
          );

          final Map<String, dynamic> finalUser = {
            ...profileBody,
            'sessionToken': sessionToken,
          };

          await _saveUserToLocal(finalUser);
          return finalUser;
        } else {
          final errorData = jsonDecode(signupRes.body);
          throw Exception(errorData['msg'] ?? errorData['error_description'] ?? '注册失败，请重试');
        }
      }
    } catch (e) {
      print("Supabase Auth failed. Check local cache: $e");
      final currentCached = await getCurrentUser();
      if (currentCached != null && currentCached['username'] == username) {
        return currentCached;
      }
      throw Exception('无法连接至 Supabase 服务：$e');
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
    final url = Uri.parse('$_baseUrl/rest/v1/CoupleRelation?or=(user1_id.eq.$userId,user2_id.eq.$userId)');

    try {
      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final List results = jsonDecode(response.body);
        if (results.isNotEmpty) {
          final relation = results.first;
          final box = await Hive.openBox('user');
          await box.put('couple_relation', relation);

          // 更新本地用户状态为已配对
          user['status'] = 'paired';
          user['couple_id'] = relation['couple_id'];
          user['partner_id'] = relation['user1_id'] == userId ? relation['user2_id'] : relation['user1_id'];
          await _saveUserToLocal(user);

          // 同步更新云端的 Profile 表状态
          final profileUrl = Uri.parse('$_baseUrl/rest/v1/Profile?objectId=eq.$userId');
          await http.patch(
            profileUrl,
            headers: _headers,
            body: jsonEncode({
              'status': 'paired',
              'couple_id': relation['couple_id'],
              'partner_id': user['partner_id'],
            }),
          );

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
        'user1_name': '对方',
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
      // 1. 查询持有此邀请码的另一位用户 Profile
      final profileUrl = Uri.parse('$_baseUrl/rest/v1/Profile?invite_code=eq.${Uri.encodeComponent(inviteCode)}');
      final response = await http.get(profileUrl, headers: _headers);

      if (response.statusCode != 200) {
        throw Exception('网络查询失败：${response.statusCode}');
      }

      final List results = jsonDecode(response.body);
      if (results.isEmpty) {
        throw Exception('邀请码无效，请确认对方邀请码是否正确');
      }

      final partnerUser = results.first;
      final partnerId = partnerUser['objectId'];
      final partnerNickname = partnerUser['nickname'] ?? partnerUser['username'];

      if (partnerId == currentUserId) {
        throw Exception('不能与自己配对哦！');
      }

      if (partnerUser['status'] == 'paired' || currentUser['status'] == 'paired') {
        throw Exception('您或对方已经处于配对状态了');
      }

      // 2. 创建 CoupleRelation 配对关系
      final coupleId = 'couple_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
      final relationBody = {
        'objectId': 'relation_${DateTime.now().millisecondsSinceEpoch}',
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

      final createRelationUrl = Uri.parse('$_baseUrl/rest/v1/CoupleRelation');
      final createResponse = await http.post(
        createRelationUrl,
        headers: _headers,
        body: jsonEncode(relationBody),
      );

      if (createResponse.statusCode == 201 || createResponse.statusCode == 200) {
        // 更新两人的 Profile
        final updatePartnerUrl = Uri.parse('$_baseUrl/rest/v1/Profile?objectId=eq.$partnerId');
        await http.patch(
          updatePartnerUrl,
          headers: _headers,
          body: jsonEncode({
            'status': 'paired',
            'couple_id': coupleId,
            'partner_id': currentUserId,
          }),
        );

        final updateSelfUrl = Uri.parse('$_baseUrl/rest/v1/Profile?objectId=eq.$currentUserId');
        await http.patch(
          updateSelfUrl,
          headers: _headers,
          body: jsonEncode({
            'status': 'paired',
            'couple_id': coupleId,
            'partner_id': partnerId,
          }),
        );

        // 成功配对后更新本地状态
        await checkPairStatus();
      } else {
        throw Exception('创建关系失败，服务器返回码: ${createResponse.statusCode}');
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

    // 2. 更新云端 Profile
    try {
      final url = Uri.parse('$_baseUrl/rest/v1/Profile?objectId=eq.$userId');
      await http.patch(
        url,
        headers: _headers,
        body: jsonEncode({
          'nickname': newNickname,
        }),
      );

      // 同步更新 GoTrue 基础元数据
      if (sessionToken.isNotEmpty) {
        final gotrueUrl = Uri.parse('$_baseUrl/auth/v1/user');
        await http.put(
          gotrueUrl,
          headers: _authHeaders(sessionToken),
          body: jsonEncode({
            'data': {'nickname': newNickname}
          }),
        );
      }
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
    final url = Uri.parse('$_baseUrl/rest/v1/CoupleRelation?objectId=eq.$objectId');

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
      final response = await http.patch(
        url,
        headers: _headers,
        body: jsonEncode(updateBody),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        if (currentUser != null) {
          final currentUserId = currentUser['objectId'];
          final currentGender = relation['user1_id'] == currentUserId ? user1Gender : user2Gender;
          final currentNickname = relation['user1_id'] == currentUserId ? user1Name : user2Name;
          
          currentUser['gender'] = currentGender;
          currentUser['nickname'] = currentNickname;
          await _saveUserToLocal(currentUser);

          // 更新本地用户表在云端的字段
          final profileUrl = Uri.parse('$_baseUrl/rest/v1/Profile?objectId=eq.$currentUserId');
          await http.patch(
            profileUrl,
            headers: _headers,
            body: jsonEncode({
              'gender': currentGender,
              'nickname': currentNickname,
            }),
          );
        }
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
    int currentCount = relation['heartbeat_count'] ?? 0;

    // 1. 获取最新云端计数以防止冲突覆盖
    try {
      final getUrl = Uri.parse('$_baseUrl/rest/v1/CoupleRelation?objectId=eq.$objectId&select=heartbeat_count');
      final res = await http.get(getUrl, headers: _headers);
      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        if (list.isNotEmpty) {
          currentCount = list.first['heartbeat_count'] ?? currentCount;
        }
      }
    } catch (_) {}

    final newCount = currentCount + 1;

    try {
      final patchUrl = Uri.parse('$_baseUrl/rest/v1/CoupleRelation?objectId=eq.$objectId');
      await http.patch(
        patchUrl,
        headers: _headers,
        body: jsonEncode({'heartbeat_count': newCount}),
      );
    } catch (e) {
      print("sendHeartbeat upload failed: $e");
    }

    // Local update
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
        // 删除 Profile 表中的个人公开资料
        final url = Uri.parse('$_baseUrl/rest/v1/Profile?objectId=eq.$userId');
        await http.delete(url, headers: _headers);
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

  // --- 日记同步 ---
  static Future<List<Map<String, dynamic>>> fetchDiaries() async {
    try {
      final user = await getCurrentUser();
      if (user == null || user['couple_id'] == null) return [];

      final coupleId = user['couple_id'];
      final url = Uri.parse('$_baseUrl/rest/v1/Diary?couple_id=eq.$coupleId&order=date.desc');

      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final List results = jsonDecode(response.body);
        final list = results.map((item) {
          final map = Map<String, dynamic>.from(item);
          // 处理 Supabase 中的 jsonb 数组
          if (map['tags'] is String) {
            try {
              map['tags'] = List<String>.from(jsonDecode(map['tags']));
            } catch (_) {
              map['tags'] = <String>[];
            }
          } else if (map['tags'] is List) {
            map['tags'] = List<String>.from(map['tags']);
          } else {
            map['tags'] = <String>[];
          }
          return map;
        }).toList();
        
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
      'tags': tags, // Supabase allows sending list direct to JSONB column
      'date': date,
      'image_url': imageUrl ?? '',
      'creator_id': user['objectId'],
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };

    try {
      // 查询是否存在
      final checkUrl = Uri.parse('$_baseUrl/rest/v1/Diary?objectId=eq.$finalObjectId&select=objectId');
      final checkRes = await http.get(checkUrl, headers: _headers);
      bool exists = false;
      if (checkRes.statusCode == 200) {
        final List list = jsonDecode(checkRes.body);
        exists = list.isNotEmpty;
      }

      if (exists) {
        final url = Uri.parse('$_baseUrl/rest/v1/Diary?objectId=eq.$finalObjectId');
        await http.patch(url, headers: _headers, body: jsonEncode(body));
      } else {
        final url = Uri.parse('$_baseUrl/rest/v1/Diary');
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
      final url = Uri.parse('$_baseUrl/rest/v1/Diary?objectId=eq.$objectId');
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

  // --- 心愿清单同步 ---
  static Future<List<Map<String, dynamic>>> fetchWishes() async {
    try {
      final user = await getCurrentUser();
      if (user == null || user['couple_id'] == null) return [];

      final coupleId = user['couple_id'];
      final url = Uri.parse('$_baseUrl/rest/v1/Wish?couple_id=eq.$coupleId&order=createdAt.asc');

      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final List results = jsonDecode(response.body);
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
      final url = Uri.parse('$_baseUrl/rest/v1/Wish');
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
      final url = Uri.parse('$_baseUrl/rest/v1/Wish?objectId=eq.$objectId');
      final body = {
        'completed': completed,
        'completed_at': completed ? DateTime.now().toIso8601String() : '',
        'updatedAt': DateTime.now().toIso8601String(),
      };
      await http.patch(url, headers: _headers, body: jsonEncode(body));
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
      final url = Uri.parse('$_baseUrl/rest/v1/Wish?objectId=eq.$objectId');
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

  // --- 纪念日同步 ---
  static Future<List<Map<String, dynamic>>> fetchAnniversaries() async {
    try {
      final user = await getCurrentUser();
      if (user == null || user['couple_id'] == null) return [];

      final coupleId = user['couple_id'];
      final url = Uri.parse('$_baseUrl/rest/v1/Anniversary?couple_id=eq.$coupleId&order=date.asc');

      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final List results = jsonDecode(response.body);
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
      final url = Uri.parse('$_baseUrl/rest/v1/Anniversary');
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

  // --- 生理期同步 ---
  static Future<List<String>> fetchPeriodLogs() async {
    try {
      final user = await getCurrentUser();
      if (user == null || user['couple_id'] == null) return [];

      final coupleId = user['couple_id'];
      final url = Uri.parse('$_baseUrl/rest/v1/PeriodLog?couple_id=eq.$coupleId&limit=500');

      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final List results = jsonDecode(response.body);
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
        // 检查是否存在
        final queryUrl = Uri.parse('$_baseUrl/rest/v1/PeriodLog?couple_id=eq.$coupleId&date=eq.$dateString&select=objectId');
        final checkRes = await http.get(queryUrl, headers: _headers);
        bool exists = false;
        if (checkRes.statusCode == 200) {
          final List list = jsonDecode(checkRes.body);
          exists = list.isNotEmpty;
        }

        if (!exists) {
          final url = Uri.parse('$_baseUrl/rest/v1/PeriodLog');
          await http.post(
            url,
            headers: _headers,
            body: jsonEncode({
              'objectId': 'period_${DateTime.now().millisecondsSinceEpoch}',
              'couple_id': coupleId,
              'date': dateString,
              'createdAt': DateTime.now().toIso8601String(),
              'updatedAt': DateTime.now().toIso8601String(),
            }),
          );
        }
      } else {
        // 删除记录
        final deleteUrl = Uri.parse('$_baseUrl/rest/v1/PeriodLog?couple_id=eq.$coupleId&date=eq.$dateString');
        await http.delete(deleteUrl, headers: _headers);
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

  // --- 亲密记同步 ---
  static Future<List<Map<String, dynamic>>> fetchIntimacyLogs() async {
    try {
      final user = await getCurrentUser();
      if (user == null || user['couple_id'] == null) return [];

      final coupleId = user['couple_id'];
      final url = Uri.parse('$_baseUrl/rest/v1/IntimacyLog?couple_id=eq.$coupleId&order=date.desc');

      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final List results = jsonDecode(response.body);
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
      // 检查是否存在
      final checkUrl = Uri.parse('$_baseUrl/rest/v1/IntimacyLog?objectId=eq.$finalObjectId&select=objectId');
      final checkRes = await http.get(checkUrl, headers: _headers);
      bool exists = false;
      if (checkRes.statusCode == 200) {
        final List list = jsonDecode(checkRes.body);
        exists = list.isNotEmpty;
      }

      if (exists) {
        final url = Uri.parse('$_baseUrl/rest/v1/IntimacyLog?objectId=eq.$finalObjectId');
        await http.patch(url, headers: _headers, body: jsonEncode(body));
      } else {
        final url = Uri.parse('$_baseUrl/rest/v1/IntimacyLog');
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

  // --- Helper ---
  static String _generateInviteCode() {
    final random = Random();
    return List.generate(6, (index) => random.nextInt(10)).join();
  }

  static Future<bool> _isInviteCodeUnique(String inviteCode) async {
    try {
      final url = Uri.parse('$_baseUrl/rest/v1/Profile?invite_code=eq.${Uri.encodeComponent(inviteCode)}&select=objectId');
      final res = await http.get(url, headers: _headers);
      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        return list.isEmpty;
      }
    } catch (_) {}
    return false;
  }
}
