// lib/services/firebase_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/cours.dart';
import '../models/reservation.dart';
import 'attente_service.dart';

class FirebaseService {
  final CollectionReference _coursCollection = 
      FirebaseFirestore.instance.collection('cours');
  final CollectionReference _reservationsCollection = 
      FirebaseFirestore.instance.collection('reservations');
  final CollectionReference _utilisateursCollection = 
      FirebaseFirestore.instance.collection('utilisateurs');

  // ----- GESTION DES COURS -----
  
  Stream<List<Cours>> getCours() {
    return _coursCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Cours.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  Future<void> addCours(Cours cours) async {
    await _coursCollection.doc(cours.id).set(cours.toMap());
  }

  Future<void> updateCours(Cours cours) async {
    await _coursCollection.doc(cours.id).update(cours.toMap());
  }

  Future<void> deleteCours(String coursId) async {
    await _coursCollection.doc(coursId).delete();
  }

  // ----- GESTION DES RÉSERVATIONS -----
  
  Future<bool> reserverCours(String coursId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      debugPrint('❌ Utilisateur non connecté');
      return false;
    }

    try {
      // Vérification admin
      final userDoc = await _utilisateursCollection.doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final role = userData['role'] ?? 'client';
        if (role == 'admin') {
          debugPrint('❌ Les admins ne peuvent pas réserver');
          return false;
        }
      }

      // Vérifier si le cours existe
      final coursDoc = await _coursCollection.doc(coursId).get();
      if (!coursDoc.exists) {
        debugPrint('❌ Cours non trouvé');
        return false;
      }
      
      final cours = Cours.fromMap(coursDoc.data() as Map<String, dynamic>);
      debugPrint('📊 Cours: ${cours.titre}, places: ${cours.placesRestantes}/${cours.placesMax}');
      
      // Vérifier les places disponibles
      if (cours.placesRestantes <= 0) {
        debugPrint('❌ Plus de places disponibles');
        return false;
      }

      // Vérifier si l'utilisateur a déjà réservé
      final existingReservation = await _reservationsCollection
          .where('utilisateurId', isEqualTo: userId)
          .where('coursId', isEqualTo: coursId)
          .get();

      if (existingReservation.docs.isNotEmpty) {
        debugPrint('❌ Réservation déjà existante');
        return false;
      }

      // Créer la réservation
      final reservationId = DateTime.now().millisecondsSinceEpoch.toString();
      final reservation = Reservation(
        id: reservationId,
        utilisateurId: userId,
        coursId: coursId,
        dateReservation: DateTime.now(),
        estPaye: false,
      );

      // Ajouter la réservation
      await _reservationsCollection.doc(reservationId).set(reservation.toMap());
      debugPrint('✅ Réservation créée avec ID: $reservationId');
      
      // Mettre à jour le nombre de places
      await _coursCollection.doc(coursId).update({
        'placesRestantes': cours.placesRestantes - 1,
      });
      debugPrint('✅ Places mises à jour: ${cours.placesRestantes - 1}');

      return true;
    } catch (e) {
      debugPrint('❌ Erreur: $e');
      return false;
    }
  }

  Future<bool> annulerReservation(String reservationId, String coursId) async {
    try {
      final coursDoc = await _coursCollection.doc(coursId).get();
      if (!coursDoc.exists) return false;
      
      final cours = Cours.fromMap(coursDoc.data() as Map<String, dynamic>);

      await _reservationsCollection.doc(reservationId).delete();
      
      await _coursCollection.doc(coursId).update({
        'placesRestantes': cours.placesRestantes + 1,
      });

      debugPrint('✅ Annulation réussie');

      // Déclencher la vérification de la liste d'attente
      await AttenteService().verifierPlacesDisponibles(coursId);

      return true;
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'annulation: $e');
      return false;
    }
  }

  Stream<List<Reservation>> getMesReservations() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _reservationsCollection
        .where('utilisateurId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Reservation.fromMap(doc.data() as Map<String, dynamic>);
          }).toList();
        });
  }

  Future<Cours?> getCoursById(String coursId) async {
    try {
      final doc = await _coursCollection.doc(coursId).get();
      if (doc.exists) {
        return Cours.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération du cours: $e');
      return null;
    }
  }

  // ----- GESTION DES UTILISATEURS -----
  
  Future<Map<String, dynamic>?> getUtilisateur(String userId) async {
    try {
      final doc = await _utilisateursCollection.doc(userId).get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération de l\'utilisateur: $e');
      return null;
    }
  }

  Future<void> updateProfil(String userId, Map<String, dynamic> data) async {
    await _utilisateursCollection.doc(userId).update(data);
  }

  // ----- DÉCONNEXION -----
  Future<void> deconnexion() async {
    await FirebaseAuth.instance.signOut();
  }
}