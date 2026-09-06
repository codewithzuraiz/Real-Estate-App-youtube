import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class FilterCriteria {
  final String purpose;
  final String propertyType;
  final String areaUnit;
  final double? minPrice;
  final double? maxPrice;
  final int? minBedrooms;

  const FilterCriteria({
    this.purpose = 'All',
    this.propertyType = 'All',
    this.areaUnit = 'All',
    this.minPrice,
    this.maxPrice,
    this.minBedrooms,
  });

  FilterCriteria copyWith({
    String? purpose,
    String? propertyType,
    String? areaUnit,
    double? minPrice,
    double? maxPrice,
    int? minBedrooms,
  }) {
    return FilterCriteria(
      purpose: purpose ?? this.purpose,
      propertyType: propertyType ?? this.propertyType,
      areaUnit: areaUnit ?? this.areaUnit,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      minBedrooms: minBedrooms ?? this.minBedrooms,
    );
  }

  bool get hasActiveFilters =>
      purpose != 'All' ||
      propertyType != 'All' ||
      areaUnit != 'All' ||
      minPrice != null ||
      maxPrice != null ||
      (minBedrooms != null && minBedrooms! > 0);
}

class FilterBottomSheet extends StatefulWidget {
  final FilterCriteria initialCriteria;
  final ValueChanged<FilterCriteria> onApply;

  const FilterBottomSheet({
    super.key,
    required this.initialCriteria,
    required this.onApply,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late String _selectedPurpose;
  late String _selectedType;
  late String _selectedAreaUnit;
  late int? _selectedBedrooms;
  late TextEditingController _minPriceController;
  late TextEditingController _maxPriceController;

  final List<String> _purposes = ['All', 'For Sale', 'For Rent'];
  final List<String> _propertyTypes = [
    'All',
    'House / Villa',
    'Apartment',
    'Penthouse',
    'Commercial',
    'Plot',
    'Farmhouse',
    'Office',
  ];
  final List<String> _areaUnits = ['All', 'Marla', 'Kanal', 'Sq Ft', 'Sq Yd'];
  final List<int> _bedroomsList = [0, 1, 2, 3, 4, 5];

  @override
  void initState() {
    super.initState();
    _selectedPurpose = widget.initialCriteria.purpose;
    _selectedType = widget.initialCriteria.propertyType;
    _selectedAreaUnit = widget.initialCriteria.areaUnit;
    _selectedBedrooms = widget.initialCriteria.minBedrooms;
    _minPriceController = TextEditingController(
      text: widget.initialCriteria.minPrice != null
          ? widget.initialCriteria.minPrice!.toInt().toString()
          : '',
    );
    _maxPriceController = TextEditingController(
      text: widget.initialCriteria.maxPrice != null
          ? widget.initialCriteria.maxPrice!.toInt().toString()
          : '',
    );
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _handleReset() {
    setState(() {
      _selectedPurpose = 'All';
      _selectedType = 'All';
      _selectedAreaUnit = 'All';
      _selectedBedrooms = null;
      _minPriceController.clear();
      _maxPriceController.clear();
    });
  }

  void _handleApply() {
    final minP = double.tryParse(_minPriceController.text.trim());
    final maxP = double.tryParse(_maxPriceController.text.trim());

    final criteria = FilterCriteria(
      purpose: _selectedPurpose,
      propertyType: _selectedType,
      areaUnit: _selectedAreaUnit,
      minPrice: minP,
      maxPrice: maxP,
      minBedrooms: (_selectedBedrooms != null && _selectedBedrooms! > 0)
          ? _selectedBedrooms
          : null,
    );

    widget.onApply(criteria);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderGrey,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filter Properties',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkNavy,
                  ),
                ),
                TextButton(
                  onPressed: _handleReset,
                  child: const Text(
                    'Reset All',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24, color: AppColors.borderGrey),

            // Purpose (Buy / Rent)
            _buildSectionTitle('Purpose'),
            Wrap(
              spacing: 8,
              children: _purposes.map((purpose) {
                final isSelected = _selectedPurpose == purpose;
                return ChoiceChip(
                  label: Text(purpose),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedPurpose = purpose);
                  },
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.scaffoldBg,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.darkNavy,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.borderGrey,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Property Type
            _buildSectionTitle('Property Type'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _propertyTypes.map((type) {
                final isSelected = _selectedType == type;
                return ChoiceChip(
                  label: Text(type),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedType = type);
                  },
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.scaffoldBg,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.darkNavy,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.borderGrey,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Area Unit
            _buildSectionTitle('Area Unit'),
            Wrap(
              spacing: 8,
              children: _areaUnits.map((unit) {
                final isSelected = _selectedAreaUnit == unit;
                return ChoiceChip(
                  label: Text(unit),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedAreaUnit = unit);
                  },
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.scaffoldBg,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.darkNavy,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.borderGrey,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Bedrooms
            _buildSectionTitle('Minimum Bedrooms'),
            Wrap(
              spacing: 8,
              children: _bedroomsList.map((bed) {
                final isSelected = (_selectedBedrooms ?? 0) == bed;
                return ChoiceChip(
                  label: Text(bed == 0 ? 'Any' : '$bed+ Beds'),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedBedrooms = bed == 0 ? null : bed);
                    }
                  },
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.scaffoldBg,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.darkNavy,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.borderGrey,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Price Range (PKR)
            _buildSectionTitle('Price Range (PKR)'),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minPriceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Min Price',
                      prefixText: 'PKR ',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _maxPriceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Max Price',
                      prefixText: 'PKR ',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Apply Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _handleApply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text(
                  'Apply Filters',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.darkNavy,
        ),
      ),
    );
  }
}
