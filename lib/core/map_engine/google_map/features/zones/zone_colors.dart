import 'package:flutter/material.dart';

class ZoneColors {
  static Color get(String name) {
    if (name == 'Nyamirambo') return Colors.red;
    if (name == 'Kimihurura') return Colors.blue;
    if (name == 'Remera') return Colors.green;
    if (name == 'Kigali Downtown') return Colors.purple;
    return Colors.orange;
  }
}
