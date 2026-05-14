// lib/services/profil_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/profil.dart';

class ProfilService {
  final CollectionReference _utilisateursCollection = 
      FirebaseFirestore.instance.collection('utilisateurs');

  // Récupérer le profil de l'utilisateur connecté
  Stream<Profil?> getProfil() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return Stream.value(null);

    return _utilisateursCollection.doc(userId).snapshots().map((doc) {
      if (doc.exists) {
        return Profil.fromMap(userId, doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  // Mettre à jour le profil (sans photo pour l'instant)
  Future<bool> updateProfil(Profil profil) async {
    try {
      await _utilisateursCollection.doc(profil.id).update(profil.toMap());
      return true;
    } catch (e) {
      debugPrint('❌ Erreur mise à jour profil: $e');
      return false;
    }
  }

  // Version simplifiée pour la photo (à implémenter plus tard)
  Future<String?> uploadPhotoProfil(String userId, XFile imageFile) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profils')
          .child('$userId.jpg');
      await storageRef.putData(await imageFile.readAsBytes());
      final downloadUrl = await storageRef.getDownloadURL();

      await _utilisateursCollection.doc(userId).update({
        'photoUrl': downloadUrl,
      });

      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Erreur upload photo: $e');
      return null;
    }
  }

  // Choisir une image
  Future<XFile?> choisirImage() async {
    final ImagePicker picker = ImagePicker();
    return await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 500,
      maxHeight: 500,
      imageQuality: 80,
    );
  }

  // Prendre une photo
  Future<XFile?> prendrePhoto() async {
    final ImagePicker picker = ImagePicker();
    return await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 500,
      maxHeight: 500,
      imageQuality: 80,
    );
  }

  // Calculer les statistiques
  Future<Map<String, dynamic>> calculerStatistiques(String userId) async {
    try {
      final now = DateTime.now();
      final reservations = await FirebaseFirestore.instance
          .collection('reservations')
          .where('utilisateurId', isEqualTo: userId)
          .get();

      int coursReserves = reservations.docs.length;
      int coursPasses = 0;
      int totalHeures = 0;

      for (var doc in reservations.docs) {
        final reservation = doc.data();
        final coursId = reservation['coursId'];
        
        final coursDoc = await FirebaseFirestore.instance
            .collection('cours')
            .doc(coursId)
            .get();

        if (coursDoc.exists) {
          final coursData = coursDoc.data() as Map<String, dynamic>;
          final dateField = coursData['date'];
          final dateCours = dateField is Timestamp
              ? dateField.toDate()
              : DateTime.parse(dateField as String);
          final duree = (coursData['duree'] as int?) ?? 0;

          if (dateCours.add(Duration(minutes: duree)).isBefore(now)) {
            coursPasses++;
            totalHeures += duree;
          }
        }
      }

      return {
        'coursReserves': coursReserves,
        'coursPasses': coursPasses,
        'totalHeures': totalHeures,
        'coursFuturs': coursReserves - coursPasses,
      };
    } catch (e) {
      debugPrint('❌ Erreur calcul statistiques: $e');
      return {
        'coursReserves': 0,
        'coursPasses': 0,
        'totalHeures': 0,
        'coursFuturs': 0,
      };
    }
  }
}