// lib/screens/programmes/seance_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_theme.dart';
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
    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exercice termine')),
    );
    Navigator.pop(context);
  }

  Future<void> _ouvrirVideo() async {
    final videoUrl = widget.exercice.videoUrl;
    if (videoUrl == null || videoUrl.isEmpty) return;

    final url = Uri.parse(videoUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(widget.exercice.titre),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.exercice.titre, style: AppText.display(size: 30)),
            const SizedBox(height: 8),
            Text(
              'Seance: ${widget.seance.titre}',
              style: AppText.body(size: 15, color: AppColors.ink3),
            ),
            const SizedBox(height: 20),
            _Section(
              title: 'Description',
              child: Text(
                widget.exercice.description,
                style: AppText.body(size: 15, color: AppColors.ink2, height: 1.5),
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              borderRadius: AppRadius.md,
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.timer_outlined,
                    label: 'Duree',
                    value: '${widget.exercice.dureeSecondes} secondes',
                  ),
                  const Divider(height: 24, color: AppColors.line),
                  _InfoRow(
                    icon: Icons.loop_rounded,
                    label: 'Repetitions',
                    value: '${widget.exercice.repetitions} fois',
                  ),
                ],
              ),
            ),
            if (widget.exercice.materiel.isNotEmpty) ...[
              const SizedBox(height: 16),
              _Section(
                title: 'Materiel necessaire',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.exercice.materiel.map((item) {
                    return AppTag(
                      label: item,
                      background: AppColors.sageBg,
                      textColor: AppColors.sageDeep,
                    );
                  }).toList(),
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (widget.exercice.videoUrl != null && widget.exercice.videoUrl!.isNotEmpty) ...[
              AppButtonSoft(
                label: 'Voir la video',
                onPressed: _ouvrirVideo,
                background: AppColors.dangerBg,
                foreground: AppColors.danger,
              ),
              const SizedBox(height: 12),
            ],
            AppButton(
              label: 'Marquer comme termine',
              onPressed: _isLoading ? null : _marquerTermine,
              isLoading: _isLoading,
              backgroundColor: AppColors.sageDeep,
              leading: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppText.body(size: 18, weight: FontWeight.w600)),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(color: AppColors.sageBg, shape: BoxShape.circle),
          child: Icon(icon, color: AppColors.sageDeep, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: AppText.body(size: 14, color: AppColors.ink3)),
        ),
        Text(value, style: AppText.body(size: 15, weight: FontWeight.w600)),
      ],
    );
  }
}
