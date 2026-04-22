import 'dart:typed_data';

import 'package:flutter/material.dart';

class AssetLoader {
  static Future<Uint8List> load(BuildContext context, String path) async {
    final data = await DefaultAssetBundle.of(context).load(path);
    return data.buffer.asUint8List();
  }
}
