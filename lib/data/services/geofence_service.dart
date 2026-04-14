import 'package:geolocator/geolocator.dart';
import 'package:map_prototype_app/data/model/location_model.dart';

class GeofenceService {
  LocationModel? checkInside(
    Position user,
    List<LocationModel> zones,
    double radiusMeters,
  ) {
    for (final zone in zones) {
      final distance = Geolocator.distanceBetween(
        user.latitude,
        user.longitude,
        zone.position.latitude,
        zone.position.longitude,
      );

      if (distance <= radiusMeters) {
        return zone;
      }
    }
    return null;
  }
}
