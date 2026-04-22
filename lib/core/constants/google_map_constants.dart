import 'package:google_maps_flutter/google_maps_flutter.dart';

class GoogleMapConstants {
  static const double defaultZoom = 13;
  static const double clusterZoomDelta = 0.3;
  static const double clusterZoomIn = 2;
  static const double heatmapKernelSize = 60;
  static const double heatmapIntensity = 1.3;
  static const double heatmapTransparency = 0.2;
  static const String heatmapOverlayId = 'heatmap_layer';
  static const String droppedPinId = '__user_dropped_pin__';
  static const LatLng kigaliLocation = LatLng(-1.9441, 30.0619);

  static const String noLabelsStyle =
      '[{"featureType": "poi","stylers":[{"visibility":"off"}]},'
      '{"featureType":"transit","stylers":[{"visibility":"off"}]},'
      '{"featureType":"road","elementType":"labels","stylers":[{"visibility":"off"}]},'
      '{"featureType":"administrative","elementType":"labels","stylers":[{"visibility":"off"}]}]';
}
