import 'package:flutter/material.dart';
import 'package:flutter_land_measure/models/measurement_history.dart';

class ExportDialog extends StatefulWidget {
  final Function(ExportFormat) onExport;

  const ExportDialog({Key? key, required this.onExport}) : super(key: key);

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  ExportFormat _selectedFormat = ExportFormat.kml;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('选择导出格式'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFormatOption(
            ExportFormat.kml,
            'KML格式',
            '用于Google地球\n兼容性好，支持3D可视化',
          ),
          const SizedBox(height: 8),
          _buildFormatOption(
            ExportFormat.geojson,
            'GeoJSON格式',
            '国际标准地理数据格式\n用于Web地图应用',
          ),
          const SizedBox(height: 8),
          _buildFormatOption(
            ExportFormat.csv,
            'CSV格式',
            '可以在Excel中打开\n便于数据分析和整理',
          ),
          const SizedBox(height: 8),
          _buildFormatOption(
            ExportFormat.json,
            'JSON格式',
            '完整数据备份\n包含所有测量信息',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onExport(_selectedFormat);
            Navigator.pop(context);
          },
          child: const Text('导出'),
        ),
      ],
    );
  }

  Widget _buildFormatOption(
    ExportFormat format,
    String title,
    String description,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: _selectedFormat == format ? Colors.blue : Colors.grey.shade300,
          width: _selectedFormat == format ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
        color: _selectedFormat == format
            ? Colors.blue.withOpacity(0.05)
            : Colors.transparent,
      ),
      child: RadioListTile<ExportFormat>(
        value: format,
        groupValue: _selectedFormat,
        onChanged: (value) {
          setState(() => _selectedFormat = value!);
        },
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          description,
          style: const TextStyle(fontSize: 11),
        ),
      ),
    );
  }
}
