import 'dart:convert';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_land_measure/models/measurement_history.dart';
import 'package:flutter_land_measure/models/track_measurement.dart';

/// 测量数据库管理
class MeasurementDatabase {
  static final _instance = MeasurementDatabase._internal();

  factory MeasurementDatabase() => _instance;
  MeasurementDatabase._internal();

  static Database? _database;
  static const String _tableName = 'measurements';

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// 初始化数据库
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'measurements.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            description TEXT,
            createdAt TEXT NOT NULL,
            completedAt TEXT,
            areaInMu REAL NOT NULL,
            areaInSquareMeters REAL NOT NULL,
            areaInHectares REAL NOT NULL,
            perimeter REAL NOT NULL,
            pointsCount INTEGER NOT NULL,
            isClosed INTEGER DEFAULT 0,
            isSelfIntersecting INTEGER DEFAULT 0,
            accuracy REAL,
            tags TEXT,
            pointsJson TEXT NOT NULL,
            createdAtTimestamp INTEGER DEFAULT 0
          )
        ''');
      },
    );
  }

  /// 保存测量
  Future<int> saveMeasurement(TrackMeasurement measurement) async {
    final db = await database;
    final history = MeasurementHistory.fromTrackMeasurement(measurement);
    return await db.insert(
      _tableName,
      history.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 保存或更新测量
  Future<void> saveOrUpdateMeasurement(TrackMeasurement measurement) async {
    final db = await database;
    final history = MeasurementHistory.fromTrackMeasurement(measurement);
    await db.insert(
      _tableName,
      history.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 获取所有测量
  Future<List<MeasurementHistory>> getAllMeasurements({
    String? sortBy = 'createdAtTimestamp',
    bool descending = true,
  }) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      orderBy: '$sortBy ${descending ? 'DESC' : 'ASC'}',
    );
    return maps.map((map) => MeasurementHistory.fromMap(map)).toList();
  }

  /// 按日期范围查询
  Future<List<MeasurementHistory>> getMeasurementsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where:
          'createdAtTimestamp >= ? AND createdAtTimestamp <= ?',
      whereArgs: [
        startDate.millisecondsSinceEpoch,
        endDate.millisecondsSinceEpoch,
      ],
      orderBy: 'createdAtTimestamp DESC',
    );
    return maps.map((map) => MeasurementHistory.fromMap(map)).toList();
  }

  /// 按面积范围查询
  Future<List<MeasurementHistory>> getMeasurementsByAreaRange(
    double minAreaInMu,
    double maxAreaInMu,
  ) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'areaInMu >= ? AND areaInMu <= ?',
      whereArgs: [minAreaInMu, maxAreaInMu],
      orderBy: 'areaInMu DESC',
    );
    return maps.map((map) => MeasurementHistory.fromMap(map)).toList();
  }

  /// 按标签查询
  Future<List<MeasurementHistory>> getMeasurementsByTag(String tag) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: "tags LIKE '%' || ? || '%'",
      whereArgs: [tag],
      orderBy: 'createdAtTimestamp DESC',
    );
    return maps.map((map) => MeasurementHistory.fromMap(map)).toList();
  }

  /// 搜索测量（按名称）
  Future<List<MeasurementHistory>> searchMeasurements(String query) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: "name LIKE '%' || ? || '%'",
      whereArgs: [query],
      orderBy: 'createdAtTimestamp DESC',
    );
    return maps.map((map) => MeasurementHistory.fromMap(map)).toList();
  }

  /// 获取单条测量
  Future<MeasurementHistory?> getMeasurementById(String id) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return MeasurementHistory.fromMap(maps.first);
  }

  /// 删除单条测量
  Future<int> deleteMeasurement(String id) async {
    final db = await database;
    return await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 批量删除
  Future<int> deleteMeasurements(List<String> ids) async {
    final db = await database;
    int deleted = 0;
    for (final id in ids) {
      deleted += await db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    return deleted;
  }

  /// 更新测量描述
  Future<int> updateMeasurementDescription(
    String id,
    String description,
  ) async {
    final db = await database;
    return await db.update(
      _tableName,
      {'description': description},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 更新标签
  Future<int> updateMeasurementTags(
    String id,
    List<String> tags,
  ) async {
    final db = await database;
    return await db.update(
      _tableName,
      {'tags': tags.join(',')},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 获取统计信息
  Future<MeasurementStatistics> getStatistics() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count, '
      'SUM(areaInMu) as totalArea, '
      'AVG(areaInMu) as avgArea, '
      'MAX(areaInMu) as maxArea, '
      'MIN(areaInMu) as minArea, '
      'SUM(perimeter) as totalPerimeter '
      'FROM $_tableName',
    );

    final row = result.first;
    final monthlyData = await db.rawQuery(
      "SELECT strftime('%Y-%m', createdAt) as month, COUNT(*) as count "
      "FROM $_tableName GROUP BY month ORDER BY month DESC",
    );

    return MeasurementStatistics(
      totalCount: (row['count'] as int?) ?? 0,
      totalAreaInMu: ((row['totalArea'] as num?) ?? 0).toDouble(),
      averageAreaInMu: ((row['avgArea'] as num?) ?? 0).toDouble(),
      maxAreaInMu: ((row['maxArea'] as num?) ?? 0).toDouble(),
      minAreaInMu: ((row['minArea'] as num?) ?? 0).toDouble(),
      totalPerimeter: ((row['totalPerimeter'] as num?) ?? 0).toDouble(),
      monthlyCount: {
        for (final m in monthlyData)
          (m['month'] as String): (m['count'] as int)
      },
    );
  }

  /// 导出为KML
  Future<String> exportAsKml(String id) async {
    final history = await getMeasurementById(id);
    if (history == null) throw Exception('测量不存在');

    final points = jsonDecode(history.pointsJson) as List;

    final coordinates = points.map((p) => '${p['lon']},${p['lat']},0').join('\n            ');

    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>${history.name}</name>
    <Placemark>
      <name>${history.name}</name>
      <description>面积: ${history.areaInMu.toStringAsFixed(2)}亩 (${history.areaInSquareMeters.toStringAsFixed(0)}m²)\n周长: ${history.perimeter.toStringAsFixed(0)}米\n${history.description ?? ''}</description>
      <Polygon>
        <outerBoundaryIs>
          <LinearRing>
            <coordinates>
              $coordinates
            </coordinates>
          </LinearRing>
        </outerBoundaryIs>
      </Polygon>
    </Placemark>
  </Document>
</kml>''';
  }

  /// 导出为GeoJSON
  Future<String> exportAsGeoJson(String id) async {
    final history = await getMeasurementById(id);
    if (history == null) throw Exception('测量不存在');

    final points = jsonDecode(history.pointsJson) as List;
    final coordinates = points.map((p) => [p['lon'], p['lat']]).toList();

    final feature = {
      'type': 'Feature',
      'properties': {
        'name': history.name,
        'description': history.description ?? '',
        'areaInMu': history.areaInMu,
        'areaInSquareMeters': history.areaInSquareMeters,
        'perimeter': history.perimeter,
        'createdAt': history.createdAt.toIso8601String(),
        'tags': history.tags,
      },
      'geometry': {
        'type': 'Polygon',
        'coordinates': [...coordinates, coordinates.first],
      },
    };

    return jsonEncode(feature);
  }

  /// 导出为CSV
  Future<String> exportAsCsv(String id) async {
    final history = await getMeasurementById(id);
    if (history == null) throw Exception('测量不存在');

    final csv =
        'ID,名称,面积(亩),面积(m²),周长(米),点数,日期,时间,闭合,自交,描述\n';
    final row =
        '${history.id},${history.name},${history.areaInMu.toStringAsFixed(2)},'
        '${history.areaInSquareMeters.toStringAsFixed(0)},${history.perimeter.toStringAsFixed(0)},'
        '${history.pointsCount},${history.formattedDate},${history.formattedTime},'
        '${history.isClosed ? '是' : '否'},${history.isSelfIntersecting ? '是' : '否'},${history.description ?? ''}\n';

    return csv + row;
  }

  /// 导出为JSON
  Future<String> exportAsJson(String id) async {
    final history = await getMeasurementById(id);
    if (history == null) throw Exception('测量不存在');

    return jsonEncode(history.toMap());
  }

  /// 导出多条为KML
  Future<String> exportMultipleAsKml(List<String> ids) async {
    final placemarks = <String>[];
    for (final id in ids) {
      final history = await getMeasurementById(id);
      if (history != null) {
        final points = jsonDecode(history.pointsJson) as List;
        final coordinates =
            points.map((p) => '${p['lon']},${p['lat']},0').join('\n            ');
        placemarks.add(
          '''    <Placemark>
      <name>${history.name}</name>
      <description>面积: ${history.areaInMu.toStringAsFixed(2)}亩 (${history.areaInSquareMeters.toStringAsFixed(0)}m²)\n周长: ${history.perimeter.toStringAsFixed(0)}米</description>
      <Polygon>
        <outerBoundaryIs>
          <LinearRing>
            <coordinates>
              $coordinates
            </coordinates>
          </LinearRing>
        </outerBoundaryIs>
      </Polygon>
    </Placemark>''',
        );
      }
    }

    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>测量数据导出</name>
${placemarks.join('\n')}
  </Document>
</kml>''';
  }

  /// 导出多条为CSV
  Future<String> exportMultipleAsCsv(List<String> ids) async {
    final csv =
        'ID,名称,面积(亩),面积(m²),周长(米),点数,日期,时间,闭合,自交\n';
    final rows = <String>[];

    for (final id in ids) {
      final history = await getMeasurementById(id);
      if (history != null) {
        rows.add(
          '${history.id},${history.name},${history.areaInMu.toStringAsFixed(2)},'
          '${history.areaInSquareMeters.toStringAsFixed(0)},${history.perimeter.toStringAsFixed(0)},'
          '${history.pointsCount},${history.formattedDate},${history.formattedTime},'
          '${history.isClosed ? '是' : '否'},${history.isSelfIntersecting ? '是' : '否'}',
        );
      }
    }

    return csv + rows.join('\n');
  }

  /// 导出为文件
  Future<String> exportToFile(
    String id,
    ExportFormat format,
  ) async {
    final dir = await getApplicationDocumentsDirectory();
    final history = await getMeasurementById(id);
    if (history == null) throw Exception('测量不存在');

    final fileName = '${history.name}_${DateTime.now().millisecondsSinceEpoch}';
    final ext = format.name;

    String content;
    switch (format) {
      case ExportFormat.kml:
        content = await exportAsKml(id);
        break;
      case ExportFormat.geojson:
        content = await exportAsGeoJson(id);
        break;
      case ExportFormat.csv:
        content = await exportAsCsv(id);
        break;
      case ExportFormat.json:
        content = await exportAsJson(id);
        break;
    }

    final file = File('${dir.path}/$fileName.$ext');
    await file.writeAsString(content);
    return file.path;
  }

  /// 清空所有数据
  Future<int> clearAll() async {
    final db = await database;
    return await db.delete(_tableName);
  }

  /// 获取数据库大小
  Future<int> getDatabaseSize() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'measurements.db');
    final file = File(path);
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }
}
