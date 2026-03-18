//lib/models/calendar_event.dart
import '../models/cours.dart';

class CalendarEvent {
  final String id;
  final String title;
  final DateTime date;
  final String niveau;
  final String coach;
  final int duree;
  final int placesRestantes;
  final int placesMax;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.date,
    required this.niveau,
    required this.coach,
    required this.duree,
    required this.placesRestantes,
    required this.placesMax,
  });

  factory CalendarEvent.fromCours(Cours cours) {
    return CalendarEvent(
      id: cours.id,
      title: cours.titre,
      date: cours.date,
      niveau: cours.niveau,
      coach: cours.coach,
      duree: cours.duree,
      placesRestantes: cours.placesRestantes,
      placesMax: cours.placesMax,
    );
  }

  factory CalendarEvent.fromMap(Map<String, dynamic> map) {
    return CalendarEvent(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      date: DateTime.parse(map['date']),
      niveau: map['niveau'] ?? '',
      coach: map['coach'] ?? '',
      duree: map['duree'] ?? 0,
      placesRestantes: map['placesRestantes'] ?? 0,
      placesMax: map['placesMax'] ?? 0,
    );
  }
}