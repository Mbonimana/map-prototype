import 'dart:async';
import 'package:geolocator/geolocator.dart';

class LocationService {
  static final StreamController<Position> _controller =
      StreamController<Position>.broadcast();

  static StreamSubscription<Position>? _gpsSubscription;

  //real GPS stream
  static Future<void> start() async {
    final position = await getCurrentLocation();
    _controller.add(position);

    _gpsSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 1,
          ),
        ).listen((pos) {
          _controller.add(pos);
        });
  }

  // Unified stream (REAL + SIMULATION)
  static Stream<Position> getPositionStream() => _controller.stream;


  static Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception("Location services are disabled");
    }

    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception("Location permission denied");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception("Location permission permanently denied");
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  //simulated location
  static void injectSimulation({required double lat, required double lng}) {
    _controller.add(
      Position(
        latitude: lat,
        longitude: lng,
        timestamp: DateTime.now(),
        accuracy: 5,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      ),
    );
  }

  //Cleanup
  static Future<void> dispose() async {
    await _gpsSubscription?.cancel();
    await _controller.close();
  }
}
