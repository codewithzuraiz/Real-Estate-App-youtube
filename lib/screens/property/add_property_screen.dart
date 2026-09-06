import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/property_model.dart';
import '../../services/property_service.dart';
import '../../services/user_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_snackbar.dart';
import '../../widgets/custom_text_field.dart';
import 'map_location_picker_screen.dart';

class AddPropertyScreen extends StatefulWidget {
  final VoidCallback? onSuccess;
  final bool isEmbeddedInTab;
  final PropertyModel? propertyToEdit;

  const AddPropertyScreen({
    super.key,
    this.onSuccess,
    this.isEmbeddedInTab = false,
    this.propertyToEdit,
  });

  bool get isEditing => propertyToEdit != null;

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _propertyService = PropertyService();

  // Basic Info Controllers
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _videoUrlController = TextEditingController();

  // Location Controllers
  final _addressController = TextEditingController();
  final _areaNameController = TextEditingController();
  final _cityController = TextEditingController(text: 'Lahore');
  final _latController = TextEditingController(text: '31.5204');
  final _lngController = TextEditingController(text: '74.3587');

  // Specs & Units
  final _areaController = TextEditingController();
  final _bedroomsController = TextEditingController(text: '3');
  final _bathroomsController = TextEditingController(text: '3');

  // Agent Info Controllers
  final _agentNameController = TextEditingController();
  final _agentAgencyController = TextEditingController(text: 'Premier Real Estate');
  final _agentPhoneController = TextEditingController();
  final _agentEmailController = TextEditingController();

  // Image URLs List
  final _imageUrlInputController = TextEditingController();
  final List<String> _imageUrls = [];

  // Dropdowns & Selections
  String _purpose = 'For Sale';
  String _propertyType = 'House / Villa';
  String _areaUnit = 'Marla';
  bool _isFeatured = false;
  bool _isLoading = false;

  final List<String> _purposes = ['For Sale', 'For Rent'];
  final List<String> _propertyTypes = [
    'House / Villa',
    'Apartment',
    'Penthouse',
    'Commercial',
    'Plot',
    'Farmhouse',
    'Office',
  ];
  final List<String> _areaUnits = ['Marla', 'Kanal', 'Sq Ft', 'Sq Yd', 'Sq M'];

  final List<String> _availableAmenities = [
    '24/7 Security & CCTV',
    'Covered Car Parking',
    'Swimming Pool',
    'Gym & Fitness Center',
    'Central Air Conditioning',
    'Lawn / Landscaped Garden',
    'Solar / Power Backup',
    'High-Speed Internet',
    'Private Balcony',
    'Fully Furnished',
    'Passenger Elevator',
    'Servant Quarter',
  ];
  final Set<String> _selectedAmenities = {};

  @override
  void initState() {
    super.initState();
    if (widget.propertyToEdit != null) {
      _populateEditData(widget.propertyToEdit!);
    } else {
      _fillDefaultAgentData();
    }
  }

  void _populateEditData(PropertyModel p) {
    _titleController.text = p.title;
    _priceController.text = p.price > 0 ? p.price.toStringAsFixed(0) : '';
    _descriptionController.text = p.description;
    _videoUrlController.text = p.videoUrl ?? '';
    _addressController.text = p.location.address;
    _areaNameController.text = p.location.areaName;
    _cityController.text = p.location.city;
    _latController.text = p.location.latitude.toString();
    _lngController.text = p.location.longitude.toString();
    _areaController.text = p.area > 0 ? p.area.toString() : '';
    _bedroomsController.text = p.bedrooms.toString();
    _bathroomsController.text = p.bathrooms.toString();
    _agentNameController.text = p.agent.name;
    _agentAgencyController.text = p.agent.agency;
    _agentPhoneController.text = p.agent.phone;
    _agentEmailController.text = p.agent.email;
    _purpose = p.purpose;
    _propertyType = p.propertyType;
    _areaUnit = p.areaUnit;
    _isFeatured = p.isFeatured;
    _imageUrls.addAll(p.images);
    _selectedAmenities.addAll(p.amenities);
  }

