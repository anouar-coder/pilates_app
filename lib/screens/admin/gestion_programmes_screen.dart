// lib/screens/admin/gestion_programmes_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/programme_service.dart';
import '../../models/programme.dart';
import 'gestion_seances_screen.dart'; // ← IMPORT POUR LA GESTION DES SÉANCES

class GestionProgrammesScreen extends StatefulWidget {
  const GestionProgrammesScreen({super.key});

  @override
  State<GestionProgrammesScreen> createState() => _GestionProgrammesScreenState();
}

class _GestionProgrammesScreenState extends State<GestionProgrammesScreen> {
  final ProgrammeService _programmeService = ProgrammeService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _titreController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _niveauController = TextEditingController();
  final _dureeController = TextEditingController();
  final _tagsController = TextEditingController();
  
  bool _isLoading = false;

  Future<void> _creerProgramme() async {
    if (_titreController.text.isEmpty || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir les champs obligatoires')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final user = _auth.currentUser;
    final userDoc = await FirebaseFirestore.instance
        .collection('utilisateurs')
        .doc(user!.uid)
        .get();
    final userNom = userDoc.data()?['nom'] ?? 'Coach';

    final programme = Programme(
      id: '',
      coachId: user.uid,
      coachNom: userNom,
      titre: _titreController.text,
      description: _descriptionController.text,
      niveau: _niveauController.text.isEmpty ? 'Débutant' : _niveauController.text,
      dureeJours: int.tryParse(_dureeController.text) ?? 7,
      tags: _tagsController.text.split(',').map((e) => e.trim()).toList(),
      dateCreation: DateTime.now(),
      publie: true,
    );

    final id = await _programmeService.creerProgramme(programme);
    
    setState(() => _isLoading = false);

    if (id != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Programme créé'), backgroundColor: Colors.green),
      );
      _titreController.clear();
      _descriptionController.clear();
      _niveauController.clear();
      _dureeController.clear();
      _tagsController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des programmes'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Formulaire de création
                  const Text(
                    'Créer un nouveau programme',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: _titreController,
                    decoration: InputDecoration(
                      labelText: 'Titre du programme',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  TextField(
                    controller: _niveauController,
                    decoration: InputDecoration(
                      labelText: 'Niveau (Débutant/Intermédiaire/Avancé)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  TextField(
                    controller: _dureeController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Durée (en jours)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  TextField(
                    controller: _tagsController,
                    decoration: InputDecoration(
                      labelText: 'Tags (séparés par des virgules)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  ElevatedButton(
                    onPressed: _creerProgramme,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('Créer le programme'),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Liste des programmes existants
                  const Text(
                    'Programmes existants',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // StreamBuilder pour afficher les programmes
                  StreamBuilder<List<Programme>>(
                    stream: _programmeService.getAllProgrammes(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            children: [
                              Icon(Icons.error, color: Colors.red),
                              const SizedBox(height: 8),
                              Text('Erreur: ${snapshot.error}'),
                            ],
                          ),
                        );
                      }

                      final programmes = snapshot.data ?? [];

                      if (programmes.isEmpty) {
                        return Center(
                          child: Column(
                            children: [
                              Icon(Icons.fitness_center, size: 50, color: Colors.grey),
                              const SizedBox(height: 8),
                              Text(
                                'Aucun programme créé',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: programmes.length,
                        itemBuilder: (context, index) {
                          final programme = programmes[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getNiveauColor(programme.niveau),
                                child: Text(
                                  programme.dureeJours.toString(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(programme.titre),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Niveau: ${programme.niveau}'),
                                  Text('Tags: ${programme.tags.join(', ')}'),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => GestionSeancesScreen(
                                        programme: programme,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Color _getNiveauColor(String niveau) {
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