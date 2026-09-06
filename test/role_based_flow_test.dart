import 'package:flutter_test/flutter_test.dart';
import 'package:real_estate_app/models/chat_model.dart';
import 'package:real_estate_app/models/property_model.dart';
import 'package:real_estate_app/models/user_model.dart';
import 'package:real_estate_app/models/visit_booking_model.dart';

void main() {
  group('UserModel Role Tests', () {
    test('Identifies buyer role correctly', () {
      final buyer1 = UserModel(
        uid: 'user_1',
        name: 'Ali Khan',
        email: 'ali@example.com',
        role: 'Buyer',
        createdAt: DateTime.now(),
      );
      expect(buyer1.isBuyer, isTrue);
      expect(buyer1.isSeller, isFalse);

      final buyer2 = UserModel(
        uid: 'user_2',
        name: 'Sara Ahmed',
        email: 'sara@example.com',
        role: 'Client / Buyer',
        createdAt: DateTime.now(),
      );
      expect(buyer2.isBuyer, isTrue);
      expect(buyer2.isSeller, isFalse);
    });

    test('Identifies seller and agent roles correctly', () {
      final seller1 = UserModel(
        uid: 'user_3',
        name: 'Zuraiz',
        email: 'zuraiz@example.com',
        role: 'Seller',
        createdAt: DateTime.now(),
      );
      expect(seller1.isSeller, isTrue);
      expect(seller1.isBuyer, isFalse);

      final seller2 = UserModel(
        uid: 'user_4',
        name: 'Agent Bilal',
        email: 'bilal@agency.com',
        role: 'Real Estate Agent',
        createdAt: DateTime.now(),
      );
      expect(seller2.isSeller, isTrue);
    });
  });

  group('PropertyModel Status and Ownership Tests', () {
    test('Default status is Active and sellerId is stored', () {
      final now = DateTime.now();
      final property = PropertyModel(
        id: 'prop_100',
        title: 'Luxury 1 Kanal Villa',
        description: 'Prime location in DHA Phase 6',
        price: 75000000,
        currency: 'PKR',
        purpose: 'For Sale',
        propertyType: 'House / Villa',
        images: ['https://example.com/image.jpg'],
        location: PropertyLocation(
          address: 'Main Boulevard, Phase 6',
          areaName: 'DHA Phase 6',
          city: 'Lahore',
          latitude: 31.47,
          longitude: 74.45,
        ),
        area: 1,
        areaUnit: 'Kanal',
        bedrooms: 5,
        bathrooms: 6,
        agent: AgentModel(
          id: 'agent_1',
          name: 'Zuraiz',
          agency: 'Premier Estates',
          phone: '+92 300 1234567',
          email: 'agent@premier.com',
        ),
        sellerId: 'seller_123',
        status: 'Active',
        createdAt: now,
      );

      expect(property.isActive, isTrue);
      expect(property.isSold, isFalse);
      expect(property.sellerId, equals('seller_123'));

      // Test copyWith status update
      final soldProperty = property.copyWith(status: 'Sold');
      expect(soldProperty.isSold, isTrue);
      expect(soldProperty.isActive, isFalse);
      expect(soldProperty.sellerId, equals('seller_123'));

      // Test toMap and fromMap serialization
      final map = soldProperty.toMap();
      expect(map['status'], equals('Sold'));
      expect(map['sellerId'], equals('seller_123'));

      final restored = PropertyModel.fromMap(map, 'prop_100');
      expect(restored.id, equals('prop_100'));
      expect(restored.isSold, isTrue);
      expect(restored.sellerId, equals('seller_123'));
    });
  });

  group('VisitBookingModel Tests', () {
    test('Serialization and status helpers work correctly', () {
      final visitDate = DateTime(2026, 9, 15);
      final createdAt = DateTime.now();
      final visit = VisitBookingModel(
        id: 'booking_1',
        propertyId: 'prop_100',
        propertyTitle: 'Luxury 1 Kanal Villa',
        propertyImage: 'https://example.com/img.jpg',
        propertyAddress: 'DHA Phase 6, Lahore',
        buyerId: 'buyer_99',
        buyerName: 'Usman Tariq',
        buyerEmail: 'usman@gmail.com',
        buyerPhone: '+92 321 9876543',
        sellerId: 'seller_123',
        visitDate: visitDate,
        timeSlot: '11:00 AM - 12:00 PM',
        notes: 'Interested in seeing the master bedroom',
        status: 'pending',
        createdAt: createdAt,
      );

      expect(visit.isPending, isTrue);
      expect(visit.isConfirmed, isFalse);
      expect(visit.isCancelled, isFalse);

      final map = visit.toMap();
      final restored = VisitBookingModel.fromMap(map, 'booking_1');
      expect(restored.id, equals('booking_1'));
      expect(restored.propertyTitle, equals('Luxury 1 Kanal Villa'));
      expect(restored.buyerPhone, equals('+92 321 9876543'));
      expect(restored.visitDate.day, equals(15));
      expect(restored.timeSlot, equals('11:00 AM - 12:00 PM'));

      final confirmed = visit.copyWith(status: 'confirmed');
      expect(confirmed.isConfirmed, isTrue);
      expect(confirmed.isPending, isFalse);
    });
  });

  group('ChatModel Tests', () {
    test('ChatConversation and ChatMessage serialization', () {
      final now = DateTime.now();
      final msg = ChatMessage(
        id: 'msg_1',
        senderId: 'buyer_99',
        senderName: 'Usman',
        text: 'Hello, is this property still available?',
        createdAt: now,
        isRead: false,
      );

      final msgMap = msg.toMap();
      expect(msgMap['text'], equals('Hello, is this property still available?'));
      expect(msgMap['senderId'], equals('buyer_99'));

      final restoredMsg = ChatMessage.fromMap(msgMap, 'msg_1');
      expect(restoredMsg.id, equals('msg_1'));
      expect(restoredMsg.text, equals('Hello, is this property still available?'));

      final conv = ChatConversation(
        id: 'chat_prop_100_buyer_99',
        propertyId: 'prop_100',
        propertyTitle: 'Luxury 1 Kanal Villa',
        propertyImage: 'https://example.com/prop.jpg',
        propertyPrice: 75000000,
        participantIds: ['buyer_99', 'seller_123'],
        buyerId: 'buyer_99',
        buyerName: 'Usman',
        sellerId: 'seller_123',
        sellerName: 'Zuraiz',
        lastMessage: 'Hello, is this property still available?',
        lastMessageTime: now,
        lastSenderId: 'buyer_99',
      );

      expect(conv.otherPartyName('buyer_99'), equals('Zuraiz'));
      expect(conv.otherPartyName('seller_123'), equals('Usman'));
      expect(conv.otherPartyRole('buyer_99'), equals('Seller'));
      expect(conv.otherPartyRole('seller_123'), equals('Buyer'));

      final convMap = conv.toMap();
      final restoredConv = ChatConversation.fromMap(convMap, 'chat_prop_100_buyer_99');
      expect(restoredConv.propertyTitle, equals('Luxury 1 Kanal Villa'));
      expect(restoredConv.sellerName, equals('Zuraiz'));
    });
  });
}
