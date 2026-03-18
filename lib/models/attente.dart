//lib/models/attente.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum StatutAttente {
  enAttente,      // En attente d'une place
  notifie,        // A été notifié d'une place disponible
  expire,         // Le délai de réservation a expiré
  reserve,        // A réservé le cours
  annule          // A quitté la liste d'attente
}

class Attente {
  final String id;
  final String coursId;
  final String coursTitre;
  final String utilisateurId;
  final String utilisateurNom;
  final DateTime dateInscription;
  final int position;
  final StatutAttente statut;
  final DateTime? dateNotification;
  final DateTime? dateExpiration;

  Attente({
    required this.id,
    required this.coursId,
    required this.coursTitre,
    required this.utilisateurId,
    required this.utilisateurNom,
    required this.dateInscription,
    required this.position,
    required this.statut,
    this.dateNotification,
    this.dateExpiration,
  });

  factory Attente.fromMap(String id, Map<String, dynamic> map) {
    return Attente(
      id: id,
      coursId: map['coursId'] ?? '',
      coursTitre: map['coursTitre'] ?? '',
      utilisateurId: map['utilisateurId'] ?? '',
      utilisateurNom: map['utilisateurNom'] ?? '',
      dateInscription: (map['dateInscription'] as Timestamp?)?.toDate() ?? DateTime.now(),
      position: map['position'] ?? 0,
      statut: StatutAttente.values.firstWhere(
        (e) => e.toString() == 'StatutAttente.${map['statut']}',
        orElse: () => StatutAttente.enAttente,
      ),
      dateNotification: (map['dateNotification'] as Timestamp?)?.toDate(),
      dateExpiration: (map['dateExpiration'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'coursId': coursId,
      'coursTitre': coursTitre,
      'utilisateurId': utilisateurId,
      'utilisateurNom': utilisateurNom,
      'dateInscription': Timestamp.fromDate(dateInscription),
      'position': position,
      'statut': statut.toString().split('.').last,
      'dateNotification': dateNotification != null ? Timestamp.fromDate(dateNotification!) : null,
      'dateExpiration': dateExpiration != null ? Timestamp.fromDate(dateExpiration!) : null,
    };
  }
}
