import 'package:map_prototype_app/data/model/coordinate_model.dart';

class ZoneModel {
  final String name;
  final String category;
  final List<AppLatLng> polygon;

  ZoneModel({
    required this.name,
    required this.category,
    required this.polygon,
  });

  factory ZoneModel.fromGeoJsonFeature(Map<String, dynamic> feature) {
    final properties = feature['properties'] as Map<String, dynamic>;
    final geometry = feature['geometry'] as Map<String, dynamic>;
    final coordinates = geometry['coordinates'] as List<dynamic>;
    final outerRing = coordinates.first as List<dynamic>;

    final polygon = outerRing.map((point) {
      final pair = point as List<dynamic>;
      return AppLatLng(
        (pair[1] as num).toDouble(),
        (pair[0] as num).toDouble(),
      );
    }).toList();

    return ZoneModel(
      name: (properties['name'] ?? 'Unknown zone').toString(),
      category: (properties['category'] ?? 'zone').toString(),
      polygon: polygon,
    );
  }
}
