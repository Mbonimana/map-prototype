import 'package:flutter/material.dart';
import 'package:map_prototype_app/core/map_engine/map_engine.dart';

class StyleLayerSelector extends StatelessWidget {
  final MapStyle selected;
  final Function(MapStyle) onChanged;

  const StyleLayerSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  static const Color primaryBlue = Color(0xFF1994ff);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(top: 12.0),
        //  Align center at the top
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(230),
              borderRadius: BorderRadius.circular(30),
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
                  icon: Icons.map,
                  label: "Map",
                  active: selected == MapStyle.streets,
                  onTap: () => onChanged(MapStyle.streets),
                ),
                const SizedBox(width: 8),
                _buildPill(
                  icon: Icons.satellite,
                  label: "Satellite",
                  active: selected == MapStyle.satellite,
                  onTap: () => onChanged(MapStyle.satellite),
                ),
                const SizedBox(width: 8),
                _buildPill(
                  icon: Icons.terrain,
                  label: "Terrain",
                  active: selected == MapStyle.terrain,
                  onTap: () => onChanged(MapStyle.terrain),
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
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: active ? primaryBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: active ? primaryBlue : Colors.black.withAlpha(40),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: active ? Colors.white : Colors.black87,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: active ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
