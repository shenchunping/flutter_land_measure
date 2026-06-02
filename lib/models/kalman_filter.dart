/// 卡尔曼滤波器 - 用于平滑GPS坐标
class KalmanFilter {
  late double _x; // 状态估计
  late double _p; // 估计误差协方差
  final double q; // 过程噪声方差 (值越小越信任预测)
  final double r; // 测量噪声方差 (值越小越信任测量)

  KalmanFilter({
    required double initialValue,
    this.q = 0.0001, // 默认值适合步行场景
    this.r = 0.5,
  }) {
    _x = initialValue;
    _p = 1.0;
  }

  /// 对测量值进行卡尔曼滤波
  double filter(double measurement) {
    // 预测阶段
    _p = _p + q;

    // 更新阶段
    double k = _p / (_p + r); // 卡尔曼增益
    _x = _x + k * (measurement - _x);
    _p = (1 - k) * _p;

    return _x;
  }

  /// 重置滤波器
  void reset(double initialValue) {
    _x = initialValue;
    _p = 1.0;
  }

  /// 获取当前估计值
  double get currentValue => _x;

  /// 获取当前协方差
  double get covariance => _p;
}
