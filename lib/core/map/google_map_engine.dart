// ignore_for_file: deprecated_member_use
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:latlong2/latlong.dart' as geo;
import 'package:map_prototype_app/core/map/map_engine.dart';
import 'package:map_prototype_app/core/utils/goole_marker_icon_helper.dart';
import 'package:map_prototype_app/data/model/coordinate_model.dart';
import 'package:map_prototype_app/data/model/location_model.dart';
import 'package:map_prototype_app/presentation/providers/heatmap_tile_provider.dart';

class GoogleMapEngine implements MapEngine {
  _GoogleMapViewState? _state;

  @override
  Widget buildMap({
    required List<LocationModel> markers,
    required AppLatLng userLocation,
    required MapStyle style,
    required MapViewMode viewMode,
    required Function(LocationModel?) onLocationSelected,
  }) {
    return _GoogleMapView(
      key: ValueKey("$style-$viewMode"),
      markers: markers,
      userLocation: LatLng(userLocation.lat, userLocation.lng),
      style: style,
      viewMode: viewMode,
      onLocationSelected: onLocationSelected,
      onCreated: (state) => _state = state,
    );
  }

  @override
  void flyToKigali() => _state?._flyToKigali();

  @override
  void tiltCamera() => _state?._tiltCamera();

  @override
  void resetCamera() => _state?._resetCamera();

  @override
  void goToUserLocation() => _state?._goToUserLocation();
}

class _GoogleMapView extends StatefulWidget {
  final List<LocationModel> markers;
  final LatLng userLocation;
  final MapStyle style;
  final MapViewMode viewMode;
  final Function(LocationModel?) onLocationSelected;
  final Function(_GoogleMapViewState) onCreated;

  const _GoogleMapView({
    super.key,
    required this.markers,
    required this.userLocation,
    required this.style,
    required this.viewMode,
    required this.onLocationSelected,
    required this.onCreated,
  });

  @override
  State<_GoogleMapView> createState() => _GoogleMapViewState();
}

class _GoogleMapViewState extends State<_GoogleMapView> {
  final Set<Marker> _markers = {};
  final Set<Polygon> _polygons = {};
  final Set<Polyline> _polylines = {};
  Marker? _droppedPinMarker;

  GoogleMapController? _controller;

  final geo.Distance _distance = const geo.Distance();

  double _currentZoom = 13;
  double? _lastClusterZoom;
  Set<TileOverlay> _tileOverlays = {};

  @override
  void initState() {
    super.initState();
    widget.onCreated(this);

    _loadMarkers();
    _loadZones();
    _loadRoute();
  }

  // MAP STYLE

  final String _noLabelsStyle =
      '[{"featureType": "poi","stylers":[{"visibility":"off"}]},'
      '{"featureType":"transit","stylers":[{"visibility":"off"}]},'
      '{"featureType":"road","elementType":"labels","stylers":[{"visibility":"off"}]},'
      '{"featureType":"administrative","elementType":"labels","stylers":[{"visibility":"off"}]}]';

  String? _mapStyleFor(MapStyle style) =>
      style == MapStyle.streets ? _noLabelsStyle : null;

  Future<void> _loadMarkers() async {
    switch (widget.viewMode) {
      case MapViewMode.pins:
        await _loadNormalMarkers();
        break;

      case MapViewMode.clusters:
        await _loadClusterMarkers(force: true);
        break;

      case MapViewMode.heatmap:
        await _loadHeatmap(widget.markers);
        break;
    }
  }

  Future<void> _loadHeatmap(List<LocationModel> markers) async {
    final provider = AdvancedHeatmapTileProvider(
      locations: markers,
      baseKernelSize: 60,
      intensity: 1.3,
    );

    final overlay = TileOverlay(
      tileOverlayId: const TileOverlayId("heatmap_layer"),
      tileProvider: provider,
      transparency: 0.2,
      fadeIn: true,
    );

    setState(() {
      _tileOverlays = {overlay};
      _markers.clear();
    });
  }

