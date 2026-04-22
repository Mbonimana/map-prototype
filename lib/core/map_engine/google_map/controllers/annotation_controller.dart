import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:map_prototype_app/core/constants/google_map_constants.dart';
import 'package:map_prototype_app/core/utils/goole_marker_icon_helper.dart';
import 'package:map_prototype_app/data/model/coordinate_model.dart';
import 'package:map_prototype_app/data/model/location_model.dart';

class AnnotationController {
  static Future<Marker> buildMarker({
    required LocationModel location,
    required Function(LocationModel?) onTap,
  }) async {
    final icon = await MarkerIconHelper.getIcon(location.category);

    return Marker(
      markerId: MarkerId(location.name),
      position: LatLng(location.position.lat, location.position.lng),
      icon: icon,
      onTap: () => onTap(location),
    );
  }

  static LocationModel buildDroppedLocation(LatLng position) {
    return LocationModel(
      name: 'Dropped Pin',
      category: 'temporary',
      position: AppLatLng(position.latitude, position.longitude),
      description: 'Temporary pin dropped.',
    );
  }

  static Future<Marker> buildDroppedPinMarker({
    required LatLng position,
    required LocationModel location,
    required Function(LocationModel?) onTap,
  }) async {
    final droppedIcon = await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(40, 40)),
      'assets/icons/user.png',
    );

    return Marker(
      markerId: const MarkerId(GoogleMapConstants.droppedPinId),
      position: position,
      icon: droppedIcon,
      onTap: () => onTap(location),
    );
  }
}
