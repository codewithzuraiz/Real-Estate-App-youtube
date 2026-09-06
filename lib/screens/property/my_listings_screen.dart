import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/property_model.dart';
import '../../services/property_service.dart';
import '../../widgets/custom_snackbar.dart';
import 'add_property_screen.dart';
import 'property_details_screen.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  final PropertyService _propertyService = PropertyService();
  final String _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  String _selectedStatusFilter = 'All'; // 'All', 'Active', 'Sold'

  Future<void> _toggleSoldStatus(PropertyModel property) async {
    final newStatus = property.isSold ? 'Active' : 'Sold';
    try {
      await _propertyService.updatePropertyStatus(property.id, newStatus);
      if (mounted) {
        CustomSnackBar.showSuccess(
          context,
          newStatus == 'Sold'
              ? 'Property marked as SOLD! 🎉'
              : 'Property marked as ACTIVE for buyers!',
        );
      }
    } catch (e) {
      if (mounted) CustomSnackBar.showError(context, 'Failed to update status: $e');
    }
  }

  Future<void> _confirmDelete(PropertyModel property) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Listing', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.darkNavy)),
        content: Text('Are you sure you want to permanently delete "${property.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.slateBlue)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await _propertyService.deleteProperty(property.id);
        if (mounted) CustomSnackBar.showSuccess(context, 'Property deleted successfully.');
      } catch (e) {
        if (mounted) CustomSnackBar.showError(context, 'Failed to delete: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text(
          'My Listed Properties',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        actions: [
          IconButton(
            tooltip: 'Add Property',
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddPropertyScreen()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Listing', style: TextStyle(fontWeight: FontWeight.w800)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddPropertyScreen()),
          );
        },
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            color: Colors.white,
            child: Row(
              children: ['All', 'Active', 'Sold'].map((status) {
                final isSelected = _selectedStatusFilter == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(status),
                    selected: isSelected,
                    onSelected: (sel) {
                      if (sel) setState(() => _selectedStatusFilter = status);
                    },
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.scaffoldBg,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.darkNavy,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : AppColors.borderGrey,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1, color: AppColors.borderGrey),

          // Property List
          Expanded(
            child: StreamBuilder<List<PropertyModel>>(
              stream: _propertyService.streamSellerProperties(_currentUid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)),
                  );
                }

                var properties = snapshot.data ?? [];

                // Filter by status
                if (_selectedStatusFilter != 'All') {
                  properties = properties.where((p) {
                    if (_selectedStatusFilter == 'Active') return p.isActive;
                    if (_selectedStatusFilter == 'Sold') return p.isSold;
                    return true;
                  }).toList();
                }

                if (properties.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.storefront_rounded, size: 44, color: AppColors.primary),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            _selectedStatusFilter == 'All'
                                ? 'No Listings Found'
                                : 'No $_selectedStatusFilter Listings',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.darkNavy),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Tap the button below to list your first property and start receiving buyer inquiries.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: AppColors.slateBlue, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
                  itemCount: properties.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final prop = properties[index];
                    return _buildSellerPropertyCard(prop);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerPropertyCard(PropertyModel prop) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderGrey, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkNavy.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: image, details, and status badge
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PropertyDetailsScreen(property: prop)),
              );
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image with SOLD overlay if sold
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          prop.coverImage,
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 90,
                            height: 90,
                            color: AppColors.slateBlue.withValues(alpha: 0.2),
                            child: const Icon(Icons.apartment_rounded, size: 30, color: AppColors.slateBlue),
                          ),
                        ),
                      ),
                      if (prop.isSold)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Center(
                              child: Text(
                                'SOLD',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: prop.isSold
                                    ? AppColors.error.withValues(alpha: 0.12)
                                    : Colors.green.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                prop.isSold ? 'SOLD' : 'ACTIVE',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: prop.isSold ? AppColors.error : Colors.green.shade800,
                                ),
                              ),
                            ),
                            Text(
                              prop.propertyType,
                              style: const TextStyle(fontSize: 11, color: AppColors.slateBlue, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          prop.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.darkNavy),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          prop.location.fullAddress,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11.5, color: AppColors.slateBlue),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              prop.formattedPrice,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '•  ${prop.formattedArea}',
                              style: const TextStyle(fontSize: 12, color: AppColors.slateBlue, fontWeight: FontWeight.w600),
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

          const Divider(height: 1, color: AppColors.borderGrey),

          // Actions Bar: Edit, Mark Sold, Delete
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                // Edit Button
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddPropertyScreen(propertyToEdit: prop),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_rounded, size: 16, color: AppColors.darkNavy),
                  label: const Text('Edit', style: TextStyle(color: AppColors.darkNavy, fontWeight: FontWeight.w700)),
                ),
                const Spacer(),

                // Mark as Sold / Active Toggle
                ElevatedButton.icon(
                  onPressed: () => _toggleSoldStatus(prop),
                  icon: Icon(
                    prop.isSold ? Icons.replay_rounded : Icons.check_circle_rounded,
                    size: 15,
                  ),
                  label: Text(
                    prop.isSold ? 'Mark Active' : 'Mark as Sold',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: prop.isSold ? AppColors.darkNavy : Colors.amber.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
                const SizedBox(width: 6),

                // Delete Button
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.error),
                  onPressed: () => _confirmDelete(prop),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
