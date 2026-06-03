import 'package:flutter_land_measure/models/track_measurement.dart';

/// 测量历史记录
class MeasurementHistory {
  final String id;
  final String name;
  final String? description;
  final DateTime createdAt;
  final DateTime? completedAt;
  final double areaInMu;
  final double areaInSquareMeters;
  final double areaInHectares;
  final double perimeter;
  final int pointsCount;
  final bool isClosed;
  final bool isSelfIntersecting;
  final double? accuracy;
  final List<String> tags;
  final String pointsJson; // 序列化的点数据

  MeasurementHistory({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
    this.completedAt,
    required this.areaInMu,
    required this.areaInSquareMeters,
    required this.areaInHectares,
    required this.perimeter,
    required this.pointsCount,
    required this.isClosed,
    required this.isSelfIntersecting,
    this.accuracy,
    this.tags = const [],
    required this.pointsJson,
  });

  /// 从TrackMeasurement创建
  factory MeasurementHistory.fromTrackMeasurement(
    TrackMeasurement measurement,
  ) {
    return MeasurementHistory(
      id: measurement.id,
      name: measurement.name ?? '未命名测量',
      description: measurement.description,
      createdAt: measurement.createdAt,
      completedAt: measurement.completedAt,
      areaInMu: measurement.areaInMu,
      areaInSquareMeters: measurement.area,
      areaInHectares: measurement.areaInHectares,
      perimeter: measurement.perimeter,
      pointsCount: measurement.points.length,
      isClosed: measurement.isClosed,
      isSelfIntersecting: measurement.isSelfIntersecting,
      pointsJson: _serializePoints(measurement.points),
    );
  }

  /// 序列化点数据
  static String _serializePoints(List<dynamic> points) {
    return jsonEncode(
      points
          .map((p) => {
            'lat': p.latitude,
            'lon': p.longitude,
            'accuracy': p.accuracy,
          })
          .toList(),
    );
  }

  /// 转换为Map（数据库存储）
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'createdAt': createdAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'areaInMu': areaInMu,
    'areaInSquareMeters': areaInSquareMeters,
    'areaInHectares': areaInHectares,
    'perimeter': perimeter,
    'pointsCount': pointsCount,
    'isClosed': isClosed ? 1 : 0,
    'isSelfIntersecting': isSelfIntersecting ? 1 : 0,
    'accuracy': accuracy,
    'tags': tags.join(','),
    'pointsJson': pointsJson,
    'createdAtTimestamp': createdAt.millisecondsSinceEpoch,
  };

  /// 从Map创建
  factory MeasurementHistory.fromMap(Map<String, dynamic> map) =>
      MeasurementHistory(
        id: map['id'] as String,
        name: map['name'] as String,
        description: map['description'] as String?,
        createdAt: DateTime.parse(map['createdAt'] as String),
        completedAt: map['completedAt'] != null
            ? DateTime.parse(map['completedAt'] as String)
            : null,
        areaInMu: (map['areaInMu'] as num).toDouble(),
        areaInSquareMeters: (map['areaInSquareMeters'] as num).toDouble(),
        areaInHectares: (map['areaInHectares'] as num).toDouble(),
        perimeter: (map['perimeter'] as num).toDouble(),
        pointsCount: map['pointsCount'] as int,
        isClosed: (map['isClosed'] as int) == 1,
        isSelfIntersecting: (map['isSelfIntersecting'] as int) == 1,
        accuracy: map['accuracy'] as double?,
        tags: (map['tags'] as String?)?.split(',') ?? [],
        pointsJson: map['pointsJson'] as String,
      );

  /// 格式化日期
  String get formattedDate =>
      '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';

  /// 格式化时间
  String get formattedTime =>
      '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';

  /// 完整时间戳
  String get formattedDateTime => '$formattedDate $formattedTime';

  @override
  String toString() => 'MeasurementHistory($name, $areaInMu亩)';
}

/// 导出格式
enum ExportFormat {
  kml('KML', 'application/vnd.google-earth.kml+xml'),
  geojson('GeoJSON', 'application/geo+json'),
  csv('CSV', 'text/csv'),
  json('JSON', 'application/json');

  final String label;
  final String mimeType;

  const ExportFormat(this.label, this.mimeType);
}

/// 测量统计信息
class MeasurementStatistics {
  final int totalCount;
  final double totalAreaInMu;
  final double averageAreaInMu;
  final double maxAreaInMu;
  final double minAreaInMu;
  final double totalPerimeter;
  final Map<String, int> monthlyCount;

  MeasurementStatistics({
    required this.totalCount,
    required this.totalAreaInMu,
    required this.averageAreaInMu,
    required this.maxAreaInMu,
    required this.minAreaInMu,
    required this.totalPerimeter,
    required this.monthlyCount,
  });
}

import 'dart:convert';
