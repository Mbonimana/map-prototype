import 'package:flutter/material.dart';

class AssetLoader {
  static Future<String> loadString(BuildContext context, String assetPath) {
    return DefaultAssetBundle.of(context).loadString(assetPath);
  }
}