  Future<void> _loadNormalMarkers() async {
    final Set<Marker> nextMarkers = {};

    for (final m in widget.markers) {
      final icon = await MarkerIconHelper.getIcon(m.category);

      nextMarkers.add(
        Marker(
          markerId: MarkerId(m.name),
          position: LatLng(m.position.lat, m.position.lng),
          icon: icon,
          onTap: () => widget.onLocationSelected(m),
        ),
      );
    }

    if (_droppedPinMarker != null) {
      nextMarkers.add(_droppedPinMarker!);
    }

    if (!mounted) return;
    setState(() {
      _markers
        ..clear()
        ..addAll(nextMarkers);
    });
  }

  //clustering
  double _clusterRadiusMeters(double zoom) {
    final radius = 220.0 * math.pow(2.0, 13.0 - zoom).toDouble();
    return radius.clamp(60.0, 2400.0);
  }

  List<List<LocationModel>> _createClusters(
    List<LocationModel> items,
    double zoom,
  ) {
    final radiusMeters = _clusterRadiusMeters(zoom);

    final List<List<LocationModel>> clusters = [];

    for (final item in items) {
      bool added = false;

      for (final cluster in clusters) {
        final center = cluster.first.position;

        final dist = _distance.as(
          geo.LengthUnit.Meter,
          geo.LatLng(center.lat, center.lng),
          geo.LatLng(item.position.lat, item.position.lng),
        );

        if (dist < radiusMeters) {
          cluster.add(item);
          added = true;
          break;
        }
      }

      if (!added) clusters.add([item]);
    }

    return clusters;
  }

  Future<void> _loadClusterMarkers({bool force = false}) async {
    if (!force &&
        _lastClusterZoom != null &&
        (_currentZoom - _lastClusterZoom!).abs() < 0.3) {
      return;
    }

    final Set<Marker> nextMarkers = {};
    final clusters = _createClusters(widget.markers, _currentZoom);

    for (final cluster in clusters) {
      if (cluster.length == 1) {
        final m = cluster.first;
        final icon = await MarkerIconHelper.getIcon(m.category);

        nextMarkers.add(
          Marker(
            markerId: MarkerId(m.name),
            position: LatLng(m.position.lat, m.position.lng),
            icon: icon,
            onTap: () => widget.onLocationSelected(m),
          ),
        );
      } else {
        final center = cluster.first.position;
        final count = cluster.length;

        final icon = BitmapDescriptor.fromBytes(await _buildClusterIcon(count));

        nextMarkers.add(
          Marker(
            markerId: MarkerId("cluster_${center.lat}_${center.lng}"),
            position: LatLng(center.lat, center.lng),
            icon: icon,
            onTap: () {
              _controller?.animateCamera(
                CameraUpdate.newLatLngZoom(
                  LatLng(center.lat, center.lng),
                  _currentZoom + 2,
                ),
              );
            },
          ),
        );
      }
    }

    if (_droppedPinMarker != null) {
      nextMarkers.add(_droppedPinMarker!);
    }

    if (!mounted) return;
    setState(() {
      _markers
        ..clear()
        ..addAll(nextMarkers);
      _lastClusterZoom = _currentZoom;
    });
  }

  Future<void> _refreshClustersOnIdle() async {
    if (widget.viewMode != MapViewMode.clusters) return;
    await _loadClusterMarkers();
  }

  
  // cluster icon

