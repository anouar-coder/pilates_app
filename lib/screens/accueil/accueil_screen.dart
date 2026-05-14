import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/cours_card.dart';
import '../../widgets/assistant_bubble.dart';
import '../../services/firebase_service.dart';
import '../../services/profil_service.dart';
import '../../services/notification_service.dart';
import '../../models/cours.dart';
import '../../models/profil.dart';
import '../../config/app_theme.dart';
import '../reservations/mes_reservations_screen.dart';
import '../notifications/notifications_screen.dart';
import '../calendrier/calendrier_screen.dart';
import '../chat/conversations_screen.dart' as chat_screen;
import 'edit_profil_screen.dart';
import '../programmes/programmes_list_screen.dart';

// ── Bottom navigation ─────────────────────────────────────────────────────────
class AccueilScreen extends StatefulWidget {
  const AccueilScreen({super.key});

  @override
  State<AccueilScreen> createState() => _AccueilScreenState();
}

class _AccueilScreenState extends State<AccueilScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = [
    CoursScreen(),
    CalendrierScreen(),
    ProfilScreen(),
    MesReservationsScreen(),
    ProgrammesListScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 56,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.danger, size: 22),
            tooltip: 'Déconnexion',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        children: [
          _screens[_selectedIndex],
          const AssistantBubble(bottom: 96),
        ],
      ),
      bottomNavigationBar: _PilateBottomNav(
        selectedIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
      ),
    );
  }
}

// ── Custom bottom nav ─────────────────────────────────────────────────────────
class _PilateBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _PilateBottomNav({required this.selectedIndex, required this.onTap});

  static const _tabs = [
    (icon: Icons.home_outlined,         activeIcon: Icons.home_rounded,             label: 'Accueil'),
    (icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today_rounded, label: 'Planning'),
    (icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded,          label: 'Profil'),
    (icon: Icons.bookmark_outline_rounded, activeIcon: Icons.bookmark_rounded,      label: 'Mes cours'),
    (icon: Icons.grid_view_outlined,    activeIcon: Icons.grid_view_rounded,        label: 'Programmes'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg.withValues(alpha: 0.95),
        border: const Border(top: BorderSide(color: AppColors.line, width: 1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A1F1D1A),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_tabs.length, (i) {
              final tab = _tabs[i];
              final active = i == selectedIndex;
              return GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 60,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        active ? tab.activeIcon : tab.icon,
                        color: active ? AppColors.ink : AppColors.ink4,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tab.label,
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
            }),
          ),
        ),
      ),
    );
  }
}

// ── Cours screen ──────────────────────────────────────────────────────────────
class CoursScreen extends StatefulWidget {
  const CoursScreen({super.key});

  @override
  State<CoursScreen> createState() => _CoursScreenState();
}

