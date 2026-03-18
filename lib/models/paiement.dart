// lib/models/paiement.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum TypePaiement {
  seance,
  pack,
  abonnement
}

enum StatutPaiement {
  enAttente,
  reussi,
  echec,
  rembourse
}

class Paiement {
  final String id;
  final String utilisateurId;
  final String utilisateurNom;
  final TypePaiement type;
  final String? coursId;
  final String? packId;
  final String? abonnementId;
  final double montant;
  final DateTime date;
  final StatutPaiement statut;
  final String stripePaymentIntentId;
  final String? stripePaymentMethodId;
  final Map<String, dynamic>? metadata;

  Paiement({
    required this.id,
    required this.utilisateurId,
    required this.utilisateurNom,
    required this.type,
    this.coursId,
    this.packId,
    this.abonnementId,
    required this.montant,
    required this.date,
    required this.statut,
    required this.stripePaymentIntentId,
    this.stripePaymentMethodId,
    this.metadata,
  });

  factory Paiement.fromMap(String id, Map<String, dynamic> map) {
    return Paiement(
      id: id,
      utilisateurId: map['utilisateurId'] ?? '',
      utilisateurNom: map['utilisateurNom'] ?? '',
      type: TypePaiement.values.firstWhere(
        (e) => e.toString() == 'TypePaiement.${map['type']}',
        orElse: () => TypePaiement.seance,
      ),
      coursId: map['coursId'],
      packId: map['packId'],
      abonnementId: map['abonnementId'],
      montant: (map['montant'] ?? 0).toDouble(),
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      statut: StatutPaiement.values.firstWhere(
        (e) => e.toString() == 'StatutPaiement.${map['statut']}',
        orElse: () => StatutPaiement.enAttente,
      ),
      stripePaymentIntentId: map['stripePaymentIntentId'] ?? '',
      stripePaymentMethodId: map['stripePaymentMethodId'],
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'utilisateurId': utilisateurId,
      'utilisateurNom': utilisateurNom,
      'type': type.toString().split('.').last,
      'coursId': coursId,
      'packId': packId,
      'abonnementId': abonnementId,
      'montant': montant,
      'date': Timestamp.fromDate(date),
      'statut': statut.toString().split('.').last,
      'stripePaymentIntentId': stripePaymentIntentId,
      'stripePaymentMethodId': stripePaymentMethodId,
      'metadata': metadata,
    };
  }
}