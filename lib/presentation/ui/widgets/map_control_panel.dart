import 'package:flutter/material.dart';

class MapControlsPanel extends StatefulWidget {
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
  State<MapControlsPanel> createState() => _MapControlsPanelState();
}

class _MapControlsPanelState extends State<MapControlsPanel> {
  bool _isOpen = false;

  final Color primaryBlue = const Color(0xFF1994ff);

  void toggle() => setState(() => _isOpen = !_isOpen);
  void close() => setState(() => _isOpen = false);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Sub buttons
        if (_isOpen) ...[
          _buildAnimatedButton(
            icon: Icons.flight_takeoff,
            onTap: () {
              widget.onFly();
              close();
            },
            delay: 1,
          ),
          const SizedBox(height: 12),

          _buildAnimatedButton(
            icon: Icons.threed_rotation,
            onTap: () {
              widget.onTilt();
              close();
            },
            delay: 2,
          ),
          const SizedBox(height: 12),

          _buildAnimatedButton(
            icon: Icons.refresh,
            onTap: () {
              widget.onReset();
              close();
            },
            delay: 3,
          ),
          const SizedBox(height: 16),
        ],

        // view toggle button
        GestureDetector(
          onTap: toggle,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: primaryBlue,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withAlpha(100),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              _isOpen ? Icons.close : Icons.visibility,
              color: Colors.white,
              size: 26,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedButton({
    required IconData icon,
    required VoidCallback onTap,
    required int delay,
  }) {
    return AnimatedSlide(
      offset: _isOpen ? Offset.zero : const Offset(0, 0.4),
      duration: Duration(milliseconds: 160 + (delay * 40)),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        opacity: _isOpen ? 1 : 0,
        duration: const Duration(milliseconds: 180),
        child: _StyledMiniButton(
          icon: icon,
          onTap: onTap,
          primaryBlue: primaryBlue,
        ),
      ),
    );
  }
}

class _StyledMiniButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color primaryBlue;

  const _StyledMiniButton({
    required this.icon,
    required this.onTap,
    required this.primaryBlue,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(230),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withAlpha(12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, size: 22, color: primaryBlue),
        ),
      ),
    );
  }
}
