import 'package:flutter/material.dart';
import 'package:map_prototype_app/core/utils/distance_calculator.dart';
import 'package:map_prototype_app/data/model/coordinate_model.dart';
import 'package:map_prototype_app/data/model/location_model.dart';

class LocationBottomPanel extends StatelessWidget {
  final LocationModel location;
  final AppLatLng userLocation;
  final VoidCallback onClose;

  const LocationBottomPanel({
    super.key,
    required this.location,
    required this.userLocation,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final distanceText = DistanceCalculator.format(
      userLocation,
      location.position,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // Title + Close
            Row(
              children: [
                Expanded(
                  child: Text(
                    location.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: onClose),
              ],
            ),

            const SizedBox(height: 4),

            // Category
            Text(
              location.category.toUpperCase(),
              style: TextStyle(
                color: Colors.blueGrey[600],
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 10),

            // Description
            Text(
              location.description ?? "No description available",
              style: const TextStyle(height: 1.4),
            ),

            const SizedBox(height: 12),

            // Distance
            Row(
              children: [
                const Icon(Icons.location_on, size: 18),
                const SizedBox(width: 6),
                Text(
                  distanceText,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
