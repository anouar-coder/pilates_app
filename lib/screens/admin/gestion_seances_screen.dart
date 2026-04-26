// lib/screens/admin/gestion_seances_screen.dart
import 'package:flutter/material.dart';
import '../../services/programme_service.dart';
import '../../models/programme.dart';
import '../../models/seance.dart';
import 'ajouter_exercice_screen.dart';

class GestionSeancesScreen extends StatefulWidget {
  final Programme programme;

  const GestionSeancesScreen({super.key, required this.programme});

  @override
  State<GestionSeancesScreen> createState() => _GestionSeancesScreenState();
}

class _GestionSeancesScreenState extends State<GestionSeancesScreen> {
  final ProgrammeService _programmeService = ProgrammeService();
  final _titreController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _jourController = TextEditingController();
  bool _isLoading = false;

  Future<void> _ajouterSeance() async {
    if (_titreController.text.isEmpty || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final seance = Seance(
      id: '',
      programmeId: widget.programme.id,
      jour: int.tryParse(_jourController.text) ?? 1,
      titre: _titreController.text,
      description: _descriptionController.text,
      exercices: [],
    );

    final success = await _programmeService.ajouterSeance(widget.programme.id, seance);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Séance ajoutée'), backgroundColor: Colors.green),
      );
      _titreController.clear();
      _descriptionController.clear();
      _jourController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Séances - ${widget.programme.titre}'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Formulaire d'ajout
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey[100],
                  child: Column(
                    children: [
                      TextField(
                        controller: _jourController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Jour',
                          hintText: '1, 2, 3...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _titreController,
                        decoration: InputDecoration(
                          labelText: 'Titre de la séance',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _descriptionController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _ajouterSeance,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          minimumSize: const Size(double.infinity, 45),
                        ),
                        child: const Text('Ajouter la séance'),
                      ),
                    ],
                  ),
                ),

                // Liste des séances existantes
                Expanded(
                  child: StreamBuilder<List<Seance>>(
                    stream: _programmeService.getSeances(widget.programme.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(child: Text('Erreur: ${snapshot.error}'));
                      }

                      final seances = snapshot.data ?? [];

                      if (seances.isEmpty) {
                        return const Center(
                          child: Text('Aucune séance pour ce programme'),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: seances.length,
                        itemBuilder: (context, index) {
                          final seance = seances[index];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue,
                                child: Text('J${seance.jour}'),
                              ),
                              title: Text(seance.titre),
                              subtitle: Text(seance.description),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.fitness_center),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => AjouterExerciceScreen(
                                            programmeId: widget.programme.id,
                                            seance: seance,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      // À implémenter: supprimer séance
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
