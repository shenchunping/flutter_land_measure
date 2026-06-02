import 'package:flutter_land_measure/models/kalman_filter.dart';
import 'package:flutter_land_measure/models/location_point.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// 鲁棒的位置过滤器 - 组合方案
/// 结合了精度检查、距离过滤、卡尔曼滤波和加权平均
class RobustLocationFilter {
  late KalmanFilter _latFilter;
  late KalmanFilter _lonFilter;
  
  final List<LocationPoint> _qualityWindow = [];
  
  // 配置参数
  final double accuracyThreshold; // 精度阈值 (米)
  final double minDistance; // 最小距离 (米)
  final int windowSize; // 质量窗口大小
  
  // 统计信息
  int _totalReceived = 0;
  int _filteredOut = 0;
  int _accepted = 0;

  RobustLocationFilter({
    this.accuracyThreshold = 20.0,
    this.minDistance = 3.0,
    this.windowSize = 10,
    double kalmanQ = 0.00001,
    double kalmanR = 0.1,
  }) {
    _initializeFilters(kalmanQ, kalmanR);
  }

  void _initializeFilters(double q, double r) {
    _latFilter = KalmanFilter(initialValue: 0, q: q, r: r);
    _lonFilter = KalmanFilter(initialValue: 0, q: q, r: r);
  }

  /// 主过滤方法
  LatLng? filter(LocationPoint point) {
    _totalReceived++;

    // 第一步：精度检查
    if (!_isAccuracyValid(point)) {
      _filteredOut++;
      return null;
    }

    // 第二步：距离检查 (去重)
    if (!_isDistanceValid(point)) {
      return null;
    }

    // 第三步：卡尔曼滤波
    final filteredLat = _latFilter.filter(point.latitude);
    final filteredLon = _lonFilter.filter(point.longitude);

    // 第四步：加入质量窗口
    final filteredPoint = LocationPoint(
      latitude: filteredLat,
      longitude: filteredLon,
      accuracy: point.accuracy,
      timestamp: point.timestamp,
      altitude: point.altitude,
      speed: point.speed,
    );

    _qualityWindow.add(filteredPoint);
    if (_qualityWindow.length > windowSize) {
      _qualityWindow.removeAt(0);
    }

    _accepted++;

    // 第五步：加权平均 (可选，仅当有足够历史数据时)
    final result = _applyWeightedAverage();
    return result;
  }

  /// 精度验证
  bool _isAccuracyValid(LocationPoint point) {
    return point.accuracy <= accuracyThreshold;
  }

  /// 距离验证 (避免抖动)
  bool _isDistanceValid(LocationPoint point) {
    if (_qualityWindow.isEmpty) return true;

    final lastPoint = _qualityWindow.last;
    final distance = lastPoint.distanceTo(point);

    return distance >= minDistance;
  }

  /// 加权平均过滤 (基于精度)
  LatLng _applyWeightedAverage() {
    if (_qualityWindow.length < 3) {
      final last = _qualityWindow.last;
      return LatLng(last.latitude, last.longitude);
    }

    double totalWeight = 0;
    double weightedLat = 0;
    double weightedLon = 0;

    // 精度越好 (accuracy越小)，权重越大
    for (final point in _qualityWindow) {
      final weight = 1.0 / (point.accuracy * point.accuracy + 0.1);
      weightedLat += point.latitude * weight;
      weightedLon += point.longitude * weight;
      totalWeight += weight;
    }

    return LatLng(weightedLat / totalWeight, weightedLon / totalWeight);
  }

  /// 重置过滤器
  void reset() {
    _latFilter.reset(0);
    _lonFilter.reset(0);
    _qualityWindow.clear();
    _totalReceived = 0;
    _filteredOut = 0;
    _accepted = 0;
  }

  // 统计信息
  FilterStatistics get statistics => FilterStatistics(
    totalReceived: _totalReceived,
    filteredOut: _filteredOut,
    accepted: _accepted,
    acceptanceRate: _totalReceived > 0 ? _accepted / _totalReceived : 0,
  );

  /// 调整参数以适应不同场景
  void switchMode(FilterMode mode) {
    switch (mode) {
      case FilterMode.walking:
        // 步行模式：速度变化慢，信任预测
        _initializeFilters(0.0001, 0.5);
        break;
      case FilterMode.vehicular:
        // 车辆模式：速度变化快，信任测量
        _initializeFilters(0.001, 0.1);
        break;
      case FilterMode.urbanCongestion:
        // 市区遮挡：放松精度要求
        // (需要外部调整accuracyThreshold)
        _initializeFilters(0.00001, 1.0);
        break;
      case FilterMode.openArea:
        // 开阔地带：严格精度要求
        _initializeFilters(0.00001, 0.05);
        break;
    }
  }
}

/// 过滤统计信息
class FilterStatistics {
  final int totalReceived;
  final int filteredOut;
  final int accepted;
  final double acceptanceRate;

  FilterStatistics({
    required this.totalReceived,
    required this.filteredOut,
    required this.accepted,
    required this.acceptanceRate,
  });

  @override
  String toString() =>
      'FilterStatistics(accepted: $accepted/$totalReceived, rate: ${(acceptanceRate * 100).toStringAsFixed(1)}%)';
}

/// 过滤模式枚举
enum FilterMode {
  walking, // 步行模式
  vehicular, // 车辆模式
  urbanCongestion, // 市区遮挡
  openArea, // 开阔地带
}
