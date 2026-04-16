import 'package:flutter/material.dart';
import 'package:map_prototype_app/core/map/map_engine.dart';

class StyleLayerSelector extends StatefulWidget {
  final MapStyle selected;
  final Function(MapStyle) onChanged;

  const StyleLayerSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  State<StyleLayerSelector> createState() => _StyleLayerSelectorState();
}

class _StyleLayerSelectorState extends State<StyleLayerSelector> {
  bool _isOpen = false;

  final Color primaryBlue = const Color(0xFF1994ff);

  void toggle() => setState(() => _isOpen = !_isOpen);
  void close() => setState(() => _isOpen = false);

  void _select(MapStyle style) {
    widget.onChanged(style);
    close();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        //  Animated style buttons
        if (_isOpen) ...[
          _buildAnimatedButton(
            icon: Icons.map,
            active: widget.selected == MapStyle.streets,
            onTap: () => _select(MapStyle.streets),
            delay: 1,
          ),
          const SizedBox(height: 12),

          _buildAnimatedButton(
            icon: Icons.satellite,
            active: widget.selected == MapStyle.satellite,
            onTap: () => _select(MapStyle.satellite),
            delay: 2,
          ),
          const SizedBox(height: 12),

          _buildAnimatedButton(
            icon: Icons.terrain,
            active: widget.selected == MapStyle.terrain,
            onTap: () => _select(MapStyle.terrain),
            delay: 3,
          ),
          const SizedBox(height: 16),
        ],

        // Main layers button
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
                  color: primaryBlue.withAlpha(120),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              _isOpen ? Icons.close : Icons.layers,
              color: Colors.white,
              size: 24,
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
    required bool active,
  }) {
    return AnimatedSlide(
      offset: _isOpen ? Offset.zero : const Offset(0, 0.4),
      duration: Duration(milliseconds: 160 + (delay * 40)),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        opacity: _isOpen ? 1 : 0,
        duration: const Duration(milliseconds: 180),
        child: _StyleMiniButton(
          icon: icon,
          onTap: onTap,
          primaryBlue: primaryBlue,
          active: active,
        ),
      ),
    );
  }
}

class _StyleMiniButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color primaryBlue;
  final bool active;

  const _StyleMiniButton({
    required this.icon,
    required this.onTap,
    required this.primaryBlue,
    required this.active,
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
            color: active ? Colors.white.withAlpha(230) : primaryBlue,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: active ? primaryBlue : Colors.black.withAlpha(12),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 22,
            color: active ? primaryBlue : Colors.white,
          ),
        ),
      ),
    );
  }
}
