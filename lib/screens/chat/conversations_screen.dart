// lib/screens/chat/conversations_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/chat_service.dart' as chat;
import '../../models/conversation.dart';
import '../../models/profil.dart';
import '../../config/app_theme.dart';
import 'chat_screen.dart' as chat_screen;

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final chat.ChatService _chatService = chat.ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isAdmin = false;
  bool _checkingRole = true;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    final user = _auth.currentUser;
    if (user == null) {
      setState(() { _isAdmin = false; _checkingRole = false; });
      return;
    }
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('utilisateurs')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        final role = (userDoc.data() as Map<String, dynamic>)['role'] ?? 'client';
        setState(() { _isAdmin = (role == 'admin'); _checkingRole = false; });
      } else {
        setState(() { _isAdmin = false; _checkingRole = false; });
      }
    } catch (_) {
      setState(() { _isAdmin = false; _checkingRole = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(child: Text('Utilisateur non connecté', style: AppText.body(color: AppColors.ink3))),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Messages', style: AppText.body(size: 17, weight: FontWeight.w600)),
        actions: [
          if (_isAdmin)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: const Icon(Icons.edit_outlined, color: AppColors.ink, size: 22),
                onPressed: () => _showNewConversationDialog(context),
              ),
            ),
        ],
      ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton(
              onPressed: () => _showNewConversationDialog(context),
              backgroundColor: AppColors.ink,
              foregroundColor: Colors.white,
              elevation: 0,
              child: const Icon(Icons.add_comment_outlined),
            )
          : null,
      body: _checkingRole
          ? const Center(child: CircularProgressIndicator(color: AppColors.sage))
          : StreamBuilder<List<Conversation>>(
              stream: _chatService.getConversations(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _buildError('${snapshot.error}');
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.sage));
                }

                final conversations = snapshot.data ?? [];

                if (conversations.isEmpty) {
                  return _buildEmpty();
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  itemCount: conversations.length,
                  itemBuilder: (context, index) =>
                      _buildConversationCard(context, conversations[index]),
                );
              },
            ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.sageBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded,
                  size: 36, color: AppColors.sage),
            ),
            const SizedBox(height: 20),
            Text('Aucune conversation',
                style: AppText.body(size: 18, weight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              _isAdmin
                  ? 'Démarrez une discussion avec un client'
                  : 'Votre coach vous contactera ici',
              style: AppText.body(size: 14, color: AppColors.ink3),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: AppColors.dangerBg, shape: BoxShape.circle),
              child: const Icon(Icons.error_outline, size: 30, color: AppColors.danger),
            ),
            const SizedBox(height: 16),
            Text('Erreur de chargement', style: AppText.body(size: 16, weight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(message, style: AppText.body(size: 13, color: AppColors.ink3), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationCard(BuildContext context, Conversation conv) {
    final hasUnread = conv.messagesNonLus > 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => chat_screen.ChatScreen(
              conversationId: conv.id,
              autreUserId: conv.autreUtilisateurId,
              autreUserNom: conv.autreUtilisateurNom,
              autreUserPhoto: conv.autreUtilisateurPhoto,
            ),
          ),
        ),
        child: Row(
          children: [
            _buildAvatar(conv.autreUtilisateurNom, conv.autreUtilisateurPhoto),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conv.autreUtilisateurNom,
                          style: AppText.body(
                            size: 15,
                            weight: hasUnread ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        _formatDate(conv.derniereActivite),
                        style: AppText.body(size: 11, color: AppColors.ink4),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conv.dernierMessage,
                          style: AppText.body(
                            size: 13,
                            color: hasUnread ? AppColors.ink2 : AppColors.ink3,
                            weight: hasUnread ? FontWeight.w500 : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: AppColors.ink,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              conv.messagesNonLus > 9 ? '9+' : '${conv.messagesNonLus}',
                              style: AppText.body(size: 10, weight: FontWeight.w600, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String nom, String? photoUrl) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.sageBg,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.line2, width: 1),
      ),
      child: ClipOval(
        child: photoUrl != null
            ? Image.network(photoUrl, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _avatarFallback(nom))
            : _avatarFallback(nom),
      ),
    );
  }

  Widget _avatarFallback(String nom) {
    return Center(
      child: Text(
        nom.isNotEmpty ? nom[0].toUpperCase() : '?',
        style: AppText.body(size: 18, weight: FontWeight.w600, color: AppColors.sageDeep),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${date.day}/${date.month}';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}min';
    return 'Maintenant';
  }

  void _showNewConversationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nouvelle conversation',
                  style: AppText.body(size: 18, weight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('Choisissez un client', style: AppText.body(size: 13, color: AppColors.ink3)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.maxFinite,
                height: 320,
                child: StreamBuilder<List<Profil>>(
                  stream: _chatService.getClients(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: AppColors.sage));
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Erreur: ${snapshot.error}',
                          style: AppText.body(color: AppColors.danger)));
                    }
                    final clients = snapshot.data ?? [];
                    if (clients.isEmpty) {
                      return Center(
                        child: Text('Aucun client trouvé',
                            style: AppText.body(color: AppColors.ink3)),
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: clients.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.line),
                      itemBuilder: (context, index) {
                        final client = clients[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                          leading: _buildAvatar(client.nom, client.photoUrl),
                          title: Text(client.nom, style: AppText.body(size: 14, weight: FontWeight.w500)),
                          subtitle: Text(client.email, style: AppText.body(size: 12, color: AppColors.ink3)),
                          onTap: () async {
                            Navigator.pop(ctx);
                            final convId = await _chatService.createConversation(client.id);
                            if (context.mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => chat_screen.ChatScreen(
                                    conversationId: convId,
                                    autreUserId: client.id,
                                    autreUserNom: client.nom,
                                    autreUserPhoto: client.photoUrl,
                                  ),
                                ),
                              );
                            }
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
