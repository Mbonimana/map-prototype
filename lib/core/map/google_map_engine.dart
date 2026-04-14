import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:map_prototype_app/core/map/map_engine.dart';
import 'package:map_prototype_app/core/utils/goole_marker_icon_helper.dart';
import 'package:map_prototype_app/data/model/location_model.dart';

class GoogleMapEngine implements MapEngine {
  @override
  Widget buildMap({
    required List<LocationModel> markers,
    required LatLng userLocation,
    required MapStyle style,
  }) {
    return _GoogleMapView(
      markers: markers,
      userLocation: userLocation,
      style: style,
    );
  }

  MapType _mapType(MapStyle style) {
    switch (style) {
      case MapStyle.satellite:
        return MapType.satellite;
      case MapStyle.terrain:
        return MapType.terrain;
      case MapStyle.streets:
        return MapType.normal;
    }
  }
}

class _GoogleMapView extends StatefulWidget {
  final List<LocationModel> markers;
  final LatLng userLocation;
  final MapStyle style;

  const _GoogleMapView({
    required this.markers,
    required this.userLocation,
    required this.style,
  });

  @override
  State<_GoogleMapView> createState() => _GoogleMapViewState();
}

class _GoogleMapViewState extends State<_GoogleMapView> {
  final Set<Marker> _markers = {};

  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_loaded) {
      _loadMarkers();
      _loaded = true;
    }
  }

  Future<void> _loadMarkers() async {
    final Set<Marker> result = {};

    for (final m in widget.markers) {
      final icon = await MarkerIconHelper.getIcon(m.category);

      result.add(
        Marker(
          markerId: MarkerId(m.name),
          position: m.position,
          infoWindow: InfoWindow(title: m.name),
          icon: icon,
        ),
      );
    }

    setState(() {
      _markers.clear();
      _markers.addAll(result);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: widget.userLocation,
        zoom: 13,
      ),
      mapType: _mapType(widget.style),
      markers: _markers,
    );
  }

  MapType _mapType(MapStyle style) {
    switch (style) {
      case MapStyle.satellite:
        return MapType.satellite;
      case MapStyle.terrain:
        return MapType.terrain;
      case MapStyle.streets:
        return MapType.normal;
    }
  }
}
