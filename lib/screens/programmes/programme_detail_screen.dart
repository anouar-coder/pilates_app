// lib/screens/programmes/programme_detail_screen.dart
import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/programme_service.dart';
import '../../models/programme.dart';
import '../../models/seance.dart';
import '../../models/exercice.dart';
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
    if (!mounted) return;
    setState(() {
      _progression = prog;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(widget.programme.titre),
      ),
      body: StreamBuilder<List<Seance>>(
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

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: seances.length + 1,
            separatorBuilder: (_, index) => SizedBox(height: index == 0 ? 18 : 12),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _ProgrammeHeader(
                  programme: widget.programme,
                  seancesCount: seances.length,
                  completedCount: _completedExercisesCount(seances),
                  totalCount: _totalExercisesCount(seances),
                );
              }

              if (seances.isEmpty) {
                return AppCard(
                  child: Center(
                    child: Text(
                      'Aucune seance dans ce programme',
                      style: AppText.body(size: 15, color: AppColors.ink3),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              final seance = seances[index - 1];
              final exercicesFaits = seance.exercices.where((exercice) {
                return _progression['${seance.id}_${exercice.id}'] == true;
              }).length;
              final progression = seance.exercices.isEmpty ? 0.0 : exercicesFaits / seance.exercices.length;

              return _SeanceProgressCard(
                seance: seance,
                progression: progression,
                progressionMap: _progression,
                onChanged: (exerciceId) async {
                  await _programmeService.marquerExerciceFait(widget.programme.id, seance.id, exerciceId);
                  _chargerProgression();
                },
                onOpen: (exercice) {
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
              );
            },
          );
        },
      ),
    );
  }

  int _completedExercisesCount(List<Seance> seances) {
    return seances.fold<int>(0, (total, seance) {
      return total +
          seance.exercices.where((exercice) {
            return _progression['${seance.id}_${exercice.id}'] == true;
          }).length;
    });
  }

  int _totalExercisesCount(List<Seance> seances) {
    return seances.fold<int>(0, (total, seance) => total + seance.exercices.length);
  }
}

class _ProgrammeHeader extends StatelessWidget {
  final Programme programme;
  final int seancesCount;
  final int completedCount;
  final int totalCount;

  const _ProgrammeHeader({
    required this.programme,
    required this.seancesCount,
    required this.completedCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalCount == 0 ? 0.0 : completedCount / totalCount;
    final levelColor = niveauColor(programme.niveau);

    return AppCard(
      padding: const EdgeInsets.all(20),
      borderRadius: AppRadius.lg,
      color: AppColors.cardAlt,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: niveauBg(programme.niveau),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(Icons.self_improvement_rounded, color: levelColor, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(programme.titre, style: AppText.display(size: 28), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Text('Par ${programme.coachNom}', style: AppText.body(size: 13, color: AppColors.ink3)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(programme.description, style: AppText.body(size: 14, color: AppColors.ink2, height: 1.45)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppTag(label: programme.niveau, background: niveauBg(programme.niveau), textColor: levelColor),
              _InfoTag(icon: Icons.calendar_today_outlined, label: '${programme.dureeJours} jours'),
              _InfoTag(icon: Icons.view_week_outlined, label: '$seancesCount seances'),
            ],
          ),
          if (programme.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: programme.tags.take(4).map((tag) {
                return AppTag(label: tag, background: AppColors.bg2, textColor: AppColors.ink3, fontSize: 11);
              }).toList(),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Progression', style: AppText.body(size: 13, weight: FontWeight.w600, color: AppColors.ink3)),
              Text(
                '$completedCount/$totalCount exercices',
                style: AppText.body(size: 13, weight: FontWeight.w600, color: AppColors.sageDeep),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: AppColors.bg2,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.sage),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTag extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoTag({required this.icon, required this.label});

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

class _SeanceProgressCard extends StatelessWidget {
  final Seance seance;
  final double progression;
  final Map<String, bool> progressionMap;
  final ValueChanged<String> onChanged;
  final ValueChanged<Exercice> onOpen;

  const _SeanceProgressCard({
    required this.seance,
    required this.progression,
    required this.progressionMap,
    required this.onChanged,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = progression >= 1
        ? AppColors.sageDeep
        : progression > 0
            ? AppColors.warn
            : AppColors.ink4;

    return AppCard(
      padding: EdgeInsets.zero,
      borderRadius: AppRadius.md,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.only(left: 8, right: 8, bottom: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.14),
          child: Text(
            'J${seance.jour}',
            style: AppText.body(size: 13, weight: FontWeight.w700, color: statusColor),
          ),
        ),
        title: Text(seance.titre, style: AppText.body(size: 16, weight: FontWeight.w600)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(seance.description, style: AppText.body(size: 13, color: AppColors.ink3)),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(
                  value: progression,
                  minHeight: 6,
                  backgroundColor: AppColors.bg2,
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              ),
            ],
          ),
        ),
        children: seance.exercices.map((exercice) {
          final estFait = progressionMap['${seance.id}_${exercice.id}'] == true;

          return ListTile(
            leading: Checkbox(
              value: estFait,
              activeColor: AppColors.sage,
              onChanged: estFait ? null : (value) => value == true ? onChanged(exercice.id) : null,
            ),
            title: Text(
              exercice.titre,
              style: AppText.body(
                size: 14,
                color: estFait ? AppColors.ink4 : AppColors.ink,
              ).copyWith(decoration: estFait ? TextDecoration.lineThrough : null),
            ),
            subtitle: Text(
              '${exercice.repetitions} reps - ${exercice.dureeSecondes}s',
              style: AppText.body(size: 12, color: AppColors.ink3),
            ),
            trailing: IconButton(
              tooltip: 'Ouvrir',
              icon: const Icon(Icons.play_circle_fill_rounded, color: AppColors.sageDeep),
              onPressed: () => onOpen(exercice),
            ),
          );
        }).toList(),
      ),
    );
  }
}
