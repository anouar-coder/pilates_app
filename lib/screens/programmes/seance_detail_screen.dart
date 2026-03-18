// lib/screens/programmes/seance_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/programme_service.dart';
import '../../models/seance.dart';
import '../../models/exercice.dart';

class SeanceDetailScreen extends StatefulWidget {
  final String programmeId;
  final Seance seance;
  final Exercice exercice;

  const SeanceDetailScreen({
    super.key,
    required this.programmeId,
    required this.seance,
    required this.exercice,
  });

  @override
  State<SeanceDetailScreen> createState() => _SeanceDetailScreenState();
}

class _SeanceDetailScreenState extends State<SeanceDetailScreen> {
  final ProgrammeService _programmeService = ProgrammeService();
  bool _isLoading = false;

  Future<void> _marquerTermine() async {
    setState(() => _isLoading = true);
    await _programmeService.marquerExerciceFait(
      widget.programmeId,
      widget.seance.id,
      widget.exercice.id,
    );
    setState(() => _isLoading = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Exercice terminé !'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _ouvrirVideo() async {
    if (widget.exercice.videoUrl != null) {
      final url = Uri.parse(widget.exercice.videoUrl!);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exercice.titre),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre
            Text(
              widget.exercice.titre,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Séance
            Text(
              'Séance: ${widget.seance.titre}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),

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
              widget.exercice.description,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 24),

            // Détails de l'exercice
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.timer, color: Colors.blue),
                        const SizedBox(width: 12),
                        const Text(
                          'Durée: ',
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          '${widget.exercice.dureeSecondes} secondes',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.loop, color: Colors.blue),
                        const SizedBox(width: 12),
                        const Text(
                          'Répétitions: ',
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          '${widget.exercice.repetitions} fois',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Matériel nécessaire
            if (widget.exercice.materiel.isNotEmpty) ...[
              const Text(
                'Matériel nécessaire',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: widget.exercice.materiel.map((item) {
                  return Chip(
                    label: Text(item),
                    avatar: const Icon(Icons.fitness_center, size: 16),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Bouton vidéo
            if (widget.exercice.videoUrl != null) ...[
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _ouvrirVideo,
                  icon: const Icon(Icons.play_circle),
                  label: const Text('Voir la vidéo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Bouton marquer comme fait
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _marquerTermine,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.check),
                label: const Text('Marquer comme terminé'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}