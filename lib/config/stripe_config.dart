//lib/config/stripe_config.dart
class StripeConfig {
  // Remplace par ta propre clé publiable (commence par pk_test_)
  static const String publishableKey = 'pk_test_51TC4ovGRKflsQnmL1dJILpuW1eusbVbzNISvLBeCHZWdt6UmdV6l9KSftf1qfOGoqGewBub4HCWwqLOAlx8lW2yE00DmMRhdOa';
  
  // ⚠️ Pour le développement uniquement - à déplacer sur un serveur en production
  static const String secretKey = 'sk_test_51TC4ovGRKflsQnmLFU3N1GobJM43wPiCjoMs1M7H0o0VhFAwauOQC5ufCmmdEcSpvOjKGYoiXUhgshDdTKm3cprE0040NEoIQP';
  
  // URL de ton backend (pour la production)
  static const String baseUrl = 'http://localhost:3000';

  // Prix des packs
  static const Map<String, double> prixPacks = {
    'pack5': 100.0,   // 5 séances : 100€
    'pack10': 180.0,  // 10 séances : 180€
    'pack20': 320.0,  // 20 séances : 320€
  };
    // Prix des abonnements
  static const Map<String, double> prixAbonnements = {
    'mensuel': 80.0,   // 80€/mois
    'trimestriel': 210.0, // 70€/mois
    'annuel': 720.0,   // 60€/mois
  };
}
