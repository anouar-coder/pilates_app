// lib/screens/chat/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/chat_service.dart' as chat;
import '../../models/message.dart';
import '../../config/app_theme.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String autreUserId;
  final String autreUserNom;
  final String? autreUserPhoto;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.autreUserId,
    required this.autreUserNom,
    this.autreUserPhoto,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final chat.ChatService _chatService = chat.ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _chatService.markMessagesAsRead(widget.conversationId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
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

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    setState(() => _isSending = true);
    final message = _messageController.text.trim();
    _messageController.clear();
    await _chatService.sendMessage(widget.conversationId, message);
    setState(() => _isSending = false);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _auth.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            _buildAvatar(widget.autreUserNom, widget.autreUserPhoto, radius: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.autreUserNom,
                      style: AppText.body(size: 15, weight: FontWeight.w600)),
                  Text('En ligne', style: AppText.body(size: 11, color: AppColors.sage)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(height: 1, color: AppColors.line),
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _chatService.getMessages(widget.conversationId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Erreur: ${snapshot.error}',
                        style: AppText.body(color: AppColors.danger)),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.sage));
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: const BoxDecoration(
                              color: AppColors.sageBg, shape: BoxShape.circle),
                          child: const Icon(Icons.waving_hand_outlined,
                              size: 32, color: AppColors.sage),
                        ),
                        const SizedBox(height: 16),
                        Text('Dites bonjour !',
                            style: AppText.body(size: 16, weight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('Envoyez votre premier message',
                            style: AppText.body(size: 13, color: AppColors.ink3)),
                      ],
                    ),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.expediteurId == currentUserId;
                    final showDate = index == 0 ||
                        messages[index].date.day != messages[index - 1].date.day;
                    return Column(
                      children: [
                        if (showDate) _buildDateDivider(message.date),
                        _buildMessageBubble(message, isMe),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildDateDivider(DateTime date) {
    final now = DateTime.now();
    String label;
    if (date.day == now.day && date.month == now.month) {
      label = "Aujourd'hui";
    } else {
      label = '${date.day}/${date.month}/${date.year}';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(children: [
        const Expanded(child: Divider(color: AppColors.line)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(label, style: AppText.body(size: 11, color: AppColors.ink4)),
        ),
        const Expanded(child: Divider(color: AppColors.line)),
      ]),
    );
  }

  Widget _buildMessageBubble(Message message, bool isMe) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            _buildAvatar(message.expediteurNom, message.expediteurPhoto, radius: 14),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.68),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? AppColors.ink : AppColors.card,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(AppRadius.md),
                  topRight: const Radius.circular(AppRadius.md),
                  bottomLeft: Radius.circular(isMe ? AppRadius.md : 4),
                  bottomRight: Radius.circular(isMe ? 4 : AppRadius.md),
                ),
                boxShadow: AppShadows.sh1,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        message.expediteurNom,
                        style: AppText.body(size: 10, weight: FontWeight.w600, color: AppColors.sage),
                      ),
                    ),
                  Text(
                    message.contenu,
                    style: AppText.body(
                      size: 14,
                      color: isMe ? Colors.white : AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        _formatTime(message.date),
                        style: AppText.body(
                          size: 9,
                          color: isMe
                              ? Colors.white.withValues(alpha: 0.55)
                              : AppColors.ink4,
                        ),
                      ),
                      if (isMe && message.lu) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.done_all_rounded,
                            size: 12,
                            color: Colors.white.withValues(alpha: 0.7)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            _buildAvatar(message.expediteurNom, message.expediteurPhoto, radius: 14),
          ],
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(top: BorderSide(color: AppColors.line, width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.line2, width: 1),
                boxShadow: AppShadows.sh1,
              ),
              child: TextField(
                controller: _messageController,
                style: AppText.body(size: 14),
                maxLines: 5,
                minLines: 1,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'Votre message…',
                  hintStyle: AppText.body(size: 14, color: AppColors.ink4),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _isSending ? null : _sendMessage,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: _isSending
                  ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      ),
                    )
                  : const Icon(Icons.arrow_upward_rounded,
                      color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String nom, String? photoUrl, {double radius = 18}) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: AppColors.sageBg,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.line2, width: 1),
      ),
      child: ClipOval(
        child: photoUrl != null
            ? Image.network(photoUrl, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _avatarFallback(nom, radius))
            : _avatarFallback(nom, radius),
      ),
    );
  }

  Widget _avatarFallback(String nom, double radius) {
    return Center(
      child: Text(
        nom.isNotEmpty ? nom[0].toUpperCase() : '?',
        style: AppText.body(
            size: radius * 0.7,
            weight: FontWeight.w600,
            color: AppColors.sageDeep),
      ),
    );
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
