import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:map_prototype_app/core/constants/google_map_constants.dart';
import 'package:map_prototype_app/data/model/location_model.dart';
import 'package:map_prototype_app/presentation/providers/heatmap_tile_provider.dart';

class HeatmapSource {
  static TileOverlay build(List<LocationModel> markers) {
    final provider = AdvancedHeatmapTileProvider(
      locations: markers,
      baseKernelSize: GoogleMapConstants.heatmapKernelSize,
      intensity: GoogleMapConstants.heatmapIntensity,
    );

    return TileOverlay(
      tileOverlayId: const TileOverlayId(GoogleMapConstants.heatmapOverlayId),
      tileProvider: provider,
      transparency: GoogleMapConstants.heatmapTransparency,
      fadeIn: true,
    );
  }
}
