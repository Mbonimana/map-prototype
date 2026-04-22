import 'dart:convert';

import 'package:map_prototype_app/data/model/location_model.dart';

class HeatmapSourceBuilder {
  static String build(List<LocationModel> markers) {
    final features = markers.map((m) {
      final w = (m.weight ?? 0.0).clamp(0.0, 1.0);

      return {
        "type": "Feature",
        "geometry": {
          "type": "Point",
          "coordinates": [m.position.lng, m.position.lat],
        },
        "properties": {"weight": w},
      };
    }).toList();

    return jsonEncode({"type": "FeatureCollection", "features": features});
  }
}
