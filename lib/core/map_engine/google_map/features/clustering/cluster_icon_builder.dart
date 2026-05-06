import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:map_prototype_app/core/constants/google_map_colors.dart';

class ClusterIconBuilder {
  static Future<Uint8List> build(int count) async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);

    const size = Size(100, 100);
    const center = Offset(50, 50);

    final paint = Paint()..color = GoogleMapColors.clusterColor(count);
    final radius = GoogleMapColors.clusterRadius(count);

    canvas.drawCircle(center, radius, paint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: '$count',
        style: const TextStyle(
          fontSize: 26,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );

    final image = await recorder.endRecording().toImage(
      size.width.toInt(),
      size.height.toInt(),
    );

    final data = await image.toByteData(format: ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }
}
