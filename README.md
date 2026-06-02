# Flutter GPS测亩仪

一个基于Flutter的GPS测量应用，使用**卡尔曼滤波**和多层过滤策略来消除GPS漂移，精确测量地形面积。

## 🎯 核心功能

### 📍 GPS测量
- **精准定位**：使用融合定位 + 卡尔曼滤波
- **实时显示**：地图实时显示轨迹和采样点
- **多模式支持**：步行、车辆、市区、开阔地带

### 🔍 GPS漂移处理

采用**组合过滤方案**：

```
原始GPS数据
    ↓
[第一步] 精度验证 (精度 < 20m)
    ↓
[第二步] 距离过滤 (避免重复点)
    ↓
[第三步] 卡尔曼滤波 (平滑坐标)
    ↓
[第四步] 加权平均 (基于精度的加权)
    ↓
平滑的GPS点
```

### 📊 面积计算

- **Shoelace公式**：计算多边形面积
- **支持多种单位**：平方米、亩、公顷
- **自交检测**：检查轨迹是否自相交
- **闭合判断**：自动检测路径是否闭合

### 🎮 交互功能

- **开始/暂停/继续/完成**：灵活的测量流程
- **手动编辑**：添加、删除、修改采样点
- **过滤模式切换**：实时切换过滤策略
- **统计信息**：显示采样率、过滤效果

---

## 📐 GPS漂移解决方案详解

### 卡尔曼滤波参数

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `q` | 过程噪声方差 | 0.0001 |
| `r` | 测量噪声方差 | 0.5 |
| `accuracy` | 精度阈值 | 20米 |
| `minDistance` | 最小距离 | 3米 |

### 过滤模式

#### 1. 步行模式 (Walking)
```dart
q = 0.0001  // 信任预测（速度变化慢）
r = 0.5     // 信任测量（精度稳定）
```

#### 2. 车辆模式 (Vehicular)
```dart
q = 0.001   // 信任测量（速度变化快）
r = 0.1     // 信任实测（快速响应）
```

#### 3. 市区遮挡 (Urban Congestion)
```dart
accuracy = 30m  // 放松精度要求
q = 0.00001     // 高度信任预测
r = 1.0         // 降低对测量的信任
```

#### 4. 开阔地带 (Open Area)
```dart
accuracy = 15m  // 严格精度要求
q = 0.00001     // 精确预测
r = 0.05        // 完全信任测量
```

---

## 🚀 快速开始

### 1. 环境要求

```bash
Flutter >= 3.0.0
Dart >= 3.0.0
```

### 2. 获取项目

```bash
git clone https://github.com/shenchunping/flutter_land_measure.git
cd flutter_land_measure
```

### 3. 安装依赖

```bash
flutter pub get
```

### 4. 配置Android

编辑 `android/app/build.gradle`：

```gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34
    }
}
```

编辑 `android/app/src/main/AndroidManifest.xml`：

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />

<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
```

### 5. 配置iOS

编辑 `ios/Runner/Info.plist`：

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>App需要访问您的位置信息来测量地形面积</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>App需要后台位置服务来持续测量</string>
```

### 6. 运行应用

```bash
# 调试模式
flutter run

# 发布模式
flutter run --release
```

---

## 📁 项目结构

```
lib/
├── main.dart                          # 应用入口
├── models/
│   ├── kalman_filter.dart            # 卡尔曼滤波器
│   ├── location_point.dart           # GPS点数据模型
│   └── track_measurement.dart        # 轨迹测量数据
├── services/
│   ├── location_service.dart         # 位置定位服务
│   └── robust_location_filter.dart   # 鲁棒过滤器（组合方案）
├── providers/
│   └── measurement_provider.dart     # 状态管理
├── screens/
│   └── home_screen.dart              # 主界面
└── widgets/
    ├── measurement_info_panel.dart   # 信息面板
    └── control_panel.dart            # 控制面板
```

---

## 🔬 核心算法

### Shoelace公式 (面积计算)

```
Area = |Σ(x_i * y_{i+1} - x_{i+1} * y_i)| / 2
```

### Haversine公式 (距离计算)

```
a = sin²(Δφ/2) + cos(φ1) * cos(φ2) * sin²(Δλ/2)
c = 2 * atan2(√a, √(1−a))
d = R * c
```

其中：
- φ = 纬度，λ = 经度
- R = 地球半径（6371 km）

---

## 📊 使用示例

