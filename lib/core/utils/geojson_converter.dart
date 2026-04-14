import 'package:google_maps_flutter/google_maps_flutter.dart';

class GeoJsonConverter {
  // GeoJSON → Flutter
  static LatLng toLatLng(List coordinates) {
    final double lng = coordinates[0];
    final double lat = coordinates[1];
    return LatLng(lat, lng);
  }

  // Flutter → GeoJSON
  static List<double> toGeoJson(LatLng point) {
    return [point.longitude, point.latitude];
  }

  static LatLng fromLat(double lat, double lng) {
    return LatLng(lat, lng);
  }
}
