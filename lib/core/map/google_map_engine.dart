import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:map_prototype_app/core/map/map_engine.dart';
import 'package:map_prototype_app/core/utils/goole_marker_icon_helper.dart';
import 'package:map_prototype_app/data/model/coordinate_model.dart';
import 'package:map_prototype_app/data/model/location_model.dart';

class GoogleMapEngine implements MapEngine {
  _GoogleMapViewState? _state;

  @override
  Widget buildMap({
    required List<LocationModel> markers,
    required AppLatLng userLocation,
    required MapStyle style,
    required Function(LocationModel?) onLocationSelected,
  }) {
    return _GoogleMapView(
      key: ValueKey(style),
      markers: markers,
      userLocation: LatLng(userLocation.lat, userLocation.lng),
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

class _GoogleMapView extends StatefulWidget {
  final List<LocationModel> markers;
  final LatLng userLocation;
  final MapStyle style;
  final Function(LocationModel?) onLocationSelected;
  final Function(_GoogleMapViewState) onCreated;

  const _GoogleMapView({
    super.key,
    required this.markers,
    required this.userLocation,
    required this.style,
    required this.onLocationSelected,
    required this.onCreated,
  });

  @override
  State<_GoogleMapView> createState() => _GoogleMapViewState();
}

class _GoogleMapViewState extends State<_GoogleMapView> {
  final Set<Marker> _markers = {};
  GoogleMapController? _controller;
  final Set<Polygon> _polygons = {};
  final Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    widget.onCreated(this);
    _loadMarkers();
    _loadZones();
    _loadRoute();
  }

  final String _noLabelsStyle =
      '[{"featureType": "poi","stylers":[{"visibility":"off"}]},{"featureType":"transit","stylers":[{"visibility":"off"}]},{"featureType":"road","elementType":"labels","stylers":[{"visibility":"off"}]},{"featureType":"administrative","elementType":"labels","stylers":[{"visibility":"off"}]}]';

  String? _mapStyleFor(MapStyle style) =>
      style == MapStyle.streets ? _noLabelsStyle : null;

  Future<void> _loadMarkers() async {
    final Set<Marker> result = {};
    for (final m in widget.markers) {
      final icon = await MarkerIconHelper.getIcon(m.category);
      result.add(
        Marker(
          markerId: MarkerId(m.name),
          position: LatLng(m.position.lat, m.position.lng),
          icon: icon,
          onTap: () => widget.onLocationSelected(m),
        ),
      );
    }
    if (mounted) {
      setState(
        () => _markers
          ..clear()
          ..addAll(result),
      );
    }
  }

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
      final List<LatLng> points = coords
          .map<LatLng>((c) => LatLng(c[1], c[0]))
          .toList();

      polygons.add(
        Polygon(
          polygonId: PolygonId(name),
          points: points,
          strokeWidth: 2,
          strokeColor: _getColor(name),
          fillColor: _getColor(name).withAlpha(75),
        ),
      );
    }
    setState(
      () => _polygons
        ..clear()
        ..addAll(polygons),
    );
  }

  Future<void> _loadRoute() async {
    final jsonString = await DefaultAssetBundle.of(
      context,
    ).loadString('assets/mock/routes.geojson');
    final data = jsonDecode(jsonString);
    final feature = data['features'][0];
    final coords = feature['geometry']['coordinates'] as List;
    final List<LatLng> points = coords
        .map<LatLng>((c) => LatLng(c[1], c[0]))
        .toList();

    setState(() {
      _polylines.clear();
      _polylines.add(
        Polyline(
          polylineId: const PolylineId("route"),
          points: points,
          color: Colors.red,
          width: 2,
        ),
      );
    });
  }

  void _onMapLongPress(LatLng pos) {
    final temp = LocationModel(
      name: 'Dropped Pin',
      category: 'temporary',
      position: AppLatLng(pos.latitude, pos.longitude),
      description: 'Temporary pin dropped.',
    );
    widget.onLocationSelected(temp);
  }

  // Camera Logic
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

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: widget.userLocation,
        zoom: 13,
      ),
      myLocationButtonEnabled: false,
      myLocationEnabled: true,
      mapType: widget.style == MapStyle.satellite
          ? MapType.satellite
          : widget.style == MapStyle.terrain
          ? MapType.terrain
          : MapType.normal,
      markers: _markers,
      polygons: _polygons,
      polylines: _polylines,
      onMapCreated: (c) => _controller = c,
      onLongPress: _onMapLongPress,
      style: _mapStyleFor(widget.style),
      zoomControlsEnabled: false,
    );
  }

  Color _getColor(String name) {
    if (name == "Nyamirambo") return Colors.red;
    if (name == "Kimihurura") return Colors.blue;
    if (name == "Remera") return Colors.green;
    return Colors.orange;
  }
}
