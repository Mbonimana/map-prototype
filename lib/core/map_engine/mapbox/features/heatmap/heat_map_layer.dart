import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;

class HeatmapLayerFactory {
  static mapbox.HeatmapLayer create() {
    return mapbox.HeatmapLayer(
      id: "heatmap-layer",
      sourceId: "heatmap-source",
      heatmapIntensityExpression: [
        "interpolate",
        ["linear"],
        ["zoom"],
        10,
        1.0,
        14,
        2.0,
        17,
        3.0,
      ],
      heatmapRadius: 30,
      heatmapOpacity: 0.9,
      heatmapWeightExpression: [
        "coalesce",
        [
          "to-number",
          ["get", "weight"],
        ],
        0.0,
      ],
      heatmapColorExpression: [
        "interpolate",
        ["linear"],
        ["heatmap-density"],
        0.0,
        "rgba(0,0,0,0)",
        0.2,
        "rgba(0,176,255,0.7)",
        0.4,
        "rgba(0,255,128,0.8)",
        0.6,
        "rgba(255,214,0,0.9)",
        0.8,
        "rgba(255,140,0,0.95)",
        1.0,
        "rgba(255,0,0,1)",
      ],
    );
  }
}
