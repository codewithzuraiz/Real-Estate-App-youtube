import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/property_model.dart';
import '../../services/property_service.dart';
import '../../widgets/custom_snackbar.dart';
import '../../widgets/property_card.dart';

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
      ),
      body: StreamBuilder<List<PropertyModel>>(
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
    );
  }
}
