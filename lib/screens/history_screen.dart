import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_land_measure/providers/history_provider.dart';
import 'package:flutter_land_measure/models/measurement_history.dart';
import 'package:flutter_land_measure/widgets/measurement_card.dart';
import 'package:flutter_land_measure/widgets/export_dialog.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showFilters = false;
  DateTime? _startDate;
  DateTime? _endDate;
  double _minArea = 0;
  double _maxArea = 100;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryProvider>().loadMeasurements();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('测量历史'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _showClearDialog,
          ),
        ],
      ),
      body: Consumer<HistoryProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              // 搜索框
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '搜索测量记录...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              provider.search('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    provider.search(value);
                    setState(() {});
                  },
                ),
              ),

              // 过滤面板
              if (_showFilters)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: _buildFilterPanel(provider),
                ),

              // 统计信息
              if (provider.statistics != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: _buildStatisticsPanel(provider.statistics!),
                ),

              // 列表
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : provider.measurements.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.inbox,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text('没有测量记录'),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: provider.measurements.length,
                            itemBuilder: (context, index) {
                              final measurement = provider.measurements[index];
                              return MeasurementCard(
                                measurement: measurement,
                                onDelete: () => _showDeleteDialog(
                                  context,
                                  provider,
                                  measurement.id,
                                ),
                                onEdit: () => _showEditDialog(
                                  context,
                                  provider,
                                  measurement,
                                ),
                                onExport: () => _showExportDialog(
                                  context,
                                  provider,
                                  measurement.id,
                                ),
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterPanel(HistoryProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 日期范围
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _startDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => _startDate = date);
                      }
                    },
                    child: Text(_startDate == null
                        ? '开始日期'
                        : _startDate.toString().split(' ')[0]),
                  ),
                ),
                const Text('~'),
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _endDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => _endDate = date);
                      }
                    },
                    child: Text(_endDate == null
                        ? '结束日期'
                        : _endDate.toString().split(' ')[0]),
                  ),
                ),
              ],
            ),
            // 面积范围
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '面积范围: ${_minArea.toStringAsFixed(1)} - ${_maxArea.toStringAsFixed(1)} 亩',
                ),
                RangeSlider(
                  min: 0,
                  max: 100,
                  start: _minArea,
                  end: _maxArea,
                  onChanged: (range) {
                    setState(() {
                      _minArea = range.start;
                      _maxArea = range.end;
                    });
                  },
                ),
              ],
            ),
            // 按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () async {
                    if (_startDate != null && _endDate != null) {
                      await provider.filterByDateRange(_startDate!, _endDate!);
                    }
                  },
                  child: const Text('按日期过滤'),
                ),
                TextButton(
                  onPressed: () async {
                    await provider.filterByAreaRange(_minArea, _maxArea);
                  },
                  child: const Text('按面积过滤'),
                ),
                TextButton(
                  onPressed: () async {
                    await provider.clearFilters();
                    setState(() {
                      _startDate = null;
                      _endDate = null;
                      _minArea = 0;
                      _maxArea = 100;
                    });
                  },
                  child: const Text('清除过滤'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsPanel(MeasurementStatistics stats) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '统计信息',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('总次数', '${stats.totalCount}次'),
                _buildStatItem('总面积', '${stats.totalAreaInMu.toStringAsFixed(1)}亩'),
                _buildStatItem('平均面积', '${stats.averageAreaInMu.toStringAsFixed(2)}亩'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('最大面积', '${stats.maxAreaInMu.toStringAsFixed(2)}亩'),
                _buildStatItem('最小面积', '${stats.minAreaInMu.toStringAsFixed(2)}亩'),
                _buildStatItem('总周长', '${stats.totalPerimeter.toStringAsFixed(0)}米'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
      ],
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    HistoryProvider provider,
    String id,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('删除后无法恢复，是否继续？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              await provider.deleteMeasurement(id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已删除')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    HistoryProvider provider,
    MeasurementHistory measurement,
  ) {
    final descController = TextEditingController(text: measurement.description);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑测量'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: '描述',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              await provider.updateDescription(measurement.id, descController.text);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已更新')),
              );
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog(
    BuildContext context,
    HistoryProvider provider,
    String id,
  ) {
    showDialog(
      context: context,
      builder: (context) => ExportDialog(
        onExport: (format) async {
          try {
            final path = await provider.exportMeasurement(id, format);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('已导出到: $path')),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('导出失败: $e')),
            );
          }
        },
      ),
    );
  }

  void _showClearDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空所有记录'),
        content: const Text('此操作无法撤销，是否继续？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              await context.read<HistoryProvider>().clearFilters();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已清空')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('清空'),
          ),
        ],
      ),
    );
  }
}
