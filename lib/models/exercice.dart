//lib/models/exercice.dart
class Exercice {
  final String id;
  final String titre;
  final String description;
  final int dureeSecondes; // Durée de l'exercice
  final int repetitions; // Nombre de répétitions
  final String? videoUrl; // Lien YouTube
  final String? imageUrl;
  final List<String> materiel; // Matériel nécessaire

  Exercice({
    required this.id,
    required this.titre,
    required this.description,
    required this.dureeSecondes,
    required this.repetitions,
    this.videoUrl,
    this.imageUrl,
    required this.materiel,
  });

  factory Exercice.fromMap(String id, Map<String, dynamic> map) {
    return Exercice(
      id: id,
      titre: map['titre'] ?? '',
      description: map['description'] ?? '',
      dureeSecondes: map['dureeSecondes'] ?? 60,
      repetitions: map['repetitions'] ?? 10,
      videoUrl: map['videoUrl'],
      imageUrl: map['imageUrl'],
      materiel: List<String>.from(map['materiel'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'titre': titre,
      'description': description,
      'dureeSecondes': dureeSecondes,
      'repetitions': repetitions,
      'videoUrl': videoUrl,
      'imageUrl': imageUrl,
      'materiel': materiel,
    };
  }
}
