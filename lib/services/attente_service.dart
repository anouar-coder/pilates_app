// lib/services/attente_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/attente.dart';
import '../models/cours.dart';

class AttenteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Rejoindre la liste d'attente d'un cours
  Future<bool> rejoindreListeAttente(String coursId) async {
    final user = _auth.currentUser;
    if (user == null) {
      print('❌ Utilisateur non connecté');
      return false;
    }

    try {
      // Récupérer les infos du cours
      final coursDoc = await _firestore.collection('cours').doc(coursId).get();
      if (!coursDoc.exists) {
        print('❌ Cours non trouvé');
        return false;
      }

      final cours = Cours.fromMap(coursDoc.data() as Map<String, dynamic>);
      
      // Vérifier si l'utilisateur est déjà dans la liste d'attente
      final existingAttente = await _firestore
          .collection('cours')
          .doc(coursId)
          .collection('attente')
          .where('utilisateurId', isEqualTo: user.uid)
          .where('statut', whereIn: ['enAttente', 'notifie'])
          .limit(1)
          .get();

      if (existingAttente.docs.isNotEmpty) {
        print('❌ Déjà dans la liste d\'attente');
        return false;
      }

      // Compter le nombre de personnes déjà en attente
      final attenteQuery = await _firestore
          .collection('cours')
          .doc(coursId)
          .collection('attente')
          .where('statut', isEqualTo: 'enAttente')
          .get();

      final position = attenteQuery.docs.length + 1;

      // Récupérer les infos de l'utilisateur
      final userDoc = await _firestore
          .collection('utilisateurs')
          .doc(user.uid)
          .get();
      
      final userData = userDoc.data() as Map<String, dynamic>;
      final userNom = userData['nom'] ?? 'Utilisateur';

      // Créer l'entrée dans la liste d'attente
      final attente = Attente(
        id: '',
        coursId: coursId,
        coursTitre: cours.titre,
        utilisateurId: user.uid,
        utilisateurNom: userNom,
        dateInscription: DateTime.now(),
        position: position,
        statut: StatutAttente.enAttente,
      );

      await _firestore
          .collection('cours')
          .doc(coursId)
          .collection('attente')
          .add(attente.toMap());

      print('✅ Inscrit à la liste d\'attente en position $position');
      return true;

    } catch (e) {
      print('❌ Erreur inscription liste attente: $e');
      return false;
    }
  }

  // Quitter la liste d'attente
  Future<bool> quitterListeAttente(String coursId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final attenteQuery = await _firestore
          .collection('cours')
          .doc(coursId)
          .collection('attente')
          .where('utilisateurId', isEqualTo: user.uid)
          .where('statut', isEqualTo: 'enAttente')
          .limit(1)
          .get();

      if (attenteQuery.docs.isEmpty) {
        return false;
      }

      final attenteDoc = attenteQuery.docs.first;
      await attenteDoc.reference.update({'statut': 'annule'});

      // Recalculer les positions
      await _recalculerPositions(coursId);

      return true;
    } catch (e) {
      print('❌ Erreur sortie liste attente: $e');
      return false;
    }
  }

  // Vérifier les places disponibles et notifier les personnes en attente
  Future<void> verifierPlacesDisponibles(String coursId) async {
    try {
      // Récupérer le cours
      final coursDoc = await _firestore.collection('cours').doc(coursId).get();
      if (!coursDoc.exists) return;

      final cours = Cours.fromMap(coursDoc.data() as Map<String, dynamic>);
      
      // Si des places se sont libérées
      if (cours.placesRestantes > 0) {
        // Récupérer les personnes en attente (par ordre de position)
        final attenteQuery = await _firestore
            .collection('cours')
            .doc(coursId)
            .collection('attente')
            .where('statut', isEqualTo: 'enAttente')
            .orderBy('position')
            .limit(cours.placesRestantes)
            .get();

        for (var doc in attenteQuery.docs) {
          final attente = Attente.fromMap(doc.id, doc.data());
          
          // Marquer comme notifié
          await doc.reference.update({
            'statut': 'notifie',
            'dateNotification': Timestamp.now(),
            'dateExpiration': Timestamp.fromDate(
              DateTime.now().add(const Duration(hours: 24)),
            ),
          });

          // Envoyer une notification à l'utilisateur
          await _firestore
              .collection('utilisateurs')
              .doc(attente.utilisateurId)
              .collection('notifications')
              .add({
            'titre': '🎉 Place disponible !',
            'message': 'Une place s\'est libérée pour "${cours.titre}". Vous avez 24h pour réserver.',
            'lu': false,
            'date': FieldValue.serverTimestamp(),
            'type': 'place_disponible',
            'coursId': coursId,
          });
        }

        // Mettre à jour le compteur de places
        await _firestore.collection('cours').doc(coursId).update({
          'placesRestantes': cours.placesRestantes - attenteQuery.docs.length,
        });
      }
    } catch (e) {
      print('❌ Erreur vérification places: $e');
    }
  }

  // Recalculer les positions après un départ
  Future<void> _recalculerPositions(String coursId) async {
    try {
      final attenteQuery = await _firestore
          .collection('cours')
          .doc(coursId)
          .collection('attente')
          .where('statut', isEqualTo: 'enAttente')
          .orderBy('position')
          .get();

      int nouvellePosition = 1;
      for (var doc in attenteQuery.docs) {
        await doc.reference.update({'position': nouvellePosition});
        nouvellePosition++;
      }
    } catch (e) {
      print('❌ Erreur recalcul positions: $e');
    }
  }

  // Récupérer la liste d'attente d'un cours (pour admin)
  Stream<List<Attente>> getListeAttente(String coursId) {
    return _firestore
        .collection('cours')
        .doc(coursId)
        .collection('attente')
        .where('statut', whereIn: ['enAttente', 'notifie'])
        .orderBy('position')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Attente.fromMap(doc.id, doc.data());
          }).toList();
        });
  }

  // Vérifier si l'utilisateur est dans la liste d'attente
  Future<Attente?> estDansListeAttente(String coursId) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final attenteQuery = await _firestore
          .collection('cours')
          .doc(coursId)
          .collection('attente')
          .where('utilisateurId', isEqualTo: user.uid)
          .where('statut', whereIn: ['enAttente', 'notifie'])
          .limit(1)
          .get();

      if (attenteQuery.docs.isEmpty) return null;
      
      return Attente.fromMap(attenteQuery.docs.first.id, attenteQuery.docs.first.data());
    } catch (e) {
      return null;
    }
  }

  // Traiter une notification de place disponible (quand l'utilisateur réserve)
  Future<bool> traiterReservationDepuisAttente(String coursId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final attenteQuery = await _firestore
          .collection('cours')
          .doc(coursId)
          .collection('attente')
          .where('utilisateurId', isEqualTo: user.uid)
          .where('statut', isEqualTo: 'notifie')
          .limit(1)
          .get();

      if (attenteQuery.docs.isEmpty) return false;

      await attenteQuery.docs.first.reference.update({
        'statut': 'reserve',
      });

      return true;
    } catch (e) {
      print('❌ Erreur traitement réservation: $e');
      return false;
    }
  }

  // Nettoyer les notifications expirées (à appeler périodiquement)
  Future<void> nettoyerNotificationsExpirees() async {
    try {
      final dateLimite = DateTime.now().subtract(const Duration(hours: 24));
      
      final query = await _firestore
          .collectionGroup('attente')
          .where('statut', isEqualTo: 'notifie')
          .where('dateNotification', isLessThan: Timestamp.fromDate(dateLimite))
          .get();

      for (var doc in query.docs) {
        await doc.reference.update({'statut': 'expire'});
        
        // Notifier l'utilisateur que son délai a expiré
        final data = doc.data();
        final userId = data['utilisateurId'];
        
        await _firestore
            .collection('utilisateurs')
            .doc(userId)
            .collection('notifications')
            .add({
          'titre': '⏰ Délai expiré',
          'message': 'Votre délai de réservation a expiré. La place a été proposée au suivant.',
          'lu': false,
          'date': FieldValue.serverTimestamp(),
        });
      }

      // Après expiration, recalculer les positions
      for (var doc in query.docs) {
        final coursId = doc.reference.parent.parent!.id;
        await _recalculerPositions(coursId);
        await verifierPlacesDisponibles(coursId);
      }
    } catch (e) {
      print('❌ Erreur nettoyage notifications: $e');
    }
  }
}