import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/property_model.dart';
import '../screens/property/property_details_screen.dart';

class FeaturedPropertyCard extends StatelessWidget {
  final PropertyModel property;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;

  const FeaturedPropertyCard({
    super.key,
    required this.property,
    this.isFavorite = false,
    this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 290,
      margin: const EdgeInsets.only(right: 16, bottom: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkNavy.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Background Hero Image
            Positioned.fill(
              child: Image.network(
                property.coverImage,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppColors.darkNavy,
                  child: const Center(
                    child: Icon(Icons.apartment_rounded, size: 50, color: Colors.white38),
                  ),
                ),
              ),
            ),

            // Deep Gradient Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.25),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.85),
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
              ),
            ),

            // Top Badges (Featured & Purpose)
            Positioned(
              top: 14,
              left: 14,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_rounded, color: Colors.white, size: 13),
                        SizedBox(width: 3),
                        Text(
                          'FEATURED',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      property.purpose.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.darkNavy,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Favorite Button
            Positioned(
              top: 14,
              right: 14,
              child: Material(
                color: Colors.white.withValues(alpha: 0.9),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onFavoriteToggle,
                  child: Padding(
                    padding: const EdgeInsets.all(7),
                    child: Icon(
                      isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: isFavorite ? AppColors.error : AppColors.darkNavy,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Content
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Price Tag
                  Text(
                    property.formattedPrice,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),

                  // Title
                  Text(
                    property.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Location
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 14, color: AppColors.primaryLight),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          property.location.fullAddress,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Specs Row (Pills)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 0.8,
                      ),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          if (property.bedrooms > 0) ...[
                            _buildMiniSpec(Icons.king_bed_outlined, '${property.bedrooms} Beds'),
                            _buildDotDivider(),
                          ],
                          if (property.bathrooms > 0) ...[
                            _buildMiniSpec(Icons.bathtub_outlined, '${property.bathrooms} Baths'),
                            _buildDotDivider(),
                          ],
                          _buildMiniSpec(Icons.aspect_ratio_rounded, property.formattedArea),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Tap Overlay
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PropertyDetailsScreen(property: property),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniSpec(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.white),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildDotDivider() {
    return Container(
      width: 3,
      height: 3,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        shape: BoxShape.circle,
      ),
    );
  }
}
