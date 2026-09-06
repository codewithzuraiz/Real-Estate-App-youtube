import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class VisitBookingModel {
  final String id;
  final String propertyId;
  final String propertyTitle;
  final String propertyImage;
  final String propertyAddress;
  final double propertyPrice;
  final String buyerId;
  final String buyerName;
  final String buyerPhone;
  final String buyerEmail;
  final String sellerId;
  final String sellerName;
  final DateTime visitDate;
  final String timeSlot;
  final String notes;
  final String status; // 'pending', 'confirmed', 'completed', 'cancelled'
  final DateTime createdAt;

  const VisitBookingModel({
    required this.id,
    required this.propertyId,
    required this.propertyTitle,
    this.propertyImage = '',
    this.propertyAddress = '',
    this.propertyPrice = 0.0,
    required this.buyerId,
    required this.buyerName,
    required this.buyerPhone,
    this.buyerEmail = '',
    required this.sellerId,
    this.sellerName = '',
    required this.visitDate,
    required this.timeSlot,
    this.notes = '',
    this.status = 'pending',
    required this.createdAt,
  });

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isConfirmed => status.toLowerCase() == 'confirmed';
  bool get isCancelled => status.toLowerCase() == 'cancelled';
  bool get isCompleted => status.toLowerCase() == 'completed';

  String get formattedVisitDate => DateFormat('EEE, d MMM yyyy').format(visitDate);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'propertyId': propertyId,
      'propertyTitle': propertyTitle,
      'propertyImage': propertyImage,
      'propertyAddress': propertyAddress,
      'propertyPrice': propertyPrice,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'buyerPhone': buyerPhone,
      'buyerEmail': buyerEmail,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'visitDate': Timestamp.fromDate(visitDate),
      'timeSlot': timeSlot,
      'notes': notes,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory VisitBookingModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic date) {
      if (date is Timestamp) return date.toDate();
      if (date is String) return DateTime.tryParse(date) ?? DateTime.now();
      return DateTime.now();
    }

    return VisitBookingModel(
      id: docId,
      propertyId: map['propertyId'] ?? '',
      propertyTitle: map['propertyTitle'] ?? '',
      propertyImage: map['propertyImage'] ?? '',
      propertyAddress: map['propertyAddress'] ?? '',
      propertyPrice: (map['propertyPrice'] as num?)?.toDouble() ?? 0.0,
      buyerId: map['buyerId'] ?? '',
      buyerName: map['buyerName'] ?? 'Buyer',
      buyerPhone: map['buyerPhone'] ?? '',
      buyerEmail: map['buyerEmail'] ?? '',
      sellerId: map['sellerId'] ?? '',
      sellerName: map['sellerName'] ?? 'Seller',
      visitDate: parseDate(map['visitDate']),
      timeSlot: map['timeSlot'] ?? '10:00 AM - 11:00 AM',
      notes: map['notes'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: parseDate(map['createdAt']),
    );
  }

  VisitBookingModel copyWith({
    String? id,
    String? propertyId,
    String? propertyTitle,
    String? propertyImage,
    String? propertyAddress,
    double? propertyPrice,
    String? buyerId,
    String? buyerName,
    String? buyerPhone,
    String? buyerEmail,
    String? sellerId,
    String? sellerName,
    DateTime? visitDate,
    String? timeSlot,
    String? notes,
    String? status,
    DateTime? createdAt,
  }) {
    return VisitBookingModel(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      propertyTitle: propertyTitle ?? this.propertyTitle,
      propertyImage: propertyImage ?? this.propertyImage,
      propertyAddress: propertyAddress ?? this.propertyAddress,
      propertyPrice: propertyPrice ?? this.propertyPrice,
      buyerId: buyerId ?? this.buyerId,
      buyerName: buyerName ?? this.buyerName,
      buyerPhone: buyerPhone ?? this.buyerPhone,
      buyerEmail: buyerEmail ?? this.buyerEmail,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      visitDate: visitDate ?? this.visitDate,
      timeSlot: timeSlot ?? this.timeSlot,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
