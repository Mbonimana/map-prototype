// ignore_for_file: deprecated_member_use
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as geo;
import 'package:map_prototype_app/core/map/map_engine.dart';
import 'package:map_prototype_app/core/utils/mapbox_marker_icon_helper.dart';
import 'package:map_prototype_app/data/model/coordinate_model.dart';
import 'package:map_prototype_app/data/model/location_model.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;

class MapboxMapEngine implements MapEngine {
  _MapboxViewState? _state;

  @override
  Widget buildMap({
    required List<LocationModel> markers,
    required AppLatLng userLocation,
    required MapStyle style,
    required MapViewMode viewMode,
    required Function(LocationModel?) onLocationSelected,
  }) {
    return _MapboxView(
      key: ValueKey('$style-$viewMode'),
      markers: markers,
      userLocation: userLocation,
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

class _MapboxView extends StatefulWidget {
  final List<LocationModel> markers;
  final AppLatLng userLocation;
  final MapStyle style;
  final MapViewMode viewMode;
  final Function(LocationModel?) onLocationSelected;
  final Function(_MapboxViewState) onCreated;

  const _MapboxView({
    super.key,
    required this.markers,
    required this.userLocation,
    required this.style,
    required this.viewMode,
    required this.onLocationSelected,
    required this.onCreated,
  });

  @override
  State<_MapboxView> createState() => _MapboxViewState();
}

class _MapboxViewState extends State<_MapboxView> {
  mapbox.MapboxMap? mapboxMap;
  mapbox.PointAnnotationManager? _annotationManager;
  mapbox.Cancelable? _annotationTapEvents;
  final geo.Distance _distance = const geo.Distance();

  final Map<String, LocationModel> _locationByAnnotationId = {};
  final Map<String, AppLatLng> _clusterCenterByAnnotationId = {};
  AppLatLng? _droppedPinPosition;

  double _currentZoom = 14;
  double? _lastClusterZoom;

  @override
  void initState() {
    super.initState();
    widget.onCreated(this);
  }

  void _onMapCreated(mapbox.MapboxMap map) => mapboxMap = map;

  Future<void> _onStyleLoaded(mapbox.StyleLoadedEventData eventData) async {
    await _removeAllLabels();
    await _addZones();
    await _setupAnnotations();
    await _addMarkersForViewMode(forceClusterRefresh: true);
    await _addRoute();
    await mapboxMap!.location.updateSettings(
      mapbox.LocationComponentSettings(enabled: true),
    );
  }

  Future<void> _setupAnnotations() async {
    _annotationTapEvents?.cancel();

    final manager = await mapboxMap!.annotations.createPointAnnotationManager();
    _annotationManager = manager;

    _annotationTapEvents = manager.tapEvents(onTap: _onAnnotationTap);
  }

  Future<void> _addMarkersForViewMode({
    bool forceClusterRefresh = false,
  }) async {
    switch (widget.viewMode) {
      case MapViewMode.pins:
        await _addPinMarkers();
        break;
      case MapViewMode.clusters:
        await _addClusterMarkers(force: forceClusterRefresh);
        break;
      case MapViewMode.heatmap:
        await _clearAllAnnotations();
        await _addHeatmapSource();
        await _addHeatmapLayer();
        break;
    }
  }

  Future<void> _clearAllAnnotations() async {
    final manager = _annotationManager;
    if (manager == null) return;

    await manager.deleteAll();
    _locationByAnnotationId.clear();
    _clusterCenterByAnnotationId.clear();
  }

  Future<void> _addPinMarkers() async {
    final manager = _annotationManager;
    if (manager == null) return;

    await _clearAllAnnotations();

    for (final m in widget.markers) {
      final bytes = await _loadAsset(MapboxIconHelper.getAsset(m.category));
      final ann = await manager.create(
        mapbox.PointAnnotationOptions(
          geometry: mapbox.Point(
            coordinates: mapbox.Position(m.position.lng, m.position.lat),
          ),
          image: bytes,
        ),
      );
      _locationByAnnotationId[ann.id] = m;
    }

    await _addDroppedPinMarkerIfAny(manager);
  }

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

  //heat map

  Future<void> _addHeatmapSource() async {
    final features = widget.markers.map((m) {
      final w = (m.weight ?? 0.0).clamp(0.0, 1.0);

      return {
        "type": "Feature",
        "geometry": {
          "type": "Point",
          "coordinates": [m.position.lng, m.position.lat],
        },
        "properties": {"weight": w},
      };
    }).toList();

    final geojson = {"type": "FeatureCollection", "features": features};

    await mapboxMap?.style.addSource(
      mapbox.GeoJsonSource(id: "heatmap-source", data: jsonEncode(geojson)),
    );
  }

  // heat map layer
  Future<void> _addHeatmapLayer() async {
    await mapboxMap?.style.addLayer(
      mapbox.HeatmapLayer(
        id: "heatmap-layer",
        sourceId: "heatmap-source",

        // Increase intensity as user zooms in so high-weight points stand out.
        heatmapIntensityExpression: [
          "interpolate",
          ["linear"],
          ["zoom"],
          10,
          1.0,
          14,
          2.0,
          17,
          3.0,
        ],

        // size of influence
        heatmapRadius: 30,

        //  smoothness
        heatmapOpacity: 0.9,

        // Read per-feature weight directly from GeoJSON (0..1).
        heatmapWeightExpression: [
          "coalesce",
          [
            "to-number",
            ["get", "weight"],
          ],
          0.0,
        ],

        // Explicit color ramp so stronger density appears yellow/red sooner.
        heatmapColorExpression: [
          "interpolate",
          ["linear"],
          ["heatmap-density"],
          0.00,
          "rgba(0, 0, 0, 0)",
          0.20,
          "rgba(0, 176, 255, 0.7)",
          0.40,
          "rgba(0, 255, 128, 0.8)",
          0.60,
          "rgba(255, 214, 0, 0.9)",
          0.80,
          "rgba(255, 140, 0, 0.95)",
          1.00,
          "rgba(255, 0, 0, 1.0)",
        ],
      ),
    );
  }

  Future<void> _addClusterMarkers({bool force = false}) async {
    final manager = _annotationManager;
    if (manager == null) return;

    if (!force &&
        _lastClusterZoom != null &&
        (_currentZoom - _lastClusterZoom!).abs() < 0.3) {
      return;
    }

    await _clearAllAnnotations();

    final clusters = _createClusters(widget.markers, _currentZoom);

    for (final cluster in clusters) {
      if (cluster.length == 1) {
        final m = cluster.first;
        final bytes = await _loadAsset(MapboxIconHelper.getAsset(m.category));
        final ann = await manager.create(
          mapbox.PointAnnotationOptions(
            geometry: mapbox.Point(
              coordinates: mapbox.Position(m.position.lng, m.position.lat),
            ),
            image: bytes,
          ),
        );
        _locationByAnnotationId[ann.id] = m;
      } else {
        final center = cluster.first.position;
        final iconBytes = await _buildClusterIcon(cluster.length);
        final ann = await manager.create(
          mapbox.PointAnnotationOptions(
            geometry: mapbox.Point(
              coordinates: mapbox.Position(center.lng, center.lat),
            ),
            image: iconBytes,
          ),
        );
        _clusterCenterByAnnotationId[ann.id] = center;
      }
    }

    await _addDroppedPinMarkerIfAny(manager);

    _lastClusterZoom = _currentZoom;
  }

  Future<void> _addDroppedPinMarkerIfAny(
    mapbox.PointAnnotationManager manager,
  ) async {
    final droppedPos = _droppedPinPosition;
    if (droppedPos == null) return;

    final droppedLocation = LocationModel(
      name: 'Dropped Pin',
      category: 'temporary',
      position: droppedPos,
      description: 'Dropped pin',
    );

    final bytes = await _loadAsset('assets/icon/user.png');
    final ann = await manager.create(
      mapbox.PointAnnotationOptions(
        geometry: mapbox.Point(
          coordinates: mapbox.Position(droppedPos.lng, droppedPos.lat),
        ),
        image: bytes,
      ),
    );

    _locationByAnnotationId[ann.id] = droppedLocation;
  }

  Future<void> _refreshClustersOnIdle() async {
    if (widget.viewMode != MapViewMode.clusters) return;
    await _addClusterMarkers();
  }

  void _onCameraChanged(mapbox.CameraChangedEventData eventData) {
    _currentZoom = eventData.cameraState.zoom;
  }

  void _onAnnotationTap(mapbox.PointAnnotation annotation) {
    final clusterCenter = _clusterCenterByAnnotationId[annotation.id];
    if (clusterCenter != null) {
      mapboxMap?.flyTo(
        mapbox.CameraOptions(
          center: mapbox.Point(
            coordinates: mapbox.Position(clusterCenter.lng, clusterCenter.lat),
          ),
          zoom: _currentZoom + 2,
        ),
        mapbox.MapAnimationOptions(duration: 600),
      );
      return;
    }

    widget.onLocationSelected(_locationByAnnotationId[annotation.id]);
  }

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
        text: '$count',
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

  Future<void> _addZones() async {
    final geojson = await DefaultAssetBundle.of(
      context,
    ).loadString('assets/mock/zones.geojson');
    final decoded = jsonDecode(geojson);
    for (var feature in decoded['features']) {
      final name = feature['properties']['name'];
      final id = name.toString().toLowerCase().replaceAll(' ', '-');
      try {
        await mapboxMap?.style.addSource(
          mapbox.GeoJsonSource(id: 'src-$id', data: jsonEncode(feature)),
        );
        await mapboxMap?.style.addLayer(
          mapbox.FillLayer(
            id: 'fill-$id',
            sourceId: 'src-$id',
            fillColor: _zoneColor(name).value,
            fillOpacity: 0.3,
          ),
        );
      } catch (_) {}
    }
  }

  Future<void> _addRoute() async {
    final geojson = await DefaultAssetBundle.of(
      context,
    ).loadString('assets/mock/routes.geojson');
    try {
      await mapboxMap?.style.addSource(
        mapbox.GeoJsonSource(id: "route-src", data: geojson),
      );
      await mapboxMap?.style.addLayer(
        mapbox.LineLayer(
          id: "route-layer",
          sourceId: "route-src",
          lineColor: Colors.blue.value,
          lineWidth: 3.0,
        ),
      );
    } catch (_) {}
  }

  Future<void> _removeAllLabels() async {
    final layers = await mapboxMap?.style.getStyleLayers() ?? [];
    for (var l in layers) {
      if (l?.type == 'symbol') {
        await mapboxMap?.style.setStyleLayerProperty(
          l!.id,
          'visibility',
          'none',
        );
      }
    }
  }

  Future<void> _onMapLongTap(mapbox.MapContentGestureContext context) async {
    final pos = AppLatLng(
      context.point.coordinates.lat.toDouble(),
      context.point.coordinates.lng.toDouble(),
    );

    _droppedPinPosition = pos;

    await _addMarkersForViewMode(forceClusterRefresh: true);

    final loc = LocationModel(
      name: 'Dropped Pin',
      category: 'temporary',
      position: pos,
      description: 'Dropped pin',
    );

    widget.onLocationSelected(loc);
  }

  // Camera Logic
  void _flyToKigali() => mapboxMap?.flyTo(
    mapbox.CameraOptions(
      center: mapbox.Point(coordinates: mapbox.Position(30.0619, -1.9441)),
      zoom: 15,
    ),
    mapbox.MapAnimationOptions(duration: 2000),
  );
  void _tiltCamera() => mapboxMap?.flyTo(
    mapbox.CameraOptions(
      center: mapbox.Point(
        coordinates: mapbox.Position(
          widget.userLocation.lng,
          widget.userLocation.lat,
        ),
      ),
      zoom: 15,
      pitch: 60,
      bearing: 45,
    ),
    mapbox.MapAnimationOptions(duration: 2000),
  );
  void _resetCamera() => mapboxMap?.flyTo(
    mapbox.CameraOptions(
      center: mapbox.Point(
        coordinates: mapbox.Position(
          widget.userLocation.lng,
          widget.userLocation.lat,
        ),
      ),
      zoom: 13,
      pitch: 0,
      bearing: 0,
    ),
    mapbox.MapAnimationOptions(duration: 1500),
  );
  void _goToUserLocation() => mapboxMap?.flyTo(
    mapbox.CameraOptions(
      center: mapbox.Point(
        coordinates: mapbox.Position(
          widget.userLocation.lng,
          widget.userLocation.lat,
        ),
      ),
      zoom: 15,
    ),
    mapbox.MapAnimationOptions(duration: 1000),
  );

  @override
  Widget build(BuildContext context) {
    return mapbox.MapWidget(
      styleUri: widget.style == MapStyle.satellite
          ? mapbox.MapboxStyles.SATELLITE
          : widget.style == MapStyle.terrain
          ? mapbox.MapboxStyles.OUTDOORS
          : mapbox.MapboxStyles.MAPBOX_STREETS,
      cameraOptions: mapbox.CameraOptions(
        center: mapbox.Point(
          coordinates: mapbox.Position(
            widget.userLocation.lng,
            widget.userLocation.lat,
          ),
        ),
        zoom: 14,
      ),
      onMapCreated: _onMapCreated,
      onStyleLoadedListener: _onStyleLoaded,
      onCameraChangeListener: _onCameraChanged,
      onMapIdleListener: (_) => _refreshClustersOnIdle(),
      onLongTapListener: _onMapLongTap,
    );
  }

  Future<Uint8List> _loadAsset(String path) async {
    final data = await DefaultAssetBundle.of(context).load(path);
    return data.buffer.asUint8List();
  }

  Color _zoneColor(String name) {
    if (name == "Nyamirambo") return Colors.red;
    if (name == "Kimihurura") return Colors.blue;
    if (name == "Remera") return Colors.green;
    if (name == "Kigali Downtown") return Colors.purple;
    return Colors.orange;
  }

  @override
  void dispose() {
    _annotationTapEvents?.cancel();
    super.dispose();
  }
}
