// lib/screens/accueil/accueil_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/cours_card.dart';
import '../../services/firebase_service.dart';
import '../../services/chat_service.dart' as chat;
import '../../services/profil_service.dart';
import '../../services/notification_service.dart';
import '../../services/attente_service.dart';
import '../../models/cours.dart';
import '../../models/profil.dart';
import '../reservations/mes_reservations_screen.dart';
import '../notifications/notifications_screen.dart';
import '../calendrier/calendrier_screen.dart'; // Import direct
import '../chat/conversations_screen.dart' as chat_screen;
import 'edit_profil_screen.dart';
import '../programmes/programmes_list_screen.dart';

// ============================================================
// ÉCRAN PRINCIPAL AVEC NAVIGATION PAR ONGLETS
// ============================================================
class AccueilScreen extends StatefulWidget {
  const AccueilScreen({super.key});

  @override
  State<AccueilScreen> createState() => _AccueilScreenState();
}

class _AccueilScreenState extends State<AccueilScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = [
    CoursScreen(),
    CalendrierScreen(), // ← Utilisation directe du vrai calendrier
    ProfilScreen(),
    MesReservationsScreen(),
    ProgrammesListScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Cours',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendrier',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark),
            label: 'Mes cours',
          ),
          const BottomNavigationBarItem(
  icon: Icon(Icons.fitness_center),
  label: 'Programmes',
),  
        ],
      ),
    );
  }
}

// ============================================================
// ÉCRAN DES COURS DISPONIBLES (AVEC NOTIFICATIONS ET MESSAGES)
// ============================================================
class CoursScreen extends StatefulWidget {
  const CoursScreen({super.key});

  @override
  State<CoursScreen> createState() => _CoursScreenState();
}

class _CoursScreenState extends State<CoursScreen> {
  final NotificationService _notificationService = NotificationService();
  final chat.ChatService _chatService = chat.ChatService();
  late StreamSubscription<QuerySnapshot> _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _ecouterNotifications();
  }

  void _ecouterNotifications() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    _notificationSubscription = FirebaseFirestore.instance
        .collection('utilisateurs')
        .doc(userId)
        .collection('notifications')
        .where('lu', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final notif = change.doc.data() as Map<String, dynamic>;
              _notificationService.afficherNotification(
                notif['titre'] ?? 'Notification',
                notif['message'] ?? '',
              );
            }
          }
        });
  }

  // Widget pour le badge de messages non lus
  Widget _buildMessageBadge() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('utilisateurs')
          .doc(userId)
          .collection('conversations')
          .snapshots(),
      builder: (context, snapshot) {
        int totalNonLus = 0;
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            totalNonLus += (data['messagesNonLus'] as int?) ?? 0;
          }
        }
        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.message),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const chat_screen.ConversationsScreen(),
                  ),
                );
              },
            ),
            if (totalNonLus > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '$totalNonLus',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _notificationSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firebaseService = FirebaseService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cours disponibles'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          // Badge de messages
          _buildMessageBadge(),
          const SizedBox(width: 4),
          
          // Badge de notifications
          StreamBuilder<QuerySnapshot>(
            stream: _notificationService.getNotificationsNonLues(),
            builder: (context, snapshot) {
              int nonLues = snapshot.data?.docs.length ?? 0;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationsScreen(),
                        ),
                      );
                    },
                  ),
                  if (nonLues > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$nonLues',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<Cours>>(
        stream: firebaseService.getCours(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur de chargement',
                    style: TextStyle(fontSize: 18, color: Colors.red[700]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Forcer le rebuild
                    },
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final coursListe = snapshot.data ?? [];

          if (coursListe.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun cours disponible',
                    style: TextStyle(fontSize: 20, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: coursListe.length,
            itemBuilder: (context, index) {
              final cours = coursListe[index];
              return CoursCard(cours: cours);
            },
          );
        },
      ),
    );
  }
}

