// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;

class RouteRenderer {
  static Future<void> render(BuildContext context, mapbox.MapboxMap map) async {
    final geojson = await DefaultAssetBundle.of(
      context,
    ).loadString('assets/mock/routes.geojson');

    try {
      //source of file
      await map.style.addSource(
        mapbox.GeoJsonSource(id: "route-src", data: geojson),
      );

      await map.style.addLayer(
        mapbox.LineLayer(
          id: "route-layer",
          sourceId: "route-src",
          filter: [
            "==",
            ["geometry-type"],
            "LineString",
          ],
          lineColor: Colors.blue.value,
          lineWidth: 2.0,
          lineJoin: mapbox.LineJoin.ROUND,
          lineCap: mapbox.LineCap.ROUND,
        ),
      );

      await map.style.addLayer(
        mapbox.SymbolLayer(
          id: "stop-labels-layer",
          sourceId: "route-src",
          filter: [
            "==",
            ["geometry-type"],
            "Point",
          ],
          textField: "{name}",
          textSize: 12.0,
          textColor: Colors.black.value,
          textHaloColor: Colors.white.value,
          textHaloWidth: 1.0,
          textOffset: [0, 1.2],
          textAnchor: mapbox.TextAnchor.TOP,
        ),
      );

      // stop labels
      await map.style.addLayer(
        mapbox.CircleLayer(
          id: "stop-dots-layer",
          sourceId: "route-src",
          filter: [
            "==",
            ["geometry-type"],
            "Point",
          ],
          circleRadius: 4.0,
          circleColor: Colors.white.value,
          circleStrokeWidth: 1.0,
          circleStrokeColor: Colors.blue.value,
        ),
      );
    } catch (e) {
      debugPrint("Error loading map layers: $e");
    }
  }
}
