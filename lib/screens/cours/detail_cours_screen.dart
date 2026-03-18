// lib/screens/cours/detail_cours_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/cours.dart';
import '../../services/avis_service.dart';
import '../../models/avis.dart';

class DetailCoursScreen extends StatelessWidget {
  final Cours cours;

  const DetailCoursScreen({super.key, required this.cours});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(cours.titre),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(
                  Icons.fitness_center,
                  size: 80,
                  color: Colors.blue,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Titre et niveau
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    cours.titre,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    cours.niveau,
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Coach
            _buildInfoRow(
              icon: Icons.person,
              label: 'Coach',
              valeur: cours.coach,
            ),
            const SizedBox(height: 8),

            // Durée
            _buildInfoRow(
              icon: Icons.access_time,
              label: 'Durée',
              valeur: '${cours.duree} minutes',
            ),
            const SizedBox(height: 8),

            // Date
            _buildInfoRow(
              icon: Icons.calendar_today,
              label: 'Date',
              valeur: '${cours.date.day}/${cours.date.month}/${cours.date.year}',
            ),
            const SizedBox(height: 8),

            // Places
            _buildInfoRow(
              icon: Icons.group,
              label: 'Places',
              valeur: '${cours.placesRestantes}/${cours.placesMax} disponibles',
            ),
            const SizedBox(height: 16),

            // ===== SECTION AVIS =====
            const Text(
              'Avis',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Note moyenne
            Row(
              children: [
                ...List.generate(5, (index) {
                  return Icon(
                    index < (cours.noteMoyenne ?? 0).round()
                        ? Icons.star
                        : Icons.star_border,
                    color: Colors.amber,
                    size: 20,
                  );
                }),
                const SizedBox(width: 8),
                Text(
                  '${(cours.noteMoyenne ?? 0).toStringAsFixed(1)}/5',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${cours.nombreAvis ?? 0} avis)',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Liste des avis
            StreamBuilder<List<Avis>>(
              stream: AvisService().getAvisPourCours(cours.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Text('Erreur: ${snapshot.error}');
                }

                final avis = snapshot.data ?? [];

                if (avis.isEmpty) {
                  return Center(
                    child: Column(
                      children: [
                        const Icon(Icons.rate_review, size: 40, color: Colors.grey),
                        const SizedBox(height: 8),
                        Text(
                          'Aucun avis pour le moment',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: avis.length,
                  itemBuilder: (context, index) {
                    final avisItem = avis[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundImage: avisItem.utilisateurPhoto != null
                                      ? NetworkImage(avisItem.utilisateurPhoto!)
                                      : null,
                                  child: avisItem.utilisateurPhoto == null
                                      ? Text(avisItem.utilisateurNom[0].toUpperCase())
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        avisItem.utilisateurNom,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Row(
                                        children: List.generate(5, (i) {
                                          return Icon(
                                            i < avisItem.note ? Icons.star : Icons.star_border,
                                            color: Colors.amber,
                                            size: 14,
                                          );
                                        }),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${avisItem.date.day}/${avisItem.date.month}/${avisItem.date.year}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                            if (avisItem.commentaire != null) ...[
                              const SizedBox(height: 8),
                              Text(avisItem.commentaire!),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 20),

            // Description
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              cours.description,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 30),

            // Bouton réserver
            if (cours.placesRestantes > 0)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Confirmation'),
                        content: Text(
                          'Voulez-vous réserver ${cours.titre} ?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Annuler'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Cours réservé avec succès!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                            child: const Text('Confirmer'),
                          ),
                        ],
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Réserver ce cours',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.info, color: Colors.red, size: 40),
                    SizedBox(height: 8),
                    Text(
                      'Ce cours est complet',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Vous pouvez rejoindre la liste d\'attente',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String valeur,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            valeur,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}