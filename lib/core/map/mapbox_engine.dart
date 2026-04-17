// ignore_for_file: deprecated_member_use
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:map_prototype_app/core/map/map_engine.dart';
import 'package:map_prototype_app/core/utils/mapbox_marker_icon_helper.dart';
import 'package:map_prototype_app/data/model/coordinate_model.dart';
import 'package:map_prototype_app/data/model/location_model.dart';
import 'package:map_prototype_app/presentation/ui/widgets/location_bottom_panel.dart';
import 'package:map_prototype_app/presentation/ui/widgets/map_control_panel.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;

class MapboxMapEngine implements MapEngine {
  @override
  Widget buildMap({
    required List<LocationModel> markers,
    required AppLatLng userLocation,
    required MapStyle style,
  }) {
    return _MapboxView(
      key: ValueKey(style),
      markers: markers,
      userLocation: userLocation,
      style: style,
    );
  }
}

class _MapboxView extends StatefulWidget {
  final List<LocationModel> markers;
  final AppLatLng userLocation;
  final MapStyle style;

  const _MapboxView({
    super.key,
    required this.markers,
    required this.userLocation,
    required this.style,
  });

  @override
  State<_MapboxView> createState() => _MapboxViewState();
}

class _MapboxViewState extends State<_MapboxView> {
  mapbox.MapboxMap? mapboxMap;

  mapbox.PointAnnotationManager? _annotationManager;
  mapbox.Cancelable? _annotationTapEvents;

  final Map<String, LocationModel> _locationByAnnotationId = {};

  mapbox.PointAnnotation? _temporaryPointAnnotation;

  LocationModel? _selectedLocation;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        mapbox.MapWidget(
          key: ValueKey(widget.style),
          styleUri: _style(widget.style),

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
          onLongTapListener: _onMapLongTap,
        ),

        Positioned(
          bottom: 100,
          right: 10,
          child: MapControlsPanel(
            onFly: _flyToKigali,
            onTilt: _tiltCamera,
            onReset: _resetCamera,
            onLocation: _goToUserLocation,
          ),
        ),

