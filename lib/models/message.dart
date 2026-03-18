//lib/models/message.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String conversationId;
  final String expediteurId;
  final String expediteurNom;
  final String? expediteurPhoto;
  final String contenu;
  final DateTime date;
  final bool lu;

  Message({
    required this.id,
    required this.conversationId,
    required this.expediteurId,
    required this.expediteurNom,
    this.expediteurPhoto,
    required this.contenu,
    required this.date,
    required this.lu,
  });

  factory Message.fromMap(String id, Map<String, dynamic> map) {
    return Message(
      id: id,
      conversationId: map['conversationId'] ?? '',
      expediteurId: map['expediteurId'] ?? '',
      expediteurNom: map['expediteurNom'] ?? '',
      expediteurPhoto: map['expediteurPhoto'],
      contenu: map['contenu'] ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lu: map['lu'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'conversationId': conversationId,
      'expediteurId': expediteurId,
      'expediteurNom': expediteurNom,
      'expediteurPhoto': expediteurPhoto,
      'contenu': contenu,
      'date': Timestamp.fromDate(date),
      'lu': lu,
    };
  }
}