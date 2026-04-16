import 'package:flutter/material.dart';
import 'package:map_prototype_app/data/model/coordinate_model.dart';
import 'package:map_prototype_app/data/model/location_model.dart';

enum MapStyle { streets, satellite, terrain }

abstract class MapEngine {
  Widget buildMap({
    required List<LocationModel> markers,
    required AppLatLng userLocation,
    required MapStyle style,
  });
}
