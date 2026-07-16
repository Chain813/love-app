import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../core/utils/coord_transform.dart';
import 'leancloud_service.dart';

/// 定位服务：权限管理 + 坐标获取 + 云端同步
class LocationService {
  static Timer? _periodicTimer;

  /// 请求定位权限
  /// 返回 true 表示已授权，false 表示被拒绝
  static Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// 检查是否已授权定位
  static Future<bool> hasPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// 检查定位服务是否开启
  static Future<bool> isServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// 获取当前位置（GCJ-02 坐标，可直接用于高德地图）
  /// 返回 (纬度, 经度)，如果获取失败返回 null
  static Future<(double, double)?> getCurrentPosition() async {
    try {
      final hasAccess = await hasPermission();
      if (!hasAccess) return null;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      // WGS-84 转 GCJ-02
      final (gcjLat, gcjLng) = CoordTransform.wgs84ToGcj02(
        position.latitude,
        position.longitude,
      );

      return (gcjLat, gcjLng);
    } catch (e) {
      print('获取位置失败: $e');
      return null;
    }
  }

  /// 同步当前位置到云端
  /// 返回是否成功
  static Future<bool> syncLocationToCloud() async {
    try {
      final pos = await getCurrentPosition();
      if (pos == null) return false;

      final (lat, lng) = pos;
      await LeanCloudService.updateLocation(lat, lng);
      return true;
    } catch (e) {
      print('同步位置失败: $e');
      return false;
    }
  }

  /// 启动定时同步（每 5 分钟）
  static void startPeriodicSync() {
    stopPeriodicSync();
    // 先立即同步一次
    syncLocationToCloud();
    // 然后每 5 分钟同步
    _periodicTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => syncLocationToCloud(),
    );
  }

  /// 停止定时同步
  static void stopPeriodicSync() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }

  /// 打开系统定位设置页面
  static Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }
}
