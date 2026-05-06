import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:map_prototype_app/core/constants/google_map_constants.dart';
import 'package:map_prototype_app/data/model/coordinate_model.dart';

class CameraController {
  final GoogleMapController controller;
  final AppLatLng userLocation;

  CameraController(this.controller, this.userLocation);

  void flyToKigali() {
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        const CameraPosition(
          target: GoogleMapConstants.kigaliLocation,
          zoom: 15,
        ),
      ),
    );
  }

  void tiltCamera() {
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(userLocation.lat, userLocation.lng),
          zoom: 15,
          tilt: 60,
          bearing: 45,
        ),
      ),
    );
  }

  void resetCamera() {
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(userLocation.lat, userLocation.lng),
          zoom: GoogleMapConstants.defaultZoom,
        ),
      ),
    );
  }

  void flyToZone(AppLatLng pos) {
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(pos.lat, pos.lng), zoom: 15),
      ),
    );
  }

  void goToUserLocation() {
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(userLocation.lat, userLocation.lng),
          zoom: 15,
        ),
      ),
    );
  }
}