// ============================================================
// ÉCRAN PROFIL UTILISATEUR
// ============================================================
class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  final ProfilService _profilService = ProfilService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();
  
  Map<String, dynamic> _statistiques = {};

  @override
  void initState() {
    super.initState();
    _chargerStatistiques();
  }

  Future<void> _chargerStatistiques() async {
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      final stats = await _profilService.calculerStatistiques(userId);
      setState(() {
        _statistiques = stats;
      });
    }
  }

  // Widget pour le badge de messages non lus (dans le profil)
  Widget _buildMessageBadge() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('utilisateurs')
          .doc(userId)
          .collection('conversations')
          .snapshots(),
      builder: (context, snapshot) {
        int totalNonLus = 0;
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            totalNonLus += (data['messagesNonLus'] as int?) ?? 0;
          }
        }
        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.message, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const chat_screen.ConversationsScreen(),
                  ),
                );
              },
            ),
            if (totalNonLus > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '$totalNonLus',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<Profil?>(
        stream: _profilService.getProfil(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }

          final profil = snapshot.data;
          
          if (profil == null) {
            return const Center(child: Text('Profil non trouvé'));
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: Colors.blue,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    profil.nom.split(' ').first,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.blue.shade400,
                              Colors.blue.shade800,
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 20,
                        left: 20,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 3,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: profil.photoUrl != null
                                ? CachedNetworkImageProvider(profil.photoUrl!)
                                : null,
                            child: profil.photoUrl == null
                                ? const Icon(
                                    Icons.person,
                                    size: 40,
                                    color: Colors.blue,
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  // Badge de messages dans le profil
                  _buildMessageBadge(),
                  
                  // Badge de notifications
                  StreamBuilder<QuerySnapshot>(
                    stream: _notificationService.getNotificationsNonLues(),
                    builder: (context, notifSnapshot) {
                      int nonLues = notifSnapshot.data?.docs.length ?? 0;
                      return Stack(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications, color: Colors.white),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const NotificationsScreen(),
                                ),
                              );
                            },
                          ),
                          if (nonLues > 0)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  '$nonLues',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfilScreen(profil: profil),
                        ),
                      );
                      if (result == true) {
                        _chargerStatistiques();
                      }
                    },
                  ),
                ],
              ),

              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Text(
                      profil.nom,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    
                    Row(
                      children: [
                        const Icon(Icons.email, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          profil.email,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    if (profil.telephone != null)
                      Row(
                        children: [
                          const Icon(Icons.phone, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            profil.telephone!,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getCouleurNiveau(profil.niveau).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getIconNiveau(profil.niveau),
                            size: 16,
                            color: _getCouleurNiveau(profil.niveau),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Niveau ${profil.niveau}',
                            style: TextStyle(
                              color: _getCouleurNiveau(profil.niveau),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (profil.objectifs != null) ...[
                      const Text(
                        '🎯 Objectifs',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Text(profil.objectifs!),
                      ),
                      const SizedBox(height: 24),
                    ],

                    const Text(
                      '📊 Statistiques',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.2,
                      children: [
                        _buildStatCard(
                          'Cours suivis',
                          '${_statistiques['coursPasses'] ?? 0}',
                          Icons.fitness_center,
                          Colors.blue,
                        ),
                        _buildStatCard(
                          'Heures totales',
                          '${_statistiques['totalHeures'] ?? 0}h',
                          Icons.access_time,
                          Colors.green,
                        ),
                        _buildStatCard(
                          'À venir',
                          '${_statistiques['coursFuturs'] ?? 0}',
                          Icons.calendar_today,
                          Colors.orange,
                        ),
                        _buildStatCard(
                          'Moyenne',
                          '${profil.noteMoyenne.toStringAsFixed(1)} ⭐',
                          Icons.star,
                          Colors.amber,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Fonctionnalité de paiement temporairement désactivée'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        },
                        icon: const Icon(Icons.shopping_cart),
                        label: const Text('Acheter des séances'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await _auth.signOut();
                          if (context.mounted) {
                            Navigator.pushReplacementNamed(context, '/login');
                          }
                        },
                        icon: const Icon(Icons.logout),
                        label: const Text('Se déconnecter'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getCouleurNiveau(String niveau) {
    switch (niveau) {
      case 'Débutant':
        return Colors.green;
      case 'Intermédiaire':
        return Colors.orange;
      case 'Avancé':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  IconData _getIconNiveau(String niveau) {
    switch (niveau) {
      case 'Débutant':
        return Icons.eco;
      case 'Intermédiaire':
        return Icons.trending_up;
      case 'Avancé':
        return Icons.workspace_premium;
      default:
        return Icons.fitness_center;
    }
  }
}

// ============================================================
// SUPPRIMEZ COMPLÈTEMENT CETTE CLASSE SI ELLE EXISTE ENCORE :
// class CalendrierScreen extends StatelessWidget {
//   const CalendrierScreen({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return const CalendrierScreen(); // ← BOUCLE INFINIE !
//   }
// }
// ============================================================