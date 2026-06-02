import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:flutter_land_measure/models/tile_source.dart';
import 'package:flutter_land_measure/services/tile_source_manager.dart';

/// Mapbox地图服务
class MapboxService {
  static final _instance = MapboxService._internal();

  factory MapboxService() => _instance;
  MapboxService._internal();

  // 替换为你的Mapbox Access Token
  static const String MAPBOX_ACCESS_TOKEN = 'pk.eyJ1IjoieW91cnVzZXJuYW1lIiwiYSI6ImNreTAwMDAwMDAwMDAwMmxwNHZxMzAwMDAwIn0.xxxxxxxxxxxxx';

  MapboxMap? _mapboxMap;
  TileSource? _currentTileSource;
  final TileSourceManager _tileSourceManager = TileSourceManager();

  MapboxMap? get mapboxMap => _mapboxMap;
  TileSource? get currentTileSource => _currentTileSource;

  /// 初始化Mapbox地图
  Future<void> initializeMapbox(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    
    // 加载活跃的瓦片源
    final activeSource = await _tileSourceManager.getActiveTileSource();
    if (activeSource != null) {
      await switchTileSource(activeSource);
    }
  }

  /// 切换瓦片源
  Future<void> switchTileSource(TileSource tileSource) async {
    _currentTileSource = tileSource;

    if (_mapboxMap == null) {
      throw Exception('Mapbox地图未初始化');
    }

    try {
      // 移除旧的瓦片层
      await _removeRasterLayers();

      // 添加新的瓦片源和层
      await _addRasterLayer(tileSource);

      // 保存为活跃源
      await _tileSourceManager.setActiveTileSource(tileSource.id);
    } catch (e) {
      print('切换瓦片源失败: $e');
      rethrow;
    }
  }

  /// 添加栅格瓦片层
  Future<void> _addRasterLayer(TileSource source) async {
    if (_mapboxMap == null) return;

    // 创建RasterSource
    final rasterSource = RasterSource(
      id: source.id,
      tiles: [source.urlTemplate],
      tileSize: 256,
      attribution: source.attribution,
      minzoom: source.minZoom,
      maxzoom: source.maxZoom,
    );

    // 创建RasterLayer
    final rasterLayer = RasterLayer(
      id: '${source.id}_layer',
      sourceId: source.id,
      visibility: Visibility.VISIBLE,
    );

    try {
      // 添加源和层
      await _mapboxMap!.style.addSource(rasterSource);
      await _mapboxMap!.style.addLayer(rasterLayer);
    } catch (e) {
      print('添加瓦片层失败: $e');
    }
  }

  /// 移除所有栅格层
  Future<void> _removeRasterLayers() async {
    if (_mapboxMap == null) return;

    try {
      final style = _mapboxMap!.style;
      
      // 获取所有层
      final layers = await style.getLayers();
      
      for (final layer in layers) {
        if (layer is RasterLayer) {
          await style.removeLayer(layer.id);
        }
      }

      // 获取所有源并移除RasterSource
      final sources = await style.getSources();
      for (final source in sources) {
        if (source is RasterSource) {
          try {
            await style.removeSource(source.id);
          } catch (e) {
            // 源可能被其他层引用，忽略错误
            print('移除源失败: $e');
          }
        }
      }
    } catch (e) {
      print('移除瓦片层失败: $e');
    }
  }

  /// 添加点标记
  Future<void> addPointAnnotation(
    String id,
    Point<double> geometry,
    {
    Color? color,
    String? text,
  }) async {
    if (_mapboxMap == null) return;

    try {
      final annotation = PointAnnotationOptions(
        geometry: geometry,
        textField: text,
        textColor: Colors.black,
      );

      await _mapboxMap!.annotations.createPointAnnotation(annotation);
    } catch (e) {
      print('添加点标记失败: $e');
    }
  }

  /// 添加线
  Future<void> addPolyline(
    String id,
    List<Point<double>> points,
    {
    Color color = Colors.blue,
    double width = 2.0,
  }) async {
    if (_mapboxMap == null) return;

    try {
      final lineSource = LineStringSource(
        id: id,
        lineString: LineString(coordinates: points),
      );

      final lineLayer = LineLayer(
        id: '${id}_layer',
        sourceId: id,
        linePaint: LinePaint(
          lineColor: color.value.toRadixString(16),
          lineWidth: width,
        ),
      );

      await _mapboxMap!.style.addSource(lineSource);
      await _mapboxMap!.style.addLayer(lineLayer);
    } catch (e) {
      print('添加线失败: $e');
    }
  }

  /// 添加多边形
  Future<void> addPolygon(
    String id,
    List<Point<double>> points,
    {
    Color fillColor = Colors.blue,
    Color outlineColor = Colors.darkBlue,
    double opacity = 0.15,
  }) async {
    if (_mapboxMap == null) return;

    try {
      // 闭合多边形
      final closedPoints = [...points];
      if (closedPoints.isNotEmpty && closedPoints.first != closedPoints.last) {
        closedPoints.add(closedPoints.first);
      }

      final polygonSource = PolygonSource(
        id: id,
        polygon: Polygon(
          outerRing: closedPoints,
        ),
      );

      final polygonLayer = FillLayer(
        id: '${id}_layer',
        sourceId: id,
        fillPaint: FillPaint(
          fillColor: fillColor.value.toRadixString(16),
          fillOpacity: opacity,
        ),
      );

      // 添加边框
      final outlineLayer = LineLayer(
        id: '${id}_outline_layer',
        sourceId: id,
        linePaint: LinePaint(
          lineColor: outlineColor.value.toRadixString(16),
          lineWidth: 2.0,
        ),
      );

      await _mapboxMap!.style.addSource(polygonSource);
      await _mapboxMap!.style.addLayer(polygonLayer);
      await _mapboxMap!.style.addLayer(outlineLayer);
    } catch (e) {
      print('添加多边形失败: $e');
    }
  }

  /// 清空所有绘制的元素
  Future<void> clearDrawings() async {
    if (_mapboxMap == null) return;

    try {
      final style = _mapboxMap!.style;
      final layers = await style.getLayers();

      // 移除所有非背景图层
      for (final layer in layers) {
        if (layer.id.endsWith('_layer') || layer.id.endsWith('_outline_layer')) {
          try {
            await style.removeLayer(layer.id);
          } catch (e) {
            print('移除图层失败: $e');
          }
        }
      }

      // 移除源
      final sources = await style.getSources();
      for (final source in sources) {
        if (source.id.endsWith('_outline_layer')) {
          try {
            await style.removeSource(source.id);
          } catch (e) {
            print('移除源失败: $e');
          }
        }
      }
    } catch (e) {
      print('清空绘制失败: $e');
    }
  }

  /// 移动相机到指定位置
  Future<void> animateCamera(
    Point<double> center,
    double zoom,
    double bearing = 0.0,
    double pitch = 0.0,
    Duration duration = const Duration(milliseconds: 500),
  ) async {
    if (_mapboxMap == null) return;

    try {
      final cameraOptions = CameraOptions(
        center: center,
        zoom: zoom,
        bearing: bearing,
        pitch: pitch,
      );

      await _mapboxMap!.easeTo(
        cameraOptions,
        MapAnimationOptions(
          duration: duration.inMilliseconds,
        ),
      );
    } catch (e) {
      print('移动相机失败: $e');
    }
  }

  /// 获取当前相机位置
  Future<CameraState?> getCameraState() async {
    if (_mapboxMap == null) return null;
    try {
      return await _mapboxMap!.getCameraState();
    } catch (e) {
      print('获取相机状态失败: $e');
      return null;
    }
  }
}
