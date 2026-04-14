import 'package:geolocator/geolocator.dart';

class LocationService {
  Stream<Position> get stream => Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      );

  Future<Position> getCurrent() async {
    return await Geolocator.getCurrentPosition();
  }
}