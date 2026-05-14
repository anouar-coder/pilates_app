//lib/models/profil.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Profil {
  final String id;
  final String nom;
  final String email;
  final String? telephone;
  final String? photoUrl;
  final String niveau;
  final String? objectifs;
  final DateTime dateInscription;
  final int coursSuivis;
  final int totalHeures;
  final int coursReserves;
  final int coursAnnules;
  final double noteMoyenne;
  final String role; // ← AJOUTE CETTE LIGNE

  Profil({
    required this.id,
    required this.nom,
    required this.email,
    this.telephone,
    this.photoUrl,
    required this.niveau,
    this.objectifs,
    required this.dateInscription,
    this.coursSuivis = 0,
    this.totalHeures = 0,
    this.coursReserves = 0,
    this.coursAnnules = 0,
    this.noteMoyenne = 0.0,
    this.role = 'client', // ← AJOUTE CETTE LIGNE
  });

  factory Profil.fromMap(String id, Map<String, dynamic> map) {
    final dateField = map['dateInscription'];
    final dateInscription = dateField is Timestamp
        ? dateField.toDate()
        : DateTime.parse(dateField ?? DateTime.now().toIso8601String());
    return Profil(
      id: id,
      nom: map['nom'] ?? '',
      email: map['email'] ?? '',
      telephone: map['telephone'],
      photoUrl: map['photoUrl'],
      niveau: map['niveau'] ?? 'Débutant',
      objectifs: map['objectifs'],
      dateInscription: dateInscription,
      coursSuivis: map['coursSuivis'] ?? 0,
      totalHeures: map['totalHeures'] ?? 0,
      coursReserves: map['coursReserves'] ?? 0,
      coursAnnules: map['coursAnnules'] ?? 0,
      noteMoyenne: (map['noteMoyenne'] ?? 0.0).toDouble(),
      role: map['role'] ?? 'client',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'email': email,
      'telephone': telephone,
      'photoUrl': photoUrl,
      'niveau': niveau,
      'objectifs': objectifs,
      'dateInscription': dateInscription.toIso8601String(),
      'coursSuivis': coursSuivis,
      'totalHeures': totalHeures,
      'coursReserves': coursReserves,
      'coursAnnules': coursAnnules,
      'noteMoyenne': noteMoyenne,
      'role': role, // ← AJOUTE CETTE LIGNE
    };
  }

  Profil copyWith({
    String? nom,
    String? email,
    String? telephone,
    String? photoUrl,
    String? niveau,
    String? objectifs,
    int? coursSuivis,
    int? totalHeures,
    int? coursReserves,
    int? coursAnnules,
    double? noteMoyenne,
    String? role, // ← AJOUTE CETTE LIGNE
  }) {
    return Profil(
      id: id,
      nom: nom ?? this.nom,
      email: email ?? this.email,
      telephone: telephone ?? this.telephone,
      photoUrl: photoUrl ?? this.photoUrl,
      niveau: niveau ?? this.niveau,
      objectifs: objectifs ?? this.objectifs,
      dateInscription: dateInscription,
      coursSuivis: coursSuivis ?? this.coursSuivis,
      totalHeures: totalHeures ?? this.totalHeures,
      coursReserves: coursReserves ?? this.coursReserves,
      coursAnnules: coursAnnules ?? this.coursAnnules,
      noteMoyenne: noteMoyenne ?? this.noteMoyenne,
      role: role ?? this.role, // ← AJOUTE CETTE LIGNE
    );
  }
}