//lib/models/cours.dart
class Cours {
  final String id;
  final String titre;
  final DateTime date;
  final int duree;
  final int placesMax;
  final int placesRestantes;
  final String niveau;
  final String coach;
  final String description;
  final double? noteMoyenne;      // ← NOUVEAU
  final int? nombreAvis;           // ← NOUVEAU

  Cours({
    required this.id,
    required this.titre,
    required this.date,
    required this.duree,
    required this.placesMax,
    required this.placesRestantes,
    required this.niveau,
    required this.coach,
    required this.description,
    this.noteMoyenne,              // ← NOUVEAU
    this.nombreAvis,                // ← NOUVEAU
  });

  // Constructeur vide pour les cas par défaut
  Cours.empty()
      : id = '',
        titre = '',
        date = DateTime.now(),
        duree = 0,
        placesMax = 0,
        placesRestantes = 0,
        niveau = '',
        coach = '',
        description = '',
        noteMoyenne = 0,            // ← NOUVEAU
        nombreAvis = 0;              // ← NOUVEAU

  factory Cours.fromMap(Map<String, dynamic> map) {
    return Cours(
      id: map['id'] ?? '',
      titre: map['titre'] ?? '',
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      duree: map['duree'] ?? 0,
      placesMax: map['placesMax'] ?? 0,
      placesRestantes: map['placesRestantes'] ?? 0,
      niveau: map['niveau'] ?? '',
      coach: map['coach'] ?? '',
      description: map['description'] ?? '',
      noteMoyenne: (map['noteMoyenne'] ?? 0).toDouble(),      // ← NOUVEAU
      nombreAvis: map['nombreAvis'] ?? 0,                      // ← NOUVEAU
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titre': titre,
      'date': date.toIso8601String(),
      'duree': duree,
      'placesMax': placesMax,
      'placesRestantes': placesRestantes,
      'niveau': niveau,
      'coach': coach,
      'description': description,
      'noteMoyenne': noteMoyenne ?? 0,                          // ← NOUVEAU
      'nombreAvis': nombreAvis ?? 0,                            // ← NOUVEAU
    };
  }
}