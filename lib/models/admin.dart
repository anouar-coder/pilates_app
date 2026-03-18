//lib/models/admin.dart
class AdminStats {
  final int totalCours;
  final int totalReservations;
  final int totalUtilisateurs;
  final double tauxRemplissage;
  final Map<String, int> coursPopulaires;
  final double revenuTotal;

  AdminStats({
    required this.totalCours,
    required this.totalReservations,
    required this.totalUtilisateurs,
    required this.tauxRemplissage,
    required this.coursPopulaires,
    required this.revenuTotal,
  });

  // Constructeur pour créer un objet à partir d'une Map (utile pour Firestore)
  factory AdminStats.fromMap(Map<String, dynamic> map) {
    return AdminStats(
      totalCours: map['totalCours'] ?? 0,
      totalReservations: map['totalReservations'] ?? 0,
      totalUtilisateurs: map['totalUtilisateurs'] ?? 0,
      tauxRemplissage: (map['tauxRemplissage'] ?? 0.0).toDouble(),
      coursPopulaires: Map<String, int>.from(map['coursPopulaires'] ?? {}),
      revenuTotal: (map['revenuTotal'] ?? 0.0).toDouble(),
    );
  }

  // Convertir l'objet en Map (pour sauvegarder dans Firestore)
  Map<String, dynamic> toMap() {
    return {
      'totalCours': totalCours,
      'totalReservations': totalReservations,
      'totalUtilisateurs': totalUtilisateurs,
      'tauxRemplissage': tauxRemplissage,
      'coursPopulaires': coursPopulaires,
      'revenuTotal': revenuTotal,
    };
  }

  // Pour créer une copie avec des modifications
  AdminStats copyWith({
    int? totalCours,
    int? totalReservations,
    int? totalUtilisateurs,
    double? tauxRemplissage,
    Map<String, int>? coursPopulaires,
    double? revenuTotal,
  }) {
    return AdminStats(
      totalCours: totalCours ?? this.totalCours,
      totalReservations: totalReservations ?? this.totalReservations,
      totalUtilisateurs: totalUtilisateurs ?? this.totalUtilisateurs,
      tauxRemplissage: tauxRemplissage ?? this.tauxRemplissage,
      coursPopulaires: coursPopulaires ?? this.coursPopulaires,
      revenuTotal: revenuTotal ?? this.revenuTotal,
    );
  }

  // Pour un affichage facile dans les logs
  @override
  String toString() {
    return 'AdminStats(totalCours: $totalCours, totalReservations: $totalReservations, totalUtilisateurs: $totalUtilisateurs, tauxRemplissage: $tauxRemplissage, revenuTotal: $revenuTotal)';
  }
}