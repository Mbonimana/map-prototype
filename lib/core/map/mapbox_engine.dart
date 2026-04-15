import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:map_prototype_app/core/map/map_engine.dart';
import 'package:map_prototype_app/core/utils/mapbox_marker_icon_helper.dart';
import 'package:map_prototype_app/data/model/location_model.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class MapboxMapEngine implements MapEngine {
  @override
  Widget buildMap({
    required List<LocationModel> markers,
    required LatLng userLocation,
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
  final LatLng userLocation;
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
  MapboxMap? mapboxMap;

  @override
  Widget build(BuildContext context) {
    return MapWidget(
      key: ValueKey(widget.style),
      styleUri: _style(widget.style),
      cameraOptions: CameraOptions(
        center: Point(
          coordinates: Position(
            widget.userLocation.longitude,
            widget.userLocation.latitude,
          ),
        ),
        zoom: 13,
      ),
      onMapCreated: _onMapCreated,
    );
  }

  Future<void> _onMapCreated(MapboxMap map) async {
    mapboxMap = map;
    await _addMarkers();
  }

  Future<void> _addMarkers() async {
    final manager = await mapboxMap!.annotations.createPointAnnotationManager();

    for (final m in widget.markers) {
      final path = MapboxIconHelper.getAsset(m.category);
      final bytes = await _loadAsset(path);

      await manager.create(
        PointAnnotationOptions(
          geometry: Point(
            coordinates: Position(m.position.longitude, m.position.latitude),
          ),
          image: bytes,
        ),
      );
    }
  }

  Future<Uint8List> _loadAsset(String path) async {
    final data = await DefaultAssetBundle.of(context).load(path);
    return data.buffer.asUint8List();
  }

  String _style(MapStyle style) {
    switch (style) {
      case MapStyle.satellite:
        return MapboxStyles.SATELLITE;
      case MapStyle.terrain:
        return MapboxStyles.OUTDOORS;
      case MapStyle.streets:
        return MapboxStyles.MAPBOX_STREETS;
    }
  }
}
