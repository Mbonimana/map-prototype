import 'package:flutter/material.dart';

class ZoneColors {
  static Color get(String name) {
    switch (name) {
      case "Nyamirambo":
        return Colors.red;
      case "Kimihurura":
        return Colors.blue;
      case "Remera":
        return Colors.green;
      case "Kigali Downtown":
        return Colors.purple;
      default:
        return Colors.orange;
    }
  }
}
