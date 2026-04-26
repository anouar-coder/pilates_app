// lib/services/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();

  // Initialiser les notifications locales
  Future<void> initNotifications() async {
    // Configuration Android
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // Configuration iOS
    const DarwinInitializationSettings iosSettings = 
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(initSettings);

    // Créer le canal de notification pour Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'pilates_channel',
      'Notifications Pilates',
      description: 'Canal pour les notifications',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    
    print('✅ Notifications locales initialisées');
  }

  // Afficher une notification locale
  Future<void> afficherNotification(String titre, String message) async {
    await _localNotifications.show(
      DateTime.now().millisecond,
      titre,
      message,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'pilates_channel',
          'Notifications Pilates',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
    print('🔔 Notification affichée: $titre');
  }

  // Récupérer les notifications non lues (sans orderBy pour éviter l'index composite)
  Stream<QuerySnapshot> getNotificationsNonLues() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return Stream.empty();

    return FirebaseFirestore.instance
        .collection('utilisateurs')
        .doc(userId)
        .collection('notifications')
        .where('lu', isEqualTo: false)
        .snapshots();
  }

  // Marquer une notification comme lue
  Future<void> marquerCommeLue(String notificationId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    await FirebaseFirestore.instance
        .collection('utilisateurs')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .update({'lu': true});
  }

  // Marquer toutes les notifications comme lues
  Future<void> marquerToutesCommeLues() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('utilisateurs')
        .doc(userId)
        .collection('notifications')
        .where('lu', isEqualTo: false)
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.update({'lu': true});
    }
  }
}