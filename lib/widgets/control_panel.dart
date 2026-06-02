import 'package:flutter/material.dart';
import 'package:flutter_land_measure/providers/measurement_provider.dart';

class ControlPanel extends StatelessWidget {
  final MeasurementProvider provider;
  final VoidCallback onStartPressed;
  final VoidCallback onStopPressed;
  final VoidCallback onPausePressed;
  final VoidCallback onResumePressed;
  final VoidCallback onCancelPressed;

  const ControlPanel({
    Key? key,
    required this.provider,
    required this.onStartPressed,
    required this.onStopPressed,
    required this.onPausePressed,
    required this.onResumePressed,
    required this.onCancelPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (provider.currentMeasurement == null) {
      // 未开始状态
      return _buildStartButton();
    } else if (provider.isTracking) {
      // 测量中状态
      return _buildMeasuringButtons();
    } else {
      // 暂停状态
      return _buildPausedButtons();
    }
  }

  Widget _buildStartButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onStartPressed,
        icon: const Icon(Icons.play_arrow),
        label: const Text('开始测量'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildMeasuringButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 暂停和停止按钮
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onPausePressed,
                icon: const Icon(Icons.pause),
                label: const Text('暂停'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onStopPressed,
                icon: const Icon(Icons.stop),
                label: const Text('完成'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // 取消按钮
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onCancelPressed,
            icon: const Icon(Icons.delete),
            label: const Text('取消测量'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // 状态提示
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade300),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on, color: Colors.green, size: 16),
              SizedBox(width: 8),
              Text(
                '测量中... 设备在移动',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPausedButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 继续和完成按钮
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onResumePressed,
                icon: const Icon(Icons.play_arrow),
                label: const Text('继续'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onStopPressed,
                icon: const Icon(Icons.check),
                label: const Text('完成'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // 取消按钮
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onCancelPressed,
            icon: const Icon(Icons.delete),
            label: const Text('取消测量'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // 状态提示
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.shade300),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.pause, color: Colors.orange, size: 16),
              SizedBox(width: 8),
              Text(
                '已暂停',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
