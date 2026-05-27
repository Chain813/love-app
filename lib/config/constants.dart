import 'keys.dart';

/// 应用全局常量配置
class AppConstants {
  // LeanCloud / TDS 配置
  static const String leanCloudAppId = AppKeys.leanCloudAppId;
  static const String leanCloudAppKey = AppKeys.leanCloudAppKey;
  static const String leanCloudServerUrl = AppKeys.leanCloudServerUrl;

  // 微信配置（请替换为真实值）
  static const String wechatAppId = 'YOUR_WECHAT_APP_ID';
  static const String wechatUniversalLink = 'YOUR_UNIVERSAL_LINK';

  // 邀请码长度
  static const int inviteCodeLength = 6;

  // 房间码长度
  static const int roomCodeLength = 6;

  // 照片压缩质量
  static const int imageQuality = 80;
  static const int thumbnailSize = 200;
}
