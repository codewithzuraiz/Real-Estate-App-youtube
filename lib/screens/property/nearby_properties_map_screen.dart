import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../../config/app_theme.dart';
import '../../models/property_model.dart';
import '../../services/property_service.dart';
import 'property_details_screen.dart';

class NearbyPropertiesMapScreen extends StatefulWidget {
  final LatLng? initialCenter;
  final double initialZoom;

  const NearbyPropertiesMapScreen({
    super.key,
    this.initialCenter,
    this.initialZoom = 13.0,
  });

  @override
  State<NearbyPropertiesMapScreen> createState() => _NearbyPropertiesMapScreenState();
}

class _NearbyPropertiesMapScreenState extends State<NearbyPropertiesMapScreen> {
  final PropertyService _propertyService = PropertyService();
  late final MapController _mapController;

  late LatLng _mapCenter;
  late double _currentZoom;
  PropertyModel? _selectedProperty;
  LatLng? _userLocation;
  bool _isLocatingUser = false;

  // Filters
  String _selectedCity = 'Lahore';
  String _selectedPurpose = 'All';
  String _selectedType = 'All';
  double? _selectedRadiusKm = 25.0; // null = All / No radius limit

  // City presets in Pakistan
  static const Map<String, LatLng> _cityCenters = {
    'Lahore': LatLng(31.5204, 74.3587),
    'Islamabad': LatLng(33.6844, 73.0479),
    'Karachi': LatLng(24.8607, 67.0011),
  };

  static const List<String> _purposeOptions = ['All', 'For Sale', 'For Rent'];
  static const List<String> _typeOptions = ['All', 'House', 'Flat', 'Plot', 'Commercial'];
  final List<double?> _radiusOptions = [5.0, 10.0, 25.0, 50.0, null];

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _mapCenter = widget.initialCenter ?? _cityCenters['Lahore']!;
    _currentZoom = widget.initialZoom;

