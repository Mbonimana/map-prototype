import 'package:flutter/material.dart';
import 'package:map_prototype_app/core/map/map_box_view.dart';
import 'package:map_prototype_app/core/map/map_engine.dart';
import 'package:map_prototype_app/data/model/coordinate_model.dart';
import 'package:map_prototype_app/data/model/location_model.dart';

class MapboxMapEngine implements MapEngine {
  MapboxViewState? _state;

  @override
  Widget buildMap({
    required List<LocationModel> markers,
    required AppLatLng userLocation,
    required MapStyle style,
    required MapViewMode viewMode,
    required Function(LocationModel?) onLocationSelected,
  }) {
    return MapboxView(
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
  void flyToKigali() => _state?.camera.flyToKigali();

  @override
  void tiltCamera() => _state?.camera.tiltToUser();

  @override
  void resetCamera() => _state?.camera.resetToUser();

  @override
  void goToUserLocation() => _state?.camera.goToUser();
}
