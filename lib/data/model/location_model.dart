import 'package:map_prototype_app/core/utils/geojson_converter.dart';
import 'package:map_prototype_app/data/model/coordinate_model.dart';

class LocationModel {
  final String name;
  final String category;
  final AppLatLng position;
  final String? description;

  LocationModel({
    required this.name,
    required this.category,
    required this.position,
    this.description,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      name: json['properties']['name'],
      category: json['properties']['category'],
      position: GeoJsonConverter.toLatLng(json['geometry']['coordinates']),
      description: json['properties']['description'],
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
