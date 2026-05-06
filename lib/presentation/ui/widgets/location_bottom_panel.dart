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

  static const Color primaryBlue = Color(0xFF1994FF);

  @override
  Widget build(BuildContext context) {
    final distanceText = DistanceCalculator().format(
      userLocation,
      location.position,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.12),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 28,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(0, 0, 0, 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),

                  // Close button
                  Positioned(
                    right: 0,
                    top: -6,
                    child: GestureDetector(
                      onTap: onClose,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(0, 0, 0, 0.06),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 18,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Title
            Text(
              location.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 6),

            // Category badge
            Text(
              location.category.toUpperCase(),
              style: const TextStyle(
                color: primaryBlue,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 12),

            // Description
            Text(
              location.description ?? "No description available",
              style: const TextStyle(
                height: 1.5,
                color: Color.fromRGBO(0, 0, 0, 0.75),
              ),
            ),

            const SizedBox(height: 14),

            // Distance
            Row(
              children: [
                const Icon(Icons.location_on, size: 18, color: primaryBlue),
                const SizedBox(width: 6),
                Text(
                  distanceText,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
