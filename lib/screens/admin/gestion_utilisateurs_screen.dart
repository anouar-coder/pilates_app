// lib/screens/admin/gestion_utilisateurs_screen.dart
import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/admin_service.dart';
import '../../models/profil.dart';

class GestionUtilisateursScreen extends StatefulWidget {
  const GestionUtilisateursScreen({super.key});

  @override
  State<GestionUtilisateursScreen> createState() => _GestionUtilisateursScreenState();
}

class _GestionUtilisateursScreenState extends State<GestionUtilisateursScreen> {
  final AdminService _adminService = AdminService();

  Future<void> _changerRole(Profil user, String role) async {
    final messenger = ScaffoldMessenger.of(context);
    final success = await _adminService.changerRoleUtilisateur(user.id, role);

    if (!mounted) return;
    if (success) {
      messenger.showSnackBar(
        SnackBar(content: Text('Role change pour ${user.nom}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: StreamBuilder<List<Profil>>(
        stream: _adminService.getAllUtilisateurs(),
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

          final utilisateurs = snapshot.data ?? [];

          if (utilisateurs.isEmpty) {
            return const _EmptyState(
              icon: Icons.people_outline_rounded,
              title: 'Aucun utilisateur',
              message: 'Les profils apparaitront ici.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: utilisateurs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final user = utilisateurs[index];
              return AppCard(
                padding: EdgeInsets.zero,
                borderRadius: AppRadius.md,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.sageBg,
                    foregroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                    child: user.photoUrl == null
                        ? const Icon(Icons.person_rounded, color: AppColors.sageDeep)
                        : null,
                  ),
                  title: Text(user.nom, style: AppText.body(size: 16, weight: FontWeight.w600)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.email, style: AppText.body(size: 13, color: AppColors.ink3)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.admin_panel_settings_rounded, size: 14, color: AppColors.ink4),
                          const SizedBox(width: 4),
                          Text('Role: ${user.role}', style: AppText.body(size: 12, color: AppColors.ink3)),
                        ],
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    color: AppColors.card,
                    iconColor: AppColors.ink3,
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'admin',
                        child: Row(
                          children: [
                            const Icon(Icons.admin_panel_settings_rounded, color: AppColors.sageDeep),
                            const SizedBox(width: 8),
                            Text('Promouvoir admin', style: AppText.body(size: 14)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'client',
                        child: Row(
                          children: [
                            const Icon(Icons.person_rounded, color: AppColors.clay),
                            const SizedBox(width: 8),
                            Text('Retrograder client', style: AppText.body(size: 14)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) => _changerRole(user, value),
                  ),
                ),
              );
            },
          );
        },
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
            Icon(icon, size: 64, color: iconColor.withValues(alpha: 0.65)),
            const SizedBox(height: 16),
            Text(title, style: AppText.body(size: 20, weight: FontWeight.w600), textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(message, style: AppText.body(size: 14, color: AppColors.ink3), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
