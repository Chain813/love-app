import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../services/location_service.dart';
import '../services/leancloud_service.dart';

/// 定位状态管理
class LocationProvider extends ChangeNotifier {
  bool _permissionGranted = false;
  bool _isLoading = false;
  String? _error;

  // 自己的位置 (纬度, 经度)
  double? _myLat;
  double? _myLng;

  // 伴侣的位置
  double? _partnerLat;
  double? _partnerLng;
  String? _partnerName;
  String? _partnerLocationTime;

  // 管理员用：所有用户位置
  List<Map<String, dynamic>> _allUsersLocations = [];

  bool get permissionGranted => _permissionGranted;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double? get myLat => _myLat;
  double? get myLng => _myLng;
  double? get partnerLat => _partnerLat;
  double? get partnerLng => _partnerLng;
  String? get partnerName => _partnerName;
  String? get partnerLocationTime => _partnerLocationTime;
  List<Map<String, dynamic>> get allUsersLocations => _allUsersLocations;

  bool get hasMyLocation => _myLat != null && _myLng != null;
  bool get hasPartnerLocation => _partnerLat != null && _partnerLng != null;

  /// 请求定位权限并获取位置
  Future<bool> requestPermissionAndLocate() async {
    // Web 平台不支持原生定位权限
    if (kIsWeb) {
      _permissionGranted = true;
      _error = null;
      notifyListeners();
      return true;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final granted = await LocationService.requestPermission();
      _permissionGranted = granted;

      if (granted) {
        await _loadMyLocation();
        LocationService.startPeriodicSync();
      } else {
        _error = '定位权限被拒绝';
      }

      _isLoading = false;
      notifyListeners();
      return granted;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 检查已有权限状态
  Future<void> checkPermission() async {
    if (kIsWeb) {
      _permissionGranted = true;
      notifyListeners();
      return;
    }
    _permissionGranted = await LocationService.hasPermission();
    if (_permissionGranted) {
      await _loadMyLocation();
      LocationService.startPeriodicSync();
    }
    notifyListeners();
  }

  /// 加载自己的位置
  Future<void> _loadMyLocation() async {
    if (kIsWeb) return;
    try {
      final pos = await LocationService.getCurrentPosition();
      if (pos != null) {
        final (lat, lng) = pos;
        _myLat = lat;
        _myLng = lng;
      }
    } catch (e) {
      debugPrint('加载自己位置失败: $e');
    }
  }

  /// 加载伴侣的位置
  Future<void> loadPartnerLocation(String partnerId) async {
    try {
      final data = await LeanCloudService.fetchPartnerLocation(partnerId);
      if (data != null) {
        _partnerLat = data['latitude'] as double?;
        _partnerLng = data['longitude'] as double?;
        _partnerName = data['nickname'] as String?;
        _partnerLocationTime = data['location_updated_at'] as String?;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('加载伴侣位置失败: $e');
    }
  }

  /// 刷新双方位置
  Future<void> refreshLocations(String partnerId) async {
    _isLoading = true;
    notifyListeners();

    await Future.wait([
      _loadMyLocation(),
      loadPartnerLocation(partnerId),
      LocationService.syncLocationToCloud(),
    ]);

    _isLoading = false;
    notifyListeners();
  }

  /// 管理员：加载所有用户位置
  Future<void> loadAllUsersLocations() async {
    _isLoading = true;
    notifyListeners();

    try {
      _allUsersLocations = await LeanCloudService.fetchAllLocations();
    } catch (e) {
      _error = '加载用户位置失败: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 清除错误
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    LocationService.stopPeriodicSync();
    super.dispose();
  }
}
