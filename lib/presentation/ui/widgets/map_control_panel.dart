import 'package:flutter/material.dart';

class MapControlsPanel extends StatelessWidget {
  final VoidCallback onFly;
  final VoidCallback onTilt;
  final VoidCallback onReset;
  final VoidCallback onLocation;

  const MapControlsPanel({
    super.key,
    required this.onFly,
    required this.onTilt,
    required this.onReset,
    required this.onLocation,
  });

  final Color primaryBlue = const Color(0xFF1994ff);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _StyledMiniButton(
          icon: Icons.my_location,
          onTap: onLocation,
          primaryBlue: primaryBlue,
          isPrimary: true, 
        ),
        const SizedBox(height: 12),

        _StyledMiniButton(
          icon: Icons.flight_takeoff,
          onTap: onFly,
          primaryBlue: primaryBlue,
        ),
        const SizedBox(height: 12),

        _StyledMiniButton(
          icon: Icons.threed_rotation,
          onTap: onTilt,
          primaryBlue: primaryBlue,
        ),
        const SizedBox(height: 12),

        _StyledMiniButton(
          icon: Icons.refresh,
          onTap: onReset,
          primaryBlue: primaryBlue,
        ),
      ],
    );
  }
}

class _StyledMiniButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color primaryBlue;
  final bool isPrimary;

  const _StyledMiniButton({
    required this.icon,
    required this.onTap,
    required this.primaryBlue,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 44, // Slightly larger for better touch targets
          height: 44,
          decoration: BoxDecoration(
            // If it's the primary (location) button, we can give it a blue tint or white
            color: isPrimary ? Colors.white : Colors.white.withAlpha(230),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPrimary
                  ? primaryBlue.withAlpha(80)
                  : Colors.black.withAlpha(12),
              width: isPrimary ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isPrimary ? 40 : 25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, size: 24, color: primaryBlue),
        ),
      ),
    );
  }
}
