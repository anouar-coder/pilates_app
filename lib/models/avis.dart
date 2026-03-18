//lib/models/avis.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Avis {
  final String id;
  final String coursId;
  final String coursTitre;
  final String utilisateurId;
  final String utilisateurNom;
  final String? utilisateurPhoto;
  final int note; // 1 à 5
  final String? commentaire;
  final DateTime date;
  final bool visible; // Pour modération admin

  Avis({
    required this.id,
    required this.coursId,
    required this.coursTitre,
    required this.utilisateurId,
    required this.utilisateurNom,
    this.utilisateurPhoto,
    required this.note,
    this.commentaire,
    required this.date,
    this.visible = true,
  });

  factory Avis.fromMap(String id, Map<String, dynamic> map) {
    return Avis(
      id: id,
      coursId: map['coursId'] ?? '',
      coursTitre: map['coursTitre'] ?? '',
      utilisateurId: map['utilisateurId'] ?? '',
      utilisateurNom: map['utilisateurNom'] ?? '',
      utilisateurPhoto: map['utilisateurPhoto'],
      note: map['note'] ?? 5,
      commentaire: map['commentaire'],
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      visible: map['visible'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'coursId': coursId,
      'coursTitre': coursTitre,
      'utilisateurId': utilisateurId,
      'utilisateurNom': utilisateurNom,
      'utilisateurPhoto': utilisateurPhoto,
      'note': note,
      'commentaire': commentaire,
      'date': Timestamp.fromDate(date),
      'visible': visible,
    };
  }
}
