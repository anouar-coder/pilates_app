// lib/screens/avis/ajouter_avis_screen.dart
import 'package:flutter/material.dart';
import '../../services/avis_service.dart';
import '../../models/cours.dart';

class AjouterAvisScreen extends StatefulWidget {
  final Cours cours;

  const AjouterAvisScreen({super.key, required this.cours});

  @override
  State<AjouterAvisScreen> createState() => _AjouterAvisScreenState();
}

class _AjouterAvisScreenState extends State<AjouterAvisScreen> {
  final AvisService _avisService = AvisService();
  int _note = 5;
  final TextEditingController _commentaireController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Donner mon avis'),
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
                  // Info cours
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.fitness_center, color: Colors.blue, size: 32),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.cours.titre,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${widget.cours.date.day}/${widget.cours.date.month}/${widget.cours.date.year}',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Sélection de note
                  const Text(
                    'Votre note',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(5, (index) {
                        final etoile = index + 1;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _note = etoile;
                            });
                          },
                          child: Icon(
                            etoile <= _note ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 40,
                          ),
                        );
                      }),
                    ),
                  ),

                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      _getNoteTexte(_note),
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Commentaire
                  const Text(
                    'Commentaire (optionnel)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _commentaireController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Partagez votre expérience...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Bouton envoyer
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _envoyerAvis,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Envoyer mon avis',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String _getNoteTexte(int note) {
    switch (note) {
      case 1:
        return 'Très déçu(e)';
      case 2:
        return 'Déçu(e)';
      case 3:
        return 'Moyen';
      case 4:
        return 'Bon';
      case 5:
        return 'Excellent !';
      default:
        return '';
    }
  }

  Future<void> _envoyerAvis() async {
    setState(() => _isLoading = true);

    final success = await _avisService.ajouterAvis(
      coursId: widget.cours.id,
      coursTitre: widget.cours.titre,
      note: _note,
      commentaire: _commentaireController.text.isNotEmpty
          ? _commentaireController.text
          : null,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Merci pour votre avis !'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Impossible d\'ajouter un avis'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _commentaireController.dispose();
    super.dispose();
  }
}
