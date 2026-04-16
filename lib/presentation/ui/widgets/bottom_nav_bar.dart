import 'package:flutter/material.dart';

class EngineToggle extends StatelessWidget {
  final int index;
  final Function(int) onChanged;

  const EngineToggle({super.key, required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        currentIndex: index,
        onTap: onChanged,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF2563EB),
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: _LogoIcon(
              asset: "assets/icons/google_maps_logo.webp",
              active: index == 0,
            ),
            label: "Google Maps",
          ),
          BottomNavigationBarItem(
            icon: _LogoIcon(
              asset: "assets/icons/mapbox_logo.webp",
              active: index == 1,
            ),
            label: "Mapbox",
          ),
        ],
      ),
    );
  }
}

class _LogoIcon extends StatelessWidget {
  final String asset;
  final bool active;

  const _LogoIcon({required this.asset, required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: active
            ? const Color(0xFF1994ff).withAlpha(30)
            : Colors.transparent,
      ),
      child: Image.asset(asset, width: 24, height: 24, fit: BoxFit.contain),
    );
  }
}
