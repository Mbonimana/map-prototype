import 'package:flutter/material.dart';

class EngineToggle extends StatelessWidget {
  final int index;
  final Function(int) onChanged;

  const EngineToggle({super.key, required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: index,
      onTap: onChanged,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.map), label: "Google"),
        BottomNavigationBarItem(
          icon: Icon(Icons.map_outlined),
          label: "Mapbox",
        ),
      ],
    );
  }
}
