import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:map_prototype_app/core/map/map_engine.dart';
import 'package:map_prototype_app/core/utils/goole_marker_icon_helper.dart';
import 'package:map_prototype_app/data/model/coordinate_model.dart';
import 'package:map_prototype_app/data/model/location_model.dart';
import 'package:map_prototype_app/presentation/ui/widgets/location_bottom_panel.dart';
import 'package:map_prototype_app/presentation/ui/widgets/map_control_panel.dart';

class GoogleMapEngine implements MapEngine {
  @override
  Widget buildMap({
    required List<LocationModel> markers,

    required AppLatLng userLocation,
    required MapStyle style,
  }) {
    return _GoogleMapView(
      key: ValueKey(style),
      markers: markers,
      userLocation: LatLng(userLocation.lat, userLocation.lng),
      style: style,
    );
  }
}

class _GoogleMapView extends StatefulWidget {
  final List<LocationModel> markers;
  final LatLng userLocation;
  final MapStyle style;

  const _GoogleMapView({
    super.key,
    required this.markers,
    required this.userLocation,
    required this.style,
  });

  @override
  State<_GoogleMapView> createState() => _GoogleMapViewState();
}

class _GoogleMapViewState extends State<_GoogleMapView> {
  final Set<Marker> _markers = {};
  GoogleMapController? _controller;
  LocationModel? _selectedLocation;
  Marker? _temporaryMarker;
  final Set<Polygon> _polygons = {};

  @override
  void initState() {
    super.initState();
    _loadMarkers();
    _loadZones();
  }

  final String _noLabelsStyle = '''
[
  {
    "featureType": "poi",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "transit",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "road",
    "elementType": "labels",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "administrative",
    "elementType": "labels",
    "stylers": [{"visibility": "off"}]
  }
]
''';

  //disable
  String? _mapStyleFor(MapStyle style) {
    if (style == MapStyle.streets) {
      return _noLabelsStyle;
    }
    return null;
  }

  Future<void> _loadMarkers() async {
    final Set<Marker> result = {};

    for (final m in widget.markers) {
      final icon = await MarkerIconHelper.getIcon(m.category);

      result.add(
        Marker(
          markerId: MarkerId(m.name),
          position: LatLng(m.position.lat, m.position.lng),
          infoWindow: InfoWindow(title: m.name),
          icon: icon,
          onTap: () {
            if (!mounted) return;
            setState(() => _selectedLocation = m);
          },
        ),
      );
    }

    if (_temporaryMarker != null) {
      result.add(_temporaryMarker!);
    }

    if (!mounted) return;

    setState(() {
      _markers
        ..clear()
        ..addAll(result);
    });
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

      final List<LatLng> points = coords.map<LatLng>((c) {
        return LatLng(c[1], c[0]); //  lat,lng swap
      }).toList();

      polygons.add(
        Polygon(
          polygonId: PolygonId(name),
          points: points,
          strokeWidth: 2,
          strokeColor: _getColor(name),
          fillColor: _getColor(name).withOpacity(0.3),
          consumeTapEvents: true,
          onTap: () {
            print("Tapped zone: $name");
          },
        ),
      );
    }

    setState(() {
      _polygons.clear();
      _polygons.addAll(polygons);
    });
  }

  Color _getColor(String name) {
    switch (name) {
      case "Nyamirambo":
        return Colors.red;
      case "Kimihurura":
        return Colors.blue;
      case "Remera":
        return Colors.green;
      case "Kigali Downtown":
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _onMapLongPress(LatLng position) {
    final temporaryLocation = LocationModel(
      name: 'Dropped Pin',
      category: 'temporary',
      position: AppLatLng(position.latitude, position.longitude),
      description: 'Temporary pin dropped by long-press.',
    );

    final marker = Marker(
      markerId: const MarkerId('__temporary_pin__'),
      position: position,
      infoWindow: const InfoWindow(title: 'Dropped Pin'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      onTap: () {
        if (!mounted) return;
        setState(() => _selectedLocation = temporaryLocation);
      },
    );

    setState(() {
      _temporaryMarker = marker;
      _markers.removeWhere((m) => m.markerId.value == '__temporary_pin__');
      _markers.add(marker);
      _selectedLocation = temporaryLocation;
    });
  }

  AppLatLng get _userAppLatLng =>
      AppLatLng(widget.userLocation.latitude, widget.userLocation.longitude);

  // Fly to Kigali
  Future<void> _flyToKigali() async {
    const kigali = LatLng(-1.9441, 30.0619);

    await _controller?.animateCamera(
      CameraUpdate.newCameraPosition(
        const CameraPosition(target: kigali, zoom: 15),
      ),
    );
  }

  //  Tilt
  Future<void> _tiltCamera() async {
    await _controller?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: widget.userLocation,
          zoom: 15,
          tilt: 60,
          bearing: 45,
        ),
      ),
    );
  }

  // Reset
  Future<void> _resetCamera() async {
    await _controller?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: widget.userLocation,
          zoom: 13,
          tilt: 0,
          bearing: 0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          key: ValueKey(widget.style),
          initialCameraPosition: CameraPosition(
            target: widget.userLocation,
            zoom: 13,
          ),
          myLocationButtonEnabled: true,
          myLocationEnabled: true,
          mapType: _mapType(widget.style),
          markers: _markers,
          zoomControlsEnabled: true,
          onLongPress: _onMapLongPress,
          onMapCreated: (c) => _controller = c,
          style: _mapStyleFor(widget.style),
          polygons: _polygons,
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