  Future<Uint8List> _buildClusterIcon(int count) async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);

    const size = Size(100, 100);
    const center = Offset(50, 50);

    final paint = Paint()
      ..color = count <= 3
          ? Colors.blue
          : count <= 10
          ? Colors.orange
          : Colors.red;

    final radius = count <= 3
        ? 28.0
        : count <= 10
        ? 36.0
        : 44.0;

    canvas.drawCircle(center, radius, paint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: "$count",
        style: const TextStyle(
          fontSize: 26,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );

    final img = await recorder.endRecording().toImage(
      size.width.toInt(),
      size.height.toInt(),
    );

    final data = await img.toByteData(format: ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  //zones

  Future<void> _loadZones() async {
    final jsonString = await DefaultAssetBundle.of(
      context,
    ).loadString('assets/mock/zones.geojson');

    final data = jsonDecode(jsonString);
    final List features = data['features'];

    final Set<Polygon> polygons = {};

    for (final f in features) {
      final name = f['properties']['name'];
      final coords = f['geometry']['coordinates'][0];

      final points = coords.map<LatLng>((c) => LatLng(c[1], c[0])).toList();

      polygons.add(
        Polygon(
          polygonId: PolygonId(name),
          points: points,
          strokeWidth: 0,

          fillColor: _getColor(name).withAlpha(75),
        ),
      );
    }

    setState(() {
      _polygons
        ..clear()
        ..addAll(polygons);
    });
  }

  Future<void> _loadRoute() async {
    final jsonString = await DefaultAssetBundle.of(
      context,
    ).loadString('assets/mock/routes.geojson');

    final data = jsonDecode(jsonString);
    final coords = data['features'][0]['geometry']['coordinates'];

    final points = coords.map<LatLng>((c) => LatLng(c[1], c[0])).toList();

    setState(() {
      _polylines
        ..clear()
        ..add(
          Polyline(
            polylineId: const PolylineId("route"),
            points: points,
            color: Colors.red,
            width: 2,
          ),
        );
    });
  }

  //camera controls
  void _flyToKigali() => _controller?.animateCamera(
    CameraUpdate.newCameraPosition(
      const CameraPosition(target: LatLng(-1.9441, 30.0619), zoom: 15),
    ),
  );

  void _tiltCamera() => _controller?.animateCamera(
    CameraUpdate.newCameraPosition(
      CameraPosition(
        target: widget.userLocation,
        zoom: 15,
        tilt: 60,
        bearing: 45,
      ),
    ),
  );

  void _resetCamera() => _controller?.animateCamera(
    CameraUpdate.newCameraPosition(
      CameraPosition(target: widget.userLocation, zoom: 13),
    ),
  );

  void _goToUserLocation() => _controller?.animateCamera(
    CameraUpdate.newCameraPosition(
      CameraPosition(target: widget.userLocation, zoom: 15),
    ),
  );

  Future<void> _onMapLongPress(LatLng pos) async {
    final temp = LocationModel(
      name: 'Dropped Pin',
      category: 'temporary',
      position: AppLatLng(pos.latitude, pos.longitude),
      description: 'Temporary pin dropped.',
    );

    final droppedIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(56, 56)),
      'assets/icons/user.png',
    );

    final droppedMarker = Marker(
      markerId: const MarkerId('__user_dropped_pin__'),
      position: pos,
      icon: droppedIcon,
      onTap: () => widget.onLocationSelected(temp),
    );

    if (!mounted) return;
    setState(() {
      _droppedPinMarker = droppedMarker;
      _markers.removeWhere(
        (marker) => marker.markerId.value == '__user_dropped_pin__',
      );
      _markers.add(droppedMarker);
    });

    widget.onLocationSelected(temp);
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: widget.userLocation,
        zoom: 13,
      ),
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      markers: _markers,
      polygons: _polygons,
      polylines: _polylines,
      onMapCreated: (c) => _controller = c,
      onCameraMove: (pos) => _currentZoom = pos.zoom,
      onCameraIdle: _refreshClustersOnIdle,
      onLongPress: _onMapLongPress,
      style: _mapStyleFor(widget.style),
      tileOverlays: _tileOverlays,
      mapType: widget.style == MapStyle.satellite
          ? MapType.satellite
          : widget.style == MapStyle.terrain
          ? MapType.terrain
          : MapType.normal,
    );
  }

  Color _getColor(String name) {
    if (name == "Nyamirambo") return Colors.red;
    if (name == "Kimihurura") return Colors.blue;
    if (name == "Remera") return Colors.green;
    if (name == "Kigali Downtown") return Colors.purple;
    return Colors.orange;
  }
}
