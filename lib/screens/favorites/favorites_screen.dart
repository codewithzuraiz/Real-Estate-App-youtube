import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/property_model.dart';
import '../../services/property_service.dart';
import '../../services/property_compare_service.dart';
import '../../widgets/compare_bottom_bar.dart';
import '../../widgets/custom_snackbar.dart';
import '../../widgets/property_card.dart';
import '../property/property_compare_screen.dart';

class FavoritesScreen extends StatefulWidget {
  final VoidCallback? onExploreTap;

  const FavoritesScreen({super.key, this.onExploreTap});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final PropertyService _propertyService = PropertyService();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.scaffoldBg,
        appBar: AppBar(title: const Text('Saved Properties')),
        body: const Center(
          child: Text('Please log in to view saved properties'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Saved Properties'),
        actions: [
          ListenableBuilder(
            listenable: PropertyCompareService(),
            builder: (context, _) {
              final compareService = PropertyCompareService();
              if (compareService.isEmpty) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: IconButton(
                  tooltip: 'View Comparison (${compareService.count})',
                  icon: Badge(
                    label: Text('${compareService.count}'),
                    backgroundColor: AppColors.primary,
                    child: const Icon(Icons.compare_arrows_rounded, color: AppColors.darkNavy),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PropertyCompareScreen(),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          StreamBuilder<List<PropertyModel>>(
        stream: _propertyService.streamFavoriteProperties(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            );
          }

          final favorites = snapshot.data ?? [];

          if (favorites.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_border_rounded,
                        size: 46,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'No Saved Properties Yet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkNavy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tap the heart icon on any property to save your favorite homes for later.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.slateBlue,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (widget.onExploreTap != null)
                      ElevatedButton(
                        onPressed: widget.onExploreTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        ),
                        child: const Text(
                          'Explore Properties',
                          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final property = favorites[index];
              return PropertyCard(
                property: property,
                isFavorite: true,
                onFavoriteToggle: () async {
                  await _propertyService.toggleFavorite(user.uid, property.id);
                  if (context.mounted) {
                    CustomSnackBar.showInfo(context, 'Removed from saved properties');
                  }
                },
              );
            },
          );
        },
      ),
      const CompareBottomBar(bottomPadding: 16),
    ],
  ),
);
  }
}
