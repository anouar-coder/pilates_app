// lib/screens/admin/gestion_attente_screen.dart
import 'package:flutter/material.dart';
import '../../services/attente_service.dart';
import '../../models/attente.dart';
import '../../models/cours.dart';

class GestionAttenteScreen extends StatefulWidget {
  final Cours cours;

  const GestionAttenteScreen({super.key, required this.cours});

  @override
  State<GestionAttenteScreen> createState() => _GestionAttenteScreenState();
}

class _GestionAttenteScreenState extends State<GestionAttenteScreen> {
  final AttenteService _attenteService = AttenteService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Liste d\'attente - ${widget.cours.titre}'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Attente>>(
        stream: _attenteService.getListeAttente(widget.cours.id),
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

          final attente = snapshot.data ?? [];

          if (attente.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.queue_play_next, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune personne en attente',
                    style: TextStyle(fontSize: 20, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'La liste d\'attente est vide',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Résumé
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      'En attente',
                      attente.where((a) => a.statut == StatutAttente.enAttente).length.toString(),
                      Icons.hourglass_empty,
                      Colors.orange,
                    ),
                    _buildStatItem(
                      'Notifiés',
                      attente.where((a) => a.statut == StatutAttente.notifie).length.toString(),
                      Icons.notifications_active,
                      Colors.green,
                    ),
                  ],
                ),
              ),
              
              // Liste
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: attente.length,
                  itemBuilder: (context, index) {
                    final item = attente[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getStatutCouleur(item.statut).withValues(alpha: 0.2),
                          child: Text(
                            '${item.position}',
                            style: TextStyle(
                              color: _getStatutCouleur(item.statut),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(item.utilisateurNom),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Inscrit le ${item.dateInscription.day}/${item.dateInscription.month}'),
                            if (item.dateNotification != null)
                              Text('Notifié le ${item.dateNotification!.day}/${item.dateNotification!.month}'),
                            if (item.dateExpiration != null)
                              Text('Expire le ${item.dateExpiration!.day}/${item.dateExpiration!.month}'),
                          ],
                        ),
                        trailing: Chip(
                          label: Text(
                            _getStatutTexte(item.statut),
                            style: TextStyle(
                              fontSize: 12,
                              color: _getStatutCouleur(item.statut),
                            ),
                          ),
                          backgroundColor: _getStatutCouleur(item.statut).withValues(alpha: 0.1),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Color _getStatutCouleur(StatutAttente statut) {
    switch (statut) {
      case StatutAttente.enAttente:
        return Colors.orange;
      case StatutAttente.notifie:
        return Colors.green;
      case StatutAttente.expire:
        return Colors.red;
      case StatutAttente.reserve:
        return Colors.blue;
      case StatutAttente.annule:
        return Colors.grey;
    }
  }

  String _getStatutTexte(StatutAttente statut) {
    switch (statut) {
      case StatutAttente.enAttente:
        return 'En attente';
      case StatutAttente.notifie:
        return 'Notifié';
      case StatutAttente.expire:
        return 'Expiré';
      case StatutAttente.reserve:
        return 'Réservé';
      case StatutAttente.annule:
        return 'Annulé';
    }
  }
}