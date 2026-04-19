// ignore_for_file: deprecated_member_use
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
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
    required Function(LocationModel?) onLocationSelected,
  }) {
    return _MapboxView(
      key: ValueKey(style),
      markers: markers,
      userLocation: userLocation,
      style: style,
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
  final Function(LocationModel?) onLocationSelected;
  final Function(_MapboxViewState) onCreated;

  const _MapboxView({
    super.key,
    required this.markers,
    required this.userLocation,
    required this.style,
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
  final Map<String, LocationModel> _locationByAnnotationId = {};

  @override
  void initState() {
    super.initState();
    widget.onCreated(this);
  }

  void _onMapCreated(mapbox.MapboxMap map) => mapboxMap = map;

  Future<void> _onStyleLoaded(mapbox.StyleLoadedEventData eventData) async {
    await _removeAllLabels();
    await _addZones();
    await _addMarkers();
    await _addRoute();
    await mapboxMap!.location.updateSettings(
      mapbox.LocationComponentSettings(enabled: true),
    );
  }

  Future<void> _addMarkers() async {
    final manager = await mapboxMap!.annotations.createPointAnnotationManager();
    _annotationManager = manager;
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
    _annotationTapEvents = manager.tapEvents(
      onTap: (a) => widget.onLocationSelected(_locationByAnnotationId[a.id]),
    );
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

  void _onMapLongTap(mapbox.MapContentGestureContext context) {
    final loc = LocationModel(
      name: 'Dropped Pin',
      category: 'temporary',
      position: AppLatLng(
        context.point.coordinates.lat.toDouble(),
        context.point.coordinates.lng.toDouble(),
      ),
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
      onLongTapListener: _onMapLongTap,
    );
  }

  Future<Uint8List> _loadAsset(String path) async {
    final data = await DefaultAssetBundle.of(context).load(path);
    return data.buffer.asUint8List();
  }

  Color _zoneColor(String name) => name == 'Nyamirambo'
      ? Colors.red
      : name == 'Kimihurura'
      ? Colors.blue
      : Colors.green;

  @override
  void dispose() {
    _annotationTapEvents?.cancel();
    super.dispose();
  }
}
