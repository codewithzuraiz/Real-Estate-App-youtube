import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/visit_booking_model.dart';

class VisitBookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _bookingsCollection =>
      _firestore.collection('visit_bookings');

  /// Create a new property visit appointment booking
  Future<String> createBooking(VisitBookingModel booking) async {
    final data = booking.toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    final docRef = await _bookingsCollection.add(data);
    return docRef.id;
  }

  /// Stream count of active/scheduled visits for a specific property
  Stream<int> streamPropertyVisitsCount(String propertyId) {
    return _bookingsCollection.snapshots().map((snapshot) {
      return snapshot.docs.where((doc) {
        final data = doc.data();
        final matchesProp = data['propertyId'] == propertyId;
        final status = (data['status'] ?? '').toString().toLowerCase();
        final isActive = status != 'cancelled';
        return matchesProp && isActive;
      }).length;
    });
  }

  /// Stream visit bookings made by a buyer
  Stream<List<VisitBookingModel>> streamBuyerBookings(String buyerId) {
    return _bookingsCollection.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => VisitBookingModel.fromMap(doc.data(), doc.id))
          .where((b) => b.buyerId == buyerId)
          .toList();
      list.sort((a, b) => b.visitDate.compareTo(a.visitDate));
      return list;
    });
  }

  /// Stream visit bookings received by a seller for their properties
  Stream<List<VisitBookingModel>> streamSellerBookings(String sellerId) {
    return _bookingsCollection.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => VisitBookingModel.fromMap(doc.data(), doc.id))
          .where((b) => b.sellerId == sellerId)
          .toList();
      list.sort((a, b) => b.visitDate.compareTo(a.visitDate));
      return list;
    });
  }

  /// Update the status of a visit booking (e.g. 'confirmed', 'cancelled', 'completed')
  Future<void> updateBookingStatus(String bookingId, String newStatus) async {
    await _bookingsCollection.doc(bookingId).update({
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
