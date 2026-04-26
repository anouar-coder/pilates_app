import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/avis_service.dart';
import '../../models/cours.dart';
import '../../config/app_theme.dart';

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

  String _getNoteTexte(int note) {
    switch (note) {
      case 1: return 'Très déçu(e)';
      case 2: return 'Déçu(e)';
      case 3: return 'Moyen';
      case 4: return 'Bon';
      default: return 'Excellent !';
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
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Merci pour votre avis !')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'ajouter un avis')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ÉVALUATION', style: AppText.label(size: 10, color: AppColors.ink3, letterSpacing: 2)),
            Text(
              'Mon avis',
              style: GoogleFonts.fraunces(
                fontSize: 18,
                fontWeight: FontWeight.w400,
                fontStyle: FontStyle.italic,
                color: AppColors.ink,
                letterSpacing: -0.4,
              ),
            ),
          ],
        ),
        toolbarHeight: 64,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.sage, strokeWidth: 2))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cours card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      boxShadow: AppShadows.sh1,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.sageBg,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: const Icon(Icons.self_improvement_rounded,
                              color: AppColors.sageDeep, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.cours.titre,
                                  style: AppText.body(size: 15, weight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text(
                                '${widget.cours.date.day}/${widget.cours.date.month}/${widget.cours.date.year}',
                                style: AppText.body(size: 13, color: AppColors.ink3),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  Text('VOTRE NOTE', style: AppText.label(size: 10, color: AppColors.ink3, letterSpacing: 2)),
                  const SizedBox(height: 20),

                  // Stars
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final etoile = i + 1;
                      return GestureDetector(
                        onTap: () => setState(() => _note = etoile),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(
                            etoile <= _note ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: AppColors.clay,
                            size: 44,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      _getNoteTexte(_note),
                      style: AppText.body(size: 15, weight: FontWeight.w500, color: AppColors.sageDeep),
                    ),
                  ),

                  const SizedBox(height: 32),
                  Text('COMMENTAIRE', style: AppText.label(size: 10, color: AppColors.ink3, letterSpacing: 2)),
                  const SizedBox(height: 12),

                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      boxShadow: AppShadows.sh1,
                    ),
                    child: TextField(
                      controller: _commentaireController,
                      maxLines: 4,
                      style: AppText.body(size: 15),
                      decoration: InputDecoration(
                        hintText: 'Partagez votre expérience (optionnel)…',
                        hintStyle: AppText.body(size: 15, color: AppColors.ink4),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide: const BorderSide(color: AppColors.line, width: 1),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide: const BorderSide(color: AppColors.line, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide: const BorderSide(color: AppColors.sage, width: 1.5),
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                  AppButton(label: 'Envoyer mon avis', onPressed: _envoyerAvis),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _commentaireController.dispose();
    super.dispose();
  }
}
