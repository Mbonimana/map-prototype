import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:map_prototype_app/core/map/map_engine.dart';
import 'package:map_prototype_app/core/utils/mapbox_marker_icon_helper.dart';
import 'package:map_prototype_app/data/model/coordinate_model.dart';
import 'package:map_prototype_app/data/model/location_model.dart';
import 'package:map_prototype_app/presentation/ui/widgets/location_bottom_panel.dart';
import 'package:map_prototype_app/presentation/ui/widgets/map_control_panel.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

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
      userLocation: LatLng(userLocation.lat, userLocation.lng),
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
  PointAnnotationManager? _annotationManager;
  Cancelable? _annotationTapEvents;
  final Map<String, LocationModel> _locationByAnnotationId = {};
  PointAnnotation? _temporaryPointAnnotation;
  LocationModel? _selectedLocation;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MapWidget(
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
                  userLocation: _userAppLatLng,
                  onClose: () => setState(() => _selectedLocation = null),
                ),
        ),
      ],
    );
  }

  Future<void> _onMapCreated(MapboxMap map) async {
    mapboxMap = map;
    await _addMarkers();
  }

  Future<void> _addMarkers() async {
    final manager = await mapboxMap!.annotations.createPointAnnotationManager();
    _annotationManager = manager;
    _locationByAnnotationId.clear();

    for (final m in widget.markers) {
      final path = MapboxIconHelper.getAsset(m.category);
      final bytes = await _loadAsset(path);

      final annotation = await manager.create(
        PointAnnotationOptions(
          geometry: Point(
            coordinates: Position(m.position.lng, m.position.lat),
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

  Future<Uint8List> _loadAsset(String path) async {
    final data = await DefaultAssetBundle.of(context).load(path);
    return data.buffer.asUint8List();
  }

  Future<void> _onMapLongTap(MapContentGestureContext context) async {
    final manager = _annotationManager;
    if (manager == null) return;

    if (_temporaryPointAnnotation != null) {
      await manager.delete(_temporaryPointAnnotation!);
      _locationByAnnotationId.remove(_temporaryPointAnnotation!.id);
      _temporaryPointAnnotation = null;
    }

    final point = context.point;
    final position = point.coordinates;
    final tempLocation = LocationModel(
      name: 'Dropped Pin',
      category: 'temporary',
      position: AppLatLng(position.lat.toDouble(), position.lng.toDouble()),
      description: 'Temporary pin dropped by long-press.',
    );

    final bytes = await _loadAsset(MapboxIconHelper.getAsset('landmark'));
    final tempAnnotation = await manager.create(
      PointAnnotationOptions(geometry: point, image: bytes),
    );

    _temporaryPointAnnotation = tempAnnotation;
    _locationByAnnotationId[tempAnnotation.id] = tempLocation;

    if (!mounted) return;
    setState(() => _selectedLocation = tempLocation);
  }

  AppLatLng get _userAppLatLng =>
      AppLatLng(widget.userLocation.latitude, widget.userLocation.longitude);

  @override
  void dispose() {
    _annotationTapEvents?.cancel();
    super.dispose();
  }

  //  Fly
  Future<void> _flyToKigali() async {
    await mapboxMap?.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(30.0619, -1.9441)),
        zoom: 15,
      ),
      MapAnimationOptions(duration: 2000),
    );
  }

  //  Tilt
  Future<void> _tiltCamera() async {
    await mapboxMap?.flyTo(
      CameraOptions(
        center: Point(
          coordinates: Position(
            widget.userLocation.longitude,
            widget.userLocation.latitude,
          ),
        ),
        zoom: 15,
        pitch: 60,
        bearing: 45,
      ),
      MapAnimationOptions(duration: 3000),
    );
  }

  //  Reset
  Future<void> _resetCamera() async {
    await mapboxMap?.flyTo(
      CameraOptions(
        center: Point(
          coordinates: Position(
            widget.userLocation.longitude,
            widget.userLocation.latitude,
          ),
        ),
        zoom: 13,
        pitch: 0,
        bearing: 0,
      ),
      MapAnimationOptions(duration: 1500),
    );
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
