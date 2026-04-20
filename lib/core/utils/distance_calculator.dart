import 'package:latlong2/latlong.dart';
import 'package:map_prototype_app/data/model/coordinate_model.dart';

class DistanceCalculator {
  final Distance _distance = const Distance();

  /// Calculates distance between two points using using coordinates
  double calculate(AppLatLng a, AppLatLng b) {
    return _distance.as(
      LengthUnit.Kilometer,
      LatLng(a.lat, a.lng),
      LatLng(b.lat, b.lng),
    );
  }

  // formatted string
  String format(AppLatLng a, AppLatLng b) {
    final meters = _distance.as(
      LengthUnit.Meter,
      LatLng(a.lat, a.lng),
      LatLng(b.lat, b.lng),
    );

    if (meters < 1000) {
      final display = meters < 1 ? 1 : meters.round();
      return "$display m away";
    } else {
      final km = meters / 1000;
      return "${km.toStringAsFixed(2)} km away";
    }
  }
}
