import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:flutter_land_measure/providers/measurement_provider.dart';
import 'package:flutter_land_measure/services/mapbox_service.dart';
import 'package:flutter_land_measure/services/tile_source_manager.dart';
import 'package:flutter_land_measure/models/tile_source.dart';
import 'package:flutter_land_measure/widgets/measurement_info_panel.dart';
import 'package:flutter_land_measure/widgets/control_panel.dart';
import 'package:flutter_land_measure/widgets/tile_source_selector.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapboxService _mapboxService = MapboxService();
  final TileSourceManager _tileSourceManager = TileSourceManager();
  late MapboxMap _mapboxMap;
  bool _mapReady = false;
  List<TileSource> _tileSources = [];
  TileSource? _currentTileSource;

  @override
  void initState() {
    super.initState();
    _loadTileSources();
  }

  Future<void> _loadTileSources() async {
    final sources = await _tileSourceManager.getAllTileSources();
    final activeTile = await _tileSourceManager.getActiveTileSource();
    setState(() {
      _tileSources = sources;
      _currentTileSource = activeTile;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GPS测亩仪 - Mapbox'),
        elevation: 0,
        actions: [
          // 瓦片源选择按钮
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'add_custom') {
                _showAddCustomTileSourceDialog();
              } else {
                final source = _tileSources
                    .firstWhere((s) => s.id == value);
                await _switchTileSource(source);
              }
            },
            itemBuilder: (BuildContext context) => [
              for (final source in _tileSources)
                PopupMenuItem<String>(
                  value: source.id,
                  child: Row(
                    children: [
                      source == _currentTileSource
                          ? const Icon(Icons.check, color: Colors.blue)
                          : const SizedBox(width: 24),
                      const SizedBox(width: 8),
                      Text(source.name),
                    ],
                  ),
                ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'add_custom',
                child: Row(
                  children: const [
                    Icon(Icons.add, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('添加自定义源'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          // Mapbox地图
          _buildMapbox(),

          // 信息面板
          Positioned(
            top: 16,
            right: 16,
            left: 16,
            child: _buildInfoPanel(),
          ),

          // 控制面板
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: _buildControlPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildMapbox() {
    return Consumer<MeasurementProvider>(
      builder: (context, provider, _) {
        return MapboxMap(
          accessToken: MapboxService.MAPBOX_ACCESS_TOKEN,
          styleUri: MapboxStyles.MAPBOX_STREETS,
          initialCameraPosition: const CameraPosition(
            target: Point(name: '', latitude: 39.9042, longitude: 116.4074),
            zoom: 18.0,
          ),
          onMapCreated: (mapboxMap) async {
            _mapboxMap = mapboxMap;
            await _mapboxService.initializeMapbox(mapboxMap);
            setState(() => _mapReady = true);
            _updateMapDisplay(provider);
          },
          onStyleLoadedCallback: () {
            setState(() => _mapReady = true);
          },
        );
      },
    );
  }

  Future<void> _updateMapDisplay(MeasurementProvider provider) async {
    if (!_mapReady) return;

    try {
      await _mapboxService.clearDrawings();

      final trackPoints = provider.trackPoints;
      if (trackPoints.isEmpty) return;

      // 转换为Mapbox Point对象
      final points = trackPoints
          .map((p) => Point(
            name: '',
            latitude: p.latitude,
            longitude: p.longitude,
          ))
          .toList();

      // 绘制轨迹线
      if (points.length > 1) {
        await _mapboxService.addPolyline(
          'track_line',
          points,
          color: Colors.blue,
          width: 3.0,
        );
      }

      // 绘制多边形（如果闭合）
      if (provider.isClosed && points.length >= 3) {
        await _mapboxService.addPolygon(
          'track_polygon',
          points,
          fillColor: Colors.blue,
          outlineColor: Colors.darkBlue,
          opacity: 0.15,
        );
      }

      // 添加点标记
      for (int i = 0; i < points.length; i++) {
        final point = points[i];
        await _mapboxService.addPointAnnotation(
          'point_$i',
          point,
          text: '${i + 1}',
        );
      }
    } catch (e) {
      print('更新地图显示失败: $e');
    }
  }

  Future<void> _switchTileSource(TileSource source) async {
    try {
      await _mapboxService.switchTileSource(source);
      setState(() => _currentTileSource = source);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已切换到${source.name}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('切换失败: $e')),
      );
    }
  }

  void _showAddCustomTileSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AddCustomTileSourceDialog(
        onAdd: (source) async {
          try {
            // 验证瓦片源
            final isValid =
                await _tileSourceManager.validateTileSource(source);
            if (!isValid) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('瓦片源验证失败，URL可能无效')),
                );
              }
              return;
            }

            // 保存到数据库
            await _tileSourceManager.addCustomTileSource(source);

            // 刷新列表
            await _loadTileSources();

            // 切换到新源
            await _switchTileSource(source);

            if (mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('已添加${source.name}')),
              );
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('添加失败: $e')),
            );
          }
        },
      ),
    );
  }

  Widget _buildInfoPanel() {
    return Consumer<MeasurementProvider>(
      builder: (context, provider, _) {
        return MeasurementInfoPanel(
          provider: provider,
          onFilterModeChanged: (_) {},
          filterMode: null,
        );
      },
    );
  }

  Widget _buildControlPanel() {
    return Consumer<MeasurementProvider>(
      builder: (context, provider, _) {
        return ControlPanel(
          provider: provider,
          onStartPressed: () async {
            await provider.startMeasurement(
              name: '测量 ${DateTime.now().toString().split('.')[0]}',
            );
          },
          onStopPressed: () async {
            await provider.stopMeasurement();
          },
          onPausePressed: () async {
            await provider.pauseMeasurement();
          },
          onResumePressed: () async {
            await provider.resumeMeasurement();
          },
          onCancelPressed: () {
            provider.cancelMeasurement();
          },
        );
      },
    );
  }
}
