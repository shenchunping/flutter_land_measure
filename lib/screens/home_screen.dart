import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_land_measure/providers/measurement_provider.dart';
import 'package:flutter_land_measure/services/robust_location_filter.dart';
import 'package:flutter_land_measure/widgets/measurement_info_panel.dart';
import 'package:flutter_land_measure/widgets/control_panel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GoogleMapController? _mapController;
  LatLng? _currentLocation;
  FilterMode _filterMode = FilterMode.walking;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    final provider = context.read<MeasurementProvider>();
    final location = await provider.getCurrentLocation();
    if (location != null) {
      setState(() => _currentLocation = location);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GPS测亩仪'),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Google Maps
          _buildMap(),

          // 信息面板
          Positioned(
            top: 16,
            right: 16,
            left: 16,
            child: _buildInfoPanel(),
          ),

          // 控制面板
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: _buildControlPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return Consumer<MeasurementProvider>(
      builder: (context, provider, _) {
        final trackPoints = provider.trackPoints;
        final initialLocation = _currentLocation ?? const LatLng(39.9042, 116.4074);

        // 构建多边形
        final polygons = <Polygon>{};
        if (trackPoints.length >= 3) {
          polygons.add(
            Polygon(
              polygonId: const PolygonId('track'),
              points: trackPoints.map((p) => LatLng(p.latitude, p.longitude)).toList(),
              strokeColor: Colors.blue,
              strokeWidth: 2,
              fillColor: Colors.blue.withOpacity(0.15),
            ),
          );
        }

        // 构建折线
        final polylines = <Polyline>{};
        if (trackPoints.isNotEmpty) {
          polylines.add(
            Polyline(
              polylineId: const PolylineId('track'),
              points: trackPoints.map((p) => LatLng(p.latitude, p.longitude)).toList(),
              color: Colors.blue,
              width: 3,
            ),
          );
        }

        // 构建标记
        final markers = <Marker>{};
        for (int i = 0; i < trackPoints.length; i++) {
          final point = trackPoints[i];
          markers.add(
            Marker(
              markerId: MarkerId('point_$i'),
              position: LatLng(point.latitude, point.longitude),
              infoWindow: InfoWindow(title: '点 ${i + 1}'),
              icon: i == 0
                  ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
                  : i == trackPoints.length - 1
                      ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)
                      : BitmapDescriptor.defaultMarker,
            ),
          );
        }

        return GoogleMap(
          initialCameraPosition: CameraPosition(
            target: initialLocation,
            zoom: 18,
          ),
          onMapCreated: (controller) => _mapController = controller,
          markers: markers,
          polylines: polylines,
          polygons: polygons,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          compassEnabled: true,
          mapToolbarEnabled: false,
        );
      },
    );
  }

  Widget _buildInfoPanel() {
    return Consumer<MeasurementProvider>(
      builder: (context, provider, _) {
        return MeasurementInfoPanel(
          provider: provider,
          onFilterModeChanged: (mode) {
            setState(() => _filterMode = mode);
            provider.switchFilterMode(mode);
          },
          filterMode: _filterMode,
        );
      },
    );
  }

  Widget _buildControlPanel() {
    return Consumer<MeasurementProvider>(
      builder: (context, provider, _) {
        return ControlPanel(
          provider: provider,
          onStartPressed: () async {
            await provider.startMeasurement(
              name: '测量 ${DateTime.now().toString().split('.')[0]}',
              mode: _filterMode,
            );
          },
          onStopPressed: () async {
            await provider.stopMeasurement();
          },
          onPausePressed: () async {
            await provider.pauseMeasurement();
          },
          onResumePressed: () async {
            await provider.resumeMeasurement(mode: _filterMode);
          },
          onCancelPressed: () {
            provider.cancelMeasurement();
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