    // Detect user's current GPS location quietly in background
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _detectUserLocationQuietly();
    });
  }


  Future<void> _detectUserLocationQuietly() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 5),
          ),
        );
        if (mounted) {
          setState(() {
            _userLocation = LatLng(position.latitude, position.longitude);
          });
        }
      }
    } catch (_) {
      // Quiet background check, ignore
    }
  }

  Future<void> _determineUserLocation({bool animateTo = true}) async {
    if (_isLocatingUser) return;
    setState(() => _isLocatingUser = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted && animateTo) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.location_off_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Location service is turned off. Please turn on GPS.'),
                  ),
                ],
              ),
              backgroundColor: AppColors.darkNavy,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
        if (mounted) setState(() => _isLocatingUser = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted && animateTo) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.lock_outline_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('Location permission denied. Showing city center.'),
                    ),
                  ],
                ),
                backgroundColor: AppColors.darkNavy,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
          if (mounted) setState(() => _isLocatingUser = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted && animateTo) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Location permission is blocked. Please enable it in settings.'),
                  ),
                ],
              ),
              backgroundColor: AppColors.darkNavy,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
        if (mounted) setState(() => _isLocatingUser = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final userCoords = LatLng(position.latitude, position.longitude);

      if (mounted) {
        setState(() {
          _userLocation = userCoords;
          _isLocatingUser = false;
        });

        if (animateTo) {
          _moveToLocation(userCoords, zoom: 15.0);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.my_location_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Centered on your current location'),
                ],
              ),
              backgroundColor: AppColors.primary,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLocatingUser = false);
        if (animateTo) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not fetch location: $e'),
              backgroundColor: AppColors.darkNavy,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    }
  }

  void _moveToLocation(LatLng target, {double? zoom}) {
    final newZoom = zoom ?? _currentZoom;
    _mapController.move(target, newZoom);
    setState(() {
      _mapCenter = target;
      _currentZoom = newZoom;
    });
  }

  void _selectCity(String city) {
    final center = _cityCenters[city];
    if (center != null) {
      setState(() {
        _selectedCity = city;
        _selectedProperty = null;
      });
      _moveToLocation(center, zoom: 13.0);
    }
  }

  LatLng get _referenceOrigin =>
      _userLocation ?? _cityCenters[_selectedCity] ?? _mapCenter;

  double _calculateDistanceKm(PropertyLocation location) {
    const distance = Distance();
    return distance.as(
      LengthUnit.Kilometer,
      _referenceOrigin,
      LatLng(location.latitude, location.longitude),
    );
  }

  String _formatDistance(double km) {
    if (km < 0.05) {
      return '< 50 m';
    }
    if (km < 1.0) {
      return '${(km * 1000).round()} m';
    }
    return '${km.toStringAsFixed(1)} km';
  }

  String _formatShortPrice(double price, String purpose) {
    String short;
    if (price >= 10000000) {
      final cr = price / 10000000;
      short = '${cr.toStringAsFixed(cr % 1 == 0 ? 0 : 1)} Cr';
    } else if (price >= 100000) {
      final lac = price / 100000;
      short = '${lac.toStringAsFixed(lac % 1 == 0 ? 0 : 1)} Lac';
    } else if (price >= 1000) {
      short = '${(price / 1000).round()}k';
    } else {
      short = price.toStringAsFixed(0);
    }

    if (purpose.toLowerCase().contains('rent')) {
      return '₨ $short/mo';
    }
    return '₨ $short';
  }

  List<PropertyModel> _filterProperties(List<PropertyModel> all) {
    return all.where((prop) {
      // Filter by purpose
      if (_selectedPurpose != 'All' && prop.purpose != _selectedPurpose) {
        return false;
      }
      // Filter by type
      if (_selectedType != 'All' && prop.propertyType != _selectedType) {
        return false;
      }
      // Filter by radius from map center
      if (_selectedRadiusKm != null) {
        final dist = _calculateDistanceKm(prop.location);
        if (dist > _selectedRadiusKm!) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: Stack(
        children: [
          // Stream of Properties from Firestore with fallback to sample properties
          StreamBuilder<List<PropertyModel>>(
            stream: _propertyService.streamProperties(),
            builder: (context, snapshot) {
              final rawList = snapshot.data ?? [];
              final allProperties = rawList.isNotEmpty
                  ? rawList
                  : PropertyService.sampleProperties;
              final filteredProperties = _filterProperties(allProperties);

              return Stack(
                children: [
                  // 1. Full Screen Interactive Map
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _mapCenter,
                      initialZoom: _currentZoom,
                      minZoom: 4,
                      maxZoom: 18,
                      onTap: (tapPosition, point) {
                        if (_selectedProperty != null) {
                          setState(() => _selectedProperty = null);
                        }
                      },
                      onPositionChanged: (pos, hasGesture) {
                        _mapCenter = pos.center;
                        _currentZoom = pos.zoom;
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.real_estate_app',
                        tileProvider: CancellableNetworkTileProvider(),
                        maxZoom: 19,
                      ),

                      // Markers Layer
                      MarkerLayer(
                        markers: [
                          // User Live GPS Location Pin (Blue Pulse)
                          if (_userLocation != null)
                            Marker(
                              point: _userLocation!,
                              width: 36,
                              height: 36,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFF1A73E8).withValues(alpha: 0.2),
                                    ),
                                  ),
                                  Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFF1A73E8).withValues(alpha: 0.35),
                                    ),
                                  ),
                                  Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFF1A73E8),
                                      border: Border.all(color: Colors.white, width: 2.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF1A73E8).withValues(alpha: 0.45),
                                          blurRadius: 6,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Property Price Pin Markers
                          ...filteredProperties.map((property) {
                            final isSelected =
                                _selectedProperty?.id == property.id &&
                                    property.id.isNotEmpty;
                            final shortPrice = _formatShortPrice(
                              property.price,
                              property.purpose,
                            );

                            return Marker(
                              point: LatLng(
                                property.location.latitude,
                                property.location.longitude,
                              ),
                              width: isSelected ? 120 : 90,
                              height: isSelected ? 56 : 42,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedProperty = property;
                                  });
                                  _moveToLocation(
                                    LatLng(
                                      property.location.latitude,
                                      property.location.longitude,
                                    ),
                                  );
                                },
                                child: _buildPriceMarker(
                                  priceText: shortPrice,
                                  isSelected: isSelected,
                                  property: property,
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ],
                  ),

                  // 2. Top Header & Floating Filter Controls
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: _buildTopOverlay(filteredProperties.length),
                  ),

                  // 3. Floating Right Map Controls (Zoom, Re-center)
                  Positioned(
                    right: 16,
                    bottom: _selectedProperty != null ? 220 : 30,
                    child: _buildFloatingMapControls(),
                  ),

                  // 4. Bottom Floating Property Preview Card
                  if (_selectedProperty != null)
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: _buildPropertyPreviewCard(_selectedProperty!),
                    ),

                  // 5. No properties found banner
                  if (filteredProperties.isEmpty)
                    Positioned(
                      top: 190,
                      left: 20,
                      right: 20,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.darkNavy.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'No properties within ${_selectedRadiusKm != null ? '${_selectedRadiusKm!.round()} km' : 'this area'}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => setState(() => _selectedRadiusKm = null),
                                child: const Text(
                                  'Show All',
                                  style: TextStyle(
                                    color: AppColors.primaryLight,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPriceMarker({
    required String priceText,
    required bool isSelected,
    required PropertyModel property,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: isSelected ? 10 : 8,
            vertical: isSelected ? 6 : 4,
          ),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [AppColors.primaryLight, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? Colors.white : AppColors.primary,
              width: isSelected ? 2 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (isSelected ? AppColors.primary : Colors.black)
                    .withValues(alpha: 0.28),
                blurRadius: isSelected ? 10 : 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.apartment_rounded,
                size: isSelected ? 16 : 12,
                color: isSelected ? Colors.white : AppColors.primary,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  priceText,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isSelected ? 13 : 11,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? Colors.white : AppColors.darkNavy,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Pin pointer triangle
        CustomPaint(
          size: const Size(10, 6),
          painter: _TrianglePainter(
            color: isSelected ? AppColors.primary : Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildTopOverlay(int propertiesCount) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            Colors.white.withValues(alpha: 0.95),
            Colors.white.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.75, 1.0],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Header + Count Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (Navigator.canPop(context))
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 20,
                            color: AppColors.darkNavy,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nearby Properties',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.darkNavy,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'Find real estate around you',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.slateBlue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.place_rounded,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$propertiesCount Listed',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Row 2: City Selector Pills
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _cityCenters.keys.map((city) {
                    final isCitySelected = _selectedCity == city;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(city),
                        selected: isCitySelected,
                        onSelected: (_) => _selectCity(city),
                        selectedColor: AppColors.primary,
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isCitySelected
                              ? Colors.white
                              : AppColors.darkNavy,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isCitySelected
                                ? AppColors.primary
                                : AppColors.borderGrey,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),

              // Row 3: Purpose & Type Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ..._purposeOptions.map((purpose) {
                      final isSelected = _selectedPurpose == purpose;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(purpose),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() {
                              _selectedPurpose = purpose;
                              _selectedProperty = null;
                            });
                          },
                          selectedColor: AppColors.darkNavy,
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.white : AppColors.darkNavy,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.darkNavy
                                  : AppColors.borderGrey,
                            ),
                          ),
                        ),
                      );
                    }),
                    Container(
                      height: 16,
                      width: 1,
                      color: AppColors.borderGrey,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    ..._typeOptions.map((type) {
                      final isSelected = _selectedType == type;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(type),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() {
                              _selectedType = type;
                              _selectedProperty = null;
                            });
                          },
                          selectedColor: AppColors.slateBlue,
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.white : AppColors.darkNavy,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.slateBlue
                                  : AppColors.borderGrey,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Row 3: Radius Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Text(
                      'Radius: ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.slateBlue,
                      ),
                    ),
                    ..._radiusOptions.map((radius) {
                      final isSelected = _selectedRadiusKm == radius;
                      final label = radius == null ? 'All' : '${radius.round()} km';
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          label: Text(label),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() => _selectedRadiusKm = radius);
                          },
                          selectedColor: AppColors.slateBlue.withValues(alpha: 0.15),
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? AppColors.primary : AppColors.slateBlue,
                          ),
                          checkmarkColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.borderGrey,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingMapControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildMapButton(
          icon: Icons.add_rounded,
          onTap: () {
            _moveToLocation(_mapCenter, zoom: _currentZoom + 1);
          },
        ),
        const SizedBox(height: 8),
        _buildMapButton(
          icon: Icons.remove_rounded,
          onTap: () {
            _moveToLocation(_mapCenter, zoom: _currentZoom - 1);
          },
        ),
        const SizedBox(height: 8),
        _buildMapButton(
          icon: Icons.my_location_rounded,
          isLoading: _isLocatingUser,
          highlight: _userLocation != null,
          onTap: () => _determineUserLocation(animateTo: true),
        ),
      ],
    );
  }

  Widget _buildMapButton({
    required IconData icon,
    required VoidCallback onTap,
    bool highlight = false,
    bool isLoading = false,
  }) {
    return Material(
      color: highlight ? AppColors.primary : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: highlight ? AppColors.primary : AppColors.borderGrey,
        ),
      ),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isLoading ? null : onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: isLoading
              ? Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        highlight ? Colors.white : AppColors.primary,
                      ),
                    ),
                  ),
                )
              : Icon(
                  icon,
                  size: 22,
                  color: highlight ? Colors.white : AppColors.darkNavy,
                ),
        ),
      ),
    );
  }

  Widget _buildPropertyPreviewCard(PropertyModel property) {
    final distanceKm = _calculateDistanceKm(property.location);
    final distanceStr = _formatDistance(distanceKm);
    final originSuffix = _userLocation != null ? 'away' : 'from $_selectedCity';
    final priceStr = NumberFormat('#,##,###').format(property.price);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkNavy.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PropertyDetailsScreen(property: property),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 90,
                    height: 90,
                    color: AppColors.scaffoldBg,
                    child: property.images.isNotEmpty
                        ? Image.network(
                            property.images.first,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.apartment_rounded,
                              color: AppColors.silverGrey,
                              size: 32,
                            ),
                          )
                        : const Icon(
                            Icons.apartment_rounded,
                            color: AppColors.silverGrey,
                            size: 32,
                          ),
                  ),
                ),
                const SizedBox(width: 12),

                // Property Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Purpose Badge & Distance
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: property.purpose == 'For Sale'
                                  ? AppColors.primary.withValues(alpha: 0.12)
                                  : AppColors.slateBlue.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              property.purpose,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: property.purpose == 'For Sale'
                                    ? AppColors.primary
                                    : AppColors.slateBlue,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.near_me_rounded,
                                  size: 11,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '$distanceStr $originSuffix',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Price
                      Text(
                        '₨ $priceStr${property.purpose.contains('Rent') ? ' /mo' : ''}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.darkNavy,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),

                      // Title
                      Text(
                        property.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkNavy,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Specs Row (Bed, Bath, Area)
                      Row(
                        children: [
                          if (property.bedrooms > 0) ...[
                            const Icon(
                              Icons.bed_outlined,
                              size: 13,
                              color: AppColors.slateBlue,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${property.bedrooms}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.slateBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (property.bathrooms > 0) ...[
                            const Icon(
                              Icons.bathtub_outlined,
                              size: 13,
                              color: AppColors.slateBlue,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${property.bathrooms}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.slateBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          const Icon(
                            Icons.square_foot_rounded,
                            size: 13,
                            color: AppColors.slateBlue,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${property.area.round()} ${property.areaUnit}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.slateBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Close Button
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  color: AppColors.silverGrey,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    setState(() => _selectedProperty = null);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;

  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter oldDelegate) =>
      color != oldDelegate.color;
}
