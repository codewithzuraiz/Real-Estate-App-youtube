import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../screens/property/property_compare_screen.dart';
import '../services/property_compare_service.dart';

class CompareBottomBar extends StatelessWidget {
  final double bottomPadding;

  const CompareBottomBar({
    super.key,
    this.bottomPadding = 80,
  });

  @override
  Widget build(BuildContext context) {
    final compareService = PropertyCompareService();

    return Positioned(
      left: 16,
      right: 16,
      bottom: bottomPadding,
      child: ListenableBuilder(
        listenable: compareService,
        builder: (context, _) {
          if (compareService.isEmpty) {
            return const SizedBox.shrink();
          }

          final count = compareService.count;
          final properties = compareService.properties;

          return Material(
            elevation: 12,
            shadowColor: AppColors.darkNavy.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(22),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.darkNavy,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  // Thumbnails Overlapping Stack
                  SizedBox(
                    height: 40,
                    width: properties.length == 1
                        ? 40
                        : (properties.length == 2 ? 68 : (properties.length == 3 ? 94 : 116)),
                    child: Stack(
                      children: List.generate(properties.length, (index) {
                        final prop = properties[index];
                        final leftOffset = index * 25.0;
                        return Positioned(
                          left: leftOffset,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1.5,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(9),
                                  child: Image.network(
                                    prop.coverImage,
                                    width: 38,
                                    height: 38,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: AppColors.slateBlue.withValues(alpha: 0.4),
                                      child: const Icon(Icons.apartment_rounded, color: Colors.white70, size: 18),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: -3,
                                right: -3,
                                child: GestureDetector(
                                  onTap: () => compareService.remove(prop.id),
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: const BoxDecoration(
                                      color: Colors.redAccent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close_rounded,
                                      color: Colors.white,
                                      size: 10,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Info text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$count/${PropertyCompareService.maxProperties}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Flexible(
                              child: Text(
                                'Compare',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          count < 2 ? 'Add 1 more to compare' : '$count properties ready',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Action Button
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PropertyCompareScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'View',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_rounded, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
