import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_theme.dart';
import '../../models/visit_booking_model.dart';
import '../../services/user_service.dart';
import '../../services/visit_booking_service.dart';
import '../../widgets/custom_snackbar.dart';
import 'property_details_screen.dart';
import '../../services/property_service.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> with SingleTickerProviderStateMixin {
  final _visitService = VisitBookingService();
  final _userService = UserService();
  final String _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool _isSeller = false;
  bool _isLoadingRole = true;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  void _loadUserRole() async {
    if (_currentUid.isNotEmpty) {
      final user = await _userService.getUser(_currentUid);
      if (user != null && mounted) {
        setState(() {
          _isSeller = user.isSeller;
          _isLoadingRole = false;
        });
        return;
      }
    }
    if (mounted) setState(() => _isLoadingRole = false);
  }

  Future<void> _updateStatus(String bookingId, String newStatus) async {
    try {
      await _visitService.updateBookingStatus(bookingId, newStatus);
      if (mounted) {
        CustomSnackBar.showSuccess(
          context,
          newStatus == 'confirmed'
              ? 'Visit confirmed! Buyer will be notified.'
              : 'Visit appointment updated.',
        );
      }
    } catch (e) {
      if (mounted) CustomSnackBar.showError(context, 'Failed to update: $e');
    }
  }

  Future<void> _launchPhone(String phone) async {
    final clean = phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _viewProperty(String propertyId) async {
    final prop = await PropertyService().getPropertyById(propertyId);
    if (prop != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PropertyDetailsScreen(property: prop)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: Text(
          _isSeller ? 'Manage Visit Requests' : 'My Scheduled Visits',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
      ),
      body: _isLoadingRole
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)))
          : StreamBuilder<List<VisitBookingModel>>(
              stream: _isSeller
                  ? _visitService.streamSellerBookings(_currentUid)
                  : _visitService.streamBuyerBookings(_currentUid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)),
                  );
                }

                final bookings = snapshot.data ?? [];

                if (bookings.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.event_note_rounded, size: 44, color: AppColors.primary),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            _isSeller ? 'No Visit Requests Yet' : 'No Scheduled Visits',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.darkNavy),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isSeller
                                ? 'When buyers request walkthroughs of your properties, they will appear here for confirmation.'
                                : 'You have not booked any property visits yet. Explore listings and tap "Book a Visit" to schedule a tour!',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 13, color: AppColors.slateBlue, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: bookings.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final booking = bookings[index];
                    return _buildBookingCard(booking);
                  },
                );
              },
            ),
    );
  }

  Widget _buildBookingCard(VisitBookingModel booking) {
    Color statusBg;
    Color statusTextColor;
    String statusLabel;

    switch (booking.status.toLowerCase()) {
      case 'confirmed':
        statusBg = Colors.green.shade50;
        statusTextColor = Colors.green.shade800;
        statusLabel = 'CONFIRMED';
        break;
      case 'cancelled':
        statusBg = Colors.red.shade50;
        statusTextColor = Colors.red.shade800;
        statusLabel = 'CANCELLED';
        break;
      default:
        statusBg = Colors.amber.shade50;
        statusTextColor = Colors.amber.shade900;
        statusLabel = 'PENDING';
    }

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
          // Header: Date & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    booking.formattedVisitDate,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.darkNavy),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: statusTextColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Time Slot Badge
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 15, color: AppColors.slateBlue),
              const SizedBox(width: 6),
              Text(
                booking.timeSlot,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.slateBlue),
              ),
            ],
          ),
          const Divider(height: 20, color: AppColors.borderGrey),

          // Property summary
          InkWell(
            onTap: () => _viewProperty(booking.propertyId),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: booking.propertyImage.isNotEmpty
                      ? Image.network(
                          booking.propertyImage,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 50,
                            height: 50,
                            color: AppColors.slateBlue.withValues(alpha: 0.2),
                            child: const Icon(Icons.apartment_rounded, size: 24, color: AppColors.slateBlue),
                          ),
                        )
                      : Container(
                          width: 50,
                          height: 50,
                          color: AppColors.slateBlue.withValues(alpha: 0.2),
                          child: const Icon(Icons.apartment_rounded, size: 24, color: AppColors.slateBlue),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.propertyTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.darkNavy),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        booking.propertyAddress,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: AppColors.slateBlue),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.silverGrey),
              ],
            ),
          ),

          // Person Info & Notes
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.scaffoldBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isSeller ? 'Buyer: ${booking.buyerName}' : 'Seller: ${booking.sellerName}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.darkNavy),
                    ),
                    if (booking.buyerPhone.isNotEmpty)
                      GestureDetector(
                        onTap: () => _launchPhone(booking.buyerPhone),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.phone_rounded, size: 13, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              booking.buyerPhone,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                if (booking.notes.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Notes: "${booking.notes}"',
                    style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.slateBlue),
                  ),
                ],
              ],
            ),
          ),

          // Action Buttons for Seller
          if (_isSeller && booking.isPending) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _updateStatus(booking.id, 'confirmed'),
                    icon: const Icon(Icons.check_circle_rounded, size: 16),
                    label: const Text('Confirm Visit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _updateStatus(booking.id, 'cancelled'),
                    icon: const Icon(Icons.cancel_outlined, size: 16),
                    label: const Text('Decline'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error, width: 1.2),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