```dart
// 1. 初始化提供者
final provider = MeasurementProvider();

// 2. 启动测量
await provider.startMeasurement(
  name: '田地1号',
  mode: FilterMode.walking,
);

// 3. 监听位置更新（自动采集）

// 4. 暂停测量
await provider.pauseMeasurement();

// 5. 继续测量
await provider.resumeMeasurement(mode: FilterMode.walking);

// 6. 完成测量
provider.completeMeasurement(
  description: '测量完成，面积：5.2亩'
);

// 7. 获取结果
final measurement = provider.currentMeasurement;
print('面积: ${measurement?.areaInMu} 亩');
print('周长: ${measurement?.perimeter} 米');
print('是否闭合: ${measurement?.isClosed}');
print('自交: ${measurement?.isSelfIntersecting}');
```

---

## 🧪 测试和调试

### 1. 查看过滤统计

```dart
final stats = provider.getFilterStatistics();
print('采样点数: ${stats.totalReceived}');
print('采纳点数: ${stats.accepted}');
print('过滤点数: ${stats.filteredOut}');
print('采纳率: ${stats.acceptanceRate * 100}%');
```

### 2. 模拟GPS数据

在测试中使用模拟器的模拟位置功能：
- Android Studio: Extended Controls → Location → 输入坐标
- Xcode: Debug → Location → Freeway Drive

### 3. 参数调优

根据实际情况调整：

```dart
final filter = RobustLocationFilter(
  accuracyThreshold: 15.0,  // 更严格的精度要求
  minDistance: 5.0,          // 更大的最小距离
  kalmanQ: 0.00001,          // 更信任预测
  kalmanR: 0.1,              // 更信任测量
);
```

---

## 🔧 常见问题

### Q1: 为什么测量结果偏差很大？

**A:** 可能原因：
1. **信号弱**：在建筑物遮挡处测量，建议在开阔地测量
2. **精度不足**：GPS精度显示 >20m，等待精度改善
3. **快速移动**：车速过快导致采样间隔不足，切换到车辆模式
4. **路径自交**：轨迹出现十字交叉，重新测量

**解决方案**：
```dart
// 1. 在开阔地带测量
// 2. 等待GPS精度稳定（显示精度值在10m以内）
// 3. 根据移动方式选择合适的过滤模式
// 4. 避免路径交叉
```

### Q2: 电池耗电很快？

**A:** GPS定位很耗电，可以：
1. 减少采样频率：`distanceFilter` 设置更大的值
2. 降低精度要求：`LocationAccuracy.best` → `LocationAccuracy.high`
3. 使用省电模式：关闭地图实时更新

### Q3: 市区精度很差？

**A:** 多路径效应严重，建议：
1. 切换到 `FilterMode.urbanCongestion`
2. 放松精度要求：`accuracyThreshold = 30`
3. 在开放的广场或公园进行测量
4. 重复测量取平均值

---

## 🎓 理论背景

### GPS误差来源

| 误差源 | 范围 | 处理方法 |
|------|------|----------|
| 多路径效应 | 5-20m | 卡尔曼滤波 |
| 电离层延迟 | 5-15m | 融合定位 |
| 对流层延迟 | 2-10m | 加权平均 |
| 接收机噪声 | 1-5m | 距离过滤 |

### 卡尔曼滤波原理

```
状态方程: x[k] = A*x[k-1] + w[k]  (w ~ N(0, Q))
观测方程: z[k] = H*x[k] + v[k]    (v ~ N(0, R))

预测:
  x̂⁻[k] = A*x̂[k-1]
  P⁻[k] = A*P[k-1]*A' + Q

更新:
  K[k] = P⁻[k]*H' / (H*P⁻[k]*H' + R)  // 卡尔曼增益
  x̂[k] = x̂⁻[k] + K[k]*(z[k] - H*x̂⁻[k])
  P[k] = (I - K[k]*H)*P⁻[k]
```

---

## 📝 许可证

MIT License

---

## 🤝 贡献

欢迎提交Issue和Pull Request！

---

## 📞 联系方式

- GitHub: [@shenchunping](https://github.com/shenchunping)
- Issues: [GitHub Issues](https://github.com/shenchunping/flutter_land_measure/issues)

---

## 🔗 相关资源

- [Flutter官方文档](https://flutter.dev/docs)
- [Google Maps Flutter](https://pub.dev/packages/google_maps_flutter)
- [Geolocator Plugin](https://pub.dev/packages/geolocator)
- [Kalman Filter Tutorial](https://en.wikipedia.org/wiki/Kalman_filter)
