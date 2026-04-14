import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MarkerIconHelper {
  static Future<BitmapDescriptor> getIcon(String category) async {
    switch (category) {
      case "landmark":
        return await BitmapDescriptor.asset(
          const ImageConfiguration(size: Size(22, 22)),
          "assets/icons/landmark.png",
        );

      case "business":
        return await BitmapDescriptor.asset(
          const ImageConfiguration(size: Size(22, 22)),
          "assets/icons/business.png",
        );

      case "service":
        return await BitmapDescriptor.asset(
          const ImageConfiguration(size: Size(22, 22)),
          "assets/icons/service.png",
        );

      default:
        return BitmapDescriptor.defaultMarker;
    }
  }
}
