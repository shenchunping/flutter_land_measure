import 'package:flutter/material.dart';
import 'package:flutter_land_measure/providers/measurement_provider.dart';
import 'package:flutter_land_measure/services/robust_location_filter.dart';

class MeasurementInfoPanel extends StatelessWidget {
  final MeasurementProvider provider;
  final Function(FilterMode) onFilterModeChanged;
  final FilterMode filterMode;

  const MeasurementInfoPanel({
    Key? key,
    required this.provider,
    required this.onFilterModeChanged,
    required this.filterMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题和过滤模式选择
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '测量信息',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildFilterModeDropdown(),
              ],
            ),
            const SizedBox(height: 12),

            // 面积信息
            _buildInfoRow('面积', _formatArea()),
            const SizedBox(height: 8),

            // 周长信息
            _buildInfoRow('周长', _formatPerimeter()),
            const SizedBox(height: 8),

            // 采样点数
            _buildInfoRow('采样点数', '${provider.pointCount}'),
            const SizedBox(height: 8),

            // 状态
            _buildInfoRow('状态', provider.isTracking ? '测量中' : '已暂停'),
            const SizedBox(height: 12),

            // 闭合状态和自交检查
      if (provider.pointCount >= 3) ...[
        Row(
          children: [
            _buildStatusBadge(
              '闭合',
              provider.isClosed,
            ),
            const SizedBox(width: 8),
            _buildStatusBadge(
              '自交',
              provider.currentMeasurement?.isSelfIntersecting ?? false,
              isError: true,
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],

            // 过滤统计信息
            _buildFilterStatistics(),

            // 错误提示
            if (provider.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          provider.error!,
                          style: const TextStyle(color: Colors.red, fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterModeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButton<FilterMode>(
        value: filterMode,
        underline: const SizedBox(),
        items: [
          DropdownMenuItem(
            value: FilterMode.walking,
            child: const Text('步行', style: TextStyle(fontSize: 12)),
          ),
          DropdownMenuItem(
            value: FilterMode.vehicular,
            child: const Text('车辆', style: TextStyle(fontSize: 12)),
          ),
          DropdownMenuItem(
            value: FilterMode.urbanCongestion,
            child: const Text('市区', style: TextStyle(fontSize: 12)),
          ),
          DropdownMenuItem(
            value: FilterMode.openArea,
            child: const Text('开阔', style: TextStyle(fontSize: 12)),
          ),
        ],
        onChanged: (mode) {
          if (mode != null) {
            onFilterModeChanged(mode);
          }
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String label, bool isPositive, {bool isError = false}) {
    final color = isError
        ? (isPositive ? Colors.red : Colors.green)
        : (isPositive ? Colors.green : Colors.orange);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label: ${isPositive ? '✓' : '✗'}',
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildFilterStatistics() {
    final stats = provider.getFilterStatistics();
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '过滤统计',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '接收: ${stats.totalReceived} | 采纳: ${stats.accepted} | 过滤: ${stats.filteredOut}',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          Text(
            '采纳率: ${(stats.acceptanceRate * 100).toStringAsFixed(1)}%',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  String _formatArea() {
    final area = provider.areaInMu;
    if (area == 0) return '- 亩';
    if (area < 1) return '${area.toStringAsFixed(2)} 亩';
    return '${area.toStringAsFixed(1)} 亩';
  }

  String _formatPerimeter() {
    final perimeter = provider.perimeter;
    if (perimeter == 0) return '- 米';
    if (perimeter < 1000) return '${perimeter.toStringAsFixed(0)} 米';
    return '${(perimeter / 1000).toStringAsFixed(2)} 公里';
  }
}
