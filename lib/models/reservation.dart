//lib/models/reservation.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Reservation {
  final String id;
  final String utilisateurId;
  final String coursId;
  final DateTime dateReservation;
  final bool estPaye;

  Reservation({
    required this.id,
    required this.utilisateurId,
    required this.coursId,
    required this.dateReservation,
    required this.estPaye,
  });

  factory Reservation.fromMap(Map<String, dynamic> map) {
    final dateField = map['dateReservation'];
    final dateReservation = dateField is Timestamp
        ? dateField.toDate()
        : dateField is String
            ? DateTime.parse(dateField)
            : DateTime.now();
    return Reservation(
      id: map['id'] ?? '',
      utilisateurId: map['utilisateurId'] ?? '',
      coursId: map['coursId'] ?? '',
      dateReservation: dateReservation,
      estPaye: map['estPaye'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'utilisateurId': utilisateurId,
      'coursId': coursId,
      'dateReservation': dateReservation.toIso8601String(),
      'estPaye': estPaye,
    };
  }
}
