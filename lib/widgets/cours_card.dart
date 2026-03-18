// lib/widgets/cours_card.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/cours.dart';
import '../screens/cours/detail_cours_screen.dart';
import '../services/firebase_service.dart';
import '../services/attente_service.dart';
import '../models/attente.dart';

class CoursCard extends StatelessWidget {
  final Cours cours;

  const CoursCard({super.key, required this.cours});

  Color _getCouleurNiveau() {
    switch (cours.niveau) {
      case 'Débutant':
        return Colors.green;
      case 'Intermédiaire':
        return Colors.orange;
      case 'Avancé':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🔍 Cours ${cours.titre} - placesRestantes: ${cours.placesRestantes}, placesMax: ${cours.placesMax}');
    print('🔍 Est complet: ${cours.placesRestantes <= 0}');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailCoursScreen(cours: cours),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      cours.titre,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getCouleurNiveau().withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      cours.niveau,
                      style: TextStyle(
                        color: _getCouleurNiveau(),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(cours.coach, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(width: 16),
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('${cours.duree} min',
                      style: const TextStyle(color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('${cours.date.day}/${cours.date.month}/${cours.date.year}',
                      style: const TextStyle(color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: cours.placesRestantes > 0
                          ? Colors.blue.withValues(alpha: 0.2)
                          : Colors.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      cours.placesRestantes > 0
                          ? '${cours.placesRestantes}/${cours.placesMax} places'
                          : 'Complet',
                      style: TextStyle(
                        color: cours.placesRestantes > 0 ? Colors.blue : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (cours.placesRestantes > 0)
                    ElevatedButton(
                      onPressed: () async {
                        final firebaseService = FirebaseService();
                        
                        // Vérification si l'utilisateur est admin
                        final userId = FirebaseAuth.instance.currentUser?.uid;
                        if (userId != null) {
                          final userDoc = await FirebaseFirestore.instance
                              .collection('utilisateurs')
                              .doc(userId)
                              .get();
                          
                          if (userDoc.exists) {
                            final role = userDoc.data()?['role'] ?? 'client';
                            if (role == 'admin') {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('❌ Les administrateurs ne peuvent pas réserver de cours'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              return;
                            }
                          }
                        }

                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (BuildContext dialogContext) => AlertDialog(
                            title: const Text('Confirmer la réservation'),
                            content: Text('Voulez-vous réserver "${cours.titre}" ?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dialogContext, false),
                                child: const Text('Annuler'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(dialogContext, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Confirmer'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Réservation en cours...'),
                              duration: Duration(seconds: 1),
                            ),
                          );

                          final success = await firebaseService.reserverCours(cours.id);

                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ Cours réservé avec succès!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } else if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  cours.placesRestantes <= 0
                                      ? '❌ Plus de places disponibles'
                                      : '❌ Vous avez déjà réservé ce cours',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Réserver'),
                    )
                  else
                    FutureBuilder<Attente?>(
                      future: AttenteService().estDansListeAttente(cours.id),
                      builder: (context, snapshot) {
                        final estEnAttente = snapshot.data != null;
                        
                        return ElevatedButton(
                          onPressed: () async {
                            final attenteService = AttenteService();
                            
                            if (estEnAttente) {
                              // Quitter la liste d'attente
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Quitter la liste d\'attente'),
                                  content: Text('Voulez-vous quitter la liste d\'attente pour "${cours.titre}" ?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('Annuler'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Quitter'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                final success = await attenteService.quitterListeAttente(cours.id);
                                if (success && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('❌ Vous avez quitté la liste d\'attente'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                }
                              }
                            } else {
                              // Rejoindre la liste d'attente
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Rejoindre la liste d\'attente'),
                                  content: Text('Le cours est complet. Voulez-vous être notifié quand une place se libère ?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('Annuler'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('M\'inscrire'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                final success = await attenteService.rejoindreListeAttente(cours.id);
                                if (success && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('✅ Inscrit à la liste d\'attente'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: estEnAttente ? Colors.orange : Colors.grey,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(estEnAttente ? '✓ Inscrit' : 'Liste d\'attente'),
                        );
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}