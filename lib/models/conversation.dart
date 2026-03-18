//lib/models/conversation.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Conversation {
  final String id;
  final String autreUtilisateurId;
  final String autreUtilisateurNom;
  final String? autreUtilisateurPhoto;
  final String dernierMessage;
  final DateTime derniereActivite;
  final int messagesNonLus;

  Conversation({
    required this.id,
    required this.autreUtilisateurId,
    required this.autreUtilisateurNom,
    this.autreUtilisateurPhoto,
    required this.dernierMessage,
    required this.derniereActivite,
    required this.messagesNonLus,
  });

  factory Conversation.fromMap(String id, Map<String, dynamic> map) {
    return Conversation(
      id: id,
      autreUtilisateurId: map['autreUtilisateurId'] ?? '',
      autreUtilisateurNom: map['autreUtilisateurNom'] ?? '',
      autreUtilisateurPhoto: map['autreUtilisateurPhoto'],
      dernierMessage: map['dernierMessage'] ?? '',
      derniereActivite: (map['derniereActivite'] as Timestamp?)?.toDate() ?? DateTime.now(),
      messagesNonLus: (map['messagesNonLus'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'autreUtilisateurId': autreUtilisateurId,
      'autreUtilisateurNom': autreUtilisateurNom,
      'autreUtilisateurPhoto': autreUtilisateurPhoto,
      'dernierMessage': dernierMessage,
      'derniereActivite': Timestamp.fromDate(derniereActivite),
      'messagesNonLus': messagesNonLus,
    };
  }
}