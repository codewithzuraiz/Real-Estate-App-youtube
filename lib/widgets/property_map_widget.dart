import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_theme.dart';
import '../models/property_model.dart';
import 'custom_snackbar.dart';

class PropertyMapWidget extends StatelessWidget {
  final PropertyLocation location;
  final String title;

  const PropertyMapWidget({
    super.key,
    required this.location,
    required this.title,
  });

  Future<void> _openGoogleMaps(BuildContext context) async {
    final lat = location.latitude;
    final lng = location.longitude;
    final googleMapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    final appleMapsUrl = Uri.parse('https://maps.apple.com/?q=$lat,$lng');

    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(appleMapsUrl)) {
        await launchUrl(appleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          CustomSnackBar.showError(context, 'Could not open maps on this device');
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.showError(context, 'Error launching map: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderGrey, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkNavy.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Map Visual Graphic Container
          Container(
            height: 160,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE8EEF5), Color(0xFFD6E2ED)],
              ),
            ),
            child: Stack(
              children: [
                // Stylized Map Grid and Roads Illustration
                Positioned.fill(
                  child: CustomPaint(
                    painter: _MapGridPainter(),
                  ),
                ),

                // Center Location Pin with Ripple
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.4),
                              blurRadius: 16,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.darkNavy.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          location.areaName.isNotEmpty ? location.areaName : location.city,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Coordinates Pill
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borderGrey),
                    ),
                    child: Text(
                      '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.slateBlue,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Address & Action Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        location.fullAddress,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkNavy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${location.city}, Pakistan',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.slateBlue,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _openGoogleMaps(context),
                  icon: const Icon(Icons.directions_rounded, size: 16),
                  label: const Text('Directions'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for stylized map pattern
class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;

    final thinRoadPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Draw stylized diagonal and curved roads
    final path1 = Path()
      ..moveTo(0, size.height * 0.3)
      ..cubicTo(
        size.width * 0.3,
        size.height * 0.2,
        size.width * 0.7,
        size.height * 0.8,
        size.width,
        size.height * 0.7,
      );
    canvas.drawPath(path1, roadPaint);

    final path2 = Path()
      ..moveTo(size.width * 0.2, 0)
      ..lineTo(size.width * 0.8, size.height);
    canvas.drawPath(path2, thinRoadPaint);

    final path3 = Path()
      ..moveTo(0, size.height * 0.85)
      ..lineTo(size.width, size.height * 0.25);
    canvas.drawPath(path3, thinRoadPaint);

    // Green space patch (parks)
    final parkPaint = Paint()
      ..color = const Color(0xFFC8E6C9).withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.08, size.height * 0.55, 60, 40),
        const Radius.circular(8),
      ),
      parkPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.75, size.height * 0.12, 50, 35),
        const Radius.circular(8),
      ),
      parkPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
