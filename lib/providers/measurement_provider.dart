import 'package:flutter/material.dart';
import 'package:flutter_land_measure/models/location_point.dart';
import 'package:flutter_land_measure/models/track_measurement.dart';
import 'package:flutter_land_measure/services/location_service.dart';
import 'package:flutter_land_measure/services/robust_location_filter.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

/// 测量提供者 - 管理测量状态和数据
class MeasurementProvider extends ChangeNotifier {
  final LocationService _locationService = LocationService();
  
  TrackMeasurement? _currentMeasurement;
  bool _isTracking = false;
  String? _error;

  MeasurementProvider() {
    _locationService.locationStream.listen((point) {
      notifyListeners();
    });
  }

  // Getters
  TrackMeasurement? get currentMeasurement => _currentMeasurement;
  bool get isTracking => _isTracking;
  String? get error => _error;
  List<LocationPoint> get trackPoints => _locationService.trackPoints;
  
  int get pointCount => trackPoints.length;
  bool get isClosed => _currentMeasurement?.isClosed ?? false;
  double get area => _currentMeasurement?.area ?? 0;
  double get areaInMu => _currentMeasurement?.areaInMu ?? 0;
  double get areaInHectares => _currentMeasurement?.areaInHectares ?? 0;
  double get perimeter => _currentMeasurement?.perimeter ?? 0;

  /// 启动新的测量
  Future<void> startMeasurement({
    String? name,
    FilterMode mode = FilterMode.walking,
  }) async {
    try {
      _error = null;
      
      // 检查服务
      final serviceEnabled = await _locationService.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _error = '请启用位置服务';
        notifyListeners();
        return;
      }

      // 创建新的测量
      _currentMeasurement = TrackMeasurement(
        id: const Uuid().v4(),
        createdAt: DateTime.now(),
        points: [],
        name: name ?? '测量 ${DateTime.now().toString().split('.')[0]}',
      );

      // 启动位置追踪
      await _locationService.startTracking(mode: mode);
      _isTracking = true;
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isTracking = false;
      notifyListeners();
    }
  }

  /// 停止测量
  Future<void> stopMeasurement() async {
    await _locationService.stopTracking();
    _isTracking = false;

    if (_currentMeasurement != null) {
      _currentMeasurement = TrackMeasurement(
        id: _currentMeasurement!.id,
        createdAt: _currentMeasurement!.createdAt,
        completedAt: DateTime.now(),
        points: trackPoints,
        name: _currentMeasurement!.name,
        description: _currentMeasurement!.description,
      );
    }

    notifyListeners();
  }

  /// 继续测量 (暂停后继续)
  Future<void> resumeMeasurement({
    FilterMode mode = FilterMode.walking,
  }) async {
    if (_currentMeasurement == null) {
      _error = '没有暂停的测量';
      notifyListeners();
      return;
    }

    try {
      _error = null;
      await _locationService.startTracking(mode: mode);
      _isTracking = true;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 暂停测量
  Future<void> pauseMeasurement() async {
    await _locationService.stopTracking();
    _isTracking = false;
    notifyListeners();
  }

  /// 完成测量
  void completeMeasurement({String? description}) {
    if (_currentMeasurement == null) return;

    _currentMeasurement = TrackMeasurement(
      id: _currentMeasurement!.id,
      createdAt: _currentMeasurement!.createdAt,
      completedAt: DateTime.now(),
      points: trackPoints,
      name: _currentMeasurement!.name,
      description: description,
    );

    _isTracking = false;
    notifyListeners();
  }

  /// 取消测量
  void cancelMeasurement() {
    _currentMeasurement = null;
    _isTracking = false;
    _locationService.clearTrack();
    notifyListeners();
  }

  /// 添加手动点
  void addManualPoint(LatLng latLng) {
    _locationService.addManualPoint(latLng);
    notifyListeners();
  }

  /// 移除指定���
  void removePoint(int index) {
    _locationService.removePoint(index);
    notifyListeners();
  }

  /// 修改指定点
  void updatePoint(int index, LatLng newLatLng) {
    _locationService.updatePoint(index, newLatLng);
    notifyListeners();
  }

  /// 获取过滤统计信息
  FilterStatistics getFilterStatistics() => _locationService.getStatistics();

  /// 切换过滤模式
  void switchFilterMode(FilterMode mode) {
    // 注意：这只会影响后续的采样
    // 如果需要立即应用，需要重新启动追踪
    notifyListeners();
  }

  /// 获取当前位置
  Future<LatLng?> getCurrentLocation() async {
    final point = await _locationService.getCurrentLocation();
    return point?.toLatLng();
  }

  /// 获取测量中心
  LatLng? getMeasurementCenter() {
    if (trackPoints.isEmpty) return null;
    
    double avgLat = trackPoints.fold(0.0, (sum, p) => sum + p.latitude) / trackPoints.length;
    double avgLon = trackPoints.fold(0.0, (sum, p) => sum + p.longitude) / trackPoints.length;
    
    return LatLng(avgLat, avgLon);
  }

  @override
  void dispose() {
    _locationService.dispose();
    super.dispose();
  }
}
