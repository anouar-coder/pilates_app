// lib/screens/programmes/programmes_list_screen.dart
import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/programme_service.dart';
import '../../models/programme.dart';
import 'programme_detail_screen.dart';

class ProgrammesListScreen extends StatefulWidget {
  const ProgrammesListScreen({super.key});

  @override
  State<ProgrammesListScreen> createState() => _ProgrammesListScreenState();
}

class _ProgrammesListScreenState extends State<ProgrammesListScreen> {
  final ProgrammeService _programmeService = ProgrammeService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Programmes'),
      ),
      body: StreamBuilder<List<Programme>>(
        stream: _programmeService.getProgrammesPublies(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.sage));
          }

          if (snapshot.hasError) {
            return _EmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Erreur',
              message: '${snapshot.error}',
              iconColor: AppColors.danger,
            );
          }

          final programmes = snapshot.data ?? [];

          if (programmes.isEmpty) {
            return const _EmptyState(
              icon: Icons.self_improvement_rounded,
              title: 'Aucun programme disponible',
              message: 'Les nouveaux programmes apparaitront ici.',
            );
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PROGRAMMES', style: AppText.label(size: 11, color: AppColors.ink3, letterSpacing: 2.5)),
                      const SizedBox(height: 8),
                      Text('Votre pratique guidee', style: AppText.display(size: 32)),
                      const SizedBox(height: 8),
                      Text(
                        'Choisissez un parcours et avancez seance par seance.',
                        style: AppText.body(size: 14, color: AppColors.ink3, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList.separated(
                  itemCount: programmes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    return _ProgrammeCard(
                      programme: programmes[index],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProgrammeDetailScreen(programme: programmes[index]),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProgrammeCard extends StatelessWidget {
  final Programme programme;
  final VoidCallback onTap;

  const _ProgrammeCard({
    required this.programme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final levelColor = niveauColor(programme.niveau);
    final tags = programme.tags.take(3).toList();

    return AppCard(
      padding: EdgeInsets.zero,
      borderRadius: AppRadius.lg,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 118,
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: niveauBg(programme.niveau),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
            ),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: AppColors.card.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(Icons.self_improvement_rounded, color: levelColor, size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        programme.titre,
                        style: AppText.body(size: 19, weight: FontWeight.w700, color: AppColors.ink),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Par ${programme.coachNom}',
                        style: AppText.body(size: 13, color: AppColors.ink3),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.ink3),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AppTag(
                      label: programme.niveau,
                      background: niveauBg(programme.niveau),
                      textColor: levelColor,
                    ),
                    const SizedBox(width: 8),
                    _MetaChip(icon: Icons.calendar_today_outlined, label: '${programme.dureeJours} jours'),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  programme.description,
                  style: AppText.body(size: 14, color: AppColors.ink2, height: 1.45),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: tags.map((tag) {
                      return AppTag(
                        label: tag,
                        background: AppColors.bg2,
                        textColor: AppColors.ink3,
                        fontSize: 11,
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.ink3),
          const SizedBox(width: 5),
          Text(label, style: AppText.body(size: 12, color: AppColors.ink3)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Color iconColor;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.iconColor = AppColors.ink4,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(icon, size: 32, color: iconColor),
            ),
            const SizedBox(height: 16),
            Text(title, style: AppText.body(size: 19, weight: FontWeight.w600), textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(message, style: AppText.body(size: 14, color: AppColors.ink3), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
