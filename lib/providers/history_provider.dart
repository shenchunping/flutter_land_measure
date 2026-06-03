import 'package:flutter/material.dart';
import 'package:flutter_land_measure/models/measurement_history.dart';
import 'package:flutter_land_measure/services/measurement_database.dart';

/// 历史记录提供者
class HistoryProvider extends ChangeNotifier {
  final MeasurementDatabase _database = MeasurementDatabase();

  List<MeasurementHistory> _measurements = [];
  List<MeasurementHistory> _filteredMeasurements = [];
  MeasurementStatistics? _statistics;

  bool _isLoading = false;
  String? _error;

  // 过滤条件
  DateTime? _startDate;
  DateTime? _endDate;
  double? _minArea;
  double? _maxArea;
  String? _selectedTag;
  String? _searchQuery;

  // Getters
  List<MeasurementHistory> get measurements => _filteredMeasurements;
  bool get isLoading => _isLoading;
  String? get error => _error;
  MeasurementStatistics? get statistics => _statistics;
  int get totalCount => _measurements.length;

  /// 加载所有测量
  Future<void> loadMeasurements() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _measurements = await _database.getAllMeasurements();
      _filteredMeasurements = _measurements;
      await loadStatistics();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 加载统计信息
  Future<void> loadStatistics() async {
    try {
      _statistics = await _database.getStatistics();
      notifyListeners();
    } catch (e) {
      print('加载统计信息失败: $e');
    }
  }

  /// 按日期范围过滤
  Future<void> filterByDateRange(DateTime start, DateTime end) async {
    _isLoading = true;
    _startDate = start;
    _endDate = end;
    notifyListeners();

    try {
      _filteredMeasurements =
          await _database.getMeasurementsByDateRange(start, end);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 按面积范围过滤
  Future<void> filterByAreaRange(double min, double max) async {
    _isLoading = true;
    _minArea = min;
    _maxArea = max;
    notifyListeners();

    try {
      _filteredMeasurements =
          await _database.getMeasurementsByAreaRange(min, max);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 按标签过滤
  Future<void> filterByTag(String tag) async {
    _isLoading = true;
    _selectedTag = tag;
    notifyListeners();

    try {
      _filteredMeasurements = await _database.getMeasurementsByTag(tag);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 搜索测量
  Future<void> search(String query) async {
    if (query.isEmpty) {
      _searchQuery = null;
      _filteredMeasurements = _measurements;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _searchQuery = query;
    notifyListeners();

    try {
      _filteredMeasurements = await _database.searchMeasurements(query);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 清除所有过滤
  Future<void> clearFilters() async {
    _startDate = null;
    _endDate = null;
    _minArea = null;
    _maxArea = null;
    _selectedTag = null;
    _searchQuery = null;
    _filteredMeasurements = _measurements;
    notifyListeners();
  }

  /// 删除单条测量
  Future<void> deleteMeasurement(String id) async {
    try {
      await _database.deleteMeasurement(id);
      _measurements.removeWhere((m) => m.id == id);
      _filteredMeasurements.removeWhere((m) => m.id == id);
      await loadStatistics();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 批量删除
  Future<void> deleteMeasurements(List<String> ids) async {
    try {
      await _database.deleteMeasurements(ids);
      _measurements.removeWhere((m) => ids.contains(m.id));
      _filteredMeasurements.removeWhere((m) => ids.contains(m.id));
      await loadStatistics();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 导出测量
  Future<String> exportMeasurement(String id, ExportFormat format) async {
    try {
      return await _database.exportToFile(id, format);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// 导出多条测量
  Future<String?> exportMultipleMeasurements(
    List<String> ids,
    ExportFormat format,
  ) async {
    try {
      String content;
      switch (format) {
        case ExportFormat.kml:
          content = await _database.exportMultipleAsKml(ids);
          break;
        case ExportFormat.csv:
          content = await _database.exportMultipleAsCsv(ids);
          break;
        default:
          throw Exception('不支持的格式');
      }
      return content;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// 更新测量描述
  Future<void> updateDescription(String id, String description) async {
    try {
      await _database.updateMeasurementDescription(id, description);
      final index = _measurements.indexWhere((m) => m.id == id);
      if (index >= 0) {
        await loadMeasurements();
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 更新标签
  Future<void> updateTags(String id, List<String> tags) async {
    try {
      await _database.updateMeasurementTags(id, tags);
      final index = _measurements.indexWhere((m) => m.id == id);
      if (index >= 0) {
        await loadMeasurements();
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
