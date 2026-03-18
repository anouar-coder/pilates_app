// lib/screens/admin/gestion_cours_screen.dart
import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../models/cours.dart';
import 'ajouter_cours_screen.dart';
import 'gestion_attente_screen.dart'; // ← NOUVEL IMPORT

class GestionCoursScreen extends StatefulWidget {
  const GestionCoursScreen({super.key});

  @override
  State<GestionCoursScreen> createState() => _GestionCoursScreenState();
}

class _GestionCoursScreenState extends State<GestionCoursScreen> {
  final AdminService _adminService = AdminService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AjouterCoursScreen(),
            ),
          ).then((_) => setState(() {}));
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<List<Cours>>(
        stream: _adminService.getAllCours(),
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

          final coursListe = snapshot.data ?? [];

          if (coursListe.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.fitness_center, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun cours',
                    style: TextStyle(fontSize: 20, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cliquez sur + pour ajouter un cours',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: coursListe.length,
            itemBuilder: (context, index) {
              final cours = coursListe[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getCouleurNiveau(cours.niveau).withValues(alpha: 0.2),
                    child: Icon(
                      Icons.fitness_center,
                      color: _getCouleurNiveau(cours.niveau),
                    ),
                  ),
                  title: Text(cours.titre),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${cours.coach} • ${cours.niveau}'),
                      Text('${cours.date.day}/${cours.date.month} • ${cours.duree}min • ${cours.placesRestantes}/${cours.placesMax} places'),
                    ],
                  ),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Modifier'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Supprimer'),
                          ],
                        ),
                      ),
                      // ★★★ NOUVELLE OPTION ★★★
                      const PopupMenuItem(
                        value: 'attente',
                        child: Row(
                          children: [
                            Icon(Icons.queue, color: Colors.orange),
                            SizedBox(width: 8),
                            Text('Liste d\'attente'),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) async {
                      if (value == 'delete') {
                        _showDeleteDialog(context, cours);
                      } else if (value == 'edit') {
                        // À implémenter: page d'édition
                      } else if (value == 'attente') {
                        // ★★★ NOUVELLE NAVIGATION ★★★
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GestionAttenteScreen(cours: cours),
                          ),
                        );
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Cours cours) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer le cours "${cours.titre}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _adminService.supprimerCours(cours.id);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cours supprimé'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Color _getCouleurNiveau(String niveau) {
    switch (niveau) {
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
}