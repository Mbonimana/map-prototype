import 'dart:math';

import 'package:map_prototype_app/data/model/coordinate_model.dart';
import 'package:map_prototype_app/data/model/location_model.dart';

class GeofenceService {
  LocationModel? checkInside(
    AppLatLng user,
    List<LocationModel> zones,
    double radiusMeters,
  ) {
    for (final zone in zones) {
      final distance = _distanceBetween(user, zone.position);

      if (distance <= radiusMeters) {
        return zone;
      }
    }
    return null;
  }

  double _distanceBetween(AppLatLng a, AppLatLng b) {
    const earthRadius = 6371000;

    final dLat = _degToRad(b.lat - a.lat);
    final dLng = _degToRad(b.lng - a.lng);

    final lat1 = _degToRad(a.lat);
    final lat2 = _degToRad(b.lat);

    final h =
        (sin(dLat / 2) * sin(dLat / 2)) +
        cos(lat1) * cos(lat2) * (sin(dLng / 2) * sin(dLng / 2));

    final c = 2 * atan2(sqrt(h), sqrt(1 - h));

    return earthRadius * c;
  }

  double _degToRad(double deg) => deg * (3.141592653589793 / 180);
}
