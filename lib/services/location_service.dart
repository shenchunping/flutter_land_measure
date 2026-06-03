import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_land_measure/models/location_point.dart';
import 'package:flutter_land_measure/services/robust_location_filter.dart';

/// 位置服务 - 处理GPS定位和权限
class LocationService {
  static final LocationService _instance = LocationService._internal();

  factory LocationService() {
    return _instance;
  }

  LocationService._internal();

  final RobustLocationFilter _filter = RobustLocationFilter();
  StreamSubscription<Position>? _positionStream;
  
  final List<LocationPoint> _trackPoints = [];
  bool _isTracking = false;

  // 位置变化流
  final StreamController<LocationPoint?> _locationController =
      StreamController<LocationPoint?>.broadcast();

  Stream<LocationPoint?> get locationStream => _locationController.stream;

  bool get isTracking => _isTracking;
  List<LocationPoint> get trackPoints => List.unmodifiable(_trackPoints);

  /// 请求位置权限
  Future<bool> requestLocationPermission() async {
    final status = await Geolocator.checkPermission();
    
    if (status == LocationPermission.denied) {
      final newStatus = await Geolocator.requestPermission();
      return newStatus == LocationPermission.whileInUse ||
          newStatus == LocationPermission.always;
    }
    
    if (status == LocationPermission.deniedForever) {
      await Geolocator.openLocationSettings();
      return false;
    }
    
    return true;
  }

  /// 检查位置服务是否启用
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// 启动轨迹采集
  Future<void> startTracking({
    FilterMode mode = FilterMode.walking,
  }) async {
    if (_isTracking) return;

    // 检查权限
    final hasPermission = await requestLocationPermission();
    if (!hasPermission) {
      throw Exception('位置权限被拒绝');
    }

    // 检查位置服务
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('位置服务未启用');
    }

    _isTracking = true;
    _filter.switchMode(mode);
    _trackPoints.clear();

    // 配置位置请求
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 3, // 最小3米位移
    );

    // 监听位置更新
    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen(
      (Position position) {
        final point = LocationPoint(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
          timestamp: position.timestamp ?? DateTime.now(),
          altitude: position.altitude,
          speed: position.speed,
        );

        // 应用过滤
        final filteredLatLng = _filter.filter(point);

        if (filteredLatLng != null) {
          // 创建过滤后的点
          final filteredPoint = LocationPoint(
            latitude: filteredLatLng.latitude,
            longitude: filteredLatLng.longitude,
            accuracy: position.accuracy,
            timestamp: point.timestamp,
            altitude: position.altitude,
            speed: position.speed,
          );

          _trackPoints.add(filteredPoint);
          _locationController.add(filteredPoint);
        } else {
          // 过滤掉的点也报告，以便UI显示
          _locationController.add(null);
        }
      },
      onError: (e) {
        print('位置流错误: $e');
        _locationController.addError(e);
      },
    );
  }

  /// 停止轨迹采集
  Future<void> stopTracking() async {
    _isTracking = false;
    await _positionStream?.cancel();
    _positionStream = null;
  }

  /// 获取当前位置
  Future<LocationPoint?> getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      return LocationPoint(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        timestamp: position.timestamp ?? DateTime.now(),
        altitude: position.altitude,
        speed: position.speed,
      );
    } catch (e) {
      print('获取当前位置失败: $e');
      return null;
    }
  }

  /// 清空轨迹
  void clearTrack() {
    _trackPoints.clear();
    _filter.reset();
  }

  /// 添加手动点 (编辑使用)
  void addManualPoint(LatLng latLng) {
    final point = LocationPoint(
      latitude: latLng.latitude,
      longitude: latLng.longitude,
      accuracy: 0,
      timestamp: DateTime.now(),
    );
    _trackPoints.add(point);
    _locationController.add(point);
  }

  /// 移除指定索引的点
  void removePoint(int index) {
    if (index >= 0 && index < _trackPoints.length) {
      _trackPoints.removeAt(index);
    }
  }

  /// 移动指定索引的点
  void updatePoint(int index, LatLng newLatLng) {
    if (index >= 0 && index < _trackPoints.length) {
      final oldPoint = _trackPoints[index];
      _trackPoints[index] = LocationPoint(
        latitude: newLatLng.latitude,
        longitude: newLatLng.longitude,
        accuracy: oldPoint.accuracy,
        timestamp: oldPoint.timestamp,
        altitude: oldPoint.altitude,
        speed: oldPoint.speed,
      );
    }
  }

  /// 获取过滤统计信息
  FilterStatistics getStatistics() => _filter.statistics;

  /// 释放资源
  void dispose() {
    _positionStream?.cancel();
    _locationController.close();
  }
}
