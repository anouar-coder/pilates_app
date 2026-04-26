// lib/services/chat_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message.dart';
import '../models/conversation.dart';
import '../models/profil.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Récupérer toutes les conversations de l'utilisateur connecté
  Stream<List<Conversation>> getConversations() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('utilisateurs')
        .doc(userId)
        .collection('conversations')
        .orderBy('derniereActivite', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Conversation.fromMap(doc.id, doc.data());
          }).toList();
        });
  }

  // Récupérer les messages d'une conversation
  Stream<List<Message>> getMessages(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Message.fromMap(doc.id, doc.data());
          }).toList();
        });
  }

  // Envoyer un message
  Future<void> sendMessage(String conversationId, String contenu) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Récupérer les infos de l'utilisateur
    final userDoc = await _firestore
        .collection('utilisateurs')
        .doc(user.uid)
        .get();
    
    final userData = userDoc.data() as Map<String, dynamic>;
    final userNom = userData['nom'] ?? 'Utilisateur';
    final userPhoto = userData['photoUrl'];

    // Créer le message
    final message = Message(
      id: '', // Sera généré par Firestore
      conversationId: conversationId,
      expediteurId: user.uid,
      expediteurNom: userNom,
      expediteurPhoto: userPhoto,
      contenu: contenu,
      date: DateTime.now(),
      lu: false,
    );

    // Ajouter le message à la conversation
    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .add(message.toMap());

    // Mettre à jour le dernier message de la conversation
    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .update({
          'dernierMessage': contenu,
          'derniereActivite': Timestamp.now(),
        });

    // Récupérer l'ID de l'autre utilisateur
    final convDoc = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .get();
    
    final convData = convDoc.data() as Map<String, dynamic>;
    final user1Id = convData['user1Id'];
    final user2Id = convData['user2Id'];
    final autreUserId = user1Id == user.uid ? user2Id : user1Id;

    // Mettre à jour la conversation de l'autre utilisateur
    await _firestore
        .collection('utilisateurs')
        .doc(autreUserId)
        .collection('conversations')
        .doc(conversationId)
        .update({
          'dernierMessage': contenu,
          'derniereActivite': Timestamp.now(),
          'messagesNonLus': FieldValue.increment(1),
        });
  }

  // Créer une nouvelle conversation
  Future<String> createConversation(String autreUserId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');

    // Vérifier si une conversation existe déjà (deux requêtes car whereIn sur deux champs n'est pas supporté)
    final conv1 = await _firestore
        .collection('conversations')
        .where('user1Id', isEqualTo: user.uid)
        .where('user2Id', isEqualTo: autreUserId)
        .limit(1)
        .get();
    if (conv1.docs.isNotEmpty) return conv1.docs.first.id;

    final conv2 = await _firestore
        .collection('conversations')
        .where('user1Id', isEqualTo: autreUserId)
        .where('user2Id', isEqualTo: user.uid)
        .limit(1)
        .get();
    if (conv2.docs.isNotEmpty) return conv2.docs.first.id;

    // Récupérer les infos de l'autre utilisateur
    final autreUserDoc = await _firestore
        .collection('utilisateurs')
        .doc(autreUserId)
        .get();
    
    final autreUserData = autreUserDoc.data() as Map<String, dynamic>;
    final autreUserNom = autreUserData['nom'] ?? 'Utilisateur';
    final autreUserPhoto = autreUserData['photoUrl'];

    // Récupérer les infos de l'utilisateur connecté
    final currentUserDoc = await _firestore
        .collection('utilisateurs')
        .doc(user.uid)
        .get();

    final currentUserData = currentUserDoc.data() as Map<String, dynamic>;

    // Créer la conversation
    final conversationData = {
      'user1Id': user.uid,
      'user2Id': autreUserId,
      'dernierMessage': '',
      'derniereActivite': Timestamp.now(),
    };

    final convRef = await _firestore
        .collection('conversations')
        .add(conversationData);

    // Ajouter la conversation pour l'utilisateur connecté
    await _firestore
        .collection('utilisateurs')
        .doc(user.uid)
        .collection('conversations')
        .doc(convRef.id)
        .set({
          'autreUtilisateurId': autreUserId,
          'autreUtilisateurNom': autreUserNom,
          'autreUtilisateurPhoto': autreUserPhoto,
          'dernierMessage': '',
          'derniereActivite': Timestamp.now(),
          'messagesNonLus': 0,
        });

    // Ajouter la conversation pour l'autre utilisateur
    await _firestore
        .collection('utilisateurs')
        .doc(autreUserId)
        .collection('conversations')
        .doc(convRef.id)
        .set({
          'autreUtilisateurId': user.uid,
          'autreUtilisateurNom': currentUserData['nom'] ?? 'Utilisateur',
          'autreUtilisateurPhoto': currentUserData['photoUrl'],
          'dernierMessage': '',
          'derniereActivite': Timestamp.now(),
          'messagesNonLus': 0,
        });

    return convRef.id;
  }

  // Marquer les messages comme lus
  Future<void> markMessagesAsRead(String conversationId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Récupérer tous les messages non lus, filtrer côté client pour éviter l'index composite
    final unreadMessages = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .where('lu', isEqualTo: false)
        .get();

    // Marquer comme lus uniquement les messages des autres (pas les siens)
    for (var doc in unreadMessages.docs) {
      if (doc.data()['expediteurId'] != user.uid) {
        await doc.reference.update({'lu': true});
      }
    }

    // Réinitialiser le compteur de messages non lus
    await _firestore
        .collection('utilisateurs')
        .doc(user.uid)
        .collection('conversations')
        .doc(conversationId)
        .update({'messagesNonLus': 0});
  }

  // Récupérer la liste des clients pour l'admin
  Stream<List<Profil>> getClients() {
    final currentUserId = _auth.currentUser?.uid;
    
    return _firestore
        .collection('utilisateurs')
        .snapshots()
        .map((snapshot) {
          final clients = snapshot.docs.where((doc) {
            if (doc.id == currentUserId) return false;
            final data = doc.data();
            final role = data['role'];
            return role == 'client' || role == null;
          }).toList();
          
          return clients.map((doc) {
            return Profil.fromMap(doc.id, doc.data());
          }).toList();
        });
  }
}