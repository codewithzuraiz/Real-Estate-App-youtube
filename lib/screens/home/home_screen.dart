import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/property_model.dart';
import '../../services/property_service.dart';
import '../../services/property_compare_service.dart';
import '../../widgets/compare_bottom_bar.dart';
import '../../widgets/custom_snackbar.dart';
import '../../widgets/featured_property_card.dart';
import '../../widgets/filter_bottom_sheet.dart';
import '../../widgets/property_card.dart';
import '../property/add_property_screen.dart';
import '../property/nearby_properties_map_screen.dart';
import '../property/property_compare_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const HomeScreen({super.key, this.onNavigateTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PropertyService _propertyService = PropertyService();
  final TextEditingController _searchController = TextEditingController();

  String _selectedCategory = 'All';
  FilterCriteria _activeFilters = const FilterCriteria();
  String _searchQuery = '';
  bool _isSeeding = false;
  Set<String> _favoriteIds = {};
  StreamSubscription<Set<String>>? _favSubscription;

  final List<String> _categories = [
    'All',
    'House / Villa',
    'Apartment',
    'Penthouse',
    'Commercial',
    'Plot',
    'Farmhouse',
  ];

  @override
  void initState() {
    super.initState();
    _listenFavorites();
  }

  void _listenFavorites() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _favSubscription?.cancel();
      _favSubscription = _propertyService.streamFavoriteIds(user.uid).listen((ids) {
        if (mounted) setState(() => _favoriteIds = ids);
      });
    }
  }

  @override
  void dispose() {
    _favSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        initialCriteria: _activeFilters,
        onApply: (newCriteria) {
          setState(() {
            _activeFilters = newCriteria;
            if (newCriteria.propertyType != 'All') {
              _selectedCategory = newCriteria.propertyType;
            }
          });
        },
      ),
    );
  }

  Future<void> _seedData() async {
    setState(() => _isSeeding = true);
    try {
      await _propertyService.seedSampleProperties();
      if (mounted) {
        CustomSnackBar.showSuccess(context, 'Successfully seeded sample property listings!');
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(context, 'Seeding error: $e');
      }
    } finally {
      if (mounted) setState(() => _isSeeding = false);
    }
  }

  Future<void> _toggleFavorite(PropertyModel property) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      CustomSnackBar.showWarning(context, 'Please log in to save properties');
      return;
    }

    final added = await _propertyService.toggleFavorite(user.uid, property.id);
    if (mounted) {
      if (added) {
        CustomSnackBar.showSuccess(context, 'Property saved to favorites!');
      } else {
        CustomSnackBar.showInfo(context, 'Removed from favorites');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName?.split(' ').first ?? 'User';

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                setState(() {});
              },
              child: CustomScrollView(
            slivers: [
              // Top Header & Search App Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        children: [
                          // User Greeting
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_rounded, size: 14, color: AppColors.primary),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Lahore, Pakistan',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.slateBlue.withValues(alpha: 0.9),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Hello, $displayName 👋',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.darkNavy,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Compare Quick Button (when items selected)
                          ListenableBuilder(
                            listenable: PropertyCompareService(),
                            builder: (context, _) {
                              final compareService = PropertyCompareService();
                              if (compareService.isEmpty) return const SizedBox.shrink();

                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const PropertyCompareScreen(),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: AppColors.darkNavy,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.compare_arrows_rounded, color: AppColors.primary, size: 18),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${compareService.count}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                          // Add Listing Quick Button
                          InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              if (widget.onNavigateTab != null) {
                                widget.onNavigateTab!(2);
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const AddPropertyScreen(),
                                  ),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [AppColors.primaryLight, AppColors.primary],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 18),
                                  SizedBox(width: 6),
                                  Text(
                                    'Post Ad',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Search Bar & Filter Button Row
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.darkNavy.withValues(alpha: 0.04),
                                    blurRadius: 12,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _searchController,
                                onChanged: (val) {
                                  setState(() => _searchQuery = val);
                                },
                                decoration: InputDecoration(
                                  hintText: 'Search city, society, title...',
                                  hintStyle: TextStyle(
                                    color: AppColors.slateBlue.withValues(alpha: 0.6),
                                    fontSize: 14,
                                  ),
                                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.silverGrey),
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() => _searchQuery = '');
                                          },
                                        )
                                      : null,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Filter Trigger Button
                          Material(
                            color: _activeFilters.hasActiveFilters ? AppColors.primary : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            elevation: 1,
                            shadowColor: AppColors.darkNavy.withValues(alpha: 0.1),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: _openFilterSheet,
                              child: Container(
                                height: 52,
                                width: 52,
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.tune_rounded,
                                  color: _activeFilters.hasActiveFilters ? Colors.white : AppColors.darkNavy,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Map View Quick Button
                          Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            elevation: 1,
                            shadowColor: AppColors.darkNavy.withValues(alpha: 0.1),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                if (widget.onNavigateTab != null) {
                                  widget.onNavigateTab!(1);
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const NearbyPropertiesMapScreen(),
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                height: 52,
                                width: 52,
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.map_rounded,
                                  color: AppColors.primary,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Category Horizontal List
                      SizedBox(
                        height: 40,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _categories.length,
                          itemBuilder: (context, index) {
                            final cat = _categories[index];
                            final isSelected = _selectedCategory == cat;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(cat),
                                selected: isSelected,
                                onSelected: (sel) {
                                  if (sel) {
                                    setState(() {
                                      _selectedCategory = cat;
                                      _activeFilters = _activeFilters.copyWith(propertyType: cat);
                                    });
                                  }
                                },
                                selectedColor: AppColors.primary,
                                backgroundColor: Colors.white,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : AppColors.darkNavy,
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: BorderSide(
                                    color: isSelected ? AppColors.primary : AppColors.borderGrey,
                                    width: 1,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Featured Properties Section (If no search query active)
              if (_searchQuery.isEmpty && !_activeFilters.hasActiveFilters) ...[
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Expanded(
                              child: Text(
                                'Featured Listings ✨',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.darkNavy,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 220,
                        child: StreamBuilder<List<PropertyModel>>(
                          stream: _propertyService.streamFeaturedProperties(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                ),
                              );
                            }

                            final featured = snapshot.data ?? [];
                            if (featured.isEmpty) {
                              return const SizedBox.shrink();
                            }

                            return ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.only(left: 20, right: 4),
                              itemCount: featured.length,
                              itemBuilder: (context, index) {
                                final prop = featured[index];
                                return FeaturedPropertyCard(
                                  property: prop,
                                  isFavorite: _favoriteIds.contains(prop.id),
                                  onFavoriteToggle: () => _toggleFavorite(prop),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // All / Recent Properties Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _selectedCategory == 'All' ? 'All Properties' : '$_selectedCategory Listings',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.darkNavy,
                          ),
                        ),
                      ),
                      if (_activeFilters.hasActiveFilters) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _activeFilters = const FilterCriteria();
                              _selectedCategory = 'All';
                            });
                          },
                          child: const Text(
                            'Reset Filters',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Property List Stream
              StreamBuilder<List<PropertyModel>>(
                stream: _propertyService.streamProperties(
                  purpose: _activeFilters.purpose,
                  propertyType: _selectedCategory,
                  searchQuery: _searchQuery,
                  minPrice: _activeFilters.minPrice,
                  maxPrice: _activeFilters.maxPrice,
                  minBedrooms: _activeFilters.minBedrooms,
                  areaUnit: _activeFilters.areaUnit,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    final errStr = snapshot.error.toString();
                    final isPermission = errStr.contains('permission-denied') || errStr.contains('insufficient permissions');
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(28.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.lock_outline_rounded, size: 40, color: AppColors.error),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                isPermission ? 'Firestore Permission Required' : 'Failed to Load Properties',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.darkNavy,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isPermission
                                    ? 'Please allow read/write rules in Firebase Console -> Firestore Database -> Rules tab.'
                                    : '$snapshot.error',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 13, color: AppColors.slateBlue),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: () => setState(() {}),
                                icon: const Icon(Icons.refresh_rounded, size: 18),
                                label: const Text('Retry'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  final properties = snapshot.data ?? [];

                  if (properties.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.holiday_village_outlined,
                                  size: 42,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 18),
                              const Text(
                                'No Properties Found',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.darkNavy,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'No properties matched your criteria or the database is currently empty.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 13, color: AppColors.slateBlue),
                              ),
                              const SizedBox(height: 24),

                              // One-Click Seed Button
                              ElevatedButton.icon(
                                onPressed: _isSeeding ? null : _seedData,
                                icon: _isSeeding
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Icon(Icons.cloud_download_rounded, size: 18),
                                label: Text(_isSeeding ? 'Populating...' : 'Seed Sample Real Estate Data'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final property = properties[index];
                          return PropertyCard(
                            property: property,
                            isFavorite: _favoriteIds.contains(property.id),
                            onFavoriteToggle: () => _toggleFavorite(property),
                          );
                        },
                        childCount: properties.length,
                      ),
                    ),
                  );
                },
              ),

              // Bottom Spacer
              const SliverToBoxAdapter(
                child: SizedBox(height: 90),
              ),
            ],
          ),
        ),

        // Floating Compare Tray
        const CompareBottomBar(bottomPadding: 16),
      ],
    ),
  ),
);
  }
}
