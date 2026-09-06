import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/property_model.dart';
import '../services/property_compare_service.dart';
import '../services/property_service.dart';
import 'custom_snackbar.dart';

class PropertyPickerBottomSheet extends StatefulWidget {
  final String? preferredArea;

  const PropertyPickerBottomSheet({
    super.key,
    this.preferredArea,
  });

  @override
  State<PropertyPickerBottomSheet> createState() => _PropertyPickerBottomSheetState();
}

class _PropertyPickerBottomSheetState extends State<PropertyPickerBottomSheet> {
  final PropertyService _propertyService = PropertyService();
  final PropertyCompareService _compareService = PropertyCompareService();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    if (widget.preferredArea != null && widget.preferredArea!.isNotEmpty) {
      _selectedFilter = widget.preferredArea!;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderGrey,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 14),

          // Title & Counter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add Property to Compare',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkNavy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Currently comparing ${_compareService.count}/${PropertyCompareService.maxProperties} properties',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.slateBlue,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.darkNavy),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.scaffoldBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderGrey, width: 1.2),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search by title, area (e.g. Malir), city...',
                  hintStyle: const TextStyle(fontSize: 13, color: AppColors.slateBlue),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
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
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Area Filter Quick Chips
          if (widget.preferredArea != null && widget.preferredArea!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoiceChip(
                      label: Text('In ${widget.preferredArea}'),
                      selected: _selectedFilter == widget.preferredArea,
                      onSelected: (sel) {
                        setState(() {
                          _selectedFilter = sel ? widget.preferredArea! : 'All';
                        });
                      },
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.scaffoldBg,
                      labelStyle: TextStyle(
                        color: _selectedFilter == widget.preferredArea ? Colors.white : AppColors.darkNavy,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('All Areas'),
                      selected: _selectedFilter == 'All',
                      onSelected: (sel) {
                        setState(() {
                          _selectedFilter = 'All';
                        });
                      },
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.scaffoldBg,
                      labelStyle: TextStyle(
                        color: _selectedFilter == 'All' ? Colors.white : AppColors.darkNavy,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const Divider(height: 20, color: AppColors.borderGrey),

          // Property List Stream
          Expanded(
            child: StreamBuilder<List<PropertyModel>>(
              stream: _propertyService.streamProperties(
                searchQuery: _searchQuery.isNotEmpty
                    ? _searchQuery
                    : (_selectedFilter != 'All' ? _selectedFilter : null),
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  );
                }

                var list = snapshot.data ?? [];

                // Filter by preferred area if selected
                if (_selectedFilter != 'All' && _searchQuery.isEmpty) {
                  final areaLow = _selectedFilter.toLowerCase();
                  list = list.where((p) {
                    return p.location.areaName.toLowerCase().contains(areaLow) ||
                        p.location.address.toLowerCase().contains(areaLow) ||
                        p.location.city.toLowerCase().contains(areaLow);
                  }).toList();
                }

                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.home_work_outlined, size: 48, color: AppColors.silverGrey.withValues(alpha: 0.7)),
                        const SizedBox(height: 12),
                        const Text(
                          'No properties found',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkNavy),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Try searching with a different area name or keyword',
                          style: TextStyle(fontSize: 13, color: AppColors.slateBlue),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: list.length,
                  separatorBuilder: (context, index) => const Divider(height: 16, color: AppColors.borderGrey),
                  itemBuilder: (context, index) {
                    final prop = list[index];
                    final isAlreadyIn = _compareService.isInCompare(prop.id);

                    return InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        if (isAlreadyIn) {
                          CustomSnackBar.showInfo(context, 'This property is already in comparison');
                          return;
                        }

                        if (_compareService.isFull) {
                          CustomSnackBar.showWarning(context, 'Maximum 4 properties can be compared');
                          return;
                        }

                        _compareService.add(prop);
                        Navigator.pop(context);
                        CustomSnackBar.showSuccess(context, 'Added "${prop.title}" to comparison');
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            // Thumbnail
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                prop.coverImage,
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 72,
                                  height: 72,
                                  color: AppColors.borderGrey,
                                  child: const Icon(Icons.apartment_rounded, color: AppColors.silverGrey),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    prop.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.darkNavy,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on_rounded, size: 13, color: AppColors.primary),
                                      const SizedBox(width: 3),
                                      Expanded(
                                        child: Text(
                                          prop.location.fullAddress,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 12, color: AppColors.slateBlue),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Text(
                                        prop.formattedPrice,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.scaffoldBg,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          prop.formattedArea,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.slateBlue,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Status / Action
                            if (isAlreadyIn)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle_rounded, size: 14, color: AppColors.success),
                                    SizedBox(width: 4),
                                    Text(
                                      'Added',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.success),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.add_rounded, size: 20, color: AppColors.primary),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
