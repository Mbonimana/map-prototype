import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:map_prototype_app/data/model/coordinate_model.dart';
import 'package:map_prototype_app/data/model/zone_model.dart';

class GeofenceService {
  Set<String> _insideZoneNames = {};

  Future<List<ZoneModel>> loadZones({
    String assetPath = 'assets/mock/zones.geojson',
  }) async {
    final jsonString = await rootBundle.loadString(assetPath);
    final data = jsonDecode(jsonString);
    final features = data['features'] as List;

    return features
        .cast<Map<String, dynamic>>()
        .map(ZoneModel.fromGeoJsonFeature)
        .toList();
  }

  void seedState({
    required AppLatLng position,
    required List<ZoneModel> zones,
  }) {
    _insideZoneNames = _insideZones(position: position, zones: zones);
  }

  GeofenceTransition? evaluatePosition({
    required AppLatLng position,
    required List<ZoneModel> zones,
  }) {
    final currentInside = _insideZones(position: position, zones: zones);

    final entered = currentInside.difference(_insideZoneNames);
    final exited = _insideZoneNames.difference(currentInside);

    _insideZoneNames = currentInside;

    if (entered.isNotEmpty) {
      return GeofenceTransition(
        zoneName: entered.first,
        type: GeofenceTransitionType.entered,
      );
    }

    if (exited.isNotEmpty) {
      return GeofenceTransition(
        zoneName: exited.first,
        type: GeofenceTransitionType.exited,
      );
    }
     if (currentInside.isNotEmpty) {
    return GeofenceTransition(
      zoneName: currentInside.first,
      type: GeofenceTransitionType.current,
    );
  }

    return null;
  }

  Set<String> _insideZones({
    required AppLatLng position,
    required List<ZoneModel> zones,
  }) {
    return zones
        .where((zone) => _isPointInPolygon(position, zone.polygon))
        .map((zone) => zone.name)
        .toSet();
  }

  bool _isPointInPolygon(AppLatLng point, List<AppLatLng> polygon) {
    bool inside = false;

    for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      final xi = polygon[i].lng;
      final yi = polygon[i].lat;
      final xj = polygon[j].lng;
      final yj = polygon[j].lat;

      final intersect =
          ((yi > point.lat) != (yj > point.lat)) &&
          (point.lng < (xj - xi) * (point.lat - yi) / (yj - yi) + xi);

      if (intersect) inside = !inside;
    }

    return inside;
  }
}

enum GeofenceTransitionType { entered, exited, current }

class GeofenceTransition {
  final String zoneName;
  final GeofenceTransitionType type;

  GeofenceTransition({required this.zoneName, required this.type});

  String get message {
    switch (type) {
      case GeofenceTransitionType.entered:
        return 'You entered $zoneName zone';
      case GeofenceTransitionType.exited:
        return 'You left $zoneName zone';
      case GeofenceTransitionType.current:
        return 'You are in $zoneName zone';
    }
  }
}
