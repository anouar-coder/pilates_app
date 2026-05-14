// lib/services/calendar_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/cours.dart';
import '../models/calendar_event.dart';

class CalendarService {
  final CollectionReference _coursCollection = 
      FirebaseFirestore.instance.collection('cours');

  Stream<List<CalendarEvent>> getCalendarEvents() {
    return _coursCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final cours = Cours.fromMap(doc.data() as Map<String, dynamic>);
        return CalendarEvent.fromCours(cours);
      }).toList();
    });
  }

  Future<List<CalendarEvent>> getEventsForDay(DateTime day) async {
    try {
      final startOfDay = DateTime(day.year, day.month, day.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _coursCollection
          .where('date', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .where('date', isLessThan: endOfDay.toIso8601String())
          .get();

      return snapshot.docs.map((doc) {
        final cours = Cours.fromMap(doc.data() as Map<String, dynamic>);
        return CalendarEvent.fromCours(cours);
      }).toList();
    } catch (e) {
      debugPrint('❌ Erreur récupération événements: $e');
      return [];
    }
  }

  Future<Map<DateTime, List<CalendarEvent>>> getEventsForMonth(DateTime month) async {
    try {
      final startOfMonth = DateTime(month.year, month.month, 1);
      final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

      final snapshot = await _coursCollection
          .where('date', isGreaterThanOrEqualTo: startOfMonth.toIso8601String())
          .where('date', isLessThanOrEqualTo: endOfMonth.toIso8601String())
          .get();

      final Map<DateTime, List<CalendarEvent>> events = {};

      for (var doc in snapshot.docs) {
        final cours = Cours.fromMap(doc.data() as Map<String, dynamic>);
        final event = CalendarEvent.fromCours(cours);
        final date = DateTime(cours.date.year, cours.date.month, cours.date.day);
        
        if (events[date] == null) {
          events[date] = [];
        }
        events[date]!.add(event);
      }

      return events;
    } catch (e) {
      debugPrint('❌ Erreur récupération événements mois: $e');
      return {};
    }
  }
}
