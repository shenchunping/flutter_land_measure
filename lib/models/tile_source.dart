/// 瓦片源配置模型
class TileSource {
  final String id;
  final String name;
  final String urlTemplate; // 例如: https://tile.openstreetmap.org/{z}/{x}/{y}.png
  final String attribution; // 属性文本
  final int minZoom;
  final int maxZoom;
  final TileSourceType type;
  final bool isCustom; // 是否为自定义源
  final String? apiKey; // 某些服务需要API密钥
  final DateTime createdAt;

  TileSource({
    required this.id,
    required this.name,
    required this.urlTemplate,
    required this.attribution,
    this.minZoom = 0,
    this.maxZoom = 18,
    this.type = TileSourceType.raster,
    this.isCustom = false,
    this.apiKey,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 获取完整的URL（处理{z},{x},{y}占位符）
  String getUrl(int z, int x, int y) {
    var url = urlTemplate
        .replaceAll('{z}', '$z')
        .replaceAll('{x}', '$x')
        .replaceAll('{y}', '$y');

    // 如果需要API密钥，添加到URL
    if (apiKey != null && apiKey!.isNotEmpty) {
      url += (url.contains('?') ? '&' : '?') + 'key=$apiKey';
    }

    return url;
  }

  /// 转换为JSON (用于数据库存储)
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'urlTemplate': urlTemplate,
    'attribution': attribution,
    'minZoom': minZoom,
    'maxZoom': maxZoom,
    'type': type.toString(),
    'isCustom': isCustom,
    'apiKey': apiKey,
    'createdAt': createdAt.toIso8601String(),
  };

  /// 从JSON创建
  factory TileSource.fromJson(Map<String, dynamic> json) => TileSource(
    id: json['id'] as String,
    name: json['name'] as String,
    urlTemplate: json['urlTemplate'] as String,
    attribution: json['attribution'] as String,
    minZoom: json['minZoom'] as int? ?? 0,
    maxZoom: json['maxZoom'] as int? ?? 18,
    type: TileSourceType.values.firstWhere(
      (e) => e.toString() == json['type'],
      orElse: () => TileSourceType.raster,
    ),
    isCustom: json['isCustom'] as bool? ?? false,
    apiKey: json['apiKey'] as String?,
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'] as String)
        : null,
  );

  @override
  String toString() => 'TileSource($name)';
}

/// 瓦片源类型
enum TileSourceType {
  raster, // 栅格瓦片
  vector, // 矢量瓦片
  elevation, // 高程数据
}

/// 预定义的瓦片源
class PredefinedTileSources {
  /// OpenStreetMap
  static TileSource get openStreetMap => TileSource(
    id: 'osm',
    name: 'OpenStreetMap',
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    attribution: '© OpenStreetMap contributors',
    minZoom: 0,
    maxZoom: 19,
    type: TileSourceType.raster,
  );

  /// 高德地图
  static TileSource amap(String apiKey) => TileSource(
    id: 'amap',
    name: '高德地图',
    urlTemplate: 'https://webrd0{1,2,3,4}.is.autonavi.com/appmaptile?'
        'lang=zh_cn&size=256&scale=1&style=7&x={x}&y={y}&z={z}',
    attribution: '© Amap',
    minZoom: 0,
    maxZoom: 18,
    type: TileSourceType.raster,
    apiKey: apiKey,
  );

  /// 腾讯地图
  static TileSource tencentMap(String apiKey) => TileSource(
    id: 'tencent',
    name: '腾讯地图',
    urlTemplate: 'https://p.map.qq.com/sateTiles/{z}/{x}/{y}.jpg',
    attribution: '© Tencent Map',
    minZoom: 0,
    maxZoom: 18,
    type: TileSourceType.raster,
    apiKey: apiKey,
  );

  /// 谷歌卫星图
  static TileSource googleSatellite => TileSource(
    id: 'google_satellite',
    name: 'Google Satellite',
    urlTemplate: 'https://mt1.google.com/vt/lyrs=s&x={x}&y={y}&z={z}',
    attribution: '© Google',
    minZoom: 0,
    maxZoom: 19,
    type: TileSourceType.raster,
  );

  /// Mapbox Satellite
  static TileSource mapboxSatellite(String accessToken) => TileSource(
    id: 'mapbox_satellite',
    name: 'Mapbox Satellite',
    urlTemplate: 'https://api.mapbox.com/styles/v1/mapbox/satellite-v9/static/'
        '{x},{y},{z}/256x256@2x?access_token={accessToken}',
    attribution: '© Mapbox',
    minZoom: 0,
    maxZoom: 22,
    type: TileSourceType.raster,
    apiKey: accessToken,
  );

  /// 获取所有预定义源
  static List<TileSource> getDefault() => [
    openStreetMap,
    googleSatellite,
  ];
}
