import 'package:flutter/material.dart';
import 'package:map_prototype_app/core/map_engine/google_map/googlemap_view.dart';
import 'package:map_prototype_app/core/map_engine/map_engine.dart';
import 'package:map_prototype_app/data/model/coordinate_model.dart';
import 'package:map_prototype_app/data/model/location_model.dart';

class GoogleMapEngine implements MapEngine {
  GoogleMapViewState? _state;

  @override
  Widget buildMap({
    required List<LocationModel> markers,
    required AppLatLng userLocation,
    required MapStyle style,
    required MapViewMode viewMode,
    required Function(LocationModel?) onLocationSelected,
  }) {
    return GoogleMapView(
      key: ValueKey('$style-$viewMode'),
      markers: markers,
      userLocation: userLocation,
      style: style,
      viewMode: viewMode,
      onLocationSelected: onLocationSelected,
      onCreated: (state) => _state = state,
    );
  }

  @override
  void flyToKigali() => _state?.flyToKigali();

  @override
  void tiltCamera() => _state?.tiltCamera();

  @override
  void resetCamera() => _state?.resetCamera();

  @override
  void goToUserLocation() => _state?.goToUserLocation();
}
