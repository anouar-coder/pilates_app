// lib/screens/admin/gestion_utilisateurs_screen.dart
import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../models/profil.dart';

class GestionUtilisateursScreen extends StatefulWidget {
  const GestionUtilisateursScreen({super.key});

  @override
  State<GestionUtilisateursScreen> createState() => _GestionUtilisateursScreenState();
}

class _GestionUtilisateursScreenState extends State<GestionUtilisateursScreen> {
  final AdminService _adminService = AdminService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<Profil>>(
        stream: _adminService.getAllUtilisateurs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text('Erreur: ${snapshot.error}'),
                ],
              ),
            );
          }

          final utilisateurs = snapshot.data ?? [];

          if (utilisateurs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun utilisateur',
                    style: TextStyle(fontSize: 20, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: utilisateurs.length,
            itemBuilder: (context, index) {
              final user = utilisateurs[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: user.photoUrl != null
                        ? NetworkImage(user.photoUrl!)
                        : null,
                    child: user.photoUrl == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(user.nom),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.email),
                      Row(
                        children: [
                          const Icon(Icons.admin_panel_settings, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text('Rôle: ${user.role}'),
                        ],
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'admin',
                        child: Row(
                          children: [
                            Icon(Icons.admin_panel_settings, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Promouvoir admin'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'client',
                        child: Row(
                          children: [
                            Icon(Icons.person, color: Colors.green),
                            SizedBox(width: 8),
                            Text('Rétrograder client'),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) async {
                      final success = await _adminService.changerRoleUtilisateur(user.id, value);
                      if (success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Rôle changé pour ${user.nom}'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
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