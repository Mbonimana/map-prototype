import 'package:map_prototype_app/core/utils/geojson_converter.dart';
import 'package:map_prototype_app/data/model/coordinate_model.dart';

class LocationModel {
  final String name;
  final String category;
  final AppLatLng position;

  LocationModel({
    required this.name,
    required this.category,
    required this.position,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      name: json['properties']['name'],
      category: json['properties']['category'],
      position: GeoJsonConverter.toLatLng(json['geometry']['coordinates']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "type": "Feature",
      "properties": {"name": name, "category": category},
      "geometry": {
        "type": "Point",
        "coordinates": GeoJsonConverter.toGeoJson(position),
      },
    };
  }
}
