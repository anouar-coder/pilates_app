// lib/screens/admin/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/admin_service.dart';
import '../../models/admin.dart';
import 'gestion_cours_screen.dart';
import 'gestion_reservations_screen.dart';
import 'gestion_utilisateurs_screen.dart';
import 'gestion_avis_screen.dart'; // ← NOUVEL IMPORT
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
      appBar: AppBar(
        title: const Text('Dashboard Admin'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          // BOUTON GESTION DES AVIS (NOUVEAU)
          IconButton(
            icon: const Icon(Icons.rate_review),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GestionAvisScreen(),
                ),
              );
            },
            tooltip: 'Gérer les avis',
          ),
          // Dans les actions de l'AppBar, après le bouton des avis :
IconButton(
  icon: const Icon(Icons.library_books),
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const GestionProgrammesScreen(),
      ),
    );
  },
  tooltip: 'Programmes',
),
          // BOUTON MESSAGERIE
          IconButton(
            icon: const Icon(Icons.message),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ConversationsScreen(),
                ),
              );
            },
            tooltip: 'Messages',
          ),
          IconButton(
            icon: const Icon(Icons.notifications_active),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EnvoyerNotificationScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {});
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Stats'),
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Cours'),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: 'Réservations'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Utilisateurs'),
        ],
      ),
    );
  }
}

// StatsScreen inchangé
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final adminService = AdminService();
    return Scaffold(
      body: FutureBuilder<AdminStats>(
        future: adminService.getStatistiques(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }
          final stats = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.2,
                  children: [
                    _buildStatCard('Cours', '${stats.totalCours}', Icons.fitness_center, Colors.blue),
                    _buildStatCard('Réservations', '${stats.totalReservations}', Icons.bookmark, Colors.green),
                    _buildStatCard('Utilisateurs', '${stats.totalUtilisateurs}', Icons.people, Colors.orange),
                    _buildStatCard('Remplissage', '${stats.tauxRemplissage.toStringAsFixed(1)}%', Icons.percent, Colors.purple),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Colors.blue, Colors.lightBlue]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Revenus totaux', style: TextStyle(color: Colors.white, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text('${stats.revenuTotal.toStringAsFixed(2)} €', 
                        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.8))),
        ],
      ),
    );
  }
}