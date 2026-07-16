import 'dart:convert';
import 'package:http/http.dart' as http;
import '../db_config_service.dart';
import '../../core/utils/sync_merge.dart';

class WebdavClient {
  static final Map<String, String> _etags = {};

  static String get webdavUrl {
    var url = DbConfigService.webdavUrl.trim();
    if (!url.endsWith('/')) {
      url += '/';
    }
    return url;
  }

  static String get username => DbConfigService.webdavUser.trim();
  static String get password => DbConfigService.webdavPassword.trim();

  static Map<String, String> get headers {
    return buildHeaders(username, password);
  }

  static Uri syncUri(String relativePath) {
    return Uri.parse(webdavUrl).resolve(relativePath);
  }

  static Map<String, String> buildHeaders(String username, String password) {
    final credentials = base64Encode(utf8.encode('$username:$password'));
    return {
      'Authorization': 'Basic $credentials',
      'Content-Type': 'application/json',
    };
  }

  static String connectionHelp(Object error, {int? statusCode}) {
    final checks = <String>[
      '无法连接坚果云 WebDAV，已自动检查：',
      if (statusCode != null) '1. 服务器返回状态码：$statusCode',
      if (statusCode == null) '1. 未收到服务器有效响应：$error',
      '2. 请确认网络可以访问 ${DbConfigService.defaultWebdavUrl}',
      '3. 请确认账号填写的是坚果云登录邮箱。',
      '4. 请确认密码是“第三方应用管理”里生成的应用授权密码，不是坚果云登录密码。',
      '5. 如果开启了代理、VPN 或公司网络限制，请切换网络后重试。',
    ];

    if (statusCode == 401 || statusCode == 403) {
      checks.add('判断：账号或应用授权密码不正确，或该账号没有 WebDAV 权限。');
    } else if (statusCode == 404) {
      checks.add('判断：WebDAV 地址不正确，请使用 ${DbConfigService.defaultWebdavUrl}。');
    } else if (statusCode != null && statusCode >= 500) {
      checks.add('判断：坚果云服务端暂时不可用，请稍后重试。');
    }

    return checks.join('\n');
  }

  static Future<void> createSyncDir() async {
    final client = http.Client();
    try {
      for (final directory in const [
        'love_app_sync/',
        'love_app_sync/images/',
      ]) {
        final req = http.Request('MKCOL', syncUri(directory))
          ..headers.addAll(headers);
        final res = await client.send(req).timeout(const Duration(seconds: 10));
        // 405 = 目录已存在，201 = 创建成功，均视为正常
        if (res.statusCode != 201 && res.statusCode != 405) {
          throw Exception(connectionHelp(
            'WebDAV sync directory creation failed',
            statusCode: res.statusCode,
          ));
        }
      }
    } catch (e) {
      if (e is Exception && e.toString().contains('无法连接坚果云 WebDAV')) {
        rethrow;
      }
      throw Exception(connectionHelp(e));
    } finally {
      client.close();
    }
  }

  static Future<bool> uploadFileWithLock(String fileName, dynamic data) async {
    try {
      final bodyStr = jsonEncode(data);
      final reqHeaders = Map<String, String>.from(headers);
      final cachedEtag = _etags[fileName];
      if (cachedEtag != null) {
        reqHeaders['If-Match'] = cachedEtag;
      }
      final res = await http
          .put(
            syncUri('love_app_sync/$fileName'),
            headers: reqHeaders,
            body: utf8.encode(bodyStr),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 412) return false; // ETag 不匹配，冲突
      if (res.statusCode < 200 || res.statusCode >= 300) {
        print("WebDAV uploadWithLock $fileName failed: HTTP ${res.statusCode}");
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

  static Future<dynamic> downloadFile(String fileName) async {
    try {
      final res = await http
          .get(syncUri('love_app_sync/$fileName'), headers: headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final etag = res.headers['etag'];
        if (etag != null) _etags[fileName] = etag;
        return jsonDecode(utf8.decode(res.bodyBytes));
      }
    } catch (e) {
      print("WebDAV download $fileName failed: $e");
    }
    return null;
  }

  static Future<bool> safeUploadWithRetry(String fileName, dynamic data) async {
    final success = await uploadFileWithLock(fileName, data);
    if (success) return true;

    // 冲突：重新下载远端数据，合并后再试一次
    final remote = await downloadFile(fileName);
    if (remote is List) {
      final localList = data is List
          ? List<Map<String, dynamic>>.from(data)
          : <Map<String, dynamic>>[];
      final remoteList = List<Map<String, dynamic>>.from(remote);
      final merged = SyncMerge.mergeRecords(localList, remoteList);
      return uploadFileWithLock(fileName, merged);
    } else if (remote is Map<String, dynamic> && data is Map<String, dynamic>) {
      final merged = <String, dynamic>{}
        ..addAll(remote)
        ..addAll(data);
      return uploadFileWithLock(fileName, merged);
    }
    return false;
  }

  static Future<String?> uploadImageBytes(String fileName, List<int> bytes) async {
    try {
      final res = await http
          .put(
            syncUri('love_app_sync/images/$fileName'),
            headers: headers,
            body: bytes,
          )
          .timeout(const Duration(seconds: 15));
      if (res.statusCode < 200 || res.statusCode >= 300) {
        return null;
      }
      return fileName;
    } catch (e) {
      print('WebDAV upload image $fileName failed: $e');
      return null;
    }
  }

  static Future<void> deleteImageFile(String fileName) async {
    try {
      await http
          .delete(syncUri('love_app_sync/images/$fileName'), headers: headers)
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      print('WebDAV delete image $fileName failed: $e');
    }
  }
}
