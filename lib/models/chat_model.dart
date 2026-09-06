import 'package:cloud_firestore/cloud_firestore.dart';

class ChatConversation {
  final String id;
  final String propertyId;
  final String propertyTitle;
  final double propertyPrice;
  final String propertyImage;
  final String propertyLocation;
  final String buyerId;
  final String buyerName;
  final String buyerAvatar;
  final String sellerId;
  final String sellerName;
  final String sellerAvatar;
  final String lastMessage;
  final DateTime lastMessageTime;
  final String lastSenderId;
  final List<String> participantIds;

  const ChatConversation({
    required this.id,
    required this.propertyId,
    required this.propertyTitle,
    this.propertyPrice = 0.0,
    this.propertyImage = '',
    this.propertyLocation = '',
    required this.buyerId,
    required this.buyerName,
    this.buyerAvatar = '',
    required this.sellerId,
    required this.sellerName,
    this.sellerAvatar = '',
    this.lastMessage = '',
    required this.lastMessageTime,
    this.lastSenderId = '',
    required this.participantIds,
  });

  String otherPartyName(String currentUid) {
    return currentUid == buyerId ? sellerName : buyerName;
  }

  String otherPartyRole(String currentUid) {
    return currentUid == buyerId ? 'Seller' : 'Buyer';
  }

  String otherPartyAvatar(String currentUid) {
    return currentUid == buyerId ? sellerAvatar : buyerAvatar;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'propertyId': propertyId,
      'propertyTitle': propertyTitle,
      'propertyPrice': propertyPrice,
      'propertyImage': propertyImage,
      'propertyLocation': propertyLocation,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'buyerAvatar': buyerAvatar,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'sellerAvatar': sellerAvatar,
      'lastMessage': lastMessage,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'lastSenderId': lastSenderId,
      'participantIds': participantIds,
    };
  }

  factory ChatConversation.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic date) {
      if (date is Timestamp) return date.toDate();
      if (date is String) return DateTime.tryParse(date) ?? DateTime.now();
      return DateTime.now();
    }

    final pIds = (map['participantIds'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [map['buyerId']?.toString() ?? '', map['sellerId']?.toString() ?? ''];

    return ChatConversation(
      id: docId,
      propertyId: map['propertyId'] ?? '',
      propertyTitle: map['propertyTitle'] ?? '',
      propertyPrice: (map['propertyPrice'] as num?)?.toDouble() ?? 0.0,
      propertyImage: map['propertyImage'] ?? '',
      propertyLocation: map['propertyLocation'] ?? '',
      buyerId: map['buyerId'] ?? '',
      buyerName: map['buyerName'] ?? 'Buyer',
      buyerAvatar: map['buyerAvatar'] ?? '',
      sellerId: map['sellerId'] ?? '',
      sellerName: map['sellerName'] ?? 'Seller',
      sellerAvatar: map['sellerAvatar'] ?? '',
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTime: parseDate(map['lastMessageTime']),
      lastSenderId: map['lastSenderId'] ?? '',
      participantIds: pIds,
    );
  }
}

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime createdAt;
  final bool isRead;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.createdAt,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic date) {
      if (date is Timestamp) return date.toDate();
      if (date is String) return DateTime.tryParse(date) ?? DateTime.now();
      return DateTime.now();
    }

    return ChatMessage(
      id: docId,
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      text: map['text'] ?? '',
      createdAt: parseDate(map['createdAt']),
      isRead: map['isRead'] ?? false,
    );
  }
}
