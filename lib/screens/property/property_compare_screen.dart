import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_theme.dart';
import '../../models/property_model.dart';
import '../../services/property_compare_service.dart';
import '../../widgets/custom_snackbar.dart';
import '../../widgets/property_picker_bottom_sheet.dart';
import 'property_details_screen.dart';

class PropertyCompareScreen extends StatefulWidget {
  const PropertyCompareScreen({super.key});

  @override
  State<PropertyCompareScreen> createState() => _PropertyCompareScreenState();
}

class _PropertyCompareScreenState extends State<PropertyCompareScreen> {
  final PropertyCompareService _compareService = PropertyCompareService();
  final ScrollController _scrollController = ScrollController();
  bool _differencesOnly = false;
  int _activePropertyTab = 0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToColumn(int index, double columnWidth, double spacing) {
    if (!mounted) return;
    setState(() => _activePropertyTab = index);
    final targetOffset = index * (columnWidth + spacing);
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _openPropertyPicker({String? preferredArea}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PropertyPickerBottomSheet(preferredArea: preferredArea),
    );
  }

  Future<void> _launchCall(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      CustomSnackBar.showError(context, 'Could not make a call to $phone');
    }
  }

  Future<void> _launchWhatsApp(PropertyModel property) async {
    final cleanPhone = property.agent.phone.replaceAll(RegExp(r'[^0-9]'), '');
    final msg = Uri.encodeComponent(
      'Hi ${property.agent.name}, I compared properties on the Real Estate app and have finalized my choice on "${property.title}" (${property.formattedPrice}) in ${property.location.areaName}, ${property.location.city}. I would like to schedule a visit and discuss booking details.',
    );
    final uri = Uri.parse('https://wa.me/$cleanPhone?text=$msg');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (mounted) {
        CustomSnackBar.showError(context, 'Could not open WhatsApp');
      }
    } catch (e) {
      if (mounted) CustomSnackBar.showError(context, 'WhatsApp error: $e');
    }
  }

  Future<void> _launchEmail(PropertyModel property) async {
    final subject = Uri.encodeComponent('Finalized Choice: ${property.title}');
    final body = Uri.encodeComponent(
      'Hello ${property.agent.name},\n\nI have compared multiple listings and decided to finalize "${property.title}" at ${property.location.fullAddress}.\n\nPlease let me know the earliest available slot for an on-site visit and document verification.\n\nThank you.',
    );
    final uri = Uri.parse('mailto:${property.agent.email}?subject=$subject&body=$body');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      CustomSnackBar.showError(context, 'Could not open email app');
    }
  }

  void _showFinalizeSheet(PropertyModel property) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 30),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderGrey,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),

              // Success Icon & Headline
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_rounded,
                  color: AppColors.success,
                  size: 34,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Property Finalized! 🎉',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.darkNavy,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'You have selected this property as your final choice from the comparison. Connect directly with the agent below:',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.slateBlue),
              ),
              const SizedBox(height: 18),

              // Selected Property Summary Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.scaffoldBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.borderGrey, width: 1.2),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        property.coverImage,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 70,
                          height: 70,
                          color: AppColors.borderGrey,
                          child: const Icon(Icons.apartment_rounded, color: AppColors.silverGrey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            property.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.darkNavy,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            property.location.fullAddress,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: AppColors.slateBlue),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                property.formattedPrice,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                property.formattedArea,
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
              const SizedBox(height: 20),

              // WhatsApp Inquire Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _launchWhatsApp(property);
                  },
                  icon: const Icon(Icons.chat_rounded, size: 20),
                  label: const Text(
                    'Chat on WhatsApp with Agent',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Call & Details Row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _launchCall(property.agent.phone);
                      },
                      icon: const Icon(Icons.phone_rounded, size: 18),
                      label: const Text('Call Agent'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.darkNavy,
                        side: const BorderSide(color: AppColors.borderGrey, width: 1.2),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _launchEmail(property);
                      },
                      icon: const Icon(Icons.email_rounded, size: 18),
                      label: const Text('Email'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary, width: 1.2),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // View Full Details Page
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PropertyDetailsScreen(property: property),
                    ),
                  );
                },
                child: const Text(
                  'View Full Property Details Page',
                  style: TextStyle(
                    color: AppColors.slateBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _compareService,
      builder: (context, _) {
        final properties = _compareService.properties;
        final count = properties.length;
        final bestPriceId = _compareService.getBestPriceId();
        final largestAreaId = _compareService.getLargestAreaId();
        final mostBedroomsId = _compareService.getMostBedroomsId();

        // Extract primary area for quick suggestions
        final primaryArea = properties.isNotEmpty ? properties.first.location.areaName : null;

        // Collect all distinct amenities
        final allAmenities = <String>{};
        for (final p in properties) {
          allAmenities.addAll(p.amenities);
        }
        final sortedAmenities = allAmenities.toList()..sort();

        return Scaffold(
          backgroundColor: AppColors.scaffoldBg,
          appBar: AppBar(
            title: Column(
              children: [
                const Text(
                  'Property Comparison',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                ),
                Text(
                  '$count of ${PropertyCompareService.maxProperties} properties',
                  style: const TextStyle(fontSize: 11, color: AppColors.slateBlue, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            actions: [
              if (count < PropertyCompareService.maxProperties)
                IconButton(
                  tooltip: 'Add Property',
                  icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
                  onPressed: () => _openPropertyPicker(preferredArea: primaryArea),
                ),
              if (count > 0)
                TextButton(
                  onPressed: () {
                    _compareService.clear();
                    CustomSnackBar.showInfo(context, 'Cleared comparison list');
                  },
                  child: const Text(
                    'Clear',
                    style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
            ],
          ),
          body: count == 0
              ? _buildEmptyState()
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final screenWidth = constraints.maxWidth;
                    const double horizontalPadding = 16.0;
                    const double cardSpacing = 12.0;

                    // Responsive column width calculation
                    final double columnWidth;
                    final bool isCompactMobile;

                    if (screenWidth >= 900) {
                      // Desktop / Tablet Landscape: Fit evenly
                      final slots = count + (count < PropertyCompareService.maxProperties ? 1 : 0);
                      final calc = (screenWidth - (horizontalPadding * 2) - ((slots - 1) * cardSpacing)) / slots;
                      columnWidth = calc.clamp(230.0, 310.0);
                      isCompactMobile = false;
                    } else if (screenWidth >= 600) {
                      // Tablet Portrait
                      if (count == 2) {
                        columnWidth = (screenWidth - (horizontalPadding * 2) - cardSpacing) / 2;
                      } else {
                        columnWidth = ((screenWidth - (horizontalPadding * 2) - (cardSpacing * 2)) / 3).clamp(200.0, 260.0);
                      }
                      isCompactMobile = false;
                    } else {
                      // Mobile (< 600px)
                      if (count == 2) {
                        // Exactly 2 properties: Fit BOTH side-by-side with zero cut-off!
                        columnWidth = (screenWidth - (horizontalPadding * 2) - cardSpacing) / 2;
                        isCompactMobile = true;
                      } else {
                        // 1, 3, or 4 properties: comfortable width with property selector
                        columnWidth = (screenWidth * 0.74).clamp(210.0, 260.0);
                        isCompactMobile = false;
                      }
                    }

                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Filter & Notification Bar
                          _buildTopControlBar(
                            count: count,
                            primaryArea: primaryArea,
                            screenWidth: screenWidth,
                          ),

                          // Property Quick Switcher Pills (when 3 or 4 properties are compared)
                          if (count > 2)
                            _buildPropertyQuickTabs(
                              properties: properties,
                              columnWidth: columnWidth,
                              spacing: cardSpacing,
                            ),

                          // Swipe Guide Indicator (when cards extend beyond viewport)
                          if (count > 2 && screenWidth < 700)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.swipe_rounded, size: 15, color: AppColors.slateBlue.withValues(alpha: 0.7)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Swipe horizontally to view all $count properties side-by-side',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.slateBlue.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 8),

                          // Responsive Comparison Matrix Container
                          SingleChildScrollView(
                            controller: _scrollController,
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ...List.generate(properties.length, (index) {
                                  final prop = properties[index];
                                  return Container(
                                    width: columnWidth,
                                    margin: EdgeInsets.only(
                                      right: (index == properties.length - 1 && count >= PropertyCompareService.maxProperties)
                                          ? 0
                                          : cardSpacing,
                                    ),
                                    child: _buildPropertyCardColumn(
                                      property: prop,
                                      columnWidth: columnWidth,
                                      isCompactMobile: isCompactMobile,
                                      isBestPrice: prop.id == bestPriceId,
                                      isLargestArea: prop.id == largestAreaId,
                                      isMostBedrooms: prop.id == mostBedroomsId,
                                      sortedAmenities: sortedAmenities,
                                      properties: properties,
                                    ),
                                  );
                                }),

                                // "+ Add Property" Slot
                                if (count < PropertyCompareService.maxProperties)
                                  Container(
                                    width: isCompactMobile ? columnWidth : 200,
                                    margin: const EdgeInsets.only(left: 4),
                                    child: _buildAddPropertySlot(
                                      preferredArea: primaryArea,
                                      isCompactMobile: isCompactMobile,
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 48),
                        ],
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildTopControlBar({
    required int count,
    required String? primaryArea,
    required double screenWidth,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkNavy.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Area Info / Comparison Status
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.location_city_rounded, size: 16, color: AppColors.primary),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        primaryArea != null && primaryArea.isNotEmpty ? primaryArea : 'Multiple Areas',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.darkNavy,
                        ),
                      ),
                      Text(
                        count == 2
                            ? '2 properties fitted side-by-side'
                            : '$count properties normalized to Sq Ft',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: AppColors.slateBlue),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Differences Only Filter Switch
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              if (mounted) setState(() => _differencesOnly = !_differencesOnly);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _differencesOnly ? AppColors.primary : AppColors.scaffoldBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _differencesOnly ? AppColors.primary : AppColors.borderGrey,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _differencesOnly ? Icons.filter_alt_rounded : Icons.filter_alt_outlined,
                    size: 13,
                    color: _differencesOnly ? Colors.white : AppColors.slateBlue,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Diffs Only',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _differencesOnly ? Colors.white : AppColors.darkNavy,
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

  Widget _buildPropertyQuickTabs({
    required List<PropertyModel> properties,
    required double columnWidth,
    required double spacing,
  }) {
    return Container(
      height: 38,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: properties.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final prop = properties[index];
          final isSelected = _activePropertyTab == index;

          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _scrollToColumn(index, columnWidth, spacing),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.borderGrey,
                  width: 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      prop.coverImage,
                      width: 20,
                      height: 20,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 20,
                        height: 20,
                        color: AppColors.borderGrey,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 100),
                    child: Text(
                      prop.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.darkNavy,
                      ),
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.compare_arrows_rounded,
                size: 52,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Properties to Compare',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.darkNavy,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select up to 4 properties from the home feed or property details page to compare price, square feet, location, and amenities side-by-side.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.slateBlue, height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _openPropertyPicker(),
              icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
              label: const Text('Add Properties to Compare'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddPropertySlot({
    required String? preferredArea,
    required bool isCompactMobile,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isCompactMobile ? 10 : 16, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.borderGrey,
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: isCompactMobile ? 44 : 52,
            height: isCompactMobile ? 44 : 52,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.add_rounded, size: isCompactMobile ? 26 : 30, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          Text(
            'Add Another Property',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isCompactMobile ? 12 : 14,
              fontWeight: FontWeight.w800,
              color: AppColors.darkNavy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            preferredArea != null ? 'Compare from $preferredArea' : 'Compare up to 4',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: isCompactMobile ? 10 : 11, color: AppColors.slateBlue),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () => _openPropertyPicker(preferredArea: preferredArea),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: EdgeInsets.symmetric(horizontal: isCompactMobile ? 10 : 16, vertical: 8),
            ),
            child: Text('+ Add', style: TextStyle(fontWeight: FontWeight.w700, fontSize: isCompactMobile ? 11 : 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyCardColumn({
    required PropertyModel property,
    required double columnWidth,
    required bool isCompactMobile,
    required bool isBestPrice,
    required bool isLargestArea,
    required bool isMostBedrooms,
    required List<String> sortedAmenities,
    required List<PropertyModel> properties,
  }) {
    final sqFt = PropertyCompareService.normalizeToSqFt(property.area, property.areaUnit);
    final pricePerSqFt = PropertyCompareService.calculatePricePerSqFt(property);
    final imageHeight = isCompactMobile ? 115.0 : 140.0;

    // Filter check helpers
    bool isDifferent(dynamic Function(PropertyModel) accessor) {
      if (!_differencesOnly || properties.length < 2) return true;
      final firstVal = accessor(properties.first);
      return properties.any((p) => accessor(p) != firstVal);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isBestPrice ? AppColors.primary.withValues(alpha: 0.6) : AppColors.borderGrey,
          width: isBestPrice ? 1.8 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkNavy.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Image & Badges
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                child: Image.network(
                  property.coverImage,
                  height: imageHeight,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: imageHeight,
                    color: AppColors.borderGrey,
                    child: const Icon(Icons.apartment_rounded, color: AppColors.silverGrey, size: 36),
                  ),
                ),
              ),

              // Purpose Badge
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: property.purpose == 'For Sale' ? AppColors.primary : AppColors.slateBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    property.purpose.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w800),
                  ),
                ),
              ),

              // Remove Button
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => _compareService.remove(property.id),
                    child: const Padding(
                      padding: EdgeInsets.all(5),
                      child: Icon(Icons.close_rounded, color: Colors.white, size: 14),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Winner Highlights Pill Strip
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            color: (isBestPrice || isLargestArea || isMostBedrooms)
                ? AppColors.primary.withValues(alpha: 0.08)
                : Colors.transparent,
            child: Wrap(
              spacing: 4,
              runSpacing: 3,
              children: [
                if (isBestPrice)
                  _buildWinnerPill('🏆 Best Price', Colors.amber.shade800, isCompactMobile),
                if (isLargestArea)
                  _buildWinnerPill('📐 Largest', const Color(0xFF27AE60), isCompactMobile),
                if (isMostBedrooms)
                  _buildWinnerPill('🛏️ Most Beds', AppColors.primary, isCompactMobile),
              ],
            ),
          ),

          // Title (Fixed height of 40px ensures rows stay 100% aligned!)
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
            child: SizedBox(
              height: isCompactMobile ? 36 : 40,
              child: Text(
                property.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isCompactMobile ? 12 : 13.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.darkNavy,
                  height: 1.25,
                ),
              ),
            ),
          ),

          // Price Tag & Price/Sq Ft
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  property.formattedPrice,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isCompactMobile ? 13.5 : 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  PropertyCompareService.formatPricePerSqFt(pricePerSqFt),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isCompactMobile ? 9.5 : 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slateBlue,
                  ),
                ),
              ],
            ),
          ),

          // Top Finalize Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showFinalizeSheet(property),
                icon: const Icon(Icons.check_circle_rounded, size: 14),
                label: Text(
                  isCompactMobile ? 'Finalize' : 'Finalize Choice',
                  style: TextStyle(fontSize: isCompactMobile ? 11 : 12, fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkNavy,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ),

          const Divider(height: 14, color: AppColors.borderGrey),

          // Area & Dimensions Section
          _buildCategoryHeader('Area & Dimensions', isCompactMobile),
          if (isDifferent((p) => p.area))
            _buildAlignedRow('Listed Area', property.formattedArea, isCompactMobile),
          if (isDifferent((p) => PropertyCompareService.normalizeToSqFt(p.area, p.areaUnit)))
            _buildAlignedRow('Normalized', PropertyCompareService.formatSqFt(sqFt), isCompactMobile, isHighlight: isLargestArea),
          if (isDifferent((p) => p.bedrooms))
            _buildAlignedRow('Bedrooms', property.bedrooms > 0 ? '${property.bedrooms} Beds' : 'N/A', isCompactMobile),
          if (isDifferent((p) => p.bathrooms))
            _buildAlignedRow('Bathrooms', property.bathrooms > 0 ? '${property.bathrooms} Baths' : 'N/A', isCompactMobile),

          const Divider(height: 14, color: AppColors.borderGrey),

          // Location Section
          _buildCategoryHeader('Location & Society', isCompactMobile),
          if (isDifferent((p) => p.location.areaName))
            _buildAlignedRow('Area / Sector', property.location.areaName.isNotEmpty ? property.location.areaName : 'N/A', isCompactMobile),
          if (isDifferent((p) => p.location.city))
            _buildAlignedRow('City', property.location.city.isNotEmpty ? property.location.city : 'N/A', isCompactMobile),
          if (isDifferent((p) => p.location.address))
            _buildAlignedRow('Address', property.location.address.isNotEmpty ? property.location.address : 'N/A', isCompactMobile, maxLines: 2),

          const Divider(height: 14, color: AppColors.borderGrey),

          // Property Type Section
          _buildCategoryHeader('Type & Purpose', isCompactMobile),
          if (isDifferent((p) => p.propertyType))
            _buildAlignedRow('Property Type', property.propertyType, isCompactMobile),
          if (isDifferent((p) => p.purpose))
            _buildAlignedRow('Listing Purpose', property.purpose, isCompactMobile),

          // Amenities Checklist Matrix
          if (sortedAmenities.isNotEmpty) ...[
            const Divider(height: 14, color: AppColors.borderGrey),
            _buildCategoryHeader('Amenities Checklist', isCompactMobile),
            ...sortedAmenities.map((amenity) {
              final hasIt = property.amenities.contains(amenity);
              // If differences only, check if at least one property differs for this amenity
              if (_differencesOnly && properties.length > 1) {
                final allSame = properties.every((p) => p.amenities.contains(amenity) == hasIt);
                if (allSame) return const SizedBox.shrink();
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                child: Row(
                  children: [
                    Icon(
                      hasIt ? Icons.check_circle_rounded : Icons.remove_rounded,
                      size: isCompactMobile ? 13 : 15,
                      color: hasIt ? AppColors.success : AppColors.silverGrey.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        amenity,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: isCompactMobile ? 10 : 11,
                          fontWeight: hasIt ? FontWeight.w700 : FontWeight.w500,
                          color: hasIt ? AppColors.darkNavy : AppColors.silverGrey,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],

          const Divider(height: 14, color: AppColors.borderGrey),

          // Agent & Direct Contact Section
          _buildCategoryHeader('Agent Details', isCompactMobile),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 2, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: isCompactMobile ? 12 : 14,
                      backgroundColor: AppColors.primaryLight,
                      backgroundImage: property.agent.avatarUrl.isNotEmpty ? NetworkImage(property.agent.avatarUrl) : null,
                      child: property.agent.avatarUrl.isEmpty
                          ? Text(
                              property.agent.name.isNotEmpty ? property.agent.name[0] : 'A',
                              style: TextStyle(fontSize: isCompactMobile ? 9 : 11, color: Colors.white, fontWeight: FontWeight.w700),
                            )
                          : null,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            property.agent.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: isCompactMobile ? 10.5 : 11.5, fontWeight: FontWeight.w700, color: AppColors.darkNavy),
                          ),
                          Text(
                            property.agent.agency,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: isCompactMobile ? 9 : 10, color: AppColors.slateBlue),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Contact Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _launchWhatsApp(property),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF25D366),
                          side: const BorderSide(color: Color(0xFF25D366), width: 1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          minimumSize: const Size(0, 30),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.chat_rounded, size: 12),
                            if (!isCompactMobile) ...[
                              const SizedBox(width: 4),
                              const Text('Chat', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700)),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _launchCall(property.agent.phone),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary, width: 1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          minimumSize: const Size(0, 30),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.phone_rounded, size: 12),
                            if (!isCompactMobile) ...[
                              const SizedBox(width: 4),
                              const Text('Call', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700)),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Bottom Finalize Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _showFinalizeSheet(property),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      minimumSize: const Size(0, 28),
                    ),
                    child: Text(
                      'Choose This Home',
                      style: TextStyle(fontSize: isCompactMobile ? 10 : 11, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWinnerPill(String text, Color color, bool isCompactMobile) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isCompactMobile ? 4 : 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: isCompactMobile ? 8.5 : 9.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildCategoryHeader(String title, bool isCompactMobile) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: isCompactMobile ? 9 : 10,
          fontWeight: FontWeight.w800,
          color: AppColors.slateBlue,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildAlignedRow(String label, String value, bool isCompactMobile, {bool isHighlight = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: isCompactMobile ? 9.5 : 10.5, color: AppColors.slateBlue, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 1),
          Text(
            value,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isCompactMobile ? 11 : 12,
              fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w700,
              color: isHighlight ? AppColors.primary : AppColors.darkNavy,
            ),
          ),
        ],
      ),
    );
  }
}
