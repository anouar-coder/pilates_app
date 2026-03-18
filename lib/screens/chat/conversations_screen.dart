// lib/screens/chat/conversations_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/chat_service.dart' as chat;
import '../../models/conversation.dart';
import '../../models/profil.dart';
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
      setState(() {
        _isAdmin = false;
        _checkingRole = false;
      });
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('utilisateurs')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final role = userData['role'] ?? 'client';
        setState(() {
          _isAdmin = (role == 'admin');
          _checkingRole = false;
        });
        print('👤 isAdmin: $_isAdmin');
      } else {
        setState(() {
          _isAdmin = false;
          _checkingRole = false;
        });
      }
    } catch (e) {
      print('❌ Erreur: $e');
      setState(() {
        _isAdmin = false;
        _checkingRole = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return const Center(child: Text('Utilisateur non connecté'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.add_comment),
              onPressed: () {
                _showNewConversationDialog(context);
              },
            ),
        ],
      ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton(
              onPressed: () {
                _showNewConversationDialog(context);
              },
              backgroundColor: Colors.blue,
              child: const Icon(Icons.add_comment, color: Colors.white),
            )
          : null,
      body: _checkingRole
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<Conversation>>(
              stream: _chatService.getConversations(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text('Erreur: ${snapshot.error}'),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final conversations = snapshot.data ?? [];

                if (conversations.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Aucune conversation',
                          style: TextStyle(fontSize: 20, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isAdmin 
                              ? 'Cliquez sur le bouton + pour démarrer une conversation'
                              : 'Commencez une discussion avec votre coach',
                          style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: conversations.length,
                  itemBuilder: (context, index) {
                    final conv = conversations[index];
                    return _buildConversationCard(context, conv);
                  },
                );
              },
            ),
    );
  }

  Widget _buildConversationCard(BuildContext context, Conversation conv) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => chat_screen.ChatScreen(
                conversationId: conv.id,
                autreUserId: conv.autreUtilisateurId,
                autreUserNom: conv.autreUtilisateurNom,
                autreUserPhoto: conv.autreUtilisateurPhoto,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.blue.withValues(alpha: 0.2),
                backgroundImage: conv.autreUtilisateurPhoto != null
                    ? NetworkImage(conv.autreUtilisateurPhoto!)
                    : null,
                child: conv.autreUtilisateurPhoto == null
                    ? Text(
                        conv.autreUtilisateurNom.isNotEmpty
                            ? conv.autreUtilisateurNom[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conv.autreUtilisateurNom,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          _formatDate(conv.derniereActivite),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      conv.dernierMessage,
                      style: TextStyle(
                        fontSize: 14,
                        color: conv.messagesNonLus > 0
                            ? Colors.black
                            : Colors.grey[600],
                        fontWeight: conv.messagesNonLus > 0
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${date.day}/${date.month}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}min';
    } else {
      return 'Maintenant';
    }
  }

  void _showNewConversationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouvelle conversation'),
        content: SizedBox(
          width: double.maxFinite,
          child: StreamBuilder<List<Profil>>(
            stream: _chatService.getClients(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 40),
                      const SizedBox(height: 8),
                      Text('Erreur: ${snapshot.error}'),
                    ],
                  ),
                );
              }
              final clients = snapshot.data ?? [];
              if (clients.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange, size: 40),
                      SizedBox(height: 8),
                      Text('Aucun client trouvé'),
                    ],
                  ),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                itemCount: clients.length,
                itemBuilder: (context, index) {
                  if (index >= clients.length) {
                    return const SizedBox();
                  }
                  final client = clients[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: client.photoUrl != null
                          ? NetworkImage(client.photoUrl!)
                          : null,
                      child: client.photoUrl == null
                          ? Text(client.nom.isNotEmpty ? client.nom[0].toUpperCase() : '?')
                          : null,
                    ),
                    title: Text(client.nom),
                    subtitle: Text(client.email),
                    onTap: () async {
                      Navigator.pop(context);
                      final convId = await _chatService.createConversation(client.id);
                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => chat_screen.ChatScreen(
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
      ),
    );
  }
}