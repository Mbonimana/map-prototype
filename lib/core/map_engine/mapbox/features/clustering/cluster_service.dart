import 'dart:math' as math;

import 'package:latlong2/latlong.dart' as geo;
import 'package:map_prototype_app/data/model/location_model.dart';

class ClusterService {
  final geo.Distance distance;

  const ClusterService(this.distance);

  double clusterRadius(double zoom) {
    final radius = 220.0 * math.pow(2.0, 13.0 - zoom).toDouble();
    return radius.clamp(60.0, 2400.0);
  }

  List<List<LocationModel>> createClusters(
    List<LocationModel> items,
    double zoom,
  ) {
    final radiusMeters = clusterRadius(zoom);
    final List<List<LocationModel>> clusters = [];

    for (final item in items) {
      bool added = false;

      for (final cluster in clusters) {
        final center = cluster.first.position;

        final dist = distance.as(
          geo.LengthUnit.Meter,
          geo.LatLng(center.lat, center.lng),
          geo.LatLng(item.position.lat, item.position.lng),
        );

        if (dist < radiusMeters) {
          cluster.add(item);
          added = true;
          break;
        }
      }

      if (!added) clusters.add([item]);
    }

    return clusters;
  }
}
