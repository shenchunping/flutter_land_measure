import 'package:flutter/material.dart';
import 'package:flutter_land_measure/models/measurement_history.dart';

/// 测量卡片组件
class MeasurementCard extends StatelessWidget {
  final MeasurementHistory measurement;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onExport;

  const MeasurementCard({
    Key? key,
    required this.measurement,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onExport,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题和日期
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          measurement.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          measurement.formattedDateTime,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 状态指示
                  Column(
                    children: [
                      if (measurement.isClosed)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            border: Border.all(color: Colors.green),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '闭合',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (measurement.isSelfIntersecting)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            border: Border.all(color: Colors.red),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '自交',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 数据信息
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      '面积',
                      '${measurement.areaInMu.toStringAsFixed(2)}亩',
                      Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      '周长',
                      '${measurement.perimeter.toStringAsFixed(0)}米',
                      Colors.orange,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      '点数',
                      '${measurement.pointsCount}',
                      Colors.purple,
                    ),
                  ),
                ],
              ),
              // 描述
              if (measurement.description != null &&
                  measurement.description!.isNotEmpty) ...[const SizedBox(height: 12), Text(
                  measurement.description!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                )],
              // 标签
              if (measurement.tags.isNotEmpty) ...[const SizedBox(height: 12), Wrap(
                  spacing: 4,
                  children: measurement.tags.map((tag) =>
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          border: Border.all(color: Colors.blue.shade200),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.blue,
                          ),
                        ),
                      )).toList(),
                )],
              const SizedBox(height: 12),
              // 操作按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    Icons.edit,
                    '编辑',
                    Colors.blue,
                    onEdit,
                  ),
                  _buildActionButton(
                    Icons.cloud_download,
                    '导出',
                    Colors.green,
                    onExport,
                  ),
                  _buildActionButton(
                    Icons.delete,
                    '删除',
                    Colors.red,
                    onDelete,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback? onPressed,
  ) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(8),
              child: Icon(icon, color: color, size: 20),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: color,
          ),
        ),
      ],
    );
  }
}
