// lib/services/programme_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/programme.dart';
import '../models/exercice.dart';
import '../models/seance.dart';

class ProgrammeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ----- CRÉATION DE PROGRAMMES (ADMIN) -----

  // Créer un nouveau programme
  Future<String?> creerProgramme(Programme programme) async {
    try {
      final docRef = await _firestore.collection('programmes').add(programme.toMap());
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Erreur création programme: $e');
      return null;
    }
  }

  // Ajouter une séance à un programme
  Future<bool> ajouterSeance(String programmeId, Seance seance) async {
    try {
      await _firestore
          .collection('programmes')
          .doc(programmeId)
          .collection('seances')
          .add(seance.toMap());
      return true;
    } catch (e) {
      debugPrint('❌ Erreur ajout séance: $e');
      return false;
    }
  }

  // Ajouter un exercice à une séance
  Future<bool> ajouterExercice(String programmeId, String seanceId, Exercice exercice) async {
    try {
      await _firestore
          .collection('programmes')
          .doc(programmeId)
          .collection('seances')
          .doc(seanceId)
          .collection('exercices')
          .add(exercice.toMap());
      return true;
    } catch (e) {
      debugPrint('❌ Erreur ajout exercice: $e');
      return false;
    }
  }

  // Supprimer une seance et ses exercices.
  Future<bool> supprimerSeance(String programmeId, String seanceId) async {
    try {
      final seanceRef = _firestore
          .collection('programmes')
          .doc(programmeId)
          .collection('seances')
          .doc(seanceId);

      final exercices = await seanceRef.collection('exercices').get();
      final batch = _firestore.batch();

      for (final doc in exercices.docs) {
        batch.delete(doc.reference);
      }

      batch.delete(seanceRef);
      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Erreur suppression seance: $e');
      return false;
    }
  }

  // ----- LECTURE DE PROGRAMMES (CLIENT) - SANS INDEX -----

  // Récupérer tous les programmes publiés (sans orderBy)
  Stream<List<Programme>> getProgrammesPublies() {
    return _firestore
        .collection('programmes')
        .where('publie', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final programmes = snapshot.docs.map((doc) {
            return Programme.fromMap(doc.id, doc.data());
          }).toList();
          
          // Trier manuellement côté client
          programmes.sort((a, b) => b.dateCreation.compareTo(a.dateCreation));
          
          return programmes;
        });
  }

  // Récupérer les séances d'un programme (sans orderBy)
  Stream<List<Seance>> getSeances(String programmeId) {
    return _firestore
        .collection('programmes')
        .doc(programmeId)
        .collection('seances')
        .snapshots()
        .asyncMap((snapshot) async {
          List<Seance> seances = [];
          for (var doc in snapshot.docs) {
            // Récupérer les exercices de chaque séance
            final exercicesSnapshot = await doc.reference
                .collection('exercices')
                .get();
            
            final exercices = exercicesSnapshot.docs.map((eDoc) {
              return Exercice.fromMap(eDoc.id, eDoc.data());
            }).toList();

            seances.add(Seance.fromMap(doc.id, doc.data(), exercices));
          }
          
          // Trier par jour manuellement
          seances.sort((a, b) => a.jour.compareTo(b.jour));
          
          return seances;
        });
  }

  // ----- SUIVI CLIENT -----

  // Assigner un programme à un client
  Future<bool> assignerProgramme(String clientId, String programmeId) async {
    try {
      await _firestore
          .collection('utilisateurs')
          .doc(clientId)
          .collection('programmes_assignes')
          .doc(programmeId)
          .set({
            'programmeId': programmeId,
            'dateDebut': Timestamp.now(),
            'termine': false,
          });
      return true;
    } catch (e) {
      debugPrint('❌ Erreur assignation programme: $e');
      return false;
    }
  }

  // Marquer un exercice comme fait
  Future<bool> marquerExerciceFait(
    String programmeId,
    String seanceId,
    String exerciceId,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      await _firestore
          .collection('utilisateurs')
          .doc(user.uid)
          .collection('programmes_assignes')
          .doc(programmeId)
          .collection('progression')
          .doc('${seanceId}_$exerciceId')
          .set({
            'seanceId': seanceId,
            'exerciceId': exerciceId,
            'fait': true,
            'date': Timestamp.now(),
          });
      return true;
    } catch (e) {
      debugPrint('❌ Erreur marquage exercice: $e');
      return false;
    }
  }

  // Récupérer la progression d'un programme
  Future<Map<String, bool>> getProgression(String programmeId) async {
    final user = _auth.currentUser;
    if (user == null) return {};

    try {
      final snapshot = await _firestore
          .collection('utilisateurs')
          .doc(user.uid)
          .collection('programmes_assignes')
          .doc(programmeId)
          .collection('progression')
          .get();

      Map<String, bool> progression = {};
      for (var doc in snapshot.docs) {
        progression[doc.id] = doc.data()['fait'] ?? false;
      }
      return progression;
    } catch (e) {
      return {};
    }
  }

  // ----- FONCTIONS ADMIN - SANS INDEX -----

  // Récupérer tous les programmes (pour admin) - sans orderBy
  Stream<List<Programme>> getAllProgrammes() {
    return _firestore
        .collection('programmes')
        .snapshots()
        .map((snapshot) {
          final programmes = snapshot.docs.map((doc) {
            return Programme.fromMap(doc.id, doc.data());
          }).toList();
          
          // Trier manuellement
          programmes.sort((a, b) => b.dateCreation.compareTo(a.dateCreation));
          
          return programmes;
        });
  }

  // Mettre à jour un programme
  Future<bool> updateProgramme(Programme programme) async {
    try {
      await _firestore
          .collection('programmes')
          .doc(programme.id)
          .update(programme.toMap());
      return true;
    } catch (e) {
      debugPrint('❌ Erreur mise à jour: $e');
      return false;
    }
  }

  // Supprimer un programme
  Future<bool> deleteProgramme(String programmeId) async {
    try {
      await _firestore.collection('programmes').doc(programmeId).delete();
      return true;
    } catch (e) {
      debugPrint('❌ Erreur suppression: $e');
      return false;
    }
  }
}

