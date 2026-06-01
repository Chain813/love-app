import 'dart:math';

/// WGS-84 ↔ GCJ-02 坐标转换工具
/// GPS 设备返回 WGS-84 坐标，高德/腾讯地图使用 GCJ-02（火星坐标）
/// 直接在高德地图上显示 WGS-84 坐标会有 100~700 米偏移
class CoordTransform {
  static const double _pi = 3.14159265358979324;
  static const double _a = 6378245.0; // 克拉索夫斯基椭球长半轴
  static const double _ee = 0.00669342162296594; // 偏心率平方

  /// 判断是否在中国境内（粗略范围）
  static bool _outOfChina(double lat, double lng) {
    return lng < 72.004 || lng > 137.8347 || lat < 0.8293 || lat > 55.8271;
  }

  static double _transformLat(double x, double y) {
    double ret = -100.0 + 2.0 * x + 3.0 * y + 0.2 * y * y +
        0.1 * x * y + 0.2 * sqrt(x.abs());
    ret += (20.0 * sin(6.0 * x * _pi) + 20.0 * sin(2.0 * x * _pi)) * 2.0 / 3.0;
    ret += (20.0 * sin(y * _pi) + 40.0 * sin(y / 3.0 * _pi)) * 2.0 / 3.0;
    ret += (160.0 * sin(y / 12.0 * _pi) + 320 * sin(y * _pi / 30.0)) * 2.0 / 3.0;
    return ret;
  }

  static double _transformLng(double x, double y) {
    double ret = 300.0 + x + 2.0 * y + 0.1 * x * x +
        0.1 * x * y + 0.1 * sqrt(x.abs());
    ret += (20.0 * sin(6.0 * x * _pi) + 20.0 * sin(2.0 * x * _pi)) * 2.0 / 3.0;
    ret += (20.0 * sin(x * _pi) + 40.0 * sin(x / 3.0 * _pi)) * 2.0 / 3.0;
    ret += (150.0 * sin(x / 12.0 * _pi) + 300.0 * sin(x / 30.0 * _pi)) * 2.0 / 3.0;
    return ret;
  }

  /// WGS-84 转 GCJ-02
  /// [wgsLat] WGS-84 纬度
  /// [wgsLng] WGS-84 经度
  /// 返回 [gcjLat, gcjLng]
  static (double, double) wgs84ToGcj02(double wgsLat, double wgsLng) {
    if (_outOfChina(wgsLat, wgsLng)) {
      return (wgsLat, wgsLng);
    }
    double dLat = _transformLat(wgsLng - 105.0, wgsLat - 35.0);
    double dLng = _transformLng(wgsLng - 105.0, wgsLat - 35.0);
    double radLat = wgsLat / 180.0 * _pi;
    double magic = sin(radLat);
    magic = 1 - _ee * magic * magic;
    double sqrtMagic = sqrt(magic);
    dLat = (dLat * 180.0) / ((_a * (1 - _ee)) / (magic * sqrtMagic) * _pi);
    dLng = (dLng * 180.0) / (_a / sqrtMagic * cos(radLat) * _pi);
    return (wgsLat + dLat, wgsLng + dLng);
  }

  /// GCJ-02 转 WGS-84（近似逆算）
  static (double, double) gcj02ToWgs84(double gcjLat, double gcjLng) {
    if (_outOfChina(gcjLat, gcjLng)) {
      return (gcjLat, gcjLng);
    }
    double dLat = _transformLat(gcjLng - 105.0, gcjLat - 35.0);
    double dLng = _transformLng(gcjLng - 105.0, gcjLat - 35.0);
    double radLat = gcjLat / 180.0 * _pi;
    double magic = sin(radLat);
    magic = 1 - _ee * magic * magic;
    double sqrtMagic = sqrt(magic);
    dLat = (dLat * 180.0) / ((_a * (1 - _ee)) / (magic * sqrtMagic) * _pi);
    dLng = (dLng * 180.0) / (_a / sqrtMagic * cos(radLat) * _pi);
    return (gcjLat - dLat, gcjLng - dLng);
  }
}
