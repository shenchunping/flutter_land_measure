import 'location_point.dart';

/// 轨迹测量数据
class TrackMeasurement {
  final String id;
  final DateTime createdAt;
  final DateTime? completedAt;
  final List<LocationPoint> points;
  final String? name;
  final String? description;

  TrackMeasurement({
    required this.id,
    required this.createdAt,
    this.completedAt,
    required this.points,
    this.name,
    this.description,
  });

  /// 是否已闭合
  bool get isClosed {
    if (points.length < 3) return false;
    // 首尾距离小于10米视为闭合
    return points.first.distanceTo(points.last) < 10;
  }

  /// 轨迹周长 (米)
  double get perimeter {
    if (points.length < 2) return 0;
    double total = 0;
    for (int i = 0; i < points.length - 1; i++) {
      total += points[i].distanceTo(points[i + 1]);
    }
    // 如果闭合，加上首尾距离
    if (isClosed && points.length >= 3) {
      total += points[points.length - 1].distanceTo(points.first);
    }
    return total;
  }

  /// 面积计算 (Shoelace公式)
  double get area {
    if (points.length < 3 || !isClosed) return 0;

    // 将地理坐标转换为平面坐标 (简化版：直接使用纬度经度)
    double total = 0;
    final closedPoints = [...points, points.first]; // 闭合

    for (int i = 0; i < closedPoints.length - 1; i++) {
      final p1 = closedPoints[i];
      final p2 = closedPoints[i + 1];
      // Shoelace公式
      total += (p1.longitude * p2.latitude) - (p2.longitude * p1.latitude);
    }

    // 转换为面积 (需要结合投影)
    // 此处为近似计算，实际应使用高斯克吕格投影
    double area = (total.abs() / 2);

    // 近似转换为平方米 (在赤道附近)
    // 1度纬度约111km, 1度经度约111km*cos(latitude)
    final avgLat =
        points.fold<double>(0, (sum, p) => sum + p.latitude) / points.length;
    final latMeters = 111000; // 1度纬度约111km
    final lonMeters = 111000 * _cosApprox(avgLat);

    return area * latMeters * lonMeters;
  }

  /// 面积转换为亩 (1亩 = 666.67 m²)
  double get areaInMu => area / 666.67;

  /// 面积转换为公顷 (1公顷 = 10000 m²)
  double get areaInHectares => area / 10000;

  /// 获取轨迹的中心点
  LocationPoint? get centerPoint {
    if (points.isEmpty) return null;
    double avgLat =
        points.fold(0.0, (sum, p) => sum + p.latitude) / points.length;
    double avgLon =
        points.fold(0.0, (sum, p) => sum + p.longitude) / points.length;
    return LocationPoint(
      latitude: avgLat,
      longitude: avgLon,
      accuracy: 0,
      timestamp: DateTime.now(),
    );
  }

  /// 检查轨迹是否自相交
  bool get isSelfIntersecting {
    if (points.length < 4) return false;

    for (int i = 0; i < points.length - 2; i++) {
      for (int j = i + 2; j < points.length - 1; j++) {
        if (i == 0 && j == points.length - 2) continue; // 跳过首尾边

        if (_doSegmentsIntersect(
            points[i], points[i + 1], points[j], points[j + 1])) {
          return true;
        }
      }
    }
    return false;
  }

  /// 判断两条线段是否相交
  bool _doSegmentsIntersect(
      LocationPoint p1, LocationPoint p2, LocationPoint p3, LocationPoint p4) {
    final o1 = _orientation(p1, p2, p3);
    final o2 = _orientation(p1, p2, p4);
    final o3 = _orientation(p3, p4, p1);
    final o4 = _orientation(p3, p4, p2);

    if (o1 != o2 && o3 != o4) return true;
    return false;
  }

  /// 计算方向 (0=共线, 1=顺时针, 2=逆时针)
  int _orientation(LocationPoint p, LocationPoint q, LocationPoint r) {
    double val = (q.longitude - p.longitude) * (r.latitude - q.latitude) -
        (q.latitude - p.latitude) * (r.longitude - q.longitude);

    if (val.abs() < 1e-9) return 0;
    return val > 0 ? 1 : 2;
  }

  double _cosApprox(double degrees) {
    final radians = degrees * 3.141592653589793 / 180;
    // 简单余弦近似
    if (radians.abs() < 1.5708) {
      return 1 - radians * radians / 2;
    }
    return (1 - (radians - 1.5708) * (radians - 1.5708) / 2).abs();
  }

  @override
  String toString() => 'TrackMeasurement($id, ${points.length} points)';
}
