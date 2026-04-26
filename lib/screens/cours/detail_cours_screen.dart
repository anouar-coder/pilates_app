import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/cours.dart';
import '../../models/avis.dart';
import '../../services/avis_service.dart';
import '../../config/app_theme.dart';

class DetailCoursScreen extends StatelessWidget {
  final Cours cours;
  const DetailCoursScreen({super.key, required this.cours});

  bool get _isFull => cours.placesRestantes <= 0;
  double get _fillPct =>
      cours.placesMax > 0
          ? (cours.placesMax - cours.placesRestantes) / cours.placesMax
          : 1.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ── Hero image header ────────────────────────────────
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: AppColors.bg,
                foregroundColor: AppColors.ink,
                elevation: 0,
                scrolledUnderElevation: 0,
                leading: Padding(
                  padding: const EdgeInsets.all(8),
                  child: _CircleButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          niveauColor(cours.niveau).withValues(alpha: 0.15),
                          AppColors.bg,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.self_improvement_rounded,
                        size: 100,
                        color: niveauColor(cours.niveau).withValues(alpha: 0.25),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Content ──────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 140),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Tags row
                    Row(
                      children: [
                        AppTag(label: cours.niveau, background: niveauBg(cours.niveau), textColor: niveauColor(cours.niveau)),
                        const SizedBox(width: 8),
                        AppTag(
                          label: '${cours.duree} min',
                          background: AppColors.bg2,
                          textColor: AppColors.ink3,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Title
                    Text(
                      cours.titre,
                      style: GoogleFonts.fraunces(
                        fontSize: 32,
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.italic,
                        color: AppColors.ink,
                        letterSpacing: -0.8,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Meta info row
                    _MetaRow(cours: cours),
                    const SizedBox(height: 20),

                    // Rating row
                    _RatingRow(cours: cours),
                    const SizedBox(height: 20),

                    // Capacity card
                    _CapacityCard(cours: cours, fillPct: _fillPct, isFull: _isFull),
                    const SizedBox(height: 24),

                    // Focus areas
                    const AppSectionHeader(title: 'Ce que vous travaillez'),
                    Row(
                      children: [
                        _FocusChip(icon: Icons.self_improvement_rounded, label: 'Posture'),
                        const SizedBox(width: 10),
                        _FocusChip(icon: Icons.air_rounded, label: 'Respiration'),
                        const SizedBox(width: 10),
                        _FocusChip(icon: Icons.fitness_center_rounded, label: 'Gainage'),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Description
                    const AppSectionHeader(title: 'À propos de la séance'),
                    Text(
                      cours.description,
                      style: AppText.body(size: 14, color: AppColors.ink2, height: 1.6),
                    ),
                    const SizedBox(height: 24),

                    // Reviews section
                    _ReviewsSection(cours: cours),
                  ]),
                ),
              ),
            ],
          ),

          // ── Bottom CTA ───────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _BottomCTA(cours: cours, isFull: _isFull),
          ),
        ],
      ),
    );
  }
}

// ── Back / action circle button ───────────────────────────────────────────────
class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.card.withValues(alpha: 0.92),
          shape: BoxShape.circle,
          boxShadow: AppShadows.sh1,
        ),
        child: Icon(icon, color: AppColors.ink, size: 20),
      ),
    );
  }
}

// ── Meta info row ─────────────────────────────────────────────────────────────
class _MetaRow extends StatelessWidget {
  final Cours cours;
  const _MetaRow({required this.cours});

  @override
  Widget build(BuildContext context) {
    final date = cours.date;
    final dateStr =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _MetaChip(icon: Icons.person_outline_rounded, label: cours.coach),
        _MetaChip(icon: Icons.calendar_today_outlined, label: dateStr),
        _MetaChip(icon: Icons.location_on_outlined, label: 'Studio Marais'),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.ink3),
        const SizedBox(width: 5),
        Text(label, style: AppText.body(size: 13, color: AppColors.ink3)),
      ],
    );
  }
}

// ── Rating row ────────────────────────────────────────────────────────────────
class _RatingRow extends StatelessWidget {
  final Cours cours;
  const _RatingRow({required this.cours});

  @override
  Widget build(BuildContext context) {
    final note = cours.noteMoyenne ?? 0.0;
    final nbAvis = cours.nombreAvis ?? 0;
    return Row(
      children: [
        ...List.generate(5, (i) {
          return Icon(
            i < note.round() ? Icons.star_rounded : Icons.star_outline_rounded,
            color: AppColors.clay,
            size: 18,
          );
        }),
        const SizedBox(width: 8),
        Text(
          note.toStringAsFixed(1),
          style: AppText.body(size: 14, weight: FontWeight.w600),
        ),
        const SizedBox(width: 4),
        Text(
          '($nbAvis avis)',
          style: AppText.body(size: 13, color: AppColors.ink3),
        ),
      ],
    );
  }
}

