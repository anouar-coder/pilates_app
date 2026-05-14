import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/firebase_service.dart';
import '../../services/avis_service.dart';
import '../../models/reservation.dart';
import '../../models/cours.dart';
import '../../config/app_theme.dart';
import '../avis/ajouter_avis_screen.dart';

class MesReservationsScreen extends StatefulWidget {
  const MesReservationsScreen({super.key});

  @override
  State<MesReservationsScreen> createState() => _MesReservationsScreenState();
}

class _MesReservationsScreenState extends State<MesReservationsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final AvisService _avisService = AvisService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('MES COURS', style: AppText.label(size: 11, color: AppColors.ink3, letterSpacing: 2.5)),
                  const SizedBox(height: 4),
                  Text(
                    'Réservations',
                    style: GoogleFonts.fraunces(
                      fontSize: 28,
                      fontWeight: FontWeight.w400,
                      fontStyle: FontStyle.italic,
                      color: AppColors.ink,
                      letterSpacing: -0.8,
                      height: 1.05,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.line),

            // ── List ─────────────────────────────────────────────────
            Expanded(
              child: StreamBuilder<List<Reservation>>(
                stream: _firebaseService.getMesReservations(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Erreur: ${snapshot.error}',
                          style: AppText.body(size: 14, color: AppColors.danger)),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(color: AppColors.sage, strokeWidth: 2));
                  }

                  final reservations = snapshot.data ?? [];

                  if (reservations.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bookmark_outline_rounded,
                              size: 60, color: AppColors.ink4.withValues(alpha: 0.4)),
                          const SizedBox(height: 16),
                          Text('Aucune réservation pour le moment',
                              style: AppText.body(size: 15, color: AppColors.ink3)),
                          const SizedBox(height: 24),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/accueil'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.ink,
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                              ),
                              child: Text('Voir les cours',
                                  style: AppText.body(size: 14, weight: FontWeight.w500, color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: reservations.length,
                    itemBuilder: (context, index) {
                      final reservation = reservations[index];
                      return FutureBuilder<Cours?>(
                        future: _firebaseService.getCoursById(reservation.coursId),
                        builder: (context, coursSnapshot) {
                          if (coursSnapshot.connectionState == ConnectionState.waiting) {
                            return _LoadingCard();
                          }
                          if (coursSnapshot.data == null) {
                            return const SizedBox.shrink();
                          }
                          final cours = coursSnapshot.data!;
                          return _ReservationCard(
                            cours: cours,
                            reservation: reservation,
                            avisService: _avisService,
                            firebaseService: _firebaseService,
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Loading placeholder ───────────────────────────────────────────────────────
class _LoadingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.sh1,
      ),
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.sage, strokeWidth: 2),
      ),
    );
  }
}

// ── Reservation card ──────────────────────────────────────────────────────────
class _ReservationCard extends StatelessWidget {
  final Cours cours;
  final Reservation reservation;
  final AvisService avisService;
  final FirebaseService firebaseService;

  const _ReservationCard({
    required this.cours,
    required this.reservation,
    required this.avisService,
    required this.firebaseService,
  });

  bool get _isPast => cours.date.add(Duration(minutes: cours.duree)).isBefore(DateTime.now());

  Color get _niveauDot {
    switch (cours.niveau) {
      case 'Avancé':        return AppColors.danger;
      case 'Intermédiaire': return AppColors.warn;
      default:              return AppColors.sage;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${cours.date.day.toString().padLeft(2, '0')}/${cours.date.month.toString().padLeft(2, '0')}/${cours.date.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.sh1,
        border: Border(left: BorderSide(color: _niveauDot, width: 3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + status
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(cours.titre,
                      style: AppText.body(size: 16, weight: FontWeight.w600)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _isPast ? AppColors.bg2 : AppColors.sageBg,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    _isPast ? 'Terminé' : 'À venir',
                    style: AppText.body(
                      size: 11,
                      weight: FontWeight.w500,
                      color: _isPast ? AppColors.ink3 : AppColors.sageDeep,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Meta
            Wrap(
              spacing: 14,
              runSpacing: 4,
              children: [
                _Meta(icon: Icons.person_outline_rounded, label: cours.coach),
                _Meta(icon: Icons.calendar_today_outlined, label: dateStr),
                _Meta(icon: Icons.access_time_rounded, label: '${cours.duree} min'),
              ],
            ),
            const SizedBox(height: 14),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_isPast)
                  _ActionBtn(
                    label: 'Évaluer',
                    icon: Icons.star_outline_rounded,
                    color: AppColors.clay,
                    onTap: () => _handleRating(context),
                  ),
                if (_isPast) const SizedBox(width: 8),
                _ActionBtn(
                  label: 'Annuler',
                  icon: Icons.close_rounded,
                  color: AppColors.danger,
                  outline: true,
                  onTap: () => _showCancelDialog(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleRating(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final existing = await avisService.getMonAvis(cours.id);
    if (!context.mounted) return;
    if (existing != null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Vous avez déjà donné votre avis')),
      );
    } else {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => AjouterAvisScreen(cours: cours)));
    }
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Annuler la réservation',
            style: AppText.body(size: 17, weight: FontWeight.w600)),
        content: Text('Voulez-vous annuler votre réservation pour "${cours.titre}" ?',
            style: AppText.body(size: 15, color: AppColors.ink2)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Non', style: AppText.body(size: 14, color: AppColors.ink3)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final messenger = ScaffoldMessenger.of(context);
              final success = await firebaseService.annulerReservation(
                reservation.id,
                reservation.coursId,
              );
              messenger.showSnackBar(
                SnackBar(
                  content: Text(success
                      ? 'Réservation annulée'
                      : 'Erreur lors de l\'annulation'),
                ),
              );
            },
            child: Text('Oui, annuler',
                style: AppText.body(size: 14, weight: FontWeight.w600, color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}

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

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool outline;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.outline = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: outline ? Colors.transparent : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: outline
              ? Border.all(color: color.withValues(alpha: 0.4), width: 1)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(label,
                style: AppText.body(size: 12, weight: FontWeight.w500, color: color)),
          ],
        ),
      ),
    );
  }
}
