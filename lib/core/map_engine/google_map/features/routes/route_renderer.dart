import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:map_prototype_app/core/constants/google_map_colors.dart';
import 'package:map_prototype_app/core/map_engine/google_map/utils/asset_loader.dart';

class RouteRenderer {
  static Future<Set<Polyline>> render(BuildContext context) async {
    final jsonString = await AssetLoader.loadString(
      context,
      GoogleMapRouteAssets.route,
    );

    final data = jsonDecode(jsonString);
    final coords = data['features'][0]['geometry']['coordinates'];
    final points = coords.map<LatLng>((c) => LatLng(c[1], c[0])).toList();

    return {
      Polyline(
        polylineId: const PolylineId(GoogleMapRouteAssets.routeId),
        points: points,
        color: GoogleMapColors.route,
        width: GoogleMapColors.routeWidth,
      ),
    };
  }
}

class GoogleMapRouteAssets {
  static const String route = 'assets/mock/routes.geojson';
  static const String routeId = 'route';
}
