//lib/models/cours.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Cours {
  final String id;
  final String titre;
  final DateTime date;
  final int duree;
  final int placesMax;
  final int placesRestantes;
  final String niveau;
  final String coach;
  final String description;
  final double? noteMoyenne;      // ← NOUVEAU
  final int? nombreAvis;           // ← NOUVEAU

  Cours({
    required this.id,
    required this.titre,
    required this.date,
    required this.duree,
    required this.placesMax,
    required this.placesRestantes,
    required this.niveau,
    required this.coach,
    required this.description,
    this.noteMoyenne,              // ← NOUVEAU
    this.nombreAvis,                // ← NOUVEAU
  });

  // Constructeur vide pour les cas par défaut
  Cours.empty()
      : id = '',
        titre = '',
        date = DateTime.now(),
        duree = 0,
        placesMax = 0,
        placesRestantes = 0,
        niveau = '',
        coach = '',
        description = '',
        noteMoyenne = 0,            // ← NOUVEAU
        nombreAvis = 0;              // ← NOUVEAU

  factory Cours.fromMap(Map<String, dynamic> map) {
    final dateField = map['date'];
    final date = dateField is Timestamp
        ? dateField.toDate()
        : DateTime.parse(dateField ?? DateTime.now().toIso8601String());
    return Cours(
      id: map['id'] ?? '',
      titre: map['titre'] ?? '',
      date: date,
      duree: map['duree'] ?? 0,
      placesMax: map['placesMax'] ?? 0,
      placesRestantes: map['placesRestantes'] ?? 0,
      niveau: map['niveau'] ?? '',
      coach: map['coach'] ?? '',
      description: map['description'] ?? '',
      noteMoyenne: (map['noteMoyenne'] ?? 0).toDouble(),
      nombreAvis: map['nombreAvis'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titre': titre,
      'date': date.toIso8601String(),
      'duree': duree,
      'placesMax': placesMax,
      'placesRestantes': placesRestantes,
      'niveau': niveau,
      'coach': coach,
      'description': description,
      'noteMoyenne': noteMoyenne ?? 0,                          // ← NOUVEAU
      'nombreAvis': nombreAvis ?? 0,                            // ← NOUVEAU
    };
  }
}