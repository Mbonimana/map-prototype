import 'package:map_prototype_app/data/model/coordinate_model.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;

class CameraController {
  final mapbox.MapboxMap map;
  final AppLatLng userLocation;

  CameraController(this.map, this.userLocation);

  void flyToKigali() {
    map.flyTo(
      mapbox.CameraOptions(
        center: mapbox.Point(coordinates: mapbox.Position(30.0619, -1.9441)),
        zoom: 15,
      ),
      mapbox.MapAnimationOptions(duration: 2000),
    );
  }

  void tiltToUser() {
    map.flyTo(
      mapbox.CameraOptions(
        center: mapbox.Point(
          coordinates: mapbox.Position(userLocation.lng, userLocation.lat),
        ),
        zoom: 15,
        pitch: 60,
        bearing: 45,
      ),
      mapbox.MapAnimationOptions(duration: 2000),
    );
  }

  void resetToUser() {
    map.flyTo(
      mapbox.CameraOptions(
        center: mapbox.Point(
          coordinates: mapbox.Position(userLocation.lng, userLocation.lat),
        ),
        zoom: 13,
        pitch: 0,
        bearing: 0,
      ),
      mapbox.MapAnimationOptions(duration: 1500),
    );
  }

  void goToUser() {
    map.flyTo(
      mapbox.CameraOptions(
        center: mapbox.Point(
          coordinates: mapbox.Position(userLocation.lng, userLocation.lat),
        ),
        zoom: 15,
      ),
      mapbox.MapAnimationOptions(duration: 1000),
    );
  }

  void flyToPosition(AppLatLng pos) {
    map.flyTo(
      mapbox.CameraOptions(
        center: mapbox.Point(coordinates: mapbox.Position(pos.lng, pos.lat)),
        zoom: 15,
      ),
      mapbox.MapAnimationOptions(duration: 800),
    );
  }
}
