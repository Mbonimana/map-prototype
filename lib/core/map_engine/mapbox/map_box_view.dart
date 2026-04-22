// ignore_for_file: use_build_context_synchronously, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as geo;
import 'package:map_prototype_app/core/map_engine/map_engine.dart';
import 'package:map_prototype_app/core/map_engine/mapbox/controllers/camera_controller.dart';
import 'package:map_prototype_app/core/map_engine/mapbox/features/clustering/cluster_icon_builder.dart';
import 'package:map_prototype_app/core/map_engine/mapbox/features/clustering/cluster_service.dart';
import 'package:map_prototype_app/core/map_engine/mapbox/features/heatmap/heat_map_layer.dart';
import 'package:map_prototype_app/core/map_engine/mapbox/features/heatmap/heat_map_source.dart';
import 'package:map_prototype_app/core/map_engine/mapbox/routes/route_renderer.dart';
import 'package:map_prototype_app/core/map_engine/mapbox/zones/zone_renderer.dart';
import 'package:map_prototype_app/core/utils/asset_loader.dart';
import 'package:map_prototype_app/core/utils/mapbox_marker_icon_helper.dart';
import 'package:map_prototype_app/core/utils/styel_cleaner.dart';
import 'package:map_prototype_app/data/model/coordinate_model.dart';
import 'package:map_prototype_app/data/model/location_model.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;

class MapboxView extends StatefulWidget {
  final List<LocationModel> markers;
  final AppLatLng userLocation;
  final MapStyle style;
  final MapViewMode viewMode;
  final Function(LocationModel?) onLocationSelected;
  final Function(MapboxViewState) onCreated;

  const MapboxView({
    super.key,
    required this.markers,
    required this.userLocation,
    required this.style,
    required this.viewMode,
    required this.onLocationSelected,
    required this.onCreated,
  });

  @override
  State<MapboxView> createState() => MapboxViewState();
}

class MapboxViewState extends State<MapboxView> {
  mapbox.MapboxMap? mapboxMap;
  mapbox.PointAnnotationManager? _annotationManager;
  mapbox.Cancelable? _tapEvents;

  final geo.Distance _distance = const geo.Distance();
  late final ClusterService _clusterService;
  bool _isRendering = false;

  CameraController get camera =>
      CameraController(mapboxMap!, widget.userLocation);

  final Map<String, LocationModel> _locationMap = {};
  final Map<String, AppLatLng> _clusterCenters = {};

  AppLatLng? _droppedPin;
  double _zoom = 14;
  double? _lastClusterZoom;

  @override
  void initState() {
    super.initState();
    _clusterService = ClusterService(_distance);
    widget.onCreated(this);
  }

  void _onMapCreated(mapbox.MapboxMap map) {
    mapboxMap = map;
  }

  Future<void> _onStyleLoaded(mapbox.StyleLoadedEventData _) async {
    await StyleCleaner.hideAllLabels(mapboxMap!);
    await ZoneRenderer.render(context, mapboxMap!);
    await RouteRenderer.render(context, mapboxMap!);

    await _setupAnnotations();
    await _renderByMode(force: true);

    await mapboxMap!.location.updateSettings(
      mapbox.LocationComponentSettings(enabled: true),
    );
  }

  Future<void> _setupAnnotations() async {
    _tapEvents?.cancel();
    _annotationManager = await mapboxMap!.annotations
        .createPointAnnotationManager();
    _tapEvents = _annotationManager!.tapEvents(onTap: _onTap);
  }

  Future<void> _renderByMode({bool force = false}) async {
    if (_isRendering) return;

    _isRendering = true;
    try {
      switch (widget.viewMode) {
        case MapViewMode.pins:
          await _renderPins();
          break;

        case MapViewMode.clusters:
          await _renderClusters(force);
          break;

        case MapViewMode.heatmap:
          await _clear();
          final geojson = HeatmapSourceBuilder.build(widget.markers);

          await mapboxMap!.style.addSource(
            mapbox.GeoJsonSource(id: "heatmap-source", data: geojson),
          );

          await mapboxMap!.style.addLayer(HeatmapLayerFactory.create());
          break;
      }
    } finally {
      _isRendering = false;
    }
  }

