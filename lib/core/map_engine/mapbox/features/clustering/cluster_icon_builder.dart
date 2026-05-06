import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';

class ClusterIconBuilder {
  static Future<Uint8List> build(int count) async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);

    const center = Offset(50, 50);

    final paint = Paint()
      ..color = count <= 3
          ? Colors.blue
          : count <= 10
          ? Colors.orange
          : Colors.red;

    final radius = count <= 3
        ? 28.0
        : count <= 10
        ? 36.0
        : 44.0;

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

    final img = await recorder.endRecording().toImage(100, 100);
    final data = await img.toByteData(format: ImageByteFormat.png);

    return data!.buffer.asUint8List();
  }
}
