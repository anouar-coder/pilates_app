// lib/screens/reservations/mes_reservations_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firebase_service.dart';
import '../../services/avis_service.dart';
import '../../models/reservation.dart';
import '../../models/cours.dart';
import '../avis/ajouter_avis_screen.dart';

class MesReservationsScreen extends StatefulWidget {
  const MesReservationsScreen({super.key});

  @override
  State<MesReservationsScreen> createState() => _MesReservationsScreenState();
}

class _MesReservationsScreenState extends State<MesReservationsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final AvisService _avisService = AvisService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes réservations'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Reservation>>(
        stream: _firebaseService.getMesReservations(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Erreur: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final reservations = snapshot.data ?? [];

          if (reservations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('Aucune réservation',
                      style: TextStyle(fontSize: 20, color: Colors.grey[600])),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/accueil');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    child: const Text('Voir les cours'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reservations.length,
            itemBuilder: (context, index) {
              final reservation = reservations[index];
              return FutureBuilder<Cours?>(
                future: _firebaseService.getCoursById(reservation.coursId),
                builder: (context, coursSnapshot) {
                  if (!coursSnapshot.hasData) {
                    return const Card(
                      child: ListTile(
                        leading: CircularProgressIndicator(),
                        title: Text('Chargement...'),
                      ),
                    );
                  }

                  final cours = coursSnapshot.data!;
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                         // Dans la partie où tu as le bouton Noter, remplace par :

Row(
  mainAxisAlignment: MainAxisAlignment.end,
  children: [
    // Bouton Noter - TOUJOURS VISIBLE POUR TEST
    ElevatedButton(
      onPressed: () async {
        final avisExistant = await _avisService.getMonAvis(cours.id);
        if (avisExistant != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vous avez déjà donné votre avis'),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AjouterAvisScreen(cours: cours),
            ),
          );
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.amber,
        foregroundColor: Colors.white,
      ),
      child: const Text('Noter'),
    ),
    const SizedBox(width: 8),
    
    // Bouton Annuler
    OutlinedButton(
      onPressed: () {
        _showAnnulationDialog(context, reservation, cours);
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.red,
        side: const BorderSide(color: Colors.red),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: const Text('Annuler'),
    ),
  ],
),
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text('${cours.date.day}/${cours.date.month}/${cours.date.year}',
                                  style: TextStyle(color: Colors.grey[600])),
                              const SizedBox(width: 16),
                              Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text('${cours.duree} min',
                                  style: TextStyle(color: Colors.grey[600])),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Bouton Noter (pour les cours passés)
                              if (cours.date.isBefore(DateTime.now())) ...[
                                ElevatedButton(
                                  onPressed: () async {
                                    final peutAvis = await _avisService.peutLaisserAvis(cours.id);
                                    if (peutAvis) {
                                      final avisExistant = await _avisService.getMonAvis(cours.id);
                                      if (avisExistant != null) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Vous avez déjà donné votre avis'),
                                            backgroundColor: Colors.orange,
                                          ),
                                        );
                                      } else {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => AjouterAvisScreen(cours: cours),
                                          ),
                                        );
                                      }
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Vous ne pouvez pas encore donner votre avis'),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Noter'),
                                ),
                                const SizedBox(width: 8),
                              ],
                              OutlinedButton(
                                onPressed: () {
                                  _showAnnulationDialog(context, reservation, cours);
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('Annuler'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showAnnulationDialog(BuildContext context, Reservation reservation, Cours cours) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Annuler la réservation'),
        content: Text('Voulez-vous vraiment annuler votre réservation pour "${cours.titre}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Non'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              
              final success = await _firebaseService.annulerReservation(
                reservation.id,
                reservation.coursId,
              );

              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Réservation annulée avec succès'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Erreur lors de l\'annulation'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );
  }
}