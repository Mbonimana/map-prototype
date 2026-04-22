import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;

class StyleCleaner {
  static Future<void> hideAllLabels(mapbox.MapboxMap map) async {
    final layers = await map.style.getStyleLayers();

    for (final layer in layers) {
      if (layer?.type == 'symbol') {
        try {
          await map.style.setStyleLayerProperty(
            layer!.id,
            'visibility',
            'none',
          );
        } catch (_) {
          // ignore style protection errors
        }
      }
    }
  }
}
