import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart';
import '../models/property_model.dart';
import '../models/user_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _chatsCollection =>
      _firestore.collection('chats');

  /// Get or create a 1-on-1 chat conversation for a property between buyer and seller
  Future<ChatConversation> getOrCreateConversation({
    required PropertyModel property,
    required UserModel buyer,
  }) async {
    final sellerId = property.sellerId.isNotEmpty ? property.sellerId : property.agent.id;
    // Standard composite document ID
    final chatId = 'chat_${property.id}_${buyer.uid}';
    final docRef = _chatsCollection.doc(chatId);
    final doc = await docRef.get();

    if (doc.exists && doc.data() != null) {
      return ChatConversation.fromMap(doc.data()!, doc.id);
    }

    final locationStr = property.location.areaName.isNotEmpty
        ? '${property.location.areaName}, ${property.location.city}'
        : property.location.city;

    final conversation = ChatConversation(
      id: chatId,
      propertyId: property.id,
      propertyTitle: property.title,
      propertyPrice: property.price,
      propertyImage: property.coverImage,
      propertyLocation: locationStr,
      buyerId: buyer.uid,
      buyerName: buyer.name.isNotEmpty ? buyer.name : 'Buyer',
      buyerAvatar: buyer.avatarUrl,
      sellerId: sellerId,
      sellerName: property.agent.name.isNotEmpty ? property.agent.name : 'Seller',
      sellerAvatar: property.agent.avatarUrl,
      lastMessage: 'Inquiry started for ${property.title}',
      lastMessageTime: DateTime.now(),
      lastSenderId: buyer.uid,
      participantIds: [buyer.uid, sellerId],
    );

    await docRef.set(conversation.toMap(), SetOptions(merge: true));
    return conversation;
  }

  /// Stream all conversations for a user (either as buyer or seller)
  Stream<List<ChatConversation>> streamUserConversations(String userId) {
    return _chatsCollection.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ChatConversation.fromMap(doc.data(), doc.id))
          .where((chat) => chat.participantIds.contains(userId))
          .toList();
      list.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
      return list;
    });
  }

  /// Stream real-time messages within a conversation
  Stream<List<ChatMessage>> streamMessages(String chatId) {
    return _chatsCollection
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatMessage.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Send a message in a conversation
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String text,
  }) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return;

    final now = DateTime.now();

    // Add message to subcollection
    await _chatsCollection.doc(chatId).collection('messages').add({
      'senderId': senderId,
      'senderName': senderName,
      'text': cleanText,
      'createdAt': Timestamp.fromDate(now),
      'isRead': false,
    });

    // Update parent conversation
    await _chatsCollection.doc(chatId).update({
      'lastMessage': cleanText,
      'lastMessageTime': Timestamp.fromDate(now),
      'lastSenderId': senderId,
    });
  }
}
