import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../models/property_model.dart';
import '../models/visit_booking_model.dart';
import '../services/user_service.dart';
import '../services/visit_booking_service.dart';
import 'custom_button.dart';
import 'custom_snackbar.dart';

class ScheduleVisitBottomSheet extends StatefulWidget {
  final PropertyModel property;

  const ScheduleVisitBottomSheet({
    super.key,
    required this.property,
  });

  @override
  State<ScheduleVisitBottomSheet> createState() => _ScheduleVisitBottomSheetState();
}

class _ScheduleVisitBottomSheetState extends State<ScheduleVisitBottomSheet> {
  final _visitService = VisitBookingService();
  final _userService = UserService();
  final _notesController = TextEditingController();
  final _phoneController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedSlot = '10:00 AM - 11:00 AM';
  bool _isSubmitting = false;

  final List<String> _timeSlots = [
    '10:00 AM - 11:00 AM',
    '11:30 AM - 12:30 PM',
    '02:00 PM - 03:00 PM',
    '03:30 PM - 04:30 PM',
    '05:00 PM - 06:00 PM',
    '06:30 PM - 07:30 PM',
  ];

  @override
  void initState() {
    super.initState();
    _fetchBuyerPhone();
  }

  void _fetchBuyerPhone() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final profile = await _userService.getUser(user.uid);
      if (profile != null && profile.phone.isNotEmpty && mounted) {
        _phoneController.text = profile.phone;
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      CustomSnackBar.showWarning(context, 'Please log in to schedule a property visit.');
      return;
    }

    if (_phoneController.text.trim().isEmpty) {
      CustomSnackBar.showWarning(context, 'Please provide a contact phone number.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final booking = VisitBookingModel(
        id: '',
        propertyId: widget.property.id,
        propertyTitle: widget.property.title,
        propertyImage: widget.property.coverImage,
        propertyAddress: widget.property.location.fullAddress,
        propertyPrice: widget.property.price,
        buyerId: user.uid,
        buyerName: user.displayName ?? 'Interested Buyer',
        buyerPhone: _phoneController.text.trim(),
        buyerEmail: user.email ?? '',
        sellerId: widget.property.sellerId.isNotEmpty
            ? widget.property.sellerId
            : widget.property.agent.id,
        sellerName: widget.property.agent.name,
        visitDate: _selectedDate,
        timeSlot: _selectedSlot,
        notes: _notesController.text.trim(),
        status: 'pending',
        createdAt: DateTime.now(),
      );

      await _visitService.createBooking(booking);

      if (mounted) {
        Navigator.pop(context);
        CustomSnackBar.showSuccess(
          context,
          'Visit requested for ${DateFormat('EEE, d MMM').format(_selectedDate)} ($_selectedSlot)! The seller has been notified.',
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(context, 'Failed to book visit: $e');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Generate next 14 days
    final nextDays = List.generate(
      14,
      (index) => DateTime.now().add(Duration(days: index + 1)),
    );

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Schedule Property Visit',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkNavy,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Book an on-site walkthrough with the seller',
                      style: TextStyle(fontSize: 12, color: AppColors.slateBlue),
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
          const Divider(height: 20, color: AppColors.borderGrey),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Active Visits Counter Indicator
                  StreamBuilder<int>(
                    stream: _visitService.streamPropertyVisitsCount(widget.property.id),
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: count > 0
                              ? Colors.amber.shade50
                              : AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: count > 0
                                ? Colors.amber.shade300
                                : AppColors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              count > 0 ? Icons.local_fire_department_rounded : Icons.event_available_rounded,
                              size: 20,
                              color: count > 0 ? Colors.amber.shade800 : AppColors.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                count > 0
                                    ? '$count buyer${count == 1 ? '' : 's'} currently have visits booked for this property!'
                                    : 'Be the first buyer to schedule a private tour for this property!',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: count > 0 ? Colors.amber.shade900 : AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 18),

                  // Select Date
                  const Text(
                    'Select Visit Date',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.darkNavy,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 84,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: nextDays.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final date = nextDays[index];
                        final isSelected = _selectedDate.year == date.year &&
                            _selectedDate.month == date.month &&
                            _selectedDate.day == date.day;

                        return InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => setState(() => _selectedDate = date),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 64,
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : AppColors.scaffoldBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : AppColors.borderGrey,
                                width: 1.5,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  DateFormat('EEE').format(date).toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? Colors.white70 : AppColors.slateBlue,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${date.day}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: isSelected ? Colors.white : AppColors.darkNavy,
                                  ),
                                ),
                                Text(
                                  DateFormat('MMM').format(date),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? Colors.white70 : AppColors.slateBlue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Select Time Slot
                  const Text(
                    'Available Time Slots',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.darkNavy,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _timeSlots.map((slot) {
                      final isSelected = _selectedSlot == slot;
                      return ChoiceChip(
                        label: Text(slot),
                        selected: isSelected,
                        onSelected: (sel) {
                          if (sel) setState(() => _selectedSlot = slot);
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
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Buyer Contact Phone
                  const Text(
                    'Contact Phone Number',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.darkNavy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.scaffoldBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borderGrey, width: 1.2),
                    ),
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        hintText: 'e.g. +92 300 1234567',
                        hintStyle: TextStyle(fontSize: 13, color: AppColors.slateBlue),
                        prefixIcon: Icon(Icons.phone_outlined, size: 20, color: AppColors.primary),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Special Notes
                  const Text(
                    'Notes / Questions for Seller (Optional)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.darkNavy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.scaffoldBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borderGrey, width: 1.2),
                    ),
                    child: TextField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Want to inspect the construction & layout...',
                        hintStyle: TextStyle(fontSize: 13, color: AppColors.slateBlue),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  CustomButton(
                    text: 'Confirm Visit Request',
                    icon: Icons.calendar_month_rounded,
                    onPressed: _handleSubmit,
                    isLoading: _isSubmitting,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
