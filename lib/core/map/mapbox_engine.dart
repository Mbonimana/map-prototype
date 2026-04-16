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
  mapbox.PointAnnotation? _userAnnotation;

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
          onLongTapListener: _onMapLongTap,
        ),

        Positioned(
          bottom: 100,
          right: 10,
          child: MapControlsPanel(
            onFly: _flyToKigali,
            onTilt: _tiltCamera,
            onReset: _resetCamera,
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

    await _addMarkers();
    await _addUserLocationMarker();
  }

  //user location

  Future<void> _addUserLocationMarker() async {
    final manager =
        await mapboxMap!.annotations.createPointAnnotationManager();

    final bytes =
        await _loadAsset(MapboxIconHelper.getAsset('user'));

    _userAnnotation = await manager.create(
      mapbox.PointAnnotationOptions(
        geometry: mapbox.Point(
          coordinates: mapbox.Position(
            widget.userLocation.lng,
            widget.userLocation.lat,
          ),
        ),
        image: bytes,
        iconSize: 1.3,
      ),
    );
  }

  // markers

  Future<void> _addMarkers() async {
    final manager =
        await mapboxMap!.annotations.createPointAnnotationManager();

    _annotationManager = manager;
    _locationByAnnotationId.clear();

    for (final m in widget.markers) {
      final path = MapboxIconHelper.getAsset(m.category);
      final bytes = await _loadAsset(path);

      final annotation = await manager.create(
        mapbox.PointAnnotationOptions(
          geometry: mapbox.Point(
            coordinates: mapbox.Position(
              m.position.lng,
              m.position.lat,
            ),
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

  Future<void> _onMapLongTap(
      mapbox.MapContentGestureContext context) async {
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

    final bytes =
        await _loadAsset(MapboxIconHelper.getAsset('landmark'));

    _temporaryPointAnnotation = await manager.create(
      mapbox.PointAnnotationOptions(
        geometry: point,
        image: bytes,
      ),
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
        center: mapbox.Point(
          coordinates: mapbox.Position(30.0619, -1.9441),
        ),
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