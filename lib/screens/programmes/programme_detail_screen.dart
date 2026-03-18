// lib/screens/programmes/programme_detail_screen.dart
import 'package:flutter/material.dart';
import '../../services/programme_service.dart';
import '../../models/programme.dart';
import '../../models/seance.dart';
import 'seance_detail_screen.dart';

class ProgrammeDetailScreen extends StatefulWidget {
  final Programme programme;

  const ProgrammeDetailScreen({super.key, required this.programme});

  @override
  State<ProgrammeDetailScreen> createState() => _ProgrammeDetailScreenState();
}

class _ProgrammeDetailScreenState extends State<ProgrammeDetailScreen> {
  final ProgrammeService _programmeService = ProgrammeService();
  Map<String, bool> _progression = {};

  @override
  void initState() {
    super.initState();
    _chargerProgression();
  }

  Future<void> _chargerProgression() async {
    final prog = await _programmeService.getProgression(widget.programme.id);
    setState(() {
      _progression = prog;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.programme.titre),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Seance>>(
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
              child: Text('Aucune séance dans ce programme'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: seances.length,
            itemBuilder: (context, index) {
              final seance = seances[index];
              
              // Calculer la progression de la séance
              int exercicesFaits = 0;
              for (var exercice in seance.exercices) {
                if (_progression['${seance.id}_${exercice.id}'] == true) {
                  exercicesFaits++;
                }
              }
              double progression = seance.exercices.isEmpty 
                  ? 0 
                  : exercicesFaits / seance.exercices.length;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: progression == 1
                        ? Colors.green
                        : progression > 0
                            ? Colors.orange
                            : Colors.grey,
                    child: Text(
                      'J${seance.jour}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(seance.titre),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(seance.description),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: progression,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progression == 1 ? Colors.green : Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  children: seance.exercices.map((exercice) {
                    final estFait = _progression['${seance.id}_${exercice.id}'] == true;
                    
                    return ListTile(
                      leading: Checkbox(
                        value: estFait,
                        onChanged: (value) async {
                          if (value == true) {
                            await _programmeService.marquerExerciceFait(
                              widget.programme.id,
                              seance.id,
                              exercice.id,
                            );
                            _chargerProgression();
                          }
                        },
                      ),
                      title: Text(
                        exercice.titre,
                        style: TextStyle(
                          decoration: estFait ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      subtitle: Text(
                        '${exercice.repetitions} reps • ${exercice.dureeSecondes}s',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.play_circle, color: Colors.blue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SeanceDetailScreen(
                                programmeId: widget.programme.id,
                                seance: seance,
                                exercice: exercice,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
