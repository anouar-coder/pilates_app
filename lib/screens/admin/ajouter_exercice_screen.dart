// lib/screens/admin/ajouter_exercice_screen.dart
import 'package:flutter/material.dart';
import '../../services/programme_service.dart';
import '../../models/seance.dart';
import '../../models/exercice.dart';

class AjouterExerciceScreen extends StatefulWidget {
  final String programmeId;
  final Seance seance;

  const AjouterExerciceScreen({
    super.key,
    required this.programmeId,
    required this.seance,
  });

  @override
  State<AjouterExerciceScreen> createState() => _AjouterExerciceScreenState();
}

class _AjouterExerciceScreenState extends State<AjouterExerciceScreen> {
  final ProgrammeService _programmeService = ProgrammeService();
  final _titreController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dureeController = TextEditingController();
  final _repetitionsController = TextEditingController();
  final _videoController = TextEditingController();
  final _materielController = TextEditingController();
  bool _isLoading = false;

  Future<void> _ajouterExercice() async {
    if (_titreController.text.isEmpty || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir les champs obligatoires')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final exercice = Exercice(
      id: '',
      titre: _titreController.text,
      description: _descriptionController.text,
      dureeSecondes: int.tryParse(_dureeController.text) ?? 60,
      repetitions: int.tryParse(_repetitionsController.text) ?? 10,
      videoUrl: _videoController.text.isNotEmpty ? _videoController.text : null,
      materiel: _materielController.text.isNotEmpty
          ? _materielController.text.split(',').map((e) => e.trim()).toList()
          : [],
    );

    final success = await _programmeService.ajouterExercice(
      widget.programmeId,
      widget.seance.id,
      exercice,
    );

    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Exercice ajouté'), backgroundColor: Colors.green),
      );
      _titreController.clear();
      _descriptionController.clear();
      _dureeController.clear();
      _repetitionsController.clear();
      _videoController.clear();
      _materielController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ajouter exercice - ${widget.seance.titre}'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _titreController,
                    decoration: InputDecoration(
                      labelText: 'Titre de l\'exercice *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Description *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _dureeController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Durée (secondes)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _repetitionsController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Répétitions',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _videoController,
                    decoration: InputDecoration(
                      labelText: 'Lien YouTube (optionnel)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _materielController,
                    decoration: InputDecoration(
                      labelText: 'Matériel (séparé par des virgules)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _ajouterExercice,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('Ajouter l\'exercice'),
                  ),
                ],
              ),
            ),
    );
  }
}
