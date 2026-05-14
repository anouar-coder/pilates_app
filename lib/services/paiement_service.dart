// lib/services/paiement_service.dart
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/stripe_config.dart';
import '../models/paiement.dart';

class PaiementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Initialiser Stripe
  static void initialize() {
    Stripe.publishableKey = StripeConfig.publishableKey;
  }

  // Payer une séance individuelle
  Future<bool> payerSeance({
    required String coursId,
    required String titreCours,
    required double montant,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('❌ Utilisateur non connecté');
      return false;
    }

    try {
      // 1. Créer un PaymentIntent
      final paymentIntent = await _createPaymentIntent(
        amount: montant,
        currency: 'eur',
        metadata: {
          'type': 'seance',
          'coursId': coursId,
          'coursTitre': titreCours,
          'utilisateurId': user.uid,
        },
      );

      if (paymentIntent == null) return false;

      // 2. Initialiser le paiement Stripe
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntent['client_secret'],
          merchantDisplayName: 'Pilates Studio',
          style: ThemeMode.light,
        ),
      );

      // 3. Afficher la feuille de paiement
      await Stripe.instance.presentPaymentSheet();

      // 4. Si le paiement réussit, confirmer la réservation
      return await _confirmerPaiementSeance(
        utilisateurId: user.uid,
        utilisateurNom: await _getUserNom(user.uid),
        coursId: coursId,
        titreCours: titreCours,
        montant: montant,
        paymentIntentId: paymentIntent['id'],
      );

    } catch (e) {
      debugPrint('❌ Erreur paiement: $e');
      return false;
    }
  }

  // Payer un pack de séances
  Future<bool> payerPack({
    required String packId,
    required String packNom,
    required double montant,
    required int nombreSeances,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('❌ Utilisateur non connecté');
      return false;
    }

    try {
      final paymentIntent = await _createPaymentIntent(
        amount: montant,
        currency: 'eur',
        metadata: {
          'type': 'pack',
          'packId': packId,
          'packNom': packNom,
          'nombreSeances': nombreSeances,
          'utilisateurId': user.uid,
        },
      );

      if (paymentIntent == null) return false;

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntent['client_secret'],
          merchantDisplayName: 'Pilates Studio',
          style: ThemeMode.light,
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      return await _confirmerPaiementPack(
        utilisateurId: user.uid,
        utilisateurNom: await _getUserNom(user.uid),
        packId: packId,
        packNom: packNom,
        montant: montant,
        nombreSeances: nombreSeances,
        paymentIntentId: paymentIntent['id'],
      );

    } catch (e) {
      debugPrint('❌ Erreur paiement pack: $e');
      return false;
    }
  }

  // Payer un abonnement
  Future<bool> payerAbonnement({
    required String abonnementId,
    required String abonnementNom,
    required double montant,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('❌ Utilisateur non connecté');
      return false;
    }

    try {
      final paymentIntent = await _createPaymentIntent(
        amount: montant,
        currency: 'eur',
        metadata: {
          'type': 'abonnement',
          'abonnementId': abonnementId,
          'abonnementNom': abonnementNom,
          'utilisateurId': user.uid,
        },
      );

      if (paymentIntent == null) return false;

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntent['client_secret'],
          merchantDisplayName: 'Pilates Studio',
          style: ThemeMode.light,
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      return await _confirmerPaiementAbonnement(
        utilisateurId: user.uid,
        utilisateurNom: await _getUserNom(user.uid),
        abonnementId: abonnementId,
        abonnementNom: abonnementNom,
        montant: montant,
        paymentIntentId: paymentIntent['id'],
      );

    } catch (e) {
      debugPrint('❌ Erreur paiement abonnement: $e');
      return false;
    }
  }

  // Créer un PaymentIntent via l'API Stripe
  Future<Map<String, dynamic>?> _createPaymentIntent({
    required double amount,
    required String currency,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer ${StripeConfig.secretKey}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'amount': (amount * 100).toInt().toString(),
          'currency': currency,
          'metadata[type]': metadata['type'],
          if (metadata.containsKey('coursId')) 'metadata[coursId]': metadata['coursId'],
          if (metadata.containsKey('packId')) 'metadata[packId]': metadata['packId'],
          if (metadata.containsKey('abonnementId')) 'metadata[abonnementId]': metadata['abonnementId'],
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint('❌ Erreur Stripe: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Exception: $e');
      return null;
    }
  }

  // Confirmer le paiement d'une séance
  Future<bool> _confirmerPaiementSeance({
    required String utilisateurId,
    required String utilisateurNom,
    required String coursId,
    required String titreCours,
    required double montant,
    required String paymentIntentId,
  }) async {
    try {
      // 1. Sauvegarder le paiement
      final paiement = Paiement(
        id: '',
        utilisateurId: utilisateurId,
        utilisateurNom: utilisateurNom,
        type: TypePaiement.seance,
        coursId: coursId,
        montant: montant,
        date: DateTime.now(),
        statut: StatutPaiement.reussi,
        stripePaymentIntentId: paymentIntentId,
        metadata: {'titreCours': titreCours},
      );

      await _firestore
          .collection('utilisateurs')
          .doc(utilisateurId)
          .collection('paiements')
          .add(paiement.toMap());

      // 2. Mettre à jour la réservation
      final reservations = await _firestore
          .collection('reservations')
          .where('utilisateurId', isEqualTo: utilisateurId)
          .where('coursId', isEqualTo: coursId)
          .limit(1)
          .get();

      if (reservations.docs.isNotEmpty) {
        await reservations.docs.first.reference.update({
          'estPaye': true,
        });
      }

      return true;
    } catch (e) {
      debugPrint('❌ Erreur confirmation: $e');
      return false;
    }
  }

  // Confirmer le paiement d'un pack
  Future<bool> _confirmerPaiementPack({
    required String utilisateurId,
    required String utilisateurNom,
    required String packId,
    required String packNom,
    required double montant,
    required int nombreSeances,
    required String paymentIntentId,
  }) async {
    try {
      final paiement = Paiement(
        id: '',
        utilisateurId: utilisateurId,
        utilisateurNom: utilisateurNom,
        type: TypePaiement.pack,
        packId: packId,
        montant: montant,
        date: DateTime.now(),
        statut: StatutPaiement.reussi,
        stripePaymentIntentId: paymentIntentId,
        metadata: {'packNom': packNom, 'nombreSeances': nombreSeances},
      );

      await _firestore
          .collection('utilisateurs')
          .doc(utilisateurId)
          .collection('paiements')
          .add(paiement.toMap());

      // Ajouter les séances au compte de l'utilisateur
      await _firestore
          .collection('utilisateurs')
          .doc(utilisateurId)
          .update({
            'seancesRestantes': FieldValue.increment(nombreSeances),
          });

      return true;
    } catch (e) {
      debugPrint('❌ Erreur confirmation pack: $e');
      return false;
    }
  }

  // Confirmer le paiement d'un abonnement
  Future<bool> _confirmerPaiementAbonnement({
    required String utilisateurId,
    required String utilisateurNom,
    required String abonnementId,
    required String abonnementNom,
    required double montant,
    required String paymentIntentId,
  }) async {
    try {
      // Calculer la date de fin selon l'abonnement
      DateTime dateFin;
      switch (abonnementId) {
        case 'mensuel':
          dateFin = DateTime.now().add(const Duration(days: 30));
          break;
        case 'trimestriel':
          dateFin = DateTime.now().add(const Duration(days: 90));
          break;
        case 'annuel':
          dateFin = DateTime.now().add(const Duration(days: 365));
          break;
        default:
          dateFin = DateTime.now().add(const Duration(days: 30));
      }

      final paiement = Paiement(
        id: '',
        utilisateurId: utilisateurId,
        utilisateurNom: utilisateurNom,
        type: TypePaiement.abonnement,
        abonnementId: abonnementId,
        montant: montant,
        date: DateTime.now(),
        statut: StatutPaiement.reussi,
        stripePaymentIntentId: paymentIntentId,
        metadata: {'abonnementNom': abonnementNom, 'dateFin': dateFin.toIso8601String()},
      );

      await _firestore
          .collection('utilisateurs')
          .doc(utilisateurId)
          .collection('paiements')
          .add(paiement.toMap());

      // Mettre à jour l'abonnement de l'utilisateur
      await _firestore
          .collection('utilisateurs')
          .doc(utilisateurId)
          .update({
            'abonnement': {
              'id': abonnementId,
              'nom': abonnementNom,
              'dateDebut': DateTime.now().toIso8601String(),
              'dateFin': dateFin.toIso8601String(),
              'actif': true,
            },
          });

      return true;
    } catch (e) {
      debugPrint('❌ Erreur confirmation abonnement: $e');
      return false;
    }
  }

  // Récupérer le nom de l'utilisateur
  Future<String> _getUserNom(String userId) async {
    try {
      final doc = await _firestore
          .collection('utilisateurs')
          .doc(userId)
          .get();
      final data = doc.data() as Map<String, dynamic>;
      return data['nom'] ?? 'Utilisateur';
    } catch (e) {
      return 'Utilisateur';
    }
  }

  // Récupérer l'historique des paiements
  Stream<List<Paiement>> getHistoriquePaiements() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('utilisateurs')
        .doc(userId)
        .collection('paiements')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Paiement.fromMap(doc.id, doc.data());
          }).toList();
        });
  }

  // Récupérer les packs disponibles
  List<Map<String, dynamic>> getPacksDisponibles() {
    return [
      {
        'id': 'pack5',
        'nom': 'Pack 5 séances',
        'prix': 100.0,
        'seances': 5,
        'description': 'Économisez 20% sur vos séances',
        'economie': '20%',
      },
      {
        'id': 'pack10',
        'nom': 'Pack 10 séances',
        'prix': 180.0,
        'seances': 10,
        'description': 'Économisez 28% sur vos séances',
        'economie': '28%',
      },
      {
        'id': 'pack20',
        'nom': 'Pack 20 séances',
        'prix': 320.0,
        'seances': 20,
        'description': 'Économisez 36% sur vos séances',
        'economie': '36%',
      },
    ];
  }

  // Récupérer les abonnements disponibles
  List<Map<String, dynamic>> getAbonnementsDisponibles() {
    return [
      {
        'id': 'mensuel',
        'nom': 'Abonnement mensuel',
        'prix': 80.0,
        'description': 'Cours illimités pendant 1 mois',
        'parMois': '80€/mois',
      },
      {
        'id': 'trimestriel',
        'nom': 'Abonnement trimestriel',
        'prix': 210.0,
        'description': 'Cours illimités pendant 3 mois',
        'parMois': '70€/mois',
        'economie': 'Économisez 30€',
      },
      {
        'id': 'annuel',
        'nom': 'Abonnement annuel',
        'prix': 720.0,
        'description': 'Cours illimités pendant 1 an',
        'parMois': '60€/mois',
        'economie': 'Économisez 240€',
      },
    ];
  }

  // Vérifier le solde de séances de l'utilisateur
  Future<int> getSeancesRestantes() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return 0;

    try {
      final doc = await _firestore
          .collection('utilisateurs')
          .doc(userId)
          .get();
      final data = doc.data() as Map<String, dynamic>;
      return data['seancesRestantes'] ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // Vérifier l'abonnement de l'utilisateur
  Future<Map<String, dynamic>?> getAbonnementActif() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;

    try {
      final doc = await _firestore
          .collection('utilisateurs')
          .doc(userId)
          .get();
      final data = doc.data() as Map<String, dynamic>;
      return data['abonnement'] as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }
}
