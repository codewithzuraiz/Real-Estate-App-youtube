import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/property_model.dart';
import '../screens/property/property_details_screen.dart';

class PropertyCard extends StatelessWidget {
  final PropertyModel property;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;

  const PropertyCard({
    super.key,
    required this.property,
    this.isFavorite = false,
    this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkNavy.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PropertyDetailsScreen(property: property),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Header with Badges
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                    child: Image.network(
                      property.coverImage,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 200,
                          color: AppColors.borderGrey.withValues(alpha: 0.4),
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 200,
                        color: AppColors.borderGrey.withValues(alpha: 0.5),
                        child: const Center(
                          child: Icon(Icons.apartment_rounded, size: 50, color: AppColors.silverGrey),
                        ),
                      ),
                    ),
                  ),

                  // Gradient Dark Overlay for Badge Readability
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.35),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.45),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Purpose Badge (For Sale / For Rent)
                  Positioned(
                    top: 14,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: property.purpose == 'For Sale'
                            ? AppColors.primary
                            : AppColors.slateBlue,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        property.purpose.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),

                  // Favorite Button
                  Positioned(
                    top: 14,
                    right: 14,
                    child: Material(
                      color: Colors.white.withValues(alpha: 0.85),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onFavoriteToggle,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: isFavorite ? AppColors.error : AppColors.darkNavy,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Video Tour Tag (If video exists)
                  if (property.videoUrl != null && property.videoUrl!.isNotEmpty)
                    Positioned(
                      bottom: 12,
                      left: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Video Tour',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Price Tag Bottom Right
                  Positioned(
                    bottom: 12,
                    right: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.darkNavy.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 0.8),
                      ),
                      child: Text(
                        property.formattedPrice,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Property Details Body
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Property Type Tag
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            property.propertyType,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (property.viewsCount > 0)
                          Row(
                            children: [
                              const Icon(Icons.remove_red_eye_outlined, size: 14, color: AppColors.silverGrey),
                              const SizedBox(width: 4),
                              Text(
                                '${property.viewsCount} views',
                                style: const TextStyle(fontSize: 11, color: AppColors.slateBlue),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Title
                    Text(
                      property.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkNavy,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Location Row
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 16, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            property.location.fullAddress,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.slateBlue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: AppColors.borderGrey),
                    const SizedBox(height: 12),

                    // Specs Icons Row (Beds, Baths, Area)
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        if (property.bedrooms > 0)
                          _buildSpecItem(
                            icon: Icons.king_bed_outlined,
                            text: '${property.bedrooms} Beds',
                          ),
                        if (property.bathrooms > 0)
                          _buildSpecItem(
                            icon: Icons.bathtub_outlined,
                            text: '${property.bathrooms} Baths',
                          ),
                        _buildSpecItem(
                          icon: Icons.aspect_ratio_rounded,
                          text: property.formattedArea,
                          isHighlight: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecItem({
    required IconData icon,
    required String text,
    bool isHighlight = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 17,
          color: isHighlight ? AppColors.primary : AppColors.slateBlue,
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w600,
            color: isHighlight ? AppColors.darkNavy : AppColors.slateBlue,
          ),
        ),
      ],
    );
  }
}
