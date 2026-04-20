import 'package:map_prototype_app/data/model/coordinate_model.dart';
import 'package:map_prototype_app/data/model/location_model.dart';

class ClusterItem {
  final AppLatLng position;
  final List<LocationModel> items;

  ClusterItem({required this.position, required this.items});
}
