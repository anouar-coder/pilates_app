// lib/utils/donnees_test.dart
import '../models/cours.dart';

class DonneesTest {
  static List<Cours> coursDisponibles = [
    Cours(
      id: '1',
      titre: 'Pilates Débutant',
      date: DateTime.now().add(const Duration(days: 1)),
      duree: 60,
      placesMax: 10,
      placesRestantes: 5,
      niveau: 'Débutant',
      coach: 'Sophie Martin',
      description: 'Cours d\'initiation au Pilates. Idéal pour commencer.',
    ),
    Cours(
      id: '2',
      titre: 'Pilates Intermédiaire',
      date: DateTime.now().add(const Duration(days: 2)),
      duree: 75,
      placesMax: 8,
      placesRestantes: 2,
      niveau: 'Intermédiaire',
      coach: 'Thomas Dubois',
      description: 'Pour ceux qui maîtrisent les bases.',
    ),
    Cours(
      id: '3',
      titre: 'Pilates Avancé',
      date: DateTime.now().add(const Duration(days: 3)),
      duree: 90,
      placesMax: 6,
      placesRestantes: 3,
      niveau: 'Avancé',
      coach: 'Sophie Martin',
      description: 'Cours intensif pour pratiquants confirmés.',
    ),
    Cours(
      id: '4',
      titre: 'Pilates & Relaxation',
      date: DateTime.now().add(const Duration(days: 4)),
      duree: 60,
      placesMax: 12,
      placesRestantes: 8,
      niveau: 'Débutant',
      coach: 'Emma Petit',
      description: 'Focus sur la respiration et la relaxation.',
    ),
    Cours(
      id: '5',
      titre: 'Pilates Renforcement',
      date: DateTime.now().add(const Duration(days: 5)),
      duree: 60,
      placesMax: 10,
      placesRestantes: 0,
      niveau: 'Intermédiaire',
      coach: 'Thomas Dubois',
      description: 'Renforcement musculaire profond.',
    ),
  ];
}
