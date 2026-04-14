import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:map_prototype_app/data/model/location_model.dart';

enum MapStyle { streets, satellite, terrain }

abstract class MapEngine {
  Widget buildMap({
    required List<LocationModel> markers,
    required LatLng userLocation,
    required MapStyle style,
  });
}
