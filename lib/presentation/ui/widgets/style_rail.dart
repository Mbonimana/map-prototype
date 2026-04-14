import 'package:flutter/material.dart';
import 'package:map_prototype_app/core/map/map_engine.dart';

class StyleRail extends StatelessWidget {
  final MapStyle selected;
  final Function(MapStyle) onChanged;

  const StyleRail({super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(
          icon: const Icon(Icons.map),
          onPressed: () => onChanged(MapStyle.streets),
        ),
        IconButton(
          icon: const Icon(Icons.satellite),
          onPressed: () => onChanged(MapStyle.satellite),
        ),
        IconButton(
          icon: const Icon(Icons.terrain),
          onPressed: () => onChanged(MapStyle.terrain),
        ),
      ],
    );
  }
}
