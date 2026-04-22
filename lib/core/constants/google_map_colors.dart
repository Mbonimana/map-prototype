import 'package:flutter/material.dart';

class GoogleMapColors {
  static const Color clusterLow = Colors.blue;
  static const Color clusterMedium = Colors.orange;
  static const Color clusterHigh = Colors.red;
  static const Color route = Colors.red;
  static const int routeWidth = 2;

  static Color clusterColor(int count) {
    if (count <= 3) return clusterLow;
    if (count <= 10) return clusterMedium;
    return clusterHigh;
  }

  static double clusterRadius(int count) {
    if (count <= 3) return 28.0;
    if (count <= 10) return 36.0;
    return 44.0;
  }
}
