// lib/services/avis_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/avis.dart';

class AvisService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Ajouter un avis
  Future<bool> ajouterAvis({
    required String coursId,
    required String coursTitre,
    required int note,
    String? commentaire,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('❌ Utilisateur non connecté');
      return false;
    }

    try {
      // Récupérer les infos de l'utilisateur
      final userDoc = await _firestore
          .collection('utilisateurs')
          .doc(user.uid)
          .get();
      
      final userData = userDoc.data() as Map<String, dynamic>;
      final userNom = userData['nom'] ?? 'Utilisateur';
      final userPhoto = userData['photoUrl'];

      // Créer l'avis
      final avis = Avis(
        id: '',
        coursId: coursId,
        coursTitre: coursTitre,
        utilisateurId: user.uid,
        utilisateurNom: userNom,
        utilisateurPhoto: userPhoto,
        note: note,
        commentaire: commentaire,
        date: DateTime.now(),
        visible: true,
      );

      // Sauvegarder dans Firestore
      await _firestore
          .collection('cours')
          .doc(coursId)
          .collection('avis')
          .add(avis.toMap());

      // Mettre à jour la note moyenne du cours
      await _mettreAJourNoteMoyenne(coursId);

      debugPrint('✅ Avis ajouté avec succès');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur ajout avis: $e');
      return false;
    }
  }

  // Mettre à jour la note moyenne d'un cours
  Future<void> _mettreAJourNoteMoyenne(String coursId) async {
    try {
      final avisSnapshot = await _firestore
          .collection('cours')
          .doc(coursId)
          .collection('avis')
          .where('visible', isEqualTo: true)
          .get();

      if (avisSnapshot.docs.isEmpty) {
        await _firestore.collection('cours').doc(coursId).update({
          'noteMoyenne': 0,
          'nombreAvis': 0,
        });
        return;
      }

      double somme = 0;
      for (var doc in avisSnapshot.docs) {
        somme += (doc.data()['note'] ?? 0).toDouble();
      }

      double moyenne = somme / avisSnapshot.docs.length;

      await _firestore.collection('cours').doc(coursId).update({
        'noteMoyenne': moyenne,
        'nombreAvis': avisSnapshot.docs.length,
      });
    } catch (e) {
      debugPrint('❌ Erreur mise à jour note moyenne: $e');
    }
  }

  // Récupérer les avis d'un cours
  Stream<List<Avis>> getAvisPourCours(String coursId) {
    return _firestore
        .collection('cours')
        .doc(coursId)
        .collection('avis')
        .where('visible', isEqualTo: true)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Avis.fromMap(doc.id, doc.data());
          }).toList();
        });
  }

  // VERSION SIMPLIFIÉE POUR TEST - TOUJOURS AUTORISÉ
  Future<bool> peutLaisserAvis(String coursId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      // Vérifier seulement s'il a déjà laissé un avis
      final avisExistant = await _firestore
          .collection('cours')
          .doc(coursId)
          .collection('avis')
          .where('utilisateurId', isEqualTo: user.uid)
          .limit(1)
          .get();

      // Pour les tests : on autorise si pas d'avis existant
      // (peu importe la date du cours)
      return avisExistant.docs.isEmpty;
    } catch (e) {
      return false;
    }
  }

  // Récupérer l'avis de l'utilisateur pour un cours
  Future<Avis?> getMonAvis(String coursId) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final avisQuery = await _firestore
          .collection('cours')
          .doc(coursId)
          .collection('avis')
          .where('utilisateurId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (avisQuery.docs.isEmpty) return null;

      return Avis.fromMap(avisQuery.docs.first.id, avisQuery.docs.first.data());
    } catch (e) {
      return null;
    }
  }

  // ----- FONCTIONS ADMIN -----
  
  // Récupérer tous les avis
  Stream<List<Avis>> getAllAvis() {
    return _firestore
        .collectionGroup('avis')
        .snapshots()
        .map((snapshot) {
          final avis = snapshot.docs.map((doc) {
            return Avis.fromMap(doc.id, doc.data());
          }).toList();
          avis.sort((a, b) => b.date.compareTo(a.date));
          return avis;
        });
  }

  // Masquer un avis
  Future<void> masquerAvis(String coursId, String avisId) async {
    await _firestore
        .collection('cours')
        .doc(coursId)
        .collection('avis')
        .doc(avisId)
        .update({'visible': false});
    
    await _mettreAJourNoteMoyenne(coursId);
  }

  // Afficher un avis
  Future<void> afficherAvis(String coursId, String avisId) async {
    await _firestore
        .collection('cours')
        .doc(coursId)
        .collection('avis')
        .doc(avisId)
        .update({'visible': true});
    
    await _mettreAJourNoteMoyenne(coursId);
  }

  // Supprimer un avis
  Future<void> supprimerAvis(String coursId, String avisId) async {
    await _firestore
        .collection('cours')
        .doc(coursId)
        .collection('avis')
        .doc(avisId)
        .delete();
    
    await _mettreAJourNoteMoyenne(coursId);
  }
}
