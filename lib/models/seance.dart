//lib/models/seance.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'exercice.dart';

class Seance {
  final String id;
  final String programmeId;
  final int jour; // Jour 1, 2, 3...
  final String titre;
  final String description;
  final List<Exercice> exercices;
  final bool termine; // Pour le suivi client

  Seance({
    required this.id,
    required this.programmeId,
    required this.jour,
    required this.titre,
    required this.description,
    required this.exercices,
    this.termine = false,
  });

  factory Seance.fromMap(String id, Map<String, dynamic> map, List<Exercice> exercices) {
    return Seance(
      id: id,
      programmeId: map['programmeId'] ?? '',
      jour: map['jour'] ?? 1,
      titre: map['titre'] ?? '',
      description: map['description'] ?? '',
      exercices: exercices,
      termine: map['termine'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'programmeId': programmeId,
      'jour': jour,
      'titre': titre,
      'description': description,
      'termine': termine,
    };
  }
}