  void _fillDefaultAgentData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _agentNameController.text = user.displayName ?? 'Real Estate Agent';
      _agentEmailController.text = user.email ?? '';
      _agentPhoneController.text = user.phoneNumber ?? '+92 300 1234567';
    } else {
      _agentNameController.text = 'Shahid Khan';
      _agentEmailController.text = 'shahid.khan@realestate.pk';
      _agentPhoneController.text = '+92 300 9876543';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _videoUrlController.dispose();
    _addressController.dispose();
    _areaNameController.dispose();
    _cityController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _areaController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    _agentNameController.dispose();
    _agentAgencyController.dispose();
    _agentPhoneController.dispose();
    _agentEmailController.dispose();
    _imageUrlInputController.dispose();
    super.dispose();
  }

  void _addImageUrl() {
    final url = _imageUrlInputController.text.trim();
    if (url.isEmpty) return;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      CustomSnackBar.showWarning(context, 'Please enter a valid image URL (http/https)');
      return;
    }

    setState(() {
      _imageUrls.add(url);
      _imageUrlInputController.clear();
    });
  }

  void _removeImageUrl(int index) {
    setState(() {
      _imageUrls.removeAt(index);
    });
  }

  Future<void> _pickLocationOnMap() async {
    final double currentLat = double.tryParse(_latController.text.trim()) ?? 31.5204;
    final double currentLng = double.tryParse(_lngController.text.trim()) ?? 74.3587;
    final String currentCity = _cityController.text.trim().isNotEmpty ? _cityController.text.trim() : 'Lahore';

    final result = await Navigator.push<SelectedLocationResult>(
      context,
      MaterialPageRoute(
        builder: (context) => MapLocationPickerScreen(
          initialLat: currentLat,
          initialLng: currentLng,
          initialCity: currentCity,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _addressController.text = result.address;
        _areaNameController.text = result.areaName;
        _cityController.text = result.city;
        _latController.text = result.latitude.toStringAsFixed(6);
        _lngController.text = result.longitude.toStringAsFixed(6);
      });
      if (mounted) {
        CustomSnackBar.showSuccess(context, 'Location updated from Map!');
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_imageUrls.isEmpty) {
      _imageUrls.add('https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=1200&q=80');
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (!widget.isEditing && user != null) {
        final userModel = await UserService().getUser(user.uid);
        if (userModel != null && !userModel.isSeller) {
          if (mounted) {
            CustomSnackBar.showError(
              context,
              'Buyer accounts cannot post listings. Please switch your role to Seller in your profile.',
            );
          }
          return;
        }
      }

      final agent = AgentModel(
        id: user?.uid ?? 'agent_manual',
        name: _agentNameController.text.trim(),
        agency: _agentAgencyController.text.trim(),
        phone: _agentPhoneController.text.trim(),
        email: _agentEmailController.text.trim(),
        avatarUrl: user?.photoURL ?? '',
        isVerified: true,
        rating: 5.0,
        reviewsCount: 1,
      );

      final location = PropertyLocation(
        address: _addressController.text.trim(),
        areaName: _areaNameController.text.trim(),
        city: _cityController.text.trim(),
        latitude: double.tryParse(_latController.text.trim()) ?? 31.5204,
        longitude: double.tryParse(_lngController.text.trim()) ?? 74.3587,
      );

      final isEditing = widget.isEditing;
      final property = PropertyModel(
        id: isEditing ? widget.propertyToEdit!.id : '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.tryParse(_priceController.text.trim()) ?? 0.0,
        currency: 'PKR',
        purpose: _purpose,
        propertyType: _propertyType,
        images: _imageUrls,
        videoUrl: _videoUrlController.text.trim().isNotEmpty ? _videoUrlController.text.trim() : null,
        location: location,
        area: double.tryParse(_areaController.text.trim()) ?? 0.0,
        areaUnit: _areaUnit,
        bedrooms: int.tryParse(_bedroomsController.text.trim()) ?? 0,
        bathrooms: int.tryParse(_bathroomsController.text.trim()) ?? 0,
        amenities: _selectedAmenities.toList(),
        agent: agent,
        sellerId: user?.uid ?? (isEditing ? widget.propertyToEdit!.sellerId : ''),
        status: isEditing ? widget.propertyToEdit!.status : 'Active',
        isFeatured: _isFeatured,
        createdAt: isEditing ? widget.propertyToEdit!.createdAt : DateTime.now(),
      );

      if (isEditing) {
        await _propertyService.updateProperty(property);
      } else {
        await _propertyService.addProperty(property);
      }

      if (mounted) {
        CustomSnackBar.showSuccess(
          context,
          isEditing ? 'Property updated successfully!' : 'Property listed successfully!',
        );
        _titleController.clear();
        _priceController.clear();
        _descriptionController.clear();
        _videoUrlController.clear();
        _imageUrls.clear();

        if (widget.onSuccess != null) {
          widget.onSuccess!();
        } else if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(context, 'Failed to save property: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Property Listing' : 'Add Property Listing'),
        automaticallyImplyLeading: !widget.isEmbeddedInTab,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // 1. Basic Info Section
            _buildSectionCard(
              title: '1. Basic Information',
              children: [
                // Purpose Selector
                const Text(
                  'Purpose',
                  style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.darkNavy, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: _purposes.map((p) {
                    final isSel = _purpose == p;
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: OutlinedButton(
                          onPressed: () => setState(() => _purpose = p),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: isSel ? AppColors.primary : Colors.white,
                            foregroundColor: isSel ? Colors.white : AppColors.darkNavy,
                            side: BorderSide(
                              color: isSel ? AppColors.primary : AppColors.borderGrey,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            p,
                            style: TextStyle(fontWeight: isSel ? FontWeight.w800 : FontWeight.w600),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Property Title
                CustomTextField(
                  controller: _titleController,
                  label: 'Property Title',
                  hint: 'e.g. Modern 1 Kanal Luxury Villa in DHA Phase 6',
                  prefixIcon: Icons.home_work_outlined,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Please enter title' : null,
                ),
                const SizedBox(height: 16),

                // Property Type Dropdown
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Property Type',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkNavy),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _propertyType,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.category_outlined, color: AppColors.slateBlue),
                      ),
                      items: _propertyTypes
                          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _propertyType = v);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Price (PKR)
                CustomTextField(
                  controller: _priceController,
                  label: 'Price (PKR)',
                  hint: 'e.g. 45000000',
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.payments_outlined,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Please enter price';
                    if (double.tryParse(v.trim()) == null) return 'Enter a valid number';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Description
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Description',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkNavy),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Detail highlights, architectural design, finishes, location benefits...',
                        alignLabelWithHint: true,
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Please enter description' : null,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 2. Area & Room Specs Section
            _buildSectionCard(
              title: '2. Area & Specifications',
              children: [
                // Area & Unit Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: CustomTextField(
                        controller: _areaController,
                        label: 'Area Size',
                        hint: 'e.g. 10 or 2500',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        prefixIcon: Icons.aspect_ratio_rounded,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Enter area';
                          if (double.tryParse(v.trim()) == null) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Unit',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkNavy),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: _areaUnit,
                            items: _areaUnits
                                .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _areaUnit = v);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Bedrooms & Bathrooms Row
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _bedroomsController,
                        label: 'Bedrooms',
                        hint: 'e.g. 4',
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.king_bed_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        controller: _bathroomsController,
                        label: 'Bathrooms',
                        hint: 'e.g. 5',
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.bathtub_outlined,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 3. Location & Map Coordinates
            _buildSectionCard(
              title: '3. Location & Map',
              children: [
                // Interactive Map Picker Trigger Button
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.08),
                        AppColors.primaryLight.withValues(alpha: 0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.35), width: 1.5),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _pickLocationOnMap,
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.map_rounded, color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Select Location on Map',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.darkNavy,
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Tap to open map & auto-fill address & coordinates',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.slateBlue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                CustomTextField(
                  controller: _addressController,
                  label: 'Street Address',
                  hint: 'e.g. Sector K, Phase 6',
                  prefixIcon: Icons.location_on_outlined,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter address' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _areaNameController,
                        label: 'Area / Society',
                        hint: 'e.g. DHA Defence',
                        prefixIcon: Icons.map_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        controller: _cityController,
                        label: 'City',
                        hint: 'e.g. Lahore',
                        prefixIcon: Icons.location_city_outlined,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Enter city' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _latController,
                        label: 'Latitude',
                        hint: '31.5204',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        controller: _lngController,
                        label: 'Longitude',
                        hint: '74.3587',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 4. Media (Images & Video)
            _buildSectionCard(
              title: '4. Property Images & Video',
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _imageUrlInputController,
                        label: 'Add Image URL',
                        hint: 'https://images.unsplash.com/...',
                        prefixIcon: Icons.add_photo_alternate_outlined,
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _addImageUrl,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkNavy,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Icon(Icons.add_rounded, color: Colors.white),
                    ),
                  ],
                ),
                if (_imageUrls.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 90,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _imageUrls.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            Container(
                              width: 90,
                              height: 90,
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                image: DecorationImage(
                                  image: NetworkImage(_imageUrls[index]),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 14,
                              child: GestureDetector(
                                onTap: () => _removeImageUrl(index),
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: AppColors.error,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _videoUrlController,
                  label: 'Video Walkthrough URL (Optional)',
                  hint: 'e.g. YouTube or Video link',
                  prefixIcon: Icons.videocam_outlined,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 5. Amenities Checkboxes
            _buildSectionCard(
              title: '5. Amenities & Facilities',
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableAmenities.map((amenity) {
                    final isSel = _selectedAmenities.contains(amenity);
                    return FilterChip(
                      label: Text(amenity),
                      selected: isSel,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedAmenities.add(amenity);
                          } else {
                            _selectedAmenities.remove(amenity);
                          }
                        });
                      },
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.scaffoldBg,
                      labelStyle: TextStyle(
                        color: isSel ? Colors.white : AppColors.darkNavy,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      checkmarkColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: isSel ? AppColors.primary : AppColors.borderGrey),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 6. Agent Contact Information
            _buildSectionCard(
              title: '6. Agent Contact Information',
              children: [
                CustomTextField(
                  controller: _agentNameController,
                  label: 'Agent Full Name',
                  hint: 'e.g. Ali Raza',
                  prefixIcon: Icons.person_outline_rounded,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter agent name' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _agentAgencyController,
                  label: 'Agency / Brokerage',
                  hint: 'e.g. Premier Estate Group',
                  prefixIcon: Icons.business_outlined,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _agentPhoneController,
                  label: 'Agent Phone / WhatsApp',
                  hint: '+92 300 1234567',
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter phone number' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _agentEmailController,
                  label: 'Agent Email',
                  hint: 'agent@premierestates.pk',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Featured Switch
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.darkNavy.withValues(alpha: 0.04),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: AppColors.primary,
                    title: const Text(
                      'Mark as Featured Listing',
                      style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.darkNavy),
                    ),
                    subtitle: const Text(
                      'Highlight this property on the home screen carousel',
                      style: TextStyle(fontSize: 12, color: AppColors.slateBlue),
                    ),
                    value: _isFeatured,
                    onChanged: (val) => setState(() => _isFeatured = val),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            CustomButton(
              text: widget.isEditing ? 'Update Property Listing' : 'Publish Property Listing',
              icon: Icons.check_circle_outline_rounded,
              isLoading: _isLoading,
              onPressed: _handleSubmit,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkNavy.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.darkNavy,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