// ── Capacity card ─────────────────────────────────────────────────────────────
class _CapacityCard extends StatelessWidget {
  final Cours cours;
  final double fillPct;
  final bool isFull;
  const _CapacityCard({required this.cours, required this.fillPct, required this.isFull});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Places occupées', style: AppText.body(size: 13, color: AppColors.ink3)),
              Text(
                '${cours.placesMax - cours.placesRestantes} / ${cours.placesMax}',
                style: AppText.body(size: 13, weight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: fillPct,
              minHeight: 6,
              backgroundColor: AppColors.bg2,
              color: isFull ? AppColors.danger : AppColors.sage,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isFull
                ? 'Cours complet — rejoignez la liste d\'attente'
                : '${cours.placesRestantes} place${cours.placesRestantes > 1 ? 's' : ''} restante${cours.placesRestantes > 1 ? 's' : ''} — réservation jusqu\'à 2h avant',
            style: AppText.body(
              size: 12,
              color: isFull ? AppColors.danger : AppColors.ink3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Focus chip ────────────────────────────────────────────────────────────────
class _FocusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FocusChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.cardAlt,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: AppColors.sageDeep),
            const SizedBox(height: 8),
            Text(label, style: AppText.body(size: 12, color: AppColors.ink2), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ── Reviews section ───────────────────────────────────────────────────────────
class _ReviewsSection extends StatelessWidget {
  final Cours cours;
  const _ReviewsSection({required this.cours});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Avis>>(
      stream: AvisService().getAvisPourCours(cours.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: AppColors.sage, strokeWidth: 2),
            ),
          );
        }
        final avis = snapshot.data ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSectionHeader(
              title: 'Avis',
              action: avis.isEmpty ? null : 'Ajouter le mien',
              onAction: () => Navigator.pushNamed(context, '/ajouter_avis',
                  arguments: cours.id),
            ),
            if (avis.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'Aucun avis pour le moment.',
                    style: AppText.body(size: 14, color: AppColors.ink3),
                  ),
                ),
              )
            else
              ...avis.map((a) => _AvisCard(avis: a)),
          ],
        );
      },
    );
  }
}

class _AvisCard extends StatelessWidget {
  final Avis avis;
  const _AvisCard({required this.avis});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.sh1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.sageSoft,
                    backgroundImage: avis.utilisateurPhoto != null
                        ? NetworkImage(avis.utilisateurPhoto!)
                        : null,
                    child: avis.utilisateurPhoto == null
                        ? Text(
                            avis.utilisateurNom.isNotEmpty
                                ? avis.utilisateurNom[0].toUpperCase()
                                : '?',
                            style: AppText.body(size: 12, weight: FontWeight.w600, color: AppColors.sageDeep),
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    avis.utilisateurNom,
                    style: AppText.body(size: 13, weight: FontWeight.w500),
                  ),
                ],
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < avis.note ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: AppColors.clay,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
          if (avis.commentaire != null && avis.commentaire!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              avis.commentaire!,
              style: AppText.body(size: 13, color: AppColors.ink2, height: 1.5),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Bottom CTA bar ────────────────────────────────────────────────────────────
class _BottomCTA extends StatelessWidget {
  final Cours cours;
  final bool isFull;
  const _BottomCTA({required this.cours, required this.isFull});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: AppColors.bg.withValues(alpha: 0.96),
        border: const Border(top: BorderSide(color: AppColors.line, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Inclus', style: AppText.label(size: 11, letterSpacing: 1)),
                const SizedBox(height: 2),
                Text('dans votre abonnement',
                    style: AppText.body(size: 13, weight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          isFull
              ? _OutlineBtn(
                  label: "Liste d'attente",
                  onTap: () => _showWaitlistDialog(context),
                )
              : _PrimaryBtn(
                  label: 'Réserver',
                  onTap: () => _showReservationDialog(context),
                ),
        ],
      ),
    );
  }

  void _showReservationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Confirmation', style: AppText.body(size: 17, weight: FontWeight.w600)),
        content: Text('Voulez-vous réserver "${cours.titre}" ?',
            style: AppText.body(size: 15, color: AppColors.ink2)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: AppText.body(size: 14, color: AppColors.ink3)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cours réservé avec succès')),
              );
            },
            child: Text('Confirmer',
                style: AppText.body(size: 14, weight: FontWeight.w600, color: AppColors.sage)),
          ),
        ],
      ),
    );
  }

  void _showWaitlistDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Liste d'attente", style: AppText.body(size: 17, weight: FontWeight.w600)),
        content: Text(
            'Le cours est complet. Voulez-vous rejoindre la liste d\'attente ?',
            style: AppText.body(size: 15, color: AppColors.ink2)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: AppText.body(size: 14, color: AppColors.ink3)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Inscrit à la liste d'attente")),
              );
            },
            child: Text("M'inscrire",
                style: AppText.body(size: 14, weight: FontWeight.w600, color: AppColors.sage)),
          ),
        ],
      ),
    );
  }
}

class _PrimaryBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PrimaryBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(label,
            style: AppText.body(size: 15, weight: FontWeight.w500, color: Colors.white)),
      ),
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _OutlineBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: AppColors.line2, width: 1.5),
        ),
        child: Text(label, style: AppText.body(size: 14, weight: FontWeight.w500)),
      ),
    );
  }
}
