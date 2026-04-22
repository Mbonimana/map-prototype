import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:map_prototype_app/core/map_engine/google_map/features/zones/zone_colors.dart';
import 'package:map_prototype_app/core/map_engine/google_map/utils/asset_loader.dart';

class ZoneRenderer {
  static Future<Set<Polygon>> render(BuildContext context) async {
    final jsonString = await AssetLoader.loadString(
      context,
      GoogleMapZoneAssets.zones,
    );

    final data = jsonDecode(jsonString);
    final List features = data['features'];

    final Set<Polygon> polygons = {};

    for (final feature in features) {
      final name = feature['properties']['name'];
      final coords = feature['geometry']['coordinates'][0];

      final points = coords.map<LatLng>((c) => LatLng(c[1], c[0])).toList();

      polygons.add(
        Polygon(
          polygonId: PolygonId(name),
          points: points,
          strokeWidth: 0,
          fillColor: ZoneColors.get(name).withAlpha(75),
        ),
      );
    }

    return polygons;
  }
}

class GoogleMapZoneAssets {
  static const String zones = 'assets/mock/zones.geojson';
}
