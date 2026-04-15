import 'package:flutter/material.dart';
import 'package:map_prototype_app/core/map/map_engine.dart';
import 'package:map_prototype_app/data/model/coordinate_model.dart';
import 'package:map_prototype_app/data/model/location_model.dart';
import 'package:map_prototype_app/presentation/ui/widgets/style_rail.dart';

class MapScreen extends StatefulWidget {
  final MapEngine engine;
  final List<LocationModel> locations;
  final AppLatLng startPostion;

  const MapScreen({
    super.key,
    required this.engine,
    required this.locations,
    required this.startPostion,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  MapStyle style = MapStyle.streets;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          widget.engine.buildMap(
            markers: widget.locations,
            userLocation: widget.startPostion,
            style: style,
          ),

          Positioned(
            right: 10,
            top: 100,
            child: StyleRail(
              selected: style,
              onChanged: (s) => setState(() => style = s),
            ),
          ),
        ],
      ),
    );
  }
}
