import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter_land_measure/models/tile_source.dart';

/// 瓦片源管理器
class TileSourceManager {
  static final _instance = TileSourceManager._internal();

  factory TileSourceManager() => _instance;
  TileSourceManager._internal();

  static Database? _database;
  static const String _tableName = 'tile_sources';

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// 初始化数据库
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'tile_sources.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // 创建表
        await db.execute('''
          CREATE TABLE $_tableName (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            urlTemplate TEXT NOT NULL,
            attribution TEXT,
            minZoom INTEGER DEFAULT 0,
            maxZoom INTEGER DEFAULT 18,
            type TEXT DEFAULT 'raster',
            isCustom INTEGER DEFAULT 0,
            apiKey TEXT,
            createdAt TEXT NOT NULL,
            isActive INTEGER DEFAULT 0
          )
        ''');

        // 插入预定义的瓦片源
        await _insertPredefinedSources(db);
      },
    );
  }

  /// 插入预定义的瓦片源
  Future<void> _insertPredefinedSources(Database db) async {
    final sources = PredefinedTileSources.getDefault();
    for (final source in sources) {
      await db.insert(_tableName, _tileSourceToMap(source, false));
    }
  }

  /// 添加自定义瓦片源
  Future<int> addCustomTileSource(TileSource source) async {
    final db = await database;
    return await db.insert(
      _tableName,
      _tileSourceToMap(source, true),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 获取所有瓦片源
  Future<List<TileSource>> getAllTileSources() async {
    final db = await database;
    final maps = await db.query(_tableName);
    return maps.map((map) => _mapToTileSource(map)).toList();
  }

  /// 获取自定义瓦片源
  Future<List<TileSource>> getCustomTileSources() async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'isCustom = ?',
      whereArgs: [1],
    );
    return maps.map((map) => _mapToTileSource(map)).toList();
  }

  /// 根据ID获取瓦片源
  Future<TileSource?> getTileSourceById(String id) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return _mapToTileSource(maps.first);
  }

  /// 更新瓦片源
  Future<int> updateTileSource(TileSource source) async {
    final db = await database;
    return await db.update(
      _tableName,
      _tileSourceToMap(source, source.isCustom),
      where: 'id = ?',
      whereArgs: [source.id],
    );
  }

  /// 删除瓦片源
  Future<int> deleteTileSource(String id) async {
    final db = await database;
    return await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 设置活跃的瓦片源
  Future<void> setActiveTileSource(String id) async {
    final db = await database;
    // 先取消所有活跃状态
    await db.update(
      _tableName,
      {'isActive': 0},
    );
    // 再设置指定的为活跃
    await db.update(
      _tableName,
      {'isActive': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 获取活跃的瓦片源
  Future<TileSource?> getActiveTileSource() async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'isActive = ?',
      whereArgs: [1],
      limit: 1,
    );
    if (maps.isEmpty) {
      // 如果没有活跃源，返回默认的OSM
      return PredefinedTileSources.openStreetMap;
    }
    return _mapToTileSource(maps.first);
  }

  /// 验证瓦片源URL
  Future<bool> validateTileSource(TileSource source) async {
    try {
      // 测试一个实际的瓦片URL
      final testUrl = source.getUrl(10, 512, 512);
      final response = await _makeRequest(testUrl);
      return response.statusCode == 200;
    } catch (e) {
      print('瓦片源验证失败: $e');
      return false;
    }
  }

  /// 发送HTTP请求
  Future<http.Response> _makeRequest(String url) async {
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'User-Agent': 'Flutter Land Measure App/1.0.0',
      },
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception('请求超时'),
    );
    return response;
  }

  /// TileSource转Map
  Map<String, dynamic> _tileSourceToMap(TileSource source, bool isCustom) => {
    'id': source.id,
    'name': source.name,
    'urlTemplate': source.urlTemplate,
    'attribution': source.attribution,
    'minZoom': source.minZoom,
    'maxZoom': source.maxZoom,
    'type': source.type.toString(),
    'isCustom': isCustom ? 1 : 0,
    'apiKey': source.apiKey,
    'createdAt': source.createdAt.toIso8601String(),
  };

  /// Map转TileSource
  TileSource _mapToTileSource(Map<String, dynamic> map) => TileSource(
    id: map['id'] as String,
    name: map['name'] as String,
    urlTemplate: map['urlTemplate'] as String,
    attribution: map['attribution'] as String? ?? '',
    minZoom: map['minZoom'] as int? ?? 0,
    maxZoom: map['maxZoom'] as int? ?? 18,
    type: TileSourceType.values.firstWhere(
      (e) => e.toString() == map['type'],
      orElse: () => TileSourceType.raster,
    ),
    isCustom: (map['isCustom'] as int? ?? 0) == 1,
    apiKey: map['apiKey'] as String?,
    createdAt: DateTime.parse(map['createdAt'] as String? ?? DateTime.now().toIso8601String()),
  );
}

// 导入http包
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
