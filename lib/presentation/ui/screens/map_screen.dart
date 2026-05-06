import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:map_prototype_app/core/map_engine/map_engine.dart';
import 'package:map_prototype_app/data/model/coordinate_model.dart';
import 'package:map_prototype_app/data/model/location_model.dart';
import 'package:map_prototype_app/data/model/zone_model.dart';
import 'package:map_prototype_app/data/services/geofence_service.dart';
import 'package:map_prototype_app/data/services/location_service.dart';
import 'package:map_prototype_app/presentation/ui/screens/offline_maps_settings_screen.dart';
import 'package:map_prototype_app/presentation/ui/screens/simulated_geofence_screen.dart';
import 'package:map_prototype_app/presentation/ui/widgets/location_bottom_panel.dart';
import 'package:map_prototype_app/presentation/ui/widgets/map_control_panel.dart';
import 'package:map_prototype_app/presentation/ui/widgets/map_view_mode_toggle.dart';
import 'package:map_prototype_app/presentation/ui/widgets/style_rail.dart';
import 'package:map_prototype_app/presentation/ui/widgets/zone_toaster.dart';

class MapScreen extends StatefulWidget {
  final MapEngine engine;
  final List<LocationModel> locations
  final AppLatLng startPostion;
  final bool isMapboxEngine;

  const MapScreen({
    super.key,
    required this.engine,
    required this.locations,
    required this.startPostion,
    required this.isMapboxEngine,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  MapStyle style = MapStyle.streets;
  LocationModel? _selectedLocation;
  MapViewMode viewMode = MapViewMode.pins;

  final GeofenceService _geofenceService = GeofenceService();
  final List<ZoneModel> _zones = [];

  StreamSubscription<Position>? _positionSubscription;

  String? _zoneMessage;
  ZoneUiState _zoneState = ZoneUiState.inside;

  @override
  void initState() {
    super.initState();
    _bootstrapGeofencing();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _bootstrapGeofencing() async {
    final zones = await _geofenceService.loadZones();

    if (!mounted) return;

    _zones
      ..clear()
      ..addAll(zones);

    _geofenceService.seedState(position: widget.startPostion, zones: _zones);

    _positionSubscription = LocationService.getPositionStream().listen((
      position,
    ) {
      final transition = _geofenceService.evaluatePosition(
        position: AppLatLng(position.latitude, position.longitude),
        zones: _zones,
      );

      if (transition != null) {
        _showZoneToast(transition);
      }
    });
  }

  void _showZoneToast(GeofenceTransition transition) {
    if (!mounted) return;

    setState(() {
      _zoneMessage = transition.message;
      _zoneState = switch (transition.type) {
        GeofenceTransitionType.entered => ZoneUiState.entered,
        GeofenceTransitionType.exited => ZoneUiState.exited,
        GeofenceTransitionType.current => ZoneUiState.inside,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// MAP
          widget.engine.buildMap(
            markers: widget.locations,
            userLocation: widget.startPostion,
            style: style,
            viewMode: viewMode,
            onLocationSelected: (loc) =>
                setState(() => _selectedLocation = loc),
          ),

          //style selector
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: StyleLayerSelector(
              selected: style,
              onChanged: (s) => setState(() => style = s),
            ),
          ),

          // zone toaster
          Positioned(
            top: 100,
            left: 16,
            right: 16,
            child: ZoneToaster(message: _zoneMessage, state: _zoneState),
          ),

          // setting button
          Positioned(
            top: 120,
            right: 12,
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              elevation: 3,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => OfflineMapsSettingsScreen(
                        isMapboxEngine: widget.isMapboxEngine,
                      ),
                    ),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(Icons.settings, color: Colors.blue),
                ),
              ),
            ),
          ),
          Positioned(
            top: 120,
            left: 12,
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              elevation: 3,
              child: IconButton(
                icon: const Icon(Icons.golf_course, color: Colors.blue),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          GeofenceSimulationScreen(engine: widget.engine),
                    ),
                  );
                },
              ),
            ),
          ),

          //camera controlls
          Positioned(
            bottom: 120,
            right: 10,
            child: MapControlsPanel(
              onFly: widget.engine.flyToKigali,
              onTilt: widget.engine.tiltCamera,
              onReset: widget.engine.resetCamera,
              onLocation: widget.engine.goToUserLocation,
            ),
          ),

          /// LOCATION PANEL
          AnimatedPositioned(
            duration:  Duration(milliseconds: 280),
            curve: Curves.easeInOut,
            left: 0,
            right: 0,
            bottom: _selectedLocation != null ? 0 : -300,
            child: _selectedLocation == null
                ? const SizedBox.shrink()
                : LocationBottomPanel(
                    location: _selectedLocation!,
                    userLocation: widget.startPostion,
                    onClose: () => setState(() => _selectedLocation = null),
                  ),
          ),

          /// VIEW MODE
          Positioned(
            top: 650,
            right: 10,
            child: MapViewModeToggle(
              selected: viewMode,
              onChanged: (mode) {
                setState(() {
                  viewMode = mode;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}

/*
Nyamirambo:  Enter(button), Leave(button),
Kimihurura: Enter(button), Leave(button)
Remera: Enter(button), Leave(button)
RwBuild: Enter(button), Leave(button)
Kigali Downtown: Enter(button), Leave(button)



*/
