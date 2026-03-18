// lib/screens/paiement/historique_paiements_screen.dart
import 'package:flutter/material.dart';
import '../../services/paiement_service.dart';
import '../../models/paiement.dart';

class HistoriquePaiementsScreen extends StatefulWidget {
  const HistoriquePaiementsScreen({super.key});

  @override
  State<HistoriquePaiementsScreen> createState() => _HistoriquePaiementsScreenState();
}

class _HistoriquePaiementsScreenState extends State<HistoriquePaiementsScreen> {
  final PaiementService _paiementService = PaiementService();

  String _getTypeTexte(TypePaiement type) {
    switch (type) {
      case TypePaiement.seance:
        return 'Séance';
      case TypePaiement.pack:
        return 'Pack';
      case TypePaiement.abonnement:
        return 'Abonnement';
    }
  }

  Color _getStatutCouleur(StatutPaiement statut) {
    switch (statut) {
      case StatutPaiement.reussi:
        return Colors.green;
      case StatutPaiement.enAttente:
        return Colors.orange;
      case StatutPaiement.echec:
        return Colors.red;
      case StatutPaiement.rembourse:
        return Colors.grey;
    }
  }

  String _getStatutTexte(StatutPaiement statut) {
    switch (statut) {
      case StatutPaiement.reussi:
        return 'Réussi';
      case StatutPaiement.enAttente:
        return 'En attente';
      case StatutPaiement.echec:
        return 'Échec';
      case StatutPaiement.rembourse:
        return 'Remboursé';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des paiements'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Paiement>>(
        stream: _paiementService.getHistoriquePaiements(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text('Erreur: ${snapshot.error}'),
                ],
              ),
            );
          }

          final paiements = snapshot.data ?? [];

          if (paiements.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun paiement',
                    style: TextStyle(fontSize: 20, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Vos paiements apparaîtront ici',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: paiements.length,
            itemBuilder: (context, index) {
              final paiement = paiements[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              paiement.type == TypePaiement.seance
                                  ? Icons.fitness_center
                                  : paiement.type == TypePaiement.pack
                                      ? Icons.inventory
                                      : Icons.calendar_month,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_getTypeTexte(paiement.type)} - ${paiement.montant}€',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${paiement.date.day}/${paiement.date.month}/${paiement.date.year} ${paiement.date.hour}:${paiement.date.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatutCouleur(paiement.statut).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getStatutTexte(paiement.statut),
                              style: TextStyle(
                                color: _getStatutCouleur(paiement.statut),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (paiement.metadata != null) ...[
                        const SizedBox(height: 8),
                        const Divider(),
                        const SizedBox(height: 8),
                        if (paiement.type == TypePaiement.seance)
                          Text(
                            'Cours: ${paiement.metadata!['titreCours'] ?? 'Inconnu'}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        if (paiement.type == TypePaiement.pack) ...[
                          Text(
                            'Pack: ${paiement.metadata!['packNom'] ?? 'Inconnu'}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          Text(
                            '${paiement.metadata!['nombreSeances'] ?? 0} séances ajoutées',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                        if (paiement.type == TypePaiement.abonnement) ...[
                          Text(
                            'Abonnement: ${paiement.metadata!['abonnementNom'] ?? 'Inconnu'}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          if (paiement.metadata!.containsKey('dateFin'))
                            Text(
                              'Valable jusqu\'au ${paiement.metadata!['dateFin'].split('T')[0].replaceAll('-', '/')}',
                              style: const TextStyle(fontSize: 14),
                            ),
                        ],
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}