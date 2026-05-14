// lib/screens/admin/gestion_seances_screen.dart
import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
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
    if (_titreController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty ||
        _jourController.text.trim().isEmpty) {
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
      titre: _titreController.text.trim(),
      description: _descriptionController.text.trim(),
      exercices: [],
    );

    final success = await _programmeService.ajouterSeance(widget.programme.id, seance);

    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Seance ajoutee' : 'Ajout impossible'),
        backgroundColor: success ? AppColors.ink : AppColors.danger,
      ),
    );

    if (success) {
      _titreController.clear();
      _descriptionController.clear();
      _jourController.clear();
    }
  }

  Future<void> _supprimerSeance(Seance seance) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer la seance', style: AppText.body(size: 18, weight: FontWeight.w600)),
        content: Text(
          'Voulez-vous supprimer "${seance.titre}" et tous ses exercices ?',
          style: AppText.body(size: 15, color: AppColors.ink2),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Supprimer',
              style: AppText.body(size: 14, weight: FontWeight.w600, color: AppColors.danger),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await _programmeService.supprimerSeance(widget.programme.id, seance.id);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Seance supprimee' : 'Suppression impossible'),
        backgroundColor: success ? AppColors.ink : AppColors.danger,
      ),
    );
  }

  @override
  void dispose() {
    _titreController.dispose();
    _descriptionController.dispose();
    _jourController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('Seances - ${widget.programme.titre}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.sage))
          : Column(
              children: [
                _AddSeanceForm(
                  jourController: _jourController,
                  titreController: _titreController,
                  descriptionController: _descriptionController,
                  onSubmit: _ajouterSeance,
                ),
                const Divider(height: 1, color: AppColors.line),
                Expanded(
                  child: StreamBuilder<List<Seance>>(
                    stream: _programmeService.getSeances(widget.programme.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: AppColors.sage));
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Erreur: ${snapshot.error}',
                            style: AppText.body(color: AppColors.danger),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }

                      final seances = snapshot.data ?? [];

                      if (seances.isEmpty) {
                        return Center(
                          child: Text(
                            'Aucune seance pour ce programme',
                            style: AppText.body(size: 15, color: AppColors.ink3),
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: seances.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final seance = seances[index];
                          return AppCard(
                            padding: EdgeInsets.zero,
                            borderRadius: AppRadius.md,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor: AppColors.sageBg,
                                foregroundColor: AppColors.sageDeep,
                                child: Text(
                                  'J${seance.jour}',
                                  style: AppText.body(size: 13, weight: FontWeight.w700, color: AppColors.sageDeep),
                                ),
                              ),
                              title: Text(seance.titre, style: AppText.body(size: 16, weight: FontWeight.w600)),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(seance.description, style: AppText.body(size: 13, color: AppColors.ink3)),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'Ajouter des exercices',
                                    icon: const Icon(Icons.fitness_center, color: AppColors.sageDeep),
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
                                    tooltip: 'Supprimer',
                                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                                    onPressed: () => _supprimerSeance(seance),
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

class _AddSeanceForm extends StatelessWidget {
  final TextEditingController jourController;
  final TextEditingController titreController;
  final TextEditingController descriptionController;
  final VoidCallback onSubmit;

  const _AddSeanceForm({
    required this.jourController,
    required this.titreController,
    required this.descriptionController,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.sh1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nouvelle seance', style: AppText.body(size: 18, weight: FontWeight.w600)),
          const SizedBox(height: 14),
          TextField(
            controller: jourController,
            keyboardType: TextInputType.number,
            style: AppText.body(size: 15),
            decoration: const InputDecoration(
              labelText: 'Jour',
              hintText: '1, 2, 3...',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: titreController,
            style: AppText.body(size: 15),
            decoration: const InputDecoration(labelText: 'Titre de la seance'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: descriptionController,
            maxLines: 2,
            style: AppText.body(size: 15),
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          const SizedBox(height: 14),
          AppButton(
            label: 'Ajouter la seance',
            onPressed: onSubmit,
            leading: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }
}
