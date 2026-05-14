// lib/services/admin_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/cours.dart';
import '../models/reservation.dart';
import '../models/profil.dart';
import '../models/admin.dart';

class AdminService {
  final CollectionReference _coursCollection = 
      FirebaseFirestore.instance.collection('cours');
  final CollectionReference _reservationsCollection = 
      FirebaseFirestore.instance.collection('reservations');
  final CollectionReference _utilisateursCollection = 
      FirebaseFirestore.instance.collection('utilisateurs');

  // Vérifier si l'utilisateur est admin
  Future<bool> estAdmin() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return false;

    try {
      final doc = await _utilisateursCollection.doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['role'] == 'admin';
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ----- GESTION DES COURS -----
  Stream<List<Cours>> getAllCours() {
    return _coursCollection.snapshots().map((snapshot) {
      final now = DateTime.now();
      final coursList = snapshot.docs
        .map((doc) => Cours.fromMap(doc.data() as Map<String, dynamic>))
        .where((cours) => cours.date.add(Duration(minutes: cours.duree)).isAfter(now))
        .toList();
      coursList.sort((a, b) => a.date.compareTo(b.date));
      return coursList;
    });
  }

  Future<bool> creerCours(Cours cours) async {
    try {
      await _coursCollection.doc(cours.id).set(cours.toMap());
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> modifierCours(Cours cours) async {
    try {
      await _coursCollection.doc(cours.id).update(cours.toMap());
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> supprimerCours(String coursId) async {
    try {
      await _coursCollection.doc(coursId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  // ----- GESTION DES RÉSERVATIONS -----
  Stream<List<Reservation>> getAllReservations() {
    return _reservationsCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Reservation.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  Future<List<Map<String, dynamic>>> getReservationsWithDetails() async {
    try {
      final reservations = await _reservationsCollection.get();
      List<Map<String, dynamic>> resultats = [];

      for (var doc in reservations.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) continue;
          final reservation = Reservation.fromMap(data);

          final coursDoc = await _coursCollection.doc(reservation.coursId).get();
          final cours = coursDoc.exists
              ? Cours.fromMap(coursDoc.data() as Map<String, dynamic>)
              : null;

          final userDoc = await _utilisateursCollection.doc(reservation.utilisateurId).get();
          final user = userDoc.exists
              ? Profil.fromMap(reservation.utilisateurId, userDoc.data() as Map<String, dynamic>)
              : null;

          resultats.add({
            'reservation': reservation,
            'cours': cours,
            'utilisateur': user,
          });
        } catch (e) {
          debugPrint('❌ Réservation ignorée: $e');
        }
      }

      return resultats;
    } catch (e) {
      debugPrint('❌ Erreur récupération réservations: $e');
      return [];
    }
  }

  // ----- GESTION DES UTILISATEURS -----
  Stream<List<Profil>> getAllUtilisateurs() {
    return _utilisateursCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Profil.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  Future<bool> changerRoleUtilisateur(String userId, String nouveauRole) async {
    try {
      await _utilisateursCollection.doc(userId).update({'role': nouveauRole});
      return true;
    } catch (e) {
      return false;
    }
  }

  // ----- STATISTIQUES -----
  Future<AdminStats> getStatistiques() async {
    try {
      final now = DateTime.now();
      final coursSnapshot = await _coursCollection.get();
      final totalCours = coursSnapshot.docs
          .map((doc) => Cours.fromMap(doc.data() as Map<String, dynamic>))
          .where((c) => c.date.add(Duration(minutes: c.duree)).isAfter(now))
          .length;

      final reservationsSnapshot = await _reservationsCollection.get();
      final totalReservations = reservationsSnapshot.docs.length;

      final usersSnapshot = await _utilisateursCollection.get();
      final totalUtilisateurs = usersSnapshot.docs.length;

      double tauxRemplissage = 0;
      Map<String, int> coursPopulaires = {};
      int coursFutursCount = 0;

      for (var doc in coursSnapshot.docs) {
        final cours = Cours.fromMap(doc.data() as Map<String, dynamic>);
        if (cours.date.add(Duration(minutes: cours.duree)).isBefore(now)) continue;

        coursFutursCount++;
        final placesMax = cours.placesMax;
        final placesOccupees = placesMax - cours.placesRestantes;
        
        if (placesMax > 0) {
          tauxRemplissage += (placesOccupees / placesMax) * 100;
        }

        final reservationsCours = await _reservationsCollection
            .where('coursId', isEqualTo: cours.id)
            .get();
        coursPopulaires[cours.titre] = reservationsCours.docs.length;
      }

      tauxRemplissage = coursFutursCount > 0 ? tauxRemplissage / coursFutursCount : 0;

      var sortedEntries = coursPopulaires.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      coursPopulaires = Map.fromEntries(sortedEntries.take(5));

      return AdminStats(
        totalCours: totalCours,
        totalReservations: totalReservations,
        totalUtilisateurs: totalUtilisateurs,
        tauxRemplissage: tauxRemplissage,
        coursPopulaires: coursPopulaires,
        revenuTotal: totalReservations * 25.0,
      );
    } catch (e) {
      return AdminStats(
        totalCours: 0,
        totalReservations: 0,
        totalUtilisateurs: 0,
        tauxRemplissage: 0,
        coursPopulaires: {},
        revenuTotal: 0,
      );
    }
  }
}