import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_theme.dart';
import '../../models/property_model.dart';
import '../../models/user_model.dart';
import '../../services/chat_service.dart';
import '../../services/property_service.dart';
import '../../services/property_compare_service.dart';
import '../../services/user_service.dart';
import '../../services/visit_booking_service.dart';
import '../../widgets/custom_snackbar.dart';
import '../../widgets/property_map_widget.dart';
import '../../widgets/schedule_visit_sheet.dart';
import '../chat/chat_screen.dart';
import 'add_property_screen.dart';
import 'property_compare_screen.dart';

class PropertyDetailsScreen extends StatefulWidget {
  final PropertyModel property;

  const PropertyDetailsScreen({
    super.key,
    required this.property,
  });

  @override
  State<PropertyDetailsScreen> createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> {
  final PropertyService _propertyService = PropertyService();
  final PageController _imagePageController = PageController();
  int _currentImageIndex = 0;
  bool _isDescriptionExpanded = false;
  bool _isFavorite = false;
  StreamSubscription<Set<String>>? _favSubscription;

  @override
  void initState() {
    super.initState();
    // Increment view count
    _propertyService.incrementViews(widget.property.id);
    _checkFavoriteStatus();
  }

  void _checkFavoriteStatus() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _favSubscription?.cancel();
      _favSubscription = _propertyService.streamFavoriteIds(user.uid).listen((ids) {
        if (mounted) {
          setState(() {
            _isFavorite = ids.contains(widget.property.id);
          });
        }
      });
    }
  }

  Future<void> _handleToggleFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      CustomSnackBar.showWarning(context, 'Please log in to save properties');
      return;
    }

    final added = await _propertyService.toggleFavorite(user.uid, widget.property.id);
    if (mounted) {
      setState(() => _isFavorite = added);
      if (added) {
        CustomSnackBar.showSuccess(context, 'Property saved to favorites!');
      } else {
        CustomSnackBar.showInfo(context, 'Removed from favorites');
      }
    }
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

  Future<void> _launchWhatsApp(String phone) async {
    // Remove '+' and spaces for WhatsApp API
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final msg = Uri.encodeComponent(
      'Hi ${widget.property.agent.name}, I am interested in your property: "${widget.property.title}" (${widget.property.formattedPrice}) listed in ${widget.property.location.city}. Please share more details.',
    );
    final uri = Uri.parse('https://wa.me/$cleanPhone?text=$msg');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (mounted) {
        CustomSnackBar.showError(context, 'Could not open WhatsApp');
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(context, 'WhatsApp error: $e');
      }
    }
  }

  Future<void> _launchEmail(String email) async {
    final subject = Uri.encodeComponent('Inquiry regarding ${widget.property.title}');
    final body = Uri.encodeComponent(
      'Hello ${widget.property.agent.name},\n\nI would like to inquire about the property "${widget.property.title}" (${widget.property.formattedPrice}) at ${widget.property.location.fullAddress}.\n\nPlease let me know your availability for a visit.\n\nThank you.',
    );
    final uri = Uri.parse('mailto:$email?subject=$subject&body=$body');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      CustomSnackBar.showError(context, 'Could not open email app');
    }
  }

  Future<void> _launchVideoTour(String? url) async {
    if (url == null || url.isEmpty) {
      CustomSnackBar.showInfo(context, 'No video tour link available for this property');
      return;
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      CustomSnackBar.showError(context, 'Could not open video link');
    }
  }

  Future<void> _openInAppChat() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      CustomSnackBar.showWarning(context, 'Please log in to start a chat.');
      return;
    }

    if (user.uid == widget.property.sellerId || user.uid == widget.property.agent.id) {
      CustomSnackBar.showInfo(context, 'This is your own property listing.');
      return;
    }

    try {
      final buyerModel = await UserService().getUser(user.uid) ??
          UserModel(
            uid: user.uid,
            name: user.displayName ?? 'Buyer',
            email: user.email ?? '',
            role: 'Buyer',
            createdAt: DateTime.now(),
          );

      final conversation = await ChatService().getOrCreateConversation(
        property: widget.property,
        buyer: buyerModel,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(conversation: conversation),
          ),
        );
      }
    } catch (e) {
      if (mounted) CustomSnackBar.showError(context, 'Failed to start chat: $e');
    }
  }

  void _openScheduleVisitSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ScheduleVisitBottomSheet(property: widget.property),
    );
  }

  Future<void> _handleToggleSoldStatus() async {
    final newStatus = widget.property.isSold ? 'Active' : 'Sold';
    try {
      await _propertyService.updatePropertyStatus(widget.property.id, newStatus);
      if (mounted) {
        CustomSnackBar.showSuccess(
          context,
          newStatus == 'Sold'
              ? 'Property marked as SOLD! 🎉'
              : 'Property marked as ACTIVE for buyers!',
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) CustomSnackBar.showError(context, 'Failed to update status: $e');
    }
  }

  @override
  void dispose() {
    _favSubscription?.cancel();
    _imagePageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final property = widget.property;
    final images = property.images.isNotEmpty ? property.images : [property.coverImage];
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isOwner = currentUid.isNotEmpty &&
        (property.sellerId == currentUid || property.agent.id == currentUid);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: Stack(
        children: [
          // Scrollable Body Content
          CustomScrollView(
            slivers: [
              // Top Gallery App Bar
              SliverAppBar(
                expandedHeight: 330,
                pinned: true,
                backgroundColor: AppColors.darkNavy,
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleAvatar(
                    backgroundColor: Colors.white.withValues(alpha: 0.9),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: AppColors.darkNavy),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                actions: [
                  // Owner Edit Action Button
                  if (isOwner) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: CircleAvatar(
                        backgroundColor: Colors.white.withValues(alpha: 0.9),
                        child: IconButton(
                          tooltip: 'Edit Listing',
                          icon: const Icon(Icons.edit_rounded, color: AppColors.darkNavy),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddPropertyScreen(propertyToEdit: widget.property),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],

                  // Compare Action Button
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListenableBuilder(
                      listenable: PropertyCompareService(),
                      builder: (context, _) {
                        final compareService = PropertyCompareService();
                        final isCompared = compareService.isInCompare(widget.property.id);

                        return CircleAvatar(
                          backgroundColor: isCompared
                              ? AppColors.primary
                              : Colors.white.withValues(alpha: 0.9),
                          child: IconButton(
                            tooltip: isCompared ? 'Open Comparison' : 'Add to Comparison',
                            icon: Icon(
                              Icons.compare_arrows_rounded,
                              color: isCompared ? Colors.white : AppColors.darkNavy,
                            ),
                            onPressed: () {
                              if (isCompared) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const PropertyCompareScreen(),
                                  ),
                                );
                              } else {
                                final added = compareService.add(widget.property);
                                if (added) {
                                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Added to compare (${compareService.count}/4)'),
                                      action: SnackBarAction(
                                        label: 'View Compare',
                                        textColor: Colors.amber,
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => const PropertyCompareScreen(),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                } else if (compareService.isFull) {
                                  CustomSnackBar.showWarning(context, 'Maximum 4 properties can be compared');
                                }
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 4),

                  // Favorite Button
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 8.0, right: 8.0),
                    child: CircleAvatar(
                      backgroundColor: Colors.white.withValues(alpha: 0.9),
                      child: IconButton(
                        icon: Icon(
                          _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: _isFavorite ? AppColors.error : AppColors.darkNavy,
                        ),
                        onPressed: _handleToggleFavorite,
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    children: [
                      // Image PageView
                      PageView.builder(
                        controller: _imagePageController,
                        itemCount: images.length,
                        onPageChanged: (idx) => setState(() => _currentImageIndex = idx),
                        itemBuilder: (context, idx) {
                          return Image.network(
                            images[idx],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: AppColors.darkNavy,
                              child: const Center(
                                child: Icon(Icons.apartment_rounded, size: 70, color: Colors.white24),
                              ),
                            ),
                          );
                        },
                      ),

                      // Gradient Overlay for readability
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.4),
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.6),
                              ],
                              stops: const [0.0, 0.6, 1.0],
                            ),
                          ),
                        ),
                      ),

                      // Image Dots Indicator
                      if (images.length > 1)
                        Positioned(
                          bottom: 18,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              images.length,
                              (index) => AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: _currentImageIndex == index ? 22 : 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: _currentImageIndex == index
                                      ? AppColors.primary
                                      : Colors.white.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Video Tour Badge Button
                      if (property.videoUrl != null && property.videoUrl!.isNotEmpty)
                        Positioned(
                          bottom: 14,
                          right: 16,
                          child: InkWell(
                            onTap: () => _launchVideoTour(property.videoUrl),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.5),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
                                  SizedBox(width: 4),
                                  Text(
                                    'Watch Tour',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      // Big SOLD Badge on Gallery
                      if (property.isSold)
                        Positioned(
                          top: 80,
                          left: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Text(
                              'SOLD',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ),

                      // Photo Counter Badge
                      Positioned(
                        bottom: 14,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.photo_library_rounded, color: Colors.white, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '${_currentImageIndex + 1}/${images.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Content Body
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Purpose and Type Badges
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (property.isSold)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'SOLD',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: property.purpose == 'For Sale'
                                  ? AppColors.primary
                                  : AppColors.slateBlue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              property.purpose.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              property.propertyType,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (property.isFeatured)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade700,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.star_rounded, color: Colors.white, size: 14),
                                  SizedBox(width: 3),
                                  Text(
                                    'FEATURED',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Title
                      Text(
                        property.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.darkNavy,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Location
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, size: 18, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              property.location.fullAddress,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.slateBlue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Key Specs Grid Card
                      _buildKeySpecsCard(property),
                      const SizedBox(height: 16),

                      // Compare Banner
                      _buildCompareBanner(property),
                      const SizedBox(height: 16),

                      // Visits Scheduled & Tour Booking Card
                      _buildVisitsBanner(property),
                      const SizedBox(height: 24),

                      // Description Section
                      _buildSectionHeader('Overview & Description'),
                      const SizedBox(height: 10),
                      Text(
                        property.description,
                        maxLines: _isDescriptionExpanded ? null : 4,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.slateBlue,
                          height: 1.6,
                        ),
                      ),
                      if (property.description.length > 180) ...[
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () {
                            setState(() => _isDescriptionExpanded = !_isDescriptionExpanded);
                          },
                          child: Text(
                            _isDescriptionExpanded ? 'Read Less' : 'Read More',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),

                      // Amenities Grid Section
                      if (property.amenities.isNotEmpty) ...[
                        _buildSectionHeader('Amenities & Features'),
                        const SizedBox(height: 14),
                        _buildAmenitiesGrid(property.amenities),
                        const SizedBox(height: 28),
                      ],

                      // Location & Map Section
                      _buildSectionHeader('Location & Map View'),
                      const SizedBox(height: 14),
                      PropertyMapWidget(
                        location: property.location,
                        title: property.title,
                      ),
                      const SizedBox(height: 28),

                      // Agent Information Section
                      _buildSectionHeader('Listing Agent'),
                      const SizedBox(height: 14),
                      _buildAgentCard(property.agent),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Sticky Bottom Contact Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.darkNavy.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: isOwner
                    ? Row(
                        children: [
                          // Edit Button
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddPropertyScreen(propertyToEdit: property),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.edit_rounded, size: 18),
                              label: const Text('Edit Listing'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.darkNavy,
                                side: const BorderSide(color: AppColors.borderGrey, width: 1.5),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Mark as Sold / Active Toggle
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _handleToggleSoldStatus,
                              icon: Icon(
                                property.isSold ? Icons.replay_rounded : Icons.check_circle_rounded,
                                size: 18,
                              ),
                              label: Text(property.isSold ? 'Mark Active' : 'Mark as Sold'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: property.isSold ? AppColors.darkNavy : Colors.amber.shade800,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          // Price display
                          Expanded(
                            flex: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Total Price',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.slateBlue,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  property.formattedPrice,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),

                          // In-App Chat Button
                          Expanded(
                            flex: 3,
                            child: ElevatedButton(
                              onPressed: _openInAppChat,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.chat_bubble_rounded, size: 16),
                                  SizedBox(width: 5),
                                  Text('Chat', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Call Button
                          Expanded(
                            flex: 3,
                            child: OutlinedButton(
                              onPressed: () => _launchCall(property.agent.phone),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.darkNavy,
                                side: const BorderSide(color: AppColors.borderGrey, width: 1.2),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.phone_rounded, size: 16),
                                  SizedBox(width: 5),
                                  Text('Call', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: AppColors.darkNavy,
      ),
    );
  }

  Widget _buildKeySpecsCard(PropertyModel property) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkNavy.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSpecTile(
            icon: Icons.aspect_ratio_rounded,
            title: 'Area',
            value: property.formattedArea,
          ),
          _buildSpecDivider(),
          _buildSpecTile(
            icon: Icons.king_bed_outlined,
            title: 'Bedrooms',
            value: property.bedrooms > 0 ? '${property.bedrooms} Beds' : 'N/A',
          ),
          _buildSpecDivider(),
          _buildSpecTile(
            icon: Icons.bathtub_outlined,
            title: 'Bathrooms',
            value: property.bathrooms > 0 ? '${property.bathrooms} Baths' : 'N/A',
          ),
        ],
      ),
    );
  }

  Widget _buildCompareBanner(PropertyModel property) {
    return ListenableBuilder(
      listenable: PropertyCompareService(),
      builder: (context, _) {
        final compareService = PropertyCompareService();
        final isCompared = compareService.isInCompare(property.id);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.darkNavy,
                AppColors.darkNavy.withValues(alpha: 0.9),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.darkNavy.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.compare_arrows_rounded,
                  color: AppColors.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Compare Properties',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      property.location.areaName.isNotEmpty
                          ? 'Compare side-by-side with other listings in ${property.location.areaName}'
                          : 'Compare price, square feet, and amenities side-by-side',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  if (!isCompared) {
                    compareService.add(property);
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PropertyCompareScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  isCompared ? 'Comparing' : 'Compare',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVisitsBanner(PropertyModel property) {
    final visitService = VisitBookingService();

    return StreamBuilder<int>(
      stream: visitService.streamPropertyVisitsCount(property.id),
      builder: (context, snapshot) {
        final visitCount = snapshot.data ?? 0;

        return Container(
          padding: const EdgeInsets.all(16),
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: visitCount > 0 ? Colors.amber.shade100 : AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      visitCount > 0 ? Icons.local_fire_department_rounded : Icons.calendar_today_rounded,
                      size: 20,
                      color: visitCount > 0 ? Colors.amber.shade800 : AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          visitCount > 0
                              ? '$visitCount Property Visits Scheduled'
                              : 'Schedule a Private Tour',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.darkNavy,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          visitCount > 0
                              ? 'Active buyer interest! Book your preferred walkthrough slot.'
                              : 'Pick a convenient date and time to visit this property on-site.',
                          style: const TextStyle(fontSize: 11, color: AppColors.slateBlue),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _openScheduleVisitSheet,
                  icon: const Icon(Icons.calendar_month_rounded, size: 18),
                  label: const Text(
                    'Book a Property Visit',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkNavy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSpecTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.darkNavy,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.slateBlue,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSpecDivider() {
    return Container(
      height: 40,
      width: 1,
      color: AppColors.borderGrey,
    );
  }

  Widget _buildAmenitiesGrid(List<String> amenities) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: amenities.map((amenity) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderGrey, width: 1.2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_getAmenityIcon(amenity), size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                amenity,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkNavy,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  IconData _getAmenityIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('pool')) return Icons.pool_rounded;
    if (lower.contains('security') || lower.contains('cctv')) return Icons.shield_rounded;
    if (lower.contains('park') || lower.contains('garage')) return Icons.directions_car_rounded;
    if (lower.contains('gym') || lower.contains('fitness')) return Icons.fitness_center_rounded;
    if (lower.contains('lawn') || lower.contains('garden')) return Icons.park_rounded;
    if (lower.contains('ac') || lower.contains('condition')) return Icons.ac_unit_rounded;
    if (lower.contains('solar') || lower.contains('generator') || lower.contains('power')) return Icons.bolt_rounded;
    if (lower.contains('internet') || lower.contains('wifi')) return Icons.wifi_rounded;
    if (lower.contains('elevator') || lower.contains('lift')) return Icons.elevator_rounded;
    if (lower.contains('balcony')) return Icons.balcony_rounded;
    if (lower.contains('furnish')) return Icons.chair_rounded;
    return Icons.check_circle_outline_rounded;
  }

  Widget _buildAgentCard(AgentModel agent) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkNavy.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Agent Avatar
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primaryLight,
                backgroundImage: agent.avatarUrl.isNotEmpty ? NetworkImage(agent.avatarUrl) : null,
                child: agent.avatarUrl.isEmpty
                    ? Text(
                        agent.name.isNotEmpty ? agent.name[0] : 'A',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),

              // Agent info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            agent.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.darkNavy,
                            ),
                          ),
                        ),
                        if (agent.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified_rounded, size: 16, color: AppColors.primary),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      agent.agency,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.slateBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                        const SizedBox(width: 3),
                        Text(
                          '${agent.rating} (${agent.reviewsCount} reviews)',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkNavy,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.borderGrey),
          const SizedBox(height: 14),

          // Contact Actions Row
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _launchCall(agent.phone),
                  icon: const Icon(Icons.phone_outlined, size: 16),
                  label: const Text('Call'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.darkNavy,
                    side: const BorderSide(color: AppColors.borderGrey, width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _launchWhatsApp(agent.phone),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                  label: const Text('WhatsApp'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF25D366),
                    side: const BorderSide(color: Color(0xFF25D366), width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _launchEmail(agent.email),
                  icon: const Icon(Icons.email_outlined, size: 16),
                  label: const Text('Email'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary, width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
