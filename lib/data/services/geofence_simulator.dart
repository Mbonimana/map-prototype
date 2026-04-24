import 'package:map_prototype_app/data/services/geofence_service.dart';

class GeofenceSimulator {
  String? _currentZone;

  GeofenceTransition simulateEnter(String zoneName) {
    _currentZone = zoneName;

    return GeofenceTransition(
      zoneName: zoneName,
      type: GeofenceTransitionType.entered,
    );
  }

  GeofenceTransition simulateExit(String zoneName) {
    _currentZone = null;

    return GeofenceTransition(
      zoneName: zoneName,
      type: GeofenceTransitionType.exited,
    );
  }

  GeofenceTransition? get current {
    if (_currentZone == null) return null;

    return GeofenceTransition(
      zoneName: _currentZone!,
      type: GeofenceTransitionType.current,
    );
  }
}