class _CoursScreenState extends State<CoursScreen> {
  final NotificationService _notificationService = NotificationService();
  StreamSubscription<QuerySnapshot>? _notificationSubscription;

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
    }, onError: (Object error, StackTrace stackTrace) {
      // Ignore backend permission issues to keep UI responsive.
      debugPrint('Erreur notifications en temps reel: $error');
    });
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

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
        int total = 0;
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final d = doc.data() as Map<String, dynamic>;
            total += (d['messagesNonLus'] as int?) ?? 0;
          }
        }
        return _IconBadge(
          icon: Icons.chat_bubble_outline_rounded,
          count: total,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const chat_screen.ConversationsScreen())),
        );
      },
    );
  }

  Widget _buildNotifBadge() {
    return StreamBuilder<QuerySnapshot>(
      stream: _notificationService.getNotificationsNonLues(),
      builder: (context, snapshot) {
        int count = snapshot.data?.docs.length ?? 0;
        return _IconBadge(
          icon: Icons.notifications_outlined,
          count: count,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen())),
        );
      },
    );
  }

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
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PILATE',
                          style: AppText.label(size: 11, color: AppColors.ink3, letterSpacing: 2.5),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Cours disponibles',
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
                  _buildMessageBadge(),
                  _buildNotifBadge(),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.line),
            // ── Course list ──────────────────────────────────────────
            Expanded(
              child: StreamBuilder<List<Cours>>(
                stream: FirebaseService().getCours(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _EmptyState(
                      icon: Icons.error_outline_rounded,
                      message: 'Impossible de charger les cours',
                      color: AppColors.danger,
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.sage, strokeWidth: 2),
                    );
                  }
                  final cours = snapshot.data ?? [];
                  if (cours.isEmpty) {
                    return _EmptyState(
                      icon: Icons.event_busy_outlined,
                      message: 'Aucun cours disponible pour le moment',
                      color: AppColors.ink4,
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: cours.length,
                    itemBuilder: (context, i) => CoursCard(cours: cours[i]),
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

// ── Icon with badge ───────────────────────────────────────────────────────────
class _IconBadge extends StatelessWidget {
  final IconData icon;
  final int count;
  final VoidCallback onTap;

  const _IconBadge({required this.icon, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: Icon(icon, color: AppColors.ink2, size: 22),
          onPressed: onTap,
        ),
        if (count > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.clay,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color color;

  const _EmptyState({required this.icon, required this.message, required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: color.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppText.body(size: 15, color: AppColors.ink3),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Profil screen ─────────────────────────────────────────────────────────────
class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  final ProfilService _profilService = ProfilService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notifService = NotificationService();
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      final s = await _profilService.calculerStatistiques(uid);
      if (!mounted) return;
      setState(() => _stats = s);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: StreamBuilder<Profil?>(
        stream: _profilService.getProfil(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.sage, strokeWidth: 2),
            );
          }
          final profil = snapshot.data;
          if (profil == null) {
            return const Center(child: Text('Profil non trouvé'));
          }
          return CustomScrollView(
            slivers: [
              // ── Identity header ────────────────────────────────────
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Mon profil',
                            style: AppText.body(size: 13, color: AppColors.ink3),
                          ),
                        ),
                        // Messages badge
                        _buildMsgBadge(context),
                        // Notifications badge
                        StreamBuilder<QuerySnapshot>(
                          stream: _notifService.getNotificationsNonLues(),
                          builder: (ctx, ns) {
                            int n = ns.data?.docs.length ?? 0;
                            return _IconBadge(
                              icon: Icons.notifications_outlined,
                              count: n,
                              onTap: () => Navigator.push(ctx,
                                  MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: AppColors.ink3, size: 20),
                          onPressed: () async {
                            final r = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditProfilScreen(profil: profil),
                              ),
                            );
                            if (r == true) _loadStats();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Avatar + name ──────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Row(
                    children: [
                      _Avatar(profil: profil, size: 72),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profil.nom,
                              style: GoogleFonts.fraunces(
                                fontSize: 24,
                                fontWeight: FontWeight.w400,
                                fontStyle: FontStyle.italic,
                                color: AppColors.ink,
                                letterSpacing: -0.6,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: niveauBg(profil.niveau),
                                    borderRadius: BorderRadius.circular(AppRadius.pill),
                                  ),
                                  child: Text(
                                    profil.niveau,
                                    style: AppText.body(
                                        size: 12,
                                        weight: FontWeight.w500,
                                        color: niveauColor(profil.niveau)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Stats grid ─────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: AppCard(
                    color: AppColors.cardAlt,
                    shadows: const [],
                    child: Row(
                      children: [
                        Expanded(
                          child: _StatItem(
                            value: '${_stats['coursPasses'] ?? 0}',
                            label: 'Cours suivis',
                          ),
                        ),
                        Container(width: 1, height: 40, color: AppColors.line),
                        Expanded(
                          child: _StatItem(
                            value: '${_stats['totalHeures'] ?? 0}h',
                            label: 'Total heures',
                          ),
                        ),
                        Container(width: 1, height: 40, color: AppColors.line),
                        Expanded(
                          child: _StatItem(
                            value: '${_stats['coursFuturs'] ?? 0}',
                            label: 'À venir',
                          ),
                        ),
                        Container(width: 1, height: 40, color: AppColors.line),
                        Expanded(
                          child: _StatItem(
                            value: profil.noteMoyenne.toStringAsFixed(1),
                            label: 'Moyenne',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Objectives ────────────────────────────────────────
              if (profil.objectifs != null && profil.objectifs!.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AppSectionHeader(title: 'Objectifs'),
                        AppCard(
                          color: AppColors.cardAlt,
                          shadows: const [],
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.eco_outlined, color: AppColors.sageDeep, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  profil.objectifs!,
                                  style: AppText.body(size: 14, color: AppColors.ink2, height: 1.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // ── Menu rows ─────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppSectionHeader(title: 'Mon compte'),
                      AppCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _MenuRow(
                              icon: Icons.access_time_rounded,
                              label: 'Historique des séances',
                              trailing: '${_stats['coursPasses'] ?? 0}',
                              onTap: () {},
                            ),
                            const Divider(height: 1, indent: 56, color: AppColors.line),
                            _MenuRow(
                              icon: Icons.credit_card_rounded,
                              label: 'Paiements & factures',
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Fonctionnalité de paiement temporairement désactivée'),
                                  ),
                                );
                              },
                            ),
                            const Divider(height: 1, indent: 56, color: AppColors.line),
                            _MenuRow(
                              icon: Icons.notifications_outlined,
                              label: 'Notifications',
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                            ),
                            const Divider(height: 1, indent: 56, color: AppColors.line),
                            _MenuRow(
                              icon: Icons.logout_rounded,
                              label: 'Se déconnecter',
                              isDanger: true,
                              onTap: () async {
                                await _auth.signOut();
                                if (context.mounted) {
                                  Navigator.pushReplacementNamed(context, '/login');
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMsgBadge(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox();
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('utilisateurs')
          .doc(uid)
          .collection('conversations')
          .snapshots(),
      builder: (ctx, snap) {
        int total = 0;
        if (snap.hasData) {
          for (var doc in snap.data!.docs) {
            final d = doc.data() as Map<String, dynamic>;
            total += (d['messagesNonLus'] as int?) ?? 0;
          }
        }
        return _IconBadge(
          icon: Icons.chat_bubble_outline_rounded,
          count: total,
          onTap: () => Navigator.push(ctx,
              MaterialPageRoute(builder: (_) => const chat_screen.ConversationsScreen())),
        );
      },
    );
  }
}

// ── Avatar widget ─────────────────────────────────────────────────────────────
class _Avatar extends StatelessWidget {
  final Profil profil;
  final double size;

  const _Avatar({required this.profil, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.sageSoft,
        border: Border.all(color: AppColors.sageSoft, width: 3),
        image: profil.photoUrl != null
            ? DecorationImage(
                image: CachedNetworkImageProvider(profil.photoUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: profil.photoUrl == null
          ? Center(
              child: Text(
                profil.nom.isNotEmpty ? profil.nom[0].toUpperCase() : '?',
                style: AppText.body(
                  size: size * 0.36,
                  weight: FontWeight.w600,
                  color: AppColors.sageDeep,
                ),
              ),
            )
          : null,
    );
  }
}

// ── Stat item ─────────────────────────────────────────────────────────────────
class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.fraunces(
              fontSize: 22,
              fontWeight: FontWeight.w400,
              fontStyle: FontStyle.italic,
              color: AppColors.ink,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: AppText.body(size: 10, color: AppColors.ink3), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ── Menu row ──────────────────────────────────────────────────────────────────
class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;
  final bool isDanger;
  final VoidCallback? onTap;

  const _MenuRow({
    required this.icon,
    required this.label,
    this.trailing,
    this.isDanger = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDanger ? AppColors.danger : AppColors.ink;
    final bgColor = isDanger ? AppColors.dangerBg : AppColors.bg2;

    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 16, color: isDanger ? AppColors.danger : AppColors.ink2),
      ),
      title: Text(
        label,
        style: AppText.body(size: 15, color: color),
      ),
      trailing: trailing != null
          ? Text(trailing!, style: AppText.body(size: 13, color: AppColors.ink3))
          : (!isDanger
              ? const Icon(Icons.chevron_right_rounded, color: AppColors.ink4, size: 20)
              : null),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      minLeadingWidth: 0,
    );
  }
}
