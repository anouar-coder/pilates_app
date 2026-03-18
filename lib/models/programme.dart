//lib/models/programme.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Programme {
  final String id;
  final String coachId;
  final String coachNom;
  final String titre;
  final String description;
  final String niveau; // Débutant, Intermédiaire, Avancé
  final int dureeJours; // Durée totale en jours
  final List<String> tags;
  final String? imageUrl;
  final DateTime dateCreation;
  final bool publie; // Visible pour les clients ?

  Programme({
    required this.id,
    required this.coachId,
    required this.coachNom,
    required this.titre,
    required this.description,
    required this.niveau,
    required this.dureeJours,
    required this.tags,
    this.imageUrl,
    required this.dateCreation,
    this.publie = true,
  });

  factory Programme.fromMap(String id, Map<String, dynamic> map) {
    return Programme(
      id: id,
      coachId: map['coachId'] ?? '',
      coachNom: map['coachNom'] ?? '',
      titre: map['titre'] ?? '',
      description: map['description'] ?? '',
      niveau: map['niveau'] ?? 'Débutant',
      dureeJours: map['dureeJours'] ?? 7,
      tags: List<String>.from(map['tags'] ?? []),
      imageUrl: map['imageUrl'],
      dateCreation: (map['dateCreation'] as Timestamp?)?.toDate() ?? DateTime.now(),
      publie: map['publie'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'coachId': coachId,
      'coachNom': coachNom,
      'titre': titre,
      'description': description,
      'niveau': niveau,
      'dureeJours': dureeJours,
      'tags': tags,
      'imageUrl': imageUrl,
      'dateCreation': Timestamp.fromDate(dateCreation),
      'publie': publie,
    };
  }
}
