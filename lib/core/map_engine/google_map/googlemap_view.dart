// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:latlong2/latlong.dart' as geo;
import 'package:map_prototype_app/core/constants/google_map_constants.dart';
import 'package:map_prototype_app/core/map_engine/google_map/controllers/annotation_controller.dart';
import 'package:map_prototype_app/core/map_engine/google_map/controllers/camera_controller.dart';
import 'package:map_prototype_app/core/map_engine/google_map/features/clustering/cluster_icon_builder.dart';
import 'package:map_prototype_app/core/map_engine/google_map/features/clustering/cluster_service.dart';
import 'package:map_prototype_app/core/map_engine/google_map/features/heatmap/heatmap_source.dart';
import 'package:map_prototype_app/core/map_engine/google_map/features/routes/route_renderer.dart';
import 'package:map_prototype_app/core/map_engine/google_map/features/zones/zone_renderer.dart';
import 'package:map_prototype_app/core/map_engine/map_engine.dart';
import 'package:map_prototype_app/data/model/coordinate_model.dart';
import 'package:map_prototype_app/data/model/location_model.dart';

class GoogleMapView extends StatefulWidget {
  final List<LocationModel> markers;
  final AppLatLng userLocation;
  final MapStyle style;
  final MapViewMode viewMode;
  final Function(LocationModel?) onLocationSelected;
  final Function(GoogleMapViewState) onCreated;

  const GoogleMapView({
    super.key,
    required this.markers,
    required this.userLocation,
    required this.style,
    required this.viewMode,
    required this.onLocationSelected,
    required this.onCreated,
  });

  @override
  State<GoogleMapView> createState() => GoogleMapViewState();
}

class GoogleMapViewState extends State<GoogleMapView> {
  final Set<Marker> _markers = {};
  final Set<Polygon> _polygons = {};
  final Set<Polyline> _polylines = {};
  final geo.Distance _distance = const geo.Distance();

  GoogleMapController? _controller;
  Marker? _droppedPinMarker;
  Set<TileOverlay> _tileOverlays = {};
  double _currentZoom = GoogleMapConstants.defaultZoom;
  double? _lastClusterZoom;

  late final ClusterService _clusterService = ClusterService(_distance);

  @override
  void initState() {
    super.initState();
    widget.onCreated(this);

    _loadMarkers();
    _loadZones();
    _loadRoute();
  }

  String? _mapStyleFor(MapStyle style) =>
      style == MapStyle.streets ? GoogleMapConstants.noLabelsStyle : null;

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
    final overlay = HeatmapSource.build(markers);

    setState(() {
      _tileOverlays = {overlay};
      _markers.clear();
    });
  }

  Future<void> _loadNormalMarkers() async {
    final Set<Marker> nextMarkers = {};

    for (final marker in widget.markers) {
      nextMarkers.add(
        await AnnotationController.buildMarker(
          location: marker,
          onTap: widget.onLocationSelected,
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

  Future<void> _loadClusterMarkers({bool force = false}) async {
    if (!force &&
        _lastClusterZoom != null &&
        (_currentZoom - _lastClusterZoom!).abs() <
            GoogleMapConstants.clusterZoomDelta) {
      return;
    }

    final Set<Marker> nextMarkers = {};
    final clusters = _clusterService.createClusters(
      widget.markers,
      _currentZoom,
    );

    for (final cluster in clusters) {
      if (cluster.length == 1) {
        final marker = cluster.first;

        nextMarkers.add(
          await AnnotationController.buildMarker(
            location: marker,
            onTap: widget.onLocationSelected,
          ),
        );
      } else {
        final center = cluster.first.position;
        final icon = BitmapDescriptor.fromBytes(
          await ClusterIconBuilder.build(cluster.length),
        );

        nextMarkers.add(
          Marker(
            markerId: MarkerId('cluster_${center.lat}_${center.lng}'),
            position: LatLng(center.lat, center.lng),
            icon: icon,
            onTap: () {
              _controller?.animateCamera(
                CameraUpdate.newLatLngZoom(
                  LatLng(center.lat, center.lng),
                  _currentZoom + GoogleMapConstants.clusterZoomIn,
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

  Future<void> _loadZones() async {
    final polygons = await ZoneRenderer.render(context);

    if (!mounted) return;
    setState(() {
      _polygons
        ..clear()
        ..addAll(polygons);
    });
  }

  Future<void> _loadRoute() async {
    final polylines = await RouteRenderer.render(context);

    if (!mounted) return;
    setState(() {
      _polylines
        ..clear()
        ..addAll(polylines);
    });
  }

  void flyToKigali() {
    if (_controller == null) return;
    CameraController(_controller!, widget.userLocation).flyToKigali();
  }

  void flyToLocation(AppLatLng pos) {
    if (_controller == null) return;
    CameraController(_controller!, widget.userLocation).flyTo(pos);
  }

  void tiltCamera() {
    if (_controller == null) return;
    CameraController(_controller!, widget.userLocation).tiltCamera();
  }

  void resetCamera() {
    if (_controller == null) return;
    CameraController(_controller!, widget.userLocation).resetCamera();
  }

  void goToUserLocation() {
    if (_controller == null) return;
    CameraController(_controller!, widget.userLocation).goToUserLocation();
  }

  Future<void> _onMapLongPress(LatLng position) async {
    final tempLocation = AnnotationController.buildDroppedLocation(position);
    final droppedMarker = await AnnotationController.buildDroppedPinMarker(
      position: position,
      location: tempLocation,
      onTap: widget.onLocationSelected,
    );

    if (!mounted) return;
    setState(() {
      _droppedPinMarker = droppedMarker;
      _markers.removeWhere(
        (marker) => marker.markerId.value == GoogleMapConstants.droppedPinId,
      );
      _markers.add(droppedMarker);
    });

    widget.onLocationSelected(tempLocation);
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(widget.userLocation.lat, widget.userLocation.lng),
        zoom: GoogleMapConstants.defaultZoom,
      ),
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      markers: _markers,
      polygons: _polygons,
      polylines: _polylines,
      onMapCreated: (controller) => _controller = controller,
      onCameraMove: (position) => _currentZoom = position.zoom,
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
}
