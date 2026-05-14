import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/cours.dart';
import '../screens/cours/detail_cours_screen.dart';
import '../services/firebase_service.dart';
import '../services/attente_service.dart';
import '../models/attente.dart';
import '../config/app_theme.dart';

class CoursCard extends StatelessWidget {
  final Cours cours;
  const CoursCard({super.key, required this.cours});

  Color get _niveauDot {
    switch (cours.niveau) {
      case 'Avancé':       return AppColors.danger;
      case 'Intermédiaire': return AppColors.warn;
      default:             return AppColors.sage;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFull = cours.placesRestantes <= 0;
    final dateStr =
        '${cours.date.day.toString().padLeft(2, '0')}/${cours.date.month.toString().padLeft(2, '0')}/${cours.date.year}';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetailCoursScreen(cours: cours)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.sh1,
          // left accent border by level
          border: Border(
            left: BorderSide(color: _niveauDot, width: 3),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top row: title + niveau tag ──────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      cours.titre,
                      style: AppText.body(size: 16, weight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: niveauBg(cours.niveau),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      cours.niveau,
                      style: AppText.body(
                          size: 11, weight: FontWeight.w500, color: niveauColor(cours.niveau)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // ── Meta row ─────────────────────────────────────────
              Wrap(
                spacing: 14,
                runSpacing: 4,
                children: [
                  _Meta(icon: Icons.person_outline_rounded, label: cours.coach),
                  _Meta(
                      icon: Icons.access_time_rounded,
                      label: '${cours.duree} min'),
                  _Meta(icon: Icons.calendar_today_outlined, label: dateStr),
                ],
              ),
              const SizedBox(height: 14),

              // ── Bottom row: capacity + action ────────────────────
              Row(
                children: [
                  // Capacity bar
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              isFull
                                  ? 'Complet'
                                  : '${cours.placesRestantes} place${cours.placesRestantes > 1 ? 's' : ''} restante${cours.placesRestantes > 1 ? 's' : ''}',
                              style: AppText.body(
                                size: 12,
                                weight: FontWeight.w500,
                                color: isFull ? AppColors.danger : AppColors.sageDeep,
                              ),
                            ),
                            Text(
                              ' / ${cours.placesMax}',
                              style: AppText.body(size: 12, color: AppColors.ink4),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: cours.placesMax > 0
                                ? (cours.placesMax - cours.placesRestantes) / cours.placesMax
                                : 1.0,
                            minHeight: 4,
                            backgroundColor: AppColors.bg2,
                            color: isFull ? AppColors.danger : AppColors.sage,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Action button
                  FutureBuilder<bool>(
                    future: FirebaseFirestore.instance
                        .collection('reservations')
                        .where('utilisateurId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                        .where('coursId', isEqualTo: cours.id)
                        .get()
                        .then((snap) => snap.docs.isNotEmpty),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(width: 90, height: 34);
                      }
                      if (snapshot.data == true) {
                        return _ReservedBadge();
                      }
                      return isFull
                          ? _WaitlistButton(cours: cours)
                          : _ReserveButton(cours: cours);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Meta chip ─────────────────────────────────────────────────────────────────
class _Meta extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Meta({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.ink4),
        const SizedBox(width: 4),
        Text(label, style: AppText.body(size: 12, color: AppColors.ink3)),
      ],
    );
  }
}

// ── Reserve button ────────────────────────────────────────────────────────────
class _ReserveButton extends StatelessWidget {
  final Cours cours;
  const _ReserveButton({required this.cours});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _reserve(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          'Réserver',
          style: AppText.body(size: 13, weight: FontWeight.w500, color: Colors.white),
        ),
      ),
    );
  }

  Future<void> _reserve(BuildContext context) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final doc = await FirebaseFirestore.instance
          .collection('utilisateurs')
          .doc(userId)
          .get();
      if (doc.exists && (doc.data()?['role'] ?? 'client') == 'admin') {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Les administrateurs ne peuvent pas réserver de cours')),
          );
        }
        return;
      }
    }

    if (!context.mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Confirmer la réservation',
            style: AppText.body(size: 17, weight: FontWeight.w600)),
        content: Text('Voulez-vous réserver "${cours.titre}" ?',
            style: AppText.body(size: 15, color: AppColors.ink2)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler', style: AppText.body(size: 14, color: AppColors.ink3)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Confirmer', style: AppText.body(size: 14, weight: FontWeight.w600, color: AppColors.sage)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final success = await FirebaseService().reserverCours(cours.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Cours réservé avec succès' : 'Impossible de réserver ce cours'),
          ),
        );
      }
    }
  }
}

// ── Waitlist button ───────────────────────────────────────────────────────────
class _WaitlistButton extends StatelessWidget {
  final Cours cours;
  const _WaitlistButton({required this.cours});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Attente?>(
      future: AttenteService().estDansListeAttente(cours.id),
      builder: (context, snapshot) {
        final enAttente = snapshot.data != null;
        return GestureDetector(
          onTap: () => _toggleWaitlist(context, enAttente),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: enAttente ? AppColors.sageBg : AppColors.bg2,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                color: enAttente ? AppColors.sage : AppColors.line2,
                width: 1,
              ),
            ),
            child: Text(
              enAttente ? 'Inscrit' : 'Liste d\'attente',
              style: AppText.body(
                size: 12,
                weight: FontWeight.w500,
                color: enAttente ? AppColors.sageDeep : AppColors.ink3,
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _toggleWaitlist(BuildContext context, bool enAttente) async {
    final svc = AttenteService();
    final messenger = ScaffoldMessenger.of(context);

    if (enAttente) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("Quitter la liste d'attente",
              style: AppText.body(size: 17, weight: FontWeight.w600)),
          content: Text('Voulez-vous quitter la liste d\'attente pour "${cours.titre}" ?',
              style: AppText.body(size: 15, color: AppColors.ink2)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Annuler', style: AppText.body(size: 14, color: AppColors.ink3)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Quitter',
                  style: AppText.body(size: 14, weight: FontWeight.w600, color: AppColors.danger)),
            ),
          ],
        ),
      );
      if (confirm == true) {
        await svc.quitterListeAttente(cours.id);
        messenger.showSnackBar(
          const SnackBar(content: Text("Retiré de la liste d'attente")),
        );
      }
    } else {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("Liste d'attente",
              style: AppText.body(size: 17, weight: FontWeight.w600)),
          content: Text(
              "Le cours est complet. Voulez-vous être notifié quand une place se libère ?",
              style: AppText.body(size: 15, color: AppColors.ink2)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Annuler', style: AppText.body(size: 14, color: AppColors.ink3)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text("M'inscrire",
                  style: AppText.body(size: 14, weight: FontWeight.w600, color: AppColors.sage)),
            ),
          ],
        ),
      );
      if (confirm == true) {
        final ok = await svc.rejoindreListeAttente(cours.id);
        messenger.showSnackBar(
          SnackBar(
            content: Text(
                ok ? "Inscrit à la liste d'attente" : "Impossible de rejoindre la liste"),
          ),
        );
      }
    }
  }
}

// ── Reserved badge ────────────────────────────────────────────────────────────
class _ReservedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.sageBg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.sage, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_rounded, size: 14, color: AppColors.sageDeep),
          const SizedBox(width: 4),
          Text(
            'Réservé',
            style: AppText.body(
              size: 12,
              weight: FontWeight.w500,
              color: AppColors.sageDeep,
            ),
          ),
        ],
      ),
    );
  }
}