  Future<void> _clear() async {
    await _annotationManager?.deleteAll();
    _locationMap.clear();
    _clusterCenters.clear();
  }

  Future<void> _renderPins() async {
    await _clear();

    for (final m in widget.markers) {
      final bytes = await AssetLoader.load(
        context,
        MapboxIconHelper.getAsset(m.category),
      );

      final ann = await _annotationManager!.create(
        mapbox.PointAnnotationOptions(
          geometry: mapbox.Point(
            coordinates: mapbox.Position(m.position.lng, m.position.lat),
          ),
          image: bytes,
        ),
      );

      _locationMap[ann.id] = m;
    }

    await _addDroppedPin();
  }

  Future<void> _renderClusters(bool force) async {
    if (!force &&
        _lastClusterZoom != null &&
        (_zoom - _lastClusterZoom!).abs() < 0.3) {
      return;
    }

    await _clear();

    final clusters = _clusterService.createClusters(widget.markers, _zoom);

    for (final cluster in clusters) {
      if (cluster.length == 1) {
        final m = cluster.first;

        final bytes = await AssetLoader.load(
          context,
          MapboxIconHelper.getAsset(m.category),
        );

        final ann = await _annotationManager!.create(
          mapbox.PointAnnotationOptions(
            geometry: mapbox.Point(
              coordinates: mapbox.Position(m.position.lng, m.position.lat),
            ),
            image: bytes,
          ),
        );

        _locationMap[ann.id] = m;
      } else {
        final center = cluster.first.position;

        final icon = await ClusterIconBuilder.build(cluster.length);

        final ann = await _annotationManager!.create(
          mapbox.PointAnnotationOptions(
            geometry: mapbox.Point(
              coordinates: mapbox.Position(center.lng, center.lat),
            ),
            image: icon,
          ),
        );

        _clusterCenters[ann.id] = center;
      }
    }

    await _addDroppedPin();
    _lastClusterZoom = _zoom;
  }

  Future<void> _addDroppedPin() async {
    if (_droppedPin == null) return;

    final bytes = await AssetLoader.load(context, 'assets/icons/user.png');

    final ann = await _annotationManager!.create(
      mapbox.PointAnnotationOptions(
        geometry: mapbox.Point(
          coordinates: mapbox.Position(_droppedPin!.lng, _droppedPin!.lat),
        ),
        image: bytes,
      ),
    );

    _locationMap[ann.id] = LocationModel(
      name: 'Dropped Pin',
      category: 'temporary',
      position: _droppedPin!,
      description: 'Dropped pin',
    );
  }

  void _onTap(mapbox.PointAnnotation ann) {
    if (_clusterCenters.containsKey(ann.id)) {
      final c = _clusterCenters[ann.id]!;

      mapboxMap?.flyTo(
        mapbox.CameraOptions(
          center: mapbox.Point(coordinates: mapbox.Position(c.lng, c.lat)),
          zoom: _zoom + 2,
        ),
        mapbox.MapAnimationOptions(duration: 600),
      );
      return;
    }

    widget.onLocationSelected(_locationMap[ann.id]);
  }

  void _onCameraChanged(mapbox.CameraChangedEventData e) {
    final newZoom = e.cameraState.zoom;

    if ((newZoom - _zoom).abs() > 0.4) {
      _zoom = newZoom;

      if (widget.viewMode == MapViewMode.clusters) {
        _renderByMode(force: true);
      }
    }
  }

  Future<void> _onLongTap(mapbox.MapContentGestureContext ctx) async {
    if (_annotationManager == null || mapboxMap == null) return;

    final pos = AppLatLng(
      ctx.point.coordinates.lat.toDouble(),
      ctx.point.coordinates.lng.toDouble(),
    );

    _droppedPin = pos;

    await _renderByMode(force: true);

    widget.onLocationSelected(
      LocationModel(
        name: 'Dropped Pin',
        category: 'temporary',
        position: pos,
        description: 'Dropped pin',
      ),
    );
  }

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
      onLongTapListener: _onLongTap,
    );
  }

  @override
  void dispose() {
    _tapEvents?.cancel();
    super.dispose();
  }
}
