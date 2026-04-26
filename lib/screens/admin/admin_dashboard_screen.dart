import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_theme.dart';
import '../../services/admin_service.dart';
import '../../models/admin.dart';
import 'gestion_cours_screen.dart';
import 'gestion_reservations_screen.dart';
import 'gestion_utilisateurs_screen.dart';
import 'gestion_avis_screen.dart';
import 'envoyer_notification_screen.dart';
import '../chat/conversations_screen.dart';
import 'gestion_programmes_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _screens = [
    const StatsScreen(),
    const GestionCoursScreen(),
    const GestionReservationsScreen(),
    const GestionUtilisateursScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ADMIN', style: AppText.label(size: 10, color: AppColors.ink3, letterSpacing: 2)),
            Text(
              'Studio Pilate',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.rate_review_outlined, color: AppColors.ink2, size: 22),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const GestionAvisScreen())),
            tooltip: 'Gérer les avis',
          ),
          IconButton(
            icon: const Icon(Icons.library_books_outlined, color: AppColors.ink2, size: 22),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const GestionProgrammesScreen())),
            tooltip: 'Programmes',
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.ink2, size: 22),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ConversationsScreen())),
            tooltip: 'Messages',
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppColors.ink2, size: 22),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const EnvoyerNotificationScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.ink2, size: 22),
            onPressed: () => setState(() {}),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.danger, size: 22),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.bg,
          border: Border(top: BorderSide(color: AppColors.line, width: 1)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _AdminTab(icon: Icons.bar_chart_rounded, label: 'Stats', index: 0, selected: _selectedIndex, onTap: (i) => setState(() => _selectedIndex = i)),
                _AdminTab(icon: Icons.fitness_center_rounded, label: 'Cours', index: 1, selected: _selectedIndex, onTap: (i) => setState(() => _selectedIndex = i)),
                _AdminTab(icon: Icons.bookmark_outline_rounded, label: 'Réserv.', index: 2, selected: _selectedIndex, onTap: (i) => setState(() => _selectedIndex = i)),
                _AdminTab(icon: Icons.people_outline_rounded, label: 'Membres', index: 3, selected: _selectedIndex, onTap: (i) => setState(() => _selectedIndex = i)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int selected;
  final ValueChanged<int> onTap;

  const _AdminTab({
    required this.icon,
    required this.label,
    required this.index,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = index == selected;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: active ? AppColors.ink : AppColors.ink4),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppText.body(
                size: 10,
                weight: active ? FontWeight.w600 : FontWeight.w400,
                color: active ? AppColors.ink : AppColors.ink4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stats screen ──────────────────────────────────────────────────────────────
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AdminStats>(
      future: AdminService().getStatistiques(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.sage, strokeWidth: 2));
        }
        if (snapshot.hasError) {
          return Center(
              child: Text('Erreur: ${snapshot.error}',
                  style: AppText.body(size: 14, color: AppColors.danger)));
        }
        final stats = snapshot.data!;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vue d\'ensemble',
                style: GoogleFonts.fraunces(
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.italic,
                  color: AppColors.ink,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 20),

              // Stat grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: [
                  _StatCard(
                    value: '${stats.totalCours}',
                    label: 'Cours',
                    icon: Icons.fitness_center_rounded,
                    color: AppColors.sage,
                  ),
                  _StatCard(
                    value: '${stats.totalReservations}',
                    label: 'Réservations',
                    icon: Icons.bookmark_rounded,
                    color: AppColors.clay,
                  ),
                  _StatCard(
                    value: '${stats.totalUtilisateurs}',
                    label: 'Membres',
                    icon: Icons.people_rounded,
                    color: AppColors.sageDeep,
                  ),
                  _StatCard(
                    value: '${stats.tauxRemplissage.toStringAsFixed(0)}%',
                    label: 'Remplissage',
                    icon: Icons.donut_large_rounded,
                    color: AppColors.warn,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Revenue card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.sageDeep,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  boxShadow: AppShadows.sh2,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'REVENUS TOTAUX',
                      style: AppText.label(size: 11, color: Colors.white.withValues(alpha: 0.7), letterSpacing: 2),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${stats.revenuTotal.toStringAsFixed(2)} €',
                      style: GoogleFonts.fraunces(
                        fontSize: 36,
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.italic,
                        color: Colors.white,
                        letterSpacing: -0.8,
                      ),
                    ),
                  ],
                ),
              ),

              if (stats.coursPopulaires.isNotEmpty) ...[
                const SizedBox(height: 24),
                const AppSectionHeader(title: 'Cours populaires'),
                ...stats.coursPopulaires.entries.take(3).map(
                      (c) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          boxShadow: AppShadows.sh1,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.sage,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(c.key, style: AppText.body(size: 14, weight: FontWeight.w500)),
                            ),
                            Text('${c.value}', style: AppText.body(size: 13, color: AppColors.ink3)),
                          ],
                        ),
                      ),
                    ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.sh1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.fraunces(
                  fontSize: 28,
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.italic,
                  color: AppColors.ink,
                  letterSpacing: -0.5,
                ),
              ),
              Text(label, style: AppText.body(size: 12, color: AppColors.ink3)),
            ],
          ),
        ],
      ),
    );
  }
}
