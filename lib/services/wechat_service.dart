import 'package:flutter/services.dart';

/// 微信服务层 - 本地 Stub 实现
///
/// 由于 fluwx 包与当前 Dart 版本不兼容，
/// 此文件提供 Stub 实现。
/// 未来接入真实微信 SDK 时，只需替换此文件的实现。
class WeChatService {
  static bool _initialized = false;

  /// 初始化（Stub）
  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
  }

  /// 模拟微信登录 - 返回模拟数据
  static Future<Map<String, String>> login() async {
    // Stub: 模拟微信登录返回数据
    return {
      'openId': 'mock_openid_${DateTime.now().millisecondsSinceEpoch}',
      'nickname': '虫米用户',
      'avatar': '',
    };
  }

  /// 分享文本到微信
  static Future<void> shareText(String text) async {
    // Stub: 复制到剪贴板代替微信分享
    await Clipboard.setData(ClipboardData(text: text));
  }

  /// 是否已安装微信
  static Future<bool> isWeChatInstalled() async {
    // Stub: 始终返回 true
    return true;
  }
}
