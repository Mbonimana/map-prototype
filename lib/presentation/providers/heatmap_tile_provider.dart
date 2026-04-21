import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:map_prototype_app/data/model/location_model.dart';

class AdvancedHeatmapTileProvider implements TileProvider {
  final List<LocationModel> locations;

  /// Kernel size in pixels at zoom 0 (scaled later)
  final double baseKernelSize;

  /// Strength multiplier
  final double intensity;

  AdvancedHeatmapTileProvider({
    required this.locations,
    this.baseKernelSize = 100,
    this.intensity = 2.5,
  });

  static const int tileSize = 256;

  /// TILE RENDER

  @override
  Future<Tile> getTile(int x, int y, int? zoom) async {
    if (zoom == null) return TileProvider.noTile;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // density grid
    const int gridSize = 128;

    final heatGrid = List.generate(gridSize, (_) => List.filled(gridSize, 0.0));

    final scale = math.pow(2, zoom).toDouble();

    final kernel = _kernelRadius(zoom);

    // 1. PROJECT POINTS INTO TILE SPACE

    for (final p in locations) {
      final w = (p.weight ?? 0.3) * intensity;

      final world = _toWorld(p, scale);

      final dx = (world.dx - x) * tileSize;
      final dy = (world.dy - y) * tileSize;

      if (dx < -kernel ||
          dy < -kernel ||
          dx > tileSize + kernel ||
          dy > tileSize + kernel) {
        continue;
      }

      // 2. SPLAT GAUSSIAN KERNEL INTO GRID

      final gx = ((dx / tileSize) * gridSize).round();
      final gy = ((dy / tileSize) * gridSize).round();

      for (int i = -10; i <= 10; i++) {
        for (int j = -10; j <= 10; j++) {
          final ix = gx + i;
          final iy = gy + j;

          if (ix < 0 || iy < 0 || ix >= gridSize || iy >= gridSize) continue;

          final dist = math.sqrt(i * i + j * j);
          final influence = math.exp(-(dist * dist) / 28);

          heatGrid[iy][ix] += w * influence;
        }
      }
    }

    // 3. RENDER HEAT FIELD

    final paint = Paint();

    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        final value = heatGrid[y][x];

        if (value < 0.01) continue;

        final color = _colorRamp(value);

        final rect = Rect.fromLTWH(
          x * (tileSize / gridSize),
          y * (tileSize / gridSize),
          tileSize / gridSize,
          tileSize / gridSize,
        );

        paint.color = color;

        canvas.drawRect(rect, paint);
      }
    }

    final image = await recorder.endRecording().toImage(tileSize, tileSize);

    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    return Tile(tileSize, tileSize, bytes!.buffer.asUint8List());
  }

  /// WORLD PROJECTION (SAME AS MAPBOX)

  Offset _toWorld(LocationModel p, double scale) {
    final x = ((p.position.lng + 180) / 360) * scale;

    final latRad = p.position.lat * math.pi / 180;

    final y =
        (1 - math.log(math.tan(latRad) + 1 / math.cos(latRad)) / math.pi) /
        2 *
        scale;

    return Offset(x, y);
  }

  /// KERNEL SIZE (ZOOM RESPONSIVE)

  double _kernelRadius(int zoom) {
    return (baseKernelSize * math.pow(1.6, zoom - 10))
        .clamp(20, 180)
        .toDouble();
  }

  ///  COLOR RAMP

  Color _colorRamp(double v) {
    // normalize curve (important for realism)
    final t = v.clamp(0.0, 1.0);

    if (t < 0.2) {
      return Color.lerp(
        Colors.transparent,
        Colors.blue.withAlpha(100),
        t / 0.2,
      )!;
    }

    if (t < 0.4) {
      return Color.lerp(
        Colors.blue.withAlpha(100),
        Colors.green.withAlpha(128),
        (t - 0.2) / 0.2,
      )!;
    }

    if (t < 0.7) {
      return Color.lerp(
        Colors.green.withAlpha(128),
        Colors.orange.withAlpha(179),
        (t - 0.4) / 0.3,
      )!;
    }

    return Color.lerp(
      Colors.orange.withAlpha(179),
      Colors.red.withAlpha(230),
      (t - 0.7) / 0.3,
    )!;
  }
}
