import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;

import 'zone_colors.dart';

class ZoneRenderer {
  static Future<void> render(BuildContext context, mapbox.MapboxMap map) async {
    final geojson = await DefaultAssetBundle.of(
      context,
    ).loadString('assets/mock/zones.geojson');

    final decoded = jsonDecode(geojson);

    for (var feature in decoded['features']) {
      final name = feature['properties']['name'];
      final id = name.toString().toLowerCase().replaceAll(' ', '-');

      try {
        await map.style.addSource(
          mapbox.GeoJsonSource(id: 'src-$id', data: jsonEncode(feature)),
        );

        await map.style.addLayer(
          mapbox.FillLayer(
            id: 'fill-$id',
            sourceId: 'src-$id',
            fillColor: ZoneColors.get(name).value,
            fillOpacity: 0.3,
          ),
        );
      } catch (_) {
        // ignore duplicates / style reload conflicts
      }
    }
  }
}
