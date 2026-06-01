import 'package:flutter/material.dart';
import '../services/leancloud_service.dart';
import '../services/wechat_service.dart';

/// 用户认证状态管理 Provider
class AuthProvider extends ChangeNotifier {
  Map<String, dynamic>? _currentUser;
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  bool get isPaired => _currentUser?['status'] == 'paired';
  String? get error => _error;
  String? get inviteCode => _currentUser?['invite_code'] as String?;
  String? get nickname => _currentUser?['nickname'] as String?;

  /// 检查登录状态并同步配对关系
  Future<void> checkLoginStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await LeanCloudService.getCurrentUser();
      if (_currentUser != null) {
        // 同步最新的配对状态
        await LeanCloudService.checkPairStatus();
        _currentUser = await LeanCloudService.getCurrentUser();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 账号密码登录/自动注册
  Future<bool> loginWithPassword(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await LeanCloudService.registerOrLogin(username, password);
      // 登录成功后紧接着校验一次配对状态
      await LeanCloudService.checkPairStatus();
      _currentUser = await LeanCloudService.getCurrentUser();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 微信登录 (保留接口，作为备用或伪装，调用上面实现)
  Future<void> loginWithWeChat() async {
    // 默认回退，此处无实际微信接口，直接在 UI 重构中替换为输入框登录。
  }

  /// 配对
  Future<bool> pairWithInviteCode(String inviteCode) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await LeanCloudService.pairWithInviteCode(inviteCode);
      await checkLoginStatus(); // 刷新用户状态
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 注销
  Future<void> deleteAccount() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await LeanCloudService.deleteAccount();
      _currentUser = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 更新昵称
  Future<bool> updateNickname(String newNickname) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await LeanCloudService.updateNickname(newNickname);
      _currentUser = await LeanCloudService.getCurrentUser();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 退出登录
  Future<void> logout() async {
    await LeanCloudService.logout();
    _currentUser = null;
    _error = null;
    notifyListeners();
  }

  /// 清除错误
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
