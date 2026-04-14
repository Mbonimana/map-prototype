import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:map_prototype_app/data/model/location_model.dart';

class GeoJsonService {
  Future<List<LocationModel>> loadLocations() async {
    final data = await rootBundle.loadString('assets/mock/locations.geojson');

    final jsonResult = json.decode(data);

    return (jsonResult['features'] as List)
        .map((e) => LocationModel.fromJson(e))
        .toList();
  }
}
