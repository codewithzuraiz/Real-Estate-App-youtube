import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../../config/app_theme.dart';

class SelectedLocationResult {
  final String address;
  final String areaName;
  final String city;
  final double latitude;
  final double longitude;

  const SelectedLocationResult({
    required this.address,
    required this.areaName,
    required this.city,
    required this.latitude,
    required this.longitude,
  });
}

class MapLocationPickerScreen extends StatefulWidget {
  final double initialLat;
  final double initialLng;
  final String initialCity;

  const MapLocationPickerScreen({
    super.key,
    this.initialLat = 31.5204, // Default Lahore
    this.initialLng = 74.3587,
    this.initialCity = 'Lahore',
  });

  @override
  State<MapLocationPickerScreen> createState() => _MapLocationPickerScreenState();
}

class _MapLocationPickerScreenState extends State<MapLocationPickerScreen> {
  late final MapController _mapController;
  late LatLng _selectedPosition;
  double _currentZoom = 14.0;

  String _detectedAddress = 'Loading address...';
  String _detectedArea = '';
  String _detectedCity = 'Lahore';
  bool _isGeocoding = false;
  Timer? _debounceTimer;

  final TextEditingController _searchController = TextEditingController();

  // Popular Pakistani City / Society Presets
  final List<Map<String, dynamic>> _quickLocations = [
    {
      'name': 'DHA Phase 6, Lahore',
      'lat': 31.4720,
      'lng': 74.4312,
      'city': 'Lahore',
      'area': 'DHA Phase 6',
    },
    {
      'name': 'Gulberg III, Lahore',
      'lat': 31.5168,
      'lng': 74.3436,
      'city': 'Lahore',
      'area': 'Gulberg III',
    },
    {
      'name': 'Bahria Town, Lahore',
      'lat': 31.3686,
      'lng': 74.1842,
      'city': 'Lahore',
      'area': 'Bahria Town',
    },
    {
      'name': 'Sector F-11, Islamabad',
      'lat': 33.6844,
      'lng': 73.0479,
      'city': 'Islamabad',
      'area': 'Sector F-11',
    },
    {
      'name': 'DHA Phase 5, Karachi',
      'lat': 24.7890,
      'lng': 67.0650,
      'city': 'Karachi',
      'area': 'DHA Phase 5',
    },
  ];

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _selectedPosition = LatLng(widget.initialLat, widget.initialLng);
    _detectedCity = widget.initialCity;
    _reverseGeocode(_selectedPosition);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    if (hasGesture) {
      _selectedPosition = camera.center;
      _currentZoom = camera.zoom;

      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 600), () {
        _reverseGeocode(_selectedPosition);
      });
    }
  }

  Future<void> _reverseGeocode(LatLng pos) async {
    if (!mounted) return;
    setState(() => _isGeocoding = true);

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${pos.latitude}&lon=${pos.longitude}&zoom=18&addressdetails=1',
      );
      final response = await http.get(url, headers: {
        'User-Agent': 'RealEstateAppFlutter/1.0',
      }).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final addressMap = data['address'] as Map<String, dynamic>? ?? {};

        final road = addressMap['road'] ?? addressMap['street'] ?? addressMap['pedestrian'] ?? '';
        final suburb = addressMap['suburb'] ?? addressMap['neighbourhood'] ?? addressMap['residential'] ?? '';
        final city = addressMap['city'] ?? addressMap['town'] ?? addressMap['county'] ?? addressMap['state_district'] ?? 'Lahore';

        String street = road.isNotEmpty ? road : (data['display_name']?.toString().split(',').first ?? 'Selected Location');
        String area = suburb.isNotEmpty ? suburb : (data['display_name']?.toString().split(',').take(2).join(',') ?? '');

        if (mounted) {
          setState(() {
            _detectedAddress = street;
            _detectedArea = area.isNotEmpty ? area : 'Selected Area';
            _detectedCity = city;
          });
        }
      } else {
        _fallbackAddress(pos);
      }
    } catch (_) {
      _fallbackAddress(pos);
    } finally {
      if (mounted) setState(() => _isGeocoding = false);
    }
  }

  void _fallbackAddress(LatLng pos) {
    if (!mounted) return;
    setState(() {
      _detectedAddress = 'Near ${_detectedArea.isNotEmpty ? _detectedArea : "Coordinates"} (${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)})';
      if (_detectedArea.isEmpty) _detectedArea = 'Selected Zone';
    });
  }

  void _animateToLocation(double lat, double lng, {String? area, String? city}) {
    final target = LatLng(lat, lng);
    setState(() {
      _selectedPosition = target;
      if (area != null) _detectedArea = area;
      if (city != null) _detectedCity = city;
    });
    _mapController.move(target, 15.0);
    _reverseGeocode(target);
  }

  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _isGeocoding = true);

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent('$query, Pakistan')}&limit=1',
      );
      final response = await http.get(url, headers: {
        'User-Agent': 'RealEstateAppFlutter/1.0',
      }).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List results = json.decode(response.body);
        if (results.isNotEmpty) {
          final first = results.first;
          final lat = double.parse(first['lat']);
          final lon = double.parse(first['lon']);
          _animateToLocation(lat, lon);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location not found. Please try another search.')),
            );
          }
        }
      }
    } catch (_) {
      // Ignored fallback
    } finally {
      if (mounted) setState(() => _isGeocoding = false);
    }
  }

  void _confirmSelection() {
    final result = SelectedLocationResult(
      address: _detectedAddress.isNotEmpty ? _detectedAddress : 'Selected Location',
      areaName: _detectedArea.isNotEmpty ? _detectedArea : 'Prime Society',
      city: _detectedCity.isNotEmpty ? _detectedCity : 'Lahore',
      latitude: _selectedPosition.latitude,
      longitude: _selectedPosition.longitude,
    );

    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Pick Property Location'),
        actions: [
          TextButton.icon(
            onPressed: _confirmSelection,
            icon: const Icon(Icons.check_rounded, color: AppColors.primary),
            label: const Text(
              'Done',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Flutter OpenStreetMap Tile Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedPosition,
              initialZoom: _currentZoom,
              minZoom: 4,
              maxZoom: 18,
              onPositionChanged: _onPositionChanged,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.real_estate_app',
                maxZoom: 19,
              ),
            ],
          ),

          // 2. Fixed Center Pin Marker with Animation
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40), // Pin tip sits on center
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Floating Tooltip Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.darkNavy.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      _isGeocoding ? 'Detecting address...' : 'Move map to place pin',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Pin Icon
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withValues(alpha: 0.25),
                        ),
                      ),
                      const Icon(
                        Icons.location_on_rounded,
                        color: AppColors.primary,
                        size: 42,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 3. Top Search Bar & Preset Societies Chips
          Positioned(
            top: 14,
            left: 16,
            right: 16,
            child: Column(
              children: [
                // Search Field Container
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.darkNavy.withValues(alpha: 0.1),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: _searchLocation,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search society, area or city...',
                      hintStyle: const TextStyle(fontSize: 13, color: AppColors.slateBlue),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.arrow_forward_rounded, color: AppColors.primary),
                        onPressed: () => _searchLocation(_searchController.text),
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Quick Preset Chips
                SizedBox(
                  height: 34,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _quickLocations.length,
                    itemBuilder: (context, index) {
                      final item = _quickLocations[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          avatar: const Icon(Icons.near_me_rounded, size: 14, color: AppColors.primary),
                          label: Text(item['name']),
                          backgroundColor: Colors.white.withValues(alpha: 0.95),
                          labelStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkNavy,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: AppColors.borderGrey),
                          ),
                          onPressed: () {
                            _animateToLocation(
                              item['lat'],
                              item['lng'],
                              area: item['area'],
                              city: item['city'],
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // 4. Map Zoom Controls (+ / -)
          Positioned(
            right: 16,
            bottom: 220,
            child: Column(
              children: [
                _buildMapControl(
                  icon: Icons.add_rounded,
                  onTap: () {
                    _mapController.move(_selectedPosition, _mapController.camera.zoom + 1);
                  },
                ),
                const SizedBox(height: 8),
                _buildMapControl(
                  icon: Icons.remove_rounded,
                  onTap: () {
                    _mapController.move(_selectedPosition, _mapController.camera.zoom - 1);
                  },
                ),
              ],
            ),
          ),

          // 5. Bottom Selected Location Details Card & Confirm Button
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.darkNavy.withValues(alpha: 0.12),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Coordinates Tag
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.pin_drop_rounded, color: AppColors.primary, size: 20),
                          SizedBox(width: 6),
                          Text(
                            'Selected Location',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.darkNavy,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.scaffoldBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.borderGrey),
                        ),
                        child: Text(
                          '${_selectedPosition.latitude.toStringAsFixed(4)}, ${_selectedPosition.longitude.toStringAsFixed(4)}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.slateBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Detected Address
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.home_outlined, size: 18, color: AppColors.slateBlue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _detectedAddress,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.darkNavy,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_detectedArea.isNotEmpty ? "$_detectedArea, " : ""}$_detectedCity, Pakistan',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.slateBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Confirm Location Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _confirmSelection,
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                      label: const Text(
                        'Confirm This Location',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapControl({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      shadowColor: Colors.black26,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: AppColors.darkNavy, size: 22),
        ),
      ),
    );
  }
}
