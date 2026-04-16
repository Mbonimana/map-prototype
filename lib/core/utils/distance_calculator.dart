import 'dart:math';

import 'package:map_prototype_app/data/model/coordinate_model.dart';

class DistanceCalculator {
  static const double _earthRadiusKm = 6371;

  /// Calculates distance between two points using Haversine formula
  static double calculate(AppLatLng a, AppLatLng b) {
    final dLat = _degToRad(b.lat - a.lat);
    final dLng = _degToRad(b.lng - a.lng);

    final lat1 = _degToRad(a.lat);
    final lat2 = _degToRad(b.lat);

    final h =
        pow(sin(dLat / 2), 2) + cos(lat1) * cos(lat2) * pow(sin(dLng / 2), 2);

    final c = 2 * atan2(sqrt(h), sqrt(1 - h));

    return _earthRadiusKm * c;
  }

  /// Optional: formatted string (clean UI usage)
  static String format(AppLatLng a, AppLatLng b) {
    final distance = calculate(a, b);

    if (distance < 1) {
      return "${(distance * 1000).toStringAsFixed(0)} m away";
    } else {
      return "${distance.toStringAsFixed(2)} km away";
    }
  }

  static double _degToRad(double deg) => deg * (pi / 180);
}
