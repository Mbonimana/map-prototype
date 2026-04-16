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
    final distance = calculate(a, b);

    if (distance < 1) {
      return "${(distance * 1000).toStringAsFixed(0)} m away";
    } else {
      return "${distance.toStringAsFixed(2)} km away";
    }
  }
}
