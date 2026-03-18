// lib/screens/admin/gestion_avis_screen.dart
import 'package:flutter/material.dart';
import '../../services/avis_service.dart';
import '../../models/avis.dart';

class GestionAvisScreen extends StatefulWidget {
  const GestionAvisScreen({super.key});

  @override
  State<GestionAvisScreen> createState() => _GestionAvisScreenState();
}

class _GestionAvisScreenState extends State<GestionAvisScreen> {
  final AvisService _avisService = AvisService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des avis'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Avis>>(
        stream: _avisService.getAllAvis(),
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

          final avis = snapshot.data ?? [];

          if (avis.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.rate_review, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun avis',
                    style: TextStyle(fontSize: 20, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: avis.length,
            itemBuilder: (context, index) {
              final avisItem = avis[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: avisItem.utilisateurPhoto != null
                                ? NetworkImage(avisItem.utilisateurPhoto!)
                                : null,
                            child: avisItem.utilisateurPhoto == null
                                ? Text(avisItem.utilisateurNom[0].toUpperCase())
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  avisItem.utilisateurNom,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  avisItem.coursTitre,
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
                              color: avisItem.visible
                                  ? Colors.green.withValues(alpha: 0.2)
                                  : Colors.red.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              avisItem.visible ? 'Visible' : 'Masqué',
                              style: TextStyle(
                                color: avisItem.visible ? Colors.green : Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: List.generate(5, (i) {
                          return Icon(
                            i < avisItem.note ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 16,
                          );
                        }),
                      ),
                      if (avisItem.commentaire != null) ...[
                        const SizedBox(height: 8),
                        Text(avisItem.commentaire!),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        '${avisItem.date.day}/${avisItem.date.month}/${avisItem.date.year}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (avisItem.visible)
                            ElevatedButton.icon(
                              onPressed: () async {
                                await _avisService.masquerAvis(
                                  avisItem.coursId,
                                  avisItem.id,
                                );
                              },
                              icon: const Icon(Icons.visibility_off),
                              label: const Text('Masquer'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                            )
                          else
                            ElevatedButton.icon(
                              onPressed: () async {
                                await _avisService.afficherAvis(
                                  avisItem.coursId,
                                  avisItem.id,
                                );
                              },
                              icon: const Icon(Icons.visibility),
                              label: const Text('Afficher'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Confirmer'),
                                  content: const Text('Supprimer cet avis ?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('Annuler'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                      ),
                                      child: const Text('Supprimer'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                await _avisService.supprimerAvis(
                                  avisItem.coursId,
                                  avisItem.id,
                                );
                              }
                            },
                            icon: const Icon(Icons.delete),
                            label: const Text('Supprimer'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
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
      ),
    );
  }
}
