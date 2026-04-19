import 'package:flutter/material.dart';
import 'package:map_prototype_app/core/map/map_engine.dart';
import 'package:map_prototype_app/data/model/coordinate_model.dart';
import 'package:map_prototype_app/data/model/location_model.dart';
import 'package:map_prototype_app/presentation/ui/widgets/location_bottom_panel.dart';
import 'package:map_prototype_app/presentation/ui/widgets/map_control_panel.dart';
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
  LocationModel? _selectedLocation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          widget.engine.buildMap(
            markers: widget.locations,
            userLocation: widget.startPostion,
            style: style,
            onLocationSelected: (loc) =>
                setState(() => _selectedLocation = loc),
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: StyleLayerSelector(
              selected: style,
              onChanged: (s) => setState(() => style = s),
            ),
          ),

          Positioned(
            bottom: 120,
            right: 10,
            child: MapControlsPanel(
              onFly: widget.engine.flyToKigali,
              onTilt: widget.engine.tiltCamera,
              onReset: widget.engine.resetCamera,
              onLocation: widget.engine.goToUserLocation,
            ),
          ),

          AnimatedPositioned(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOut,
            left: 0,
            right: 0,
            bottom: _selectedLocation != null ? 0 : -300,
            child: _selectedLocation == null
                ? const SizedBox.shrink()
                : LocationBottomPanel(
                    location: _selectedLocation!,
                    userLocation: widget.startPostion,
                    onClose: () => setState(() => _selectedLocation = null),
                  ),
          ),
        ],
      ),
    );
  }
}
