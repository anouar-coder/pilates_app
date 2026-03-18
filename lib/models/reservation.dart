//lib/models/reservation.dart
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
    return Reservation(
      id: map['id'],
      utilisateurId: map['utilisateurId'],
      coursId: map['coursId'],
      dateReservation: DateTime.parse(map['dateReservation']),
      estPaye: map['estPaye'],
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
