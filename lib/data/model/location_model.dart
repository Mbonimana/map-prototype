import 'package:map_prototype_app/core/utils/geojson_converter.dart';
import 'package:map_prototype_app/data/model/coordinate_model.dart';

class LocationModel {
  final String name;
  final String category;
  final AppLatLng position;
  final String? description;
  final double? weight;

  LocationModel({
    required this.name,
    required this.category,
    required this.position,
    this.description,
    this.weight = 0.3,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      name: json['properties']['name'],
      category: json['properties']['category'],
      position: GeoJsonConverter.toLatLng(json['geometry']['coordinates']),
      description: json['properties']['description'],
      weight: (json['properties']['weight'] ?? 0.3).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "type": "Feature",
      "properties": {"name": name, "category": category, "weight": weight},
      "geometry": {
        "type": "Point",
        "coordinates": GeoJsonConverter.toGeoJson(position),
      },
    };
  }
}
