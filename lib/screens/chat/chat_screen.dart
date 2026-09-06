import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../models/chat_model.dart';
import '../../services/chat_service.dart';
import '../property/property_details_screen.dart';
import '../../services/property_service.dart';

class ChatScreen extends StatefulWidget {
  final ChatConversation conversation;

  const ChatScreen({
    super.key,
    required this.conversation,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  final String _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  final String _currentName = FirebaseAuth.instance.currentUser?.displayName ?? 'User';
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _handleSendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    _messageController.clear();
    setState(() => _isSending = true);

    try {
      await _chatService.sendMessage(
        chatId: widget.conversation.id,
        senderId: _currentUid,
        senderName: _currentName,
        text: text,
      );
      _scrollToBottom();
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _navigateToProperty() async {
    final prop = await PropertyService().getPropertyById(widget.conversation.propertyId);
    if (prop != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PropertyDetailsScreen(property: prop),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final otherName = widget.conversation.otherPartyName(_currentUid);
    final otherRole = widget.conversation.otherPartyRole(_currentUid);
    final otherAvatar = widget.conversation.otherPartyAvatar(_currentUid);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: AppColors.primaryLight,
              backgroundImage: otherAvatar.isNotEmpty ? NetworkImage(otherAvatar) : null,
              child: otherAvatar.isEmpty
                  ? Text(
                      otherName.isNotEmpty ? otherName[0].toUpperCase() : 'U',
                      style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 16),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    otherName,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          otherRole,
                          style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Direct Messaging',
                        style: TextStyle(fontSize: 11, color: AppColors.slateBlue),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Pinned Property Context Card
          InkWell(
            onTap: _navigateToProperty,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(
                  bottom: BorderSide(color: AppColors.borderGrey, width: 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.darkNavy.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: widget.conversation.propertyImage.isNotEmpty
                        ? Image.network(
                            widget.conversation.propertyImage,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 44,
                              height: 44,
                              color: AppColors.slateBlue.withValues(alpha: 0.2),
                              child: const Icon(Icons.apartment_rounded, size: 22, color: AppColors.slateBlue),
                            ),
                          )
                        : Container(
                            width: 44,
                            height: 44,
                            color: AppColors.slateBlue.withValues(alpha: 0.2),
                            child: const Icon(Icons.apartment_rounded, size: 22, color: AppColors.slateBlue),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.conversation.propertyTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.darkNavy),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.conversation.propertyLocation,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: AppColors.slateBlue),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.scaffoldBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.borderGrey),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                        ),
                        SizedBox(width: 2),
                        Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.primary),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Message Stream List
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _chatService.streamMessages(widget.conversation.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  );
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.chat_bubble_outline_rounded, size: 36, color: AppColors.primary),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Start conversation with $otherName',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.darkNavy),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Discuss property pricing, visits, documents, and negotiations.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: AppColors.slateBlue),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == _currentUid;
                    final timeStr = DateFormat('hh:mm a').format(msg.createdAt);

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.76,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(18),
                            topRight: const Radius.circular(18),
                            bottomLeft: Radius.circular(isMe ? 18 : 4),
                            bottomRight: Radius.circular(isMe ? 4 : 18),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isMe
                                  ? AppColors.primary.withValues(alpha: 0.2)
                                  : AppColors.darkNavy.withValues(alpha: 0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: isMe ? null : Border.all(color: AppColors.borderGrey, width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg.text,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.4,
                                color: isMe ? Colors.white : AppColors.darkNavy,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              timeStr,
                              style: TextStyle(
                                fontSize: 10,
                                color: isMe
                                    ? Colors.white.withValues(alpha: 0.75)
                                    : AppColors.slateBlue.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Message Input Field
          Container(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
            decoration: BoxDecoration(
              color: Colors.white,
              border: const Border(
                top: BorderSide(color: AppColors.borderGrey, width: 1),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.darkNavy.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.scaffoldBg,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.borderGrey, width: 1.2),
                      ),
                      child: TextField(
                        controller: _messageController,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _handleSendMessage(),
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(fontSize: 13, color: AppColors.slateBlue),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primaryLight, AppColors.primary],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: _isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      onPressed: _isSending ? null : _handleSendMessage,
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
}
