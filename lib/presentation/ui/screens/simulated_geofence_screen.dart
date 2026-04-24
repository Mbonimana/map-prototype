import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'package:map_prototype_app/core/map_engine/map_engine.dart';
import 'package:map_prototype_app/data/model/coordinate_model.dart';
import 'package:map_prototype_app/data/model/zone_model.dart';
import 'package:map_prototype_app/data/services/geofence_service.dart';
import 'package:map_prototype_app/data/services/location_service.dart';
import 'package:map_prototype_app/presentation/ui/widgets/zone_toaster.dart';

class GeofenceSimulationScreen extends StatefulWidget {
  final MapEngine engine;

  const GeofenceSimulationScreen({super.key, required this.engine});

  @override
  State<GeofenceSimulationScreen> createState() =>
      _GeofenceSimulationScreenState();
}

class _GeofenceSimulationScreenState extends State<GeofenceSimulationScreen> {
  final GeofenceService _service = GeofenceService();

  List<ZoneModel> _zones = [];

  String? _message;
  ZoneUiState? _state;

  StreamSubscription<Position>? _sub;

  AppLatLng? _userLocation;

  bool _isSimulating = false;
  String? _activeZone;

  final Map<String, bool> _insideZone = {};

  @override
  void initState() {
    super.initState();
    _loadZones();
    _listenUserLocation();
  }

  void _listenUserLocation() {
    _sub = LocationService.getPositionStream().listen((pos) {
      if (_isSimulating) return;

      _userLocation = AppLatLng(pos.latitude, pos.longitude);
      _updateZoneStatus();
    });
  }

  void _updateZoneStatus() {
    if (_userLocation == null) return;

    for (final zone in _zones) {
      final center = _center(zone);

      final distance = Geolocator.distanceBetween(
        _userLocation!.lat,
        _userLocation!.lng,
        center.lat,
        center.lng,
      );

      _insideZone[zone.name] = distance < 80;
    }

    if (mounted) setState(() {});
  }

  Future<void> _loadZones() async {
    final zones = await _service.loadZones();
    if (!mounted) return;

    setState(() => _zones = zones);
  }

  // Calculate zone center 
  AppLatLng _center(ZoneModel zone) {
    double lat = 0;
    double lng = 0;

    for (final p in zone.polygon) {
      lat += p.lat;
      lng += p.lng;
    }

    return AppLatLng(lat / zone.polygon.length, lng / zone.polygon.length);
  }


  void _enterZone(ZoneModel zone) {
    final c = _center(zone);

    _isSimulating = true;
    _activeZone = zone.name;

    _userLocation = c;

    widget.engine.flyToZone(c);

    LocationService.injectSimulation(lat: c.lat, lng: c.lng);

    _insideZone[zone.name] = true;

    _toast(" You have Entered ${zone.name} zone", ZoneUiState.entered);

    setState(() {});
  }


  Future<void> _leaveZone(ZoneModel zone) async {
    final real = await LocationService.getCurrentLocation();

    _isSimulating = false;
    _activeZone = null;

    _userLocation = AppLatLng(real.latitude, real.longitude);

    widget.engine.flyToZone(_userLocation!);

    LocationService.injectSimulation(lat: real.latitude, lng: real.longitude);

    _insideZone[zone.name] = false;

    _toast(" You have Left ${zone.name} zone", ZoneUiState.exited);

    setState(() {});
  }

  void _toast(String msg, ZoneUiState state) {
    setState(() {
      _message = msg;
      _state = state;
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.blue),
        title: const Text(
          "Geofence Simulator",
          style: TextStyle(color: Colors.blue),
        ),
        centerTitle: true,
      ),

      body: Stack(
        children: [
          /// MAP
          widget.engine.buildMap(
            markers: const [],
            userLocation: _userLocation ?? const AppLatLng(-1.9441, 30.0619),
            style: MapStyle.streets,
            viewMode: MapViewMode.pins,
            onLocationSelected: (_) {},
          ),

          /// CONTROL PANEL
          Positioned(
            left: 10,
            bottom: 20,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200, maxWidth: 260),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(250),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(20),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _zones.isEmpty
                    ? const SizedBox(
                        height: 100,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(10),
                        itemCount: _zones.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 2),
                        itemBuilder: (context, index) {
                          final zone = _zones[index];

                          final inside = _insideZone[zone.name] ?? false;
                          final isActive = _activeZone == zone.name;

                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    zone.name,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),

                                _miniButton(
                                  label: "Enter",
                                  color: Colors.blue,
                                  onTap: () => _enterZone(zone),
                                ),

                                const SizedBox(width: 6),

                                _miniButton(
                                  label: "Leave",
                                  color: (inside && isActive)
                                      ? Colors.red
                                      : Colors.grey,
                                  onTap: (inside && isActive)
                                      ? () => _leaveZone(zone)
                                      : null,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),
          ),

          //toaster
          Positioned(
            top: 60,
            left: 16,
            right: 16,
            child: ZoneToaster(
              message: _message,
              state: _state ?? ZoneUiState.inside,
            ),
          ),
        ],
      ),
    );
  }

  
  Widget _miniButton({
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    final enabled = onTap != null;

    return Material(
      color: enabled ? color.withAlpha(25) : Colors.grey.shade200,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: enabled ? color : Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
