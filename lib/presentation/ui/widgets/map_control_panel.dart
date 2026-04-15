import 'package:flutter/material.dart';
import 'package:map_prototype_app/presentation/ui/widgets/map_control_buttons.dart';


class MapControlsPanel extends StatelessWidget {
  final VoidCallback onFly;
  final VoidCallback onTilt;
  final VoidCallback onReset;

  const MapControlsPanel({
    super.key,
    required this.onFly,
    required this.onTilt,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MapControlButton(
          icon: Icons.flight_takeoff,
          label: "Fly",
          onTap: onFly,
        ),
        const SizedBox(height: 10),
        MapControlButton(
          icon: Icons.threed_rotation,
          label: "Tilt",
          onTap: onTilt,
        ),
        const SizedBox(height: 10),
        MapControlButton(
          icon: Icons.refresh,
          label: "Reset",
          onTap: onReset,
        ),
      ],
    );
  }
}