        AnimatedPositioned(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOut,
          left: 0,
          right: 0,
          bottom: _selectedLocation != null ? 0 : -260,
          child: _selectedLocation == null
              ? const SizedBox.shrink()
              : LocationBottomPanel(
                  location: _selectedLocation!,
                  userLocation: widget.userLocation,
                  onClose: () => setState(() => _selectedLocation = null),
                ),
        ),
      ],
    );
  }

  // map initialization

  Future<void> _onMapCreated(mapbox.MapboxMap map) async {
    mapboxMap = map;
  }
  Future<void> _goToUserLocation() async {
  final map = mapboxMap;
  if (map == null) return;

  await map.flyTo(
    mapbox.CameraOptions(
      center: mapbox.Point(
        coordinates: mapbox.Position(
          widget.userLocation.lng,
          widget.userLocation.lat,
        ),
      ),
      zoom: 15,
    ),
    mapbox.MapAnimationOptions(
      duration: 1200,
    ),
  );
}
  

  Future<void> _addZones() async {
    final geojson = await DefaultAssetBundle.of(
      context,
    ).loadString('assets/mock/zones.geojson');

    final style = mapboxMap?.style;
    if (style == null) return;

    final decoded = jsonDecode(geojson) as Map<String, dynamic>;
    final features = (decoded['features'] as List?) ?? const [];

    for (final feature in features) {
      final featureMap = feature as Map<String, dynamic>;
      final properties = (featureMap['properties'] as Map?) ?? const {};
      final zoneName = (properties['name'] ?? 'Unknown').toString();
      final zoneId = _zoneLayerId(zoneName);
      final zoneColor = _zoneColor(zoneName);

      final singleFeatureCollection = jsonEncode({
        'type': 'FeatureCollection',
        'features': [featureMap],
      });

      try {
        await style.addSource(
          mapbox.GeoJsonSource(
            id: 'zones-source-$zoneId',
            data: singleFeatureCollection,
          ),
        );
      } catch (_) {
        // Source may already exist after a rebuild or style reload.
      }

      try {
        await style.addLayer(
          mapbox.FillLayer(
            id: 'zones-fill-$zoneId',
            sourceId: 'zones-source-$zoneId',
            fillColor: zoneColor.value,
            fillOpacity: 0.3,
          ),
        );
      } catch (_) {
        // Layer may already exist after a rebuild or style reload.
      }

      try {
        await style.addLayer(
          mapbox.LineLayer(
            id: 'zones-border-$zoneId',
            sourceId: 'zones-source-$zoneId',
            lineColor: zoneColor.value,
            lineWidth: 2.0,
          ),
        );
      } catch (_) {
        // Layer may already exist after a rebuild or style reload.
      }
    }
  }

  Color _zoneColor(String name) {
    switch (name) {
      case 'Nyamirambo':
        return Colors.red;
      case 'Kimihurura':
        return Colors.blue;
      case 'Remera':
        return Colors.green;
      case 'Kigali Downtown':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _zoneLayerId(String zoneName) {
    final normalized = zoneName.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]+'),
      '-',
    );
    return normalized.replaceAll(RegExp(r'^-+|-+$'), '');
  }

  Future<void> _onStyleLoaded(mapbox.StyleLoadedEventData eventData) async {
    await _removeAllLabels();
    await _addZones();
    await _addMarkers();
    await _enableUserLocation();
    await _addRoute();
  }

  //user location

  Future<void> _enableUserLocation() async {
    if (mapboxMap == null) return;

    await mapboxMap!.location.updateSettings(
      mapbox.LocationComponentSettings(enabled: true, pulsingEnabled: true),
    );
  }

  Future<void> _addRoute() async {
    final style = mapboxMap?.style;
    if (style == null) return;

    final geojson = await DefaultAssetBundle.of(
      context,
    ).loadString('assets/mock/routes.geojson');

    const sourceId = "route-source";
    const layerId = "route-layer";

    try {
      await style.addSource(mapbox.GeoJsonSource(id: sourceId, data: geojson));
    } catch (_) {}

    try {
      await style.addLayer(
        mapbox.LineLayer(
          id: layerId,
          sourceId: sourceId,
          lineColor: Colors.blue.value,
          lineWidth: 2.0,
          lineJoin: mapbox.LineJoin.ROUND,
          lineCap: mapbox.LineCap.ROUND,
        ),
      );
    } catch (_) {}
  }

  Future<void> _removeAllLabels() async {
    final style = mapboxMap?.style;
    if (style == null) return;

    final layers = await style.getStyleLayers();

    for (final layer in layers) {
      final layerType = layer?.type;
      final layerId = layer?.id;
      if (layerType == 'symbol' && layerId != null) {
        await style.setStyleLayerProperty(layerId, 'visibility', 'none');
      }
    }
  }

  // markers

  Future<void> _addMarkers() async {
    final manager = await mapboxMap!.annotations.createPointAnnotationManager();

    _annotationManager = manager;
    _locationByAnnotationId.clear();

    for (final m in widget.markers) {
      final path = MapboxIconHelper.getAsset(m.category);
      final bytes = await _loadAsset(path);

      final annotation = await manager.create(
        mapbox.PointAnnotationOptions(
          geometry: mapbox.Point(
            coordinates: mapbox.Position(m.position.lng, m.position.lat),
          ),
          image: bytes,
        ),
      );

      _locationByAnnotationId[annotation.id] = m;
    }

    _annotationTapEvents?.cancel();
    _annotationTapEvents = manager.tapEvents(
      onTap: (annotation) {
        final selected = _locationByAnnotationId[annotation.id];
        if (selected == null || !mounted) return;

        setState(() => _selectedLocation = selected);
      },
    );
  }

  //long press to drop pin

  Future<void> _onMapLongTap(mapbox.MapContentGestureContext context) async {
    final manager = _annotationManager;
    if (manager == null) return;

    if (_temporaryPointAnnotation != null) {
      await manager.delete(_temporaryPointAnnotation!);
    }

    final point = context.point;
    final pos = point.coordinates;

    final tempLocation = LocationModel(
      name: 'Dropped Pin',
      category: 'temporary',
      position: AppLatLng(pos.lat.toDouble(), pos.lng.toDouble()),
      description: 'Temporary pin dropped',
    );

    final bytes = await _loadAsset(MapboxIconHelper.getAsset('landmark'));

    _temporaryPointAnnotation = await manager.create(
      mapbox.PointAnnotationOptions(geometry: point, image: bytes),
    );

    _locationByAnnotationId[_temporaryPointAnnotation!.id] = tempLocation;

    if (!mounted) return;
    setState(() => _selectedLocation = tempLocation);
  }

  // utils

  Future<Uint8List> _loadAsset(String path) async {
    final data = await DefaultAssetBundle.of(context).load(path);
    return data.buffer.asUint8List();
  }

  String _style(MapStyle style) {
    switch (style) {
      case MapStyle.satellite:
        return mapbox.MapboxStyles.SATELLITE;
      case MapStyle.terrain:
        return mapbox.MapboxStyles.OUTDOORS;
      case MapStyle.streets:
        return mapbox.MapboxStyles.MAPBOX_STREETS;
    }
  }

  @override
  void dispose() {
    _annotationTapEvents?.cancel();
    super.dispose();
  }

  // camera controls

  Future<void> _flyToKigali() async {
    await mapboxMap?.flyTo(
      mapbox.CameraOptions(
        center: mapbox.Point(coordinates: mapbox.Position(30.0619, -1.9441)),
        zoom: 15,
      ),
      mapbox.MapAnimationOptions(duration: 2000),
    );
  }

  Future<void> _tiltCamera() async {
    await mapboxMap?.flyTo(
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
      mapbox.MapAnimationOptions(duration: 3000),
    );
  }

  Future<void> _resetCamera() async {
    await mapboxMap?.flyTo(
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
  }
}
