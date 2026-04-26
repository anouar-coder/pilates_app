import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_theme.dart';
import '../../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ALERTES', style: AppText.label(size: 10, color: AppColors.ink3, letterSpacing: 2)),
            Text(
              'Notifications',
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
          TextButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              await _notificationService.marquerToutesCommeLues();
              messenger.showSnackBar(
                const SnackBar(content: Text('Toutes marquées comme lues')),
              );
            },
            child: Text(
              'Tout lire',
              style: AppText.body(size: 13, weight: FontWeight.w500, color: AppColors.sage),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _notificationService.getNotificationsNonLues(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.sage, strokeWidth: 2));
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Erreur: ${snapshot.error}',
                  style: AppText.body(size: 14, color: AppColors.danger)),
            );
          }

          final notifications = snapshot.data?.docs ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_outlined,
                      size: 56, color: AppColors.ink4.withValues(alpha: 0.4)),
                  const SizedBox(height: 16),
                  Text('Aucune notification',
                      style: AppText.body(size: 15, color: AppColors.ink3)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index].data() as Map<String, dynamic>;
              final notifId = notifications[index].id;
              final date = (notif['date'] as Timestamp?)?.toDate();
              final timeStr = date != null
                  ? '${date.day}/${date.month}/${date.year} · ${date.hour}h${date.minute.toString().padLeft(2, '0')}'
                  : '';

              return Dismissible(
                key: Key(notifId),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: AppColors.sageBg,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: const Icon(Icons.done_all_rounded, color: AppColors.sageDeep),
                ),
                onDismissed: (_) => _notificationService.marquerCommeLue(notifId),
                child: GestureDetector(
                  onTap: () => _notificationService.marquerCommeLue(notifId),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      boxShadow: AppShadows.sh1,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.sageBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.notifications_outlined,
                              color: AppColors.sageDeep, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notif['titre'] ?? 'Notification',
                                style: AppText.body(size: 14, weight: FontWeight.w600),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                notif['message'] ?? '',
                                style: AppText.body(size: 13, color: AppColors.ink2, height: 1.4),
                              ),
                              if (timeStr.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(timeStr,
                                    style: AppText.body(size: 11, color: AppColors.ink4)),
                              ],
                            ],
                          ),
                        ),
                        const Icon(Icons.circle, color: AppColors.clay, size: 8),
                      ],
                    ),
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
