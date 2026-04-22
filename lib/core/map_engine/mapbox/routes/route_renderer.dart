import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;

class RouteRenderer {
  static Future<void> render(BuildContext context, mapbox.MapboxMap map) async {
    final geojson = await DefaultAssetBundle.of(
      context,
    ).loadString('assets/mock/routes.geojson');

    try {
      await map.style.addSource(
        mapbox.GeoJsonSource(id: "route-src", data: geojson),
      );

      await map.style.addLayer(
        mapbox.LineLayer(
          id: "route-layer",
          sourceId: "route-src",
          lineColor: Colors.blue.value,
          lineWidth: 3.0,
        ),
      );
    } catch (_) {
      // ignore if already added
    }
  }
}
