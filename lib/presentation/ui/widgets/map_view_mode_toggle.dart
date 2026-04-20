import 'package:flutter/material.dart';
import 'package:map_prototype_app/core/map/map_engine.dart';

class MapViewModeToggle extends StatelessWidget {
  final MapViewMode selected;
  final ValueChanged<MapViewMode> onChanged;

  const MapViewModeToggle({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  static const Color primaryBlue = Color(0xFF1994ff);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(230),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(30),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildPill(
                  icon: Icons.place,
                  active: selected == MapViewMode.pins,
                  onTap: () => onChanged(MapViewMode.pins),
                ),
                const SizedBox(width: 6),
                _buildPill(
                  icon: Icons.scatter_plot,
                  active: selected == MapViewMode.clusters,
                  onTap: () => onChanged(MapViewMode.clusters),
                ),
                const SizedBox(width: 6),
                _buildPill(
                  icon: Icons.whatshot,
                  active: selected == MapViewMode.heatmap,
                  onTap: () => onChanged(MapViewMode.heatmap),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPill({
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: active ? primaryBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active ? primaryBlue : Colors.black.withAlpha(40),
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: active ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}
