import 'package:map_prototype_app/data/model/coordinate_model.dart';

class GeoJsonConverter {
  // GeoJSON → AppLatLng
  static AppLatLng toLatLng(List coordinates) {
    final double lng = coordinates[0];
    final double lat = coordinates[1];

    return AppLatLng(lat, lng);
  }

  // AppLatLng → GeoJSON
  static List<double> toGeoJson(AppLatLng point) {
    return [point.lng, point.lat];
  }

  static AppLatLng fromLat(double lat, double lng) {
    return AppLatLng(lat, lng);
  }
}
