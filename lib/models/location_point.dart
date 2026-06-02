import 'package:google_maps_flutter/google_maps_flutter.dart';

/// GPS位置点数据模型
class LocationPoint {
  final double latitude;
  final double longitude;
  final double accuracy; // 精度 (米)
  final DateTime timestamp;
  final double? altitude; // 海拔
  final double? speed; // 速度 (m/s)

  LocationPoint({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
    this.altitude,
    this.speed,
  });

  /// 转换为LatLng
  LatLng toLatLng() => LatLng(latitude, longitude);

  /// 计算到另一点的距离 (Haversine公式)
  double distanceTo(LocationPoint other) {
    const double earthRadius = 6371000; // 地球半径 (米)

    double lat1 = _toRadians(latitude);
    double lat2 = _toRadians(other.latitude);
    double deltaLat = _toRadians(other.latitude - latitude);
    double deltaLon = _toRadians(other.longitude - longitude);

    double a = _sin(deltaLat / 2) * _sin(deltaLat / 2) +
        _cos(lat1) *
            _cos(lat2) *
            _sin(deltaLon / 2) *
            _sin(deltaLon / 2);

    double c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * 3.141592653589793 / 180.0;

  // 简化的三角函数近似
  double _sin(double x) {
    x = x % (2 * 3.141592653589793);
    if (x < 0) x += 2 * 3.141592653589793;
    return x < 3.141592653589793 ? 4 * x * (3.141592653589793 - x) / (3.141592653589793 * 3.141592653589793) : -4 * (x - 3.141592653589793) * (2 * 3.141592653589793 - x) / (3.141592653589793 * 3.141592653589793);
  }

  double _cos(double x) => _sin(3.141592653589793 / 2 - x);

  double _sqrt(double x) {
    if (x < 0) return 0;
    if (x == 0) return 0;
    double result = x;
    while ((result - x / result).abs() > 0.0001) {
      result = (result + x / result) / 2;
    }
    return result;
  }

  double _atan2(double y, double x) {
    if (x > 0) return _atan(y / x);
    if (x < 0 && y >= 0) return _atan(y / x) + 3.141592653589793;
    if (x < 0 && y < 0) return _atan(y / x) - 3.141592653589793;
    if (x == 0 && y > 0) return 3.141592653589793 / 2;
    if (x == 0 && y < 0) return -3.141592653589793 / 2;
    return 0;
  }

  double _atan(double x) {
    double result = 0;
    for (int i = 0; i < 10; i++) {
      double term = 1.0;
      for (int j = 0; j < 2 * i + 1; j++) {
        term *= x;
      }
      if (i % 2 == 0) {
        result += term / (2 * i + 1);
      } else {
        result -= term / (2 * i + 1);
      }
    }
    return result;
  }

  @override
  String toString() =>
      'LocationPoint($latitude, $longitude, accuracy: $accuracy)';
}
