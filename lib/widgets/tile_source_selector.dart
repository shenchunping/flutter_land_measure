import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_land_measure/models/tile_source.dart';

class TileSourceSelector extends StatefulWidget {
  final List<TileSource> sources;
  final TileSource? currentSource;
  final Function(TileSource) onSourceChanged;
  final VoidCallback onAddCustom;

  const TileSourceSelector({
    Key? key,
    required this.sources,
    this.currentSource,
    required this.onSourceChanged,
    required this.onAddCustom,
  }) : super(key: key);

  @override
  State<TileSourceSelector> createState() => _TileSelectorState();
}

class _TileSelectorState extends State<TileSourceSelector> {
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
            const Text(
              '瓦片源',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            // 瓦片源列表
            ...widget.sources.map((source) => ListTile(
              title: Text(source.name),
              subtitle: Text(source.attribution),
              leading: source == widget.currentSource
                  ? const Icon(Icons.check_circle, color: Colors.blue)
                  : const Icon(Icons.circle_outlined),
              onTap: () => widget.onSourceChanged(source),
            )),
            const Divider(),
            // 添加自定义源按钮
            ListTile(
              title: const Text('添加自定义源'),
              leading: const Icon(Icons.add),
              onTap: widget.onAddCustom,
            ),
          ],
        ),
      ),
    );
  }
}

class AddCustomTileSourceDialog extends StatefulWidget {
  final Function(TileSource) onAdd;

  const AddCustomTileSourceDialog({
    Key? key,
    required this.onAdd,
  }) : super(key: key);

  @override
  State<AddCustomTileSourceDialog> createState() =>
      _AddCustomTileSourceDialogState();
}

class _AddCustomTileSourceDialogState extends State<AddCustomTileSourceDialog> {
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  final _attributionController = TextEditingController();
  final _apiKeyController = TextEditingController();
  int _minZoom = 0;
  int _maxZoom = 18;

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _attributionController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加自定义瓦片源'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 名称
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '源名称',
                hintText: '例如: 我的地图',
              ),
            ),
            const SizedBox(height: 12),

            // URL模板
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: '瓦片URL模板',
                hintText: 'https://tile.example.com/{z}/{x}/{y}.png',
                helperText: '使用 {z}, {x}, {y} 作为占位符',
              ),
              minLines: 2,
              maxLines: 3,
            ),
            const SizedBox(height: 12),

            // 属性文本
            TextField(
              controller: _attributionController,
              decoration: const InputDecoration(
                labelText: '属性文本',
                hintText: '© Map Provider',
              ),
            ),
            const SizedBox(height: 12),

            // API密钥（可选）
            TextField(
              controller: _apiKeyController,
              decoration: const InputDecoration(
                labelText: 'API密钥 (可选)',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),

            // 缩放级别范围
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: '最小缩放',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      _minZoom = int.tryParse(value) ?? 0;
                    },
                    initialValue: '$_minZoom',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: '最大缩放',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      _maxZoom = int.tryParse(value) ?? 18;
                    },
                    initialValue: '$_maxZoom',
                  ),
                ),
              ],
            ),

            // 帮助信息
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '常见的瓦片源:\n'
                  'OSM: https://tile.openstreetmap.org/{z}/{x}/{y}.png\n'
                  '高德: https://webrd0{1,2,3,4}.is.autonavi.com/appmaptile?'
                  'lang=zh_cn&size=256&scale=1&style=7&x={x}&y={y}&z={z}\n'
                  '谷歌卫星: https://mt1.google.com/vt/lyrs=s&x={x}&y={y}&z={z}',
                  style: TextStyle(fontSize: 11),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _addTileSource,
          child: const Text('添加'),
        ),
      ],
    );
  }

  void _addTileSource() {
    final name = _nameController.text.trim();
    final url = _urlController.text.trim();
    final attribution = _attributionController.text.trim();
    final apiKey = _apiKeyController.text.trim();

    if (name.isEmpty || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写必填项')),
      );
      return;
    }

    // 验证URL格式
    if (!url.contains('{z}') || !url.contains('{x}') || !url.contains('{y}')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL必须包含 {z}, {x}, {y} 占位符')),
      );
      return;
    }

    final source = TileSource(
      id: const Uuid().v4(),
      name: name,
      urlTemplate: url,
      attribution: attribution.isNotEmpty ? attribution : 'Custom',
      minZoom: _minZoom,
      maxZoom: _maxZoom,
      isCustom: true,
      apiKey: apiKey.isNotEmpty ? apiKey : null,
    );

    widget.onAdd(source);
  }
}
